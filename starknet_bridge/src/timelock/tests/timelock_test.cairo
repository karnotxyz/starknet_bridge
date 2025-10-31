use snforge_std as snf;
use snforge_std::{ContractClassTrait, DeclareResultTrait};
use starknet_bridge::bridge::tests::constants::{
    DELAY_TIME, PROPOSER_ROLE, EXECUTOR_ROLE, DEFAULT_ADMIN,
};
use openzeppelin::access::accesscontrol::{
    DEFAULT_ADMIN_ROLE, interface::{IAccessControlDispatcher, IAccessControlDispatcherTrait},
};
use openzeppelin::governance::timelock::interface::ITimelockDispatcher;

fn deploy_timelock() -> (ITimelockDispatcher, snf::EventSpy) {
    let timelock_class = snf::declare("TimelockController").unwrap().contract_class();

    let mut calldata = ArrayTrait::new();
    DELAY_TIME.serialize(ref calldata);
    [PROPOSER_ROLE()].span().serialize(ref calldata);
    [EXECUTOR_ROLE()].span().serialize(ref calldata);
    DEFAULT_ADMIN().serialize(ref calldata);

    let (timelock_address, _) = timelock_class.deploy(@calldata).unwrap();
    let timelock = ITimelockDispatcher { contract_address: timelock_address };

    let mut spy = snf::spy_events();
    (timelock, spy)
}

#[test]
#[should_panic(expected: ('Default admin cannot renounce',))]
fn test_timelock_deploy() {
    let (timelock, _) = deploy_timelock();
    let access_control = IAccessControlDispatcher { contract_address: timelock.contract_address };
    snf::start_cheat_caller_address_global(DEFAULT_ADMIN());
    access_control.renounce_role(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN());
}

