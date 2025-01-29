
// This function is called on each console.log
// So we need to filter out the logs that are not transactions

parseTransaction = (text) => {
    const lines = text.split("\n");
    const accountLine = lines[0];
    if(accountLine.inludes("unpacking account ")) {
        const match = text.match(/unpacking account (\S+)/);
        if (match) {
            const accountAddress = match[1];
        }
    }
    const gasLine = lines[13];
    if(gasLine.includes("gas used: ")) {
        const match = gasLine.match(/Gas used: (\d+)/);
        if (match) {
            const gasUsed = match[1];
        }
    }
}

module.exports = async () => {
    //Override console.log
    require("@ton/sandbox").Blockchain.create = async (...args) => {
       const blockchain = await require("@ton/sandbox").Blockchain.create(...args);
       blockchain.verbosity.blockchainLogs = true;
       return blockchain;
    };
    const oldLog = console.log;
    console.log = parseTransaction;
};
