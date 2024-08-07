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
fn withdraw_ok() {
    let (token_bridge, mut spy, messaging_mock) = deploy_token_bridge_with_messaging();
    let usdc_address = deploy_erc20("usdc", "usdc");
    let usdc = IERC20Dispatcher { contract_address: usdc_address };
    let messaging = IMessagingDispatcher { contract_address: messaging_mock.contract_address };

    snf::start_cheat_caller_address(usdc_address, OWNER());
    usdc.transfer(snf::test_address(), 100);
    snf::stop_cheat_caller_address(usdc_address);

    assert(token_bridge.get_status(usdc_address) == TokenStatus::Unknown, 'Should be Unknown');

    token_bridge.enroll_token(usdc_address);
    assert(token_bridge.get_status(usdc_address) == TokenStatus::Pending, 'Should be Pending');

    // Enroll token will emit the event `TokenEnrollmentInitiated`
    // Getting the deployment_message_hash from the emitted event
    let (_, event) = spy.get_events().emitted_by(token_bridge.contract_address).events.at(0);
    let mut keys = event.keys.span();
    let mut data = event.data.span();
    let token_enrollment_initiated = starknet::Event::<
        TokenBridge::TokenEnrollmentInitiated
    >::deserialize(ref keys, ref data)
        .unwrap();

    messaging_mock.update_state_for_message(token_enrollment_initiated.deployment_message_hash);

    // Successfully updates the nonce
    let nonce: felt252 = messaging
        .sn_to_appchain_messages(token_enrollment_initiated.deployment_message_hash);
    assert(nonce == 0, 'Nonce no zero');

    token_bridge.check_deployment_status(usdc_address);

    let final_status = token_bridge.get_status(usdc_address);
    assert(final_status == TokenStatus::Active, 'Should be Active');

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

    // Register a withdraw message from appchain to piltover
    messaging_mock
        .process_message_to_starknet(
            L3_BRIDGE_ADDRESS(),
            token_bridge.contract_address,
            message_payloads::withdraw_message_payload_from_appchain(
                usdc_address, amount, snf::test_address()
            )
        );
    token_bridge.withdraw(usdc_address, 100, snf::test_address());
}

