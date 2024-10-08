use snforge_std as snf;
use snforge_std::EventSpyAssertionsTrait;
use starknet_bridge::bridge::{
    ITokenBridgeDispatcher, ITokenBridgeDispatcherTrait, ITokenBridgeAdminDispatcher,
    ITokenBridgeAdminDispatcherTrait, TokenBridge, TokenBridge::Event,
};
use openzeppelin::access::ownable::{
    interface::{IOwnableTwoStepDispatcher, IOwnableTwoStepDispatcherTrait}
};
use starknet::contract_address::{contract_address_const};
use starknet_bridge::bridge::tests::utils::setup::{deploy_token_bridge};
use super::constants::{OWNER, L3_BRIDGE_ADDRESS, USDC_MOCK_ADDRESS};


#[test]
fn constructor_ok() {
    let (token_bridge, _) = deploy_token_bridge();
    let token_bridge_ownable = IOwnableTwoStepDispatcher {
        contract_address: token_bridge.contract_address
    };
    assert(OWNER() == token_bridge_ownable.owner(), 'Incorrect owner');
}

#[test]
fn set_appchain_bridge_ok() {
    let (token_bridge, mut spy) = deploy_token_bridge();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address
    };
    let token_bridge = ITokenBridgeDispatcher { contract_address: token_bridge.contract_address };

    // Assert for old bridge address
    let old_appchain_bridge_address = token_bridge.appchain_bridge();
    assert(old_appchain_bridge_address == L3_BRIDGE_ADDRESS(), 'L3 Bridge address incorrect');

    let owner = OWNER();
    // Cheat for the owner
    snf::start_cheat_caller_address(token_bridge.contract_address, owner);

    // Set and check new bridge
    let new_appchain_bridge_address = contract_address_const::<'l3_bridge_address_new'>();
    token_bridge_admin.set_appchain_token_bridge(new_appchain_bridge_address);
    assert(
        token_bridge.appchain_bridge() == new_appchain_bridge_address, 'Appchain bridge not set'
    );
    snf::stop_cheat_caller_address(token_bridge.contract_address);

    let expected_event = TokenBridge::SetAppchainBridge {
        appchain_bridge: new_appchain_bridge_address
    };
    spy
        .assert_emitted(
            @array![(token_bridge.contract_address, Event::SetAppchainBridge(expected_event))]
        );
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn set_appchain_bridge_not_owner() {
    let (token_bridge, _) = deploy_token_bridge();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address
    };
    let token_bridge = ITokenBridgeDispatcher { contract_address: token_bridge.contract_address };

    // Assert for old bridge address
    let old_appchain_bridge_address = token_bridge.appchain_bridge();
    assert(old_appchain_bridge_address == L3_BRIDGE_ADDRESS(), 'L3 Bridge address incorrect');

    // Set and check new bridge
    let new_appchain_bridge_address = contract_address_const::<'l3_bridge_address_new'>();
    token_bridge_admin.set_appchain_token_bridge(new_appchain_bridge_address);
}


#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn set_max_total_balance_not_owner() {
    let (token_bridge, _) = deploy_token_bridge();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address
    };

    let usdc_address = USDC_MOCK_ADDRESS();
    let decimals = 1000_000;
    token_bridge_admin.set_max_total_balance(usdc_address, 50 * decimals);
}


#[test]
fn set_max_total_balance_ok() {
    let (token_bridge, mut spy) = deploy_token_bridge();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address
    };

    let usdc_address = USDC_MOCK_ADDRESS();

    let owner = OWNER();
    // Cheat for the owner
    snf::start_cheat_caller_address(token_bridge.contract_address, owner);

    let decimals = 1000_000;
    token_bridge_admin.set_max_total_balance(usdc_address, 50 * decimals);

    snf::stop_cheat_caller_address(token_bridge.contract_address);

    let expected_event = TokenBridge::SetMaxTotalBalance {
        token: usdc_address, value: 50 * decimals
    };

    spy
        .assert_emitted(
            @array![(token_bridge.contract_address, Event::SetMaxTotalBalance(expected_event))]
        );
}
