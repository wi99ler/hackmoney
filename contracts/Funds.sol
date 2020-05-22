pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./StableCoin.sol";
import "./Market.sol";

contract Funds {
    struct Account {
        uint index;
        uint total;
        uint lockup;
        bool active;
    }

    struct Fund {
        mapping (address => Account) account;
        address[] addr;
        uint size;
    }
    Fund fund;

    struct Contribution {
        uint index;
        uint amount;
    }

    struct IOU {
        mapping (address => Contribution) contribution;
        address[] addr;
        uint size;
        bool active;
    }
    mapping (uint => IOU) ious; //itemId => IOU

    // linking with other contracts
    address public addrWon;
    Won public won;

    address public addrMarket;
    Market public market;

    constructor (address Won) public {
        addrWon = Won;
        investorCnt = 0;
        currentFlag = 0;

        lockedAmount = 0;
        totalAmount = 0;

        iouCnt = 0;

        tax = 10;
    }

    function depositRequest(uint itemId, uint amount) public {
        iou memory newIOU = iou({itemId:itemId, investorCnt:0, amount:0, active:true});
        while(newIOU.amount < amount) {
            for(uint i=0 ; i<investorCnt ; i++) {
                uint investAmount = (pool[i].total - pool[i].lockup - pool[i].requested)*(investRate/100);
                if (amount < newIOU.amount + investAmount) {
                    investAmount = amount - newIOU.amount;
                }

                if(!newIOU.investor[pool[i].investor].exist) {
                    newIOU.debt[newIOU.investorCnt].investor = pool[i].investor;

                    newIOU.investor[pool[i].investor] = new Investor(newIOU.investorCnt, true);
                    newIOU.investorCnt++;
                }

                newIOU.debt[newIOU.investor[pool[i].investor].investor].amount += investAmount;

                newIOU.amount += investAmount;
                pool[i].lockup += investAmount;

                currentFlag = i;
            }
        }
        IOU[iouCnt] = newIOU;
        item2iou[itemId] = iouCnt;
        iouCnt++;

        won.transfer(addrMarket, amount);
    }

    function refundDeposit(uint itemId) public {
        uint iouId = item2iou[itemId];
        won.transferFrom(addrMarket, address(this), (IOU[iouId].amount * (100+market.getFee()))/100);

        iou memory fund = IOU[iouId];
        for (uint i=0 ; i< iou.investorCnt ; i++) {
            pool[investor[fund.debt[i].investor]].lockup -= fund.debt[i].amount;
            uint profit = (fund.debt[i].amount*market.getFee())/100;
            pool[investor[fund.debt[i].investor]].total += (profit*(100-tax))/100;//
        }
        IOU[iouId].active = false;
    }

    function save(uint amount) public {
        won.transferFrom(msg.sender, address(this), amount);
        if (pool[investor[msg.sender]].exist) {
            pool[investor[msg.sender]].total = pool[investor[msg.sender]].total + amount;
        }
        else {
            investor[msg.sender] = investorCnt;
            pool[investor[msg.sender]] = account(msg.sender, pool[investor[msg.sender]].total + amount, 0, 0, true);
            investorCnt++;
        }
    }

    function withdraw(uint256 amount) public {
        require(pool[investor[msg.sender]].total <= amount, "withdraw have to be smaller than saving amount");
        if (pool[investor[msg.sender]].total - pool[investor[msg.sender]].lockup > amount) {
            won.transfer(msg.sender, amount);
            pool[investor[msg.sender]].total -= amount;
        }
        else {
            uint withdrawAmount = pool[investor[msg.sender]].total - pool[investor[msg.sender]].lockup;
            won.transfer(msg.sender, withdrawAmount);
            pool[investor[msg.sender]].total = 0;
            pool[investor[msg.sender]].requested = amount - withdrawAmount;
        }
    }

    // function SplitProfit() payable {
        // msg.value
        //
    // }
}