// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script, console2, stdJson} from "forge-std/Script.sol";
import {Storage} from "./Storage.sol";

contract MultiApproval is Script, Storage {
    function run() external {
        uint256 i;
        while (i < 64) {
            vmSafe.startBroadcast(_privateKeys_[i]);
            _usdt_.approve(address(_come2top_), type(uint256).max);
            vmSafe.stopBroadcast();
        }
    }
}
