// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ICome2Top, Storage} from "./Storage.sol";
import {Script} from "forge-std/Script.sol";

contract MultiJoin is Script, Storage {
    function run() external {
        (
            ICome2Top.Status stat,
            ,
            ,
            ,
            ,
            uint256 remainingTickets,
            ,
            ,
            ,
            ,

        ) = _COME2TOP_.wagerInfo();
        uint256 currentWagerID = _COME2TOP_.currentWagerID();
        bool joinable = (stat == ICome2Top.Status.Withdrawable &&
            remainingTickets == 1) || stat == ICome2Top.Status.finished;

        uint256 ticketID;
        uint256 totalPlayers;
        uint8[] memory tickets = new uint8[](4);

        if (stat != ICome2Top.Status.waitForCommingWave)
            while (totalPlayers < 64) {
                tickets[0] = uint8(ticketID);
                tickets[1] = uint8(ticketID + 1);
                tickets[2] = uint8(ticketID + 2);
                tickets[3] = uint8(ticketID + 3);

                if (
                    joinable ||
                    _COME2TOP_.ticketOwnership(currentWagerID, tickets[0]) ==
                    address(0) ||
                    _COME2TOP_.ticketOwnership(currentWagerID, tickets[1]) ==
                    address(0) ||
                    _COME2TOP_.ticketOwnership(currentWagerID, tickets[2]) ==
                    address(0) ||
                    _COME2TOP_.ticketOwnership(currentWagerID, tickets[3]) ==
                    address(0)
                ) {
                    vmSafe.startBroadcast(_privateKeys_[totalPlayers]);
                    _COME2TOP_.join(tickets);
                    vmSafe.stopBroadcast();
                }

                unchecked {
                    ticketID += 4;
                    totalPlayers++;
                }
            }
    }
}
