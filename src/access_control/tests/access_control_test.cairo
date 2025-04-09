use openzeppelin::access::accesscontrol::DEFAULT_ADMIN_ROLE;
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
    [GOVERNANCE_ADMIN()].span().serialize(ref calldata);
    [APP_GOVERNOR()].span().serialize(ref calldata);
    [SECURITY_ADMIN()].span().serialize(ref calldata);
    [SECURITY_AGENT()].span().serialize(ref calldata);
    [TOKEN_ADMIN()].span().serialize(ref calldata);
    UPGRADE_GOVERNOR().serialize(ref calldata);
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

    // Test role assignments
    assert!(
        access_control.has_role(Roles::APP_GOVERNOR, APP_GOVERNOR()), "App governor not granted",
    );
    assert!(
        access_control.has_role(Roles::SECURITY_ADMIN, SECURITY_ADMIN()),
        "Security admin not granted",
    );
    assert!(
        access_control.has_role(Roles::SECURITY_AGENT, SECURITY_AGENT()),
        "Security agent not granted",
    );
    assert!(access_control.has_role(Roles::TOKEN_ADMIN, TOKEN_ADMIN()), "Token admin not granted");
    assert!(
        access_control.has_role(Roles::UPGRADE_GOVERNOR, UPGRADE_GOVERNOR()),
        "Upgrade governor not granted",
    );

    // Test role admin relationships as per the diagram
    // GOVERNANCE_ADMIN is its own admin
    assert!(
        access_control.get_role_admin(Roles::GOVERNANCE_ADMIN) == Roles::GOVERNANCE_ADMIN,
        "Gov_admin: incorrect admin",
    );

    // APP_GOVERNOR is administered by GOVERNANCE_ADMIN
    assert!(
        access_control.get_role_admin(Roles::APP_GOVERNOR) == Roles::GOVERNANCE_ADMIN,
        "App_gov: incorrect admin",
    );

    // SECURITY_ADMIN is administered by GOVERNANCE_ADMIN
    assert!(
        access_control.get_role_admin(Roles::SECURITY_ADMIN) == Roles::GOVERNANCE_ADMIN,
        "Sec_admin: incorrect admin",
    );

    // SECURITY_AGENT is administered by SECURITY_ADMIN
    assert!(
        access_control.get_role_admin(Roles::SECURITY_AGENT) == Roles::SECURITY_ADMIN,
        "Sec_agent: incorrect admin",
    );

    // TOKEN_ADMIN is administered by APP_GOVERNOR
    assert!(
        access_control.get_role_admin(Roles::TOKEN_ADMIN) == Roles::APP_GOVERNOR,
        "Token_admin: incorrect admin",
    );

    // UPGRADE_GOVERNOR is administered by DEFAULT_ADMIN (timelock)
    assert!(
        access_control.get_role_admin(Roles::UPGRADE_GOVERNOR) == DEFAULT_ADMIN_ROLE,
        "Upgrade_gov: incorrect admin",
    );
}
