import { FinalRoles, TimelockControllerRoleIds } from './types';

export const finalRoles: FinalRoles = {
    l2: {
        TokenBridge: {
            TOKEN_ADMIN: [
            "0x015465662A637494E435CF06F7A73E690b149EC1e19FC7fA9A533bfd868581E6"
            ],
            SECURITY_AGENT: [
                "0x015465662A637494E435CF06F7A73E690b149EC1e19FC7fA9A533bfd868581E6"
            ],
            APP_GOVERNOR: [
                "0x015465662A637494E435CF06F7A73E690b149EC1e19FC7fA9A533bfd868581E6"
            ],
            SECURITY_ADMIN: [
                "0x015465662A637494E435CF06F7A73E690b149EC1e19FC7fA9A533bfd868581E6"
            ],
            GOVERNANCE_ADMIN: [
                "0x015465662A637494E435CF06F7A73E690b149EC1e19FC7fA9A533bfd868581E6"
            ]
        },
        TimelockController_starknet_bridge: {
            PROPOSER_ROLE: [
                "0x015465662A637494E435CF06F7A73E690b149EC1e19FC7fA9A533bfd868581E6"
            ],
            EXECUTOR_ROLE: [
                "0x015465662A637494E435CF06F7A73E690b149EC1e19FC7fA9A533bfd868581E6"
            ],
            CANCELLER_ROLE: [
                "0x015465662A637494E435CF06F7A73E690b149EC1e19FC7fA9A533bfd868581E6"
            ],
            [TimelockControllerRoleIds.DEFAULT_ADMIN]: "0x015465662A637494E435CF06F7A73E690b149EC1e19FC7fA9A533bfd868581E6"
        },
        appchain: {
            owner: "0x06dBC7e4e075aD5c5F9aCa6fAa7765A06541e20C862Be997b8E8AA3C8C53FD57",
            operators: [
                "0x06dBC7e4e075aD5c5F9aCa6fAa7765A06541e20C862Be997b8E8AA3C8C53FD57"
            ]
        }
    },
    l3: {
        TokenBridge: {
            GovernanceAdmin: [
                "0xabcdf"
            ],
            AppRoleAdmin: [
                "0xabcdf"
            ], 
            AppGovernor: [
                "0xabcdf"
            ], 
            Operator: [
                "0xabcdf"
            ],
            TokenAdmin: [
                "0xabcdf"
            ],
            UpgradeGovernor: [
                "0xabcdf"
            ],
            SecurityAdmin: [
                "0xabcdf"
            ],
            SecurityAgent: [
                "0xabcdf"
            ],
            L2TokenGovernance: "0xabcdf"
        }
    }
}; 