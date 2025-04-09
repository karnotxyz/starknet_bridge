use openzeppelin::access::accesscontrol::interface::{
    IAccessControlDispatcher, IAccessControlDispatcherTrait,
};
use snforge_std as snf;
use snforge_std::{ContractClassTrait, DeclareResultTrait, EventSpy};
use starknet_bridge::access_control::roles::Roles;
use starknet_bridge::bridge::tests::constants::{
    APP_GOVERNOR, GOVERNANCE_ADMIN, SECURITY_ADMIN, SECURITY_AGENT, TOKEN_ADMIN, UPGRADE_GOVERNOR,
};

fn deploy_access_control() -> (IAccessControlDispatcher, EventSpy) {
    let access_control_mock_class_hash = snf::declare("access_control_mock")
        .unwrap()
        .contract_class();

    let mut calldata = ArrayTrait::new();
    [GOVERNANCE_ADMIN()].serialize(ref calldata);
    [APP_GOVERNOR()].serialize(ref calldata);
    [SECURITY_ADMIN()].serialize(ref calldata);
    [SECURITY_AGENT()].serialize(ref calldata);
    [TOKEN_ADMIN()].serialize(ref calldata);
    [UPGRADE_GOVERNOR()].serialize(ref calldata);
    let (access_control_mock_address, _) = access_control_mock_class_hash
        .deploy(@calldata)
        .unwrap();
    let access_control_mock = IAccessControlDispatcher {
        contract_address: access_control_mock_address,
    };

    let mut spy = snf::spy_events();
    (access_control_mock, spy)
}


#[test]
fn test_access_control_roles() {
    let (access_control, _) = deploy_access_control();

    access_control.has_role(Roles::GOVERNANCE_ADMIN, GOVERNANCE_ADMIN());
    access_control.has_role(Roles::APP_GOVERNOR, APP_GOVERNOR());
    access_control.has_role(Roles::SECURITY_ADMIN, SECURITY_ADMIN());
    access_control.has_role(Roles::SECURITY_AGENT, SECURITY_AGENT());
    access_control.has_role(Roles::TOKEN_ADMIN, TOKEN_ADMIN());
    access_control.has_role(Roles::UPGRADE_GOVERNOR, UPGRADE_GOVERNOR());
}
