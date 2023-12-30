// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

contract CCIPSender_Unsafe {
    address immutable i_link;
    address immutable i_router;

    constructor(address _link, address _router) {
        i_link = _link;
        i_router = _router;
        LinkTokenInterface(_link).approve(_router, type(uint256).max);
    }

    function send(
        address _receiver,
        string memory _textMessage,
        uint64 _destinationChainSelector
    ) external {
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver),
            data: abi.encode(_textMessage),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: i_link
        });

       IRouterClient(i_router).ccipSend(_destinationChainSelector, message);
    }
}
