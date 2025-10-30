// SPDX-License-Identifier: MIT
///
/// This is a mock ERC20 contract to be used only in test cases.
/// Unlike the current OpenZeppelin recommendation, this contract returns
/// name and symbol as felt252 instead of ByteArray.
/// Some tokens on Starknet mainnet still use felt252 for name and symbol,
/// so testing with this format is required for compatibility.

// 💀💀💀💀💀💀💀💀💀💀💀💀💀💀
// ! Not to be used in mainnet
// 💀💀💀💀💀💀💀💀💀💀💀💀💀💀

#[starknet::contract]
pub mod ERC20_FELT_NAME_SYMBOL {
    use starknet::ContractAddress;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        name: felt252,
        symbol: felt252,
        decimals: u8,
        initial_supply: u256,
        initial_recipient: ContractAddress,
        permitted_minter: ContractAddress,
        l2_token_governance: ContractAddress,
        upgrade_delay: u64,
    }

    const DECIMALS: u256 = 1000000000000000000;

    /// Sets the token `name` and `symbol`.

    #[constructor]
    fn constructor(
        ref self: ContractState,
        name: felt252,
        symbol: felt252,
        decimals: u8,
        initial_supply: u256,
        initial_recipient: ContractAddress,
        permitted_minter: ContractAddress,
        l2_token_governance: ContractAddress,
        upgrade_delay: u64,
    ) {
        self.name.write(name);
        self.symbol.write(symbol);
        self.decimals.write(decimals);
    }

    #[external(v0)]
    fn name(ref self: ContractState) -> felt252 {
        self.name.read()
    }

    #[external(v0)]
    fn symbol(ref self: ContractState) -> felt252 {
        self.symbol.read()
    }

    #[external(v0)]
    fn decimals(ref self: ContractState) -> u8 {
        self.decimals.read()
    }
}
