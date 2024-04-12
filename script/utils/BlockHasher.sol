//  SPDX-License-Identifier: -- Come2Top --
pragma solidity 0.8.20;

contract BlockHasher {
    mapping(uint256 => bytes32) public blockHash;

    function setBlockHash(uint256 blockNo) external {
        blockHash[blockNo] = blockhash(blockNo);
    }
}
