import { Account } from "starknet";
import { declareContract, deployContract, getProvider } from "./utils/utils.ts";
import { Layer } from "./config/types.ts";
import { boostrapAccountContract, BOOTSTRAP, BOOTSTRAP_ACCOUNT_PUBLIC_KEY } from "./config/constants.ts";
import { logger } from "./utils/logger.ts";

class BoostrapAccount {
    private account!: Account;

    constructor() {
        let provider = getProvider(Layer.L3);

        this.account = new Account({
            provider,
            address: this.boostrapAddress(),
            signer: BOOTSTRAP,
        })
    }

    public boostrapAddress() {
        return BOOTSTRAP;
    }

    public async deployBoostrapAccount() {
        this.account.declare();
    }
}