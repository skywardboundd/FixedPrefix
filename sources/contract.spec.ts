import { Address, Cell, toNano } from "@ton/core";
import { Blockchain, SandboxContract } from "@ton/sandbox";
import "@ton/test-utils";
import { Parent } from "./output/sample_Parent";
import { Child } from "./output/sample_Child";
import { OptimizedParent } from "./output/sample_OptimizedParent";

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
	let parentContract: SandboxContract<Parent>;
	let usualParentChild: SandboxContract<Child>;
	let optimizedParentChild: SandboxContract<Child>;
	let optimizedParentContract: SandboxContract<OptimizedParent>;
    it("should deploy correctly", async () => {
        // Create Sandbox and deploy contract
        blockchain = await Blockchain.create();
		//blockchain.verbosity.vmLogs = "vm_logs_verbose";
        owner = await blockchain.treasury("owner");
        parentContract = blockchain.openContract(await Parent.fromInit());
		usualParentChild = blockchain.openContract(await Child.fromInit(parentContract.address));
		optimizedParentContract = blockchain.openContract(await OptimizedParent.fromInit());
		optimizedParentChild = blockchain.openContract(await Child.fromInit(optimizedParentContract.address));
		
        const deployResult = await parentContract.send(owner.getSender(), { value: toNano(1) }, null);
        expect(deployResult.transactions).toHaveTransaction({
            from: owner.address,
            to: parentContract.address,
            deploy: true,
            success: true,
        });

		const deployResultOptimized = await optimizedParentContract.send(owner.getSender(), { value: toNano(1) }, null);
		expect(deployResultOptimized.transactions).toHaveTransaction({
			from: owner.address,
			to: optimizedParentContract.address,
			deploy: true,
			success: true,
		});
    });
    it("Usual parent should work correctly", async () => {
        const res = await usualParentChild.send(owner.getSender(), { value: toNano(1) }, null);
		expect(res.transactions).toHaveTransaction({
			from: parentContract.address,
			to: Address.parse("UQBAmIBdInKmGzdTUMay9fqq8nyCZ9jnUh_yBFEE_cfediVD"),
		});
		const storageStats = await getStateSizeForAccount(blockchain, parentContract.address);
		console.log("Version without optmization");
		console.log(storageStats);
    });
	it("Optimized parent should work correctly", async () => {
		const res = await optimizedParentChild.send(owner.getSender(), { value: toNano(1) }, null);
		expect(res.transactions).toHaveTransaction({
			from: optimizedParentContract.address,
			to: Address.parse("UQBAmIBdInKmGzdTUMay9fqq8nyCZ9jnUh_yBFEE_cfediVD"),
		});
		const storageStats = await getStateSizeForAccount(blockchain, optimizedParentContract.address);
		console.log("Version with optmization");
		console.log(storageStats);
	});
});