use starknet::ContractAddress;

#[starknet::interface]
pub trait IMockWithdrawalLimit<TState> {
    fn change_withdrawal_limit_token(ref self: TState, token: ContractAddress, is_applied: bool);
}

#[starknet::contract]
mod withdrawal_limit_mock {
    use starknet_bridge::withdrawal_limit::{
        component::WithdrawalLimitComponent,
        interface::{IWithdrawalLimitDispatcher, IWithdrawalLimitDispatcherTrait, IWithdrawalLimit}
    };
    use starknet_bridge::bridge::interface::IWithdrawalLimitStatus;
    use starknet::ContractAddress;


    component!(path: WithdrawalLimitComponent, storage: withdrawal, event: WithdrawalEvent);

    // WithdrawalLimit
    #[abi(embed_v0)]
    impl WithdrawalLimitImpl =
        WithdrawalLimitComponent::WithdrawalLimitImpl<ContractState>;
    impl WithdrawalLimitInternal = WithdrawalLimitComponent::InternalImpl<ContractState>;


    #[storage]
    struct Storage {
        limits: LegacyMap<ContractAddress, bool>,
        #[substorage(v0)]
        withdrawal: WithdrawalLimitComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        WithdrawalEvent: WithdrawalLimitComponent::Event,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {}


    #[abi(embed_v0)]
    impl MockWithdrawalLimitImpl of super::IMockWithdrawalLimit<ContractState> {
        fn change_withdrawal_limit_token(
            ref self: ContractState, token: ContractAddress, is_applied: bool
        ) {
            self.limits.write(token, is_applied);
        }
    }

    #[abi(embed_v0)]
    impl WithdrawalLimitStatusImpl of IWithdrawalLimitStatus<ContractState> {
        fn is_withdrawal_limit_applied(self: @ContractState, token: ContractAddress) -> bool {
            self.limits.read(token)
        }
    }
}
