use starknet::ContractAddress;

#[starknet::interface]
pub trait IMockWithdrawalLimit<TState> {
    fn toggle_withdrawal_limit_for_token(
        ref self: TState, token: ContractAddress, is_applied: bool
    );
    fn consume_quota(ref self: TState, token: ContractAddress, amount: u256);
    fn write_daily_withdrawal_limit_pct(ref self: TState, limit_percent: u8);
    fn get_daily_withdrawal_limit_pct(self: @TState) -> u8;
}

#[starknet::contract]
pub mod withdrawal_limit_mock {
    use starknet_bridge::withdrawal_limit::component::WithdrawalLimitComponent::InternalTrait;
    use starknet_bridge::withdrawal_limit::{component::WithdrawalLimitComponent};
    use starknet_bridge::bridge::interface::IWithdrawalLimitStatus;
    use starknet::ContractAddress;
    use starknet::storage::Map;


    component!(path: WithdrawalLimitComponent, storage: withdrawal, event: WithdrawalEvent);

    // WithdrawalLimit
    #[abi(embed_v0)]
    impl WithdrawalLimitImpl =
        WithdrawalLimitComponent::WithdrawalLimitImpl<ContractState>;
    impl WithdrawalLimitInternal = WithdrawalLimitComponent::InternalImpl<ContractState>;


    #[storage]
    struct Storage {
        limits: Map<ContractAddress, bool>,
        #[substorage(v0)]
        withdrawal: WithdrawalLimitComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        #[flat]
        WithdrawalEvent: WithdrawalLimitComponent::Event,
    }

    #[constructor]
    pub fn constructor(ref self: ContractState) {
        self.withdrawal.initialize(5);
    }


    #[abi(embed_v0)]
    impl MockWithdrawalLimitImpl of super::IMockWithdrawalLimit<ContractState> {
        fn toggle_withdrawal_limit_for_token(
            ref self: ContractState, token: ContractAddress, is_applied: bool
        ) {
            self.limits.write(token, is_applied);
        }

        fn consume_quota(ref self: ContractState, token: ContractAddress, amount: u256) {
            self.withdrawal.consume_withdrawal_quota(token, amount);
        }

        fn write_daily_withdrawal_limit_pct(ref self: ContractState, limit_percent: u8) {
            self.withdrawal.write_daily_withdrawal_limit_pct(limit_percent);
        }

        fn get_daily_withdrawal_limit_pct(self: @ContractState) -> u8 {
            self.withdrawal.daily_withdrawal_limit_pct.read()
        }
    }

    #[abi(embed_v0)]
    impl WithdrawalLimitStatusImpl of IWithdrawalLimitStatus<ContractState> {
        fn is_withdrawal_limit_applied(self: @ContractState, token: ContractAddress) -> bool {
            self.limits.read(token)
        }
    }
}
