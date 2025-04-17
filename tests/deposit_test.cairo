use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std as snf;
use snforge_std::{EventSpy, EventSpyAssertionsTrait};
use starknet::ContractAddress;
use starknet_bridge::bridge::TokenBridge::Event;
use starknet_bridge::bridge::tests::utils::setup::{
    deploy_erc20, deploy_token_bridge_with_messaging, enroll_token_and_settle, enroll_token,
};

use starknet_bridge::bridge::types::TokenStatus;
use starknet_bridge::bridge::{
    ITokenBridgeAdminDispatcher, ITokenBridgeAdminDispatcherTrait, ITokenBridgeDispatcher,
    ITokenBridgeDispatcherTrait, TokenBridge,
};
use starknet_bridge::constants;
use starknet_bridge::bridge::tests::utils::message_payloads;
use starknet_bridge::mocks::messaging::{IMockMessagingDispatcher, IMockMessagingDispatcherTrait};
use super::constants::{SECURITY_AGENT, TOKEN_ADMIN, L3_BRIDGE_ADDRESS};


fn setup(
    with_settle: bool,
) -> (ITokenBridgeDispatcher, EventSpy, ContractAddress, IMockMessagingDispatcher) {
    let (token_bridge, mut spy, messaging_mock) = deploy_token_bridge_with_messaging();
    let usdc_address = deploy_erc20("usdc", "usdc");
    if with_settle {
        enroll_token_and_settle(token_bridge, messaging_mock, usdc_address);
    } else {
        enroll_token(token_bridge, messaging_mock, usdc_address);
    }
    (token_bridge, spy, usdc_address, messaging_mock)
}

#[test]
fn deposit_ok() {
    let (token_bridge, mut spy, usdc_address, _) = setup(true);

    let usdc = IERC20Dispatcher { contract_address: usdc_address };
    let initial_bridge_balance = usdc.balance_of(token_bridge.contract_address);
    usdc.approve(token_bridge.contract_address, 100);
    token_bridge.deposit(usdc_address, 100, snf::test_address());

    assert(
        usdc.balance_of(token_bridge.contract_address) == initial_bridge_balance + 100,
        'incorrect amount recieved',
    );

    let expected_deposit = TokenBridge::Deposit {
        sender: snf::test_address(),
        token: usdc_address,
        amount: 100,
        appchain_recipient: snf::test_address(),
        nonce: 1,
    };

    spy.assert_emitted(@array![(token_bridge.contract_address, Event::Deposit(expected_deposit))]);
}


#[test]
fn deposit_should_activate_token() {
    let (token_bridge, mut spy, usdc_address, messaging_mock) = setup(false);

    let usdc = IERC20Dispatcher { contract_address: usdc_address };
    let initial_bridge_balance = usdc.balance_of(token_bridge.contract_address);
    usdc.approve(token_bridge.contract_address, 100);

    // Settles the message sent to appchain
    messaging_mock
        .process_last_message_to_appchain(
            token_bridge.contract_address,
            L3_BRIDGE_ADDRESS(),
            constants::HANDLE_TOKEN_DEPLOYMENT_SELECTOR,
            message_payloads::deployment_message_payload(usdc_address),
        );

    token_bridge.deposit(usdc_address, 100, snf::test_address());

    assert(
        usdc.balance_of(token_bridge.contract_address) == initial_bridge_balance + 100,
        'incorrect amount recieved',
    );

    let expected_deposit = TokenBridge::Deposit {
        sender: snf::test_address(),
        token: usdc_address,
        amount: 100,
        appchain_recipient: snf::test_address(),
        nonce: 1,
    };

    spy.assert_emitted(@array![(token_bridge.contract_address, Event::Deposit(expected_deposit))]);

    assert(token_bridge.get_status(usdc_address) == TokenStatus::Active, 'Token should be active');
}

#[test]
#[should_panic(expected: ('Pausable: paused',))]
fn deposit_paused() {
    let (token_bridge, _, usdc_address, _) = setup(true);
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address,
    };

    // Set up security agent before pausing
    snf::start_cheat_caller_address(token_bridge.contract_address, SECURITY_AGENT());
    token_bridge_admin.pause();
    snf::stop_cheat_caller_address(token_bridge.contract_address);

    token_bridge.deposit(usdc_address, 100, snf::test_address());
}

#[test]
#[should_panic(expected: ('ERC20: insufficient balance',))]
fn deposit_insufficient_balance() {
    let (token_bridge, _, usdc_address, _) = setup(true);
    let usdc = IERC20Dispatcher { contract_address: usdc_address };

    usdc.approve(token_bridge.contract_address, 200);
    token_bridge.deposit(usdc_address, 200, snf::test_address());
}

#[test]
#[should_panic(expected: ('ERC20: insufficient allowance',))]
fn deposit_insufficient_allowance() {
    let (token_bridge, _, usdc_address, _) = setup(true);
    token_bridge.deposit(usdc_address, 100, snf::test_address());
}


