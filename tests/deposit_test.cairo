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


#[test]
fn deposit_ok() {
    let (token_bridge, _, messaging_mock) = deploy_token_bridge_with_messaging();
    let usdc_address = deploy_erc20("usdc", "usdc");
    let usdc = IERC20Dispatcher { contract_address: usdc_address };

    snf::start_cheat_caller_address(usdc_address, OWNER());
    usdc.transfer(snf::test_address(), 100);
    snf::stop_cheat_caller_address(usdc_address);

    assert(token_bridge.get_status(usdc_address) == TokenStatus::Unknown, 'Should be Unknown');

    token_bridge.enroll_token(usdc_address);
    assert(token_bridge.get_status(usdc_address) == TokenStatus::Pending, 'Should be Pending');

    // Settles the message sent to appchain
    messaging_mock
        .process_last_message_to_appchain(
            L3_BRIDGE_ADDRESS(),
            constants::HANDLE_TOKEN_DEPLOYMENT_SELECTOR,
            message_payloads::deployment_message_payload(usdc_address)
        );

    token_bridge.check_deployment_status(usdc_address);

    let final_status = token_bridge.get_status(usdc_address);
    assert(final_status == TokenStatus::Active, 'Should be Active');

    assert(snf::test_address() == starknet::get_contract_address(), 'should be equal');
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

    assert(token_bridge.get_status(usdc_address) == TokenStatus::Unknown, 'Should be Unknown');

    token_bridge.enroll_token(usdc_address);
    assert(token_bridge.get_status(usdc_address) == TokenStatus::Pending, 'Should be Pending');

    // Settles the message sent to appchain
    messaging_mock
        .process_last_message_to_appchain(
            L3_BRIDGE_ADDRESS(),
            constants::HANDLE_TOKEN_DEPLOYMENT_SELECTOR,
            message_payloads::deployment_message_payload(usdc_address)
        );

    token_bridge.check_deployment_status(usdc_address);

    let final_status = token_bridge.get_status(usdc_address);
    assert(final_status == TokenStatus::Active, 'Should be Active');

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

    assert(token_bridge.get_status(usdc_address) == TokenStatus::Unknown, 'Should be Unknown');

    token_bridge.enroll_token(usdc_address);
    assert(token_bridge.get_status(usdc_address) == TokenStatus::Pending, 'Should be Pending');

    // Settles the message sent to appchain
    messaging_mock
        .process_last_message_to_appchain(
            L3_BRIDGE_ADDRESS(),
            constants::HANDLE_TOKEN_DEPLOYMENT_SELECTOR,
            message_payloads::deployment_message_payload(usdc_address)
        );

    token_bridge.check_deployment_status(usdc_address);

    let final_status = token_bridge.get_status(usdc_address);
    assert(final_status == TokenStatus::Active, 'Should be Active');

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

    assert(token_bridge.get_status(usdc_address) == TokenStatus::Unknown, 'Should be Unknown');

    token_bridge.enroll_token(usdc_address);
    assert(token_bridge.get_status(usdc_address) == TokenStatus::Pending, 'Should be Pending');

    // Settles the message sent to appchain
    messaging_mock
        .process_last_message_to_appchain(
            L3_BRIDGE_ADDRESS(),
            constants::HANDLE_TOKEN_DEPLOYMENT_SELECTOR,
            message_payloads::deployment_message_payload(usdc_address)
        );

    token_bridge.check_deployment_status(usdc_address);

    let final_status = token_bridge.get_status(usdc_address);
    assert(final_status == TokenStatus::Active, 'Should be Active');

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

    assert(token_bridge.get_status(usdc_address) == TokenStatus::Unknown, 'Should be Unknown');

    token_bridge.enroll_token(usdc_address);
    assert(token_bridge.get_status(usdc_address) == TokenStatus::Pending, 'Should be Pending');

    // Settles the message sent to appchain
    messaging_mock
        .process_last_message_to_appchain(
            L3_BRIDGE_ADDRESS(),
            constants::HANDLE_TOKEN_DEPLOYMENT_SELECTOR,
            message_payloads::deployment_message_payload(usdc_address)
        );

    token_bridge.check_deployment_status(usdc_address);

    let final_status = token_bridge.get_status(usdc_address);
    assert(final_status == TokenStatus::Active, 'Should be Active');

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

    assert(token_bridge.get_status(usdc_address) == TokenStatus::Unknown, 'Should be Unknown');

    token_bridge.enroll_token(usdc_address);
    assert(token_bridge.get_status(usdc_address) == TokenStatus::Pending, 'Should be Pending');

    // Settles the message sent to appchain
    messaging_mock
        .process_last_message_to_appchain(
            L3_BRIDGE_ADDRESS(),
            constants::HANDLE_TOKEN_DEPLOYMENT_SELECTOR,
            message_payloads::deployment_message_payload(usdc_address)
        );
    token_bridge.check_deployment_status(usdc_address);

    let final_status = token_bridge.get_status(usdc_address);
    assert(final_status == TokenStatus::Active, 'Should be Active');

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

    assert(token_bridge.get_status(usdc_address) == TokenStatus::Unknown, 'Should be Unknown');

    token_bridge.enroll_token(usdc_address);
    assert(token_bridge.get_status(usdc_address) == TokenStatus::Pending, 'Should be Pending');

    // Settles the message sent to appchain
    messaging_mock
        .process_last_message_to_appchain(
            L3_BRIDGE_ADDRESS(),
            constants::HANDLE_TOKEN_DEPLOYMENT_SELECTOR,
            message_payloads::deployment_message_payload(usdc_address)
        );

    token_bridge.check_deployment_status(usdc_address);

    let final_status = token_bridge.get_status(usdc_address);
    assert(final_status == TokenStatus::Active, 'Should be Active');

    snf::start_cheat_caller_address(token_bridge.contract_address, OWNER());
    token_bridge_admin.deactivate_token(usdc_address);
    snf::stop_cheat_caller_address(OWNER());

    let mut calldata = ArrayTrait::new();
    'param1'.serialize(ref calldata);
    'param2'.serialize(ref calldata);
    token_bridge.deposit_with_message(usdc_address, 100, snf::test_address(), calldata.span());
}
