#[starknet::contract]
pub mod TokenBridge {
    use core::option::OptionTrait;
    use core::traits::TryInto;
    use core::starknet::event::EventEmitter;
    use core::traits::PanicDestruct;
    use core::array::ArrayTrait;
    use core::serde::Serde;
    use openzeppelin::token::erc20::interface::{
        IERC20Dispatcher, IERC20MetadataDispatcher, IERC20DispatcherTrait,
        IERC20MetadataDispatcherTrait
    };
    use core::num::traits::zero::Zero;
    use starknet::{ContractAddress, get_contract_address, get_caller_address, get_block_timestamp};

    use cairo_appchain_bridge::bridge::interface::{TokenStatus, TokenSettings, ITokenBridge};
    use piltover::messaging::interface::IMessagingDispatcher;
    use piltover::messaging::interface::IMessagingDispatcherTrait;
    // use cairo_appchain_bridge::interfaces::IMessaging::{
    //     IMessagingDispatcherTrait, IMessagingDispatcher
    // };
    use cairo_appchain_bridge::constants;

    #[storage]
    struct Storage {
        appchain_bridge: ContractAddress,
        // manager: ContractAddress,
        messaging_contract: IMessagingDispatcher,
        token_settings: LegacyMap<ContractAddress, TokenSettings>
    }
    // 
    // Errors 
    //
    pub mod Errors {
        pub const APPCHAIN_BRIDGE_NOT_SET: felt252 = 'L3 bridge not set';
        pub const ZERO_DEPOSIT: felt252 = 'Zero amount';
        pub const ALREADY_ENROLLED: felt252 = 'Already enrolled';
        pub const DEPLOYMENT_MESSAGE_NOT_EXIST: felt252 = 'Deployment message inexistent';
    }
    #[derive(Drop, starknet::Event)]
    #[event]
    enum Event {
        TokenEnrollmentInitiated: TokenEnrollmentInitiated,
        TokenDeactivated: TokenDeactivated,
        Deposit: Deposit,
        DepositWithMessage: DepositWithMessage,
        DepostiCancelRequest: DepositCancelRequest,
        DepositWithMessageCancelRequest: DepositWithMessageCancelRequest,
        DepositReclaimed: DepositReclaimed,
        DepositWithMessageReclaimed: DepositWithMessageReclaimed,
        Withdrawal: Withdrawal,
        WithdrawalLimitEnabled: WithdrawalLimitEnabled,
        WithdrawalLimitDisabled: WithdrawalLimitDisabled
    }

    #[derive(Drop, starknet::Event)]
    struct TokenDeactivated {
        token: ContractAddress
    }

    #[derive(Drop, starknet::Event)]
    struct TokenEnrollmentInitiated {
        token: ContractAddress,
        deployment_message_hash: felt252
    }


    #[derive(Drop, starknet::Event)]
    struct Deposit {
        #[key]
        sender: ContractAddress,
        #[key]
        token: ContractAddress,
        amount: u256,
        #[key]
        appchain_recipient: ContractAddress,
        nonce: felt252,
        fee: felt252
    }

    #[derive(Drop, starknet::Event)]
    struct DepositWithMessage {
        #[key]
        sender: ContractAddress,
        #[key]
        token: ContractAddress,
        amount: u256,
        #[key]
        appchain_recipient: ContractAddress,
        message: Span<felt252>,
        nonce: felt252,
        fee: felt252
    }

    #[derive(Drop, starknet::Event)]
    struct DepositCancelRequest {
        #[key]
        sender: ContractAddress,
        #[key]
        token: ContractAddress,
        amount: u256,
        #[key]
        appchain_recipient: ContractAddress,
        nonce: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct DepositWithMessageCancelRequest {
        #[key]
        sender: ContractAddress,
        #[key]
        token: ContractAddress,
        amount: u256,
        #[key]
        appchain_recipient: ContractAddress,
        message: Span<felt252>,
        nonce: felt252
    }

    #[derive(Drop, starknet::Event)]
    struct DepositReclaimed {
        #[key]
        sender: ContractAddress,
        #[key]
        token: ContractAddress,
        amount: u256,
        #[key]
        appchain_recipient: ContractAddress,
        nonce: felt252
    }

    #[derive(Drop, starknet::Event)]
    struct DepositWithMessageReclaimed {
        #[key]
        sender: ContractAddress,
        #[key]
        token: ContractAddress,
        amount: u256,
        #[key]
        appchain_recipient: ContractAddress,
        message: Span<felt252>,
        nonce: felt252
    }

