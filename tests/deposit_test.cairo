use snforge_std as snf;
use snforge_std::{EventSpy, EventSpyAssertionsTrait};
use starknet::ContractAddress;
use starknet_bridge::mocks::messaging::IMockMessagingDispatcher;
use starknet_bridge::bridge::{
    ITokenBridgeDispatcher, ITokenBridgeDispatcherTrait, ITokenBridgeAdminDispatcher,
    ITokenBridgeAdminDispatcherTrait, TokenBridge, TokenBridge::Event,
};

use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use starknet::contract_address::{contract_address_const};
use super::constants::{OWNER};
use starknet_bridge::bridge::tests::utils::setup::{
    deploy_erc20, deploy_token_bridge_with_messaging, enroll_token_and_settle
};

fn setup() -> (ITokenBridgeDispatcher, EventSpy, ContractAddress, IMockMessagingDispatcher) {
    let (token_bridge, mut spy, messaging_mock) = deploy_token_bridge_with_messaging();
    let usdc_address = deploy_erc20("usdc", "usdc");
    enroll_token_and_settle(token_bridge, messaging_mock, usdc_address);
    (token_bridge, spy, usdc_address, messaging_mock)
}

#[test]
fn deposit_ok() {
    let (token_bridge, mut spy, usdc_address, _) = setup();

    let usdc = IERC20Dispatcher { contract_address: usdc_address };
    let initial_bridge_balance = usdc.balance_of(token_bridge.contract_address);
    usdc.approve(token_bridge.contract_address, 100);
    token_bridge.deposit(usdc_address, 100, snf::test_address());

    assert(
        usdc.balance_of(token_bridge.contract_address) == initial_bridge_balance + 100,
        'incorrect amount recieved'
    );

    let expected_deposit = TokenBridge::Deposit {
        sender: snf::test_address(),
        token: usdc_address,
        amount: 100,
        appchain_recipient: snf::test_address(),
        nonce: 2
    };

    spy.assert_emitted(@array![(token_bridge.contract_address, Event::Deposit(expected_deposit))]);
}


#[test]
#[should_panic(expected: ('ERC20: insufficient balance',))]
fn deposit_insufficient_balance() {
    let (token_bridge, _, usdc_address, _) = setup();
    let usdc = IERC20Dispatcher { contract_address: usdc_address };

    usdc.approve(token_bridge.contract_address, 200);
    token_bridge.deposit(usdc_address, 200, snf::test_address());
}

#[test]
#[should_panic(expected: ('ERC20: insufficient allowance',))]
fn deposit_insufficient_allowance() {
    let (token_bridge, _, usdc_address, _) = setup();
    token_bridge.deposit(usdc_address, 100, snf::test_address());
}


#[test]
#[should_panic(expected: ('Only servicing tokens',))]
fn deposit_deactivated() {
    let (token_bridge, _, usdc_address, _) = setup();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address
    };

    snf::start_cheat_caller_address(token_bridge.contract_address, OWNER());
    token_bridge_admin.deactivate_token(usdc_address);
    snf::stop_cheat_caller_address(OWNER());

    token_bridge.deposit(usdc_address, 100, snf::test_address());
}


#[test]
fn deposit_with_message_ok() {
    let (token_bridge, mut spy, usdc_address, _) = setup();

    let usdc = IERC20Dispatcher { contract_address: usdc_address };
    let mut calldata = ArrayTrait::new();
    'param1'.serialize(ref calldata);
    'param2'.serialize(ref calldata);

    let initial_bridge_balance = usdc.balance_of(token_bridge.contract_address);
    usdc.approve(token_bridge.contract_address, 100);
    token_bridge.deposit_with_message(usdc_address, 100, snf::test_address(), calldata.span());

    assert(
        usdc.balance_of(token_bridge.contract_address) == initial_bridge_balance + 100,
        'incorrect amount recieved'
    );

    let expected_deposit_with_message = TokenBridge::DepositWithMessage {
        sender: snf::test_address(),
        token: usdc_address,
        amount: 100,
        appchain_recipient: snf::test_address(),
        message: calldata.span(),
        nonce: 2
    };

    spy
        .assert_emitted(
            @array![
                (
                    token_bridge.contract_address,
                    Event::DepositWithMessage(expected_deposit_with_message)
                )
            ]
        );
}

#[test]
fn deposit_with_message_empty_message_ok() {
    let (token_bridge, mut spy, usdc_address, _) = setup();
    let usdc = IERC20Dispatcher { contract_address: usdc_address };

    let mut calldata = ArrayTrait::new();
    'param1'.serialize(ref calldata);
    'param2'.serialize(ref calldata);

    let initial_bridge_balance = usdc.balance_of(token_bridge.contract_address);
    usdc.approve(token_bridge.contract_address, 100);
    token_bridge.deposit_with_message(usdc_address, 100, snf::test_address(), calldata.span());

    assert(
        usdc.balance_of(token_bridge.contract_address) == initial_bridge_balance + 100,
        'incorrect amount recieved'
    );

    let expected_deposit_with_message = TokenBridge::DepositWithMessage {
        sender: snf::test_address(),
        token: usdc_address,
        amount: 100,
        appchain_recipient: snf::test_address(),
        message: calldata.span(),
        nonce: 2
    };

    spy
        .assert_emitted(
            @array![
                (
                    token_bridge.contract_address,
                    Event::DepositWithMessage(expected_deposit_with_message)
                )
            ]
        );
}

