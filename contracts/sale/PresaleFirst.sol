pragma solidity ^0.4.19;

import "zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "zeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/ownership/Whitelist.sol";
import "zeppelin-solidity/contracts/lifecycle/Pausable.sol";
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

    uint256 public weiRaised;
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

        require(_maxcap == 1500 ether);
        require(_exceed == 300 ether);
        require(_minimum == 0.5 ether);
        require(_rate == 11500);

        startTime = _startTime;
        endTime = _endTime;
        maxcap = _maxcap;
        exceed = _exceed;
        minimum = _minimum;
        wallet = _wallet;
        token = ERC20(_token);
        rate = _rate;
        weiRaised = 0;
    }

//////////////////
//  collect eth
//////////////////
    mapping (address => uint256) public buyers;
    address[] private keys;

    function () external payable {
        collect(msg.sender);
    }

    function collect(address _buyer) public payable onlyWhitelisted whenNotPaused {
        require(_buyer != address(0));
        require(weiRaised <= maxcap);
        require(preValidation());
        require(buyers[_buyer] < exceed);

        // get exist amount
        if(buyers[_buyer] == 0) {
            keys.push(_buyer);
        }

        uint256 purchase = getPurchaseAmount(_buyer);
        uint256 refund = msg.value.sub(purchase);

        // refund
        _buyer.transfer(refund);

        // buy
        uint256 tokenAmount = purchase.mul(rate);
        maxcap = maxcap.sub(purchase);

        // wallet
        buyers[_buyer] = buyers[_buyer].add(purchase);
        emit BuyTokens(_buyer, purchase, tokenAmount);
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

    function getPurchaseAmount(address _buyer) private constant returns (uint256) {
        return checkOverMaxcap(checkOverExceed(_buyer));
    }

    // 1. check over exceed
    function checkOverExceed(address _buyer) private constant returns (uint256) {
        if(msg.value >= exceed) {
            return exceed;
        } else if(msg.value.add(buyers[_buyer]) > exceed) {
            return exceed.sub(buyers[_buyer]);
        } else {
            return msg.value;
        }
    }

    // 2. check sale hardcap
    function checkOverMaxcap(uint256 amount) private constant returns (uint256) {
        if((amount + weiRaised) >= maxcap) {
            return (maxcap.sub(weiRaised));
        } else {
            return amount;
        }
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

    // TODO : change block.timestamp to number
    function release() external onlyOwner onlyOnce {
        require(block.timestamp > endTime);
        once = true;

        wallet.transfer(address(this).balance);

        for(uint256 i = 0; i < keys.length; i++) {
            token.safeTransfer(keys[i], buyers[keys[i]].mul(rate));
            emit Release(keys[i], buyers[keys[i]].mul(rate));
        }
    }

    // TODO : withdraw 만들기
    function withdraw() external onlyOwner {
        token.safeTransfer(wallet, token.balanceOf(this));
        emit Withdraw(wallet, token.balanceOf(this));
    }

    function refund() external onlyOwner {
        for(uint256 i = 0; i < keys.length; i++) {
            keys[i].transfer(buyers[keys[i]]);
            emit Refund(keys[i], buyers[keys[i]].mul(rate));
        }
    }

//////////////////
//  events
//////////////////

    event Release(address indexed _to, uint256 _amount);
    event Withdraw(address indexed _from, uint256 _amount);
    event Refund(address indexed _to, uint256 _amount);
    event BuyTokens(address indexed buyer, uint256 price, uint256 tokens);
}
