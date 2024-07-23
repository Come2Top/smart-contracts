// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC165} from "../interfaces/IERC165.sol";
import {IERC173} from "../interfaces/IERC173.sol";
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";

library DiamondLib {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint16 functionSelectorPosition;
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint16 facetAddressPosition;
    }

    struct DiamondStorage {
        address contractOwner;
        address[] facetAddresses;
        mapping(bytes4 => bool) supportedInterfaces;
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event DiamondCut(IDiamondCut.FacetCut[] dc, address init, bytes cd);

    function setContractOwner(address newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;

        ds.contractOwner = newOwner;

        emit OwnershipTransferred(previousOwner, newOwner);
    }

    function diamondCut(
        IDiamondCut.FacetCut[] memory dc,
        address init,
        bytes memory cd
    ) internal {
        for (uint256 facetIndex; facetIndex < dc.length; ) {
            IDiamondCut.FacetCutAction action = dc[facetIndex].action;

            if (action == IDiamondCut.FacetCutAction.Add)
                addFunctions(
                    dc[facetIndex].facetAddress,
                    dc[facetIndex].functionSelectors
                );
            else if (action == IDiamondCut.FacetCutAction.Replace)
                replaceFunctions(
                    dc[facetIndex].facetAddress,
                    dc[facetIndex].functionSelectors
                );
            else
                removeFunctions(
                    dc[facetIndex].facetAddress,
                    dc[facetIndex].functionSelectors
                );

            unchecked {
                facetIndex++;
            }
        }

        emit DiamondCut(dc, init, cd);
    }

    function addDiamondFunctions(
        address diamondCutFacet,
        address diamondLoupeFacet,
        address ownershipFacet
    ) internal {
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](3);
        bytes4[] memory functionSelectors = new bytes4[](1);

        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });

        functionSelectors = new bytes4[](5);
        functionSelectors[0] = IDiamondLoupe.facets.selector;
        functionSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        functionSelectors[2] = IDiamondLoupe.facetAddresses.selector;
        functionSelectors[3] = IDiamondLoupe.facetAddress.selector;
        functionSelectors[4] = IERC165.supportsInterface.selector;
        cut[1] = IDiamondCut.FacetCut({
            facetAddress: diamondLoupeFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });

        functionSelectors = new bytes4[](2);
        functionSelectors[0] = IERC173.transferOwnership.selector;
        functionSelectors[1] = IERC173.owner.selector;
        cut[2] = IDiamondCut.FacetCut({
            facetAddress: ownershipFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });

        diamondCut(cut, address(0), "");
    }

    function addFunctions(
        address facetAddress,
        bytes4[] memory functionSelectors
    ) private {
        require(
            functionSelectors.length > 0,
            "DiamondLib: No selectors in facet to cut"
        );
        require(
            facetAddress != address(0),
            "DiamondLib: Add facet can't be address(0)"
        );

        DiamondStorage storage ds = diamondStorage();
        uint16 selectorPosition = uint16(
            ds.facetFunctionSelectors[facetAddress].functionSelectors.length
        );

        if (selectorPosition == 0) {
            enforceHasContractCode(
                facetAddress,
                "DiamondLib: New facet has no code"
            );

            ds
                .facetFunctionSelectors[facetAddress]
                .facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(facetAddress);
        }

        for (
            uint256 selectorIndex;
            selectorIndex < functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = functionSelectors[selectorIndex];

            require(
                ds.selectorToFacetAndPosition[selector].facetAddress ==
                    address(0),
                "DiamondLib: Can't add function that already exists"
            );

            ds.facetFunctionSelectors[facetAddress].functionSelectors.push(
                selector
            );
            ds.selectorToFacetAndPosition[selector].facetAddress = facetAddress;
            ds
                .selectorToFacetAndPosition[selector]
                .functionSelectorPosition = selectorPosition;
            selectorPosition++;
        }
    }

    function replaceFunctions(
        address facetAddress,
        bytes4[] memory functionSelectors
    ) private {
        DiamondStorage storage ds = diamondStorage();

        require(
            functionSelectors.length > 0,
            "DiamondLib: No selectors in facet to cut"
        );
        require(
            facetAddress != address(0),
            "DiamondLib: Add facet can't be address(0)"
        );

        uint16 selectorPosition = uint16(
            ds.facetFunctionSelectors[facetAddress].functionSelectors.length
        );

        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(
                facetAddress,
                "DiamondLib: New facet has no code"
            );

            ds
                .facetFunctionSelectors[facetAddress]
                .facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;

            require(
                oldFacetAddress != facetAddress,
                "DiamondLib: Can't replace function with same function"
            );

            removeFunction(oldFacetAddress, selector);

            ds
                .selectorToFacetAndPosition[selector]
                .functionSelectorPosition = selectorPosition;
            ds.facetFunctionSelectors[facetAddress].functionSelectors.push(
                selector
            );
            ds.selectorToFacetAndPosition[selector].facetAddress = facetAddress;
            selectorPosition++;
        }
    }

    function removeFunctions(
        address facetAddress,
        bytes4[] memory functionSelectors
    ) private {
        require(
            functionSelectors.length > 0,
            "DiamondLib: No selectors in facet to cut"
        );
        require(
            facetAddress == address(0),
            "DiamondLib: Remove facet address must be address(0)"
        );

        DiamondStorage storage ds = diamondStorage();

        for (
            uint256 selectorIndex;
            selectorIndex < functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;

            removeFunction(oldFacetAddress, selector);
        }
    }

    function removeFunction(address facetAddress, bytes4 selector) private {
        require(
            facetAddress != address(0),
            "DiamondLib: Can't remove function that doesn't exist"
        );
        require(
            facetAddress != address(this),
            "DiamondLib: Can't remove immutable function"
        );

        DiamondStorage storage ds = diamondStorage();

        uint256 selectorPosition = ds
            .selectorToFacetAndPosition[selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .facetFunctionSelectors[facetAddress]
            .functionSelectors
            .length - 1;

        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds
                .facetFunctionSelectors[facetAddress]
                .functionSelectors[lastSelectorPosition];

            ds.facetFunctionSelectors[facetAddress].functionSelectors[
                selectorPosition
            ] = lastSelector;
            ds
                .selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint16(selectorPosition);
        }

        ds.facetFunctionSelectors[facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[selector];

        if (lastSelectorPosition == 0) {
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds
                .facetFunctionSelectors[facetAddress]
                .facetAddressPosition;

            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[
                    lastFacetAddressPosition
                ];

                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds
                    .facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = uint16(facetAddressPosition);
            }

            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[facetAddress].facetAddressPosition;
        }
    }

    function contractOwner() internal view returns (address) {
        return diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(
            tx.origin == diamondStorage().contractOwner,
            "DiamondLib: Must be contract owner"
        );
    }

    function enforceHasContractCode(
        address smartContract,
        string memory errorMessage
    ) internal view {
        uint256 contractSize;

        assembly {
            contractSize := extcodesize(smartContract)
        }

        require(contractSize != 0, errorMessage);
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;

        assembly {
            ds.slot := position
        }
    }
}
