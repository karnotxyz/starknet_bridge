use openzeppelin::token::erc20::interface::{
    IERC20MetadataDispatcher, IERC20MetadataDispatcherTrait,
};
use starknet::ContractAddress;
use starknet_bridge::constants;

pub fn deposit_message_payload(
    token: ContractAddress,
    amount: u256,
    caller: ContractAddress,
    appchain_recipient: ContractAddress,
    is_with_message: bool,
    message: Span<felt252>,
) -> Span<felt252> {
    let mut payload = ArrayTrait::new();
    token.serialize(ref payload);
    caller.serialize(ref payload);
    appchain_recipient.serialize(ref payload);
    amount.serialize(ref payload);
    if (is_with_message) {
        message.serialize(ref payload);
    }

    return payload.span();
}

pub fn deployment_message_payload(token: ContractAddress) -> Span<felt252> {
    // Create the calldata that will be sent to on_receive. l2_token, amount and
    // depositor are the fields from the deposit context.
    let mut calldata = ArrayTrait::new();
    let dispatcher = IERC20MetadataDispatcher { contract_address: token };
    token.serialize(ref calldata);
    dispatcher.name().serialize(ref calldata);
    dispatcher.symbol().serialize(ref calldata);
    dispatcher.decimals().serialize(ref calldata);
    calldata.span()
}

pub fn withdraw_message_payload_from_appchain(
    token: ContractAddress, amount: u256, recipient: ContractAddress,
) -> Span<felt252> {
    let mut message_payload = ArrayTrait::new();
    constants::TRANSFER_FROM_APPCHAIN.serialize(ref message_payload);
    recipient.serialize(ref message_payload);
    token.serialize(ref message_payload);
    amount.serialize(ref message_payload);
    message_payload.span()
}


pub fn count_bytes(mut value: u128) -> usize {
    let mut bytes = 0;
    while value > 0 {
        value /= 256;
        bytes += 1;
    }
    bytes
}

pub fn deserialize_and_append(
    mut value: Span<felt252>, mut calldata: Array<felt252>,
) -> Array<felt252> {
    if (value.len() == 1) {
        let mut value_u256: u256 = (*value[0]).into();
        let mut total_bytes = count_bytes(value_u256.low) + count_bytes(value_u256.high);

        let mut value_byte_array: ByteArray = "";
        value_byte_array.append_word(*value[0], total_bytes);
        value_byte_array.serialize(ref calldata);
    } else {
        let value_byte_array = Serde::<ByteArray>::deserialize(ref value).unwrap();
        value_byte_array.serialize(ref calldata);
    }
    calldata
}
