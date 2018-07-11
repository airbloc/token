pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Whitelist.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";

contract PublicSale is Pausable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    uint256 public maxgas;
    uint256 public maxcap;      // sale hardcap
    uint256 public exceed;      // indivisual hardcap
    uint256 public minimum;     // indivisual softcap
    uint256 public rate;        // exchange rate

    bool public ignited = false;  // is sale started?
    uint256 public weiRaised = 0; // check sale status

    address public wallet;      // wallet for withdrawal
    Whitelist public List;      // whitelist
    ERC20 public Token;         // token

    constructor (
        uint256 _maxcap,
        uint256 _exceed,
        uint256 _minimum,
        uint256 _rate,
        uint256 _maxgas,
        address _wallet,
        address _whitelist,
        address _token
    ) public {
        require(_wallet != address(0));
        require(_whitelist != address(0));
        require(_token != address(0));

        maxcap = _maxcap;
        exceed = _exceed;
        minimum = _minimum;
        rate = _rate;

        maxgas = _maxgas;
        wallet = _wallet;

        Token = ERC20(_token);
        List = Whitelist(_whitelist);
    }

    /* fallback function */
    function () external payable {
        collect();
    }

//  address
    event Change(address addr, string name);
    event ChangeMaxGas(uint256 gas);

    function setMaxGas(uint256 gas)
        external
        onlyOwner
    {
        require(gas > 0);
        maxgas = gas;
        emit ChangeMaxGas(gas);
    }

    function setWhitelist(address whitelist)
        external
        onlyOwner
    {
        require(whitelist != address(0));

        List = Whitelist(whitelist);
        emit Change(whitelist, "whitelist");
    }

    function setWallet(address newWallet)
        external
        onlyOwner
    {
        require(newWallet != address(0));

        wallet = newWallet;
        emit Change(newWallet, "wallet");
    }

//  sale controller
    event Ignite();
    event Extinguish();

    function ignite()
        external
        onlyOwner
    {
        ignited = true;
        emit Ignite();
    }

    function extinguish()
        external
        onlyOwner
    {
        ignited = false;
        emit Extinguish();
    }

//  collect eth
    event Purchase(address indexed buyer, uint256 purchased, uint256 refund, uint256 tokens);

    mapping (address => uint256) public buyers;

    function collect()
        public
        payable
        whenNotPaused
    {
        address buyer = msg.sender;
        uint256 amount = msg.value;

        require(ignited);
        require(List.whitelist(buyer));
        require(buyer != address(0));
        require(buyers[buyer].add(amount) >= minimum);
        require(buyers[buyer] < exceed);
        require(weiRaised < maxcap);
        require(tx.gasprice <= maxgas);

        uint256 purchase;
        uint256 refund;

        (purchase, refund) = getPurchaseAmount(buyer, amount);

        weiRaised = weiRaised.add(purchase);
        if(weiRaised >= maxcap) ignited = false;

        buyers[buyer] = buyers[buyer].add(purchase);

        buyer.transfer(refund);
        Token.safeTransfer(buyer, purchase.mul(rate));

        emit Purchase(buyer, purchase, refund, purchase.mul(rate));
    }

//  util functions for collect
    function getPurchaseAmount(address _buyer, uint256 _amount)
        private
        view
        returns (uint256, uint256)
    {
        uint256 d1 = maxcap.sub(weiRaised);
        uint256 d2 = exceed.sub(buyers[_buyer]);

        uint256 d = (d1 > d2) ? d2 : d1;

        return (_amount > d) ? (d, _amount.sub(d)) : (_amount, 0);
    }

//  finalize
    bool public finalized = false;

    function finalize()
        external
        onlyOwner
        whenNotPaused
    {
        require(!finalized);

        withdrawEther();
        withdrawToken();

        finalized = true;
    }

//  withdraw
    event WithdrawToken(address indexed from, uint256 amount);
    event WithdrawEther(address indexed from, uint256 amount);

    function withdrawToken()
        public
        onlyOwner
        whenNotPaused
    {
        require(!ignited);
        Token.safeTransfer(wallet, Token.balanceOf(address(this)));
        emit WithdrawToken(wallet, Token.balanceOf(address(this)));
    }

    function withdrawEther()
        public
        onlyOwner
        whenNotPaused
    {
        require(!ignited);
        wallet.transfer(address(this).balance);
        emit WithdrawEther(wallet, address(this).balance);
    }
}