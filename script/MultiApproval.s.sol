// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {Storage} from "./Storage.sol";

contract MultiApproval is Script, Storage {
    function run() external {
        uint256 i;
        while (i < 64) {
            vmSafe.startBroadcast(_privateKeys_[i]);
            _FRAX_.approve(address(_COME2TOP_), type(uint256).max);
            vmSafe.stopBroadcast();

            unchecked {
                i++;
            }
        }
    }
}
