pragma solidity 0.4.23;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
// Delete this on deploy
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
        require(_wallet != address(0), "given address is empty (_wallet)");
        require(_whitelist != address(0), "given address is empty (_whitelist)");
        require(_distributor != address(0), "given address is empty (_distributor)");
        require(_token != address(0), "given address is empty (_token)");

        require(_startTime > 0, "cannot set startTime under zero");
        require(_endTime > 0, "cannot set endTime under zero");
        require(_startTime < _endTime, "cannot set startTime after endTime");

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
        require(paused && !ignited, "cannot change startTime while sale on progress");
        require(_time > now, "cannot set startTime to past");
        require(_time < endTime, "cannot set startTime after endTime");

        startTime = _time;
        emit startTimeChanged(_time);
    }

    function setEndTime(uint256 _time) external onlyOwner {
        require(paused && !ignited, "cannot change endTime while sale on progress");
        require(_time > now, "cannot set endTime to past");
        require(_time > startTime, "cannot set endTime before startTime");

        endTime = _time;
        emit endTimeChanged(_time);
    }

////////////////////////////////////
//  address
////////////////////////////////////
    event Change(address _addr, string _name);

    function setWhitelist(address _whitelist) external onlyOwner {
        require(paused && !ignited, "cannot change whitelist while sale on progress");
        require(_whitelist != address(0), "given address is empty (_whitelist)");

        List = Whitelist(_whitelist);
        emit Change(_whitelist, "whitelist");
    }

    function setDistributor(address _distributor) external onlyOwner {
        require(paused && !ignited, "cannot change distributor while sale on progress");
        require(_distributor != address(0), "given address is empty (_distributor)");

        distributor = _distributor;
        emit Change(_distributor, "distributor");

    }

    function setWallet(address _wallet) external onlyOwner {
        require(paused && !ignited, "cannot change wallet while sale on progress");
        require(_wallet != address(0), "given address is empty (_wallet)");

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
    address[] public keys;

    function getKeyLength() external view returns (uint256) {
        return keys.length;
    }

    /**
     * @dev collect ether from buyer
     */
    function collect() public payable {
        require(!paused && ignited, "sale finished");
        require(List.whitelist(msg.sender), "current buyer is not in whitelist [buyer]");

        // prevent purchase delegation
        address buyer = msg.sender;

        require(buyer != address(0), "given address is empty (_buyer)");
        require(buyers[buyer].add(msg.value) > minimum, "cannot buy under minimum");
        require(buyers[buyer] < exceed, "cannot buy over exceed");
        require(weiRaised < maxcap, "sale finished (maxcap)");
        require(now >= endTime, "sale finished (time)");

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
        pure
        returns (uint256)
    {
        return (_a > _b) ? _b : _a;
    }

    /**
     * 1. 입금량 + 판매량 >= 세일 총량
     *      : 세일 총량 - 판매량 리턴
     * 2. 입금량 + 선입금량 >= 개인 최대
     *      : 개인 최대 - 선입금량 리턴
     * 3. 나머지
     *      : 입금량 리턴
     */

    /* function getPurchaseAmount(address _buyer)
        private
        view
        returns (uint256, uint256)
    {
        if(checkOver(msg.value.add(weiRaised), maxcap))
            return maxcap.sub(weiRaised);
        else if(checkOver(msg.value.add(buyers[_buyer]), exceed))
            return exceed.sub(buyers[_buyer]);
        else
            return msg.value;
    }

    function checkOver(uint256 a, uint256 b)
        private
        view
        returns (bool)
    {
        return a >= b;
    } */

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
        require(!ignited, "sale is not over");
        require(!finalized, "already finalized [finalized()]");

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
        require(!ignited, "sale is not over");
        require(!finalized, "already finalized [release()]");
        require(msg.sender == distributor, "invalid sender [release()]"); // only for distributor
        require(_addr != address(0), "given address is empty (_addr)");

        if(buyers[_addr] == 0) return false;

        Token.safeTransfer(_addr, buyers[_addr].mul(rate));
        emit Release(_addr, buyers[_addr].mul(rate));

        delete buyers[_addr];
        return true;
    }

    /**
     * @dev refund ether to buyer
     * @param _addr The address that owner want to refund ether
     */
    function refund(address _addr) external returns (bool) {
        require(!ignited, "sale is not over");
        require(!finalized, "already finalized [refund()]");
        require(msg.sender == distributor, "invalid sender [refund()]"); // only for distributor
        require(_addr != address(0), "given address is empty (_addr)");

        if(buyers[_addr] == 0) return false;

        _addr.transfer(buyers[_addr]);
        emit Refund(_addr, buyers[_addr]);

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
