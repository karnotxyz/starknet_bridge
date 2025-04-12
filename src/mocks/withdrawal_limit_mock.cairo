use starknet::ContractAddress;

#[starknet::interface]
pub trait IMockWithdrawalLimit<TState> {
    fn consume_quota(ref self: TState, token: ContractAddress, amount: u256);
    fn write_daily_withdrawal_limit_pct(
        ref self: TState, token: ContractAddress, limit_percent: u8,
    );
}

#[starknet::contract]
pub mod withdrawal_limit_mock {
    use starknet::ContractAddress;
    use starknet_bridge::withdrawal_limit::component::WithdrawalLimitComponent;
    use starknet_bridge::withdrawal_limit::component::WithdrawalLimitComponent::InternalTrait;

    component!(path: WithdrawalLimitComponent, storage: withdrawal, event: WithdrawalEvent);

    // WithdrawalLimit
    #[abi(embed_v0)]
    impl WithdrawalLimitImpl =
        WithdrawalLimitComponent::WithdrawalLimitImpl<ContractState>;
    impl WithdrawalLimitInternal = WithdrawalLimitComponent::InternalImpl<ContractState>;


    #[storage]
    struct Storage {
        #[substorage(v0)]
        pub withdrawal: WithdrawalLimitComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        #[flat]
        WithdrawalEvent: WithdrawalLimitComponent::Event,
    }

    #[constructor]
    pub fn constructor(ref self: ContractState) {}


    #[abi(embed_v0)]
    impl MockWithdrawalLimitImpl of super::IMockWithdrawalLimit<ContractState> {
        fn consume_quota(ref self: ContractState, token: ContractAddress, amount: u256) {
            self.withdrawal.consume_withdrawal_quota(token, amount);
        }

        fn write_daily_withdrawal_limit_pct(
            ref self: ContractState, token: ContractAddress, limit_percent: u8,
        ) {
            self.withdrawal.write_daily_withdrawal_limit_pct(token, limit_percent);
        }
    }
}
