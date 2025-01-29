import { toNano } from "@ton/core";
import { Blockchain } from "@ton/sandbox";
import "@ton/test-utils";
import { SampleTactContract } from "./output/sample_SampleTactContract";
import { findErrorCodeByMessage } from './utils/error';

describe("contract", () => {
    it("should deploy correctly", async () => {
        const temp2 = Blockchain.create;
        Blockchain.create = async (...args) => {
            const system = await temp2(...args);
            system.verbosity.vmLogs = "vm_logs_verbose";
            return system;
        }
        let system = await Blockchain.create();

        let owner = await system.treasury("owner");
        let nonOwner = await system.treasury("non-owner");

        let contract = system.openContract(await SampleTactContract.fromInit());
        const deployResult = await contract.send(owner.getSender(), { value: toNano(1) }, { $$type: "Test", any: 0n});
        expect(deployResult.transactions).toHaveTransaction({
            from: owner.address,
            to: contract.address,
            deploy: true,
            success: true,
        });


        //system.verbosity.vmLogs = "vm_logs";
        // Check counter
    });
});
