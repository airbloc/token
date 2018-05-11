pragma solidity 0.4.23;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Whitelist.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";


contract PresaleSecond is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

////////////////////////////////////
//  constructor
////////////////////////////////////
    uint256 public maxcap;      // sale hardcap
    uint256 public exceed;      // indivisual hardcap
    uint256 public minimum;     // indivisual softcap
    uint256 public rate;        // exchange rate

    uint256 public startTime;     // sale startTime
    uint256 public endTime;       // sale endTime
    bool public paused = false;   // is sale paused?
    bool public ignited = false;  // is sale started?
    uint256 public weiRaised;     // check sale status

    address public wallet;      // wallet for withdrawal
    address public distributor; // contract for release, refund
    Whitelist public List;      // whitelist
    ERC20 public Token;         // token

    constructor (
        //////////////////////////
        uint256 _maxcap,
        uint256 _exceed,
        uint256 _minimum,
        uint256 _rate,
        //////////////////////////
        uint256 _startTime,
        uint256 _endTime,
        //////////////////////////
        address _wallet,
        address _distributor,
        //////////////////////////
        address _whitelist,
        address _token
        //////////////////////////
    )
        public
    {
        require(_wallet != address(0));
        require(_whitelist != address(0));
        require(_distributor != address(0));
        require(_token != address(0));

        require(_startTime > 0);
        require(_endTime > 0);
        require(_startTime < _endTime);

        maxcap = _maxcap;
        exceed = _exceed;
        minimum = _minimum;
        rate = _rate;

        weiRaised = 0;
        Token = ERC20(_token);

        wallet = _wallet;
        distributor = _distributor;

        List = Whitelist(_whitelist);
    }

    /* fallback function */
    function () external payable {
        collect();
    }

////////////////////////////////////
//  time
////////////////////////////////////
    event startTimeChanged(uint256 _time);
    event endTimeChanged(uint256 _time);

    function setStartTime(uint256 _time) external onlyOwner {
        require(!ignited);
        require(_time > now);
        require(_time < endTime);

        startTime = _time;
        emit startTimeChanged(_time);
    }

    function setEndTime(uint256 _time) external onlyOwner {
        require(_time > now);
        require(_time > startTime);

        endTime = _time;
        emit endTimeChanged(_time);
    }

////////////////////////////////////
//  address
////////////////////////////////////
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

////////////////////////////////////
//  sale controller
////////////////////////////////////
    event Pause();
    event Unpause();
    event Ignite();
    event Extinguish();

    function pause() external onlyOwner {
        paused = true;
        emit Pause();
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Unpause();
    }

    function ignite() external onlyOwner {
        ignited = true;
        emit Ignite();
    }

    function extinguish() external onlyOwner {
        ignited = false;
        emit Extinguish();
    }

////////////////////////////////////
//  collect eth
////////////////////////////////////
    event Purchase(address indexed _buyer, uint256 _price, uint256 _tokens);

    mapping (address => uint256) public buyers;
    mapping (address => uint256) public indexes;
    address[] public keys;

    function getKeyLength() external returns (uint256) {
        return keys.length;
    }

    /**
     * @dev collect ether from buyer
     */
    function collect() public payable {
        require(ignited && !paused);
        require(List.whitelist[msg.sender]);

        // prevent purchase delegation
        address buyer = msg.sender;

        require(buyer != address(0));
        require(buyers[buyer].add(msg.value) >= minimum);
        require(buyers[buyer] < exceed);
        require(weiRaised < maxcap);
        require(now < endTime);
        require(now > startTime);

        if(buyers[buyer] == 0) keys.push(buyer);

        uint256 purchase;
        uint256 refund;

        (purchase, refund) = getPurchaseAmount(buyer);

        // buy
        uint256 tokenAmount = purchase.mul(rate);
        weiRaised = weiRaised.add(purchase);

        if(weiRaised >= maxcap) ignited = false;

        // wallet
        buyers[buyer] = buyers[buyer].add(purchase);
        emit Purchase(buyer, purchase, tokenAmount);

        // refund
        buyer.transfer(refund);
    }

////////////////////////////////////
//  util functions for collect
////////////////////////////////////
    /**
     * D1 = 세일총량 - 세일판매량
     * D2 = 개인최대 - 선입금량
     * 환불량 = 입금량 - MIN D1, D2
     * if 환불량 < 0
     *      return [ 다샀음! ]
     * else
     *      return [ 조금 사고 환불! ]
     */

    /**
     * @dev get amount of buyer can purchase
     * @param _buyer The address that tries to purchase
     */
    function getPurchaseAmount(address _buyer)
        private
        view
        returns (uint256, uint256)
    {
        uint256 d1 = maxcap.sub(weiRaised);
        uint256 d2 = exceed.sub(buyers[_buyer]);

        uint256 refund = msg.value.sub(min(d1, d2));

        if(refund > 0)
            return (msg.value.sub(refund) ,refund);
        else
            return (msg.value, 0);
    }

    function min(uint256 _a, uint256 _b)
        private
        view
        returns (uint256)
    {
        return (_a > _b) ? _b : _a;
    }

////////////////////////////////////
//  finalize
////////////////////////////////////
    /**
     * @dev if sale finalized?
     */
    bool public finalized = false;

    /**
     * @dev finalize sale and withdraw everything (token, ether)
     */
    function finalize() external onlyOwner {
        require(!ignited && !finalized);

        // send ether and token to dev wallet
        withdrawEther();
        withdrawToken();

        finalized = true;
    }

////////////////////////////////////
//  release & release
////////////////////////////////////
    event Release(address indexed _to, uint256 _amount);
    event Refund(address indexed _to, uint256 _amount);

    /**
     * @dev release token to buyer
     * @param _addr The address that owner want to release token
     */
    function release(address _addr) external returns (bool) {
        require(!ignited && !finalized);
        require(msg.sender == distributor); // only for distributor
        require(_addr != address(0));

        if(buyers[_addr] == 0) return false;

        Token.safeTransfer(_addr, buyers[_addr].mul(rate));
        emit Release(_addr, buyers[_addr].mul(rate));

        // TODO 동작하는지 확인
        delete buyers[_addr];
        return true;
    }

    /**
     * @dev refund ether to buyer
     * @param _addr The address that owner want to refund ether
     */
    function refund(address _addr) external returns (bool) {
        require(!ignited && !finalized);
        require(msg.sender == distributor); // only for distributor
        require(_addr != address(0));

        if(buyers[_addr] == 0) return false;

        _addr.transfer(buyers[_addr]);
        emit Refund(_addr, buyers[_addr]);

        // TODO 동작하는지 확인
        delete buyers[_addr];
        return true;
    }

////////////////////////////////////
//  withdraw
////////////////////////////////////
    event WithdrawToken(address indexed _from, uint256 _amount);
    event WithdrawEther(address indexed _from, uint256 _amount);

    /**
     * @dev withdraw token to specific wallet
     */
    function withdrawToken() public onlyOwner {
        Token.safeTransfer(wallet, Token.balanceOf(address(this)));
        emit WithdrawToken(wallet, Token.balanceOf(address(this)));
    }

    /**
     * @dev withdraw ether to specific wallet
     */
    function withdrawEther() public onlyOwner {
        wallet.transfer(address(this).balance);
        emit WithdrawEther(wallet, address(this).balance);
    }
}
