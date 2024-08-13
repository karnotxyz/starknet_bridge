use starknet::ContractAddress;
use core::integer::BoundedInt;
use snforge_std as snf;
use snforge_std::{
    ContractClassTrait, EventSpy, EventSpyTrait, EventsFilterTrait, EventSpyAssertionsTrait
};
use starknet_bridge::bridge::tests::constants::{
    OWNER, L3_BRIDGE_ADDRESS, USDC_MOCK_ADDRESS, DELAY_TIME
};
use starknet_bridge::withdrawal_limit::{
    mock::{
        withdrawal_limit_mock, IMockWithdrawalLimitDispatcher, IMockWithdrawalLimitDispatcherTrait
    },
    interface::{IWithdrawalLimit, IWithdrawalLimitDispatcher, IWithdrawalLimitDispatcherTrait,}
};
use openzeppelin::token::erc20::interface::{IERC20, IERC20Dispatcher, IERC20DispatcherTrait};

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


pub fn deploy_erc20(name: ByteArray, symbol: ByteArray) -> ContractAddress {
    let erc20_class_hash = snf::declare("ERC20").unwrap();
    let mut constructor_args = ArrayTrait::new();
    name.serialize(ref constructor_args);
    symbol.serialize(ref constructor_args);
    let fixed_supply: u256 = 1000000000;
    fixed_supply.serialize(ref constructor_args);
    OWNER().serialize(ref constructor_args);

    let (usdc, _) = erc20_class_hash.deploy(@constructor_args).unwrap();

    let usdc_token = IERC20Dispatcher { contract_address: usdc };

    // Transfering usdc to test address for testing
    snf::start_cheat_caller_address(usdc, OWNER());
    usdc_token.transfer(snf::test_address(), 1000_000_000);
    snf::stop_cheat_caller_address(usdc);

    return usdc;
}

fn mock_component_state() -> withdrawal_limit_mock::ContractState {
    let mut mock = withdrawal_limit_mock::contract_state_for_testing();

    withdrawal_limit_mock::constructor(ref mock);
    return mock;
}

#[test]
fn get_remaining_withdrawal_quota_ok() {
    let (withdrawal_limit, _) = deploy_withdrawal_limit();

    let usdc_address = deploy_erc20("USDC", "USDC");
    let usdc = IERC20Dispatcher { contract_address: usdc_address };
    // Mocking deposits with the contract
    usdc.transfer(withdrawal_limit.contract_address, 1000_000);

    let withdrawal_limit_mock = IMockWithdrawalLimitDispatcher {
        contract_address: withdrawal_limit.contract_address
    };

    assert(
        withdrawal_limit.get_remaining_withdrawal_quota(usdc_address) == BoundedInt::max(),
        'Quota should be 0'
    );
    withdrawal_limit_mock.change_withdrawal_limit_token(usdc_address, true);

    assert(
        withdrawal_limit.get_remaining_withdrawal_quota(usdc_address) == 5000_0,
        'Quota should not be 0'
    );
}

#[test]
fn consume_withdrawal_quota_ok() {
    let (withdrawal_limit, _) = deploy_withdrawal_limit();

    let usdc_address = deploy_erc20("USDC", "USDC");
    let usdc = IERC20Dispatcher { contract_address: usdc_address };
    // Mocking deposits with the contract
    usdc.transfer(withdrawal_limit.contract_address, 1000_000);

    let withdrawal_limit_mock = IMockWithdrawalLimitDispatcher {
        contract_address: withdrawal_limit.contract_address
    };

    assert(
        withdrawal_limit.get_remaining_withdrawal_quota(usdc_address) == BoundedInt::max(),
        'Quota should be 0'
    );
    withdrawal_limit_mock.change_withdrawal_limit_token(usdc_address, true);

    assert(
        withdrawal_limit.get_remaining_withdrawal_quota(usdc_address) == 5000_0,
        'Quota should not be 0'
    );
}

