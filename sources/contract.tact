
message(0x112274a7) DeployChildShardA{}

message(0x65f969ba) DeployChildShardB{}

contract Test {
    receive(_: DeployChildShardA) {
        let realStateInit = initOf Child();

        let origStateInit = beginCell()
        .storeUint(0, 3)
        .storeRef(realStateInit.code)
        .storeRef(realStateInit.data)
        .endCell();

        let newStateInit = beginCell()
        .storeUint(1, 1)
        .storeUint(8, 5)
        .storeUint(0, 1)
        .storeMaybeRef(realStateInit.code)
        .storeMaybeRef(realStateInit.data)
        .storeUint(0, 1)
        .endCell();

        let expectedAddr = beginCell().storeUint(4, 3).storeUint(0, 8).storeUint(newStateInit.hash(), 256).asSlice();
        let parsedAddr = parseStdAddress(expectedAddr);
        let realAddr = beginCell()
        .storeUint(4, 3)
        .storeUint(parsedAddr.workchain, 8)
        .storeUint(parsedAddr.address & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, 256) // First 32 bits of address will be 0
        .asSlice();


        let msg = beginCell()
            .storeUint(0x10, 6)
            .storeSlice(realAddr)
            .storeCoins(0)
            .storeUint(4 + 2, 1 + 4 + 4 + 64 + 32 + 1 + 1 + 1)
            .storeRef(newStateInit)
            .endCell();

        sendRawMessage(msg, SendRemainingValue);
    }
}

contract Child() {
    receive() {}
    get fun myAddr(): Address {
        return myAddress();
    }
}