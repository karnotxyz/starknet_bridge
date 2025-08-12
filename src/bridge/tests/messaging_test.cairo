use piltover::messaging::interface::{IMessagingDispatcher, IMessagingDispatcherTrait};
use piltover::messaging::types::MessageToAppchainStatus;
use snforge_std as snf;
use snforge_std::{ContractClassTrait, DeclareResultTrait};
use starknet::storage::StoragePointerWriteAccess;
use starknet_bridge::bridge::TokenBridge;
use starknet_bridge::bridge::tests::constants::{
    APP_GOVERNOR, DELAY_TIME, GOVERNANCE_ADMIN, L3_BRIDGE_ADDRESS, SECURITY_ADMIN, SECURITY_AGENT,
    TIMELOCK_ADDRESS, TOKEN_ADMIN, USDC_MOCK_ADDRESS,
};
use starknet_bridge::bridge::tests::utils::message_payloads;
use starknet_bridge::bridge::tests::utils::setup::{
    deploy_erc20, deploy_erc20_with_felt252, mock_state_testing,
};
use starknet_bridge::bridge::token_bridge::TokenBridge::TokenBridgeInternal;
use starknet_bridge::constants;
use starknet_bridge::mocks::hash;
use starknet_bridge::mocks::messaging::{IMockMessagingDispatcher, IMockMessagingDispatcherTrait};


#[test]
fn deploy_message_payload_1u128_ok() {
    let usdc_address = deploy_erc20_with_felt252('USDC', 'USDC');
    let calldata = TokenBridge::deployment_message_payload(usdc_address);

    println!("calldata {:?}", calldata);
    let expected_calldata: Span<felt252> = array![
        1878846678861813862807137660746142479173097938654444763365422304796849302852, // usdc_address
        0,
        1431520323,
        4, // "USDC"
        0,
        1431520323,
        4, // "USDC"
        18,
    ]
        .span();

    assert(calldata == expected_calldata, 'Incorrect serialisation');
}

#[test]
fn deploy_message_payload_2u128_ok() {
    let usdc_address = deploy_erc20_with_felt252('Starknet Bridged Token USDC', 'USDC');
    let calldata = TokenBridge::deployment_message_payload(usdc_address);

    println!("calldata {:?}", calldata);
    let expected_calldata: Span<felt252> = array![
        1490587303571540848742139364702760394050729519911961861263204573571851472479, // token address 
        0,
        34331236061979135384369429850688382866543914782444172758941385795,
        27, // "Starknet Bridged Token USDC"
        0,
        1431520323,
        4, // "USDC"
        18,
    ]
        .span();

    assert(calldata == expected_calldata, 'Incorrect serialisation');
}

#[test]
fn deploy_message_payload_3u128_ok() {
    let usdc_address = deploy_erc20("Starknet Bridged Into Appchain Token USDC", "USDC");
    let calldata = TokenBridge::deployment_message_payload(usdc_address);
    println!("calldata {:?}", calldata);

    let expected_calldata: Span<felt252> = array![
        143620707853892322995637150357644909544175399019378012924718466488958919106, // token address
        1,
        147451536117456215510223090790872767498932623355471960875487237126251703840,
        398734111865851813774403,
        10, // "Starknet Bridged Into Appchain Token USDC"
        0,
        1431520323,
        4, // "USDC"
        18,
    ]
        .span();

    assert(calldata == expected_calldata, 'Incorrect serialisation');
}

#[test]
fn deposit_message_payload_with_message_false_ok() {
    let usdc_address = USDC_MOCK_ADDRESS();
    let calldata = TokenBridge::deposit_message_payload(
        usdc_address, 100, snf::test_address(), false, array![].span(),
    );

    let expected_calldata = array![
        26445726369279219922997965683, 0, 469394814521890341860918960550914, 100, 0,
    ]
        .span();
    assert(calldata == expected_calldata, 'Incorrect serialization');
}


