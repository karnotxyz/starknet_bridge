use core::starknet::ContractAddress;
use openzeppelin::access::accesscontrol::interface::{
    IAccessControlDispatcher, IAccessControlDispatcherTrait,
};
use crate::access_control::roles::Roles;

pub fn has_role_only(
    access_control: IAccessControlDispatcher, role: felt252, address: ContractAddress,
) -> bool {
    // Check that address has the specified role
    let has_specified_role = access_control.has_role(role, address);

    // Check that address doesn't have any other roles
    let has_no_other_roles = !access_control.has_role(Roles::GOVERNANCE_ADMIN, address)
        || (role == Roles::GOVERNANCE_ADMIN)
        && !access_control.has_role(Roles::APP_GOVERNOR, address) || (role == Roles::APP_GOVERNOR)
        && !access_control.has_role(Roles::SECURITY_ADMIN, address)
            || (role == Roles::SECURITY_ADMIN)
        && !access_control.has_role(Roles::SECURITY_AGENT, address)
            || (role == Roles::SECURITY_AGENT)
        && !access_control.has_role(Roles::TOKEN_ADMIN, address) || (role == Roles::TOKEN_ADMIN)
        && !access_control.has_role(Roles::UPGRADE_GOVERNOR, address)
            || (role == Roles::UPGRADE_GOVERNOR);

    has_specified_role && has_no_other_roles
}
