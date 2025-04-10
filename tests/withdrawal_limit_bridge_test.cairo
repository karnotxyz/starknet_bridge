use snforge_std as snf;
use snforge_std::EventSpyAssertionsTrait;
use starknet_bridge::bridge::TokenBridge::Event;
use starknet_bridge::bridge::tests::utils::setup::deploy_token_bridge;
use starknet_bridge::bridge::{
    ITokenBridgeAdminDispatcher, ITokenBridgeAdminDispatcherTrait, TokenBridge,
};
use starknet_bridge::withdrawal_limit::interface::{
    IWithdrawalLimitDispatcher, IWithdrawalLimitDispatcherTrait,
};
use starknet_bridge::access_control::roles::Roles;
use openzeppelin::access::accesscontrol::interface::{
    IAccessControlDispatcher, IAccessControlDispatcherTrait,
};
use super::constants::{SECURITY_ADMIN, SECURITY_AGENT, USDC_MOCK_ADDRESS};


#[test]
#[should_panic(expected: ('Caller is missing role',))]
fn decrease_withdrawal_limit_not_security_agent() {
    let (token_bridge, _) = deploy_token_bridge();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address,
    };

    let usdc_address = USDC_MOCK_ADDRESS();
    token_bridge_admin.decrease_withdrawal_limit(usdc_address, 10);
}

#[test]
fn decrease_withdrawal_limit_ok() {
    let (token_bridge, mut spy) = deploy_token_bridge();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address,
    };
    let withdrawal_limit = IWithdrawalLimitDispatcher {
        contract_address: token_bridge.contract_address,
    };
    let usdc_address = USDC_MOCK_ADDRESS();

    snf::start_cheat_caller_address(token_bridge.contract_address, SECURITY_AGENT());

    token_bridge_admin.decrease_withdrawal_limit(usdc_address, 10);

    snf::stop_cheat_caller_address(token_bridge.contract_address);

    assert(withdrawal_limit.is_withdrawal_limit_applied(usdc_address), 'Limit not applied');

    let exepected_limit_enabled = TokenBridge::WithdrawalLimitDecreased {
        sender: SECURITY_AGENT(), token: usdc_address, daily_withdrawal_limit_pct: 10,
    };
    spy
        .assert_emitted(
            @array![
                (
                    token_bridge_admin.contract_address,
                    Event::WithdrawalLimitDecreased(exepected_limit_enabled),
                ),
            ],
        );
}

#[test]
#[should_panic(expected: ('Pausable: paused',))]
fn decrease_withdrawal_limit_paused() {
    let (token_bridge, _) = deploy_token_bridge();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address,
    };

    snf::start_cheat_caller_address(token_bridge.contract_address, SECURITY_AGENT());
    token_bridge_admin.pause();
    snf::stop_cheat_caller_address(token_bridge.contract_address);

    let usdc_address = USDC_MOCK_ADDRESS();
    token_bridge_admin.decrease_withdrawal_limit(usdc_address, 10);
}


#[test]
fn increase_withdrawal_limit_ok() {
    let (token_bridge, mut spy) = deploy_token_bridge();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address,
    };
    let withdrawal_limit = IWithdrawalLimitDispatcher {
        contract_address: token_bridge.contract_address,
    };
    let usdc_address = USDC_MOCK_ADDRESS();

    snf::start_cheat_caller_address(token_bridge.contract_address, SECURITY_AGENT());

    token_bridge_admin.decrease_withdrawal_limit(usdc_address, 10);

    snf::stop_cheat_caller_address(token_bridge.contract_address);

    snf::start_cheat_caller_address(token_bridge.contract_address, SECURITY_ADMIN());

    token_bridge_admin.increase_withdrawal_limit(usdc_address, 20);

    snf::stop_cheat_caller_address(token_bridge.contract_address);

    assert(withdrawal_limit.is_withdrawal_limit_applied(usdc_address), 'Limit not applied');

    let exepected_limit_enabled = TokenBridge::WithdrawalLimitIncreased {
        sender: SECURITY_ADMIN(), token: usdc_address, daily_withdrawal_limit_pct: 20,
    };
    spy
        .assert_emitted(
            @array![
                (
                    token_bridge_admin.contract_address,
                    Event::WithdrawalLimitIncreased(exepected_limit_enabled),
                ),
            ],
        );
}

#[test]
#[should_panic(expected: ('Pausable: paused',))]
fn increase_withdrawal_limit_paused() {
    let (token_bridge, _) = deploy_token_bridge();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address,
    };

    snf::start_cheat_caller_address(token_bridge.contract_address, SECURITY_AGENT());
    token_bridge_admin.pause();
    snf::stop_cheat_caller_address(token_bridge.contract_address);

    let usdc_address = USDC_MOCK_ADDRESS();
    token_bridge_admin.increase_withdrawal_limit(usdc_address, 10);
}