#[test]
fn send_deploy_message_ok() {
    let mut mock = mock_state_testing();
    let usdc_address = deploy_erc20("USDC", "USDC");

    // Deploy messaging mock with 5 days cancellation delay
    let messaging_mock_class_hash = snf::declare("messaging_mock").unwrap().contract_class();
    // Deploying with 5 days as the delay time (5 * 86400 = 432000)
    let (messaging_contract_address, _) = messaging_mock_class_hash
        .deploy(@array![DELAY_TIME])
        .unwrap();

    let messaging = IMessagingDispatcher { contract_address: messaging_contract_address };

    snf::start_cheat_caller_address_global(snf::test_address());
    TokenBridge::constructor(
        ref mock,
        L3_BRIDGE_ADDRESS(),
        messaging_contract_address,
        array![GOVERNANCE_ADMIN()].span(),
        array![APP_GOVERNOR()].span(),
        array![SECURITY_ADMIN()].span(),
        array![SECURITY_AGENT()].span(),
        array![TOKEN_ADMIN()].span(),
        TIMELOCK_ADDRESS(),
    );

    mock.send_deploy_message(usdc_address);
    let hash = hash::compute_message_hash_sn_to_appc(
        snf::test_address(),
        L3_BRIDGE_ADDRESS(),
        constants::HANDLE_TOKEN_DEPLOYMENT_SELECTOR,
        message_payloads::deployment_message_payload(usdc_address),
        0,
    );
    assert(
        messaging.sn_to_appchain_messages(hash) == MessageToAppchainStatus::Pending(0),
        'Message not recieved',
    );
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
    let messaging_mock_class_hash = snf::declare("messaging_mock").unwrap().contract_class();
    // Deploying with 5 days as the delay time (5 * 86400 = 432000)
    let (messaging_contract_address, _) = messaging_mock_class_hash
        .deploy(@array![DELAY_TIME])
        .unwrap();
    let messaging = IMessagingDispatcher { contract_address: messaging_contract_address };
    TokenBridge::constructor(
        ref mock,
        L3_BRIDGE_ADDRESS(),
        messaging_contract_address,
        array![GOVERNANCE_ADMIN()].span(),
        array![APP_GOVERNOR()].span(),
        array![SECURITY_ADMIN()].span(),
        array![SECURITY_AGENT()].span(),
        array![TOKEN_ADMIN()].span(),
        TIMELOCK_ADDRESS(),
    );

    let no_message: Span<felt252> = array![].span();
    snf::start_cheat_caller_address_global(snf::test_address());
    mock
        .send_deposit_message(
            usdc_address,
            100,
            snf::test_address(),
            no_message,
            constants::HANDLE_TOKEN_DEPOSIT_SELECTOR,
        );

    let hash = hash::compute_message_hash_sn_to_appc(
        snf::test_address(),
        L3_BRIDGE_ADDRESS(),
        constants::HANDLE_TOKEN_DEPOSIT_SELECTOR,
        message_payloads::deposit_message_payload(
            usdc_address, 100, snf::test_address(), snf::test_address(), false, array![].span(),
        ),
        0,
    );

    assert(
        messaging.sn_to_appchain_messages(hash) == MessageToAppchainStatus::Pending(0),
        'Message not recieved',
    );
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
            constants::HANDLE_TOKEN_DEPOSIT_SELECTOR,
        );
}

#[test]
fn consume_message_ok() {
    let mut mock = mock_state_testing();
    let usdc_address = USDC_MOCK_ADDRESS();

    // Deploy messaging mock with 5 days cancellation delay
    let messaging_mock_class_hash = snf::declare("messaging_mock").unwrap().contract_class();
    // Deploying with 5 days as the delay time (5 * 86400 = 432000)
    let (messaging_contract_address, _) = messaging_mock_class_hash
        .deploy(@array![DELAY_TIME])
        .unwrap();

    TokenBridge::constructor(
        ref mock,
        L3_BRIDGE_ADDRESS(),
        messaging_contract_address,
        array![GOVERNANCE_ADMIN()].span(),
        array![APP_GOVERNOR()].span(),
        array![SECURITY_ADMIN()].span(),
        array![SECURITY_AGENT()].span(),
        array![TOKEN_ADMIN()].span(),
        TIMELOCK_ADDRESS(),
    );

    let messaging_mock = IMockMessagingDispatcher { contract_address: messaging_contract_address };
    // Register a withdraw message from appchain to piltover
    messaging_mock
        .process_message_to_starknet(
            L3_BRIDGE_ADDRESS(),
            snf::test_address(),
            message_payloads::withdraw_message_payload_from_appchain(
                usdc_address, 100, snf::test_address(),
            ),
        );

    mock.consume_message(usdc_address, 100, snf::test_address());
}

#[test]
#[should_panic(expected: ('INVALID_MESSAGE_TO_CONSUME',))]
fn consume_message_no_message() {
    let mut mock = mock_state_testing();
    let usdc_address = USDC_MOCK_ADDRESS();

    // Deploy messaging mock with 5 days cancellation delay
    let messaging_mock_class_hash = snf::declare("messaging_mock").unwrap().contract_class();
    // Deploying with 5 days as the delay time (5 * 86400 = 432000)
    let (messaging_contract_address, _) = messaging_mock_class_hash
        .deploy(@array![DELAY_TIME])
        .unwrap();

    TokenBridge::constructor(
        ref mock,
        L3_BRIDGE_ADDRESS(),
        messaging_contract_address,
        array![GOVERNANCE_ADMIN()].span(),
        array![APP_GOVERNOR()].span(),
        array![SECURITY_ADMIN()].span(),
        array![SECURITY_AGENT()].span(),
        array![TOKEN_ADMIN()].span(),
        TIMELOCK_ADDRESS(),
    );

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
    mock.consume_message(usdc_address, 100, 0.try_into().unwrap());
}