#[test]
#[should_panic(expected: ('Only servicing tokens',))]
fn deposit_deactivated() {
    let (token_bridge, _, usdc_address, _) = setup(true);
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address,
    };

    snf::start_cheat_caller_address(token_bridge.contract_address, TOKEN_ADMIN());
    token_bridge_admin.deactivate_token(usdc_address);
    snf::stop_cheat_caller_address(TOKEN_ADMIN());

    token_bridge.deposit(usdc_address, 100, snf::test_address());
}


#[test]
fn deposit_with_message_ok() {
    let (token_bridge, mut spy, usdc_address, _) = setup(true);

    let usdc = IERC20Dispatcher { contract_address: usdc_address };
    let mut calldata = ArrayTrait::new();
    'param1'.serialize(ref calldata);
    'param2'.serialize(ref calldata);

    let initial_bridge_balance = usdc.balance_of(token_bridge.contract_address);
    usdc.approve(token_bridge.contract_address, 100);
    token_bridge.deposit_with_message(usdc_address, 100, snf::test_address(), calldata.span());

    assert(
        usdc.balance_of(token_bridge.contract_address) == initial_bridge_balance + 100,
        'incorrect amount recieved',
    );

    let expected_deposit_with_message = TokenBridge::DepositWithMessage {
        sender: snf::test_address(),
        token: usdc_address,
        amount: 100,
        appchain_recipient: snf::test_address(),
        message: calldata.span(),
        nonce: 1,
    };

    spy
        .assert_emitted(
            @array![
                (
                    token_bridge.contract_address,
                    Event::DepositWithMessage(expected_deposit_with_message),
                ),
            ],
        );
}

#[test]
#[should_panic(expected: ('Pausable: paused',))]
fn deposit_with_message_paused() {
    let (token_bridge, _, usdc_address, _) = setup(true);
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address,
    };

    // Set up security agent before pausing
    snf::start_cheat_caller_address(token_bridge.contract_address, SECURITY_AGENT());
    token_bridge_admin.pause();
    snf::stop_cheat_caller_address(token_bridge.contract_address);

    token_bridge.deposit_with_message(usdc_address, 100, snf::test_address(), array![].span());
}

#[test]
fn deposit_with_message_empty_message_ok() {
    let (token_bridge, mut spy, usdc_address, _) = setup(true);
    let usdc = IERC20Dispatcher { contract_address: usdc_address };

    let mut calldata = ArrayTrait::new();
    'param1'.serialize(ref calldata);
    'param2'.serialize(ref calldata);

    let initial_bridge_balance = usdc.balance_of(token_bridge.contract_address);
    usdc.approve(token_bridge.contract_address, 100);
    token_bridge.deposit_with_message(usdc_address, 100, snf::test_address(), calldata.span());

    assert(
        usdc.balance_of(token_bridge.contract_address) == initial_bridge_balance + 100,
        'incorrect amount recieved',
    );

    let expected_deposit_with_message = TokenBridge::DepositWithMessage {
        sender: snf::test_address(),
        token: usdc_address,
        amount: 100,
        appchain_recipient: snf::test_address(),
        message: calldata.span(),
        nonce: 1,
    };

    spy
        .assert_emitted(
            @array![
                (
                    token_bridge.contract_address,
                    Event::DepositWithMessage(expected_deposit_with_message),
                ),
            ],
        );
}

#[test]
#[should_panic(expected: ('ERC20: insufficient balance',))]
fn deposit_with_message_insufficient_balance() {
    let (token_bridge, _, usdc_address, _) = setup(true);

    let usdc = IERC20Dispatcher { contract_address: usdc_address };
    usdc.approve(token_bridge.contract_address, 200);

    let mut calldata = ArrayTrait::new();
    'param1'.serialize(ref calldata);
    'param2'.serialize(ref calldata);
    token_bridge.deposit_with_message(usdc_address, 200, snf::test_address(), calldata.span());
}

#[test]
#[should_panic(expected: ('ERC20: insufficient allowance',))]
fn deposit_with_message_insufficient_allowance() {
    let (token_bridge, _, usdc_address, _) = setup(true);
    let mut calldata = ArrayTrait::new();
    'param1'.serialize(ref calldata);
    'param2'.serialize(ref calldata);
    token_bridge.deposit_with_message(usdc_address, 100, snf::test_address(), calldata.span());
}

#[test]
#[should_panic(expected: ('Only servicing tokens',))]
fn deposit_with_message_deactivated() {
    let (token_bridge, _, usdc_address, _) = setup(true);
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address,
    };

    snf::start_cheat_caller_address(token_bridge.contract_address, TOKEN_ADMIN());
    token_bridge_admin.deactivate_token(usdc_address);
    snf::stop_cheat_caller_address(token_bridge.contract_address);

    let mut calldata = ArrayTrait::new();
    'param1'.serialize(ref calldata);
    'param2'.serialize(ref calldata);
    token_bridge.deposit_with_message(usdc_address, 100, snf::test_address(), calldata.span());
}


