pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./StableCoin.sol";

contract Pool {
    mapping (address => uint256) Saving;

    // linking with other contracts
    address public addrWon;

    Won public WON;

    constructor (address Won) public {
        addrWon = Won;
    }

    function Save() public payable {
        Saving[msg.sender] = Saving[msg.sender] + msg.value;
    }

    function Withdraw(uint256 Amount) public {
        require(Saving[msg.sender] > Amount, "not enough saving");
        Saving[msg.sender] = Saving[msg.sender] - Amount;
        WON.transfer(msg.sender, Amount);
    }

    // function SplitProfit() payable {
        // msg.value
        //
    // }
}