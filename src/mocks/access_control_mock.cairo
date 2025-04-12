#[starknet::contract]
mod access_control_mock {
    use openzeppelin::access::accesscontrol::AccessControlComponent;
    use openzeppelin::introspection::src5::SRC5Component;
    use starknet::ContractAddress;
    use starknet_bridge::access_control::component::BridgeAccessControlComponent;

    component!(
        path: BridgeAccessControlComponent,
        storage: bridge_access_control,
        event: BridgeAccessControlEvent,
    );
    component!(path: AccessControlComponent, storage: access_control, event: AccessControlEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);


    #[abi(embed_v0)]
    impl AccessControlImpl =
        AccessControlComponent::AccessControlImpl<ContractState>;
    impl BridgeAccessControlInternal = BridgeAccessControlComponent::InternalImpl<ContractState>;
    impl AccessControlInternal = AccessControlComponent::InternalImpl<ContractState>;


    #[storage]
    struct Storage {
        #[substorage(v0)]
        pub bridge_access_control: BridgeAccessControlComponent::Storage,
        #[substorage(v0)]
        pub access_control: AccessControlComponent::Storage,
        #[substorage(v0)]
        pub src5: SRC5Component::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        #[flat]
        BridgeAccessControlEvent: BridgeAccessControlComponent::Event,
        #[flat]
        AccessControlEvent: AccessControlComponent::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        governance_admins: Span<ContractAddress>,
        app_governors: Span<ContractAddress>,
        security_admins: Span<ContractAddress>,
        security_agents: Span<ContractAddress>,
        token_admins: Span<ContractAddress>,
        upgrade_governor: ContractAddress,
    ) {
        self
            .bridge_access_control
            .initializer(
                governance_admins,
                app_governors,
                security_admins,
                security_agents,
                token_admins,
                upgrade_governor,
            );
    }
}
