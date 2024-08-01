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
use super::constants::{OWNER, L3_BRIDGE_ADDRESS, DELAY_TIME};


fn deploy_erc20(name: ByteArray, symbol: ByteArray) -> ContractAddress {
    let erc20_class_hash = snf::declare("ERC20").unwrap();
    let mut constructor_args = ArrayTrait::new();
    name.serialize(ref constructor_args);
    symbol.serialize(ref constructor_args);
    let fixed_supply: u256 = 1000000000;
    fixed_supply.serialize(ref constructor_args);
    OWNER().serialize(ref constructor_args);

    let (usdc, _) = erc20_class_hash.deploy(@constructor_args).unwrap();
    return usdc;
}

fn deploy_token_bridge_with_messaging() -> (
    ITokenBridgeDispatcher, EventSpy, IMockMessagingDispatcher
) {
    // Deploy messaging mock with 5 days cancellation delay
    let messaging_mock_class_hash = snf::declare("messaging_mock").unwrap();
    // Deploying with 5 days as the delay time (5 * 86400 = 432000)
    let (messaging_contract_address, _) = messaging_mock_class_hash
        .deploy(@array![DELAY_TIME])
        .unwrap();

    // Declare l3 bridge address
    let appchain_bridge_address = L3_BRIDGE_ADDRESS();

    // Declare owner
    let owner = OWNER();

    let token_bridge_class_hash = snf::declare("TokenBridge").unwrap();

    // Deploy the bridge
    let mut calldata = ArrayTrait::new();
    appchain_bridge_address.serialize(ref calldata);
    messaging_contract_address.serialize(ref calldata);
    owner.serialize(ref calldata);

    let (token_bridge_address, _) = token_bridge_class_hash.deploy(@calldata).unwrap();

    let token_bridge = ITokenBridgeDispatcher { contract_address: token_bridge_address };
    let messaging_mock = IMockMessagingDispatcher { contract_address: messaging_contract_address };

    let mut spy = snf::spy_events();
    (token_bridge, spy, messaging_mock)
}


fn deploy_token_bridge() -> (ITokenBridgeDispatcher, EventSpy) {
    let (token_bridge, spy, _) = deploy_token_bridge_with_messaging();
    (token_bridge, spy)
}


/// Returns the state of a contract for testing. This must be used
/// to test internal functions or directly access the storage.
/// You can't spy event with this. Use deploy instead.
fn mock_state_testing() -> TokenBridge::ContractState {
    TokenBridge::contract_state_for_testing()
}

#[test]
fn constructor_ok() {
    let (token_bridge, _) = deploy_token_bridge();
    let token_bridge_ownable = IOwnableTwoStepDispatcher {
        contract_address: token_bridge.contract_address
    };
    assert(OWNER() == token_bridge_ownable.owner(), 'Incorrect owner');
}

#[test]
fn set_appchain_bridge_ok() {
    let (token_bridge, mut spy) = deploy_token_bridge();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address
    };
    let token_bridge = ITokenBridgeDispatcher { contract_address: token_bridge.contract_address };

    // Assert for old bridge address
    let old_appchain_bridge_address = token_bridge.appchain_bridge();
    assert(old_appchain_bridge_address == L3_BRIDGE_ADDRESS(), 'L3 Bridge address incorrect');

    let owner = OWNER();
    // Cheat for the owner
    snf::start_cheat_caller_address(token_bridge.contract_address, owner);

    // Set and check new bridge
    let new_appchain_bridge_address = contract_address_const::<'l3_bridge_address_new'>();
    token_bridge_admin.set_appchain_token_bridge(new_appchain_bridge_address);
    assert(
        token_bridge.appchain_bridge() == new_appchain_bridge_address, 'Appchain bridge not set'
    );
    snf::stop_cheat_caller_address(token_bridge.contract_address);

    let expected_event = TokenBridge::SetAppchainBridge {
        appchain_bridge: new_appchain_bridge_address
    };
    spy
        .assert_emitted(
            @array![(token_bridge.contract_address, Event::SetAppchainBridge(expected_event))]
        );
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn set_appchain_bridge_not_owner() {
    let (token_bridge, _) = deploy_token_bridge();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address
    };
    let token_bridge = ITokenBridgeDispatcher { contract_address: token_bridge.contract_address };

    // Assert for old bridge address
    let old_appchain_bridge_address = token_bridge.appchain_bridge();
    assert(old_appchain_bridge_address == L3_BRIDGE_ADDRESS(), 'L3 Bridge address incorrect');

    // Set and check new bridge
    let new_appchain_bridge_address = contract_address_const::<'l3_bridge_address_new'>();
    token_bridge_admin.set_appchain_token_bridge(new_appchain_bridge_address);
    assert(
        token_bridge.appchain_bridge() == new_appchain_bridge_address, 'Appchain bridge not set'
    );
}

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
#[should_panic(expected: ('Caller is not the owner',))]
fn set_max_total_balance_not_owner() {
    let (token_bridge, _) = deploy_token_bridge();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address
    };

    let usdc_address = deploy_erc20("USDC", "USDC");
    let decimals = 1000_000;
    token_bridge_admin.set_max_total_balance(usdc_address, 50 * decimals);
}


