use snforge_std as snf;
use snforge_std::EventSpyAssertionsTrait;
use starknet::get_block_timestamp;
use starknet_bridge::bridge::tests::constants::{L3_BRIDGE_ADDRESS, TOKEN_ADMIN, SECURITY_AGENT};
use starknet_bridge::bridge::tests::utils::message_payloads;
use starknet_bridge::bridge::tests::utils::setup::{
    deploy_token_bridge_with_messaging, deploy_erc20, enroll_token,
};
use starknet_bridge::bridge::types::TokenStatus;
use starknet_bridge::bridge::{
    ITokenBridgeAdminDispatcher, ITokenBridgeAdminDispatcherTrait, ITokenBridgeDispatcherTrait,
    TokenBridge,
};
use starknet_bridge::bridge::TokenBridge::Event;
use starknet_bridge::constants;
use starknet_bridge::mocks::messaging::{IMockMessagingDispatcherTrait};

#[test]
fn check_deployment_status_non_pending_token() {
    // Test that function returns early for tokens not in Pending status
    let (token_bridge, _spy, _) = deploy_token_bridge_with_messaging();
    let token = deploy_erc20("TEST", "TST");

    // Token should be in Unknown status initially
    assert(token_bridge.get_status(token) == TokenStatus::Unknown, 'Should be Unknown');

    // Call check_deployment_status - should do nothing for Unknown token
    token_bridge.check_deployment_status(token);

    // Status should remain Unknown
    assert(token_bridge.get_status(token) == TokenStatus::Unknown, 'Should still be Unknown');
}

#[test]
fn check_deployment_status_pending_not_expired() {
    // Test pending deployment that hasn't expired yet
    let (token_bridge, _, messaging_mock) = deploy_token_bridge_with_messaging();
    let token = deploy_erc20("TEST", "TST");

    // Enroll the token
    enroll_token(token_bridge, messaging_mock, token);
    assert(token_bridge.get_status(token) == TokenStatus::Pending, 'Should be Pending');

    // Check deployment status without processing the message (so it remains pending)
    token_bridge.check_deployment_status(token);

    // Status should remain Pending since message is still pending and not expired
    assert(token_bridge.get_status(token) == TokenStatus::Pending, 'Should still be Pending');

    snf::stop_cheat_caller_address(token_bridge.contract_address);
}

#[test]
fn check_deployment_status_cancelling_completes_cancellation() {
    // Test that cancelling message completes cancellation and resets to Unknown
    let (token_bridge, mut spy, messaging_mock) = deploy_token_bridge_with_messaging();
    let token = deploy_erc20("TEST", "TST");

    // Enroll the token
    enroll_token(token_bridge, messaging_mock, token);
    assert(token_bridge.get_status(token) == TokenStatus::Pending, 'Should be Pending');

    // Fast forward time to expire the deployment
    let future_timestamp = get_block_timestamp() + token_bridge.get_max_pending_duration() + 1;
    snf::start_cheat_block_timestamp_global(future_timestamp);

    // First call starts cancellation
    token_bridge.check_deployment_status(token);

    // Fast forward time for cancellation delay to pass
    let cancellation_timestamp = future_timestamp + 432000 + 1; // 5 days + 1 second
    snf::start_cheat_block_timestamp_global(cancellation_timestamp);

    // Second call should complete cancellation
    token_bridge.check_deployment_status(token);

    // Status should be back to Unknown
    assert(token_bridge.get_status(token) == TokenStatus::Unknown, 'Should be Unknown');

    // Should emit TokenUnknown event
    let expected_event = TokenBridge::TokenUnknown { token };
    spy
        .assert_emitted(
            @array![(token_bridge.contract_address, Event::TokenUnknown(expected_event))],
        );

    snf::stop_cheat_block_timestamp_global();
}

#[test]
fn check_deployment_starts_cancelling_to_token_active() {
    // Test that cancelling message completes cancellation and resets to Unknown
    let (token_bridge, mut spy, messaging_mock) = deploy_token_bridge_with_messaging();
    let token = deploy_erc20("TEST", "TST");

    // Enroll the token
    enroll_token(token_bridge, messaging_mock, token);
    assert(token_bridge.get_status(token) == TokenStatus::Pending, 'Should be Pending');

    // Fast forward time to expire the deployment
    let future_timestamp = get_block_timestamp() + token_bridge.get_max_pending_duration() + 1;
    snf::start_cheat_block_timestamp_global(future_timestamp);

    // First call starts cancellation
    token_bridge.check_deployment_status(token);

    messaging_mock
        .process_last_message_to_appchain(
            token_bridge.contract_address,
            L3_BRIDGE_ADDRESS(),
            constants::HANDLE_TOKEN_DEPLOYMENT_SELECTOR,
            message_payloads::deployment_message_payload(token),
        );

    // Fast forward time for cancellation delay to pass
    let cancellation_timestamp = future_timestamp + 432000 + 1; // 5 days + 1 second
    snf::start_cheat_block_timestamp_global(cancellation_timestamp);

    // Second call should make the token Active since message is processed
    token_bridge.check_deployment_status(token);

    // Status should be back to Unknown
    assert(token_bridge.get_status(token) == TokenStatus::Active, 'Should be Unknown');

    // Should emit TokenUnknown event
    let expected_event = TokenBridge::TokenActivated { token };
    spy
        .assert_emitted(
            @array![(token_bridge.contract_address, Event::TokenActivated(expected_event))],
        );

    snf::stop_cheat_block_timestamp_global();
}

#[test]
#[should_panic(expected: ('Pausable: paused',))]
fn check_deployment_status_paused() {
    // Test that function fails when contract is paused
    let (token_bridge, _, _) = deploy_token_bridge_with_messaging();
    let token = deploy_erc20("TEST", "TST");

    // Pause the contract
    snf::start_cheat_caller_address(token_bridge.contract_address, SECURITY_AGENT());
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address,
    };
    token_bridge_admin.pause();

    // Try to check deployment status - should fail
    token_bridge.check_deployment_status(token);
}

#[test]
fn check_deployment_status_multiple_calls_idempotent() {
    // Test that multiple calls to check_deployment_status are idempotent
    let (token_bridge, _, messaging_mock) = deploy_token_bridge_with_messaging();
    let token = deploy_erc20("TEST", "TST");

    // Enroll and seal the message
    enroll_token(token_bridge, messaging_mock, token);
    messaging_mock
        .process_last_message_to_appchain(
            token_bridge.contract_address,
            L3_BRIDGE_ADDRESS(),
            constants::HANDLE_TOKEN_DEPLOYMENT_SELECTOR,
            message_payloads::deployment_message_payload(token),
        );

    // First call should activate the token
    token_bridge.check_deployment_status(token);
    assert(token_bridge.get_status(token) == TokenStatus::Active, 'Should be Active');

    // Second call should do nothing (early return for non-Pending status)
    token_bridge.check_deployment_status(token);
    assert(token_bridge.get_status(token) == TokenStatus::Active, 'Should still be Active');

    // Third call should also do nothing
    token_bridge.check_deployment_status(token);
    assert(token_bridge.get_status(token) == TokenStatus::Active, 'Should still be Active');
}
