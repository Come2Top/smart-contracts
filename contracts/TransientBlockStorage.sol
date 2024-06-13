//  SPDX-License-Identifier: -- Come2Top --
pragma solidity 0.8.24;

contract TransientBlockStorage {
    error TBLOCK_404(uint256 number);

    function tstoreBlockRandao(uint256 number, uint256 randao) external {
        bytes32 slot = bytes32(number);
        assembly {
            tstore(slot, randao)
        }
    }

    function tloadBlockRandao(uint256 number) external view returns (uint256 randao) {
        bytes32 slot = bytes32(number);
        assembly {
            randao := tload(slot)
        }

        if(randao == 0) revert TBLOCK_404(number);
    }

    // function testSuccess() external {
    //     tstoreBlockRandao(1,1);
    //     tstoreBlockRandao(2,2);
    //     tstoreBlockRandao(3,3);
    //     tstoreBlockRandao(4,4);
    //     tstoreBlockRandao(5,5);
    //     tstoreBlockRandao(6,6);
    //     tstoreBlockRandao(7,7);
    //     tstoreBlockRandao(8,8);
    //     tstoreBlockRandao(9,9);
    //     tstoreBlockRandao(10,10);
    //     tstoreBlockRandao(11,11);
    //     tstoreBlockRandao(12,12);
    //     tstoreBlockRandao(13,13);
    //     tstoreBlockRandao(14,14);
    //     tstoreBlockRandao(15,15);
    //     tstoreBlockRandao(16,16);
    //     tstoreBlockRandao(17,17);
    //     tstoreBlockRandao(18,18);
    //     tstoreBlockRandao(19,19);
    //     tstoreBlockRandao(20,20);
    //     tstoreBlockRandao(21,21);
    //     tstoreBlockRandao(22,22);
    //     tstoreBlockRandao(23,23);
    //     tstoreBlockRandao(24,24);

    //     tloadBlockRandao(1);
    //     tloadBlockRandao(2);
    //     tloadBlockRandao(3);
    //     tloadBlockRandao(4);
    //     tloadBlockRandao(5);
    //     tloadBlockRandao(6);
    //     tloadBlockRandao(7);
    //     tloadBlockRandao(8);
    //     tloadBlockRandao(9);
    //     tloadBlockRandao(10);
    //     tloadBlockRandao(11);
    //     tloadBlockRandao(12);
    //     tloadBlockRandao(13);
    //     tloadBlockRandao(14);
    //     tloadBlockRandao(15);
    //     tloadBlockRandao(16);
    //     tloadBlockRandao(17);
    //     tloadBlockRandao(18);
    //     tloadBlockRandao(19);
    //     tloadBlockRandao(20);
    //     tloadBlockRandao(21);
    //     tloadBlockRandao(22);
    //     tloadBlockRandao(23);
    //     tloadBlockRandao(24);
    // }
}
