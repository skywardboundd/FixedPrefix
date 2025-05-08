message(0x112274a7) DeployFirstChild {
    shard: Int as uint30;
}

message(0x65f969ba) DeploySecondChild {
    shard: Int as uint30;
}

message(0xad7c3add) Refund { }
const prefix_length: Int = 30;

fun initToPrefixInit(init: StateInit): Cell {        
    let newStateInit = beginCell()
        .storeUint(1, 1)
        .storeUint(prefix_length, 5)
        .storeUint(0, 1)
        .storeMaybeRef(init.code)
        .storeMaybeRef(init.data)
        .storeUint(0, 1)
        .endCell();
    return newStateInit;
}

fun shardedAddress(hash: Int, shard: Int): Address{ 
    let expectedAddr = beginCell()
        .storeUint(4, 3)
        .storeUint(0, 8)
        .storeUint((hash & ((1 << (256 - prefix_length)) - 1)) | (shard << (256 - prefix_length)), 256)
        .asSlice();

    let parsedAddr = parseStdAddress(expectedAddr);
    let realAddr: Slice = beginCell()
        .storeUint(4, 3)
        .storeUint(parsedAddr.workchain, 8)
        .storeUint(parsedAddr.address, 256)
        .asSlice();

    return realAddr.loadAddress();
}

contract Test {
    receive(_: Refund) { 
        send(SendParameters{
            to: sender(),
            value: 0,
            mode: SendRemainingBalance,
        });
    }

    receive(msg: DeployFirstChild) {
        let realStateInit = initOf FirstChild();

        let newStateInit = initToPrefixInit(realStateInit);

        let addr: Address = shardedAddress(newStateInit.hash(), msg.shard);

        let msgOut = beginCell()
            .storeUint(0x10, 6)
            .storeAddress(addr)
            .storeCoins(0)
            .storeUint(4 + 2, 1 + 4 + 4 + 64 + 32 + 1 + 1 + 1)
            .storeRef(newStateInit)
            .endCell();

        sendRawMessage(msgOut, SendRemainingValue);
    }

    receive(msg: DeploySecondChild) {
        let realStateInit = initOf SecondChild();

        let newStateInit = initToPrefixInit(realStateInit);

        let addr: Address = shardedAddress(newStateInit.hash(), msg.shard);

        let msgOut = beginCell()
            .storeUint(0x18, 6)
            .storeAddress(addr)
            .storeCoins(0)
            .storeUint(4 + 2, 1 + 4 + 4 + 64 + 32 + 1 + 1 + 1)
            .storeRef(newStateInit)
            .endCell();

        sendRawMessage(msgOut, SendRemainingValue);
    }

    get fun getFirstChildAddress(shard: Int): Address  {
        let realStateInit = initOf FirstChild();

        let newStateInit = initToPrefixInit(realStateInit);

        let addr: Address = shardedAddress(newStateInit.hash(), shard);
        return addr;
    }

    get fun getSecondChildAddress(shard: Int): Address { 
        let realStateInit = initOf SecondChild();

        let newStateInit = initToPrefixInit(realStateInit);

        let addr: Address = shardedAddress(newStateInit.hash(), shard);
        
        return addr;
    }
}

contract FirstChild() {
    receive() {
        cashback(sender());
    }

    receive(msg: Refund) {
        send(SendParameters{
            to: sender(),
            value: 0,
            mode: SendRemainingBalance,
        });
    }

    get fun myAddr(): Address {
        return myAddress();
    }
}

contract SecondChild {
    counter: Int = 0;

    init(){}

    receive() { self.counter += 1; }

    receive(msg: Refund) {
        send(SendParameters{
            to: sender(),
            value: 0,
            mode: SendRemainingBalance,
        });
    }

    get fun myAddr(): Address {
        return myAddress();
    }
    get fun getCounter(): Int {
        return self.counter;
    }
}
