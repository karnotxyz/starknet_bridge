use starknet::ContractAddress;

pub fn OWNER() -> ContractAddress {
    'owner address'.try_into().unwrap()
}

pub fn UPGRADE_GOVERNOR() -> ContractAddress {
    'UPGRADE_GOVERNOR'.try_into().unwrap()
}

pub fn GOVERNANCE_ADMIN() -> ContractAddress {
    'GOVERNANCE_ADMIN'.try_into().unwrap()
}

pub fn APP_GOVERNOR() -> ContractAddress {
    'APP_GOVERNOR'.try_into().unwrap()
}

pub fn SECURITY_ADMIN() -> ContractAddress {
    'SECURITY_ADMIN'.try_into().unwrap()
}

pub fn SECURITY_AGENT() -> ContractAddress {
    'SECURITY_AGENT'.try_into().unwrap()
}

pub fn TOKEN_ADMIN() -> ContractAddress {
    'TOKEN_ADMIN'.try_into().unwrap()
}


pub fn TIMELOCK_ADDRESS() -> ContractAddress {
    'timelock address'.try_into().unwrap()
}

pub fn L3_BRIDGE_ADDRESS() -> ContractAddress {
    'l3_bridge_address'.try_into().unwrap()
}

pub fn USDC_MOCK_ADDRESS() -> ContractAddress {
    'Usdc address'.try_into().unwrap()
}

// 5 days as the delay time (5 * 86400 = 432000)
pub const DELAY_TIME: felt252 = 432000;

