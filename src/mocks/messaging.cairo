use piltover::messaging::output_process::MessageToAppchain;
#[starknet::interface]
pub trait IMockMessaging<TState> {
    fn update_state_for_message(ref self: TState, message_hash: felt252);
}

#[starknet::contract]
mod messaging_mock {
    use piltover::messaging::{
        output_process::MessageToAppchain, messaging_cpt,
        messaging_cpt::InternalTrait as MessagingInternal, IMessaging
    };
    use starknet::ContractAddress;
    use super::IMockMessaging;

    component!(path: messaging_cpt, storage: messaging, event: MessagingEvent);

    #[abi(embed_v0)]
    impl MessagingImpl = messaging_cpt::MessagingImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        messaging: messaging_cpt::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        MessagingEvent: messaging_cpt::Event
    }

    #[constructor]
    fn constructor(ref self: ContractState, cancellation_delay_secs: u64) {
        self.messaging.initialize(cancellation_delay_secs);
    }

    #[abi(embed_v0)]
    impl MockMessagingImpl of IMockMessaging<ContractState> {
        fn update_state_for_message(ref self: ContractState, message_hash: felt252) {
            self.messaging.sn_to_appc_messages.write(message_hash, 0);
        }
    }
}
