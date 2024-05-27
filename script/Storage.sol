// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IFRAX} from "../test/interface/IFRAX.sol";
import {ICome2Top} from "../test/interface/ICome2Top.sol";

abstract contract Storage {
    IFRAX constant internal _frax_ = IFRAX(0x5c44535db05EfF9c84E89278Ee32BAbDC7EfB6cA);
    ICome2Top constant internal _come2top_ = ICome2Top(0x87be7A58D8a32dC69f32349D7342a94A0453952c);
    uint256[] internal _privateKeys_ = [
        0x7fc66c1f98a1cc8355601f5620e44328d3c7a4eff2cbf37d3705832e697c79a4,
        0x249b1b58b770c5a26cbedbd78f15d2c2784bccaf4833b7e895603a4397567297,
        0xcb5fa76798251b9668c245861a6a029e71997cc1bbaa70cab2b69c3ec9818368,
        0x815d532329332e522a2e3d1a911011e98b0f38dadc01104784402c21abd1d9a3,
        0x807c32089dc51373809babf4726f32c131c56690115e2182a37ad0e80d87cf44,
        0x9d8523ae6525beef8b8713af8262c8330807882b438b2aab3f39f494710c467b,
        0x25cc257e1dcb2297b0d75b77a1762750fef6144a3948d1046115adc3c8efa949,
        0x5392a9738ba621c7e30c7e6909676227a79e62a14db050d98c7fc9b1b1d3379a,
        0x0cb35711e535daae121cdd7f560618406cc3524858cf3c7a32bea0e14b994e16,
        0x7790d36ce1b2cacb9731e19f7f388bc713578de5f6bb63914dfec7167546a02e,
        0xaf51bf22d875fe091ea6903a5f40b34e0661717e3f008bbc497863b1d91bd68a,
        0x295fc8c45303d06a2dc2402469f16c64a1dc30a324999c8be5dfb65269ea2192,
        0xb2bc61a06cb80230d8c55196ef122f4adc0bdfc37155dc0d017a60742b6e6394,
        0x271fb8c0ffa639e57b0115c89623656856401631e0a458e08520a3c147bb0234,
        0xf1bb3e441bb37d3faf9916555371836b510869f50cb6766368abdec75a855e73,
        0xbf599b08529af9e2ff23831e8d8d4a1257e5d869fc094b6ca2a93cab40ce1a15,
        0xc80c01ab86e9fe2be80faca68d7a406aa9337cdf4de394937f2bd0c755c743f1,
        0xcb68f5e7d83c6f6ea384f67c710986b67743ea6caa43d52b74202b908c005342,
        0xeb54de9d4ca61029207ac03d70ce926238100d246689727017e1e79a5d2e37ea,
        0x9d54b87af020aa470ba4f0e8e94ece846341af55d475a166adc854bc019baa3b,
        0x452cd676cee7233416bfa2c0d315283348fdf81307e434a57d54c5b687a471bd,
        0xfaeacfe773fe81407b185eaac5ba32787cdb08adf7973d802b806cb192c48d50,
        0x93293cc2a3423e19c38565cfeadc3f38b889c2bad8287d523c43b3538ad4546b,
        0x1cde2a64df17a157f3e9e2db55642ec20da7d77f99b0569a60dee57457ab1ad1,
        0x10842cbcbd4dccdfc69191ea17ba799d0cc6ec228eb7538cb36bac4c0719310a,
        0x462677608b80a0e1c03f46a9259d13a69811ba8a5c80f2af89f4bb33be9dd3e7,
        0xb039a6aaba3e9799ba9fa0576547f145e44b74050881b7cd347e52977cf81ee0,
        0x0f3dc150774a0557d62299d96f1e67effb153b2928f8ef040f5f9404bfaff005,
        0xa1924511930e65657e9eced4882cf33b3f9b6e2c4068b501461d737478fb9750,
        0xfaad9817be3cf5d6346eeb2037061498128ecf7a7a1a7d33f88f11c8b4130056,
        0x30af0083c767c5dea76de4d25c6cd59c22267606edfd4424d460dccc2847d485,
        0xa176a843b4a1bc44ddbe2fd1174df0ecf6d9e9e361c62a5fbfdff24d99f453ea,
        0xe4822e4286bc564214c6c3142f569c6345fb2d154665bbf5ef1e0ff63323e1ad,
        0xcab3b03f56528790d43981ede687235cce83e8ac2bfc1fb5e413047b03b6c53f,
        0xeddd7c5e1e1c9f60d53ffd134e7b22d28db92f7484375d9d22851ce5bdb08294,
        0xcbea560097289f4d2fef16b6cf75cb4a548475dcdfbfb16c581cf606c5acad7e,
        0x25773fa596af0575bf98ae67e4dcff8cd00f86f9607c9734c57742b3380aabec,
        0xe582d6a0465330790b7a90573d8d607fb24a8010bec7d9d290f7825d44bce501,
        0x3374da8a4e21060b3c483417b481bdaca3e2a3bfe60fbe29756431a1800672ab,
        0x91952209101ad589eba35dca275d4c708dd34472c9cf5d22198866d985509eef,
        0xd04d83d25d1667e3080fdf66252cc0142cc058ffb0096a317384063c6765abd7,
        0x5a008a6c1aff0be238a8bb7811c7db344b706336f85172716dcf969372864c97,
        0x4213278f254c6dd3fc4cfe1dd336678a655070baebe638954a57c4415ae03fec,
        0x7cebc090e11090c06955bb4784ec9c307f4edb24c0700120b8bc8cbbe1980411,
        0x219809d1f4c40e038bdd85cee36476a0fa2e01b1be0862fe983d848a57d42991,
        0x59c71ae547e5d2e0349116970dfb2b83fdaecb39605eb6e185dfd288f4f11c2c,
        0xb02ebd7b9be0184208ee64cea13667a81ac77dbe0b0d09cc994a661bd0cb3f96,
        0x7cb634b2bedb44db7531b6a48e6256f32498a18eef11558a0e4c656ae42356de,
        0xe5b4b9a571cbdb6ad219a188a1b462fdf66f3a8445f68e025e525b1716690dfc,
        0xbe788bb1c77d9274405961480296c4ecd84c18560cba97b038f229d279187ec4,
        0x6ae5850ef6796d172004b9d44dd7a4fa815c6359c03dc2d817a4882fec89eec2,
        0x162dfd90bd860a867ed62207c1b7b32fa525e4c148b80b6cf41abd180df14f50,
        0xda9432e52f1ae0251e9016e424f4acf8b6bde7211adada6ab6444ab721ec8570,
        0x7a3b024cc570e55cae69994cca5d823ce5ef750c8bbf1b9aad153387231a2cb6,
        0x6a114a3006721f73bc0d948288ac7295cca162ca7f3af013a01c78d270e30fef,
        0x079c1bd0d76e5cceb9a8b2cbbdabbabb37caba058caa508f8b2063da1ceea54d,
        0x227121420cb314ff6a8d2493dbbc550b11e65fb507e9c33f62fd609a3521fbb2,
        0x1bf68f872be028d55fd01979d14d93201628d3f7540642b81ca275cdd9c0e3ec,
        0x125d156e2f5a1258ae84c43e32031e4bf9c7d329148468de8389570819e325b5,
        0x342c3ff7abcdced8e9d4ab23e50e85cfa9cbca30e5851cf2527dcbb6009e88d5,
        0x6ac74df46661b8f8706e707751f75aa8fe27d79301301db30d92ff7923e826be,
        0xd34ac2351180e52cb040841c54107352c2d07cee105e42f21ec1480bc2f04f9d,
        0xe2324dad1878778787e5438c31424d708a74319089476fa7bca809e3c1db302d,
        0xabeb7df5fbf9895575b417c37555801fa5cc7d92aea1fc48358ebeae90e91460
    ];
}
