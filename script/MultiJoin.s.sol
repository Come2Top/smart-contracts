// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IDeftGame, Storage} from "./Storage.sol";
import {Script, console2, stdJson} from "forge-std/Script.sol";

contract MultiJoin is Script, Storage {
    function run() external {
        (
            IDeftGame.Status stat,
            ,
            ,
            ,
            ,
            uint256 remainingTickets,
            ,
            ,
            ,
            ,

        ) = _deftGame_.wagerInfo();
        uint256 currentWagerID = _deftGame_.currentWagerID();
        bool canJoinEasily = (stat == IDeftGame.Status.Withdrawable && remainingTickets == 1) ||
            stat == IDeftGame.Status.finished;

        uint256 ticketID;
        uint256 totalPlayers;
        uint8[] memory tickets = new uint8[](4);

        if (stat != IDeftGame.Status.waitForCommingWave)
            while (totalPlayers < 64) {
                tickets[0] = uint8(ticketID);
                tickets[1] = uint8(ticketID + 1);
                tickets[2] = uint8(ticketID + 2);
                tickets[3] = uint8(ticketID + 3);

                if (
                    canJoinEasily ||
                    _deftGame_.ticketOwnership(currentWagerID, tickets[0]) ==
                    address(0) ||
                    _deftGame_.ticketOwnership(currentWagerID, tickets[1]) ==
                    address(0) ||
                    _deftGame_.ticketOwnership(currentWagerID, tickets[2]) ==
                    address(0) ||
                    _deftGame_.ticketOwnership(currentWagerID, tickets[3]) ==
                    address(0)
                ) {
                    vmSafe.startBroadcast(_privateKeys_[totalPlayers]);
                    _deftGame_.join(tickets);
                    vmSafe.stopBroadcast();
                }

                unchecked {
                    ticketID += 4;
                    totalPlayers++;
                }
            }
    }
}
