// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ICome2Top, Storage} from "./Storage.sol";
import {Script} from "forge-std/Script.sol";

contract MultiJoin is Script, Storage {
    function run() external {
        (ICome2Top.Status stat, , , , , , , , , , ) = _COME2TOP_
            .continuesIntegration();
        uint256 currentGameID = _COME2TOP_.currentGameID();
        bool firstEnter = uint256(stat) > 2;

        uint256 ticketID;
        uint256 totalPlayers;
        uint8[] memory tickets = new uint8[](4);

        if (
            stat != ICome2Top.Status.commingWave &&
            stat != ICome2Top.Status.operational
        )
            while (totalPlayers < 64) {
                tickets[0] = uint8(ticketID);
                tickets[1] = uint8(ticketID + 1);
                tickets[2] = uint8(ticketID + 2);
                tickets[3] = uint8(ticketID + 3);

                while (
                    _COME2TOP_.totalPlayerTickets(
                        currentGameID,
                        vm.addr(_privateKeys_[totalPlayers])
                    ) == _COME2TOP_.maxTicketsPerGame()
                ) totalPlayers++;

                if (
                    _COME2TOP_.tempTicketOwnership(currentGameID, tickets[0]) ==
                    address(0) ||
                    _COME2TOP_.tempTicketOwnership(currentGameID, tickets[1]) ==
                    address(0) ||
                    _COME2TOP_.tempTicketOwnership(currentGameID, tickets[2]) ==
                    address(0) ||
                    _COME2TOP_.tempTicketOwnership(currentGameID, tickets[3]) ==
                    address(0) ||
                    firstEnter
                ) {
                    vmSafe.startBroadcast(_privateKeys_[totalPlayers]);
                    _COME2TOP_.ticketSaleOperation(tickets);
                    vmSafe.stopBroadcast();
                }

                if (firstEnter) delete firstEnter;

                unchecked {
                    ticketID += 4;
                    totalPlayers++;
                }
            }
    }
}