#[test]
#[should_panic(expected: ('Caller is missing role',))]
fn increase_withdrawal_limit_not_security_admin() {
    let (token_bridge, _) = deploy_token_bridge();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address,
    };

    let usdc_address = USDC_MOCK_ADDRESS();
    token_bridge_admin.increase_withdrawal_limit(usdc_address, 10);
}


#[test]
fn disable_withdrawal_limit_ok() {
    let (token_bridge, mut spy) = deploy_token_bridge();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address,
    };
    let access_control = IAccessControlDispatcher {
        contract_address: token_bridge.contract_address,
    };
    let withdrawal_limit = IWithdrawalLimitDispatcher {
        contract_address: token_bridge.contract_address,
    };
    let usdc_address = USDC_MOCK_ADDRESS();

    // Security agent can enable the limit
    snf::start_cheat_caller_address(token_bridge.contract_address, SECURITY_AGENT());

    token_bridge_admin.decrease_withdrawal_limit(usdc_address, 10);

    snf::stop_cheat_caller_address(token_bridge.contract_address);

    // Withdrawal limit is now applied
    assert(withdrawal_limit.is_withdrawal_limit_applied(usdc_address), 'Limit not applied');

    assert!(
        access_control.has_role(Roles::SECURITY_ADMIN, SECURITY_ADMIN()),
        "Security admin not granted",
    );

    // Security admin can disable the limit
    snf::start_cheat_caller_address(token_bridge.contract_address, SECURITY_ADMIN());

    token_bridge_admin.disable_withdrawal_limit(usdc_address);

    snf::stop_cheat_caller_address(token_bridge.contract_address);

    println!(
        "is_withdrawal_limit_applied after disable: {}",
        withdrawal_limit.is_withdrawal_limit_applied(usdc_address),
    );
    assert(!withdrawal_limit.is_withdrawal_limit_applied(usdc_address), 'Limit not applied');

    let expected_limit_disabled = TokenBridge::WithdrawalLimitIncreased {
        sender: SECURITY_ADMIN(), token: usdc_address, daily_withdrawal_limit_pct: 100,
    };

    spy
        .assert_emitted(
            @array![
                (
                    token_bridge_admin.contract_address,
                    Event::WithdrawalLimitIncreased(expected_limit_disabled),
                ),
            ],
        );
}

#[test]
#[should_panic(expected: ('Pausable: paused',))]
fn disable_withdrawal_limit_paused() {
    let (token_bridge, _) = deploy_token_bridge();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address,
    };

    // Set up security agent before pausing
    snf::start_cheat_caller_address(token_bridge.contract_address, SECURITY_AGENT());
    token_bridge_admin.pause();
    snf::stop_cheat_caller_address(token_bridge.contract_address);

    let usdc_address = USDC_MOCK_ADDRESS();
    token_bridge_admin.disable_withdrawal_limit(usdc_address);
}

#[test]
#[should_panic(expected: ('Caller is missing role',))]
fn disable_withdrawal_limit_not_security_admin() {
    let (token_bridge, _) = deploy_token_bridge();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address,
    };

    let withdrawal_limit = IWithdrawalLimitDispatcher {
        contract_address: token_bridge.contract_address,
    };

    snf::start_cheat_caller_address(token_bridge.contract_address, SECURITY_AGENT());

    let usdc_address = USDC_MOCK_ADDRESS();
    token_bridge_admin.decrease_withdrawal_limit(usdc_address, 10);

    // Withdrawal limit is now applied
    assert(withdrawal_limit.is_withdrawal_limit_applied(usdc_address), 'Limit not applied');

    snf::stop_cheat_caller_address(token_bridge.contract_address);

    token_bridge_admin.disable_withdrawal_limit(usdc_address);

    assert(!withdrawal_limit.is_withdrawal_limit_applied(usdc_address), 'Limit not applied');
}

#[test]
#[should_panic(expected: ('Withdrawal limit not applied',))]
fn disable_withdrawal_limit_limit_not_applied() {
    let (token_bridge, _) = deploy_token_bridge();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address,
    };

    snf::start_cheat_caller_address(token_bridge.contract_address, SECURITY_ADMIN());

    let usdc_address = USDC_MOCK_ADDRESS();

    token_bridge_admin.disable_withdrawal_limit(usdc_address);
}


#[test]
fn is_withdrawal_limit_applied_ok() {
    let (token_bridge, _) = deploy_token_bridge();
    let usdc_address = USDC_MOCK_ADDRESS();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address,
    };
    let withdrawal_limit = IWithdrawalLimitDispatcher {
        contract_address: token_bridge.contract_address,
    };

    assert(!withdrawal_limit.is_withdrawal_limit_applied(usdc_address), 'Limit already applied');

    snf::start_cheat_caller_address(token_bridge.contract_address, SECURITY_AGENT());
    token_bridge_admin.decrease_withdrawal_limit(usdc_address, 10);
    snf::stop_cheat_caller_address(token_bridge.contract_address);

    assert(withdrawal_limit.is_withdrawal_limit_applied(usdc_address), 'Limit not applied');
}
