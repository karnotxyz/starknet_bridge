use core::num::traits::zero::Zero;
use starknet_bridge::bridge::token_bridge::TokenBridge::__member_module_token_settings::InternalContractMemberStateTrait;
use core::array::ArrayTrait;
use core::serde::Serde;
use core::result::ResultTrait;
use core::option::OptionTrait;
use core::traits::TryInto;
use snforge_std as snf;
use snforge_std::{
    ContractClassTrait, EventSpy, EventSpyTrait, EventsFilterTrait, EventSpyAssertionsTrait
};
use starknet::{ContractAddress, storage::StorageMemberAccessTrait};
use starknet_bridge::mocks::{
    messaging::{IMockMessagingDispatcherTrait, IMockMessagingDispatcher}, erc20::ERC20
};
use piltover::messaging::{IMessaging, IMessagingDispatcher, IMessagingDispatcherTrait};
use starknet_bridge::bridge::{
    ITokenBridge, ITokenBridgeAdmin, ITokenBridgeDispatcher, ITokenBridgeDispatcherTrait,
    ITokenBridgeAdminDispatcher, ITokenBridgeAdminDispatcherTrait, IWithdrawalLimitStatusDispatcher,
    IWithdrawalLimitStatusDispatcherTrait, TokenBridge, TokenBridge::Event,
    types::{TokenStatus, TokenSettings}
};
use openzeppelin::access::ownable::{
    OwnableComponent, OwnableComponent::Event as OwnableEvent,
    interface::{IOwnableTwoStepDispatcher, IOwnableTwoStepDispatcherTrait}
};

use openzeppelin::token::erc20::interface::{IERC20, IERC20Dispatcher, IERC20DispatcherTrait};
use starknet::contract_address::{contract_address_const};
use super::constants::{OWNER, L3_BRIDGE_ADDRESS, DELAY_TIME};
use super::setup::{deploy_erc20, deploy_token_bridge_with_messaging, deploy_token_bridge};
use starknet_bridge::constants;
use starknet_bridge::bridge::tests::utils::message_payloads;


fn enroll_token_and_settle(
    token_bridge: ITokenBridgeDispatcher,
    messaging_mock: IMockMessagingDispatcher,
    token: ContractAddress
) {
    assert(token_bridge.get_status(token) == TokenStatus::Unknown, 'Should be Unknown');

    token_bridge.enroll_token(token);
    assert(token_bridge.get_status(token) == TokenStatus::Pending, 'Should be Pending');

    // Settles the message sent to appchain
    messaging_mock
        .process_last_message_to_appchain(
            L3_BRIDGE_ADDRESS(),
            constants::HANDLE_TOKEN_DEPLOYMENT_SELECTOR,
            message_payloads::deployment_message_payload(token)
        );

    token_bridge.check_deployment_status(token);

    let final_status = token_bridge.get_status(token);
    assert(final_status == TokenStatus::Active, 'Should be Active');
}


#[test]
fn deposit_ok() {
    let (token_bridge, _, messaging_mock) = deploy_token_bridge_with_messaging();
    let usdc_address = deploy_erc20("usdc", "usdc");
    let usdc = IERC20Dispatcher { contract_address: usdc_address };

    snf::start_cheat_caller_address(usdc_address, OWNER());
    usdc.transfer(snf::test_address(), 100);
    snf::stop_cheat_caller_address(usdc_address);

    enroll_token_and_settle(token_bridge, messaging_mock, usdc_address);

    usdc.approve(token_bridge.contract_address, 100);
    token_bridge.deposit(usdc_address, 100, snf::test_address());
}


#[test]
#[should_panic(expected: ('ERC20: insufficient balance',))]
fn deposit_issufficient_balance() {
    let (token_bridge, _, messaging_mock) = deploy_token_bridge_with_messaging();
    let usdc_address = deploy_erc20("usdc", "usdc");
    let usdc = IERC20Dispatcher { contract_address: usdc_address };

    snf::start_cheat_caller_address(usdc_address, OWNER());
    usdc.transfer(snf::test_address(), 100);
    snf::stop_cheat_caller_address(usdc_address);

    enroll_token_and_settle(token_bridge, messaging_mock, usdc_address);

    usdc.approve(token_bridge.contract_address, 200);
    token_bridge.deposit(usdc_address, 200, snf::test_address());
}

#[test]
#[should_panic(expected: ('ERC20: insufficient allowance',))]
fn deposit_insufficient_allowance() {
    let (token_bridge, _, messaging_mock) = deploy_token_bridge_with_messaging();
    let usdc_address = deploy_erc20("usdc", "usdc");
    let usdc = IERC20Dispatcher { contract_address: usdc_address };

    snf::start_cheat_caller_address(usdc_address, OWNER());
    usdc.transfer(snf::test_address(), 100);
    snf::stop_cheat_caller_address(usdc_address);

    enroll_token_and_settle(token_bridge, messaging_mock, usdc_address);

    token_bridge.deposit(usdc_address, 100, snf::test_address());
}

