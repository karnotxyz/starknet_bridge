use snforge_std as snf;
use snforge_std::{
    ContractClassTrait, EventSpy, EventSpyTrait, EventsFilterTrait, EventSpyAssertionsTrait
};

use starknet_bridge::bridge::tests::constants::{
    OWNER, L3_BRIDGE_ADDRESS, USDC_MOCK_ADDRESS, DELAY_TIME
};
use starknet_bridge::withdrawal_limit::{
    mock::{IMockWithdrawalLimitDispatcher, IMockWithdrawalLimitDispatcherTrait},
    interface::{IWithdrawalLimit, IWithdrawalLimitDispatcher, IWithdrawalLimitDispatcherTrait,}
};

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
    let usdc_address = USDC_MOCK_ADDRESS();
    let withdrawal_limit_mock = IMockWithdrawalLimitDispatcher {
        contract_address: withdrawal_limit.contract_address
    };

    withdrawal_limit_mock.change_withdrawal_limit_token(usdc_address, true);
}
