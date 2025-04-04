// Role                |   Role Admin
// ----------------------------------------
// UPGRADE_GOVERNOR    |   DEFAULT_ADMIN_ROLE
// APP_GOVERNOR        |   DEFAULT_ADMIN_ROLE
// SECURITY_ADMIN      |   DEFAULT_ADMIN_ROLE
// SECURITY_AGENT      |   SECURITY_ADMIN
// TOKEN_ADMIN         |   APP_GOVERNOR

pub mod Roles {
    pub const UPGRADE_GOVERNOR: felt252 = 'UPGRADE_GOVERNOR';
    pub const APP_GOVERNOR: felt252 = 'APP_GOVERNOR';
    pub const SECURITY_ADMIN: felt252 = 'SECURITY_ADMIN';
    pub const SECURITY_AGENT: felt252 = 'SECURITY_AGENT';
    pub const TOKEN_ADMIN: felt252 = 'TOKEN_ADMIN';
}
