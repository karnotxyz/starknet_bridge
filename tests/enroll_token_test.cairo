use starknet_bridge::bridge::token_bridge::TokenBridge::__member_module_token_settings::InternalContractMemberStateTrait;
use core::array::ArrayTrait;
use core::serde::Serde;
use core::result::ResultTrait;
use core::option::OptionTrait;
use core::traits::TryInto;
use snforge_std as snf;
use snforge_std::{ContractClassTrait, EventSpy, EventSpyTrait, EventSpyAssertionsTrait};
use starknet::{ContractAddress, storage::StorageMemberAccessTrait};
use starknet_bridge::mocks::{
    messaging::{IMockMessagingDispatcherTrait, IMockMessagingDispatcher}, erc20::ERC20
};
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
use starknet::contract_address::{contract_address_const};
use super::utils::constants::{OWNER, L3_BRIDGE_ADDRESS, DELAY_TIME};
use super::utils::setup::{deploy_erc20, deploy_token_bridge, mock_state_testing};


#[test]
fn enroll_token_ok() {
    let (token_bridge, _) = deploy_token_bridge();

    let usdc_address = deploy_erc20("USDC", "USDC");

    let old_status = token_bridge.get_status(usdc_address);
    assert(old_status == TokenStatus::Unknown, 'Should be unknown before');

    token_bridge.enroll_token(usdc_address);

    let new_status = token_bridge.get_status(usdc_address);
    assert(new_status == TokenStatus::Pending, 'Should be pending now');
}

#[test]
#[should_panic(expected: ('Already enrolled',))]
fn enroll_token_already_enrolled() {
    let (token_bridge, _) = deploy_token_bridge();

    let usdc_address = deploy_erc20("USDC", "USDC");
    token_bridge.enroll_token(usdc_address);

    let new_status = token_bridge.get_status(usdc_address);
    assert(new_status == TokenStatus::Pending, 'Should be pending now');

    token_bridge.enroll_token(usdc_address);
}
