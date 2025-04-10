use openzeppelin::security::interface::{IPausableDispatcher, IPausableDispatcherTrait};
use openzeppelin::security::pausable::PausableComponent;
use openzeppelin::security::pausable::PausableComponent::Event as pausable_events;
use snforge_std as snf;
use snforge_std::{EventSpy, EventSpyAssertionsTrait};
use starknet::ContractAddress;
use starknet_bridge::bridge::tests::utils::setup::{
    deploy_erc20, deploy_token_bridge_with_messaging, enroll_token_and_settle,
};
use starknet_bridge::bridge::{
    ITokenBridgeAdminDispatcher, ITokenBridgeAdminDispatcherTrait, ITokenBridgeDispatcher,
};
use starknet_bridge::mocks::messaging::IMockMessagingDispatcher;
use super::constants::{SECURITY_ADMIN, SECURITY_AGENT, TOKEN_ADMIN};

fn setup() -> (ITokenBridgeDispatcher, EventSpy, ContractAddress, IMockMessagingDispatcher) {
    let (token_bridge, mut spy, messaging_mock) = deploy_token_bridge_with_messaging();
    let usdc_address = deploy_erc20("usdc", "usdc");
    enroll_token_and_settle(token_bridge, messaging_mock, usdc_address);
    (token_bridge, spy, usdc_address, messaging_mock)
}

#[test]
fn is_not_paused_on_deployment_ok() {
    let (token_bridge, _, _, _) = setup();
    let token_bridge_pausable = IPausableDispatcher {
        contract_address: token_bridge.contract_address,
    };
    assert!(!token_bridge_pausable.is_paused(), "Bridge should not be paused initially");
}

#[test]
fn pause_ok() {
    let (token_bridge, mut spy, _, _) = setup();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address,
    };
    let token_bridge_pausable = IPausableDispatcher {
        contract_address: token_bridge.contract_address,
    };

    // Pause the bridge with security agent
    snf::start_cheat_caller_address(token_bridge.contract_address, SECURITY_AGENT());
    token_bridge_admin.pause();
    snf::stop_cheat_caller_address(token_bridge.contract_address);

    let expected_pause = PausableComponent::Paused { account: SECURITY_AGENT() };

    spy
        .assert_emitted(
            @array![(token_bridge.contract_address, pausable_events::Paused(expected_pause))],
        );

    assert!(token_bridge_pausable.is_paused(), "Bridge should be paused");
}

#[test]
#[should_panic(expected: ('Caller is missing role',))]
fn pause_bridge_only_security_agent() {
    let (token_bridge, _, _, _) = setup();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address,
    };

    // Try to pause the bridge with a non-security agent account
    snf::start_cheat_caller_address(token_bridge.contract_address, TOKEN_ADMIN());
    token_bridge_admin.pause();
    snf::stop_cheat_caller_address(token_bridge.contract_address);
}

#[test]
fn unpause_ok() {
    let (token_bridge, mut spy, _, _) = setup();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address,
    };
    let token_bridge_pausable = IPausableDispatcher {
        contract_address: token_bridge.contract_address,
    };

    // Pause the bridge first with security agent
    snf::start_cheat_caller_address(token_bridge.contract_address, SECURITY_AGENT());
    token_bridge_admin.pause();
    snf::stop_cheat_caller_address(token_bridge.contract_address);

    assert!(token_bridge_pausable.is_paused(), "Bridge should be paused");

    // Try to unpause the bridge with a non-security admin account
    snf::start_cheat_caller_address(token_bridge.contract_address, SECURITY_ADMIN());
    token_bridge_admin.unpause();
    snf::stop_cheat_caller_address(token_bridge.contract_address);

    let expected_unpause = PausableComponent::Unpaused { account: SECURITY_ADMIN() };

    spy
        .assert_emitted(
            @array![(token_bridge.contract_address, pausable_events::Unpaused(expected_unpause))],
        );

    assert!(!token_bridge_pausable.is_paused(), "Bridge should not be paused");
}

#[test]
#[should_panic(expected: ('Caller is missing role',))]
fn unpause_bridge_only_security_admin() {
    let (token_bridge, _, _, _) = setup();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address,
    };
    let token_bridge_pausable = IPausableDispatcher {
        contract_address: token_bridge.contract_address,
    };

    // Pause the bridge first with security agent
    snf::start_cheat_caller_address(token_bridge.contract_address, SECURITY_AGENT());
    token_bridge_admin.pause();
    snf::stop_cheat_caller_address(token_bridge.contract_address);

    assert!(token_bridge_pausable.is_paused(), "Bridge should be paused");

    // Try to unpause the bridge with a non-security admin account
    snf::start_cheat_caller_address(token_bridge.contract_address, TOKEN_ADMIN());
    token_bridge_admin.unpause();
    snf::stop_cheat_caller_address(token_bridge.contract_address);
}
