use piltover::messaging::interface::IMessagingDispatcherTrait;
use starknet_bridge::bridge::token_bridge::TokenBridge::{
    __member_module_appchain_bridge::InternalContractMemberStateTrait,
    __member_module_token_settings::InternalContractMemberStateTrait as tokenSettingsStateTrait,
    TokenBridgeInternal
};
use snforge_std as snf;
use snforge_std::{ContractClassTrait};
use starknet::{ContractAddress, storage::StorageMemberAccessTrait};
use starknet_bridge::mocks::{
    messaging::{IMockMessagingDispatcherTrait, IMockMessagingDispatcher}, erc20::ERC20, hash
};
use piltover::messaging::interface::IMessagingDispatcher;
use starknet_bridge::bridge::{
    ITokenBridge, ITokenBridgeAdmin, ITokenBridgeDispatcher, ITokenBridgeDispatcherTrait,
    ITokenBridgeAdminDispatcher, ITokenBridgeAdminDispatcherTrait, IWithdrawalLimitStatusDispatcher,
    IWithdrawalLimitStatusDispatcherTrait, TokenBridge, TokenBridge::Event,
    types::{TokenStatus, TokenSettings},
    tests::constants::{OWNER, L3_BRIDGE_ADDRESS, USDC_MOCK_ADDRESS, DELAY_TIME}
};
use openzeppelin::{
    token::erc20::interface::{
        IERC20, IERC20Dispatcher, IERC20DispatcherTrait, IERC20MetadataDispatcher,
        IERC20MetadataDispatcherTrait
    },
    access::ownable::{
        OwnableComponent, OwnableComponent::Event as OwnableEvent,
        interface::{IOwnableTwoStepDispatcher, IOwnableTwoStepDispatcherTrait}
    }
};
use starknet_bridge::bridge::tests::utils::message_payloads;
use starknet::contract_address::{contract_address_const};
use starknet_bridge::constants;
use starknet_bridge::bridge::tests::utils::setup::{
    deploy_erc20, deploy_token_bridge_with_messaging, deploy_token_bridge, enroll_token_and_settle,
    mock_state_testing
};

fn setup() -> (TokenBridge::ContractState, ContractAddress) {
    let mut mock = mock_state_testing();
    let usdc_address = deploy_erc20("usdc", "usdc");
    (mock, usdc_address)
}


#[test]
#[should_panic(expected: ('ERC20: insufficient balance',))]
fn accept_deposit_insufficient_balance() {
    let (mut mock, usdc_address) = setup();
    let usdc = IERC20Dispatcher { contract_address: usdc_address };
    // Setting the token active
    let old_settings = mock.token_settings.read(usdc_address);
    mock
        .token_settings
        .write(usdc_address, TokenSettings { token_status: TokenStatus::Active, ..old_settings });
    snf::start_cheat_caller_address_global(snf::test_address());
    usdc.approve(snf::test_address(), 200);
    mock.accept_deposit(usdc_address, 200);
}

#[test]
#[should_panic(expected: ('ERC20: insufficient allowance',))]
fn accept_deposit_insufficient_allowance() {
    let (mut mock, usdc_address) = setup();
    // Setting the token active
    let old_settings = mock.token_settings.read(usdc_address);
    mock
        .token_settings
        .write(usdc_address, TokenSettings { token_status: TokenStatus::Active, ..old_settings });
    mock.accept_deposit(usdc_address, 100);
}

#[test]
#[should_panic(expected: ('Only servicing tokens',))]
fn accept_deposit_not_servicing() {
    let (mock, usdc_address) = setup();
    mock.accept_deposit(usdc_address, 200);
}

