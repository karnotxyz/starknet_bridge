use starknet::ContractAddress;

#[starknet::interface]
pub trait IWithdrawalLimit<TState> {
    fn get_remaining_withdrawal_quota(self: @TState, token: ContractAddress) -> u256;
    fn is_withdrawal_limit_applied(self: @TState, token: ContractAddress) -> bool;
    fn get_daily_withdrawal_limit_pct(self: @TState, token: ContractAddress) -> u8;
}
