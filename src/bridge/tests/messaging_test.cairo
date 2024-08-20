use piltover::messaging::interface::IMessagingDispatcherTrait;
use starknet_bridge::bridge::token_bridge::TokenBridge::{
    __member_module_appchain_bridge::InternalContractMemberStateTrait,
    __member_module_token_settings::InternalContractMemberStateTrait as tokenSettingsStateTrait,
    TokenBridgeInternal
};
use snforge_std as snf;
use snforge_std::ContractClassTrait;
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
    token::erc20::interface::{IERC20MetadataDispatcher, IERC20MetadataDispatcherTrait},
    access::ownable::{
        OwnableComponent, OwnableComponent::Event as OwnableEvent,
        interface::{IOwnableTwoStepDispatcher, IOwnableTwoStepDispatcherTrait}
    }
};
use starknet_bridge::bridge::tests::utils::setup::{deploy_erc20, mock_state_testing};
use starknet_bridge::bridge::tests::utils::message_payloads;
use starknet::contract_address::{contract_address_const};
use starknet_bridge::constants;


#[test]
fn deploy_message_payload_ok() {
    let usdc_address = deploy_erc20("USDC", "USDC");
    let calldata = TokenBridge::deployment_message_payload(usdc_address);

    let expected_calldata: Span<felt252> = array![
        3346236667719676623895870229889359551507408296949803518172317961543243553075, // usdc_address
        0,
        1431520323, // -- USDC
        4,
        0,
        1431520323, // USDC
        4,
        18 // Decimals
    ]
        .span();
    assert(calldata == expected_calldata, 'Incorrect serialisation');
}

#[test]
fn deposit_message_payload_with_message_false_ok() {
    let usdc_address = USDC_MOCK_ADDRESS();
    let calldata = TokenBridge::deposit_message_payload(
        usdc_address, 100, snf::test_address(), false, array![].span()
    );

    let expected_calldata = array![
        26445726369279219922997965683, 0, 469394814521890341860918960550914, 100, 0
    ]
        .span();
    assert(calldata == expected_calldata, 'Incorrect serialization');
}


#[test]
fn send_deploy_message_ok() {
    let mut mock = mock_state_testing();
    let usdc_address = deploy_erc20("USDC", "USDC");

    // Deploy messaging mock with 5 days cancellation delay
    let messaging_mock_class_hash = snf::declare("messaging_mock").unwrap();
    // Deploying with 5 days as the delay time (5 * 86400 = 432000)
    let (messaging_contract_address, _) = messaging_mock_class_hash
        .deploy(@array![DELAY_TIME])
        .unwrap();

    let messaging = IMessagingDispatcher { contract_address: messaging_contract_address };

    snf::start_cheat_caller_address_global(snf::test_address());
    TokenBridge::constructor(ref mock, L3_BRIDGE_ADDRESS(), messaging_contract_address, OWNER());

    mock.send_deploy_message(usdc_address);
    let hash = hash::compute_message_hash_sn_to_appc(
        1,
        L3_BRIDGE_ADDRESS(),
        constants::HANDLE_TOKEN_DEPLOYMENT_SELECTOR,
        message_payloads::deployment_message_payload(usdc_address)
    );
    assert(messaging.sn_to_appchain_messages(hash) == 1, 'Message not recieved');
}

#[test]
#[should_panic(expected: ('L3 bridge not set',))]
fn send_deploy_message_bridge_unset() {
    let mut mock = mock_state_testing();
    let usdc_address = USDC_MOCK_ADDRESS();

    mock.send_deploy_message(usdc_address);
}

