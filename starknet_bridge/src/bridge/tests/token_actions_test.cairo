use snforge_std as snf;
use starknet::storage::{StorageMapReadAccess, StorageMapWriteAccess};
use starknet_bridge::access_control::roles::Roles;
use starknet_bridge::bridge::tests::constants::{
    APP_GOVERNOR, GOVERNANCE_ADMIN, L3_BRIDGE_ADDRESS, SECURITY_ADMIN, SECURITY_AGENT,
    TIMELOCK_ADDRESS, TOKEN_ADMIN, USDC_MOCK_ADDRESS,
};
use starknet_bridge::bridge::tests::utils::setup::mock_state_testing;
use starknet_bridge::bridge::types::{TokenSettings, TokenStatus};
use starknet_bridge::bridge::{ITokenBridge, ITokenBridgeAdmin, TokenBridge};

#[test]
fn deactivate_token_ok() {
    let mut mock = mock_state_testing();
    let usdc_address = USDC_MOCK_ADDRESS();

    TokenBridge::constructor(
        ref mock,
        L3_BRIDGE_ADDRESS(),
        'messaging_mock'.try_into().unwrap(),
        array![GOVERNANCE_ADMIN()].span(),
        array![APP_GOVERNOR()].span(),
        array![SECURITY_ADMIN()].span(),
        array![SECURITY_AGENT()].span(),
        array![TOKEN_ADMIN()].span(),
        TIMELOCK_ADDRESS(),
    );
    // Setting the token active
    let old_settings = mock.token_settings.read(usdc_address);
    mock
        .token_settings
        .write(usdc_address, TokenSettings { token_status: TokenStatus::Active, ..old_settings });

    snf::start_cheat_caller_address_global(TOKEN_ADMIN());
    mock.deactivate_token(usdc_address);

    assert(mock.get_status(usdc_address) == TokenStatus::Deactivated, 'Token not deactivated');
}

#[test]
#[should_panic(expected: ('Token not active',))]
fn deactivate_token_not_active() {
    let mut mock = mock_state_testing();
    let usdc_address = USDC_MOCK_ADDRESS();

    mock.access_control.AccessControl_role_member.write((Roles::TOKEN_ADMIN, TOKEN_ADMIN()), true);
    snf::start_cheat_caller_address_global(TOKEN_ADMIN());

    mock.deactivate_token(usdc_address);
    assert(mock.get_status(usdc_address) == TokenStatus::Deactivated, 'Token not deactivated');
}


#[test]
#[should_panic(expected: ('Caller is missing role',))]
fn deactivate_token_not_owner() {
    let mut mock = mock_state_testing();
    let usdc_address = USDC_MOCK_ADDRESS();

    mock.access_control.AccessControl_role_member.write((Roles::TOKEN_ADMIN, TOKEN_ADMIN()), true);
    snf::start_cheat_caller_address_global(snf::test_address());

    mock.deactivate_token(usdc_address);
    assert(mock.get_status(usdc_address) == TokenStatus::Deactivated, 'Token not deactivated');
}

#[test]
fn block_token_ok() {
    let mut mock = mock_state_testing();
    let usdc_address = USDC_MOCK_ADDRESS();

    mock.access_control.AccessControl_role_member.write((Roles::TOKEN_ADMIN, TOKEN_ADMIN()), true);
    snf::start_cheat_caller_address_global(TOKEN_ADMIN());

    mock.block_token(usdc_address);
    assert(mock.get_status(usdc_address) == TokenStatus::Blocked, 'Token not blocked');
}


#[test]
#[should_panic(expected: ('Caller is missing role',))]
fn block_token_not_owner() {
    let mut mock = mock_state_testing();
    let usdc_address = USDC_MOCK_ADDRESS();

    mock.access_control.AccessControl_role_member.write((Roles::TOKEN_ADMIN, TOKEN_ADMIN()), true);

    snf::start_cheat_caller_address_global(snf::test_address());

    mock.block_token(usdc_address);
}

#[test]
#[should_panic(expected: ('Only unknown can be blocked',))]
fn block_token_not_unknown() {
    let mut mock = mock_state_testing();
    let usdc_address = USDC_MOCK_ADDRESS();

    // Setting the token active
    let old_settings = mock.token_settings.read(usdc_address);
    mock
        .token_settings
        .write(usdc_address, TokenSettings { token_status: TokenStatus::Active, ..old_settings });

    mock.access_control.AccessControl_role_member.write((Roles::TOKEN_ADMIN, TOKEN_ADMIN()), true);
    snf::start_cheat_caller_address_global(TOKEN_ADMIN());

    mock.block_token(usdc_address);
}

#[test]
fn unblock_token_ok() {
    let mut mock = mock_state_testing();
    let usdc_address = USDC_MOCK_ADDRESS();

    // Setting the token active
    let old_settings = mock.token_settings.read(usdc_address);
    mock
        .token_settings
        .write(usdc_address, TokenSettings { token_status: TokenStatus::Blocked, ..old_settings });

    mock.access_control.AccessControl_role_member.write((Roles::TOKEN_ADMIN, TOKEN_ADMIN()), true);
    snf::start_cheat_caller_address_global(TOKEN_ADMIN());

    mock.unblock_token(usdc_address);
    assert(mock.get_status(usdc_address) == TokenStatus::Unknown, 'Not unblocked');
}

