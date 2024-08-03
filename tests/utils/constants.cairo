use starknet::{ContractAddress, contract_address_const};

pub fn OWNER() -> ContractAddress {
    contract_address_const::<'OWNER'>()
}

pub fn L3_BRIDGE_ADDRESS() -> ContractAddress {
    contract_address_const::<'l3_bridge_address'>()
}


// 5 days as the delay time (5 * 86400 = 432000)
pub const DELAY_TIME: felt252 = 432000;

