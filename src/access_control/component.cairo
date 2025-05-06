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
    use openzeppelin::access::accesscontrol::interface::IAccessControl;
    use starknet::ContractAddress;
    use starknet_bridge::access_control::roles::Roles;

    #[storage]
    pub struct Storage {}

    //
    // Errors
    //
    pub mod Errors {
        pub const GOV_ADMIN_CANNOT_RENOUNCE: felt252 = 'Gov admin cannot renounce';
        pub const INVALID_ADDRESS: felt252 = 'Invalid 0 address';
        pub const ZERO_LENGTH_SPAN: felt252 = 'Zero length span';
    }


    #[generate_trait]
    pub impl InternalImpl<
        TContractState,
        +HasComponent<TContractState>,
        impl AccessControl: AccessControlComponent::HasComponent<TContractState>,
        +SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>,
    > of InternalTrait<TContractState> {
        fn initializer(
            ref self: ComponentState<TContractState>,
            governance_admins: Span<ContractAddress>,
            app_governors: Span<ContractAddress>,
            security_admins: Span<ContractAddress>,
            security_agents: Span<ContractAddress>,
            token_admins: Span<ContractAddress>,
            upgrade_governor: ContractAddress,
        ) {
            check_addresses(
                governance_admins,
                app_governors,
                security_admins,
                security_agents,
                token_admins,
                upgrade_governor,
            );

            let mut access_control = get_dep_component_mut!(ref self, AccessControl);
            access_control.initializer();

            access_control._grant_role(DEFAULT_ADMIN_ROLE, upgrade_governor);

            // Only the upgrade_governor will be the upgrade governor
            access_control._grant_role(Roles::UPGRADE_GOVERNOR, upgrade_governor);

            for governance_admin in governance_admins {
                access_control._grant_role(Roles::GOVERNANCE_ADMIN, *governance_admin);
            };

            for app_governor in app_governors {
                access_control._grant_role(Roles::APP_GOVERNOR, *app_governor);
            };

            for security_admin in security_admins {
                access_control._grant_role(Roles::SECURITY_ADMIN, *security_admin);
            };

            for security_agent in security_agents {
                access_control._grant_role(Roles::SECURITY_AGENT, *security_agent);
            };

            for token_admin in token_admins {
                access_control._grant_role(Roles::TOKEN_ADMIN, *token_admin);
            };

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

    fn check_addresses(
        governance_admins: Span<ContractAddress>,
        app_governors: Span<ContractAddress>,
        security_admins: Span<ContractAddress>,
        security_agents: Span<ContractAddress>,
        token_admins: Span<ContractAddress>,
        upgrade_governor: ContractAddress,
    ) {
        assert(upgrade_governor != 0.try_into().unwrap(), Errors::INVALID_ADDRESS);
        check_valid_addresses(governance_admins);
        check_valid_addresses(app_governors);
        check_valid_addresses(security_admins);
        check_valid_addresses(security_agents);
        check_valid_addresses(token_admins);
    }

    fn check_valid_addresses(addresses: Span<ContractAddress>) {
        assert(addresses.len() > 0, Errors::ZERO_LENGTH_SPAN);
        for address in addresses {
            assert(*address != 0.try_into().unwrap(), Errors::INVALID_ADDRESS);
        }
    }

    #[embeddable_as(BridgeAccessControlImpl)]
    pub impl AccessControlImpl<
        TContractState,
        +HasComponent<TContractState>,
        impl AccessControl: AccessControlComponent::HasComponent<TContractState>,
        +SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>,
    > of IAccessControl<ComponentState<TContractState>> {
        fn has_role(
            self: @ComponentState<TContractState>, role: felt252, account: ContractAddress,
        ) -> bool {
            let access_control = get_dep_component!(self, AccessControl);
            access_control.has_role(role, account)
        }

        fn get_role_admin(self: @ComponentState<TContractState>, role: felt252) -> felt252 {
            let access_control = get_dep_component!(self, AccessControl);
            access_control.get_role_admin(role)
        }

        fn grant_role(
            ref self: ComponentState<TContractState>, role: felt252, account: ContractAddress,
        ) {
            let mut access_control = get_dep_component_mut!(ref self, AccessControl);
            access_control.grant_role(role, account)
        }

        fn revoke_role(
            ref self: ComponentState<TContractState>, role: felt252, account: ContractAddress,
        ) {
            let mut access_control = get_dep_component_mut!(ref self, AccessControl);
            access_control.revoke_role(role, account)
        }

        fn renounce_role(
            ref self: ComponentState<TContractState>, role: felt252, account: ContractAddress,
        ) {
            assert(role != Roles::GOVERNANCE_ADMIN, Errors::GOV_ADMIN_CANNOT_RENOUNCE);

            let mut access_control = get_dep_component_mut!(ref self, AccessControl);
            access_control.renounce_role(role, account)
        }
    }
}
