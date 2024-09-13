use snforge_std as snf;
use snforge_std::EventSpy;
use starknet_bridge::mocks::{messaging::{IMockMessagingDispatcherTrait, IMockMessagingDispatcher},};
use starknet_bridge::bridge::{
    ITokenBridgeDispatcher, ITokenBridgeDispatcherTrait, ITokenBridgeAdminDispatcher,
    ITokenBridgeAdminDispatcherTrait,
};

use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use starknet::contract_address::{contract_address_const};
use super::constants::{OWNER, L3_BRIDGE_ADDRESS};
use starknet_bridge::bridge::tests::utils::setup::{
    deploy_erc20, deploy_token_bridge_with_messaging, enroll_token_and_settle
};
use starknet_bridge::constants;
use starknet_bridge::bridge::tests::utils::message_payloads;


fn setup() -> (ITokenBridgeDispatcher, EventSpy, IERC20Dispatcher, IMockMessagingDispatcher, u256) {
    let (token_bridge, mut spy, messaging_mock) = deploy_token_bridge_with_messaging();
    let usdc_address = deploy_erc20("usdc", "usdc");
    let usdc = IERC20Dispatcher { contract_address: usdc_address };
    enroll_token_and_settle(token_bridge, messaging_mock, usdc.contract_address);

    snf::start_cheat_caller_address(usdc.contract_address, OWNER());
    usdc.transfer(snf::test_address(), 100);
    snf::stop_cheat_caller_address(usdc_address);

    let amount = 100;
    usdc.approve(token_bridge.contract_address, amount);
    token_bridge.deposit(usdc_address, amount, snf::test_address());
    messaging_mock
        .process_last_message_to_appchain(
            L3_BRIDGE_ADDRESS(),
            constants::HANDLE_TOKEN_DEPOSIT_SELECTOR,
            message_payloads::deposit_message_payload(
                usdc_address,
                amount,
                snf::test_address(),
                snf::test_address(),
                false,
                array![].span()
            )
        );

    (token_bridge, spy, usdc, messaging_mock, amount)
}

#[test]
fn withdraw_ok() {
    let (token_bridge, _, usdc, messaging_mock, amount) = setup();

    // Register a withdraw message from appchain to piltover
    messaging_mock
        .process_message_to_starknet(
            L3_BRIDGE_ADDRESS(),
            token_bridge.contract_address,
            message_payloads::withdraw_message_payload_from_appchain(
                usdc.contract_address, amount, snf::test_address()
            )
        );

    let initial_bridge_balance = usdc.balance_of(token_bridge.contract_address);
    let initial_recipient_balance = usdc.balance_of(snf::test_address());
    token_bridge.withdraw(usdc.contract_address, amount, snf::test_address());

    assert(
        usdc.balance_of(snf::test_address()) == initial_recipient_balance + amount,
        'Incorrect amount recieved'
    );

    assert(
        usdc.balance_of(token_bridge.contract_address) == initial_bridge_balance - amount,
        'Incorrect token amount'
    );
}

#[test]
#[should_panic(expected: ('INVALID_MESSAGE_TO_CONSUME',))]
fn withdraw_incorrect_recipient() {
    let (token_bridge, _, usdc, messaging_mock, amount) = setup();

    // Register a withdraw message from appchain to piltover
    messaging_mock
        .process_message_to_starknet(
            L3_BRIDGE_ADDRESS(),
            token_bridge.contract_address,
            message_payloads::withdraw_message_payload_from_appchain(
                usdc.contract_address, amount, snf::test_address()
            )
        );

    token_bridge.withdraw(usdc.contract_address, amount, contract_address_const::<'user2'>());
}


#[test]
#[should_panic(expected: ('LIMIT_EXCEEDED',))]
fn withdraw_limit_reached() {
    let (token_bridge, _, usdc, messaging_mock, _) = setup();

    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address
    };

    snf::start_cheat_caller_address(token_bridge.contract_address, OWNER());
    token_bridge_admin.enable_withdrawal_limit(usdc.contract_address);
    snf::stop_cheat_caller_address(token_bridge.contract_address);

    let withdraw_amount = 50;

    // Register a withdraw message from appchain to piltover
    messaging_mock
        .process_message_to_starknet(
            L3_BRIDGE_ADDRESS(),
            token_bridge.contract_address,
            message_payloads::withdraw_message_payload_from_appchain(
                usdc.contract_address, withdraw_amount, snf::test_address()
            )
        );

    token_bridge.withdraw(usdc.contract_address, withdraw_amount, snf::test_address());
}