    #[derive(Drop, starknet::Event)]
    struct Withdrawal {
        #[key]
        recipient: ContractAddress,
        #[key]
        token: ContractAddress,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct WithdrawalLimitEnabled {
        #[key]
        sender: ContractAddress,
        #[key]
        token: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct WithdrawalLimitDisabled {
        #[key]
        sender: ContractAddress,
        #[key]
        token: ContractAddress,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        appchain_bridge: ContractAddress,
        messaging_contract: ContractAddress
    ) {
        self.appchain_bridge.write(appchain_bridge);
        self
            .messaging_contract
            .write(IMessagingDispatcher { contract_address: messaging_contract });
    }


    #[generate_trait]
    impl TokenBridgeInternalImpl of TokenBridgeInternal {
        fn deployment_message_payload(
            self: @ContractState, token: ContractAddress
        ) -> Span<felt252> {
            // Create the calldata that will be sent to on_receive. l2_token, amount and
            // depositor are the fields from the deposit context.
            let mut calldata = ArrayTrait::new();
            let dispatcher = IERC20MetadataDispatcher { contract_address: token };
            dispatcher.name().serialize(ref calldata);
            dispatcher.symbol().serialize(ref calldata);
            dispatcher.decimals().serialize(ref calldata);
            calldata.span()
        }

        // function acceptDeposit(address token, uint256 amount) internal virtual returns (uint256) {
        //     Fees.checkFee(msg.value);
        //     uint256 currentBalance = IERC20(token).balanceOf(address(this));
        //     require(currentBalance + amount <= getMaxTotalBalance(token), "MAX_BALANCE_EXCEEDED");
        //     Transfers.transferIn(token, msg.sender, amount);
        //     return msg.value;
        // }

        fn accept_deposit(self: @ContractState, token: ContractAddress, amount: u256) -> felt252 {
            // TODO: check fees (not sure if needed)

            let caller = get_caller_address();
            let dispatcher = IERC20Dispatcher { contract_address: token };
            assert(dispatcher.balance_of(caller) == amount, 'Not enough balance');
            dispatcher.transfer_from(caller, get_contract_address(), amount);
            // TODO: Should we return fee here
            let fee = 0;
            return fee;
        }

        // function sendDeployMessage(address token) internal returns (bytes32) {
        //     require(l2TokenBridge() != 0, "L2_BRIDGE_NOT_SET");
        //     Fees.checkFee(msg.value);
        //
        //     (bytes32 deploymentMsgHash, ) = messagingContract().sendMessageToL2{value: msg.value}(
        //         l2TokenBridge(),
        //         HANDLE_TOKEN_DEPLOYMENT_SELECTOR,
        //         deployMessagePayload(token)
        //     );
        //     return deploymentMsgHash;
        // }
        fn send_deploy_message(self: @ContractState, token: ContractAddress) -> felt252 {
            assert(self.appchain_bridge().is_non_zero(), Errors::APPCHAIN_BRIDGE_NOT_SET);
            // TODO: Check fees not sure if needed

            // TODO: Add the token deployment selector as a constant here
            let (hash, _nonce) = self
                .messaging_contract
                .read()
                .send_message_to_appchain(
                    self.appchain_bridge(),
                    constants::HANDLE_TOKEN_DEPLOYMENT_SELECTOR,
                    self.deployment_message_payload(token)
                );
            return hash;
        }

        fn emit_deposit_event(
            ref self: ContractState,
            token: ContractAddress,
            amount: u256,
            appchain_recipient: ContractAddress,
            no_message: Span<felt252>,
            selector: felt252,
            nonce: felt252,
            fee: felt252
        ) {
            let is_with_message = selector == constants::HANDLE_DEPOSIT_WITH_MESSAGE_SELECTOR;
            let caller = get_caller_address();
            if (is_with_message) {
                self
                    .emit(
                        Deposit {
                            sender: caller,
                            token: token,
                            amount: amount,
                            appchain_recipient: appchain_recipient,
                            nonce: nonce,
                            fee
                        }
                    );
            } else {
                assert(selector == constants::HANDLE_DEPOSIT_SELECTOR, 'Unknown Selector');
                self
                    .emit(
                        Deposit {
                            sender: caller,
                            token: token,
                            amount: amount,
                            appchain_recipient: appchain_recipient,
                            nonce: nonce,
                            fee
                        }
                    )
            }
        }

        fn send_deposit_message(
            self: @ContractState,
            token: ContractAddress,
            amount: u256,
            appchain_recipient: ContractAddress,
            message: Span<felt252>,
            selector: felt252,
            fee: felt252
        ) -> felt252 {
            assert(self.appchain_bridge().is_non_zero(), Errors::APPCHAIN_BRIDGE_NOT_SET);
            assert(amount > 0, Errors::ZERO_DEPOSIT);

            let is_with_message = selector == constants::HANDLE_DEPOSIT_WITH_MESSAGE_SELECTOR;
            let (_, nonce) = self
                .messaging_contract
                .read()
                .send_message_to_appchain(
                    self.appchain_bridge.read(),
                    selector,
                    deposit_message_payload(
                        token, amount, appchain_recipient, is_with_message, message
                    )
                );
            return nonce;
        }
    }


    fn deposit_message_payload(
        token: ContractAddress,
        amount: u256,
        appchain_recipient: ContractAddress,
        is_with_message: bool,
        message: Span<felt252>
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


    #[abi(embed_v0)]
    impl TokenBridgeImpl of ITokenBridge<ContractState> {
        fn appchain_bridge(self: @ContractState) -> ContractAddress {
            return self.appchain_bridge.read();
        }

        fn identity(self: @ContractState) -> ByteArray {
            "cairo_appchain_bridge"
        }

        // /**
        //     Initiates the enrollment of a token into the system.
        //     This function is used to initiate the enrollment process of a token.
        //     The token is marked as 'Pending' because the success of the deployment is uncertain at this stage.
        //     The deployment message's existence is checked, indicating that deployment has been attempted.
        //     The success of the deployment is determined at a later stage during the application's lifecycle.
        //     Only the manager, who initiates the deployment, can call this function.
        //
        //     @param token The address of the token contract to be enrolled.
        //     No return value, but it updates the token's status to 'Pending' and records the deployment message and expiration time.
        //     Emits a `TokenEnrollmentInitiated` event when the enrollment is initiated.
        //     Throws an error if the sender is not the manager or if the deployment message does not exist.
        //  */
        // function enrollToken(address token) external payable virtual onlyManager {
        //     require(
        //         tokenSettings()[token].tokenStatus == TokenStatus.Unknown,
        //         "TOKEN_ALREADY_ENROLLED"
        //     );
        //     // send message.
        //     bytes32 deploymentMsgHash = sendDeployMessage(token);
        //
        //     require(
        //         messagingContract().l1ToL2Messages(deploymentMsgHash) > 0,
        //         "DEPLOYMENT_MESSAGE_NOT_EXIST"
        //     );
        //     tokenSettings()[token].tokenStatus = TokenStatus.Pending;
        //     tokenSettings()[token].deploymentMsgHash = deploymentMsgHash;
        //     tokenSettings()[token].pendingDeploymentExpiration = block.timestamp + MAX_PENDING_DURATION;
        //     emit TokenEnrollmentInitiated(token, deploymentMsgHash);
        // }

        fn enroll_token(ref self: ContractState, token: ContractAddress) {
            let status = self.token_settings.read(token).token_status;
            assert(status == TokenStatus::Unknown, Errors::ALREADY_ENROLLED);

            // Send message to appchain
            let deployment_message_hash = self.send_deploy_message(token);

            // TODO: check the deployment msg has been sent by calling l1ToL2Messages() > 0

            // Dep(piltover): Will uncomment once piltover updates interface
            // let nonce = self
            //     .messaging_contract
            //     .read()
            //     .sn_to_appchain_messages(deployment_message_hash);
            // assert(nonce > 0, Errors::DEPLOYMENT_MESSAGE_NOT_EXIST);

            let token_status = TokenSettings {
                token_status: TokenStatus::Pending,
                deployment_message_hash: deployment_message_hash,
                pending_deployment_expiration: get_block_timestamp()
                    + constants::MAX_PENDING_DURATION.try_into().unwrap(),
                max_total_balance: core::integer::BoundedInt::max(),
                withdrawal_limit_applied: false
            };

            self.token_settings.write(token, token_status);
            self.emit(TokenEnrollmentInitiated { token, deployment_message_hash });
        }

        // function deposit(
        //     address token,
        //     uint256 amount,
        //     uint256 l2Recipient
        // ) external payable onlyServicingToken(token) {
        //     uint256[] memory noMessage = new uint256[](0);
        //     uint256 fee = acceptDeposit(token, amount);
        //     uint256 nonce = sendDepositMessage(
        //         token,
        //         amount,
        //         l2Recipient,
        //         noMessage,
        //         HANDLE_TOKEN_DEPOSIT_SELECTOR,
        //         fee
        //     );
        //     emitDepositEvent(
        //         token,
        //         amount,
        //         l2Recipient,
        //         noMessage,
        //         HANDLE_TOKEN_DEPOSIT_SELECTOR,
        //         nonce,
        //         fee
        //     );
        //
        //     // Piggy-back the deposit tx to check and update the status of token bridge deployment.
        //     checkDeploymentStatus(token);
        // }
        fn deposit(
            ref self: ContractState,
            token: ContractAddress,
            amount: u256,
            appchain_recipient: ContractAddress
        ) {
            let no_message: Span<felt252> = array![].span();
            let fee = self.accept_deposit(token, amount);
            let nonce = self
                .send_deposit_message(
                    token,
                    amount,
                    appchain_recipient,
                    no_message.clone(),
                    constants::HANDLE_TOKEN_DEPOSIT_SELECTOR,
                    fee
                );
            self
                .emit_deposit_event(
                    token,
                    amount,
                    appchain_recipient,
                    no_message,
                    constants::HANDLE_TOKEN_DEPOSIT_SELECTOR,
                    nonce,
                    fee
                );
            self.check_deployment_status(token);
        }


        //
        //     checks token deployment status.
        //     relies on starknet clearing l1-l2 message upon successful completion of deployment.
        //     processing: check the l1-l2 deployment message. set status to `active` if consumed.
        //     if not consumed after the expected duration, it returns the status to unknown.
        //
        fn check_deployment_status(ref self: ContractState, token: ContractAddress) {
            let settings = self.token_settings.read(token);
            if (settings.token_status == TokenStatus::Pending) {
                return;
            }

            let _msg_hash = settings.deployment_message_hash;
        // DEP(piltover) : to uncomment once the interface of piltover changes
        // if (self.messaging_contract.read().sn_to_appchain_messages(msg_hash) > 0) {
        //     let new_settings = TokenSettings {
        //         token_status: TokenStatus::Active, ..settings
        //     };
        //     self.token_settings.write(token, new_settings);
        // } else if (get_block_timestamp() > settings.pending_deployment_expiration) {
        //     let new_settings = TokenSettings {
        //         token_status: TokenStatus::Unknown,
        //         deployment_msg_hash: 0,
        //         pending_deployment_expiration: 0,
        //         max_total_balance: 0,
        //         withdrawal_limit_applied: false
        //     };
        //     self.token_settings.write(token, new_settings);
        // }

        }

        // Deactivates a token in the system.
        // This function is used to deactivate a token that was previously enrolled.
        // Only the manager, who initiated the enrollment, can call this function.
        //
        // @param token The address of the token contract to be deactivated.
        // No return value, but it updates the token's status to 'Deactivated'.
        // Emits a `TokenDeactivated` event when the deactivation is successful.
        // Throws an error if the token is not enrolled or if the sender is not the manager.
        fn deactivate_token(ref self: ContractState, token: ContractAddress) {
            let settings = self.token_settings.read(token);
            assert(settings.token_status != TokenStatus::Unknown, 'UNKNOWN_TOKEN');
            let new_settings = TokenSettings { token_status: TokenStatus::Deactivated, ..settings };
            self.token_settings.write(token, new_settings);
            self.emit(TokenDeactivated { token });
        }

        fn getStatus(self: @ContractState, token: ContractAddress) -> TokenStatus {
            self.token_settings.read(token).token_status
        }

        fn isServicingToken(self: @ContractState, token: ContractAddress) -> bool {
            self.token_settings.read(token).token_status == TokenStatus::Active
        }

        // /**
        //     Returns the remaining amount of withdrawal allowed for this day.
        //     If the daily allowance was not yet set, it is calculated and returned.
        //     If the withdraw limit is not enabled for that token - the uint256.max is returned.
        //  */
        // function getRemainingIntradayAllowance(address token) external view returns (uint256) {
        //     return
        //         tokenSettings()[token].withdrawalLimitApplied
        //             ? WithdrawalLimit.getRemainingIntradayAllowance(token)
        //             : type(uint256).max;
        // }
        fn get_remaining_intraday_allowance(token: ContractAddress) -> u256 {
            self.token_settings.read(token);
        }
    }
}

