// script/CrossChainReceiver.s.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import {CrossChainReceiver} from "../src/CrossChainReceiver.sol";

contract DeployCrossChainReceiver is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address ccipRouterAddress = 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59;
        address simplifiedStakingAddress = 0x9762a41e82111262E18f70aD5deB814B6B72666a;

        CrossChainReceiver crossChainReceiver = new CrossChainReceiver(
            ccipRouterAddress,
            simplifiedStakingAddress
        );

        console.log(
            "CrossChainReceiver deployed to ",
            address(crossChainReceiver)
        );

        vm.stopBroadcast();
    }
}
