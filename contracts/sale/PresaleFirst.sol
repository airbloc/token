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
    uint256 public maxcap;
    uint256 public exceed;
    uint256 public mininum;
    uint256 public rate;
    address public wallet;
    ERC20 public token;

    function PresaleFirst (
        uint256 _startTime,
        uint256 _endTime,
        uint256 _maxcap,
        uint256 _exceed,
        uint256 _mininum,
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
        mininum = _mininum;
        wallet = _wallet;
        token = ERC20(_token);
        rate = _rate;
    }

    function preValidation() private returns (bool) {
        // softcap, hardcap
        uint256 amount = msg.value;
        bool a = amount >= mininum && amount <= exceed;

        // sale duration
        uint256 time = block.timestamp;
        bool b = time > startTime && time < endTime;

        return a || b;
    }

    function getTokenAmount(address _buyer) private returns (uint256, uint256) {
        uint256 cAmount = msg.value;
        uint256 bAmount = 0;
        uint256 pAmount = 0;

        // get exist amount
        if(buyers[_buyer].Lock != address(0)) {
            bAmount = buyers[_buyer].Amount;
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

    function () external payable {
        buyToken(msg.sender);
    }

    function buyToken(address _buyer) public payable onlyWhitelisted whenNotPaused {
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

        wallet.transfer(purchase);
        token.transferFrom(wallet, buyers[_buyer].Lock, tokenAmount);
        emit BuyToken(wallet, _buyer, purchase, tokenAmount);
    }

    event PreValidationPassed(address buyer, uint256 amount, uint256 time);
    event TokenAmount(address buyer, uint256 refund, uint256 purchase);
}
