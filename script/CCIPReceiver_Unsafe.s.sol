// script/CCIPReceiver_Unsafe.s.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import {CCIPReceiver_Unsafe} from "../src/CCIPReceiver_Unsafe.sol";

contract DeployCCIPReceiver_Unsafe is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address sepoliaRouter = 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59;

        CCIPReceiver_Unsafe receiver = new CCIPReceiver_Unsafe(sepoliaRouter);

        console.log("CCIPReceiver_Unsafe deployed to ", address(receiver));

        vm.stopBroadcast();
    }
}