#[test]
fn deposit_cancel_request_ok() {
    let (token_bridge, mut spy, usdc_address, _) = setup(true);
    let usdc = IERC20Dispatcher { contract_address: usdc_address };

    usdc.approve(token_bridge.contract_address, 100);
    token_bridge.deposit(usdc_address, 100, snf::test_address());

    token_bridge.deposit_cancel_request(usdc_address, 100, snf::test_address(), 1);

    let expected_deposit_cancel = TokenBridge::DepositCancelRequest {
        sender: snf::test_address(),
        token: usdc_address,
        amount: 100,
        appchain_recipient: snf::test_address(),
        nonce: 1,
    };

    spy
        .assert_emitted(
            @array![
                (
                    token_bridge.contract_address,
                    Event::DepostiCancelRequest(expected_deposit_cancel),
                ),
            ],
        );
}

#[test]
#[should_panic(expected: ('Pausable: paused',))]
fn deposit_cancel_request_paused() {
    let (token_bridge, _, usdc_address, _) = setup(true);
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address,
    };

    // Set up security agent before pausing
    snf::start_cheat_caller_address(token_bridge.contract_address, SECURITY_AGENT());
    token_bridge_admin.pause();
    snf::stop_cheat_caller_address(token_bridge.contract_address);

    token_bridge.deposit_cancel_request(usdc_address, 100, snf::test_address(), 1);
}

#[test]
#[should_panic(expected: ('NO_MESSAGE_TO_CANCEL',))]
fn deposit_cancel_request_no_deposit() {
    let (token_bridge, _, usdc_address, _) = setup(true);
    token_bridge.deposit_cancel_request(usdc_address, 100, snf::test_address(), 2);
}

#[test]
#[should_panic(expected: ('NO_MESSAGE_TO_CANCEL',))]
fn deposit_cancel_request_different_user() {
    let (token_bridge, _, usdc_address, _) = setup(true);
    let usdc = IERC20Dispatcher { contract_address: usdc_address };

    usdc.approve(token_bridge.contract_address, 100);
    token_bridge.deposit(usdc_address, 100, snf::test_address());

    snf::start_cheat_caller_address(token_bridge.contract_address, 'user2'.try_into().unwrap());
    token_bridge.deposit_cancel_request(usdc_address, 100, snf::test_address(), 2);
}


#[test]
fn deposit_with_message_cancel_request_ok() {
    let (token_bridge, mut spy, usdc_address, _) = setup(true);
    let usdc = IERC20Dispatcher { contract_address: usdc_address };

    let mut calldata = ArrayTrait::new();
    'param1'.serialize(ref calldata);
    'param2'.serialize(ref calldata);

    usdc.approve(token_bridge.contract_address, 100);
    token_bridge.deposit_with_message(usdc_address, 100, snf::test_address(), calldata.span());

    token_bridge
        .deposit_with_message_cancel_request(
            usdc_address, 100, snf::test_address(), calldata.span(), 1,
        );

    let expected_deposit_cancel = TokenBridge::DepositWithMessageCancelRequest {
        sender: snf::test_address(),
        token: usdc_address,
        amount: 100,
        appchain_recipient: snf::test_address(),
        message: calldata.span(),
        nonce: 1,
    };

    spy
        .assert_emitted(
            @array![
                (
                    token_bridge.contract_address,
                    Event::DepositWithMessageCancelRequest(expected_deposit_cancel),
                ),
            ],
        );
}

#[test]
#[should_panic(expected: ('Pausable: paused',))]
fn deposit_with_message_cancel_request_paused() {
    let (token_bridge, _, usdc_address, _) = setup(true);
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address,
    };

    // Set up security agent before pausing
    snf::start_cheat_caller_address(token_bridge.contract_address, SECURITY_AGENT());
    token_bridge_admin.pause();
    snf::stop_cheat_caller_address(token_bridge.contract_address);

    token_bridge
        .deposit_with_message_cancel_request(
            usdc_address, 100, snf::test_address(), array![].span(), 1,
        );
}

#[test]
#[should_panic(expected: ('NO_MESSAGE_TO_CANCEL',))]
fn deposit_with_message_cancel_request_no_deposit() {
    let (token_bridge, _, usdc_address, _) = setup(true);

    let mut calldata = ArrayTrait::new();
    'param1'.serialize(ref calldata);
    'param2'.serialize(ref calldata);

    token_bridge
        .deposit_with_message_cancel_request(
            usdc_address, 100, snf::test_address(), calldata.span(), 2,
        );
}

#[test]
#[should_panic(expected: ('NO_MESSAGE_TO_CANCEL',))]
fn deposit_with_message_cancel_request_different_user() {
    let (token_bridge, _, usdc_address, _) = setup(true);
    let usdc = IERC20Dispatcher { contract_address: usdc_address };

    let mut calldata = ArrayTrait::new();
    'param1'.serialize(ref calldata);
    'param2'.serialize(ref calldata);

    usdc.approve(token_bridge.contract_address, 100);
    token_bridge.deposit_with_message(usdc_address, 100, snf::test_address(), calldata.span());

    snf::start_cheat_caller_address(token_bridge.contract_address, 'user2'.try_into().unwrap());
    token_bridge
        .deposit_with_message_cancel_request(
            usdc_address, 100, snf::test_address(), calldata.span(), 2,
        );
}

