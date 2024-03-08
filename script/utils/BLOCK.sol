//  SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

contract BLOCK {
    function getBlockHash(uint256 blockNo) external view returns(bytes32) {
        return blockhash(blockNo);
    }
}