// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC173} from "../../interfaces/IERC173.sol";

import {DiamondLib} from "../libraries/DiamondLib.sol";

contract OwnershipFacet is IERC173 {
    function transferOwnership(address newOwner) external {
        DiamondLib.enforceIsContractOwner();
        DiamondLib.setContractOwner(newOwner);
    }

    function owner() external view returns (address) {
        return DiamondLib.contractOwner();
    }
}
