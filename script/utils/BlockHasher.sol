//  SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

contract BlockHasher {
    mapping(uint256 => bytes32) public blockHash;

    function setBlockHash(uint256 blockNo) external {
        blockHash[blockNo] = blockhash(blockNo);
    }
}
