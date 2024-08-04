// SPDX-License-Identifier: -- Come2Top --
pragma solidity 0.8.20;

library GameConstantsLib {
    function BYTE_TICKETS() internal pure returns (bytes memory) {
        return
            hex"000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedfe0e1e2e3e4e5e6e7e8e9eaebecedeeeff0f1f2f3f4f5f6f7f8f9fafbfcfdfeff";
    }

    // Mainnet
    /* function MIN_TICKET_PRICE() internal pure returns(uint256) {
        return 1e19;
    } */
    // Testnet
    function MIN_TICKET_PRICE() internal pure returns (uint256) {
        return 1e20;
    }

    function MAX_PARTIES() internal pure returns (uint256) {
        return 256;
    }

    // Mainnet
    /* function WAVE_ELIGIBLES_TIME() internal pure returns (uint256) {
        return 144;
    } */
    // Testnet
    function WAVE_ELIGIBLES_TIME() internal pure returns (uint256) {
        return 24;
    }

    // Mainnet
    /* function SAFTY_DURATION() internal pure returns (uint256) {
        return 48;
    } */
    // Testnet
    function SAFTY_DURATION() internal pure returns (uint256) {
        return 10;
    }

    function MIN_PRNG_PERIOD() internal pure returns (uint256) {
        return 12;
    }

    function BASIS() internal pure returns (uint256) {
        return 100;
    }

    function MIN_TICKET_VALUE_OFFER() internal pure returns (uint256) {
        return 10;
    }

    // Mainnet - l1 avg block time ˜12.5
    /* function L1_BLOCK_LOCK_TIME() internal pure returns (uint256) {
        return 207692;
    } */
    // Testnet
    function L1_BLOCK_LOCK_TIME() internal pure returns (uint256) {
        return 50;
    }

    function ZERO_ADDRESS() internal pure returns (address) {
        return address(0x0);
    }
}
