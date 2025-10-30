#[starknet::contract]
pub mod TimelockController {
    use TimelockControllerComponent::InternalTrait as TimelockInternalTrait;
    use openzeppelin::access::accesscontrol::{AccessControlComponent, DEFAULT_ADMIN_ROLE};
    use openzeppelin::access::accesscontrol::interface::IAccessControl;
    use openzeppelin::governance::timelock::{
        CANCELLER_ROLE, EXECUTOR_ROLE, PROPOSER_ROLE, TimelockControllerComponent,
    };
    use openzeppelin::introspection::src5::SRC5Component;
    use starknet::ContractAddress;

    component!(path: AccessControlComponent, storage: access_control, event: AccessControlEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: TimelockControllerComponent, storage: timelock, event: TimelockEvent);

    // Timelock Implementations
    #[abi(embed_v0)]
    impl TimelockComponentImpl =
        TimelockControllerComponent::TimelockImpl<ContractState>;
    impl TimelockInternalImpl = TimelockControllerComponent::InternalImpl<ContractState>;

    // AccessControl Internal Implementation
    impl AccessControlInternalImpl = AccessControlComponent::InternalImpl<ContractState>;

    #[storage]
    pub struct Storage {
        #[substorage(v0)]
        pub access_control: AccessControlComponent::Storage,
        #[substorage(v0)]
        pub src5: SRC5Component::Storage,
        #[substorage(v0)]
        pub timelock: TimelockControllerComponent::Storage,
    }

    pub mod Errors {
        pub const INVALID_ADDRESS: felt252 = 'Invalid 0 address';
        pub const INVALID_SELF_ADDRESS: felt252 = 'Invalid self address';
        pub const ZERO_LENGTH_SPAN: felt252 = 'Zero length span';
        pub const DEFAULT_ADMIN_ROLE_CANNOT_RENOUNCE: felt252 = 'Default admin cannot renounce';
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        AccessControlEvent: AccessControlComponent::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        TimelockEvent: TimelockControllerComponent::Event,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        min_delay: felt252,
        proposers: Span<ContractAddress>,
        executors: Span<ContractAddress>,
        admin: ContractAddress,
    ) {
        check_addresses(proposers, executors, admin);
        self.timelock.initializer(min_delay.try_into().unwrap(), proposers, executors, admin);

        // set role admin as super admin
        self.access_control.set_role_admin(PROPOSER_ROLE, DEFAULT_ADMIN_ROLE);
        self.access_control.set_role_admin(EXECUTOR_ROLE, DEFAULT_ADMIN_ROLE);
        self.access_control.set_role_admin(CANCELLER_ROLE, DEFAULT_ADMIN_ROLE);
    }

    fn check_addresses(
        proposers: Span<ContractAddress>, executors: Span<ContractAddress>, admin: ContractAddress,
    ) {
        assert(admin != 0.try_into().unwrap(), Errors::INVALID_ADDRESS);
        check_valid_addresses(proposers);
        check_valid_addresses(executors);
    }

    fn check_valid_addresses(addresses: Span<ContractAddress>) {
        assert(addresses.len() > 0, Errors::ZERO_LENGTH_SPAN);

        for address in addresses {
            assert(*address != 0.try_into().unwrap(), Errors::INVALID_ADDRESS);
        }
    }


    #[abi(embed_v0)]
    pub impl AccessControlImpl of IAccessControl<ContractState> {
        fn has_role(self: @ContractState, role: felt252, account: ContractAddress) -> bool {
            self.access_control.has_role(role, account)
        }

        fn get_role_admin(self: @ContractState, role: felt252) -> felt252 {
            self.access_control.get_role_admin(role)
        }

        fn grant_role(ref self: ContractState, role: felt252, account: ContractAddress) {
            self.access_control.grant_role(role, account)
        }

        fn revoke_role(ref self: ContractState, role: felt252, account: ContractAddress) {
            self.access_control.revoke_role(role, account)
        }

        fn renounce_role(ref self: ContractState, role: felt252, account: ContractAddress) {
            assert(role != DEFAULT_ADMIN_ROLE, Errors::DEFAULT_ADMIN_ROLE_CANNOT_RENOUNCE);
            self.access_control.renounce_role(role, account)
        }
    }
}
