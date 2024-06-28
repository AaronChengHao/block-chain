// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ITest {
    function val() external view returns (uint256);
    function test() external ;
}


// contract Callback{
//     uint256 public val;
//     fallback() external  {
//         val = ITest(msg.sender).val();
//      }

//      function test(address target) external  {
//         ITest(target).test();
//      }
// }

// contract TestStorage{
//     uint256 public  val;

//     function test() public {
//         val = 132;
//         bytes memory b = "";
//         msg.sender.call(b);
//     }
// }

// contract TestTransientStorage{
//     bytes32 constant SLOT = 0;

//     function test() public {
//         assembly{
//             tstore(SLOT,312)
//         }
//         bytes memory b = "";
//         msg.sender.call(b);
//     }

//     function val() public  view returns (uint256 v){
//         assembly{
//             v := tload(SLOT)
//         }
//     }
// }

// contract ReentrancyGuard{
//     bool private locked;

//     modifier lock(){
//         require(!locked);
//         locked = true;
//         _;
//         locked = false;
//     }
// }

// contract ReentrancyGuardTransient{
//     bytes32 constant SLOT = 0;
//     modifier lock(){
//       assembly {
//             if tload(SLOT) { revert(0, 0) }
//             tstore(SLOT, 1)
//         }
//         _;
//         assembly {
//             tstore(SLOT, 0)
//         }
//     }

//     function test() external lock{
//         // ignore call  error
//         bytes memory b = "";
//         msg.sender.call(b);
//     }
// }