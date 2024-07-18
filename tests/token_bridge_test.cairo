#[cfg(test)]
mod tests {
    use cairo_appchain_bridge::bridge::interface::ITokenBridgeDispatcherTrait;
    use core::serde::Serde;
    use core::result::ResultTrait;
    use core::option::OptionTrait;
    use core::traits::TryInto;
    use snforge_std as snf;
    use snforge_std::{ContractClassTrait};
    use starknet::{ContractAddress, storage::StorageMemberAccessTrait};
    use cairo_appchain_bridge::mocks::erc20::ERC20;
    use cairo_appchain_bridge::bridge::interface::{
        ITokenBridgeAdmin, ITokenBridge, ITokenBridgeDispatcher
    };
    use starknet::contract_address::{contract_address_const};

    fn deploy_token_bridge() -> (ITokenBridgeDispatcher, ContractAddress) {
        let appchainCH = snf::declare("appchain").unwrap();
        let (appchainContract, _) = appchainCH
            .deploy(@array!['owner'.try_into().unwrap(), 0, 0, 0])
            .unwrap();
        let l3_bridge_address = contract_address_const::<'l3_bridge_address'>();

        let token_bridgeCH = snf::declare("TokenBridge").unwrap();

        let mut calldata = ArrayTrait::new();
        l3_bridge_address.serialize(ref calldata);
        appchainContract.serialize(ref calldata);
        let (token_bridge_address, _) = token_bridgeCH.deploy(@calldata).unwrap();

        (ITokenBridgeDispatcher { contract_address: token_bridge_address }, token_bridge_address)
    }

    fn deploy_erc20(name: ByteArray, symbol: ByteArray) -> ContractAddress {
        let recipient: felt252 = 'owner'.try_into().unwrap();

        let erc20Ch = snf::declare("ERC20").unwrap();
        let mut constructor_args = ArrayTrait::new();
        name.serialize(ref constructor_args);
        symbol.serialize(ref constructor_args);
        let fixed_supply: u256 = 1000000000;
        fixed_supply.serialize(ref constructor_args);
        recipient.serialize(ref constructor_args);

        let (usdc, _) = erc20Ch.deploy(@constructor_args).unwrap();
        return usdc;
    }

    #[test]
    fn constructor_ok() {
        deploy_token_bridge();
    }

    #[test]
    fn test_enroll_token() {
        let (token_bridge, _) = deploy_token_bridge();
        let usdc = deploy_erc20("USDC", "USDC");
        let l3_bridge_address = token_bridge.appchain_bridge();
        assert(
            l3_bridge_address == contract_address_const::<'l3_bridge_address'>(),
            'L3 Bridge address incorrect'
        );
        token_bridge.enroll_token(usdc);
    }
}

