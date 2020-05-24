pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./StableCoin.sol";
import "./Market.sol";

contract Funds {
    struct Account {
//        uint index;
        uint total;
        uint lockup;
        bool active;
        bool exist;
    }

    struct Fund {
        mapping (address => Account) account;
        address[] addr;
        uint size;
        uint taxRate;
        uint investRate;
        uint currentFlag;
    }
    Fund fund;

    struct Contribution {
        uint amount;
        bool exist;
    }

    struct IOU {
        uint amount;
        mapping (address => Contribution) contribution;
        address[] addr;
        bool active;
    }
    IOU newIOU;

    mapping (uint => IOU) ious; //itemId => IOU

    address owner;

    // linking with other contracts
    address public addrWon;
    address public addrMarket;
    Market public market;

    constructor (address Won) public {
        owner = msg.sender;
        addrWon = Won;
        fund.currentFlag = 0;
        fund.taxRate = 10;
        fund.addr = new address[](0);
        fund.addr.push(address(this));
        fund.account[address(this)] = Account(0, 0, true, true);
        fund.investRate = 1;
    }

    function setMarket(address Market) public {
        require(msg.sender == owner, "only owner can set market");

        addrMarket = Market;
    }

//    function getIOU(uint itemId) public view returns (IOU memory){
//        return ious[itemId];
//    }

    function concat(string memory _a, string memory _b) public pure returns (string memory){
        bytes memory bytes_a = bytes(_a);
        bytes memory bytes_b = bytes(_b);
        string memory length_ab = new string(bytes_a.length + bytes_b.length);
        bytes memory bytes_c = bytes(length_ab);
        uint k = 0;
        for (uint i = 0; i < bytes_a.length; i++) bytes_c[k++] = bytes_a[i];
        for (uint i = 0; i < bytes_b.length; i++) bytes_c[k++] = bytes_b[i];
        return string(bytes_c);
    }

    function uint2str(uint _i) public pure returns (string memory) {
        uint i = _i;
        if (i == 0) {
            return "0";
        }
        uint j = i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0) {
            bstr[k--] = byte(uint8(48 + i % 10));
            i /= 10;
        }
        return string(bstr);
    }

    function addressToString(address x) public pure returns (string memory) {
        bytes memory b = new bytes(20);
        for (uint i = 0; i < 20; i++)
            b[i] = byte(uint8(uint(x) / (2**(8*(19 - i)))));
        return string(b);
    }

    function getIOU(uint itemId) public view returns (string memory) {
        string memory ret = "";

        ret = concat(ret, "{");
        ret = concat(ret, "\"amount\"");
        ret = concat(ret, ":");
        ret = concat(ret, uint2str(ious[itemId].amount));
        ret = concat(ret, ",");

        ret = concat(ret, "\"contribution\"");
        ret = concat(ret, ":");
        ret = concat(ret, "[");
        for(uint i = 0 ; i < ious[itemId].addr.length ; i++) {
            ret = concat(ret, addressToString(ious[itemId].addr[i]));
            ret = concat(ret, ":");
            ret = concat(ret, uint2str(ious[itemId].contribution[ious[itemId].addr[i]].amount));
            if (i+1 != ious[itemId].addr.length) {
                ret = concat(ret, ",");
            }
        }
        ret = concat(ret, "]");
        ret = concat(ret, ",");

        ret = concat(ret, "\"active\"");
        ret = concat(ret, ":");
        if(ious[itemId].active)
            ret = concat(ret, "true");
        else
            ret = concat(ret, "false");

        ret = concat(ret, "}");

        return ret;
    }

    function requestDeposit(uint itemId, uint amount) public {
//        address[] memory addr;
//        IOU memory newIOU = IOU({amount:amount, addr:addr, active:true});
        newIOU = IOU({amount: 0,
            addr: new address[](0),
            active:true
        });
//        IOU memory newIOU = IOU({amount:amount, addr:new address[](0), active:true});
        uint i = 0;
        while(newIOU.amount < amount) {
            if(!fund.account[fund.addr[i]].active) {
                if (i < fund.size) i++;
                else i = 0;

                continue;
            }
            uint investAmount = (fund.account[fund.addr[i]].total - fund.account[fund.addr[i]].lockup)*(fund.investRate/100);
            if (amount < newIOU.amount + investAmount) {
                investAmount = amount - newIOU.amount;
            }

            // 새로운 contributor 추가
            if(!(newIOU.contribution[fund.addr[i]].exist)) {
                newIOU.addr.push(fund.addr[i]);
                newIOU.contribution[fund.addr[i]] = Contribution({amount:0, exist:true});
            }

            newIOU.contribution[fund.addr[i]].amount += investAmount;

            newIOU.amount += investAmount;
            fund.account[fund.addr[i]].lockup += investAmount;

            fund.currentFlag = i;

            if (i < fund.size) i++;
            else i = 0;
        }
        ious[itemId] = newIOU;

        Won won = Won(addrWon);
        won.transfer(addrMarket, amount);
    }

    function cancelIOU(uint itemId, uint fee) public {
        Won won = Won(addrWon);
        won.transferFrom(addrMarket, address(this), (ious[itemId].amount * (100+fee))/100);

        uint taxRate = 0;
        if (won.balanceOf(address(this)) / 5 > fund.account[address(this)].total) {
            taxRate = fund.taxRate;
        }

        for (uint i = 0 ; i < ious[itemId].addr.length ; i++) {
            fund.account[ious[itemId].addr[i]].lockup -= ious[itemId].contribution[ious[itemId].addr[i]].amount;
            uint profit = (ious[itemId].contribution[ious[itemId].addr[i]].amount*fee)/100;
            fund.account[ious[itemId].addr[i]].total += (profit*(100-taxRate))/100;
            fund.account[address(this)].total += (profit*taxRate)/100;
        }
        ious[itemId].active = false;
    }

    function regenerateIOU(uint itemId) public {
        require((fund.account[address(this)].total - fund.account[address(this)].lockup) >= ious[itemId].amount/2, "not enough fund amount");
        Won won = Won(addrWon);
        won.transferFrom(addrMarket, address(this), ious[itemId].amount/2);

        for (uint i = 0 ; i < ious[itemId].addr.length ; i++) {
            fund.account[ious[itemId].addr[i]].lockup -= ious[itemId].contribution[ious[itemId].addr[i]].amount;
        }

        // 새로운 contributor 추가
        for(uint i = 0 ; i < ious[itemId].addr.length; i++){
           delete ious[itemId].addr[i];
        }

        ious[itemId].addr.push(addrMarket);
        ious[itemId].contribution[addrMarket] = Contribution({amount:ious[itemId].amount/2, exist:true});
        ious[itemId].amount = ious[itemId].amount/2;
        fund.account[address(this)].lockup += ious[itemId].amount;
    }

    function cancelIOU(uint itemId) public {
        Won won = Won(addrWon);
        won.transferFrom(addrMarket, address(this), ious[itemId].amount);

        for (uint i = 0 ; i < ious[itemId].addr.length ; i++) {
            fund.account[ious[itemId].addr[i]].lockup -= ious[itemId].contribution[ious[itemId].addr[i]].amount;
        }
        ious[itemId].active = false;
    }

    function save(uint amount) public {
        Won won = Won(addrWon);
        won.transferFrom(msg.sender,address(this), amount);
        if (msg.sender == owner) {
            fund.account[address(this)].total += amount;
        }
        else if (fund.account[msg.sender].exist) {
            fund.account[msg.sender].total += amount;
        }
        else {
            fund.account[msg.sender] = Account(amount, 0, true, true);
            fund.addr.push(msg.sender);
            fund.size++;
        }
    }

    function withdraw(uint amount) public {
        require(fund.account[msg.sender].total - fund.account[msg.sender].lockup >= amount, "withdraw have to be smaller than saving amount");
        Won won = Won(addrWon);
        won.transfer(msg.sender, amount);
        fund.account[msg.sender].total -= amount;
    }

    function changeAccountStatus(bool activate) public {
        fund.account[msg.sender].active = activate;
    }
}