use core::num::traits::Bounded;
use snforge_std as snf;
use snforge_std::{ContractClassTrait, EventSpy, EventSpyAssertionsTrait};
use starknet_bridge::bridge::tests::constants::{OWNER};
use starknet_bridge::mocks::withdrawal_limit_mock::{
    IMockWithdrawalLimitDispatcher, IMockWithdrawalLimitDispatcherTrait
};


use starknet_bridge::withdrawal_limit::interface::{
    IWithdrawalLimitDispatcher, IWithdrawalLimitDispatcherTrait,
};
use starknet_bridge::withdrawal_limit::component::{
    WithdrawalLimitComponent,
    WithdrawalLimitComponent::{RemainingQuotaUpdated, DailyWithdrawalPercentageUpdated}
};
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use starknet_bridge::bridge::tests::utils::setup::deploy_erc20;


fn deploy_withdrawal_limit() -> (IWithdrawalLimitDispatcher, EventSpy) {
    let withdrawal_limit_mock_class_hash = snf::declare("withdrawal_limit_mock").unwrap();
    let (withdrawal_limit_mock_address, _) = withdrawal_limit_mock_class_hash
        .deploy(@array![])
        .unwrap();
    let withdrawal_limit_mock = IWithdrawalLimitDispatcher {
        contract_address: withdrawal_limit_mock_address
    };

    let mut spy = snf::spy_events();
    (withdrawal_limit_mock, spy)
}


#[test]
fn get_remaining_withdrawal_quota_ok() {
    let (withdrawal_limit, _) = deploy_withdrawal_limit();

    let usdc_address = deploy_erc20("USDC", "USDC");
    let usdc = IERC20Dispatcher { contract_address: usdc_address };

    // Transfering usdc to test address for testing
    snf::start_cheat_caller_address(usdc.contract_address, OWNER());
    usdc.transfer(snf::test_address(), 10_000_000);
    snf::stop_cheat_caller_address(usdc.contract_address);

    // Mocking deposits with the contract
    usdc.transfer(withdrawal_limit.contract_address, 1_000_000);

    let withdrawal_limit_mock = IMockWithdrawalLimitDispatcher {
        contract_address: withdrawal_limit.contract_address
    };

    // Should return BoundedInt::max() when withdrawal limit not applied
    assert(
        withdrawal_limit.get_remaining_withdrawal_quota(usdc_address) == Bounded::MAX,
        'Quota is not BoundedInt::max()'
    );
    withdrawal_limit_mock.toggle_withdrawal_limit_for_token(usdc_address, true);

    // Should return the default 5% of the balance of contract when limit applied
    assert(
        withdrawal_limit.get_remaining_withdrawal_quota(usdc_address) == 50_000,
        'Quota should not be 0'
    );
}

#[test]
fn consume_withdrawal_quota_ok() {
    let (withdrawal_limit, mut spy) = deploy_withdrawal_limit();

    let usdc_address = deploy_erc20("USDC", "USDC");
    let usdc = IERC20Dispatcher { contract_address: usdc_address };

    // Transfering usdc to test address for testing
    snf::start_cheat_caller_address(usdc.contract_address, OWNER());
    usdc.transfer(snf::test_address(), 10_000_000);
    snf::stop_cheat_caller_address(usdc.contract_address);

    // Mocking deposits with the contract
    usdc.transfer(withdrawal_limit.contract_address, 1000_000);

    let withdrawal_limit_mock = IMockWithdrawalLimitDispatcher {
        contract_address: withdrawal_limit.contract_address
    };

    withdrawal_limit_mock.toggle_withdrawal_limit_for_token(usdc_address, true);

    assert(
        withdrawal_limit.get_remaining_withdrawal_quota(usdc_address) == 5000_0,
        'Quota should not be 0'
    );
    withdrawal_limit_mock.consume_quota(usdc_address, 10_000);

    // The daily quota should reduce by the exact amount after consumption
    assert(
        withdrawal_limit.get_remaining_withdrawal_quota(usdc_address) == 4000_0,
        'Daily quota not updated'
    );

    let expected_event = RemainingQuotaUpdated { token: usdc_address, day: 0, new_quota: 40000 };
    spy
        .assert_emitted(
            @array![
                (
                    withdrawal_limit_mock.contract_address,
                    WithdrawalLimitComponent::Event::RemainingQuotaUpdated(expected_event)
                )
            ]
        );
}

