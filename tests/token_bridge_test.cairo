use openzeppelin::security::interface::{IPausableDispatcher, IPausableDispatcherTrait};
use snforge_std as snf;
use snforge_std::EventSpyAssertionsTrait;
use starknet_bridge::bridge::TokenBridge::Event;
use starknet_bridge::bridge::tests::utils::setup::deploy_token_bridge;
use starknet_bridge::bridge::{
    ITokenBridgeAdminDispatcher, ITokenBridgeAdminDispatcherTrait, ITokenBridgeDispatcher,
    ITokenBridgeDispatcherTrait, TokenBridge,
};
use super::constants::{APP_GOVERNOR, L3_BRIDGE_ADDRESS, SECURITY_AGENT, USDC_MOCK_ADDRESS};


#[test]
fn constructor_ok() {
    let (token_bridge, _) = deploy_token_bridge();
    let token_bridge_ownable = IPausableDispatcher {
        contract_address: token_bridge.contract_address,
    };
    assert(!token_bridge_ownable.is_paused(), 'Incorrect owner');
}

#[test]
fn set_appchain_bridge_ok() {
    let (token_bridge, mut spy) = deploy_token_bridge();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address,
    };
    let token_bridge = ITokenBridgeDispatcher { contract_address: token_bridge.contract_address };

    // Assert for old bridge address
    let old_appchain_bridge_address = token_bridge.appchain_bridge();
    assert(old_appchain_bridge_address == L3_BRIDGE_ADDRESS(), 'L3 Bridge address incorrect');

    // Cheat for the APP_GOVERNOR
    snf::start_cheat_caller_address(token_bridge.contract_address, APP_GOVERNOR());

    // Set and check new bridge
    let new_appchain_bridge_address = 'l3_bridge_address_new'.try_into().unwrap();
    token_bridge_admin.set_appchain_token_bridge(new_appchain_bridge_address);
    assert(
        token_bridge.appchain_bridge() == new_appchain_bridge_address, 'Appchain bridge not set',
    );
    snf::stop_cheat_caller_address(token_bridge.contract_address);

    let expected_event = TokenBridge::SetAppchainBridge {
        appchain_bridge: new_appchain_bridge_address,
    };
    spy
        .assert_emitted(
            @array![(token_bridge.contract_address, Event::SetAppchainBridge(expected_event))],
        );
}

#[test]
#[should_panic(expected: ('Pausable: paused',))]
fn set_appchain_bridge_paused() {
    let (token_bridge, _) = deploy_token_bridge();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address,
    };

    // Set up security agent before pausing
    snf::start_cheat_caller_address(token_bridge.contract_address, SECURITY_AGENT());
    token_bridge_admin.pause();
    snf::stop_cheat_caller_address(token_bridge.contract_address);

    let new_appchain_bridge_address = 'l3_bridge_address_new'.try_into().unwrap();
    token_bridge_admin.set_appchain_token_bridge(new_appchain_bridge_address);
}

#[test]
#[should_panic(expected: ('Caller is missing role',))]
fn set_appchain_bridge_not_app_governor() {
    let (token_bridge, _) = deploy_token_bridge();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address,
    };
    let token_bridge = ITokenBridgeDispatcher { contract_address: token_bridge.contract_address };

    // Assert for old bridge address
    let old_appchain_bridge_address = token_bridge.appchain_bridge();
    assert(old_appchain_bridge_address == L3_BRIDGE_ADDRESS(), 'L3 Bridge address incorrect');

    // Set and check new bridge
    let new_appchain_bridge_address = 'l3_bridge_address_new'.try_into().unwrap();
    token_bridge_admin.set_appchain_token_bridge(new_appchain_bridge_address);
}


#[test]
#[should_panic(expected: ('Caller is missing role',))]
fn set_max_total_balance_not_app_governor() {
    let (token_bridge, _) = deploy_token_bridge();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address,
    };

    let usdc_address = USDC_MOCK_ADDRESS();
    let decimals = 1000_000;
    token_bridge_admin.set_max_total_balance(usdc_address, 50 * decimals);
}


#[test]
fn set_max_total_balance_ok() {
    let (token_bridge, mut spy) = deploy_token_bridge();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address,
    };

    let usdc_address = USDC_MOCK_ADDRESS();

    // Cheat for the owner
    snf::start_cheat_caller_address(token_bridge.contract_address, APP_GOVERNOR());

    let decimals = 1000_000;
    token_bridge_admin.set_max_total_balance(usdc_address, 50 * decimals);

    snf::stop_cheat_caller_address(token_bridge.contract_address);

    let expected_event = TokenBridge::SetMaxTotalBalance {
        token: usdc_address, value: 50 * decimals,
    };

    spy
        .assert_emitted(
            @array![(token_bridge.contract_address, Event::SetMaxTotalBalance(expected_event))],
        );
}


#[test]
#[should_panic(expected: ('Pausable: paused',))]
fn set_max_total_balance_paused() {
    let (token_bridge, _) = deploy_token_bridge();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address,
    };

    // Set up security agent before pausing
    snf::start_cheat_caller_address(token_bridge.contract_address, SECURITY_AGENT());
    token_bridge_admin.pause();
    snf::stop_cheat_caller_address(token_bridge.contract_address);

    let usdc_address = USDC_MOCK_ADDRESS();
    token_bridge_admin.set_max_total_balance(usdc_address, 100);
}
