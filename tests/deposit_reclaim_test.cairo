use core::array::ArrayTrait;
use core::option::OptionTrait;
use core::traits::TryInto;
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std as snf;
use snforge_std::{EventSpy, EventSpyAssertionsTrait};
use starknet::ContractAddress;
use starknet_bridge::bridge::TokenBridge::Event;
use starknet_bridge::bridge::tests::utils::setup::{
    deploy_erc20, deploy_token_bridge_with_messaging, enroll_token_and_settle,
};
use starknet_bridge::bridge::{ITokenBridgeDispatcher, ITokenBridgeDispatcherTrait, TokenBridge};
use starknet_bridge::mocks::messaging::IMockMessagingDispatcher;
use super::constants::DELAY_TIME;

fn setup() -> (ITokenBridgeDispatcher, EventSpy, ContractAddress, IMockMessagingDispatcher) {
    let (token_bridge, mut spy, messaging_mock) = deploy_token_bridge_with_messaging();
    let usdc_address = deploy_erc20("usdc", "usdc");
    enroll_token_and_settle(token_bridge, messaging_mock, usdc_address);
    (token_bridge, spy, usdc_address, messaging_mock)
}

#[test]
fn deposit_reclaim_ok() {
    let (token_bridge, mut spy, usdc_address, _) = setup();
    let usdc = IERC20Dispatcher { contract_address: usdc_address };

    usdc.approve(token_bridge.contract_address, 100);
    token_bridge.deposit(usdc_address, 100, snf::test_address());

    snf::start_cheat_block_timestamp_global(5);
    token_bridge.deposit_cancel_request(usdc_address, 100, snf::test_address(), 1);

    snf::start_cheat_block_timestamp_global(
        starknet::get_block_timestamp() + DELAY_TIME.try_into().unwrap() + 10,
    );
    let initial_user_balance = usdc.balance_of(snf::test_address());
    token_bridge.deposit_reclaim(usdc_address, 100, snf::test_address(), 1);
    assert(
        usdc.balance_of(snf::test_address()) == initial_user_balance + 100, 'deposit not recieved',
    );

    let expected_deposit_cancel = TokenBridge::DepositCancelRequest {
        sender: snf::test_address(),
        token: usdc_address,
        amount: 100,
        appchain_recipient: snf::test_address(),
        nonce: 1,
    };

    let expected_deposit_reclaim = TokenBridge::DepositReclaimed {
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
                (token_bridge.contract_address, Event::DepositReclaimed(expected_deposit_reclaim)),
            ],
        );
}

#[test]
#[should_panic(expected: ('CANCELLATION_NOT_ALLOWED_YET',))]
fn deposit_reclaim_delay_not_reached() {
    let (token_bridge, _, usdc_address, _) = setup();
    let usdc = IERC20Dispatcher { contract_address: usdc_address };

    usdc.approve(token_bridge.contract_address, 100);
    token_bridge.deposit(usdc_address, 100, snf::test_address());

    snf::start_cheat_block_timestamp_global(5);
    token_bridge.deposit_cancel_request(usdc_address, 100, snf::test_address(), 1);

    token_bridge.deposit_reclaim(usdc_address, 100, snf::test_address(), 1);
}


#[test]
#[should_panic(expected: ('CANCELLATION_NOT_REQUESTED',))]
fn deposit_reclaim_not_cancelled() {
    let (token_bridge, _, usdc_address, _) = setup();
    let usdc = IERC20Dispatcher { contract_address: usdc_address };

    usdc.approve(token_bridge.contract_address, 100);
    token_bridge.deposit(usdc_address, 100, snf::test_address());

    snf::start_cheat_block_timestamp_global(
        starknet::get_block_timestamp() + DELAY_TIME.try_into().unwrap() + 10,
    );

    token_bridge.deposit_reclaim(usdc_address, 100, snf::test_address(), 1);
}

#[test]
#[should_panic(expected: ('NO_MESSAGE_TO_CANCEL',))]
fn deposit_reclaim_different_user() {
    let (token_bridge, _, usdc_address, _) = setup();
    let usdc = IERC20Dispatcher { contract_address: usdc_address };

    usdc.approve(token_bridge.contract_address, 100);
    token_bridge.deposit(usdc_address, 100, snf::test_address());

    snf::start_cheat_block_timestamp_global(5);
    token_bridge.deposit_cancel_request(usdc_address, 100, snf::test_address(), 1);

    snf::start_cheat_block_timestamp_global(
        starknet::get_block_timestamp() + DELAY_TIME.try_into().unwrap() + 10,
    );

    snf::start_cheat_caller_address_global('user2'.try_into().unwrap());
    token_bridge.deposit_reclaim(usdc_address, 100, snf::test_address(), 1);
}


