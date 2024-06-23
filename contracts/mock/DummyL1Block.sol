//  SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IFraxtalL1Block} from "../interfaces/IFraxtalL1Block.sol";

contract DummyL1Block is IFraxtalL1Block {
    IFraxtalL1Block private constant FraxtalL1Block =
        IFraxtalL1Block(0x4200000000000000000000000000000000000015);

    function number() external view returns (uint64) {
        return uint64(FraxtalL1Block.number());
    }

    function numberToRandao(uint64 number_) external view returns (uint256) {
        bytes32 dummyFakeRandao;

        unchecked {
            dummyFakeRandao = keccak256(abi.encode(number_ * block.chainid));
        }

        return uint256(dummyFakeRandao);
    }
}