#[test]
fn set_max_total_balance_ok() {
    let (token_bridge, mut spy) = deploy_token_bridge();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address
    };

    let usdc_address = deploy_erc20("usdc", "usdc");

    let owner = OWNER();
    // Cheat for the owner
    snf::start_cheat_caller_address(token_bridge.contract_address, owner);

    let decimals = 1000_000;
    token_bridge_admin.set_max_total_balance(usdc_address, 50 * decimals);

    snf::stop_cheat_caller_address(token_bridge.contract_address);

    let expected_event = TokenBridge::SetMaxTotalBalance {
        token: usdc_address, value: 50 * decimals
    };

    spy
        .assert_emitted(
            @array![(token_bridge.contract_address, Event::SetMaxTotalBalance(expected_event))]
        );
}


#[test]
fn block_token_ok() {
    let (token_bridge, mut spy) = deploy_token_bridge();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address
    };

    let usdc_address = deploy_erc20("usdc", "usdc");

    let owner = OWNER();
    // Cheat for the owner
    snf::start_cheat_caller_address(token_bridge.contract_address, owner);
    token_bridge_admin.block_token(usdc_address);

    let expected_event = TokenBridge::TokenBlocked { token: usdc_address };
    spy
        .assert_emitted(
            @array![(token_bridge.contract_address, Event::TokenBlocked(expected_event))]
        );

    assert(token_bridge.get_status(usdc_address) == TokenStatus::Blocked, 'Should be blocked');

    snf::stop_cheat_caller_address(token_bridge.contract_address);
}


#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn block_token_not_owner() {
    let (token_bridge, _) = deploy_token_bridge();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address
    };

    let usdc_address = deploy_erc20("usdc", "usdc");

    token_bridge_admin.block_token(usdc_address);
}

#[test]
#[should_panic(expected: ('Only unknown can be blocked',))]
fn block_token_not_unknown() {
    let (token_bridge, _) = deploy_token_bridge();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address
    };

    let owner = OWNER();
    let usdc_address = deploy_erc20("usdc", "usdc");
    token_bridge.enroll_token(usdc_address);

    snf::start_cheat_caller_address(token_bridge.contract_address, owner);
    token_bridge_admin.block_token(usdc_address);
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn enable_withdrawal_limit_not_owner() {
    let (token_bridge, _) = deploy_token_bridge();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address
    };

    let usdc_address = deploy_erc20("USDC", "USDC");
    token_bridge_admin.enable_withdrawal_limit(usdc_address);
}

#[test]
fn enable_withdrawal_limit_ok() {
    let (token_bridge, _) = deploy_token_bridge();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address
    };
    let withdrawal_limit = IWithdrawalLimitStatusDispatcher {
        contract_address: token_bridge.contract_address
    };

    let owner = OWNER();
    snf::start_cheat_caller_address(token_bridge.contract_address, owner);

    let usdc_address = deploy_erc20("USDC", "USDC");
    token_bridge_admin.enable_withdrawal_limit(usdc_address);

    snf::stop_cheat_caller_address(token_bridge.contract_address);

    assert(withdrawal_limit.is_withdrawal_limit_applied(usdc_address), 'Limit not applied');
}

#[test]
fn disable_withdrwal_limit_ok() {
    let (token_bridge, _) = deploy_token_bridge();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address
    };
    let withdrawal_limit = IWithdrawalLimitStatusDispatcher {
        contract_address: token_bridge.contract_address
    };

    let owner = OWNER();
    snf::start_cheat_caller_address(token_bridge.contract_address, owner);

    let usdc_address = deploy_erc20("USDC", "USDC");
    token_bridge_admin.enable_withdrawal_limit(usdc_address);

    // Withdrawal limit is now applied
    assert(withdrawal_limit.is_withdrawal_limit_applied(usdc_address), 'Limit not applied');

    token_bridge_admin.disable_withdrawal_limit(usdc_address);

    assert(
        withdrawal_limit.is_withdrawal_limit_applied(usdc_address) == false, 'Limit not applied'
    );
    snf::stop_cheat_caller_address(token_bridge.contract_address);
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn disable_withdrwal_not_owner() {
    let (token_bridge, _) = deploy_token_bridge();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address
    };

    let withdrawal_limit = IWithdrawalLimitStatusDispatcher {
        contract_address: token_bridge.contract_address
    };

    let owner = OWNER();
    snf::start_cheat_caller_address(token_bridge.contract_address, owner);

    let usdc_address = deploy_erc20("USDC", "USDC");
    token_bridge_admin.enable_withdrawal_limit(usdc_address);

    // Withdrawal limit is now applied
    assert(withdrawal_limit.is_withdrawal_limit_applied(usdc_address), 'Limit not applied');

    snf::stop_cheat_caller_address(token_bridge.contract_address);

    token_bridge_admin.disable_withdrawal_limit(usdc_address);

    assert(
        withdrawal_limit.is_withdrawal_limit_applied(usdc_address) == false, 'Limit not applied'
    );
}

