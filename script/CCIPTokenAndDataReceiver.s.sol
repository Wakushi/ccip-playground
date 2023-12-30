// script/CCIPTokenSender.s.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {CCIPTokenAndDataReceiver} from "../src/CCIPTokenAndDataReceiver.sol";

contract DeployCCIPTokenAndDataReceiver is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address sepoliaRouter = 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59;
        uint256 mintPrice = 100; // CCIP-BnM

        CCIPTokenAndDataReceiver sender = new CCIPTokenAndDataReceiver(
            sepoliaRouter,
            mintPrice
        );

        console.log("CCIPTokenAndDataReceiver deployed to ", address(sender));

        vm.stopBroadcast();
    }
}
