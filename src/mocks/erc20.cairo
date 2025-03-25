// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts for Cairo v0.8.1 (presets/erc20.cairo)

/// # ERC20 Preset
///
/// The ERC20 contract offers basic functionality and provides a
/// fixed-supply mechanism for token distribution. The fixed supply is
/// set in the constructor.

// 💀💀💀💀💀💀💀💀💀💀💀💀💀💀
// ! Not to be used in mainnet
// 💀💀💀💀💀💀💀💀💀💀💀💀💀💀

#[starknet::contract]
pub mod ERC20 {
    use openzeppelin::token::erc20::{ERC20Component, ERC20HooksEmptyImpl};
    use starknet::ContractAddress;

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);

    #[abi(embed_v0)]
    impl ERC20Impl = ERC20Component::ERC20Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC20MetadataImpl = ERC20Component::ERC20MetadataImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC20CamelOnlyImpl = ERC20Component::ERC20CamelOnlyImpl<ContractState>;

    impl InternalImpl = ERC20Component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event,
    }

    const DECIMALS: u256 = 1000000000000000000;

    /// Sets the token `name` and `symbol`.
    /// Mints `fixed_supply` tokens to `recipient`.
    #[constructor]
    fn constructor(
        ref self: ContractState,
        name: ByteArray,
        symbol: ByteArray,
        decimals: u8,
        initial_supply: u256,
        initial_recipient: ContractAddress,
        permitted_minter: ContractAddress,
        l2_token_governance: ContractAddress,
        upgrade_delay: u64,
    ) {
        self.erc20.initializer(name, symbol);
        self.erc20.mint(initial_recipient, initial_supply);
    }


    #[generate_trait]
    #[abi(per_item)]
    impl IERC20Impl of IERC20Trait {
        #[external(v0)]
        fn permissioned_mint(ref self: ContractState, recipient: ContractAddress, amount: u256) {
            assert(amount < 100 * DECIMALS, 'Max 100 tokens only.');
            self.erc20.mint(recipient, amount);
        }


        #[external(v0)]
        fn permissioned_burn(ref self: ContractState, account: ContractAddress, amount: u256) {
            self.erc20.burn(account, amount);
        }
    }
}
