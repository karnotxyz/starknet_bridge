use snforge_std as snf;
use snforge_std::{ContractClassTrait, DeclareResultTrait, EventSpyAssertionsTrait};
use starknet_bridge::bridge::TokenBridge::Event;
use starknet_bridge::bridge::tests::utils::message_payloads;
use starknet_bridge::bridge::tests::utils::setup::{deploy_erc20, deploy_token_bridge};
use starknet_bridge::bridge::types::TokenStatus;
use starknet_bridge::bridge::{
    ITokenBridgeAdminDispatcher, ITokenBridgeAdminDispatcherTrait, ITokenBridgeDispatcher,
    ITokenBridgeDispatcherTrait, TokenBridge,
};
use starknet_bridge::constants;
use starknet_bridge::mocks::hash;
use super::constants::{
    APP_GOVERNOR, GOVERNANCE_ADMIN, L3_BRIDGE_ADDRESS, SECURITY_ADMIN, SECURITY_AGENT,
    TIMELOCK_ADDRESS, TOKEN_ADMIN,
};


#[test]
fn enroll_token_ok() {
    let (token_bridge, mut spy) = deploy_token_bridge();

    let usdc_address = deploy_erc20("USDC", "USDC");

    let old_status = token_bridge.get_status(usdc_address);
    assert(old_status == TokenStatus::Unknown, 'Should be unknown before');

    token_bridge.enroll_token(usdc_address);

    let payload = message_payloads::deployment_message_payload(usdc_address);
    let message_hash = hash::compute_message_hash_sn_to_appc(
        token_bridge.contract_address,
        L3_BRIDGE_ADDRESS(),
        constants::HANDLE_TOKEN_DEPLOYMENT_SELECTOR,
        payload,
        0,
    );

    let expected_event = TokenBridge::TokenEnrollmentInitiated {
        token: usdc_address, deployment_message_hash: message_hash,
    };

    let new_status = token_bridge.get_status(usdc_address);
    assert(new_status == TokenStatus::Pending, 'Should be pending now');
    spy
        .assert_emitted(
            @array![
                (token_bridge.contract_address, Event::TokenEnrollmentInitiated(expected_event)),
            ],
        );
}

#[test]
fn enroll_token_permissioned_ok() {
    let (token_bridge, mut spy) = deploy_token_bridge();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address,
    };

    snf::start_cheat_caller_address(token_bridge.contract_address, APP_GOVERNOR());
    token_bridge_admin.configure_permissioned_enrollment(true);
    snf::stop_cheat_caller_address(token_bridge.contract_address);

    let usdc_address = deploy_erc20("USDC", "USDC");

    let old_status = token_bridge.get_status(usdc_address);
    assert(old_status == TokenStatus::Unknown, 'Should be unknown before');

    // Enroll token as token admin as permissioned enrollment is enabled
    snf::start_cheat_caller_address(token_bridge.contract_address, TOKEN_ADMIN());
    token_bridge.enroll_token(usdc_address);
    snf::stop_cheat_caller_address(token_bridge.contract_address);

    let payload = message_payloads::deployment_message_payload(usdc_address);
    let message_hash = hash::compute_message_hash_sn_to_appc(
        token_bridge.contract_address,
        L3_BRIDGE_ADDRESS(),
        constants::HANDLE_TOKEN_DEPLOYMENT_SELECTOR,
        payload,
        0,
    );

    let expected_event = TokenBridge::TokenEnrollmentInitiated {
        token: usdc_address, deployment_message_hash: message_hash,
    };

    let new_status = token_bridge.get_status(usdc_address);
    assert(new_status == TokenStatus::Pending, 'Should be pending now');
    spy
        .assert_emitted(
            @array![
                (token_bridge.contract_address, Event::TokenEnrollmentInitiated(expected_event)),
            ],
        );
}

#[test]
#[should_panic(expected: ('Permissioned or not TokenAdmin',))]
fn enroll_token_permissioned_not_token_admin() {
    let (token_bridge, _) = deploy_token_bridge();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address,
    };

    snf::start_cheat_caller_address(token_bridge.contract_address, APP_GOVERNOR());
    token_bridge_admin.configure_permissioned_enrollment(true);
    snf::stop_cheat_caller_address(token_bridge.contract_address);

    let usdc_address = deploy_erc20("USDC", "USDC");
    token_bridge.enroll_token(usdc_address);
}


#[test]
#[should_panic(expected: ('Pausable: paused',))]
fn enroll_token_paused() {
    let (token_bridge, _) = deploy_token_bridge();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address,
    };

    // Set up security agent before pausing
    snf::start_cheat_caller_address(token_bridge.contract_address, SECURITY_AGENT());
    token_bridge_admin.pause();
    snf::stop_cheat_caller_address(token_bridge.contract_address);

    let usdc_address = deploy_erc20("USDC", "USDC");
    token_bridge.enroll_token(usdc_address);
}

#[test]
#[should_panic(expected: ('Token not unknown',))]
fn enroll_token_already_enrolled() {
    let (token_bridge, _) = deploy_token_bridge();

    let usdc_address = deploy_erc20("USDC", "USDC");
    token_bridge.enroll_token(usdc_address);

    let new_status = token_bridge.get_status(usdc_address);
    assert(new_status == TokenStatus::Pending, 'Should be pending now');

    token_bridge.enroll_token(usdc_address);
}

#[test]
#[should_panic(expected: ('Deploy message not Pending',))]
fn enroll_token_nonce_not_updated() {
    // Deploy messaging mock with 5 days cancellation delay
    let messaging_mock_class_hash = snf::declare("messaging_malicious").unwrap().contract_class();
    // Deploying with 5 days as the delay time (5 * 86400 = 432000)
    let (messaging_contract_address, _) = messaging_mock_class_hash.deploy(@array![]).unwrap();

    // Declare l3 bridge address
    let appchain_bridge_address = L3_BRIDGE_ADDRESS();

    let token_bridge_class_hash = snf::declare("TokenBridge").unwrap().contract_class();

    // Deploy the bridge
    let mut calldata = ArrayTrait::new();
    appchain_bridge_address.serialize(ref calldata);
    messaging_contract_address.serialize(ref calldata);
    [GOVERNANCE_ADMIN()].span().serialize(ref calldata);
    [APP_GOVERNOR()].span().serialize(ref calldata);
    [SECURITY_ADMIN()].span().serialize(ref calldata);
    [SECURITY_AGENT()].span().serialize(ref calldata);
    [TOKEN_ADMIN()].span().serialize(ref calldata);
    TIMELOCK_ADDRESS().serialize(ref calldata);

    let (token_bridge_address, _) = token_bridge_class_hash.deploy(@calldata).unwrap();

    let token_bridge = ITokenBridgeDispatcher { contract_address: token_bridge_address };

    let usdc_address = deploy_erc20("USDC", "USDC");

    token_bridge.enroll_token(usdc_address);
}

