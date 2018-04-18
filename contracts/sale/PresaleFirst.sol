pragma solidity ^0.4.19;

import "../zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "../zeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "../zeppelin-solidity/contracts/math/SafeMath.sol";
import "../zeppelin-solidity/contracts/ownership/Whitelist.sol";
import "../zeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "../token/ABL.sol";
import "../util/TokenTimelock.sol";


contract PresaleFirst is Whitelist, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    event BuyToken(address wallet, address indexed buyer, uint256 price, uint256 tokens);
    event BulkRelease(address owner, address[] keys);

    struct Buyer {
        address Lock;
        uint256 Amount;
    }

    mapping (address => Buyer) public buyers;
    address[] public keys;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public releaseTime;
    uint256 public maxcap;
    uint256 public exceed;
    uint256 public mininum;
    uint256 public rate;
    address public wallet;
    ERC20 public token;

    function PresaleFirst (
        uint256 _startTime,
        uint256 _endTime,
        uint256 _releaseTime,
        uint256 _maxcap,
        uint256 _exceed,
        uint256 _mininum,
        address _wallet,
        ERC20 _token,
        uint256 _rate
        ) public {
        require(_wallet != address(0));
        require(_token != ERC20(0));

        startTime = _startTime;
        endTime = _endTime;
        releaseTime = _releaseTime;
        maxcap = _maxcap;
        exceed = _exceed;
        mininum = _mininum;
        wallet = _wallet;
        token = _token;
        rate = rate;
    }

    function preValidation() private constant returns (bool) {
        // softcap, hardcap
        uint256 amount = msg.value;
        bool a = amount >= mininum && amount <= exceed;

        // sale duration
        uint256 time = block.timestamp;
        bool b = time > startTime && time < endTime;

        return a || b;
    }

    function getTokenAmount(address buyer) private constant returns (uint256, uint256) {
        uint256 cAmount = msg.value;
        uint256 bAmount = 0;
        uint256 pAmount = 0;

        // get exist amount
        if(buyers[buyer].Lock != address(0)) {
            bAmount = buyers[buyer].Amount;
            require(bAmount < exceed);
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

    function () public payable onlyWhitelisted {
        buyToken(msg.sender);
    }

    function buyToken(address buyer) public payable onlyWhitelisted whenNotPaused {
        require(buyer != address(0));

        require(preValidation());

        uint256 refund;
        uint256 purchase;

        (refund, purchase) = getTokenAmount(buyer);

        // refund
        buyer.transfer(refund);

        // buy
        uint256 tokenAmount = purchase.div(10000000000000000).mul(rate);
        maxcap = maxcap.sub(purchase);

        if(buyers[buyer].Lock == address(0)) {
            TokenTimelock lock = new TokenTimelock(ABL(token), owner, buyer, releaseTime);
            buyers[buyer].Lock = address(lock);
        }

        wallet.transfer(purchase);
        token.transferFrom(wallet, buyers[buyer].Lock, tokenAmount);
        emit BuyToken(wallet, buyer, purchase, tokenAmount);
    }

    function bulkRelease() public onlyOwner {
        for(uint256 i = 0; i < keys.length; i++) {
            TokenTimelock lockContract = TokenTimelock(buyers[keys[i]].Lock);
            lockContract.release();
        }

        emit BulkRelease(owner, keys);
    }
}
