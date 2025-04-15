message Test {}

contract Parent() {
    receive() {}

    receive(msg: Test) {
        let child = initOf Child(myAddress());
        if(child.hasSameBasechainAddress(sender())) {
            message(MessageParameters{
                value: 0,
                mode: SendRemainingValue,
                bounce: false,
                to: address("UQBAmIBdInKmGzdTUMay9fqq8nyCZ9jnUh_yBFEE_cfediVD")
            })
        }
    }
}

contract Child(
    parent: Address,
) {
    receive() {
        message(MessageParameters{
            value: 0,
            mode: SendRemainingValue,
            to: self.parent,
            body: Test{}.toCell()
        })
    }
}


contract OptimizedParent() {
    receive() {}

    receive(msg: Test) {
        let childStateInitHash = stateInitHash(
            8837433075070783714194111561300892132251148393381834971083367764220177136600, 
            1, 
            beginCell().storeAddress(myAddress()).endCell()
        );
        if(childStateInitHash == parseStdAddress(sender().asSlice()).address) {
            message(MessageParameters{
                value: 0,
                mode: SendRemainingValue,
                to: address("UQBAmIBdInKmGzdTUMay9fqq8nyCZ9jnUh_yBFEE_cfediVD")
            });
        }
    }
}

asm fun stateInitHash(codeHash: Int, codeDepth: Int, data: Cell): Int {
    // Group 1: Computations and arrangements
    s0 PUSH HASHCU // `data` hash
    SWAP CDEPTH // `data` depth
    SWAP2
    s1 s2 XCHG

    131380 PUSHINT     // (2 << 16) | (1 << 8) | 0x34

    // Group 2: Composition of the Builder
    NEWC
    24 STU  // store refs_descriptor | bits_descriptor | data
    16 STU  // store depth_descriptor for `code`
    16 STU  // store depth_descriptor for `data`
    256 STU // store `code` hash
    256 STU // store `data` hash

    // Group 3: SHA256 hash of the resulting Builder
    ONE HASHEXT_SHA256
}