#[test]
fn deposit_with_message_ok() {
    let (token_bridge, _, messaging_mock) = deploy_token_bridge_with_messaging();
    let usdc_address = deploy_erc20("usdc", "usdc");
    let usdc = IERC20Dispatcher { contract_address: usdc_address };

    snf::start_cheat_caller_address(usdc_address, OWNER());
    usdc.transfer(snf::test_address(), 100);
    snf::stop_cheat_caller_address(usdc_address);

    enroll_token_and_settle(token_bridge, messaging_mock, usdc_address);

    let mut calldata = ArrayTrait::new();
    'param1'.serialize(ref calldata);
    'param2'.serialize(ref calldata);

    usdc.approve(token_bridge.contract_address, 100);
    token_bridge.deposit_with_message(usdc_address, 100, snf::test_address(), calldata.span());
}

#[test]
fn deposit_with_message_empty_message_ok() {
    let (token_bridge, _, messaging_mock) = deploy_token_bridge_with_messaging();
    let usdc_address = deploy_erc20("usdc", "usdc");
    let usdc = IERC20Dispatcher { contract_address: usdc_address };

    snf::start_cheat_caller_address(usdc_address, OWNER());
    usdc.transfer(snf::test_address(), 100);
    snf::stop_cheat_caller_address(usdc_address);

    enroll_token_and_settle(token_bridge, messaging_mock, usdc_address);

    let mut calldata = ArrayTrait::new();
    'param1'.serialize(ref calldata);
    'param2'.serialize(ref calldata);

    usdc.approve(token_bridge.contract_address, 100);
    token_bridge.deposit_with_message(usdc_address, 100, snf::test_address(), calldata.span());
}

#[test]
#[should_panic(expected: ('Only servicing tokens',))]
fn deposit_deactivated() {
    let (token_bridge, _, messaging_mock) = deploy_token_bridge_with_messaging();
    let usdc_address = deploy_erc20("usdc", "usdc");
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address
    };

    enroll_token_and_settle(token_bridge, messaging_mock, usdc_address);

    snf::start_cheat_caller_address(token_bridge.contract_address, OWNER());
    token_bridge_admin.deactivate_token(usdc_address);
    snf::stop_cheat_caller_address(OWNER());

    token_bridge.deposit(usdc_address, 100, snf::test_address());
}

#[test]
#[should_panic(expected: ('Only servicing tokens',))]
fn deposit_with_message_deactivated() {
    let (token_bridge, _, messaging_mock) = deploy_token_bridge_with_messaging();
    let usdc_address = deploy_erc20("usdc", "usdc");
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address
    };

    enroll_token_and_settle(token_bridge, messaging_mock, usdc_address);

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
    let (token_bridge, mut spy, messaging_mock) = deploy_token_bridge_with_messaging();
    let usdc_address = deploy_erc20("usdc", "usdc");
    let usdc = IERC20Dispatcher { contract_address: usdc_address };

    snf::start_cheat_caller_address(usdc_address, OWNER());
    usdc.transfer(snf::test_address(), 100);
    snf::stop_cheat_caller_address(usdc_address);

    enroll_token_and_settle(token_bridge, messaging_mock, usdc_address);

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
    let (token_bridge, _, messaging_mock) = deploy_token_bridge_with_messaging();
    let usdc_address = deploy_erc20("usdc", "usdc");

    enroll_token_and_settle(token_bridge, messaging_mock, usdc_address);

    token_bridge.deposit_cancel_request(usdc_address, 100, snf::test_address(), 2);
}

#[test]
#[should_panic(expected: ('NO_MESSAGE_TO_CANCEL',))]
fn deposit_cancel_request_different_user() {
    let (token_bridge, _, messaging_mock) = deploy_token_bridge_with_messaging();
    let usdc_address = deploy_erc20("usdc", "usdc");
    let usdc = IERC20Dispatcher { contract_address: usdc_address };

    snf::start_cheat_caller_address(usdc_address, OWNER());
    usdc.transfer(snf::test_address(), 100);
    snf::stop_cheat_caller_address(usdc_address);

    enroll_token_and_settle(token_bridge, messaging_mock, usdc_address);

    usdc.approve(token_bridge.contract_address, 100);
    token_bridge.deposit(usdc_address, 100, snf::test_address());

    snf::start_cheat_caller_address(
        token_bridge.contract_address, contract_address_const::<'user2'>()
    );
    token_bridge.deposit_cancel_request(usdc_address, 100, snf::test_address(), 2);
}


#[test]
fn deposit_with_message_cancel_request_ok() {
    let (token_bridge, mut spy, messaging_mock) = deploy_token_bridge_with_messaging();
    let usdc_address = deploy_erc20("usdc", "usdc");
    let usdc = IERC20Dispatcher { contract_address: usdc_address };

    snf::start_cheat_caller_address(usdc_address, OWNER());
    usdc.transfer(snf::test_address(), 100);
    snf::stop_cheat_caller_address(usdc_address);

    enroll_token_and_settle(token_bridge, messaging_mock, usdc_address);

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
    let (token_bridge, _, messaging_mock) = deploy_token_bridge_with_messaging();
    let usdc_address = deploy_erc20("usdc", "usdc");

    enroll_token_and_settle(token_bridge, messaging_mock, usdc_address);

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
    let (token_bridge, _, messaging_mock) = deploy_token_bridge_with_messaging();
    let usdc_address = deploy_erc20("usdc", "usdc");
    let usdc = IERC20Dispatcher { contract_address: usdc_address };

    snf::start_cheat_caller_address(usdc_address, OWNER());
    usdc.transfer(snf::test_address(), 100);
    snf::stop_cheat_caller_address(usdc_address);

    enroll_token_and_settle(token_bridge, messaging_mock, usdc_address);

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