#[test]
fn send_deposit_message_ok() {
    let mut mock = mock_state_testing();
    let usdc_address = USDC_MOCK_ADDRESS();

    // Deploy messaging mock with 5 days cancellation delay
    let messaging_mock_class_hash = snf::declare("messaging_mock").unwrap();
    // Deploying with 5 days as the delay time (5 * 86400 = 432000)
    let (messaging_contract_address, _) = messaging_mock_class_hash
        .deploy(@array![DELAY_TIME])
        .unwrap();
    let messaging = IMessagingDispatcher { contract_address: messaging_contract_address };
    TokenBridge::constructor(ref mock, L3_BRIDGE_ADDRESS(), messaging_contract_address, OWNER());

    let no_message: Span<felt252> = array![].span();
    snf::start_cheat_caller_address_global(snf::test_address());
    mock
        .send_deposit_message(
            usdc_address,
            100,
            snf::test_address(),
            no_message,
            constants::HANDLE_TOKEN_DEPOSIT_SELECTOR
        );

    let hash = hash::compute_message_hash_sn_to_appc(
        1,
        L3_BRIDGE_ADDRESS(),
        constants::HANDLE_TOKEN_DEPOSIT_SELECTOR,
        message_payloads::deposit_message_payload(
            usdc_address, 100, snf::test_address(), snf::test_address(), false, array![].span()
        )
    );

    assert(messaging.sn_to_appchain_messages(hash) == 1, 'Message not recieved');
}

#[test]
#[should_panic(expected: ('L3 bridge not set',))]
fn send_deposit_message_bridge_unset() {
    let mut mock = mock_state_testing();
    let usdc_address = USDC_MOCK_ADDRESS();

    let no_message: Span<felt252> = array![].span();
    mock
        .send_deposit_message(
            usdc_address,
            100,
            snf::test_address(),
            no_message,
            constants::HANDLE_TOKEN_DEPOSIT_SELECTOR
        );
}

#[test]
fn consume_message_ok() {
    let mut mock = mock_state_testing();
    let usdc_address = USDC_MOCK_ADDRESS();

    // Deploy messaging mock with 5 days cancellation delay
    let messaging_mock_class_hash = snf::declare("messaging_mock").unwrap();
    // Deploying with 5 days as the delay time (5 * 86400 = 432000)
    let (messaging_contract_address, _) = messaging_mock_class_hash
        .deploy(@array![DELAY_TIME])
        .unwrap();

    TokenBridge::constructor(ref mock, L3_BRIDGE_ADDRESS(), messaging_contract_address, OWNER());

    let messaging_mock = IMockMessagingDispatcher { contract_address: messaging_contract_address };
    // Register a withdraw message from appchain to piltover
    messaging_mock
        .process_message_to_starknet(
            L3_BRIDGE_ADDRESS(),
            snf::test_address(),
            message_payloads::withdraw_message_payload_from_appchain(
                usdc_address, 100, snf::test_address()
            )
        );

    mock.consume_message(usdc_address, 100, snf::test_address());
}

#[test]
#[should_panic(expected: ('INVALID_MESSAGE_TO_CONSUME',))]
fn consume_message_no_message() {
    let mut mock = mock_state_testing();
    let usdc_address = USDC_MOCK_ADDRESS();

    // Deploy messaging mock with 5 days cancellation delay
    let messaging_mock_class_hash = snf::declare("messaging_mock").unwrap();
    // Deploying with 5 days as the delay time (5 * 86400 = 432000)
    let (messaging_contract_address, _) = messaging_mock_class_hash
        .deploy(@array![DELAY_TIME])
        .unwrap();

    TokenBridge::constructor(ref mock, L3_BRIDGE_ADDRESS(), messaging_contract_address, OWNER());

    mock.consume_message(usdc_address, 100, snf::test_address());
}

#[test]
#[should_panic(expected: ('L3 bridge not set',))]
fn consume_message_bridge_unset() {
    let mut mock = mock_state_testing();
    let usdc_address = USDC_MOCK_ADDRESS();

    mock.consume_message(usdc_address, 100, snf::test_address());
}

#[test]
#[should_panic(expected: ('Invalid recipient',))]
fn consume_message_zero_recipient() {
    let mut mock = mock_state_testing();
    let usdc_address = USDC_MOCK_ADDRESS();

    mock.appchain_bridge.write(L3_BRIDGE_ADDRESS());
    mock.consume_message(usdc_address, 100, contract_address_const::<0>());
}