#[test]
#[should_panic(expected: ('LIMIT_EXCEEDED',))]
fn consume_withdrawal_quota_limit_exceeded() {
    let (withdrawal_limit, _) = deploy_withdrawal_limit();

    let usdc_address = deploy_erc20("USDC", "USDC");
    let usdc = IERC20Dispatcher { contract_address: usdc_address };
    // Transfering usdc to test address for testing
    snf::start_cheat_caller_address(usdc.contract_address, OWNER());
    usdc.transfer(snf::test_address(), 10_000_000);
    snf::stop_cheat_caller_address(usdc.contract_address);

    // Mocking deposits with the contract
    usdc.transfer(withdrawal_limit.contract_address, 1000_000);

    let withdrawal_limit_mock = IMockWithdrawalLimitDispatcher {
        contract_address: withdrawal_limit.contract_address
    };

    withdrawal_limit_mock.toggle_withdrawal_limit_for_token(usdc_address, true);

    assert(
        withdrawal_limit.get_remaining_withdrawal_quota(usdc_address) == 5000_0,
        'Quota should not be 0'
    );
    withdrawal_limit_mock.consume_quota(usdc_address, 1000_00);
}

#[test]
fn get_remaining_withdrawal_quota_should_reset_after_1_day_ok() {
    let (withdrawal_limit, _) = deploy_withdrawal_limit();

    let usdc_address = deploy_erc20("USDC", "USDC");
    let usdc = IERC20Dispatcher { contract_address: usdc_address };

    // Transfering usdc to test address for testing
    snf::start_cheat_caller_address(usdc.contract_address, OWNER());
    usdc.transfer(snf::test_address(), 10_000_000);
    snf::stop_cheat_caller_address(usdc.contract_address);

    // Mocking deposits with the contract
    usdc.transfer(withdrawal_limit.contract_address, 1000_000);
    let withdrawal_limit_mock = IMockWithdrawalLimitDispatcher {
        contract_address: withdrawal_limit.contract_address
    };

    withdrawal_limit_mock.toggle_withdrawal_limit_for_token(usdc_address, true);

    assert(
        withdrawal_limit.get_remaining_withdrawal_quota(usdc_address) == 5000_0,
        'Quota should not be 0'
    );
    withdrawal_limit_mock.consume_quota(usdc_address, 10000);

    // The daily quota should reduce by the exact amount after consumption
    assert(
        withdrawal_limit.get_remaining_withdrawal_quota(usdc_address) == 4000_0,
        'Daily quota not updated'
    );

    let current_time = starknet::get_block_timestamp();
    // Forwarding the time by one day
    snf::start_cheat_block_timestamp_global(current_time + 86400 + 10);

    assert(
        withdrawal_limit.get_remaining_withdrawal_quota(usdc_address) == 5000_0,
        'Daily quota not updated'
    );
}

#[test]
fn write_daily_withdrawal_limit_pct_ok() {
    let (withdrawal_limit, mut spy) = deploy_withdrawal_limit();

    let withdrawal_limit_mock = IMockWithdrawalLimitDispatcher {
        contract_address: withdrawal_limit.contract_address
    };

    assert(withdrawal_limit_mock.get_daily_withdrawal_limit_pct() == 5, 'Limit not set');
    withdrawal_limit_mock.write_daily_withdrawal_limit_pct(10);

    assert(withdrawal_limit_mock.get_daily_withdrawal_limit_pct() == 10, 'Limit not set');
    let expected_event = DailyWithdrawalPercentageUpdated { new_percentage: 10 };
    spy
        .assert_emitted(
            @array![
                (
                    withdrawal_limit_mock.contract_address,
                    WithdrawalLimitComponent::Event::DailyWithdrawalPercentageUpdated(
                        expected_event
                    )
                )
            ]
        );
}

#[test]
#[should_panic(expected: ('LIMIT_PCT_TOO_HIGH',))]
fn write_daily_withdrawal_limit_pct_too_high() {
    let (withdrawal_limit, _) = deploy_withdrawal_limit();

    let withdrawal_limit_mock = IMockWithdrawalLimitDispatcher {
        contract_address: withdrawal_limit.contract_address
    };

    assert(withdrawal_limit_mock.get_daily_withdrawal_limit_pct() == 5, 'Limit not set');
    withdrawal_limit_mock.write_daily_withdrawal_limit_pct(150);
}

