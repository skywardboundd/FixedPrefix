import { Address, Cell, toNano } from "@ton/core";
import { Blockchain, SandboxContract } from "@ton/sandbox";
import "@ton/test-utils";
import { Test } from "./output/sample_Test";
import { Child } from "./output/sample_Child";

import { findTransactionRequired, flattenTransaction } from "@ton/test-utils";
import { FirstChild } from "./output/sample_FirstChild";

const calculateCellsAndBits = (
    root: Cell,
    visited: Set<string> = new Set<string>(),
) => {
    const hash = root.hash().toString("hex");
    if (visited.has(hash)) {
        return { cells: 0, bits: 0 };
    }
    visited.add(hash);

    let cells = 1;
    let bits = root.bits.length;
    for (const ref of root.refs) {
        const childRes = calculateCellsAndBits(ref, visited);
        cells += childRes.cells;
        bits += childRes.bits;
    }
    return { cells, bits };
};

export async function getStateSizeForAccount(
    blockchain: Blockchain,
    address: Address,
): Promise<{ cells: number; bits: number }> {
    const accountState = (await blockchain.getContract(address)).accountState;
    if (!accountState || accountState.type !== "active") {
        throw new Error("Account state not found");
    }
    if (!accountState.state.code || !accountState.state.data) {
        throw new Error("Account state code or data not found");
    }
    const accountCode = accountState.state.code;
    const accountData = accountState.state.data;

    const codeSize = calculateCellsAndBits(accountCode);
    const dataSize = calculateCellsAndBits(accountData);

    return {
        cells: codeSize.cells + dataSize.cells,
        bits: codeSize.bits + dataSize.bits,
    };
}

describe("contract", () => {
	let blockchain: Blockchain;
	let owner: any;
	let parentContract: SandboxContract<Test>;
    it("should deploy correctly", async () => {
        // Create Sandbox and deploy contract
        blockchain = await Blockchain.create();
		// blockchain.verbosity.vmLogs = "vm_logs_verbose";
        owner = await blockchain.treasury("owner");
        parentContract = blockchain.openContract(await Test.fromInit());
        
        const deployTypes = ["DeployFirstChild", "DeploySecondChild"] as const;
        for (const element of deployTypes) {
            try { 
                const deployResult = await parentContract.send(owner.getSender(), { value: toNano(1) }, {
                    $$type: element,
                    shard: 123123n,
                });
                console.log(element, "without errors");
            } catch(_e) {
                console.log(element, "Some error ( Invalid Address )");
            }
        }
        
        // const childContract = blockchain.openContract(await FirstChild.fromInit());
        // console.log("Expected address: ", childContract.address);
        // console.log("Expected address parsed: ", childContract.address.hash.toString("hex"));
        // expect(deployResult.transactions).toHaveTransaction({
        //     from: parentContract.address,
        //     deploy: true,
        // });
        // console.log()

        // const realAddr = flattenTransaction(tx).to;
        // console.log("Real address: ", realAddr);
        // console.log("Real address parsed: ", realAddr?.hash.toString("hex"));
    });
});