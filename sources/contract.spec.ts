import { beginCell, toNano } from "@ton/core";
import { Blockchain } from "@ton/sandbox";
import "@ton/test-utils";
import { SampleTactContract } from "./output/sample_SampleTactContract";
import { findErrorCodeByMessage } from './utils/error';
import { flattenTransaction } from "@ton/test-utils";

describe("contract", () => {
    it("should deploy correctly", async () => {
        const temp2 = Blockchain.create;
        Blockchain.create = async (...args) => {
            const system = await temp2(...args);
            system.verbosity.vmLogs = "vm_logs_verbose";
            return system;
        }
        let system = await Blockchain.create();

        let owner = await system.treasury("deployer");
        let nonOwner = await system.treasury("non-owner");

        let contract = system.openContract(await SampleTactContract.fromInit());
        const slice = beginCell().storeUint(0, 32).asSlice();
        await contract.send(owner.getSender(), { value: toNano(1), bounce: false }, slice);

        const balanceBefore = await (await system.getContract(contract.address)).balance;
        const deployResult = await contract.send(owner.getSender(), { value: toNano(1.7) }, slice);
        const balanceAfter = await (await system.getContract(contract.address)).balance;
        expect(deployResult.transactions).toHaveTransaction({
            from: owner.address,
            to: contract.address,
            success: true,
        });
        expect(deployResult.transactions).toHaveTransaction({
            from: contract.address,
            to: owner.address,
            value: toNano(1),
        })
        expect(deployResult.transactions).toHaveTransaction({
            from: contract.address,
            to: owner.address,
            value: (value) => { return value != undefined && value > toNano(0.5) }
        })
        expect(balanceAfter).toEqual(balanceAfter);
        console.warn(balanceBefore);
        console.warn(balanceAfter);

        console.log(flattenTransaction(deployResult.transactions[1]));
        console.log(flattenTransaction(deployResult.transactions[2]));
        console.log(flattenTransaction(deployResult.transactions[3]));
    });
});
