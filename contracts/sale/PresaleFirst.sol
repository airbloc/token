pragma solidity ^0.4.19;

import "../zeppelin/token/ERC20/ERC20.sol";
import "../zeppelin/token/ERC20/SafeERC20.sol";
import "../zeppelin/math/SafeMath.sol";
import "../zeppelin/ownership/Whitelist.sol";
import "../zeppelin/lifecycle/Pausable.sol";
import "../token/ABL.sol";


contract PresaleFirst is Whitelist, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public maxcap;
    uint256 public exceed;
    uint256 public minimum;
    uint256 public rate;
    address public wallet;
    ERC20 public token;

    function PresaleFirst (
        uint256 _startTime,
        uint256 _endTime,
        uint256 _maxcap,
        uint256 _exceed,
        uint256 _minimum,
        address _wallet,
        address _token,
        uint256 _rate
        ) public {
        require(_wallet != address(0));
        require(_token != address(0));

        startTime = _startTime;
        endTime = _endTime;
        maxcap = _maxcap;
        exceed = _exceed;
        minimum = _minimum;
        wallet = _wallet;
        token = ERC20(_token);
        rate = _rate;
    }

//////////////////
//  collect eth
//////////////////

    struct Buyer {
        uint256 FundAmount;
        uint256 TokenAmount;
    }

    mapping (address => Buyer) public buyers;
    address[] public keys;


    function () public payable {
        collect(msg.sender);
    }

    function collect(address _buyer) public payable onlyWhitelisted whenNotPaused {
        require(_buyer != address(0));

        require(preValidation());

        uint256 refund;
        uint256 purchase;

        (refund, purchase) = getTokenAmount(_buyer);
        emit TokenAmount(_buyer, refund, purchase);

        // refund
        _buyer.transfer(refund);

        // buy
        uint256 tokenAmount = purchase.div(10000000000000000).mul(rate);
        maxcap = maxcap.sub(purchase);

        // wallet
        wallet.transfer(purchase);
        buyers[_buyer].FundAmount = buyers[_buyer].FundAmount.add(purchase);
        buyers[_buyer].TokenAmount = buyers[_buyer].TokenAmount.add(tokenAmount);
        emit BuyToken(_buyer, purchase, tokenAmount);
    }

//////////////////
//  validation functions for collect
//////////////////

    function preValidation() private constant returns (bool) {
        // check minimum
        bool a = msg.value >= minimum;

        // sale duration
        uint256 time = block.timestamp;
        bool b = time > startTime && time < endTime;

        return a && b;
    }

    function getTokenAmount(address _buyer) private returns (uint256, uint256) {
        uint256 cAmount = msg.value;
        uint256 bAmount = 0;
        uint256 pAmount = 0;

        // get exist amount
        if(buyers[_buyer].FundAmount != 0) {
            bAmount = buyers[_buyer].FundAmount;

            if(bAmount >= exceed){
                emit LogString("Buyer cannot purchase over exceed");
                revert();
            }
        } else {
            keys.push(_buyer);
        }

        if(cAmount >= exceed) {
            pAmount = exceed;
        }

        // 1. check indivisual hardcap
        if(cAmount.add(bAmount) > exceed) {
            pAmount = exceed.sub(bAmount);
        } else {
            pAmount = cAmount;
        }

        // 2. check sale hardcap
        if(pAmount >= maxcap) {
            pAmount = maxcap;
        }

        return (cAmount.sub(pAmount), pAmount);
    }

//////////////////
//  once
//////////////////

    bool once = false;

    modifier onlyOnce() {
        require(!once);
        _;
    }

//////////////////
//  release
//////////////////

    function release() public onlyOwner onlyOnce {
        require(block.timestamp > endTime);
        once = true;

        for(uint256 i = 0; i < keys.length; i++) {
            token.safeTransfer(keys[i], buyers[keys[i]].TokenAmount);
            emit Release(keys[i], buyers[keys[i]].TokenAmount);
        }
    }

    // TODO : withdraw 만들기

//////////////////
//  events
//////////////////

    event LogAddress(address msg);
    event LogString(string msg);
    event LogUint(uint256 msg);
    event TokenAmount(address buyer, uint256 refund, uint256 purchase);
    event Release(address buyer, uint256 amount);
    event BuyToken(address buyer, uint256 price, uint256 tokens);
}
