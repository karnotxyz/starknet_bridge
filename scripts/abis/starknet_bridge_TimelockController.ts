export const ABI = [
  {
    "type": "impl",
    "name": "TimelockComponentImpl",
    "interface_name": "openzeppelin_governance::timelock::interface::ITimelock"
  },
  {
    "type": "enum",
    "name": "core::bool",
    "variants": [
      {
        "name": "False",
        "type": "()"
      },
      {
        "name": "True",
        "type": "()"
      }
    ]
  },
  {
    "type": "enum",
    "name": "openzeppelin_governance::timelock::interface::OperationState",
    "variants": [
      {
        "name": "Unset",
        "type": "()"
      },
      {
        "name": "Waiting",
        "type": "()"
      },
      {
        "name": "Ready",
        "type": "()"
      },
      {
        "name": "Done",
        "type": "()"
      }
    ]
  },
  {
    "type": "struct",
    "name": "core::array::Span::<core::felt252>",
    "members": [
      {
        "name": "snapshot",
        "type": "@core::array::Array::<core::felt252>"
      }
    ]
  },
  {
    "type": "struct",
    "name": "core::starknet::account::Call",
    "members": [
      {
        "name": "to",
        "type": "core::starknet::contract_address::ContractAddress"
      },
      {
        "name": "selector",
        "type": "core::felt252"
      },
      {
        "name": "calldata",
        "type": "core::array::Span::<core::felt252>"
      }
    ]
  },
  {
    "type": "struct",
    "name": "core::array::Span::<core::starknet::account::Call>",
    "members": [
      {
        "name": "snapshot",
        "type": "@core::array::Array::<core::starknet::account::Call>"
      }
    ]
  },
  {
    "type": "interface",
    "name": "openzeppelin_governance::timelock::interface::ITimelock",
    "items": [
      {
        "type": "function",
        "name": "is_operation",
        "inputs": [
          {
            "name": "id",
            "type": "core::felt252"
          }
        ],
        "outputs": [
          {
            "type": "core::bool"
          }
        ],
        "state_mutability": "view"
      },
      {
        "type": "function",
        "name": "is_operation_pending",
        "inputs": [
          {
            "name": "id",
            "type": "core::felt252"
          }
        ],
        "outputs": [
          {
            "type": "core::bool"
          }
        ],
        "state_mutability": "view"
      },
      {
        "type": "function",
        "name": "is_operation_ready",
        "inputs": [
          {
            "name": "id",
            "type": "core::felt252"
          }
        ],
        "outputs": [
          {
            "type": "core::bool"
          }
        ],
        "state_mutability": "view"
      },
      {
        "type": "function",
        "name": "is_operation_done",
        "inputs": [
          {
            "name": "id",
            "type": "core::felt252"
          }
        ],
        "outputs": [
          {
            "type": "core::bool"
          }
        ],
        "state_mutability": "view"
      },
      {
        "type": "function",
        "name": "get_timestamp",
        "inputs": [
          {
            "name": "id",
            "type": "core::felt252"
          }
        ],
        "outputs": [
          {
            "type": "core::integer::u64"
          }
        ],
        "state_mutability": "view"
      },
      {
        "type": "function",
        "name": "get_operation_state",
        "inputs": [
          {
            "name": "id",
            "type": "core::felt252"
          }
        ],
        "outputs": [
          {
            "type": "openzeppelin_governance::timelock::interface::OperationState"
          }
        ],
        "state_mutability": "view"
      },
      {
        "type": "function",
        "name": "get_min_delay",
        "inputs": [],
        "outputs": [
          {
            "type": "core::integer::u64"
          }
        ],
        "state_mutability": "view"
      },
      {
        "type": "function",
        "name": "hash_operation",
        "inputs": [
          {
            "name": "call",
            "type": "core::starknet::account::Call"
          },
          {
            "name": "predecessor",
            "type": "core::felt252"
          },
          {
            "name": "salt",
            "type": "core::felt252"
          }
        ],
        "outputs": [
          {
            "type": "core::felt252"
          }
        ],
        "state_mutability": "view"
      },
      {
        "type": "function",
        "name": "hash_operation_batch",
        "inputs": [
          {
            "name": "calls",
            "type": "core::array::Span::<core::starknet::account::Call>"
          },
          {
            "name": "predecessor",
            "type": "core::felt252"
          },
          {
            "name": "salt",
            "type": "core::felt252"
          }
        ],
        "outputs": [
          {
            "type": "core::felt252"
          }
        ],
        "state_mutability": "view"
      },
      {
        "type": "function",
        "name": "schedule",
        "inputs": [
          {
            "name": "call",
            "type": "core::starknet::account::Call"
          },
          {
            "name": "predecessor",
            "type": "core::felt252"
          },
          {
            "name": "salt",
            "type": "core::felt252"
          },
          {
            "name": "delay",
            "type": "core::integer::u64"
          }
        ],
        "outputs": [],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "schedule_batch",
        "inputs": [
          {
            "name": "calls",
            "type": "core::array::Span::<core::starknet::account::Call>"
          },
          {
            "name": "predecessor",
            "type": "core::felt252"
          },
          {
            "name": "salt",
            "type": "core::felt252"
          },
          {
            "name": "delay",
            "type": "core::integer::u64"
          }
        ],
        "outputs": [],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "cancel",
        "inputs": [
          {
            "name": "id",
            "type": "core::felt252"
          }
        ],
        "outputs": [],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "execute",
        "inputs": [
          {
            "name": "call",
            "type": "core::starknet::account::Call"
          },
          {
            "name": "predecessor",
            "type": "core::felt252"
          },
          {
            "name": "salt",
            "type": "core::felt252"
          }
        ],
        "outputs": [],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "execute_batch",
        "inputs": [
          {
            "name": "calls",
            "type": "core::array::Span::<core::starknet::account::Call>"
          },
          {
            "name": "predecessor",
            "type": "core::felt252"
          },
          {
            "name": "salt",
            "type": "core::felt252"
          }
        ],
        "outputs": [],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "update_delay",
        "inputs": [
          {
            "name": "new_delay",
            "type": "core::integer::u64"
          }
        ],
        "outputs": [],
        "state_mutability": "external"
      }
    ]
  },
  {
    "type": "impl",
    "name": "AccessControlComponentImpl",
    "interface_name": "openzeppelin_access::accesscontrol::interface::IAccessControl"
  },
  {
    "type": "interface",
    "name": "openzeppelin_access::accesscontrol::interface::IAccessControl",
    "items": [
      {
        "type": "function",
        "name": "has_role",
        "inputs": [
          {
            "name": "role",
            "type": "core::felt252"
          },
          {
            "name": "account",
            "type": "core::starknet::contract_address::ContractAddress"
          }
        ],
        "outputs": [
          {
            "type": "core::bool"
          }
        ],
        "state_mutability": "view"
      },
      {
        "type": "function",
        "name": "get_role_admin",
        "inputs": [
          {
            "name": "role",
            "type": "core::felt252"
          }
        ],
        "outputs": [
          {
            "type": "core::felt252"
          }
        ],
        "state_mutability": "view"
      },
      {
        "type": "function",
        "name": "grant_role",
        "inputs": [
          {
            "name": "role",
            "type": "core::felt252"
          },
          {
            "name": "account",
            "type": "core::starknet::contract_address::ContractAddress"
          }
        ],
        "outputs": [],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "revoke_role",
        "inputs": [
          {
            "name": "role",
            "type": "core::felt252"
          },
          {
            "name": "account",
            "type": "core::starknet::contract_address::ContractAddress"
          }
        ],
        "outputs": [],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "renounce_role",
        "inputs": [
          {
            "name": "role",
            "type": "core::felt252"
          },
          {
            "name": "account",
            "type": "core::starknet::contract_address::ContractAddress"
          }
        ],
        "outputs": [],
        "state_mutability": "external"
      }
    ]
  },
  {
    "type": "struct",
    "name": "core::array::Span::<core::starknet::contract_address::ContractAddress>",
    "members": [
      {
        "name": "snapshot",
        "type": "@core::array::Array::<core::starknet::contract_address::ContractAddress>"
      }
    ]
  },
  {
    "type": "constructor",
    "name": "constructor",
    "inputs": [
      {
        "name": "min_delay",
        "type": "core::felt252"
      },
      {
        "name": "proposers",
        "type": "core::array::Span::<core::starknet::contract_address::ContractAddress>"
      },
      {
        "name": "executors",
        "type": "core::array::Span::<core::starknet::contract_address::ContractAddress>"
      },
      {
        "name": "admin",
        "type": "core::starknet::contract_address::ContractAddress"
      }
    ]
  },
  {
    "type": "event",
    "name": "openzeppelin_access::accesscontrol::accesscontrol::AccessControlComponent::RoleGranted",
    "kind": "struct",
    "members": [
      {
        "name": "role",
        "type": "core::felt252",
        "kind": "data"
      },
      {
        "name": "account",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "data"
      },
      {
        "name": "sender",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "data"
      }
    ]
  },
  {
    "type": "event",
    "name": "openzeppelin_access::accesscontrol::accesscontrol::AccessControlComponent::RoleRevoked",
    "kind": "struct",
    "members": [
      {
        "name": "role",
        "type": "core::felt252",
        "kind": "data"
      },
      {
        "name": "account",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "data"
      },
      {
        "name": "sender",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "data"
      }
    ]
  },
  {
    "type": "event",
    "name": "openzeppelin_access::accesscontrol::accesscontrol::AccessControlComponent::RoleAdminChanged",
    "kind": "struct",
    "members": [
      {
        "name": "role",
        "type": "core::felt252",
        "kind": "data"
      },
      {
        "name": "previous_admin_role",
        "type": "core::felt252",
        "kind": "data"
      },
      {
        "name": "new_admin_role",
        "type": "core::felt252",
        "kind": "data"
      }
    ]
  },
  {
    "type": "event",
    "name": "openzeppelin_access::accesscontrol::accesscontrol::AccessControlComponent::Event",
    "kind": "enum",
    "variants": [
      {
        "name": "RoleGranted",
        "type": "openzeppelin_access::accesscontrol::accesscontrol::AccessControlComponent::RoleGranted",
        "kind": "nested"
      },
      {
        "name": "RoleRevoked",
        "type": "openzeppelin_access::accesscontrol::accesscontrol::AccessControlComponent::RoleRevoked",
        "kind": "nested"
      },
      {
        "name": "RoleAdminChanged",
        "type": "openzeppelin_access::accesscontrol::accesscontrol::AccessControlComponent::RoleAdminChanged",
        "kind": "nested"
      }
    ]
  },
  {
    "type": "event",
    "name": "openzeppelin_introspection::src5::SRC5Component::Event",
    "kind": "enum",
    "variants": []
  },
  {
    "type": "event",
    "name": "openzeppelin_governance::timelock::timelock_controller::TimelockControllerComponent::CallScheduled",
    "kind": "struct",
    "members": [
      {
        "name": "id",
        "type": "core::felt252",
        "kind": "key"
      },
      {
        "name": "index",
        "type": "core::felt252",
        "kind": "key"
      },
      {
        "name": "call",
        "type": "core::starknet::account::Call",
        "kind": "data"
      },
      {
        "name": "predecessor",
        "type": "core::felt252",
        "kind": "data"
      },
      {
        "name": "delay",
        "type": "core::integer::u64",
        "kind": "data"
      }
    ]
  },
  {
    "type": "event",
    "name": "openzeppelin_governance::timelock::timelock_controller::TimelockControllerComponent::CallExecuted",
    "kind": "struct",
    "members": [
      {
        "name": "id",
        "type": "core::felt252",
        "kind": "key"
      },
      {
        "name": "index",
        "type": "core::felt252",
        "kind": "key"
      },
      {
        "name": "call",
        "type": "core::starknet::account::Call",
        "kind": "data"
      }
    ]
  },
  {
    "type": "event",
    "name": "openzeppelin_governance::timelock::timelock_controller::TimelockControllerComponent::CallSalt",
    "kind": "struct",
    "members": [
      {
        "name": "id",
        "type": "core::felt252",
        "kind": "key"
      },
      {
        "name": "salt",
        "type": "core::felt252",
        "kind": "data"
      }
    ]
  },
  {
    "type": "event",
    "name": "openzeppelin_governance::timelock::timelock_controller::TimelockControllerComponent::CallCancelled",
    "kind": "struct",
    "members": [
      {
        "name": "id",
        "type": "core::felt252",
        "kind": "key"
      }
    ]
  },
  {
    "type": "event",
    "name": "openzeppelin_governance::timelock::timelock_controller::TimelockControllerComponent::MinDelayChanged",
    "kind": "struct",
    "members": [
      {
        "name": "old_duration",
        "type": "core::integer::u64",
        "kind": "data"
      },
      {
        "name": "new_duration",
        "type": "core::integer::u64",
        "kind": "data"
      }
    ]
  },
  {
    "type": "event",
    "name": "openzeppelin_governance::timelock::timelock_controller::TimelockControllerComponent::Event",
    "kind": "enum",
    "variants": [
      {
        "name": "CallScheduled",
        "type": "openzeppelin_governance::timelock::timelock_controller::TimelockControllerComponent::CallScheduled",
        "kind": "nested"
      },
      {
        "name": "CallExecuted",
        "type": "openzeppelin_governance::timelock::timelock_controller::TimelockControllerComponent::CallExecuted",
        "kind": "nested"
      },
      {
        "name": "CallSalt",
        "type": "openzeppelin_governance::timelock::timelock_controller::TimelockControllerComponent::CallSalt",
        "kind": "nested"
      },
      {
        "name": "CallCancelled",
        "type": "openzeppelin_governance::timelock::timelock_controller::TimelockControllerComponent::CallCancelled",
        "kind": "nested"
      },
      {
        "name": "MinDelayChanged",
        "type": "openzeppelin_governance::timelock::timelock_controller::TimelockControllerComponent::MinDelayChanged",
        "kind": "nested"
      }
    ]
  },
  {
    "type": "event",
    "name": "starknet_bridge::timelock::timelock::TimelockController::Event",
    "kind": "enum",
    "variants": [
      {
        "name": "AccessControlEvent",
        "type": "openzeppelin_access::accesscontrol::accesscontrol::AccessControlComponent::Event",
        "kind": "flat"
      },
      {
        "name": "SRC5Event",
        "type": "openzeppelin_introspection::src5::SRC5Component::Event",
        "kind": "flat"
      },
      {
        "name": "TimelockEvent",
        "type": "openzeppelin_governance::timelock::timelock_controller::TimelockControllerComponent::Event",
        "kind": "flat"
      }
    ]
  }
] as const;
