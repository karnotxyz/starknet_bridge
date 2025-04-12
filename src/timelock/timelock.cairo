#[starknet::contract]
pub mod TimelockController {
    use TimelockControllerComponent::InternalTrait as TimelockInternalTrait;
    use openzeppelin::access::accesscontrol::{AccessControlComponent, DEFAULT_ADMIN_ROLE};
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


    // Timelock Implementations
    #[abi(embed_v0)]
    impl AccessControlComponentImpl =
        AccessControlComponent::AccessControlImpl<ContractState>;
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
        self.timelock.initializer(min_delay.try_into().unwrap(), proposers, executors, admin);

        // set role admin as super admin
        self.access_control.set_role_admin(PROPOSER_ROLE, DEFAULT_ADMIN_ROLE);
        self.access_control.set_role_admin(EXECUTOR_ROLE, DEFAULT_ADMIN_ROLE);
        self.access_control.set_role_admin(CANCELLER_ROLE, DEFAULT_ADMIN_ROLE);
    }
}
