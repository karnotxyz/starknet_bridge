#[starknet::component]
pub mod WithdrawalLimitComponent {
    use core::num::traits::Bounded;
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};
    use starknet::{ContractAddress, get_block_timestamp, get_contract_address};
    use starknet_bridge::constants;
    use starknet_bridge::withdrawal_limit::interface::IWithdrawalLimit;

    #[storage]
    pub struct Storage {
        // For each token and day, stores the amount that can still be withdrawn from this token
        // in this day (if the value is x, the amount left to withdraw is x-1). 0 means that
        // currently there was no withdrawal from this token in this day or there were withdrawals
        // but the limit flag was turned off.
        pub remaining_intraday_withdraw_quota: Map<(ContractAddress, u64), u256>,
        // The daily withdrawal limit percentage.
        // 0 means that the limit is not applied, or the limit is 100%
        // For all the other values, the limit is constants::DAILY_WITHDRAWAL_LIMIT_PCT_OFFSET + the
        // value Hence for 0% limit, we store 0 + constants::DAILY_WITHDRAWAL_LIMIT_PCT_OFFSET = 1
        pub daily_withdrawal_limit_pct: Map<ContractAddress, u8>,
    }

    //
    // Errors
    //
    pub mod Errors {
        pub const LIMIT_PCT_TOO_HIGH: felt252 = 'LIMIT_PCT_TOO_HIGH';
        pub const LIMIT_EXCEEDED: felt252 = 'LIMIT_EXCEEDED';
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        RemainingQuotaUpdated: RemainingQuotaUpdated,
        DailyWithdrawalPercentageUpdated: DailyWithdrawalPercentageUpdated,
    }

    #[derive(Drop, starknet::Event)]
    pub struct RemainingQuotaUpdated {
        pub token: ContractAddress,
        pub day: u64,
        pub new_quota: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct DailyWithdrawalPercentageUpdated {
        pub new_percentage: u8,
    }

    #[embeddable_as(WithdrawalLimitImpl)]
    pub impl WithdrawalLimit<
        TContractState, +HasComponent<TContractState>,
    > of IWithdrawalLimit<ComponentState<TContractState>> {
        // Returns the current remaining withdrawal quota for a given token. If there is no limit,
        // returns max uint256. If the limit was not set yet, we calculate it based on the total
        // supply. Otherwise, return the limit.
        fn get_remaining_withdrawal_quota(
            self: @ComponentState<TContractState>, token: ContractAddress,
        ) -> u256 {
            // If there is no limt, return max uint256.
            if !self.is_withdrawal_limit_applied(token) {
                return Bounded::MAX;
            }
            let remaining_quota = self.read_withdrawal_quota_slot(:token);

            // if remaining_quota is 0 then quota is not initialised
            if remaining_quota == 0 {
                return self.get_daily_withdrawal_limit(:token);
            }
            remaining_quota - constants::REMAINING_QUOTA_OFFSET
        }

        fn get_daily_withdrawal_limit_pct(
            self: @ComponentState<TContractState>, token: ContractAddress,
        ) -> u8 {
            if !self.is_withdrawal_limit_applied(token) {
                return 100;
            }
            self.daily_withdrawal_limit_pct.read(token)
                - constants::DAILY_WITHDRAWAL_LIMIT_PCT_OFFSET
        }


        fn is_withdrawal_limit_applied(
            self: @ComponentState<TContractState>, token: ContractAddress,
        ) -> bool {
            self.daily_withdrawal_limit_pct.read(token) != 0
        }
    }

    #[generate_trait]
    pub impl InternalImpl<
        TContractState, +HasComponent<TContractState>,
    > of InternalTrait<TContractState> {
        // Sets the remaining withdrawal quota for today.
        fn set_remaining_withdrawal_quota(
            ref self: ComponentState<TContractState>, token: ContractAddress, amount: u256,
        ) {
            let now = get_block_timestamp();
            let day = now / constants::SECONDS_IN_DAY;
            self
                .remaining_intraday_withdraw_quota
                .write((token, day), amount + constants::REMAINING_QUOTA_OFFSET);

            self.emit(RemainingQuotaUpdated { token: token, day: day, new_quota: amount });
        }

        // Returns the remaining withdrawal quota for today.
        fn read_withdrawal_quota_slot(
            self: @ComponentState<TContractState>, token: ContractAddress,
        ) -> u256 {
            let now = get_block_timestamp();
            let day = now / constants::SECONDS_IN_DAY;
            self.remaining_intraday_withdraw_quota.read((token, day))
        }


        // Try to withdraw an amount and if it succeeds, update the remaining withdrawal quota.
        fn consume_withdrawal_quota(
            ref self: ComponentState<TContractState>,
            token: ContractAddress,
            amount_to_withdraw: u256,
        ) {
            if !self.is_withdrawal_limit_applied(token) {
                return;
            }
            let remaining_withdrawal_quota = self.get_remaining_withdrawal_quota(token);

            assert(remaining_withdrawal_quota >= amount_to_withdraw, Errors::LIMIT_EXCEEDED);
            self
                .set_remaining_withdrawal_quota(
                    :token, amount: remaining_withdrawal_quota - amount_to_withdraw,
                )
        }

        // Returns the full quota of the daily withdrawal limit for a given token.
        // The calculation is based on the limit percentage and current token total supply.
        // Note - while technically, we're exposed to overflow error here, we consider that
        // risk non-existant for any token of even the smallest value.
        fn get_daily_withdrawal_limit(
            self: @ComponentState<TContractState>, token: ContractAddress,
        ) -> u256 {
            let dispatcher = IERC20Dispatcher { contract_address: token };
            let balance = dispatcher.balance_of(get_contract_address());
            let daily_withdrawal_limit_pct: u256 = self
                .get_daily_withdrawal_limit_pct(token)
                .into();
            balance * daily_withdrawal_limit_pct / 100
        }

        fn write_daily_withdrawal_limit_pct(
            ref self: ComponentState<TContractState>,
            token: ContractAddress,
            daily_withdrawal_limit_pct: u8,
        ) {
            assert(daily_withdrawal_limit_pct <= 100, Errors::LIMIT_PCT_TOO_HIGH);
            if daily_withdrawal_limit_pct == 100 {
                self.daily_withdrawal_limit_pct.write(token, 0);
            } else {
                self
                    .daily_withdrawal_limit_pct
                    .write(
                        token,
                        daily_withdrawal_limit_pct + constants::DAILY_WITHDRAWAL_LIMIT_PCT_OFFSET,
                    );
            }

            self
                .emit(
                    DailyWithdrawalPercentageUpdated { new_percentage: daily_withdrawal_limit_pct },
                );
        }
    }
}
