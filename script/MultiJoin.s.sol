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
        uint256 totalPlayerTickets;
        if (
            stat != ICome2Top.Status.commingWave &&
            stat != ICome2Top.Status.operational
        )
            while (totalPlayers < 64) {
                totalPlayerTickets = _COME2TOP_.totalPlayerTickets(
                    currentGameID,
                    vm.addr(_privateKeys_[totalPlayers])
                );

                totalPlayerTickets > 4 ? totalPlayerTickets = 0 : totalPlayerTickets;

                if (totalPlayerTickets == 4) totalPlayers++;
                else {
                    uint8[] memory tickets = new uint8[](
                        4 - totalPlayerTickets
                    );

                    bool shouldBreak;

                    while (true) {
                        if (ticketID == 256) {
                            shouldBreak = true;
                            break;
                        }
                        if (
                            _COME2TOP_.tempTicketOwnership(
                                currentGameID,
                                uint8(ticketID)
                            ) != address(0)
                        ) ticketID++;
                        else {
                            tickets[0] = uint8(ticketID);
                            ticketID++;
                            break;
                        }
                    }

                    if (totalPlayerTickets < 3 && !shouldBreak)
                        while (true) {
                            if (ticketID == 256) {
                                shouldBreak = true;
                                break;
                            }
                            if (
                                _COME2TOP_.tempTicketOwnership(
                                    currentGameID,
                                    uint8(ticketID)
                                ) != address(0)
                            ) ticketID++;
                            else {
                                tickets[1] = uint8(ticketID);
                                ticketID++;
                                break;
                            }
                        }
                    if (totalPlayerTickets < 2 && !shouldBreak)
                        while (true) {
                            if (ticketID == 256) {
                                shouldBreak = true;
                                break;
                            }
                            if (
                                _COME2TOP_.tempTicketOwnership(
                                    currentGameID,
                                    uint8(ticketID)
                                ) != address(0)
                            ) ticketID++;
                            else {
                                tickets[2] = uint8(ticketID);
                                ticketID++;
                                break;
                            }
                        }
                    if (totalPlayerTickets == 0 && !shouldBreak)
                        while (true) {
                            if (ticketID == 256) {
                                shouldBreak = true;
                                break;
                            }
                            if (
                                _COME2TOP_.tempTicketOwnership(
                                    currentGameID,
                                    uint8(ticketID)
                                ) != address(0)
                            ) ticketID++;
                            else {
                                tickets[3] = uint8(ticketID);
                                ticketID++;
                                break;
                            }
                        }

                    vmSafe.startBroadcast(_privateKeys_[totalPlayers]);
                    _COME2TOP_.ticketSaleOperation(tickets);
                    vmSafe.stopBroadcast();

                    if (firstEnter) {
                        firstEnter = false;
                        currentGameID++;
                    }

                    totalPlayers++;
                }
            }
    }
}
