pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./StableCoin.sol";
import "./Market.sol";

struct IndexValue { uint keyIndex; uint value; }
struct KeyFlag { uint key; bool deleted; }

struct itmap {
    mapping(uint => IndexValue) data;
    KeyFlag[] keys;
    uint size;
}

library IterableMapping {
    function insert(itmap storage self, uint key, uint value) internal returns (bool replaced) {
        uint keyIndex = self.data[key].keyIndex;
        self.data[key].value = value;
        if (keyIndex > 0)
            return true;
        else {
            keyIndex = self.keys.length;
            self.keys.push();
            self.data[key].keyIndex = keyIndex + 1;
            self.keys[keyIndex].key = key;
            self.size++;
            return false;
        }
    }

    function remove(itmap storage self, uint key) internal returns (bool success) {
        uint keyIndex = self.data[key].keyIndex;
        if (keyIndex == 0)
            return false;
        delete self.data[key];
        self.keys[keyIndex - 1].deleted = true;
        self.size --;
    }

    function contains(itmap storage self, uint key) internal view returns (bool) {
        return self.data[key].keyIndex > 0;
    }

    function iterate_start(itmap storage self) internal view returns (uint keyIndex) {
        return iterate_next(self, uint(-1));
    }

    function iterate_valid(itmap storage self, uint keyIndex) internal view returns (bool) {
        return keyIndex < self.keys.length;
    }

    function iterate_next(itmap storage self, uint keyIndex) internal view returns (uint r_keyIndex) {
        keyIndex++;
        while (keyIndex < self.keys.length && self.keys[keyIndex].deleted)
            keyIndex++;
        return keyIndex;
    }

    function iterate_get(itmap storage self, uint keyIndex) internal view returns (uint key, uint value) {
        key = self.keys[keyIndex].key;
        value = self.data[key].value;
    }
}

contract Funds {
    struct account {
        address investor;
        uint total;
        uint lockup;
        uint requested;
        bool exist;
    }

    struct Investor {
        uint idx;
        bool exist;
    }

    struct rent {
        address investor;
        uint amount;
    }

    struct iou {
        mapping (uint => rent) debt;
        mapping (address => Investor) investor;
        uint itemId;
        uint investorCnt;
        uint amount;
        bool active;
    }

    mapping (address => uint) investor;
    mapping (uint => account) pool;
    uint investorCnt;

    mapping(uint => iou) IOU;
    uint iouCnt;

    mapping (uint => uint) item2iou;

    uint currentFlag;

    uint investRate;

    uint tax;

    // ?? 필요할라나?
    uint lockedAmount;
    uint totalAmount;
    // freeAmount로 합칠 수도 있음

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