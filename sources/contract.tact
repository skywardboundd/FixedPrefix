import "@stdlib/deploy";

asm fun zero() { NOP }

fun mySend(params: SendParameters): Int { // returns forward fee
    zero();
    let b: Builder = beginCell();
    b = b.storeInt(1, 2); // internal_message + ihd_disabled
    b = b.storeBool(params.bounce); // bounce
    b = b.storeInt(0, 3); // bounced + from
    b = b.storeAddress(params.to); // To
    b = b.storeCoins(params.value); // Value
    b = b.storeInt(0, 1 + 4 + 4 + 64 + 32); // currency_collection + IHR fees + Fwd fees + CreatedLT + CreatedAt

    // Stateinit
    if (params.code != null || params.data != null) {
        b = b.storeBool(true); // State init

        // Assemble state init cell
        let bc: Builder = beginCell();
        bc = bc.storeBool(false); // SplitDepth
        bc = bc.storeBool(false); // TickTock
        if (params.code != null) {
            bc = bc.storeBool(true); // Code presence
            bc = bc.storeRef(params.code!!);
        } else {
            bc = bc.storeBool(false); // Code presence
        }
        if (params.data != null) {
            bc = bc.storeBool(true); // Data presence
            bc = bc.storeRef(params.data!!);
        } else {
            bc = bc.storeBool(false); // Data presence
        }
        bc = bc.storeBool(false); // Library

        b = b.storeBool(true); // Store as ref
        b = b.storeRef(bc.endCell());
    } else {
        b = b.storeBool(false); // No state init
    }

    // Body
    let body: Cell? = params.body;
    if (body != null) {
        b = b.storeBool(true);
        b = b.storeRef(body!!);
    } else {
        b = b.storeBool(false); // No body
    }

    // Send
    let c: Cell = b.endCell();
    return nativeSendMessageReturnForwardFee(c, params.mode);
}

message Test {
    any: Int;
}
contract SampleTactContract {
    receive(msg: Test) {
        dump(6);
        mySend(SendParameters{
            bounce: true,
            to: myAddress(),
            value: 44,
            mode: 64,
            body: "TEST".asComment(),
            code: emptyCell(),
            data: emptyCell()
        });
    }
}

