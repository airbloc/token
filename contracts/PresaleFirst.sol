pragma solidity ^0.4.19;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Whitelist.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";


contract PresaleFirst is Whitelist, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    uint256 public constant maxcap = 1500 ether;
    uint256 public constant exceed = 300 ether;
    uint256 public constant minimum = 0.5 ether;
    uint256 public constant rate = 11500;

    uint256 public startNumber;
    uint256 public endNumber;
    uint256 public weiRaised;
    address public wallet;
    ERC20 public token;

    function PresaleFirst (
        uint256 _startNumber,
        uint256 _endNumber,
        address _wallet,
        address _token
        ) public {
        require(_wallet != address(0));
        require(_token != address(0));

        startNumber = _startNumber;
        endNumber = _endNumber;
        wallet = _wallet;
        token = ERC20(_token);
        weiRaised = 0;
    }

//////////////////
//  collect eth
//////////////////

    mapping (address => uint256) public buyers;
    address[] private keys;

    function getKeyLength() external constant returns (uint256) {
        return keys.length;
    }

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
        uint256 refund = (msg.value).sub(purchase);

        // refund
        _buyer.transfer(refund);

        // buy
        uint256 tokenAmount = purchase.mul(rate);
        weiRaised = weiRaised.add(purchase);

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
        bool b = block.number >= startNumber && block.number <= endNumber;

        return a && b;
    }

    function getPurchaseAmount(address _buyer) private constant returns (uint256) {
        return checkOverMaxcap(checkOverExceed(_buyer));
    }

    // 1. check over exceed
    function checkOverExceed(address _buyer) private constant returns (uint256) {
        if(msg.value >= exceed) {
            return exceed;
        } else if(msg.value.add(buyers[_buyer]) >= exceed) {
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
//  finalize
//////////////////

    bool finalized = false;

    function finalize() public onlyOwner {
        require(!finalized);
        require(weiRaised >= maxcap || block.number >= endNumber);

        // dev team
        withdrawEther();
        withdrawToken();

        finalized = true;
    }

//////////////////
//  release
//////////////////

    function release(address addr) public onlyOwner {
        require(!finalized);

        token.safeTransfer(addr, buyers[addr].mul(rate));
        emit Release(addr, buyers[addr].mul(rate));

        buyers[addr] = 0;
    }

    function releaseMany(uint256 start, uint256 end) external onlyOwner {
        for(uint256 i = start; i < end; i++) {
            release(keys[i]);
        }
    }

//////////////////
//  refund
//////////////////

    function refund(address addr) public onlyOwner {
        require(!finalized);

        addr.transfer(buyers[addr]);
        emit Refund(addr, buyers[addr]);

        buyers[addr] = 0;
    }

    function refundMany(uint256 start, uint256 end) external onlyOwner {
        for(uint256 i = start; i < end; i++) {
            refund(keys[i]);
        }
    }

//////////////////
//  withdraw
//////////////////

    function withdrawToken() public onlyOwner {
        token.safeTransfer(wallet, token.balanceOf(this));
        emit Withdraw(wallet, token.balanceOf(this));
    }

    function withdrawEther() public onlyOwner {
        wallet.transfer(address(this).balance);
        emit Withdraw(wallet, address(this).balance);
    }

//////////////////
//  events
//////////////////

    event Release(address indexed _to, uint256 _amount);
    event Withdraw(address indexed _from, uint256 _amount);
    event Refund(address indexed _to, uint256 _amount);
    event BuyTokens(address indexed buyer, uint256 price, uint256 tokens);
}
