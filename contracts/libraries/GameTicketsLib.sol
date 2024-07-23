// SPDX-License-Identifier: -- Come2Top --
pragma solidity 0.8.20;

import {GameStorageLib} from "./GameStorageLib.sol";

library SlicedBytedArray {
    /**
        @notice Retrieves a portion of a byte array.
        @dev Returns a portion of a byte array specified by the start and end indices.
        @param array The byte array from which the portion is being retrieved.
        @param from The start index of the portion to be retrieved.
        @param to The end index of the portion to be retrieved.
        @return bytes The portion of the byte array specified by the start and end indices.
    */
    function sliceBytedArray(
        bytes calldata array,
        uint256 from,
        uint256 to
    ) external pure returns (bytes memory) {
        return array[from:to];
    }
}

library GameTicketsLib {
    error ONLY_WINNER_TICKET(uint256 ticketID);

    /**
        @notice Returns the current value of a winning ticket in {FRAX} tokens.
        @dev Calculates and returns the current value of a ticket
            by dividing the initialFraxBalance of {FRAX} tokens in the contract
            by the total number of winning tickets.
        @return The current value of a winning ticket in {FRAX} tokens.
    */
    function ticketValue(uint256 totalTickets, uint256 gameID)
        internal
        view
        returns (uint256)
    {
        return
            GameStorageLib.gameStorage().gameData[gameID].virtualFraxBalance /
            totalTickets;
    }

    /**
        @dev Deletes a specific index from a byte array.
            It returns a new byte array excluding the element at the specified index.
        @param index The index to be deleted from the byte array.
        @param bytesArray The byte array from which the index will be deleted.
        @return The new byte array after deleting the specified index.
    */
    function deleteIndex(uint8 index, bytes memory bytesArray)
        internal
        pure
        returns (bytes memory)
    {
        return
            index != (bytesArray.length - 1)
                ? abi.encodePacked(
                    SlicedBytedArray.sliceBytedArray(bytesArray, 0, index),
                    SlicedBytedArray.sliceBytedArray(
                        bytesArray,
                        index + 1,
                        bytesArray.length
                    )
                )
                : SlicedBytedArray.sliceBytedArray(bytesArray, 0, index);
    }

    /**
        @dev Performs a linear search on the provided list of tickets
            to find a specific ticket ID.
        @param tickets The list of tickets to search within.
        @param ticketID The ticket ID to search for.
        @return bool True if the ticket ID is found in the list, false otherwise.
        @return uint8 The index of the found ticket ID in the list.
    */
    function findTicket(bytes memory tickets, uint8 ticketID)
        internal
        pure
        returns (bool, uint8)
    {
        uint256 i = tickets.length - 1;
        while (true) {
            if (uint8(tickets[i]) == ticketID) {
                return (true, uint8(i));
            }

            if (i == 0) break;
            unchecked {
                i--;
            }
        }

        return (false, 0);
    }

    /**
        @dev Shuffles a byte array by swapping elements based on a random seed value. 
            It iterates through the array and generates a random index to swap elements
            ensuring that the seed value influences the shuffling process.
            ( Modified version of Fisher-Yates Algo )
        @param array The byte array to be shuffled.
        @param randomSeed The random seed value used for shuffling.
        @param to The index until which shuffling should be performed.
        @return The shuffled byte array.
    */
    function shuffleBytedArray(
        bytes memory array,
        uint256 randomSeed,
        uint256 to
    ) internal pure returns (bytes memory) {
        uint256 i;
        uint256 j;
        uint256 n = array.length;
        while (i != n) {
            unchecked {
                j =
                    uint256(keccak256(abi.encodePacked(randomSeed, i))) %
                    (i + 1);
                (array[i], array[j]) = (array[j], array[i]);
                i++;
            }
        }

        return SlicedBytedArray.sliceBytedArray(array, 0, to);
    }

    /**
        @dev Performs a linear search on the provided list of tickets to find the specific ticket ID.
            If the ticket ID is not found in the list of tickets, the transaction will be reverted.
        @param tickets The list of tickets to search within.
        @param ticketID The ticket ID to search for.
        @return The index of the found ticket ID in the list.
    */
    function onlyWinnerTicket(bytes memory tickets, uint8 ticketID)
        internal
        pure
        returns (uint8)
    {
        (bool found, uint8 index) = findTicket(tickets, ticketID);
        if (!found) revert ONLY_WINNER_TICKET(ticketID);

        return index;
    }
}
