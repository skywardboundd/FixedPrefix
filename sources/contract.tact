contract SampleTactContract {
    const firstMsgValue: Int = ton("1");
    const firstMsgFwdFee: Int = ton("0.1"); // This can be constant
    //Or, if the outcoming message is quite same that the incoming one, you can use Context().readForwardFee
    //Or, if the outcoming message differs from incoming one, you can estimate the forwardFee using
    // getForwardFee(). Number of cells and bits may be obtained using caclucateDataSize().

    const totalGasFees: Int = ton("0.1"); // This value may be found using tests.

    const minimalSecondMsgValue: Int = ton("0.5");

    receive(msg: Slice) {
        // We had 1 TON on balance before this message
        // Message has 2 TONs
        // We want to send first message, containing self.firstMsgValue TONs
        // And the second one, containing "RemainingMsgValue" TONs.
        
        // Here you should check, is that possible or not
        let msgValue = context().value;
        require(msgValue >= self.firstMsgFwdFee + self.totalGasFees + self.firstMsgValue + self.minimalSecondMsgValue, "Not enough value");

        send(SendParameters{
            to: sender(), // You can choose any address you want
            bounce: false, // And set, whether you want your message to be bounceable
            value: self.firstMsgValue,
            mode: SendPayGasSeparately, // You can also use SendDefaultMode here, it depends on your needs. But don't forget to correct the code below
            body: "First".asComment()
        });
        
        let myBalanceBeforeMsg = myBalance() - msgValue;

                                        // ↓ This is needed only if you use SendPayGasSeparately above
        let remainingValue = msgValue - self.firstMsgFwdFee - self.firstMsgValue;
        
        nativeReserve(myBalanceBeforeMsg, ReserveAtMost); // You will not fail, if you can't reserve needed amount

        send(SendParameters{
            to: sender(), // You can choose any address you want
            bounce: false, // And set, whether you want your message to be bounceable
            value: 0,
            mode: SendRemainingBalance + SendIgnoreErrors, // Actually, if your require() is correct, you should not fail here, so SendIgnore errors is unessesary 
            body: "Second".asComment()
        })
    }

    // Similar, real-world example can be found here: https://github.com/EmelyanenkoK/modern_jetton/blob/master/contracts/jetton-wallet.func#L149
    // Check, if you are an advanced user
}