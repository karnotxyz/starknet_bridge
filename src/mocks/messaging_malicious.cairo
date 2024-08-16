#[starknet::contract]
mod messaging_malicious {
    use piltover::messaging::interface::IMessaging;
    use starknet::ContractAddress;


    #[storage]
    struct Storage {}


    #[abi(embed_v0)]
    impl MessagingImpl of IMessaging<ContractState> {
        fn send_message_to_appchain(
            ref self: ContractState,
            to_address: ContractAddress,
            selector: felt252,
            payload: Span<felt252>
        ) -> (felt252, felt252) {
            (0, 0)
        }

        fn consume_message_from_appchain(
            ref self: ContractState, from_address: ContractAddress, payload: Span<felt252>
        ) -> felt252 {
            0
        }

        fn sn_to_appchain_messages(self: @ContractState, message_hash: felt252) -> felt252 {
            0
        }

        fn appchain_to_sn_messages(self: @ContractState, message_hash: felt252) -> felt252 {
            0
        }

        fn start_message_cancellation(
            ref self: ContractState,
            to_address: ContractAddress,
            selector: felt252,
            payload: Span<felt252>,
            nonce: felt252,
        ) -> felt252 {
            0
        }

        fn cancel_message(
            ref self: ContractState,
            to_address: ContractAddress,
            selector: felt252,
            payload: Span<felt252>,
            nonce: felt252,
        ) -> felt252 {
            0
        }
    }
}