#[test]
#[should_panic(expected: ('ERC20: insufficient balance',))]
fn deposit_with_message_insufficient_balance() {
    let (token_bridge, _, usdc_address, _) = setup();

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
    let (token_bridge, _, usdc_address, _) = setup();
    let mut calldata = ArrayTrait::new();
    'param1'.serialize(ref calldata);
    'param2'.serialize(ref calldata);
    token_bridge.deposit_with_message(usdc_address, 100, snf::test_address(), calldata.span());
}

#[test]
#[should_panic(expected: ('Only servicing tokens',))]
fn deposit_with_message_deactivated() {
    let (token_bridge, _, usdc_address, _) = setup();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address
    };

    snf::start_cheat_caller_address(token_bridge.contract_address, OWNER());
    token_bridge_admin.deactivate_token(usdc_address);
    snf::stop_cheat_caller_address(OWNER());

    let mut calldata = ArrayTrait::new();
    'param1'.serialize(ref calldata);
    'param2'.serialize(ref calldata);
    token_bridge.deposit_with_message(usdc_address, 100, snf::test_address(), calldata.span());
}


#[test]
fn deposit_cancel_request_ok() {
    let (token_bridge, mut spy, usdc_address, _) = setup();
    let usdc = IERC20Dispatcher { contract_address: usdc_address };

    usdc.approve(token_bridge.contract_address, 100);
    token_bridge.deposit(usdc_address, 100, snf::test_address());

    token_bridge.deposit_cancel_request(usdc_address, 100, snf::test_address(), 2);

    let expected_deposit_cancel = TokenBridge::DepositCancelRequest {
        sender: snf::test_address(),
        token: usdc_address,
        amount: 100,
        appchain_recipient: snf::test_address(),
        nonce: 2
    };

    spy
        .assert_emitted(
            @array![
                (
                    token_bridge.contract_address,
                    Event::DepostiCancelRequest(expected_deposit_cancel)
                )
            ]
        );
}


#[test]
#[should_panic(expected: ('NO_MESSAGE_TO_CANCEL',))]
fn deposit_cancel_request_no_deposit() {
    let (token_bridge, _, usdc_address, _) = setup();
    token_bridge.deposit_cancel_request(usdc_address, 100, snf::test_address(), 2);
}

#[test]
#[should_panic(expected: ('NO_MESSAGE_TO_CANCEL',))]
fn deposit_cancel_request_different_user() {
    let (token_bridge, _, usdc_address, _) = setup();
    let usdc = IERC20Dispatcher { contract_address: usdc_address };

    usdc.approve(token_bridge.contract_address, 100);
    token_bridge.deposit(usdc_address, 100, snf::test_address());

    snf::start_cheat_caller_address(
        token_bridge.contract_address, contract_address_const::<'user2'>()
    );
    token_bridge.deposit_cancel_request(usdc_address, 100, snf::test_address(), 2);
}


#[test]
fn deposit_with_message_cancel_request_ok() {
    let (token_bridge, mut spy, usdc_address, _) = setup();
    let usdc = IERC20Dispatcher { contract_address: usdc_address };

    let mut calldata = ArrayTrait::new();
    'param1'.serialize(ref calldata);
    'param2'.serialize(ref calldata);

    usdc.approve(token_bridge.contract_address, 100);
    token_bridge.deposit_with_message(usdc_address, 100, snf::test_address(), calldata.span());

    token_bridge
        .deposit_with_message_cancel_request(
            usdc_address, 100, snf::test_address(), calldata.span(), 2
        );

    let expected_deposit_cancel = TokenBridge::DepositWithMessageCancelRequest {
        sender: snf::test_address(),
        token: usdc_address,
        amount: 100,
        appchain_recipient: snf::test_address(),
        message: calldata.span(),
        nonce: 2
    };

    spy
        .assert_emitted(
            @array![
                (
                    token_bridge.contract_address,
                    Event::DepositWithMessageCancelRequest(expected_deposit_cancel)
                )
            ]
        );
}


#[test]
#[should_panic(expected: ('NO_MESSAGE_TO_CANCEL',))]
fn deposit_with_message_cancel_request_no_deposit() {
    let (token_bridge, _, usdc_address, _) = setup();

    let mut calldata = ArrayTrait::new();
    'param1'.serialize(ref calldata);
    'param2'.serialize(ref calldata);

    token_bridge
        .deposit_with_message_cancel_request(
            usdc_address, 100, snf::test_address(), calldata.span(), 2
        );
}

#[test]
#[should_panic(expected: ('NO_MESSAGE_TO_CANCEL',))]
fn deposit_with_message_cancel_request_different_user() {
    let (token_bridge, _, usdc_address, _) = setup();
    let usdc = IERC20Dispatcher { contract_address: usdc_address };

    let mut calldata = ArrayTrait::new();
    'param1'.serialize(ref calldata);
    'param2'.serialize(ref calldata);

    usdc.approve(token_bridge.contract_address, 100);
    token_bridge.deposit_with_message(usdc_address, 100, snf::test_address(), calldata.span());

    snf::start_cheat_caller_address(
        token_bridge.contract_address, contract_address_const::<'user2'>()
    );
    token_bridge
        .deposit_with_message_cancel_request(
            usdc_address, 100, snf::test_address(), calldata.span(), 2
        );
}

