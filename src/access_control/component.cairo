#[starknet::component]
pub mod BridgeAccessControlComponent {
    use openzeppelin::access::accesscontrol::AccessControlComponent::{
        InternalImpl as AccessControlInternalImpl, InternalTrait as AccessControlInternalTrait,
    };
    use openzeppelin::access::accesscontrol::{AccessControlComponent, DEFAULT_ADMIN_ROLE};
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::introspection::src5::SRC5Component::{
        InternalImpl as SRC5InternalImpl, SRC5Impl,
    };
    use starknet::ContractAddress;
    use starknet_bridge::access_control::roles::Roles;

    #[storage]
    pub struct Storage {}


    #[generate_trait]
    pub impl InternalImpl<
        TContractState,
        +HasComponent<TContractState>,
        impl AccessControl: AccessControlComponent::HasComponent<TContractState>,
        impl SRC5: SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>,
    > of InternalTrait<TContractState> {
        fn initializer(
            ref self: ComponentState<TContractState>,
            governance_admins: Span<ContractAddress>,
            app_governors: Span<ContractAddress>,
            security_admins: Span<ContractAddress>,
            security_agents: Span<ContractAddress>,
            token_admins: Span<ContractAddress>,
            timelock: ContractAddress,
        ) {
            let mut access_control = get_dep_component_mut!(ref self, AccessControl);
            access_control.initializer();

            access_control._grant_role(DEFAULT_ADMIN_ROLE, timelock);

            // Only the timelock will be the upgrade governor
            access_control._grant_role(Roles::UPGRADE_GOVERNOR, timelock);

            for governance_admin in governance_admins {
                access_control._grant_role(Roles::GOVERNANCE_ADMIN, *governance_admin);
            }

            for app_governor in app_governors {
                access_control._grant_role(Roles::APP_GOVERNOR, *app_governor);
            }

            for security_admin in security_admins {
                access_control._grant_role(Roles::SECURITY_ADMIN, *security_admin);
            }

            for security_agent in security_agents {
                access_control._grant_role(Roles::SECURITY_AGENT, *security_agent);
            }

            for token_admin in token_admins {
                access_control._grant_role(Roles::TOKEN_ADMIN, *token_admin);
            }

            // Set role admins
            access_control.set_role_admin(Roles::GOVERNANCE_ADMIN, Roles::GOVERNANCE_ADMIN);
            access_control.set_role_admin(Roles::APP_GOVERNOR, Roles::GOVERNANCE_ADMIN);
            access_control.set_role_admin(Roles::SECURITY_ADMIN, Roles::GOVERNANCE_ADMIN);
            access_control.set_role_admin(Roles::SECURITY_AGENT, Roles::SECURITY_ADMIN);
            access_control.set_role_admin(Roles::TOKEN_ADMIN, Roles::APP_GOVERNOR);
        }

        fn assert_only_governance_admin(self: @ComponentState<TContractState>) {
            let access_control = get_dep_component!(self, AccessControl);
            access_control.assert_only_role(Roles::GOVERNANCE_ADMIN);
        }

        fn assert_only_security_agent(self: @ComponentState<TContractState>) {
            let access_control = get_dep_component!(self, AccessControl);
            access_control.assert_only_role(Roles::SECURITY_AGENT);
        }

        fn assert_only_security_admin(self: @ComponentState<TContractState>) {
            let access_control = get_dep_component!(self, AccessControl);
            access_control.assert_only_role(Roles::SECURITY_ADMIN);
        }

        fn assert_only_app_governor(self: @ComponentState<TContractState>) {
            let access_control = get_dep_component!(self, AccessControl);
            access_control.assert_only_role(Roles::APP_GOVERNOR);
        }

        fn assert_only_upgrade_governor(self: @ComponentState<TContractState>) {
            let access_control = get_dep_component!(self, AccessControl);
            access_control.assert_only_role(Roles::UPGRADE_GOVERNOR);
        }

        fn assert_only_token_admin(self: @ComponentState<TContractState>) {
            let access_control = get_dep_component!(self, AccessControl);
            access_control.assert_only_role(Roles::TOKEN_ADMIN);
        }
    }
}
