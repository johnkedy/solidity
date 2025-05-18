 /// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

//import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
//import "./PriceConverter.sol";

//error NotOwner();

contract FundMe {
    
    //Set Minimum usdt to be recieved as 50.
    uint256 public miniusdt = 50;

    //create fundme function and call it fundMe, visibility should be public, type should be payable.
    function funcdMe() public payable {
        //How do we send ether to this contract?
        //Make sure that balance is equal to or greater than the minimum deposit.
        require(msg.value >= miniusdt, "Not enough fund");
    }
    // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \ 
    //         yes  no
    //         /     \
    //    receive()?  fallback() 
    //     /   \ 
    //   yes   no
    //  /        \
    //receive()  fallback()

    
}

// Concepts we didn't cover yet (will cover in later sections)
// 1. Enum
// 2. Events
// 3. Try / Catch
// 4. Function Selector
// 5. abi.encode / decode
// 6. Hash with keccak256
// 7. Yul / Assembly