#[test]
#[should_panic(expected: ('Caller is missing role',))]
fn unblock_token_not_owner() {
    let mut mock = mock_state_testing();
    let usdc_address = USDC_MOCK_ADDRESS();

    // Setting the token active
    let old_settings = mock.token_settings.read(usdc_address);
    mock
        .token_settings
        .write(usdc_address, TokenSettings { token_status: TokenStatus::Blocked, ..old_settings });

    mock.access_control.AccessControl_role_member.write((Roles::TOKEN_ADMIN, TOKEN_ADMIN()), true);

    snf::start_cheat_caller_address_global(snf::test_address());

    mock.unblock_token(usdc_address);
}


#[test]
#[should_panic(expected: ('Token not blocked',))]
fn unblock_token_not_blocked() {
    let mut mock = mock_state_testing();
    let usdc_address = USDC_MOCK_ADDRESS();

    // Setting the token active
    let old_settings = mock.token_settings.read(usdc_address);
    mock
        .token_settings
        .write(usdc_address, TokenSettings { token_status: TokenStatus::Active, ..old_settings });

    mock.access_control.AccessControl_role_member.write((Roles::TOKEN_ADMIN, TOKEN_ADMIN()), true);
    snf::start_cheat_caller_address_global(TOKEN_ADMIN());

    mock.unblock_token(usdc_address);
}

#[test]
fn reactivate_token_ok() {
    let mut mock = mock_state_testing();
    let usdc_address = USDC_MOCK_ADDRESS();

    // Setting the token active
    let old_settings = mock.token_settings.read(usdc_address);
    mock
        .token_settings
        .write(
            usdc_address, TokenSettings { token_status: TokenStatus::Deactivated, ..old_settings },
        );

    mock.access_control.AccessControl_role_member.write((Roles::TOKEN_ADMIN, TOKEN_ADMIN()), true);
    snf::start_cheat_caller_address_global(TOKEN_ADMIN());

    mock.reactivate_token(usdc_address);
    assert(mock.get_status(usdc_address) == TokenStatus::Active, 'Did not reactivate');
}

#[test]
#[should_panic(expected: ('Caller is missing role',))]
fn reactivate_token_not_owner() {
    let mut mock = mock_state_testing();
    let usdc_address = USDC_MOCK_ADDRESS();

    // Setting the token active
    let old_settings = mock.token_settings.read(usdc_address);
    mock
        .token_settings
        .write(
            usdc_address, TokenSettings { token_status: TokenStatus::Deactivated, ..old_settings },
        );

    snf::start_cheat_caller_address_global(snf::test_address());

    mock.reactivate_token(usdc_address);
}

#[test]
#[should_panic(expected: ('Token not deactivated',))]
fn reactivate_token_not_deactivated() {
    let mut mock = mock_state_testing();
    let usdc_address = USDC_MOCK_ADDRESS();

    // Setting the token active
    let old_settings = mock.token_settings.read(usdc_address);
    mock
        .token_settings
        .write(usdc_address, TokenSettings { token_status: TokenStatus::Blocked, ..old_settings });

    mock.access_control.AccessControl_role_member.write((Roles::TOKEN_ADMIN, TOKEN_ADMIN()), true);

    snf::start_cheat_caller_address_global(TOKEN_ADMIN());

    mock.reactivate_token(usdc_address);
}

#[test]
#[should_panic(expected: ('Token not unknown',))]
fn enroll_token_blocked() {
    let mut mock = mock_state_testing();

    let usdc_address = USDC_MOCK_ADDRESS();

    // Setting the token active
    let old_settings = mock.token_settings.read(usdc_address);
    mock
        .token_settings
        .write(usdc_address, TokenSettings { token_status: TokenStatus::Blocked, ..old_settings });

    mock.access_control.AccessControl_role_member.write((Roles::TOKEN_ADMIN, TOKEN_ADMIN()), true);

    snf::start_cheat_caller_address_global(TOKEN_ADMIN());
    mock.enroll_token(usdc_address);
}


#[test]
fn get_status_ok() {
    let mut mock = mock_state_testing();
    let usdc_address = USDC_MOCK_ADDRESS();

    assert(mock.get_status(usdc_address) == TokenStatus::Unknown, 'Incorrect status');

    // Setting the token active
    let old_settings = mock.token_settings.read(usdc_address);
    mock
        .token_settings
        .write(usdc_address, TokenSettings { token_status: TokenStatus::Active, ..old_settings });

    assert(mock.get_status(usdc_address) == TokenStatus::Active, 'Incorrect status');

    // Setting the token
    let old_settings = mock.token_settings.read(usdc_address);
    mock
        .token_settings
        .write(usdc_address, TokenSettings { token_status: TokenStatus::Blocked, ..old_settings });

    assert(mock.get_status(usdc_address) == TokenStatus::Blocked, 'Incorrect status');
}


#[test]
fn is_servicing_token_ok() {
    let mut mock = mock_state_testing();
    let usdc_address = USDC_MOCK_ADDRESS();

    assert(mock.is_servicing_token(usdc_address) == false, 'Should not be servicing');
    // Setting the token active
    let old_settings = mock.token_settings.read(usdc_address);
    mock
        .token_settings
        .write(usdc_address, TokenSettings { token_status: TokenStatus::Active, ..old_settings });

    assert(mock.is_servicing_token(usdc_address) == true, 'Should be servicing');
}

