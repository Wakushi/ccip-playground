// script/CCIPTokenSender.s.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import {CCIPTokenAndDataSender} from "../src/CCIPTokenAndDataSender.sol";

contract DeployCCIPTokenAndDataSender is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address fujiLink = 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846;
        address fujiRouter = 0xF694E193200268f9a4868e4Aa017A0118C9a8177;

        CCIPTokenAndDataSender sender = new CCIPTokenAndDataSender(
            fujiLink,
            fujiRouter
        );

        console.log("CCIPTokenAndDataSender deployed to ", address(sender));

        vm.stopBroadcast();
    }
}
