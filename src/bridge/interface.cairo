use starknet::ContractAddress;

#[derive(Serde, Drop, starknet::Store, PartialEq)]
pub enum TokenStatus {
    #[default]
    Unknown,
    Pending,
    Active,
    Deactivated
}

#[derive(Serde, Drop, starknet::Store)]
pub struct TokenSettings {
    pub token_status: TokenStatus,
    pub deployment_message_hash: felt252,
    pub pending_deployment_expiration: u64,
    pub max_total_balance: u256,
    pub withdrawal_limit_applied: bool
}


#[starknet::interface]
pub trait ITokenBridge<TContractState> {
    fn appchain_bridge(self: @TContractState) -> ContractAddress;
    fn identity(self: @TContractState) -> ByteArray;
    fn enroll_token(ref self: TContractState, token: ContractAddress);
    fn check_deployment_status(ref self: TContractState, token: ContractAddress);
    fn deactivate_token(ref self: TContractState, token: ContractAddress);
    fn deposit(
        ref self: TContractState,
        token: ContractAddress,
        amount: u256,
        appchain_recipient: ContractAddress
    );

    fn getStatus(self: @TContractState, token: ContractAddress) -> TokenStatus;
    fn isServicingToken(self: @TContractState, token: ContractAddress) -> bool;
}