#[test]
fn deposit_with_message_reclaim_ok() {
    let (token_bridge, mut spy, usdc_address, _) = setup();
    let usdc = IERC20Dispatcher { contract_address: usdc_address };

    let mut calldata = ArrayTrait::new();
    'param1'.serialize(ref calldata);
    'param2'.serialize(ref calldata);

    usdc.approve(token_bridge.contract_address, 100);
    token_bridge.deposit_with_message(usdc_address, 100, snf::test_address(), calldata.span());

    snf::start_cheat_block_timestamp_global(5);
    token_bridge
        .deposit_with_message_cancel_request(
            usdc_address, 100, snf::test_address(), calldata.span(), 1,
        );

    snf::start_cheat_block_timestamp_global(
        starknet::get_block_timestamp() + DELAY_TIME.try_into().unwrap() + 10,
    );

    let initial_user_balance = usdc.balance_of(snf::test_address());
    token_bridge
        .deposit_with_message_reclaim(usdc_address, 100, snf::test_address(), calldata.span(), 1);
    assert(
        usdc.balance_of(snf::test_address()) == initial_user_balance + 100, 'deposit not recieved',
    );

    let expected_deposit_cancel = TokenBridge::DepositWithMessageCancelRequest {
        sender: snf::test_address(),
        token: usdc_address,
        amount: 100,
        appchain_recipient: snf::test_address(),
        message: calldata.span(),
        nonce: 1,
    };

    let expected_deposit_reclaim = TokenBridge::DepositWithMessageReclaimed {
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
                (
                    token_bridge.contract_address,
                    Event::DepositWithMessageReclaimed(expected_deposit_reclaim),
                ),
            ],
        );
}

#[test]
#[should_panic(expected: ('CANCELLATION_NOT_ALLOWED_YET',))]
fn deposit_with_message_reclaim_delay_not_reached() {
    let (token_bridge, _, usdc_address, _) = setup();
    let usdc = IERC20Dispatcher { contract_address: usdc_address };

    let mut calldata = ArrayTrait::new();
    'param1'.serialize(ref calldata);
    'param2'.serialize(ref calldata);

    usdc.approve(token_bridge.contract_address, 100);
    token_bridge.deposit_with_message(usdc_address, 100, snf::test_address(), calldata.span());

    snf::start_cheat_block_timestamp_global(5);
    token_bridge
        .deposit_with_message_cancel_request(
            usdc_address, 100, snf::test_address(), calldata.span(), 1,
        );

    token_bridge
        .deposit_with_message_reclaim(usdc_address, 100, snf::test_address(), calldata.span(), 1);
}


#[test]
#[should_panic(expected: ('CANCELLATION_NOT_REQUESTED',))]
fn deposit_wtih_message_reclaim_not_cancelled() {
    let (token_bridge, _, usdc_address, _) = setup();
    let usdc = IERC20Dispatcher { contract_address: usdc_address };

    let mut calldata = ArrayTrait::new();
    'param1'.serialize(ref calldata);
    'param2'.serialize(ref calldata);

    usdc.approve(token_bridge.contract_address, 100);
    token_bridge.deposit_with_message(usdc_address, 100, snf::test_address(), calldata.span());

    snf::start_cheat_block_timestamp_global(
        starknet::get_block_timestamp() + DELAY_TIME.try_into().unwrap() + 10,
    );

    token_bridge
        .deposit_with_message_reclaim(usdc_address, 100, snf::test_address(), calldata.span(), 1);
}

#[test]
#[should_panic(expected: ('NO_MESSAGE_TO_CANCEL',))]
fn deposit_reclaim_with_message_different_user() {
    let (token_bridge, _, usdc_address, _) = setup();
    let usdc = IERC20Dispatcher { contract_address: usdc_address };

    let mut calldata = ArrayTrait::new();
    'param1'.serialize(ref calldata);
    'param2'.serialize(ref calldata);

    usdc.approve(token_bridge.contract_address, 100);
    token_bridge.deposit_with_message(usdc_address, 100, snf::test_address(), calldata.span());

    snf::start_cheat_block_timestamp_global(5);
    token_bridge
        .deposit_with_message_cancel_request(
            usdc_address, 100, snf::test_address(), calldata.span(), 1,
        );

    snf::start_cheat_block_timestamp_global(
        starknet::get_block_timestamp() + DELAY_TIME.try_into().unwrap() + 10,
    );

    snf::start_cheat_caller_address_global('user2'.try_into().unwrap());
    token_bridge
        .deposit_with_message_reclaim(usdc_address, 100, snf::test_address(), calldata.span(), 1);
}
