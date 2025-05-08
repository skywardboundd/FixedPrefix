message(0x112274a7) DeployFirstChild {
    shard: Int as uint30;
}

message(0x65f969ba) DeploySecondChild {
    shard: Int as uint30;
}

contract Test {
    receive(msg: DeployFirstChild) {
        let realStateInit = initOf FirstChild();

        let origStateInit = beginCell()
            .storeUint(0, 3)
            .storeRef(realStateInit.code)
            .storeRef(realStateInit.data)
            .endCell();

        let prefix_length = 30;
        let newStateInit = beginCell()
            .storeUint(1, 1)
            .storeUint(prefix_length, 5)
            .storeUint(0, 1)
            .storeMaybeRef(realStateInit.code)
            .storeMaybeRef(realStateInit.data)
            .storeUint(0, 1)
            .endCell();


        let expectedAddr = beginCell()
            .storeUint(4, 3)
            .storeUint(0, 8)
            .storeUint((newStateInit.hash() & ((1 << (256 - prefix_length)) - 1)) | (msg.shard << (256 - prefix_length)), 256)
            .asSlice();

        let parsedAddr = parseStdAddress(expectedAddr);
        let realAddr = beginCell()
            .storeUint(4, 3)
            .storeUint(parsedAddr.workchain, 8)
            .storeUint(parsedAddr.address, 256)
            .asSlice();

        let msgOut = beginCell()
            .storeUint(0x10, 6)
            .storeSlice(realAddr)
            .storeCoins(0)
            .storeUint(4 + 2, 1 + 4 + 4 + 64 + 32 + 1 + 1 + 1)
            .storeRef(newStateInit)
            .endCell();

        sendRawMessage(msgOut, SendRemainingValue);
    }

    receive(msg: DeploySecondChild) {
        let realStateInit = initOf SecondChild();

        let origStateInit = beginCell()
            .storeUint(0, 3)
            .storeRef(realStateInit.code)
            .storeRef(realStateInit.data)
            .endCell();

        let prefix_length = 30;
        let newStateInit = beginCell()
            .storeUint(1, 1)
            .storeUint(prefix_length, 5)
            .storeUint(0, 1)
            .storeMaybeRef(realStateInit.code)
            .storeMaybeRef(realStateInit.data)
            .storeUint(0, 1)
            .endCell();


        let expectedAddr = beginCell()
            .storeUint(4, 3)
            .storeUint(0, 8)
            .storeUint((newStateInit.hash() & ((1 << (256 - prefix_length)) - 1)) | (msg.shard << (256 - prefix_length)), 256)
            .asSlice();

        let parsedAddr = parseStdAddress(expectedAddr);
        let realAddr = beginCell()
            .storeUint(4, 3)
            .storeUint(parsedAddr.workchain, 8)
            .storeUint(parsedAddr.address, 256)
            .asSlice();

        let msgOut = beginCell()
            .storeUint(0x10, 6)
            .storeSlice(realAddr)
            .storeCoins(0)
            .storeUint(4 + 2, 1 + 4 + 4 + 64 + 32 + 1 + 1 + 1)
            .storeRef(newStateInit)
            .endCell();

        sendRawMessage(msgOut, SendRemainingValue);
    }
}

contract FirstChild() {
    receive() {
        cashback(sender());
    }

    get fun myAddr(): Address {
        return myAddress();
    }
}

contract SecondChild() {
    receive() { }

    get fun myAddr(): Address {
        return myAddress();
    }
}
