use starknet::ContractAddress;


#[starknet::interface]
pub trait ITokenBridge<TContractState> {
    fn identity(self: @TContractState) -> ByteArray;
    fn enroll_token(ref self: TContractState, token: ContractAddress);
}


#[starknet::contract]
mod TokenBridge {
    use core::array::ArrayTrait;
    use core::serde::Serde;
    use openzeppelin::token::erc20::interface::IERC20MetadataDispatcherTrait;
    use piltover::messaging::interface::IMessagingDispatcherTrait;
    use openzeppelin::token::erc20::interface::IERC20DispatcherTrait;
    use core::num::traits::zero::Zero;
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20MetadataDispatcher};
    use piltover::messaging::interface::IMessagingDispatcher;

    #[derive(Serde, Drop, starknet::Store, PartialEq)]
    enum TokenStatus {
        Unknown,
        Pending,
        Active,
        Deactivated
    }


    #[derive(Serde, Drop, starknet::Store)]
    struct TokenSettings {
        token_status: TokenStatus,
        deployment_msg_hash: felt252,
        pending_deployment_expiration: u64,
        max_total_balance: u256,
        withdrawal_limit_applied: bool
    }

    #[storage]
    struct Storage {
        l3_bridge: ContractAddress,
        manager: ContractAddress,
        messaging_contract: ContractAddress,
        token_settings: LegacyMap<ContractAddress, TokenSettings>
    }

    // 
    // Errors 
    //
    pub mod Errors {
        pub const L2_BRIDGE_NOT_SET: felt252 = 'TokenBridge: l2 bridge not set';
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

        fn l2_token_bridge(self: @ContractState) -> ContractAddress {
            return self.l3_bridge.read();
        }

        fn acceptDeposit(self: @ContractState, token: ContractAddress, amount: u256) {
            // TODO: check fees (not sure if needed)
            let dispatcher = IERC20Dispatcher { contract_address: token };
            assert(dispatcher.balance_of(get_caller_address()) == amount, 'Not enough balance');
        }

        fn send_deploy_message(self: @ContractState, token: ContractAddress) -> felt252 {
            assert(self.l2_token_bridge().is_zero(), Errors::L2_BRIDGE_NOT_SET);
            // TODO: Check fees not sure if needed
            let dispatcher = IMessagingDispatcher {
                contract_address: self.messaging_contract.read()
            };

            // TODO: Add the token deployment selector as a constant here
            let (hash, _nonce) = dispatcher
                .send_message_to_appchain(
                    self.l2_token_bridge(),
                    cairo_appchain_bridge::constants::HANDLE_TOKEN_DEPLOYMENT_SELECTOR,
                    self.deployment_message_payload(token)
                );
            return hash;
        }
    }

    #[abi(embed_v0)]
    impl TokenBridgeImpl of super::ITokenBridge<ContractState> {
        fn identity(self: @ContractState) -> ByteArray {
            "cairo_appchain_bridge"
        }

        fn enroll_token(ref self: ContractState, token: ContractAddress) {
            let status = self.token_settings.read(token).token_status;
            assert(status == TokenStatus::Unknown, 'Token already enrolled');
            self.send_deploy_message(token);
            // TODO: check the deployment msg has been sent by calling l1ToL2Messages() > 0
            let token_status = TokenSettings {
                token_status: TokenStatus::Pending,
                deployment_msg_hash: 2,
                pending_deployment_expiration: get_block_timestamp(),
                max_total_balance: core::integer::BoundedInt::max(),
                withdrawal_limit_applied: false
            };
            self.token_settings.write(token, token_status);
        }
    }
}

