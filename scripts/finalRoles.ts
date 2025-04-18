import { FinalRoles, TimelockControllerRoleIds } from './types';

export const finalRoles: FinalRoles = {
    l2: {
        TokenBridge: {
            TOKEN_ADMIN: [
                "0xabcdf"
            ],
            SECURITY_AGENT: [
                "0xabcdf"
            ],
            APP_GOVERNOR: [
                "0xabcdf"
            ],
            SECURITY_ADMIN: [
                "0xabcdf"
            ],
            GOVERNANCE_ADMIN: [
                "0xabcdf"
            ]
        },
        TimelockController_starknet_bridge: {
            PROPOSER_ROLE: [
                "0xabcdf"
            ],
            EXECUTOR_ROLE: [
                "0xabcdf"
            ],
            CANCELLER_ROLE: [
                "0xabcdf"
            ],
            [TimelockControllerRoleIds.DEFAULT_ADMIN]: "0xabcdf"
        },
        appchain: {
            owner: "0xabcdf",
            operators: [
                "0xabcdf"
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