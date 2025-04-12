pub mod bridge {
    pub mod interface;
    pub mod token_bridge;
    pub mod types;

    #[cfg(target: 'test')]
    pub mod tests {
        pub mod constants;
        mod messaging_test;
        mod token_actions_test;
        pub mod utils {
            pub mod message_payloads;
            pub mod setup;
        }
    }
    pub use interface::{
        ITokenBridge, ITokenBridgeAdmin, ITokenBridgeAdminDispatcher,
        ITokenBridgeAdminDispatcherTrait, ITokenBridgeDispatcher, ITokenBridgeDispatcherTrait,
    };

    pub use token_bridge::TokenBridge;
}

pub mod withdrawal_limit {
    pub mod component;
    pub mod interface;

    #[cfg(test)]
    mod tests {
        mod withdrawal_limit_test;
    }
}

pub mod access_control {
    pub mod component;
    pub mod roles;

    #[cfg(test)]
    pub mod tests {
        mod access_control_test;
        mod utils;
    }
}

pub mod timelock {
    pub mod timelock;
}

pub mod constants;

pub mod mocks {
    #[cfg(test)]
    pub mod access_control_mock;
    pub mod erc20;

    #[cfg(target: 'test')]
    pub mod hash;

    #[cfg(target: 'test')]
    pub mod messaging;

    #[cfg(test)]
    pub mod messaging_malicious;

    #[cfg(test)]
    pub mod withdrawal_limit_mock;
}

