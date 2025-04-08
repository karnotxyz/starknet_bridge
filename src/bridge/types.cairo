use piltover::messaging::types::MessageHash;

#[derive(Serde, Drop, starknet::Store, PartialEq, Debug)]
pub enum TokenStatus {
    #[default]
    Unknown,
    Pending,
    Active,
    Blocked,
    Deactivated,
}

#[derive(Serde, Drop, starknet::Store)]
pub struct TokenSettings {
    pub token_status: TokenStatus,
    pub deployment_message_hash: MessageHash,
    pub pending_deployment_expiration: u64,
    pub max_total_balance: u256,
}


pub mod Roles {
    pub const APP_GOVERNOR: felt252 = 'APP_GOVERNOR';
    pub const SECURITY_AGENT: felt252 = 'SECURITY_AGENT';
    pub const SECURITY_ADMIN: felt252 = 'SECURITY_ADMIN';
    pub const UPGRADE_GOVERNOR: felt252 = 'UPGRADE_GOVERNOR';
}

