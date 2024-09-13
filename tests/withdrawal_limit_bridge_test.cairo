use snforge_std as snf;
use snforge_std::EventSpyAssertionsTrait;
use starknet_bridge::bridge::{
    ITokenBridgeAdminDispatcher, ITokenBridgeAdminDispatcherTrait, IWithdrawalLimitStatusDispatcher,
    IWithdrawalLimitStatusDispatcherTrait, TokenBridge, TokenBridge::Event,
};
use super::constants::{OWNER, USDC_MOCK_ADDRESS};
use starknet_bridge::bridge::tests::utils::setup::{deploy_token_bridge};


#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn enable_withdrawal_limit_not_owner() {
    let (token_bridge, _) = deploy_token_bridge();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address
    };

    let usdc_address = USDC_MOCK_ADDRESS();
    token_bridge_admin.enable_withdrawal_limit(usdc_address);
}

#[test]
fn enable_withdrawal_limit_ok() {
    let (token_bridge, mut spy) = deploy_token_bridge();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address
    };
    let withdrawal_limit = IWithdrawalLimitStatusDispatcher {
        contract_address: token_bridge.contract_address
    };

    snf::start_cheat_caller_address(token_bridge.contract_address, OWNER());

    let usdc_address = USDC_MOCK_ADDRESS();
    token_bridge_admin.enable_withdrawal_limit(usdc_address);

    snf::stop_cheat_caller_address(token_bridge.contract_address);

    assert(withdrawal_limit.is_withdrawal_limit_applied(usdc_address), 'Limit not applied');

    let exepected_limit_enabled = TokenBridge::WithdrawalLimitEnabled {
        sender: OWNER(), token: usdc_address
    };
    spy
        .assert_emitted(
            @array![
                (
                    token_bridge_admin.contract_address,
                    Event::WithdrawalLimitEnabled(exepected_limit_enabled)
                )
            ]
        );
}

#[test]
fn disable_withdrwal_limit_ok() {
    let (token_bridge, mut spy) = deploy_token_bridge();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address
    };
    let withdrawal_limit = IWithdrawalLimitStatusDispatcher {
        contract_address: token_bridge.contract_address
    };

    let owner = OWNER();
    snf::start_cheat_caller_address(token_bridge.contract_address, owner);

    let usdc_address = USDC_MOCK_ADDRESS();
    token_bridge_admin.enable_withdrawal_limit(usdc_address);

    // Withdrawal limit is now applied
    assert(withdrawal_limit.is_withdrawal_limit_applied(usdc_address), 'Limit not applied');

    token_bridge_admin.disable_withdrawal_limit(usdc_address);

    assert(
        withdrawal_limit.is_withdrawal_limit_applied(usdc_address) == false, 'Limit not applied'
    );

    let expected_limit_disabled = TokenBridge::WithdrawalLimitDisabled {
        sender: OWNER(), token: usdc_address
    };

    spy
        .assert_emitted(
            @array![
                (
                    token_bridge_admin.contract_address,
                    Event::WithdrawalLimitDisabled(expected_limit_disabled)
                )
            ]
        );
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn disable_withdrawal_limit_not_owner() {
    let (token_bridge, _) = deploy_token_bridge();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address
    };

    let withdrawal_limit = IWithdrawalLimitStatusDispatcher {
        contract_address: token_bridge.contract_address
    };

    let owner = OWNER();
    snf::start_cheat_caller_address(token_bridge.contract_address, owner);

    let usdc_address = USDC_MOCK_ADDRESS();
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
fn is_withdrawal_limit_applied_ok() {
    let (token_bridge, _) = deploy_token_bridge();
    let usdc_address = USDC_MOCK_ADDRESS();
    let token_bridge_admin = ITokenBridgeAdminDispatcher {
        contract_address: token_bridge.contract_address
    };
    let withdrawal_limit = IWithdrawalLimitStatusDispatcher {
        contract_address: token_bridge.contract_address
    };

    assert(
        withdrawal_limit.is_withdrawal_limit_applied(usdc_address) == false, 'Limit already applied'
    );

    snf::start_cheat_caller_address(token_bridge.contract_address, OWNER());
    token_bridge_admin.enable_withdrawal_limit(usdc_address);
    snf::stop_cheat_caller_address(token_bridge.contract_address);

    assert(withdrawal_limit.is_withdrawal_limit_applied(usdc_address), 'Limit not applied');
}
