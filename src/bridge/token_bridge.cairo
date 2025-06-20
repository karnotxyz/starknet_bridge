#[starknet::contract]
pub mod TokenBridge {
    use core::array::ArrayTrait;
    use core::num::traits::Bounded;
    use core::num::traits::zero::Zero;
    use core::option::OptionTrait;
    use core::serde::Serde;
    use core::to_byte_array::FormatAsByteArray;
    use core::traits::TryInto;
    use openzeppelin::access::accesscontrol::AccessControlComponent;
    use openzeppelin::access::accesscontrol::interface::IAccessControl;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::introspection::src5::SRC5Component::{
        InternalImpl as SRC5InternalImpl, SRC5Impl,
    };
    use openzeppelin::security::pausable::PausableComponent;
    use openzeppelin::security::reentrancyguard::ReentrancyGuardComponent;
    use openzeppelin::security::reentrancyguard::ReentrancyGuardComponent::InternalTrait as InternalReentrancyGuardImpl;
    use openzeppelin::token::erc20::interface::{
        IERC20Dispatcher, IERC20DispatcherTrait, IERC20MetadataDispatcher,
        IERC20MetadataDispatcherTrait,
    };
    use openzeppelin::upgrades::UpgradeableComponent;
    use openzeppelin::upgrades::interface::IUpgradeable;
    use piltover::messaging::interface::{IMessagingDispatcher, IMessagingDispatcherTrait};
    use piltover::messaging::types::{MessageHash, MessageToAppchainStatus, Nonce};
    use starknet::event::EventEmitter;
    use starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess,
    };
    use starknet::syscalls::call_contract_syscall;
    use starknet::{
        ClassHash, ContractAddress, SyscallResultTrait, get_block_timestamp, get_caller_address,
        get_contract_address,
    };

    use starknet_bridge::access_control::roles::Roles;
    use starknet_bridge::access_control::component::BridgeAccessControlComponent;
    use starknet_bridge::bridge::interface::{ITokenBridge, ITokenBridgeAdmin};
    use starknet_bridge::bridge::types::{TokenSettings, TokenStatus};
    use starknet_bridge::constants;
    use starknet_bridge::withdrawal_limit::component::WithdrawalLimitComponent;
    use starknet_bridge::withdrawal_limit::component::WithdrawalLimitComponent::InternalTrait;

    component!(path: AccessControlComponent, storage: access_control, event: AccessControlEvent);
    component!(
        path: BridgeAccessControlComponent,
        storage: bridge_access_control,
        event: BridgeAccessControlEvent,
    );
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);
    component!(path: WithdrawalLimitComponent, storage: withdrawal, event: WithdrawalEvent);
    component!(
        path: ReentrancyGuardComponent, storage: reentrancy_guard, event: ReentrancyGuardEvent,
    );
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: PausableComponent, storage: pausable, event: PausableEvent);


    // AccessControl
    #[abi(embed_v0)]
    impl BridgeAccessControlImpl =
        BridgeAccessControlComponent::BridgeAccessControlImpl<ContractState>;
    impl BridgeAccessControlInternalImpl =
        BridgeAccessControlComponent::InternalImpl<ContractState>;

    // Pausable
    #[abi(embed_v0)]
    impl PausableImpl = PausableComponent::PausableImpl<ContractState>;
    impl PausableInternal = PausableComponent::InternalImpl<ContractState>;

    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    // WithdrawalLimit
    #[abi(embed_v0)]
    impl WithdrawalLimitImpl =
        WithdrawalLimitComponent::WithdrawalLimitImpl<ContractState>;

    #[storage]
    struct Storage {
        // corresponding bridge contract_address deployed on the appchain
        pub appchain_bridge: ContractAddress,
        // the core messaging contract deployed on starknet used for l2 - l3 messsaging
        pub messaging_contract: IMessagingDispatcher,
        // All token related settings and its status
        pub token_settings: Map<ContractAddress, TokenSettings>,
        // Token Enrollment is permissionless or not
        permissioned_enroll: bool,
        #[substorage(v0)]
        pub upgradeable: UpgradeableComponent::Storage,
        #[substorage(v0)]
        pub withdrawal: WithdrawalLimitComponent::Storage,
        #[substorage(v0)]
        pub reentrancy_guard: ReentrancyGuardComponent::Storage,
        #[substorage(v0)]
        pub access_control: AccessControlComponent::Storage,
        #[substorage(v0)]
        pub bridge_access_control: BridgeAccessControlComponent::Storage,
        #[substorage(v0)]
        pub pausable: PausableComponent::Storage,
        #[substorage(v0)]
        pub src5: SRC5Component::Storage,
    }

    //
    // Errors
    //
    pub mod Errors {
        pub const APPCHAIN_BRIDGE_NOT_SET: felt252 = 'L3 bridge not set';
        pub const ZERO_DEPOSIT: felt252 = 'Zero amount';
        pub const ALREADY_ENROLLED: felt252 = 'Token not unknown';
        pub const NOT_ACTIVE: felt252 = 'Token not active';
        pub const DEPLOY_MESSAGE_NOT_PENDING: felt252 = 'Deploy message not Pending';
        pub const DEPOSIT_MESSAGE_NOT_PENDING: felt252 = 'Deposit message not Pending';
        pub const NOT_DEACTIVATED: felt252 = 'Token not deactivated';
        pub const NOT_BLOCKED: felt252 = 'Token not blocked';
        pub const NOT_UNKNOWN: felt252 = 'Only unknown can be blocked';
        pub const NOT_SERVICING: felt252 = 'Only servicing tokens';
        pub const INVALID_RECIPIENT: felt252 = 'Invalid recipient';
        pub const MAX_BALANCE_EXCEEDED: felt252 = 'Max Balance Exceeded';
        pub const TOKENS_NOT_TRANSFERRED: felt252 = 'Tokens not transferred';
        pub const NEW_LIMIT_MUST_BE_GREATER: felt252 = 'New limit must be greater';
        pub const NEW_LIMIT_MUST_BE_SMALLER: felt252 = 'New limit must be smaller';
        pub const WITHDRAWAL_LIMIT_NOT_APPLIED: felt252 = 'Withdrawal limit not applied';
        pub const PERMISSIONED_OR_NOT_TOKEN_ADMIN: felt252 = 'Permissioned or not TokenAdmin';
    }


    #[derive(Drop, starknet::Event)]
    #[event]
    pub enum Event {
        TokenEnrollmentInitiated: TokenEnrollmentInitiated,
        TokenActivated: TokenActivated,
        TokenDeactivated: TokenDeactivated,
        TokenBlocked: TokenBlocked,
        TokenReactivated: TokenReactivated,
        TokenUnblocked: TokenUnblocked,
        TokenUnknown: TokenUnknown,
        Deposit: Deposit,
        DepositWithMessage: DepositWithMessage,
        DepostiCancelRequest: DepositCancelRequest,
        DepositWithMessageCancelRequest: DepositWithMessageCancelRequest,
        DepositReclaimed: DepositReclaimed,
        DepositWithMessageReclaimed: DepositWithMessageReclaimed,
        Withdrawal: Withdrawal,
        WithdrawalLimitIncreased: WithdrawalLimitIncreased,
        WithdrawalLimitDecreased: WithdrawalLimitDecreased,
        SetMaxTotalBalance: SetMaxTotalBalance,
        SetAppchainBridge: SetAppchainBridge,
        ConfigurePermissionedEnrollment: ConfigurePermissionedEnrollment,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        #[flat]
        WithdrawalEvent: WithdrawalLimitComponent::Event,
        #[flat]
        ReentrancyGuardEvent: ReentrancyGuardComponent::Event,
        #[flat]
        AccessControlEvent: AccessControlComponent::Event,
        #[flat]
        BridgeAccessControlEvent: BridgeAccessControlComponent::Event,
        #[flat]
        PausableEvent: PausableComponent::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
    }

    #[derive(Drop, starknet::Event)]
    pub struct TokenActivated {
        pub token: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct TokenDeactivated {
        pub token: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct TokenBlocked {
        pub token: ContractAddress,
    }


    #[derive(Drop, starknet::Event)]
    pub struct TokenUnblocked {
        pub token: ContractAddress,
    }


    #[derive(Drop, starknet::Event)]
    pub struct TokenReactivated {
        pub token: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct TokenUnknown {
        pub token: ContractAddress,
    }


    #[derive(Drop, starknet::Event)]
    pub struct TokenEnrollmentInitiated {
        pub token: ContractAddress,
        pub deployment_message_hash: MessageHash,
    }


    #[derive(Drop, starknet::Event)]
    pub struct Deposit {
        #[key]
        pub sender: ContractAddress,
        #[key]
        pub token: ContractAddress,
        pub amount: u256,
        #[key]
        pub appchain_recipient: ContractAddress,
        pub nonce: felt252,
    }

    #[derive(Drop, starknet::Event)]
    pub struct DepositWithMessage {
        #[key]
        pub sender: ContractAddress,
        #[key]
        pub token: ContractAddress,
        pub amount: u256,
        #[key]
        pub appchain_recipient: ContractAddress,
        pub message: Span<felt252>,
        pub nonce: felt252,
    }

    #[derive(Drop, starknet::Event)]
    pub struct DepositCancelRequest {
        #[key]
        pub sender: ContractAddress,
        #[key]
        pub token: ContractAddress,
        pub amount: u256,
        #[key]
        pub appchain_recipient: ContractAddress,
        pub nonce: felt252,
    }

    #[derive(Drop, starknet::Event)]
    pub struct DepositWithMessageCancelRequest {
        #[key]
        pub sender: ContractAddress,
        #[key]
        pub token: ContractAddress,
        pub amount: u256,
        #[key]
        pub appchain_recipient: ContractAddress,
        pub message: Span<felt252>,
        pub nonce: felt252,
    }

    #[derive(Drop, starknet::Event)]
    pub struct DepositReclaimed {
        #[key]
        pub sender: ContractAddress,
        #[key]
        pub token: ContractAddress,
        pub amount: u256,
        #[key]
        pub appchain_recipient: ContractAddress,
        pub nonce: felt252,
    }

    #[derive(Drop, starknet::Event)]
    pub struct DepositWithMessageReclaimed {
        #[key]
        pub sender: ContractAddress,
        #[key]
        pub token: ContractAddress,
        pub amount: u256,
        #[key]
        pub appchain_recipient: ContractAddress,
        pub message: Span<felt252>,
        pub nonce: felt252,
    }

    #[derive(Drop, starknet::Event)]
    pub struct Withdrawal {
        #[key]
        pub recipient: ContractAddress,
        #[key]
        pub token: ContractAddress,
        pub amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct WithdrawalLimitIncreased {
        #[key]
        pub sender: ContractAddress,
        #[key]
        pub token: ContractAddress,
        pub daily_withdrawal_limit_pct: u8,
    }

    #[derive(Drop, starknet::Event)]
    pub struct WithdrawalLimitDecreased {
        #[key]
        pub sender: ContractAddress,
        #[key]
        pub token: ContractAddress,
        pub daily_withdrawal_limit_pct: u8,
    }

    #[derive(Drop, starknet::Event)]
    pub struct SetMaxTotalBalance {
        #[key]
        pub token: ContractAddress,
        pub value: u256,
    }


    #[derive(Drop, starknet::Event)]
    pub struct SetAppchainBridge {
        pub appchain_bridge: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct ConfigurePermissionedEnrollment {
        pub enabled: bool,
    }


    #[constructor]
    pub fn constructor(
        ref self: ContractState,
        appchain_bridge: ContractAddress,
        messaging_contract: ContractAddress,
        governance_admins: Span<ContractAddress>,
        app_governors: Span<ContractAddress>,
        security_admins: Span<ContractAddress>,
        security_agents: Span<ContractAddress>,
        token_admins: Span<ContractAddress>,
        timelock: ContractAddress,
    ) {
        self.appchain_bridge.write(appchain_bridge);
        self
            .messaging_contract
            .write(IMessagingDispatcher { contract_address: messaging_contract });
        self
            .bridge_access_control
            .initializer(
                governance_admins,
                app_governors,
                security_admins,
                security_agents,
                token_admins,
                timelock,
            );
    }


    #[generate_trait]
    pub impl TokenBridgeInternalImpl of TokenBridgeInternal {
        fn send_deploy_message(self: @ContractState, token: ContractAddress) -> (felt252, felt252) {
            assert(self.appchain_bridge().is_non_zero(), Errors::APPCHAIN_BRIDGE_NOT_SET);

            let (hash, nonce) = self
                .messaging_contract
                .read()
                .send_message_to_appchain(
                    self.appchain_bridge(),
                    constants::HANDLE_TOKEN_DEPLOYMENT_SELECTOR,
                    deployment_message_payload(token),
                );

            assert(
                self
                    .messaging_contract
                    .read()
                    .sn_to_appchain_messages(hash) == MessageToAppchainStatus::Pending(nonce),
                Errors::DEPLOY_MESSAGE_NOT_PENDING,
            );
            return (hash, nonce);
        }

        fn send_deposit_message(
            self: @ContractState,
            token: ContractAddress,
            amount: u256,
            appchain_recipient: ContractAddress,
            message: Span<felt252>,
            selector: felt252,
        ) -> Nonce {
            assert(self.appchain_bridge().is_non_zero(), Errors::APPCHAIN_BRIDGE_NOT_SET);
            assert(amount > 0, Errors::ZERO_DEPOSIT);

            let is_with_message = selector == constants::HANDLE_DEPOSIT_WITH_MESSAGE_SELECTOR;
            let (hash, nonce) = self
                .messaging_contract
                .read()
                .send_message_to_appchain(
                    self.appchain_bridge(),
                    selector,
                    deposit_message_payload(
                        token, amount, appchain_recipient, is_with_message, message,
                    ),
                );

            assert(
                self
                    .messaging_contract
                    .read()
                    .sn_to_appchain_messages(hash) == MessageToAppchainStatus::Pending(nonce),
                Errors::DEPOSIT_MESSAGE_NOT_PENDING,
            );
            nonce
        }

        fn consume_message(
            self: @ContractState, token: ContractAddress, amount: u256, recipient: ContractAddress,
        ) {
            assert(recipient.is_non_zero(), Errors::INVALID_RECIPIENT);

            let appchain_bridge = self.appchain_bridge();
            assert(appchain_bridge.is_non_zero(), Errors::APPCHAIN_BRIDGE_NOT_SET);
            let mut payload = ArrayTrait::new();
            constants::TRANSFER_FROM_APPCHAIN.serialize(ref payload);
            recipient.serialize(ref payload);
            token.serialize(ref payload);
            amount.serialize(ref payload);
            self
                .messaging_contract
                .read()
                .consume_message_from_appchain(appchain_bridge, payload.span());
        }

        fn accept_deposit(self: @ContractState, token: ContractAddress, amount: u256) {
            assert(self.is_servicing_token(token), Errors::NOT_SERVICING);
            let caller = get_caller_address();
            let dispatcher = IERC20Dispatcher { contract_address: token };

            let current_balance: u256 = dispatcher.balance_of(get_contract_address());
            let max_total_balance = self.get_max_total_balance(token);
            assert(current_balance + amount < max_total_balance, Errors::MAX_BALANCE_EXCEEDED);

            let this_address = get_contract_address();
            let initial_balance = dispatcher.balance_of(this_address);
            dispatcher.transfer_from(caller, this_address, amount);
            assert(
                dispatcher.balance_of(this_address) == initial_balance + amount,
                Errors::TOKENS_NOT_TRANSFERRED,
            );
        }
    }


    pub fn deposit_message_payload(
        token: ContractAddress,
        amount: u256,
        appchain_recipient: ContractAddress,
        is_with_message: bool,
        message: Span<felt252>,
    ) -> Span<felt252> {
        let caller = get_caller_address();
        let mut payload = ArrayTrait::new();
        token.serialize(ref payload);
        caller.serialize(ref payload);
        appchain_recipient.serialize(ref payload);
        amount.serialize(ref payload);
        if (is_with_message) {
            message.serialize(ref payload);
        }

        return payload.span();
    }

    fn deserialize_and_append(
        mut value: Span<felt252>, mut calldata: Array<felt252>,
    ) -> Array<felt252> {
        if (value.len() == 1) {
            let value_byte_array = value[0].format_as_byte_array(10);
            value_byte_array.serialize(ref calldata);
        } else {
            let value_byte_array = Serde::<ByteArray>::deserialize(ref value).unwrap();
            value_byte_array.serialize(ref calldata);
        }
        calldata
    }

    pub fn deployment_message_payload(token: ContractAddress) -> Span<felt252> {
        // Create the calldata that will be sent to on_receive. l2_token, amount and
        // depositor are the fields from the deposit context.
        let mut calldata = ArrayTrait::new();
        let dispatcher = IERC20MetadataDispatcher { contract_address: token };
        token.serialize(ref calldata);

        // Openzeppelin erc20 used felt252 as return types for `name()` and `symbol()` before while
        // `ByteArray` is used currently.
        // So we use underlying syscalls, to support both the interface.
        // The returned span is deserialized into to a ByteArray in both cases to make it consistent
        // In case of ByteArray the length of returned span will be at least 3, while exactly 1 for
        // felt252
        let name_selector = selector!("name");
        let mut name = call_contract_syscall(token, name_selector, array![].span())
            .unwrap_syscall();
        calldata = deserialize_and_append(name, calldata);

        let symbol_selector = selector!("symbol");
        let mut symbol = call_contract_syscall(token, symbol_selector, array![].span())
            .unwrap_syscall();
        calldata = deserialize_and_append(symbol, calldata);

        dispatcher.decimals().serialize(ref calldata);
        calldata.span()
    }


    #[abi(embed_v0)]
    impl TokenBrdigeAdminImpl of ITokenBridgeAdmin<ContractState> {
        fn set_appchain_token_bridge(ref self: ContractState, appchain_bridge: ContractAddress) {
            self.bridge_access_control.assert_only_app_governor();
            self.appchain_bridge.write(appchain_bridge);

            self.emit(SetAppchainBridge { appchain_bridge });
        }

        // @dev Only Unknown tokens can be blocked, for stopping deposits on an
        // `Active` token check `deactivate_token()`
        // @param token The address of the token contract to be blocked
        // No return value, but it updates the token's status to 'Blocked'.
        // Emits a `TokenBlocked` event when the blocking is successful.
        // Throws an error if the token is not `Unknown` or if the sender is not the owner.
        fn block_token(ref self: ContractState, token: ContractAddress) {
            self.bridge_access_control.assert_only_token_admin();
            assert(self.get_status(token) == TokenStatus::Unknown, Errors::NOT_UNKNOWN);

            let new_settings = TokenSettings {
                token_status: TokenStatus::Blocked, ..self.token_settings.read(token),
            };
            self.token_settings.write(token, new_settings);
            self.emit(TokenBlocked { token });
        }

        // @dev This unblocks a token which can be enrolled now
        // @param token The address of the token to unblock
        fn unblock_token(ref self: ContractState, token: ContractAddress) {
            self.bridge_access_control.assert_only_token_admin();
            assert(self.get_status(token) == TokenStatus::Blocked, Errors::NOT_BLOCKED);

            let new_settings = TokenSettings {
                token_status: TokenStatus::Unknown, ..self.token_settings.read(token),
            };
            self.token_settings.write(token, new_settings);
            self.emit(TokenUnblocked { token });
        }

        // @dev Only `Active` tokens can be deactivated. For `Unknown` tokens
        // check `block_token()`
        // @param token The token to be deactivated
        fn deactivate_token(ref self: ContractState, token: ContractAddress) {
            self.bridge_access_control.assert_only_token_admin();
            let status = self.get_status(token);
            assert(status == TokenStatus::Active, Errors::NOT_ACTIVE);

            let new_settings = TokenSettings {
                token_status: TokenStatus::Deactivated, ..self.token_settings.read(token),
            };
            self.token_settings.write(token, new_settings);

            self.emit(TokenDeactivated { token });
        }

        // @dev This is reactivates back a token to `Active` that was deactivated
        // @param token The address of the token to be reactivated
        fn reactivate_token(ref self: ContractState, token: ContractAddress) {
            self.bridge_access_control.assert_only_token_admin();
            let status = self.get_status(token);
            assert(status == TokenStatus::Deactivated, Errors::NOT_DEACTIVATED);

            let new_settings = TokenSettings {
                token_status: TokenStatus::Active, ..self.token_settings.read(token),
            };
            self.token_settings.write(token, new_settings);

            self.emit(TokenReactivated { token });
        }

        // @dev This can be used to enable or disable permissioned enrollment
        // @param permissioned_enroll The boolean value to set the permissioned enrollment to
        fn configure_permissioned_enrollment(ref self: ContractState, permissioned_enroll: bool) {
            self.bridge_access_control.assert_only_app_governor();
            self.permissioned_enroll.write(permissioned_enroll);

            self.emit(ConfigurePermissionedEnrollment { enabled: permissioned_enroll });
        }


        // @dev This can be used to enable daily withdrawal limits on a token,
        // @param token The address of the token on which to enable withdrawal limit
        fn increase_withdrawal_limit(
            ref self: ContractState, token: ContractAddress, daily_withdrawal_limit_pct: u8,
        ) {
            self.bridge_access_control.assert_only_security_admin();

            let current_pct = self.withdrawal.get_daily_withdrawal_limit_pct(token);
            assert(daily_withdrawal_limit_pct > current_pct, Errors::NEW_LIMIT_MUST_BE_GREATER);
            self.withdrawal.write_daily_withdrawal_limit_pct(token, daily_withdrawal_limit_pct);

            self
                .emit(
                    WithdrawalLimitIncreased {
                        sender: get_caller_address(), token, daily_withdrawal_limit_pct,
                    },
                );
        }


        // @notice This can only be called by the security agent
        // @dev This can be used to decrease daily withdrawal limits on a token,
        // @param token The address of the token on which to decrease withdrawal limit
        fn decrease_withdrawal_limit(
            ref self: ContractState, token: ContractAddress, daily_withdrawal_limit_pct: u8,
        ) {
            self.bridge_access_control.assert_only_security_agent();

            let current_pct = self.withdrawal.get_daily_withdrawal_limit_pct(token);
            assert(daily_withdrawal_limit_pct < current_pct, Errors::NEW_LIMIT_MUST_BE_SMALLER);
            self.withdrawal.write_daily_withdrawal_limit_pct(token, daily_withdrawal_limit_pct);

            self
                .emit(
                    WithdrawalLimitDecreased {
                        sender: get_caller_address(), token, daily_withdrawal_limit_pct,
                    },
                );
        }


        // @notice This can only be called by the security admin
        // @dev This can be used to disable daily withdrawal limits on a token,
        // sets the limit to 100%
        // @param token The address of the token on which to disable withdrawal limit
        fn disable_withdrawal_limit(ref self: ContractState, token: ContractAddress) {
            self.bridge_access_control.assert_only_security_admin();
            assert(
                self.withdrawal.is_withdrawal_limit_applied(token),
                Errors::WITHDRAWAL_LIMIT_NOT_APPLIED,
            );

            // To disable the limit, we set the limit to 100%
            self.increase_withdrawal_limit(token, 100);
        }

        // Use this to add a max total balance on the token. Beyond this value no more deposits
        // will be accepted. In case of L3 this would mean the maximum supply of token that
        // can be taken from L2 to L3
        fn set_max_total_balance(
            ref self: ContractState, token: ContractAddress, max_total_balance: u256,
        ) {
            self.bridge_access_control.assert_only_app_governor();
            let new_settings = TokenSettings {
                max_total_balance: max_total_balance, ..self.token_settings.read(token),
            };
            self.token_settings.write(token, new_settings);
            self.emit(SetMaxTotalBalance { token, value: max_total_balance });
        }

        // This function is used to pause the contract.
        // It can only be called by the security agent.
        // The function checks if the contract is not already paused
        fn pause(ref self: ContractState) {
            self.pausable.assert_not_paused();
            self.bridge_access_control.assert_only_security_agent();
            self.pausable.pause();
        }

        // This function is used to unpause the contract.
        // It can only be called by the security admin.
        // The function checks if the contract is paused
        fn unpause(ref self: ContractState) {
            self.pausable.assert_paused();
            self.bridge_access_control.assert_only_security_admin();
            self.pausable.unpause();
        }
    }

    #[abi(embed_v0)]
    impl TokenBridgeImpl of ITokenBridge<ContractState> {
        fn appchain_bridge(self: @ContractState) -> ContractAddress {
            return self.appchain_bridge.read();
        }

        fn get_identity(self: @ContractState) -> felt252 {
            constants::CONTRACT_IDENTITY
        }

        fn get_version(self: @ContractState) -> felt252 {
            constants::CONTRACT_VERSION
        }


        //    Initiates the enrollment of a token into the system.
        //    This function is used to initiate the enrollment process of a token.
        //    The token is marked as 'Pending' because the success of the deployment is uncertain at
        //    this stage.
        //    The deployment message's existence is checked, indicating that deployment has been
        //    attempted.
        //    The success of the deployment is determined at a later stage during the application's
        //    lifecycle.
        //    The function is permissionless and can be called by anyone
        //
        //    @param token The address of the token contract to be enrolled.
        //    No return value, but it updates the token's status to 'Pending' and records the
        //    deployment message and expiration time.
        //    Emits a `TokenEnrollmentInitiated` event when the enrollment is initiated.
        //    Throws an error if the sender is not the manager or if the deployment message does not
        //    exist.

        fn enroll_token(ref self: ContractState, token: ContractAddress) {
            self.pausable.assert_not_paused();
            self.reentrancy_guard.start();

            let caller = get_caller_address();
            let is_token_admin = self.bridge_access_control.has_role(Roles::TOKEN_ADMIN, caller);
            assert(
                !self.permissioned_enroll.read() || is_token_admin,
                Errors::PERMISSIONED_OR_NOT_TOKEN_ADMIN,
            );

            assert(self.get_status(token) == TokenStatus::Unknown, Errors::ALREADY_ENROLLED);

            // Send message to appchain
            let (deployment_message_hash, deployment_message_nonce) = self
                .send_deploy_message(token);
            // Reading existing settings as withdrawal_limit_applied and max_total_balance
            // can be set before the token is enrolled.
            let old_settings = self.token_settings.read(token);
            let new_settings = TokenSettings {
                token_status: TokenStatus::Pending,
                deployment_message_hash: deployment_message_hash,
                deployment_message_nonce: deployment_message_nonce,
                pending_deployment_expiration: get_block_timestamp()
                    + constants::MAX_PENDING_DURATION.try_into().unwrap(),
                ..old_settings,
            };

            self.token_settings.write(token, new_settings);
            self.emit(TokenEnrollmentInitiated { token, deployment_message_hash });

            self.reentrancy_guard.end();
        }

        // @dev Used to create a deposit of for the token,
        // which sends a l2-l3 message to mint the user `amount` tokens
        // @param token: Address of the token to deposit
        // @param amount: quantity of tokens
        // @param appchain_recipient: address of the recipient on l3
        fn deposit(
            ref self: ContractState,
            token: ContractAddress,
            amount: u256,
            appchain_recipient: ContractAddress,
        ) {
            self.pausable.assert_not_paused();
            self.reentrancy_guard.start();

            let no_message: Span<felt252> = array![].span();
            self.check_deployment_status(token);
            self.accept_deposit(token, amount);

            let nonce = self
                .send_deposit_message(
                    token,
                    amount,
                    appchain_recipient,
                    no_message.clone(),
                    constants::HANDLE_TOKEN_DEPOSIT_SELECTOR,
                );

            let caller = get_caller_address();
            self.emit(Deposit { sender: caller, token, amount, appchain_recipient, nonce });

            self.reentrancy_guard.end();
        }

        // @dev This is function is used if one intends to make a contract call
        // post the deposit on l3. The calldata can be passed in `message` parameter
        // `deposit()` funciton is maintained to diverge as less as possible from Starkgate(L1-L2
        // bridges)
        fn deposit_with_message(
            ref self: ContractState,
            token: ContractAddress,
            amount: u256,
            appchain_recipient: ContractAddress,
            message: Span<felt252>,
        ) {
            self.pausable.assert_not_paused();

            self.reentrancy_guard.start();
            // Piggy-back the deposit tx to check and update the status of token bridge deployment.
            self.check_deployment_status(token);

            self.accept_deposit(token, amount);
            let nonce = self
                .send_deposit_message(
                    token,
                    amount,
                    appchain_recipient,
                    message,
                    constants::HANDLE_DEPOSIT_WITH_MESSAGE_SELECTOR,
                );

            let caller = get_caller_address();
            self
                .emit(
                    DepositWithMessage {
                        sender: caller, token, amount, appchain_recipient, message, nonce,
                    },
                );

            self.reentrancy_guard.end();
        }

        //     checks token deployment status.
        //     relies on l3 clearing l2-l3 message upon successful completion of deployment.
        //     processing: check the l2-l3 deployment message. set status to `Active` if consumed.
        //     if not consumed after the expected duration, it returns the status to `Unknown`.
        fn check_deployment_status(ref self: ContractState, token: ContractAddress) {
            self.pausable.assert_not_paused();
            let settings = self.token_settings.read(token);
            if (settings.token_status != TokenStatus::Pending) {
                return;
            }

            let message_status = self
                .messaging_contract
                .read()
                .sn_to_appchain_messages(settings.deployment_message_hash);

            if (message_status == MessageToAppchainStatus::Sealed) {
                let new_settings = TokenSettings { token_status: TokenStatus::Active, ..settings };
                self.token_settings.write(token, new_settings);
                self.emit(TokenActivated { token });
            } else if (message_status != MessageToAppchainStatus::Cancelling
                && get_block_timestamp() > settings.pending_deployment_expiration) {
                self
                    .messaging_contract
                    .read()
                    .start_message_cancellation(
                        self.appchain_bridge(),
                        constants::HANDLE_TOKEN_DEPLOYMENT_SELECTOR,
                        deployment_message_payload(token),
                        settings.deployment_message_nonce,
                    );
            } else if (message_status == MessageToAppchainStatus::Cancelled) {
                let new_settings = TokenSettings { token_status: TokenStatus::Unknown, ..settings };
                self.token_settings.write(token, new_settings);

                self.emit(TokenUnknown { token });
            }
        }


        // For withdrawing
        // 1. the user burns the tokens on l3, which registers
        // a message on the messaging contract (piltover).
        //
        // 2. Calls `withdraw()` which consumes the message in the piltover
        // and transfers the tokens to the `recipient`
        fn withdraw(
            ref self: ContractState,
            token: ContractAddress,
            amount: u256,
            recipient: ContractAddress,
        ) {
            self.pausable.assert_not_paused();
            self.reentrancy_guard.start();

            self.consume_message(token, amount, recipient);

            assert(recipient.is_non_zero(), Errors::INVALID_RECIPIENT);
            self.withdrawal.consume_withdrawal_quota(token, amount);

            let tokenDispatcher = IERC20Dispatcher { contract_address: token };

            let this_address = get_contract_address();
            let initial_balance = tokenDispatcher.balance_of(this_address);

            tokenDispatcher.transfer(recipient, amount);

            assert(
                tokenDispatcher.balance_of(this_address) == initial_balance - amount,
                Errors::TOKENS_NOT_TRANSFERRED,
            );
            self.reentrancy_guard.end();

            self.emit(Withdrawal { recipient, token, amount });
        }

        // /*
        //   A deposit cancellation requires two steps:
        //   1. The depositor should send a `deposit_cancel_request()` request with deposit details
        //   & nonce.
        //   2. After a predetermined time (cancellation delay), the depositor can claim back the
        //   funds by
        //      calling `deposit_reclaim` (using the same arguments).
        //
        //   Note: As long as the `deposit_reclaim` was not performed, the deposit may be processed,
        //   even if
        //         the cancellation delay time has already passed. Only the depositor is allowed to
        //         cancel a deposit, and only before `deposit_reclaim` was performed.
        // */
        fn deposit_cancel_request(
            ref self: ContractState,
            token: ContractAddress,
            amount: u256,
            appchain_recipient: ContractAddress,
            nonce: Nonce,
        ) {
            self.pausable.assert_not_paused();
            self.reentrancy_guard.start();

            let no_message: Span<felt252> = array![].span();
            self
                .messaging_contract
                .read()
                .start_message_cancellation(
                    self.appchain_bridge(),
                    constants::HANDLE_TOKEN_DEPOSIT_SELECTOR,
                    deposit_message_payload(token, amount, appchain_recipient, false, no_message),
                    nonce,
                );
            self
                .emit(
                    DepositCancelRequest {
                        sender: get_caller_address(), token, amount, appchain_recipient, nonce,
                    },
                );

            self.reentrancy_guard.end();
        }

        // @dev If the deposit was initiated by `deposit_with_message()` then use this.
        // If not check `deposit_cancel_request()`
        fn deposit_with_message_cancel_request(
            ref self: ContractState,
            token: ContractAddress,
            amount: u256,
            appchain_recipient: ContractAddress,
            message: Span<felt252>,
            nonce: Nonce,
        ) {
            self.pausable.assert_not_paused();
            self.reentrancy_guard.start();

            self
                .messaging_contract
                .read()
                .start_message_cancellation(
                    self.appchain_bridge(),
                    constants::HANDLE_DEPOSIT_WITH_MESSAGE_SELECTOR,
                    deposit_message_payload(token, amount, appchain_recipient, true, message),
                    nonce,
                );
            self
                .emit(
                    DepositWithMessageCancelRequest {
                        sender: get_caller_address(),
                        token,
                        amount,
                        appchain_recipient,
                        message,
                        nonce,
                    },
                );

            self.reentrancy_guard.end();
        }

        // Similar to `deposit_reclaim()` with the difference of deposit initiated with
        // `deposit_with_message()`
        fn deposit_with_message_reclaim(
            ref self: ContractState,
            token: ContractAddress,
            amount: u256,
            appchain_recipient: ContractAddress,
            message: Span<felt252>,
            nonce: Nonce,
        ) {
            self.pausable.assert_not_paused();
            self.reentrancy_guard.start();
            self
                .messaging_contract
                .read()
                .cancel_message(
                    self.appchain_bridge(),
                    constants::HANDLE_DEPOSIT_WITH_MESSAGE_SELECTOR,
                    deposit_message_payload(token, amount, appchain_recipient, true, message),
                    nonce,
                );

            let dispatcher = IERC20Dispatcher { contract_address: token };
            let initial_balance = dispatcher.balance_of(get_contract_address());

            dispatcher.transfer(get_caller_address(), amount);

            assert(
                dispatcher.balance_of(get_contract_address()) == initial_balance - amount,
                Errors::TOKENS_NOT_TRANSFERRED,
            );

            self.reentrancy_guard.end();

            self
                .emit(
                    DepositWithMessageReclaimed {
                        sender: get_caller_address(),
                        token,
                        amount,
                        appchain_recipient,
                        message,
                        nonce,
                    },
                );
        }

        // After the `cancellation delay time` has passed of the generating the cancellation request
        // a valid message can be cancelled.
        fn deposit_reclaim(
            ref self: ContractState,
            token: ContractAddress,
            amount: u256,
            appchain_recipient: ContractAddress,
            nonce: Nonce,
        ) {
            self.pausable.assert_not_paused();
            self.reentrancy_guard.start();
            let no_message: Span<felt252> = array![].span();
            self
                .messaging_contract
                .read()
                .cancel_message(
                    self.appchain_bridge(),
                    constants::HANDLE_TOKEN_DEPOSIT_SELECTOR,
                    deposit_message_payload(token, amount, appchain_recipient, false, no_message),
                    nonce,
                );

            let dispatcher = IERC20Dispatcher { contract_address: token };

            let initial_balance = dispatcher.balance_of(get_contract_address());

            dispatcher.transfer(get_caller_address(), amount);
            assert(
                dispatcher.balance_of(get_contract_address()) == initial_balance - amount,
                Errors::TOKENS_NOT_TRANSFERRED,
            );

            self.reentrancy_guard.end();

            self
                .emit(
                    DepositReclaimed {
                        sender: get_caller_address(), token, amount, appchain_recipient, nonce,
                    },
                );
        }


        fn get_status(self: @ContractState, token: ContractAddress) -> TokenStatus {
            self.token_settings.read(token).token_status
        }

        fn is_servicing_token(self: @ContractState, token: ContractAddress) -> bool {
            self.token_settings.read(token).token_status == TokenStatus::Active
        }

        fn is_enrollment_permissionless(self: @ContractState) -> bool {
            !self.permissioned_enroll.read()
        }

        fn get_max_total_balance(self: @ContractState, token: ContractAddress) -> u256 {
            let max_total_balance = self.token_settings.read(token).max_total_balance;
            if (max_total_balance == 0) {
                return Bounded::MAX;
            }
            return max_total_balance;
        }

        fn get_appchain_token_bridge(self: @ContractState) -> ContractAddress {
            self.appchain_bridge.read()
        }
    }


    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            // This function can only be called by the owner
            self.bridge_access_control.assert_only_upgrade_governor();

            // Replace the class hash upgrading the contract
            self.upgradeable.upgrade(new_class_hash);
        }
    }
}