#[test]
fn unblock_token_ok() {
    let (token_bridge, mut spy) = deploy_token_bridge();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address
    };

    let usdc_address = deploy_erc20("usdc", "usdc");

    let owner = OWNER();
    // Cheat for the owner
    snf::start_cheat_caller_address(token_bridge.contract_address, owner);
    token_bridge_admin.block_token(usdc_address);

    let expected_token_blocked = TokenBridge::TokenBlocked { token: usdc_address };

    assert(token_bridge.get_status(usdc_address) == TokenStatus::Blocked, 'Should be blocked');

    token_bridge_admin.unblock_token(usdc_address);
    assert(token_bridge.get_status(usdc_address) == TokenStatus::Unknown, 'Should be unknown');

    let expected_token_unblocked = TokenBridge::TokenUnblocked { token: usdc_address };

    snf::stop_cheat_caller_address(token_bridge.contract_address);

    spy
        .assert_emitted(
            @array![
                (token_bridge.contract_address, Event::TokenBlocked(expected_token_blocked)),
                (token_bridge.contract_address, Event::TokenUnblocked(expected_token_unblocked))
            ]
        );
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn unblock_token_not_owner() {
    let (token_bridge, mut spy) = deploy_token_bridge();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address
    };

    let usdc_address = deploy_erc20("usdc", "usdc");

    let owner = OWNER();
    // Cheat for the owner
    snf::start_cheat_caller_address(token_bridge.contract_address, owner);
    token_bridge_admin.block_token(usdc_address);

    let expected_token_blocked = TokenBridge::TokenBlocked { token: usdc_address };

    assert(token_bridge.get_status(usdc_address) == TokenStatus::Blocked, 'Should be blocked');

    spy
        .assert_emitted(
            @array![(token_bridge.contract_address, Event::TokenBlocked(expected_token_blocked))]
        );

    snf::stop_cheat_caller_address(token_bridge.contract_address);
    token_bridge_admin.unblock_token(usdc_address);
}


#[test]
#[should_panic(expected: ('Token not blocked',))]
fn unblock_token_not_blocked() {
    let mut mock = mock_state_testing();
    let usdc_address = deploy_erc20("usdc", "usdc");

    // Setting the token active
    let old_settings = mock.token_settings.read(usdc_address);
    mock
        .token_settings
        .write(usdc_address, TokenSettings { token_status: TokenStatus::Active, ..old_settings });

    mock.ownable.Ownable_owner.write(OWNER());
    snf::cheat_caller_address_global(OWNER());

    mock.unblock_token(usdc_address);
}

#[test]
fn reactivate_token_ok() {
    let mut mock = mock_state_testing();
    let usdc_address = deploy_erc20("usdc", "usdc");

    // Setting the token active
    let old_settings = mock.token_settings.read(usdc_address);
    mock
        .token_settings
        .write(
            usdc_address, TokenSettings { token_status: TokenStatus::Deactivated, ..old_settings }
        );

    mock.ownable.Ownable_owner.write(OWNER());

    snf::cheat_caller_address_global(OWNER());

    mock.reactivate_token(usdc_address);
    assert(mock.get_status(usdc_address) == TokenStatus::Active, 'Did not reactivate');
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn reactivate_token_not_owner() {
    let mut mock = mock_state_testing();
    let usdc_address = deploy_erc20("usdc", "usdc");

    // Setting the token active
    let old_settings = mock.token_settings.read(usdc_address);
    mock
        .token_settings
        .write(
            usdc_address, TokenSettings { token_status: TokenStatus::Deactivated, ..old_settings }
        );

    snf::cheat_caller_address_global(snf::test_address());

    mock.reactivate_token(usdc_address);
}

#[test]
#[should_panic(expected: ('Token not deactivated',))]
fn reactivate_token_not_deactivated() {
    let mut mock = mock_state_testing();
    let usdc_address = deploy_erc20("usdc", "usdc");

    // Setting the token active
    let old_settings = mock.token_settings.read(usdc_address);
    mock
        .token_settings
        .write(usdc_address, TokenSettings { token_status: TokenStatus::Blocked, ..old_settings });

    mock.ownable.Ownable_owner.write(OWNER());
    snf::cheat_caller_address_global(OWNER());

    mock.reactivate_token(usdc_address);
}

