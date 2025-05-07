export const ABI = [
  {
    "type": "impl",
    "name": "TokenBrdigeAdminImpl",
    "interface_name": "starknet_bridge::bridge::interface::ITokenBridgeAdmin"
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
    "type": "interface",
    "name": "starknet_bridge::bridge::interface::ITokenBridgeAdmin",
    "items": [
      {
        "type": "function",
        "name": "set_appchain_token_bridge",
        "inputs": [
          {
            "name": "appchain_bridge",
            "type": "core::starknet::contract_address::ContractAddress"
          }
        ],
        "outputs": [],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "block_token",
        "inputs": [
          {
            "name": "token",
            "type": "core::starknet::contract_address::ContractAddress"
          }
        ],
        "outputs": [],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "unblock_token",
        "inputs": [
          {
            "name": "token",
            "type": "core::starknet::contract_address::ContractAddress"
          }
        ],
        "outputs": [],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "deactivate_token",
        "inputs": [
          {
            "name": "token",
            "type": "core::starknet::contract_address::ContractAddress"
          }
        ],
        "outputs": [],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "reactivate_token",
        "inputs": [
          {
            "name": "token",
            "type": "core::starknet::contract_address::ContractAddress"
          }
        ],
        "outputs": [],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "configure_permissionless_enrollment",
        "inputs": [
          {
            "name": "permissioned_enroll",
            "type": "core::bool"
          }
        ],
        "outputs": [],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "increase_withdrawal_limit",
        "inputs": [
          {
            "name": "token",
            "type": "core::starknet::contract_address::ContractAddress"
          },
          {
            "name": "daily_withdrawal_limit_pct",
            "type": "core::integer::u8"
          }
        ],
        "outputs": [],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "decrease_withdrawal_limit",
        "inputs": [
          {
            "name": "token",
            "type": "core::starknet::contract_address::ContractAddress"
          },
          {
            "name": "daily_withdrawal_limit_pct",
            "type": "core::integer::u8"
          }
        ],
        "outputs": [],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "disable_withdrawal_limit",
        "inputs": [
          {
            "name": "token",
            "type": "core::starknet::contract_address::ContractAddress"
          }
        ],
        "outputs": [],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "set_max_total_balance",
        "inputs": [
          {
            "name": "token",
            "type": "core::starknet::contract_address::ContractAddress"
          },
          {
            "name": "max_total_balance",
            "type": "core::integer::u256"
          }
        ],
        "outputs": [],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "pause",
        "inputs": [],
        "outputs": [],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "unpause",
        "inputs": [],
        "outputs": [],
        "state_mutability": "external"
      }
    ]
  },
  {
    "type": "impl",
    "name": "TokenBridgeImpl",
    "interface_name": "starknet_bridge::bridge::interface::ITokenBridge"
  },
  {
    "type": "enum",
    "name": "starknet_bridge::bridge::types::TokenStatus",
    "variants": [
      {
        "name": "Unknown",
        "type": "()"
      },
      {
        "name": "Pending",
        "type": "()"
      },
      {
        "name": "Active",
        "type": "()"
      },
      {
        "name": "Blocked",
        "type": "()"
      },
      {
        "name": "Deactivated",
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
    "type": "interface",
    "name": "starknet_bridge::bridge::interface::ITokenBridge",
    "items": [
      {
        "type": "function",
        "name": "appchain_bridge",
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
        "name": "get_identity",
        "inputs": [],
        "outputs": [
          {
            "type": "core::felt252"
          }
        ],
        "state_mutability": "view"
      },
      {
        "type": "function",
        "name": "get_version",
        "inputs": [],
        "outputs": [
          {
            "type": "core::felt252"
          }
        ],
        "state_mutability": "view"
      },
      {
        "type": "function",
        "name": "get_status",
        "inputs": [
          {
            "name": "token",
            "type": "core::starknet::contract_address::ContractAddress"
          }
        ],
        "outputs": [
          {
            "type": "starknet_bridge::bridge::types::TokenStatus"
          }
        ],
        "state_mutability": "view"
      },
      {
        "type": "function",
        "name": "is_servicing_token",
        "inputs": [
          {
            "name": "token",
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
        "name": "is_enrollment_permissionless",
        "inputs": [],
        "outputs": [
          {
            "type": "core::bool"
          }
        ],
        "state_mutability": "view"
      },
      {
        "type": "function",
        "name": "enroll_token",
        "inputs": [
          {
            "name": "token",
            "type": "core::starknet::contract_address::ContractAddress"
          }
        ],
        "outputs": [],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "check_deployment_status",
        "inputs": [
          {
            "name": "token",
            "type": "core::starknet::contract_address::ContractAddress"
          }
        ],
        "outputs": [],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "deposit",
        "inputs": [
          {
            "name": "token",
            "type": "core::starknet::contract_address::ContractAddress"
          },
          {
            "name": "amount",
            "type": "core::integer::u256"
          },
          {
            "name": "appchain_recipient",
            "type": "core::starknet::contract_address::ContractAddress"
          }
        ],
        "outputs": [],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "deposit_with_message",
        "inputs": [
          {
            "name": "token",
            "type": "core::starknet::contract_address::ContractAddress"
          },
          {
            "name": "amount",
            "type": "core::integer::u256"
          },
          {
            "name": "appchain_recipient",
            "type": "core::starknet::contract_address::ContractAddress"
          },
          {
            "name": "message",
            "type": "core::array::Span::<core::felt252>"
          }
        ],
        "outputs": [],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "withdraw",
        "inputs": [
          {
            "name": "token",
            "type": "core::starknet::contract_address::ContractAddress"
          },
          {
            "name": "amount",
            "type": "core::integer::u256"
          },
          {
            "name": "recipient",
            "type": "core::starknet::contract_address::ContractAddress"
          }
        ],
        "outputs": [],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "deposit_cancel_request",
        "inputs": [
          {
            "name": "token",
            "type": "core::starknet::contract_address::ContractAddress"
          },
          {
            "name": "amount",
            "type": "core::integer::u256"
          },
          {
            "name": "appchain_recipient",
            "type": "core::starknet::contract_address::ContractAddress"
          },
          {
            "name": "nonce",
            "type": "core::felt252"
          }
        ],
        "outputs": [],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "deposit_with_message_cancel_request",
        "inputs": [
          {
            "name": "token",
            "type": "core::starknet::contract_address::ContractAddress"
          },
          {
            "name": "amount",
            "type": "core::integer::u256"
          },
          {
            "name": "appchain_recipient",
            "type": "core::starknet::contract_address::ContractAddress"
          },
          {
            "name": "message",
            "type": "core::array::Span::<core::felt252>"
          },
          {
            "name": "nonce",
            "type": "core::felt252"
          }
        ],
        "outputs": [],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "deposit_with_message_reclaim",
        "inputs": [
          {
            "name": "token",
            "type": "core::starknet::contract_address::ContractAddress"
          },
          {
            "name": "amount",
            "type": "core::integer::u256"
          },
          {
            "name": "appchain_recipient",
            "type": "core::starknet::contract_address::ContractAddress"
          },
          {
            "name": "message",
            "type": "core::array::Span::<core::felt252>"
          },
          {
            "name": "nonce",
            "type": "core::felt252"
          }
        ],
        "outputs": [],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "deposit_reclaim",
        "inputs": [
          {
            "name": "token",
            "type": "core::starknet::contract_address::ContractAddress"
          },
          {
            "name": "amount",
            "type": "core::integer::u256"
          },
          {
            "name": "appchain_recipient",
            "type": "core::starknet::contract_address::ContractAddress"
          },
          {
            "name": "nonce",
            "type": "core::felt252"
          }
        ],
        "outputs": [],
        "state_mutability": "external"
      },
      {
        "type": "function",
        "name": "get_max_total_balance",
        "inputs": [
          {
            "name": "token",
            "type": "core::starknet::contract_address::ContractAddress"
          }
        ],
        "outputs": [
          {
            "type": "core::integer::u256"
          }
        ],
        "state_mutability": "view"
      },
      {
        "type": "function",
        "name": "get_appchain_token_bridge",
        "inputs": [],
        "outputs": [
          {
            "type": "core::starknet::contract_address::ContractAddress"
          }
        ],
        "state_mutability": "view"
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
    "name": "BridgeAccessControlImpl",
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
    "type": "impl",
    "name": "PausableImpl",
    "interface_name": "openzeppelin_security::interface::IPausable"
  },
  {
    "type": "interface",
    "name": "openzeppelin_security::interface::IPausable",
    "items": [
      {
        "type": "function",
        "name": "is_paused",
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
    "name": "WithdrawalLimitImpl",
    "interface_name": "starknet_bridge::withdrawal_limit::interface::IWithdrawalLimit"
  },
  {
    "type": "interface",
    "name": "starknet_bridge::withdrawal_limit::interface::IWithdrawalLimit",
    "items": [
      {
        "type": "function",
        "name": "get_remaining_withdrawal_quota",
        "inputs": [
          {
            "name": "token",
            "type": "core::starknet::contract_address::ContractAddress"
          }
        ],
        "outputs": [
          {
            "type": "core::integer::u256"
          }
        ],
        "state_mutability": "view"
      },
      {
        "type": "function",
        "name": "is_withdrawal_limit_applied",
        "inputs": [
          {
            "name": "token",
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
        "name": "get_daily_withdrawal_limit_pct",
        "inputs": [
          {
            "name": "token",
            "type": "core::starknet::contract_address::ContractAddress"
          }
        ],
        "outputs": [
          {
            "type": "core::integer::u8"
          }
        ],
        "state_mutability": "view"
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
        "name": "appchain_bridge",
        "type": "core::starknet::contract_address::ContractAddress"
      },
      {
        "name": "messaging_contract",
        "type": "core::starknet::contract_address::ContractAddress"
      },
      {
        "name": "governance_admins",
        "type": "core::array::Span::<core::starknet::contract_address::ContractAddress>"
      },
      {
        "name": "app_governors",
        "type": "core::array::Span::<core::starknet::contract_address::ContractAddress>"
      },
      {
        "name": "security_admins",
        "type": "core::array::Span::<core::starknet::contract_address::ContractAddress>"
      },
      {
        "name": "security_agents",
        "type": "core::array::Span::<core::starknet::contract_address::ContractAddress>"
      },
      {
        "name": "token_admins",
        "type": "core::array::Span::<core::starknet::contract_address::ContractAddress>"
      },
      {
        "name": "timelock",
        "type": "core::starknet::contract_address::ContractAddress"
      }
    ]
  },
  {
    "type": "event",
    "name": "starknet_bridge::bridge::token_bridge::TokenBridge::TokenEnrollmentInitiated",
    "kind": "struct",
    "members": [
      {
        "name": "token",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "data"
      },
      {
        "name": "deployment_message_hash",
        "type": "core::felt252",
        "kind": "data"
      }
    ]
  },
  {
    "type": "event",
    "name": "starknet_bridge::bridge::token_bridge::TokenBridge::TokenActivated",
    "kind": "struct",
    "members": [
      {
        "name": "token",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "data"
      }
    ]
  },
  {
    "type": "event",
    "name": "starknet_bridge::bridge::token_bridge::TokenBridge::TokenDeactivated",
    "kind": "struct",
    "members": [
      {
        "name": "token",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "data"
      }
    ]
  },
  {
    "type": "event",
    "name": "starknet_bridge::bridge::token_bridge::TokenBridge::TokenBlocked",
    "kind": "struct",
    "members": [
      {
        "name": "token",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "data"
      }
    ]
  },
  {
    "type": "event",
    "name": "starknet_bridge::bridge::token_bridge::TokenBridge::TokenReactivated",
    "kind": "struct",
    "members": [
      {
        "name": "token",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "data"
      }
    ]
  },
  {
    "type": "event",
    "name": "starknet_bridge::bridge::token_bridge::TokenBridge::TokenUnblocked",
    "kind": "struct",
    "members": [
      {
        "name": "token",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "data"
      }
    ]
  },
  {
    "type": "event",
    "name": "starknet_bridge::bridge::token_bridge::TokenBridge::Deposit",
    "kind": "struct",
    "members": [
      {
        "name": "sender",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
      },
      {
        "name": "token",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
      },
      {
        "name": "amount",
        "type": "core::integer::u256",
        "kind": "data"
      },
      {
        "name": "appchain_recipient",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
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
    "name": "starknet_bridge::bridge::token_bridge::TokenBridge::DepositWithMessage",
    "kind": "struct",
    "members": [
      {
        "name": "sender",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
      },
      {
        "name": "token",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
      },
      {
        "name": "amount",
        "type": "core::integer::u256",
        "kind": "data"
      },
      {
        "name": "appchain_recipient",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
      },
      {
        "name": "message",
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
    "name": "starknet_bridge::bridge::token_bridge::TokenBridge::DepositCancelRequest",
    "kind": "struct",
    "members": [
      {
        "name": "sender",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
      },
      {
        "name": "token",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
      },
      {
        "name": "amount",
        "type": "core::integer::u256",
        "kind": "data"
      },
      {
        "name": "appchain_recipient",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
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
    "name": "starknet_bridge::bridge::token_bridge::TokenBridge::DepositWithMessageCancelRequest",
    "kind": "struct",
    "members": [
      {
        "name": "sender",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
      },
      {
        "name": "token",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
      },
      {
        "name": "amount",
        "type": "core::integer::u256",
        "kind": "data"
      },
      {
        "name": "appchain_recipient",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
      },
      {
        "name": "message",
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
    "name": "starknet_bridge::bridge::token_bridge::TokenBridge::DepositReclaimed",
    "kind": "struct",
    "members": [
      {
        "name": "sender",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
      },
      {
        "name": "token",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
      },
      {
        "name": "amount",
        "type": "core::integer::u256",
        "kind": "data"
      },
      {
        "name": "appchain_recipient",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
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
    "name": "starknet_bridge::bridge::token_bridge::TokenBridge::DepositWithMessageReclaimed",
    "kind": "struct",
    "members": [
      {
        "name": "sender",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
      },
      {
        "name": "token",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
      },
      {
        "name": "amount",
        "type": "core::integer::u256",
        "kind": "data"
      },
      {
        "name": "appchain_recipient",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
      },
      {
        "name": "message",
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
    "name": "starknet_bridge::bridge::token_bridge::TokenBridge::Withdrawal",
    "kind": "struct",
    "members": [
      {
        "name": "recipient",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
      },
      {
        "name": "token",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
      },
      {
        "name": "amount",
        "type": "core::integer::u256",
        "kind": "data"
      }
    ]
  },
  {
    "type": "event",
    "name": "starknet_bridge::bridge::token_bridge::TokenBridge::WithdrawalLimitIncreased",
    "kind": "struct",
    "members": [
      {
        "name": "sender",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
      },
      {
        "name": "token",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
      },
      {
        "name": "daily_withdrawal_limit_pct",
        "type": "core::integer::u8",
        "kind": "data"
      }
    ]
  },
  {
    "type": "event",
    "name": "starknet_bridge::bridge::token_bridge::TokenBridge::WithdrawalLimitDecreased",
    "kind": "struct",
    "members": [
      {
        "name": "sender",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
      },
      {
        "name": "token",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
      },
      {
        "name": "daily_withdrawal_limit_pct",
        "type": "core::integer::u8",
        "kind": "data"
      }
    ]
  },
  {
    "type": "event",
    "name": "starknet_bridge::bridge::token_bridge::TokenBridge::SetMaxTotalBalance",
    "kind": "struct",
    "members": [
      {
        "name": "token",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "key"
      },
      {
        "name": "value",
        "type": "core::integer::u256",
        "kind": "data"
      }
    ]
  },
  {
    "type": "event",
    "name": "starknet_bridge::bridge::token_bridge::TokenBridge::SetAppchainBridge",
    "kind": "struct",
    "members": [
      {
        "name": "appchain_bridge",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "data"
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
    "name": "starknet_bridge::withdrawal_limit::component::WithdrawalLimitComponent::RemainingQuotaUpdated",
    "kind": "struct",
    "members": [
      {
        "name": "token",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "data"
      },
      {
        "name": "day",
        "type": "core::integer::u64",
        "kind": "data"
      },
      {
        "name": "new_quota",
        "type": "core::integer::u256",
        "kind": "data"
      }
    ]
  },
  {
    "type": "event",
    "name": "starknet_bridge::withdrawal_limit::component::WithdrawalLimitComponent::DailyWithdrawalPercentageUpdated",
    "kind": "struct",
    "members": [
      {
        "name": "new_percentage",
        "type": "core::integer::u8",
        "kind": "data"
      }
    ]
  },
  {
    "type": "event",
    "name": "starknet_bridge::withdrawal_limit::component::WithdrawalLimitComponent::Event",
    "kind": "enum",
    "variants": [
      {
        "name": "RemainingQuotaUpdated",
        "type": "starknet_bridge::withdrawal_limit::component::WithdrawalLimitComponent::RemainingQuotaUpdated",
        "kind": "nested"
      },
      {
        "name": "DailyWithdrawalPercentageUpdated",
        "type": "starknet_bridge::withdrawal_limit::component::WithdrawalLimitComponent::DailyWithdrawalPercentageUpdated",
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
    "name": "starknet_bridge::access_control::component::BridgeAccessControlComponent::Event",
    "kind": "enum",
    "variants": []
  },
  {
    "type": "event",
    "name": "openzeppelin_security::pausable::PausableComponent::Paused",
    "kind": "struct",
    "members": [
      {
        "name": "account",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "data"
      }
    ]
  },
  {
    "type": "event",
    "name": "openzeppelin_security::pausable::PausableComponent::Unpaused",
    "kind": "struct",
    "members": [
      {
        "name": "account",
        "type": "core::starknet::contract_address::ContractAddress",
        "kind": "data"
      }
    ]
  },
  {
    "type": "event",
    "name": "openzeppelin_security::pausable::PausableComponent::Event",
    "kind": "enum",
    "variants": [
      {
        "name": "Paused",
        "type": "openzeppelin_security::pausable::PausableComponent::Paused",
        "kind": "nested"
      },
      {
        "name": "Unpaused",
        "type": "openzeppelin_security::pausable::PausableComponent::Unpaused",
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
    "name": "starknet_bridge::bridge::token_bridge::TokenBridge::Event",
    "kind": "enum",
    "variants": [
      {
        "name": "TokenEnrollmentInitiated",
        "type": "starknet_bridge::bridge::token_bridge::TokenBridge::TokenEnrollmentInitiated",
        "kind": "nested"
      },
      {
        "name": "TokenActivated",
        "type": "starknet_bridge::bridge::token_bridge::TokenBridge::TokenActivated",
        "kind": "nested"
      },
      {
        "name": "TokenDeactivated",
        "type": "starknet_bridge::bridge::token_bridge::TokenBridge::TokenDeactivated",
        "kind": "nested"
      },
      {
        "name": "TokenBlocked",
        "type": "starknet_bridge::bridge::token_bridge::TokenBridge::TokenBlocked",
        "kind": "nested"
      },
      {
        "name": "TokenReactivated",
        "type": "starknet_bridge::bridge::token_bridge::TokenBridge::TokenReactivated",
        "kind": "nested"
      },
      {
        "name": "TokenUnblocked",
        "type": "starknet_bridge::bridge::token_bridge::TokenBridge::TokenUnblocked",
        "kind": "nested"
      },
      {
        "name": "Deposit",
        "type": "starknet_bridge::bridge::token_bridge::TokenBridge::Deposit",
        "kind": "nested"
      },
      {
        "name": "DepositWithMessage",
        "type": "starknet_bridge::bridge::token_bridge::TokenBridge::DepositWithMessage",
        "kind": "nested"
      },
      {
        "name": "DepostiCancelRequest",
        "type": "starknet_bridge::bridge::token_bridge::TokenBridge::DepositCancelRequest",
        "kind": "nested"
      },
      {
        "name": "DepositWithMessageCancelRequest",
        "type": "starknet_bridge::bridge::token_bridge::TokenBridge::DepositWithMessageCancelRequest",
        "kind": "nested"
      },
      {
        "name": "DepositReclaimed",
        "type": "starknet_bridge::bridge::token_bridge::TokenBridge::DepositReclaimed",
        "kind": "nested"
      },
      {
        "name": "DepositWithMessageReclaimed",
        "type": "starknet_bridge::bridge::token_bridge::TokenBridge::DepositWithMessageReclaimed",
        "kind": "nested"
      },
      {
        "name": "Withdrawal",
        "type": "starknet_bridge::bridge::token_bridge::TokenBridge::Withdrawal",
        "kind": "nested"
      },
      {
        "name": "WithdrawalLimitIncreased",
        "type": "starknet_bridge::bridge::token_bridge::TokenBridge::WithdrawalLimitIncreased",
        "kind": "nested"
      },
      {
        "name": "WithdrawalLimitDecreased",
        "type": "starknet_bridge::bridge::token_bridge::TokenBridge::WithdrawalLimitDecreased",
        "kind": "nested"
      },
      {
        "name": "SetMaxTotalBalance",
        "type": "starknet_bridge::bridge::token_bridge::TokenBridge::SetMaxTotalBalance",
        "kind": "nested"
      },
      {
        "name": "SetAppchainBridge",
        "type": "starknet_bridge::bridge::token_bridge::TokenBridge::SetAppchainBridge",
        "kind": "nested"
      },
      {
        "name": "UpgradeableEvent",
        "type": "openzeppelin_upgrades::upgradeable::UpgradeableComponent::Event",
        "kind": "flat"
      },
      {
        "name": "WithdrawalEvent",
        "type": "starknet_bridge::withdrawal_limit::component::WithdrawalLimitComponent::Event",
        "kind": "flat"
      },
      {
        "name": "ReentrancyGuardEvent",
        "type": "openzeppelin_security::reentrancyguard::ReentrancyGuardComponent::Event",
        "kind": "flat"
      },
      {
        "name": "AccessControlEvent",
        "type": "openzeppelin_access::accesscontrol::accesscontrol::AccessControlComponent::Event",
        "kind": "flat"
      },
      {
        "name": "BridgeAccessControlEvent",
        "type": "starknet_bridge::access_control::component::BridgeAccessControlComponent::Event",
        "kind": "flat"
      },
      {
        "name": "PausableEvent",
        "type": "openzeppelin_security::pausable::PausableComponent::Event",
        "kind": "flat"
      },
      {
        "name": "SRC5Event",
        "type": "openzeppelin_introspection::src5::SRC5Component::Event",
        "kind": "flat"
      }
    ]
  }
] as const;
