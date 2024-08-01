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
use super::setup::{deploy_erc20, deploy_token_bridge, mock_state_testing};


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

