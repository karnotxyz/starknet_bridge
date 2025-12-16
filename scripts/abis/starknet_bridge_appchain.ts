export const ABI = [
  {
    "type": "impl",
    "name": "Appchain",
    "interface_name": "piltover::interface::IAppchain"
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
    "type": "interface",
    "name": "piltover::interface::IAppchain",
    "items": [
      {
        "type": "function",
        "name": "update_state",
        "inputs": [
          {
            "name": "snos_output",
            "type": "core::array::Span::<core::felt252>"
          },
          {
            "name": "layout_bridge_output",
            "type": "core::array::Span::<core::felt252>"
          }
        ],
        "outputs": [],
        "state_mutability": "external"
      }
    ]
  },
  {
    "type": "impl",
    "name": "UpgradeableImpl",
    "interface_name": "openzeppelin_upgrades::interface::IUpgradeable"
  },
  {
    "type": "interface",
    "name": "openzeppelin_upgrades::interface::IUpgradeable",
    "items": [
      {
        "type": "function",
        "name": "upgrade",
        "inputs": [
          {
            "name": "new_class_hash",
            "type": "core::starknet::class_hash::ClassHash"
          }
        ],
        "outputs": [],
        "state_mutability": "external"
      }
    ]
  },
  {
    "type": "impl",
    "name": "ConfigImpl",
    "interface_name": "piltover::config::interface::IConfig"
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
    "type": "struct",
    "name": "piltover::config::interface::ProgramInfo",
    "members": [
      {
        "name": "bootloader_program_hash",
        "type": "core::felt252"
      },
      {
        "name": "snos_config_hash",
        "type": "core::felt252"
      },
      {
        "name": "snos_program_hash",
        "type": "core::felt252"
      },
      {
        "name": "layout_bridge_program_hash",
        "type": "core::felt252"
      }
    ]
  },
  {
    "type": "interface",
    "name": "piltover::config::interface::IConfig",
    "items": [
      {
        "type": "function",
        "name": "register_operator",
        "inputs": [
          {
            "name": "address",
            "type": "core::starknet::contract_address::ContractAddress"
          }
        ],
        "outputs": [],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "unregister_operator",
        "inputs": [
          {
            "name": "address",
            "type": "core::starknet::contract_address::ContractAddress"
          }
        ],
        "outputs": [],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "is_operator",
        "inputs": [
          {
            "name": "address",
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
        "name": "set_program_info",
        "inputs": [
          {
            "name": "program_info",
            "type": "piltover::config::interface::ProgramInfo"
          }
        ],
        "outputs": [],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "get_program_info",
        "inputs": [],
        "outputs": [
          {
            "type": "piltover::config::interface::ProgramInfo"
          }
        ],
        "state_mutability": "view"
      },
      {
        "type": "function",
        "name": "set_facts_registry",
        "inputs": [
          {
            "name": "address",
            "type": "core::starknet::contract_address::ContractAddress"
          }
        ],
        "outputs": [],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "get_facts_registry",
        "inputs": [],
        "outputs": [
          {
            "type": "core::starknet::contract_address::ContractAddress"
          }
        ],
        "state_mutability": "view"
      },
      {
        "type": "function",
        "name": "set_use_kzg_da",
        "inputs": [
          {
            "name": "use_kzg_da",
            "type": "core::bool"
          }
        ],
        "outputs": [],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "get_use_kzg_da",
        "inputs": [],
        "outputs": [
          {
            "type": "core::bool"
          }
        ],
        "state_mutability": "view"
      }
    ]
  },
  {
    "type": "impl",
    "name": "MessagingImpl",
    "interface_name": "piltover::messaging::interface::IMessaging"
  },
  {
    "type": "enum",
    "name": "piltover::messaging::types::MessageToAppchainStatus",
    "variants": [
      {
        "name": "NotSent",
        "type": "()"
      },
      {
        "name": "Sealed",
        "type": "()"
      },
      {
        "name": "Cancelled",
        "type": "()"
      },
      {
        "name": "Pending",
        "type": "core::felt252"
      },
      {
        "name": "Cancelling",
        "type": "()"
      }
    ]
  },
  {
    "type": "enum",
    "name": "piltover::messaging::types::MessageToStarknetStatus",
    "variants": [
      {
        "name": "NothingToConsume",
        "type": "()"
      },
      {
        "name": "ReadyToConsume",
        "type": "core::felt252"
      }
    ]
  },
  {
    "type": "interface",
    "name": "piltover::messaging::interface::IMessaging",
    "items": [
      {
        "type": "function",
        "name": "send_message_to_appchain",
        "inputs": [
          {
            "name": "to_address",
            "type": "core::starknet::contract_address::ContractAddress"
          },
          {
            "name": "selector",
            "type": "core::felt252"
          },
          {
            "name": "payload",
            "type": "core::array::Span::<core::felt252>"
          }
        ],
        "outputs": [
          {
            "type": "(core::felt252, core::felt252)"
          }
        ],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "consume_message_from_appchain",
        "inputs": [
          {
            "name": "from_address",
            "type": "core::starknet::contract_address::ContractAddress"
          },
          {
            "name": "payload",
            "type": "core::array::Span::<core::felt252>"
          }
        ],
        "outputs": [
          {
            "type": "core::felt252"
          }
        ],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "sn_to_appchain_messages",
        "inputs": [
          {
            "name": "message_hash",
            "type": "core::felt252"
          }
        ],
        "outputs": [
          {
            "type": "piltover::messaging::types::MessageToAppchainStatus"
          }
        ],
        "state_mutability": "view"
      },
      {
        "type": "function",
        "name": "appchain_to_sn_messages",
        "inputs": [
          {
            "name": "message_hash",
            "type": "core::felt252"
          }
        ],
        "outputs": [
          {
            "type": "piltover::messaging::types::MessageToStarknetStatus"
          }
        ],
        "state_mutability": "view"
      },
      {
        "type": "function",
        "name": "start_message_cancellation",
        "inputs": [
          {
            "name": "to_address",
            "type": "core::starknet::contract_address::ContractAddress"
          },
          {
            "name": "selector",
            "type": "core::felt252"
          },
          {
            "name": "payload",
            "type": "core::array::Span::<core::felt252>"
          },
          {
            "name": "nonce",
            "type": "core::felt252"
          }
        ],
        "outputs": [
          {
            "type": "core::felt252"
          }
        ],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "cancel_message",
        "inputs": [
          {
            "name": "to_address",
            "type": "core::starknet::contract_address::ContractAddress"
          },
          {
            "name": "selector",
            "type": "core::felt252"
          },
          {
            "name": "payload",
            "type": "core::array::Span::<core::felt252>"
          },
          {
            "name": "nonce",
            "type": "core::felt252"
          }
        ],
        "outputs": [
          {
            "type": "core::felt252"
          }
        ],
        "state_mutability": "external"
      }
    ]
  },
  {
    "type": "impl",
    "name": "StateImpl",
    "interface_name": "piltover::state::interface::IState"
  },
  {
    "type": "interface",
    "name": "piltover::state::interface::IState",
    "items": [
      {
        "type": "function",
        "name": "get_state",
        "inputs": [],
        "outputs": [
          {
            "type": "(core::felt252, core::felt252, core::felt252)"
          }
        ],
        "state_mutability": "view"
      }
    ]
  },
  {
    "type": "impl",
    "name": "OwnableImpl",
    "interface_name": "openzeppelin_access::ownable::interface::IOwnableTwoStep"
  },
  {
    "type": "interface",
    "name": "openzeppelin_access::ownable::interface::IOwnableTwoStep",
    "items": [
      {
        "type": "function",
        "name": "owner",
        "inputs": [],
        "outputs": [
          {
            "type": "core::starknet::contract_address::ContractAddress"
          }
        ],
        "state_mutability": "view"
      },
      {
        "type": "function",
        "name": "pending_owner",
        "inputs": [],
        "outputs": [
          {
            "type": "core::starknet::contract_address::ContractAddress"
          }
        ],
        "state_mutability": "view"
      },
      {
        "type": "function",
        "name": "accept_ownership",
        "inputs": [],
        "outputs": [],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "transfer_ownership",
        "inputs": [
          {
            "name": "new_owner",
            "type": "core::starknet::contract_address::ContractAddress"
          }
        ],
        "outputs": [],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "renounce_ownership",
        "inputs": [],
        "outputs": [],
        "state_mutability": "external"
      }
    ]
  },
  {
    "type": "constructor",
    "name": "constructor",
    "inputs": [
      {
        "name": "owner",
        "type": "core::starknet::contract_address::ContractAddress"
      },
      {
        "name": "state_root",
        "type": "core::felt252"
      },
      {
        "name": "block_number",
        "type": "core::felt252"
      },
      {
        "name": "block_hash",
        "type": "core::felt252"
      }
    ]
  },
  {
    "type": "function",
    "name": "set_state",
    "inputs": [
      {
        "name": "state_root",
        "type": "core::felt252"
      },
      {
        "name": "block_number",
        "type": "core::felt252"
      },
      {
        "name": "block_hash",
        "type": "core::felt252"
      }
    ],
    "outputs": [],
    "state_mutability": "external"
  },
  {
    "type": "event",
    "name": "openzeppelin_access::ownable::ownable::OwnableComponent::OwnershipTransferred",
    "kind": "struct",
    "members": [
      {
        "name": "previous_owner",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
      },
      {
        "name": "new_owner",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
      }
    ]
  },
  {
    "type": "event",
    "name": "openzeppelin_access::ownable::ownable::OwnableComponent::OwnershipTransferStarted",
    "kind": "struct",
    "members": [
      {
        "name": "previous_owner",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
      },
      {
        "name": "new_owner",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
      }
    ]
  },
  {
    "type": "event",
    "name": "openzeppelin_access::ownable::ownable::OwnableComponent::Event",
    "kind": "enum",
    "variants": [
      {
        "name": "OwnershipTransferred",
        "type": "openzeppelin_access::ownable::ownable::OwnableComponent::OwnershipTransferred",
        "kind": "nested"
      },
      {
        "name": "OwnershipTransferStarted",
        "type": "openzeppelin_access::ownable::ownable::OwnableComponent::OwnershipTransferStarted",
        "kind": "nested"
      }
    ]
  },
  {
    "type": "event",
    "name": "openzeppelin_upgrades::upgradeable::UpgradeableComponent::Upgraded",
    "kind": "struct",
    "members": [
      {
        "name": "class_hash",
        "type": "core::starknet::class_hash::ClassHash",
        "kind": "data"
      }
    ]
  },
  {
    "type": "event",
    "name": "openzeppelin_upgrades::upgradeable::UpgradeableComponent::Event",
    "kind": "enum",
    "variants": [
      {
        "name": "Upgraded",
        "type": "openzeppelin_upgrades::upgradeable::UpgradeableComponent::Upgraded",
        "kind": "nested"
      }
    ]
  },
  {
    "type": "event",
    "name": "piltover::config::component::config_cpt::ProgramInfoChanged",
    "kind": "struct",
    "members": [
      {
        "name": "changed_by",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "data"
      },
      {
        "name": "old_program_info",
        "type": "piltover::config::interface::ProgramInfo",
        "kind": "data"
      },
      {
        "name": "new_program_info",
        "type": "piltover::config::interface::ProgramInfo",
        "kind": "data"
      }
    ]
  },
  {
    "type": "event",
    "name": "piltover::config::component::config_cpt::Event",
    "kind": "enum",
    "variants": [
      {
        "name": "ProgramInfoChanged",
        "type": "piltover::config::component::config_cpt::ProgramInfoChanged",
        "kind": "nested"
      }
    ]
  },
  {
    "type": "event",
    "name": "piltover::messaging::component::messaging_cpt::MessageSent",
    "kind": "struct",
    "members": [
      {
        "name": "message_hash",
        "type": "core::felt252",
        "kind": "key"
      },
      {
        "name": "from",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
      },
      {
        "name": "to",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
      },
      {
        "name": "selector",
        "type": "core::felt252",
        "kind": "data"
      },
      {
        "name": "nonce",
        "type": "core::felt252",
        "kind": "data"
      },
      {
        "name": "payload",
        "type": "core::array::Span::<core::felt252>",
        "kind": "data"
      }
    ]
  },
  {
    "type": "event",
    "name": "piltover::messaging::component::messaging_cpt::MessageConsumed",
    "kind": "struct",
    "members": [
      {
        "name": "message_hash",
        "type": "core::felt252",
        "kind": "key"
      },
      {
        "name": "from",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
      },
      {
        "name": "to",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
      },
      {
        "name": "payload",
        "type": "core::array::Span::<core::felt252>",
        "kind": "data"
      }
    ]
  },
  {
    "type": "event",
    "name": "piltover::messaging::component::messaging_cpt::MessageCancellationStarted",
    "kind": "struct",
    "members": [
      {
        "name": "message_hash",
        "type": "core::felt252",
        "kind": "key"
      },
      {
        "name": "from",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
      },
      {
        "name": "to",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
      },
      {
        "name": "selector",
        "type": "core::felt252",
        "kind": "data"
      },
      {
        "name": "payload",
        "type": "core::array::Span::<core::felt252>",
        "kind": "data"
      },
      {
        "name": "nonce",
        "type": "core::felt252",
        "kind": "data"
      }
    ]
  },
  {
    "type": "event",
    "name": "piltover::messaging::component::messaging_cpt::MessageCanceled",
    "kind": "struct",
    "members": [
      {
        "name": "message_hash",
        "type": "core::felt252",
        "kind": "key"
      },
      {
        "name": "from",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
      },
      {
        "name": "to",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
      },
      {
        "name": "selector",
        "type": "core::felt252",
        "kind": "data"
      },
      {
        "name": "payload",
        "type": "core::array::Span::<core::felt252>",
        "kind": "data"
      },
      {
        "name": "nonce",
        "type": "core::felt252",
        "kind": "data"
      }
    ]
  },
  {
    "type": "event",
    "name": "piltover::messaging::component::messaging_cpt::MessageToStarknetReceived",
    "kind": "struct",
    "members": [
      {
        "name": "message_hash",
        "type": "core::felt252",
        "kind": "key"
      },
      {
        "name": "from",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
      },
      {
        "name": "to",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
      },
      {
        "name": "payload",
        "type": "core::array::Span::<core::felt252>",
        "kind": "data"
      }
    ]
  },
  {
    "type": "event",
    "name": "piltover::messaging::component::messaging_cpt::MessageToAppchainSealed",
    "kind": "struct",
    "members": [
      {
        "name": "message_hash",
        "type": "core::felt252",
        "kind": "key"
      },
      {
        "name": "from",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
      },
      {
        "name": "to",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
      },
      {
        "name": "selector",
        "type": "core::felt252",
        "kind": "data"
      },
      {
        "name": "nonce",
        "type": "core::felt252",
        "kind": "data"
      },
      {
        "name": "payload",
        "type": "core::array::Span::<core::felt252>",
        "kind": "data"
      }
    ]
  },
  {
    "type": "event",
    "name": "piltover::messaging::component::messaging_cpt::Event",
    "kind": "enum",
    "variants": [
      {
        "name": "MessageSent",
        "type": "piltover::messaging::component::messaging_cpt::MessageSent",
        "kind": "nested"
      },
      {
        "name": "MessageConsumed",
        "type": "piltover::messaging::component::messaging_cpt::MessageConsumed",
        "kind": "nested"
      },
      {
        "name": "MessageCancellationStarted",
        "type": "piltover::messaging::component::messaging_cpt::MessageCancellationStarted",
        "kind": "nested"
      },
      {
        "name": "MessageCanceled",
        "type": "piltover::messaging::component::messaging_cpt::MessageCanceled",
        "kind": "nested"
      },
      {
        "name": "MessageToStarknetReceived",
        "type": "piltover::messaging::component::messaging_cpt::MessageToStarknetReceived",
        "kind": "nested"
      },
      {
        "name": "MessageToAppchainSealed",
        "type": "piltover::messaging::component::messaging_cpt::MessageToAppchainSealed",
        "kind": "nested"
      }
    ]
  },
  {
    "type": "event",
    "name": "openzeppelin_security::reentrancyguard::ReentrancyGuardComponent::Event",
    "kind": "enum",
    "variants": []
  },
  {
    "type": "event",
    "name": "piltover::state::component::state_cpt::Event",
    "kind": "enum",
    "variants": []
  },
  {
    "type": "event",
    "name": "piltover::appchain::appchain::LogStateUpdate",
    "kind": "struct",
    "members": [
      {
        "name": "state_root",
        "type": "core::felt252",
        "kind": "data"
      },
      {
        "name": "block_number",
        "type": "core::felt252",
        "kind": "data"
      },
      {
        "name": "block_hash",
        "type": "core::felt252",
        "kind": "data"
      }
    ]
  },
  {
    "type": "struct",
    "name": "core::integer::u256",
    "members": [
      {
        "name": "low",
        "type": "core::integer::u128"
      },
      {
        "name": "high",
        "type": "core::integer::u128"
      }
    ]
  },
  {
    "type": "event",
    "name": "piltover::appchain::appchain::LogStateTransitionFact",
    "kind": "struct",
    "members": [
      {
        "name": "state_transition_fact",
        "type": "core::integer::u256",
        "kind": "data"
      }
    ]
  },
  {
    "type": "event",
    "name": "piltover::appchain::appchain::Event",
    "kind": "enum",
    "variants": [
      {
        "name": "OwnableEvent",
        "type": "openzeppelin_access::ownable::ownable::OwnableComponent::Event",
        "kind": "flat"
      },
      {
        "name": "UpgradeableEvent",
        "type": "openzeppelin_upgrades::upgradeable::UpgradeableComponent::Event",
        "kind": "flat"
      },
      {
        "name": "ConfigEvent",
        "type": "piltover::config::component::config_cpt::Event",
        "kind": "flat"
      },
      {
        "name": "MessagingEvent",
        "type": "piltover::messaging::component::messaging_cpt::Event",
        "kind": "flat"
      },
      {
        "name": "ReentrancyGuardEvent",
        "type": "openzeppelin_security::reentrancyguard::ReentrancyGuardComponent::Event",
        "kind": "flat"
      },
      {
        "name": "StateEvent",
        "type": "piltover::state::component::state_cpt::Event",
        "kind": "flat"
      },
      {
        "name": "LogStateUpdate",
        "type": "piltover::appchain::appchain::LogStateUpdate",
        "kind": "nested"
      },
      {
        "name": "LogStateTransitionFact",
        "type": "piltover::appchain::appchain::LogStateTransitionFact",
        "kind": "nested"
      }
    ]
  }
] as const;
