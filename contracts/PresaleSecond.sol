pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Whitelist.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";


contract PresaleSecond is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    uint256 public maxcap;      // sale hardcap
    uint256 public exceed;      // indivisual hardcap
    uint256 public minimum;     // indivisual softcap
    uint256 public rate;        // exchange rate

    bool public paused = false;   // is sale paused?
    bool public ignited = false;  // is sale started?
    uint256 public weiRaised = 0; // check sale status

    address public wallet;      // wallet for withdrawal
    address public distributor; // contract for release, refund
    Whitelist public List;      // whitelist
    ERC20 public Token;         // token

    constructor (
        uint256 _maxcap,
        uint256 _exceed,
        uint256 _minimum,
        uint256 _rate,
        address _wallet,
        address _distributor,
        address _whitelist,
        address _token
    )
        public
    {
        require(_wallet != address(0));
        require(_whitelist != address(0));
        require(_distributor != address(0));
        require(_token != address(0));

        maxcap = _maxcap;
        exceed = _exceed;
        minimum = _minimum;
        rate = _rate;

        wallet = _wallet;
        distributor = _distributor;

        Token = ERC20(_token);
        List = Whitelist(_whitelist);
    }

    /* fallback function */
    function () external payable {
        collect();
    }

//  address
    event Change(address _addr, string _name);

    function setWhitelist(address _whitelist) external onlyOwner {
        require(_whitelist != address(0));

        List = Whitelist(_whitelist);
        emit Change(_whitelist, "whitelist");
    }

    function setDistributor(address _distributor) external onlyOwner {
        require(_distributor != address(0));

        distributor = _distributor;
        emit Change(_distributor, "distributor");

    }

    function setWallet(address _wallet) external onlyOwner {
        require(_wallet != address(0));

        wallet = _wallet;
        emit Change(_wallet, "wallet");
    }

//  sale controller
    event Pause();
    event Resume();
    event Ignite();
    event Extinguish();

    function pause() external onlyOwner {
        paused = true;
        emit Pause();
    }

    function resume() external onlyOwner {
        paused = false;
        emit Resume();
    }

    function ignite() external onlyOwner {
        ignited = true;
        emit Ignite();
    }

    function extinguish() external onlyOwner {
        ignited = false;
        emit Extinguish();
    }

//  collect eth
    event Purchase(address indexed _buyer, uint256 _purchased, uint256 _refund, uint256 _tokens);

    mapping (address => uint256) public buyers;

    function collect() public payable {
        address buyer = msg.sender;
        uint256 amount = msg.value;

        require(ignited && !paused);
        require(List.whitelist(buyer));
        require(buyer != address(0));
        require(buyers[buyer].add(amount) >= minimum);
        require(buyers[buyer] < exceed);
        require(weiRaised < maxcap);

        uint256 purchase;
        uint256 refund;

        (purchase, refund) = getPurchaseAmount(buyer, amount);

        weiRaised = weiRaised.add(purchase);

        if(weiRaised >= maxcap) ignited = false;

        buyers[buyer] = buyers[buyer].add(purchase);
        emit Purchase(buyer, purchase, refund, purchase.mul(rate));

        buyer.transfer(refund);
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

    function finalize() external onlyOwner {
        require(!ignited && !finalized);

        withdrawEther();
        withdrawToken();

        finalized = true;
    }

//  release & release
    event Release(address indexed _to, uint256 _amount);
    event Refund(address indexed _to, uint256 _amount);

    function release(address _addr)
        external
        returns (bool)
    {
        require(!ignited && !finalized);
        require(msg.sender == distributor); // only for distributor
        require(_addr != address(0));

        if(buyers[_addr] == 0) return false;

        uint256 releaseAmount = buyers[_addr].mul(rate);
        buyers[_addr] = 0;

        Token.safeTransfer(_addr, releaseAmount);
        emit Release(_addr, releaseAmount);

        return true;
    }

    // 어떤 모종의 이유로 환불 절차를 밟아야 하는 경우를 상정하여 만들어놓은 안전장치입니다.
    // This exists for safety when we have to run refund process by some reason.
    function refund(address _addr)
        external
        returns (bool)
    {
        require(!ignited && !finalized);
        require(msg.sender == distributor); // only for distributor
        require(_addr != address(0));

        if(buyers[_addr] == 0) return false;

        uint256 refundAmount = buyers[_addr];
        buyers[_addr] = 0;

        _addr.transfer(refundAmount);
        emit Refund(_addr, refundAmount);

        return true;
    }

//  withdraw
    event WithdrawToken(address indexed _from, uint256 _amount);
    event WithdrawEther(address indexed _from, uint256 _amount);

    function withdrawToken() public onlyOwner {
        require(!ignited);
        Token.safeTransfer(wallet, Token.balanceOf(address(this)));
        emit WithdrawToken(wallet, Token.balanceOf(address(this)));
    }

    function withdrawEther() public onlyOwner {
        require(!ignited);
        wallet.transfer(address(this).balance);
        emit WithdrawEther(wallet, address(this).balance);
    }
}
