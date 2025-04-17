use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std as snf;
use snforge_std::{ContractClassTrait, DeclareResultTrait, EventSpy};
use starknet::ContractAddress;
use starknet_bridge::bridge::tests::constants::{
    APP_GOVERNOR, DELAY_TIME, GOVERNANCE_ADMIN, L3_BRIDGE_ADDRESS, OWNER, SECURITY_ADMIN,
    SECURITY_AGENT, TOKEN_ADMIN,
};
use starknet_bridge::bridge::tests::utils::message_payloads;
use starknet_bridge::bridge::types::TokenStatus;
use starknet_bridge::bridge::{ITokenBridgeDispatcher, ITokenBridgeDispatcherTrait, TokenBridge};
use starknet_bridge::constants;
use starknet_bridge::mocks::messaging::{IMockMessagingDispatcher, IMockMessagingDispatcherTrait};


pub fn deploy_erc20(name: ByteArray, symbol: ByteArray) -> ContractAddress {
    let erc20_class_hash = snf::declare("ERC20_OZ").unwrap().contract_class();
    let mut constructor_args = ArrayTrait::new();
    let fixed_supply: u256 = 1000000000;

    name.serialize(ref constructor_args);
    symbol.serialize(ref constructor_args);
    18.serialize(ref constructor_args); // decimals
    fixed_supply.serialize(ref constructor_args);
    OWNER().serialize(ref constructor_args);
    OWNER().serialize(ref constructor_args);
    OWNER().serialize(ref constructor_args);
    10.serialize(ref constructor_args);

    let (usdc, _) = erc20_class_hash.deploy(@constructor_args).unwrap();

    let usdc_token = IERC20Dispatcher { contract_address: usdc };

    // Transfering usdc to test address for testing
    snf::start_cheat_caller_address(usdc, OWNER());
    usdc_token.transfer(snf::test_address(), 100);
    snf::stop_cheat_caller_address(usdc);

    return usdc;
}

pub fn deploy_token_bridge_with_messaging() -> (
    ITokenBridgeDispatcher, EventSpy, IMockMessagingDispatcher,
) {
    // Deploy messaging mock with 5 days cancellation delay
    let messaging_mock_class_hash = snf::declare("messaging_mock").unwrap().contract_class();
    // Deploying with 5 days as the delay time (5 * 86400 = 432000)
    let (messaging_contract_address, _) = messaging_mock_class_hash
        .deploy(@array![DELAY_TIME])
        .unwrap();

    // Declare l3 bridge address
    let appchain_bridge_address = L3_BRIDGE_ADDRESS();

    // Declare owner
    let owner = OWNER();

    // Declare timelock contract
    let timelock = snf::declare("TimelockController").unwrap().contract_class();

    let min_delay = 86400; // 24h

    let mut timelock_args: Array<felt252> = ArrayTrait::new();
    min_delay.serialize(ref timelock_args); // 1 min delay
    [owner].span().serialize(ref timelock_args); // 1 proposer
    [owner].span().serialize(ref timelock_args); // 1 executor
    owner.serialize(ref timelock_args); // 1 default admin
    let (timelock_address, _) = timelock.deploy(@timelock_args).unwrap();

    let token_bridge_class_hash = snf::declare("TokenBridge").unwrap().contract_class();

    // Deploy the bridge
    let mut calldata = ArrayTrait::new();
    appchain_bridge_address.serialize(ref calldata);
    messaging_contract_address.serialize(ref calldata);
    [GOVERNANCE_ADMIN()].span().serialize(ref calldata);
    [APP_GOVERNOR()].span().serialize(ref calldata);
    [SECURITY_ADMIN()].span().serialize(ref calldata);
    [SECURITY_AGENT()].span().serialize(ref calldata);
    [TOKEN_ADMIN()].span().serialize(ref calldata);
    timelock_address.serialize(ref calldata);

    let (token_bridge_address, _) = token_bridge_class_hash.deploy(@calldata).unwrap();

    let token_bridge = ITokenBridgeDispatcher { contract_address: token_bridge_address };
    let messaging_mock = IMockMessagingDispatcher { contract_address: messaging_contract_address };

    let mut spy = snf::spy_events();
    (token_bridge, spy, messaging_mock)
}


pub fn deploy_token_bridge() -> (ITokenBridgeDispatcher, EventSpy) {
    let (token_bridge, spy, _) = deploy_token_bridge_with_messaging();
    (token_bridge, spy)
}


/// Returns the state of a contract for testing. This must be used
/// to test internal functions or directly access the storage.
/// You can't spy event with this. Use deploy instead.
pub fn mock_state_testing() -> TokenBridge::ContractState {
    TokenBridge::contract_state_for_testing()
}

pub fn enroll_token(
    token_bridge: ITokenBridgeDispatcher,
    messaging_mock: IMockMessagingDispatcher,
    token: ContractAddress,
) {
    assert(token_bridge.get_status(token) == TokenStatus::Unknown, 'Should be Unknown');

    token_bridge.enroll_token(token);
    assert(token_bridge.get_status(token) == TokenStatus::Pending, 'Should be Pending');

    // Settles the message sent to appchain
    messaging_mock
        .process_last_message_to_appchain(
            token_bridge.contract_address,
            L3_BRIDGE_ADDRESS(),
            constants::HANDLE_TOKEN_DEPLOYMENT_SELECTOR,
            message_payloads::deployment_message_payload(token),
        );

    token_bridge.check_deployment_status(token);

    let final_status = token_bridge.get_status(token);
    assert(final_status == TokenStatus::Active, 'Should be Active');
}

pub fn enroll_token_and_settle(
    token_bridge: ITokenBridgeDispatcher,
    messaging_mock: IMockMessagingDispatcher,
    token: ContractAddress,
) {
    enroll_token(token_bridge, messaging_mock, token);

    token_bridge.check_deployment_status(token);

    let final_status = token_bridge.get_status(token);
    assert(final_status == TokenStatus::Active, 'Should be Active');
}
