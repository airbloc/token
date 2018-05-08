pragma solidity 0.4.23;

import "zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "zeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "zeppelin-solidity/contracts/ownership/Whitelist.sol";
import "zeppelin-solidity/contracts/ownership/rbac/RBAC.sol";


contract PresaleFirst is RBAC, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    uint256 public maxcap;
    uint256 public exceed;
    uint256 public minimum;
    uint256 public rate;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public weiRaised;

    address public wallet;
    address public owner;

    Whitelist public whitelist;
    ERC20 public token;

    constructor (
        // about token
        uint256 _maxcap,
        uint256 _exceed,
        uint256 _minimum,
        uint256 _rate,
        address _token,

        // about sale
        uint256 _startTime,
        uint256 _endTime,
        address _wallet,
        address _whitelist
    )
        public
    {
        require(_wallet != address(0));
        require(_token != address(0));
        require(_whitelist != address(0));

        maxcap = _maxcap;
        exceed = _exceed;
        minimum = _minumum;
        rate = _rate;
        token = ERC20(_token);

        startTime = _startTime;
        endTime = _endTime;
        wallet = _wallet;
        whitelist = Whitelist(_whitelist);

        owner = msg.sender;

        weiRaised = 0;
    }

    /* fallback function */
    function () external payable {
        collect(msg.sender);
    }

//////////////////
//  collect eth
//////////////////

    mapping (address => uint256) public buyers;
    address[] public keys;

    function getKeyLength() external returns (uint256) {
        return keys.length;
    }

    /**
     * @dev collect ether from buyer
     * @param _buyer The address that tries to purchase
     */
    function collect(address _buyer) public payable whenNotPaused {
        // prevent purchase delegation
        require(Whitelist.whitelist[msg.sender], "current buyer is not in whitelist [sender]");
        require(Whitelist.whitelist[_buyer], "current buyer is not in whitelist [buyer]");

        preValidate(_buyer);

        if(buyers[_buyer] == 0) keys.push(_buyer);

        uint256 (purchase, refund) = getPurchaseAmount(_buyer);

        // buy
        uint256 tokenAmount = purchase.mul(rate);
        weiRaised = weiRaised.add(purchase);

        // wallet
        buyers[_buyer] = buyers[_buyer].add(purchase);
        emit Purchase(_buyer, purchase, tokenAmount);

        // refund
        _buyer.transfer(refund);
    }

//////////////////
//  util functions for collect
//////////////////

    /**
     * @dev validate buyer's current status
     * @param _buyer The address that tries to purchase
     */
    function preValidate(address _buyer) {
        require(_buyer != address(0), "address of buyer is empty");
        require(buyers[_buyer].add(msg.value) > minimum, "cannot buy under minimum");
        require(buyers[_buyer] < exceed, "cannot buy over exceed");
        require(weiRaised <= maxcap);
    }


    /**
     * D1 = 세일총량 - 세일판매량
     * D2 = 개인최대 - 입금량
     * 추가 = input 개인추가입금량
     * 환불량 = 추가 - MIN D1, D2
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

    function min(uint256 a, uint256 b)
        private
        view
        returns (uint256)
    {
        return (a > b) ? b : a;
    }

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

//////////////////
//  finalize
//////////////////

    bool public finalized = false;

    /**
     * @dev finalize sale and withdraw everything (token, ether)
     */
    function finalize() public onlyAdmin {
        require(!finalized);
        require(weiRaised >= maxcap || block.number >= endNumber);

        // dev team
        withdrawEther();
        withdrawToken();

        finalized = true;
    }

//////////////////
//  release & release
//////////////////

    /**
     * @dev release token to buyer
     * @param _addr The address that owner want to release token
     */
    function release(address _addr)
        external
        onlyRole("release")
        returns (bool)
    {
        require(!finalized);

        token.safeTransfer(_addr, buyers[_addr].mul(rate));
        emit Release(_addr, buyers[_addr].mul(rate));

        buyers[_addr] = 0;
        return true;
    }

    /**
     * @dev refund ether to buyer
     * @param _addr The address that owner want to refund ether
     */
    function refund(address _addr)
        external
        onlyRole("refund")
        returns (bool)
    {
        require(!finalized);

        _addr.transfer(buyers[_addr]);
        emit Refund(_addr, buyers[_addr]);

        buyers[_addr] = 0;
        return true;
    }

//////////////////
//  withdraw
//////////////////

    function withdrawToken() public onlyAdmin {
        token.safeTransfer(wallet, token.balanceOf(address(this)));
        emit WithdrawToken(wallet, token.balanceOf(address(this)));
    }

    function withdrawEther() public onlyAdmin {
        wallet.transfer(address(this).balance);
        emit WithdrawEther(wallet, address(this).balance);
    }

//////////////////
//  events
//////////////////
    event Release(address indexed _to, uint256 _amount);
    event Refund(address indexed _to, uint256 _amount);

    event WithdrawToken(address indexed _from, uint256 _amount);
    event WithdrawEther(address indexed _from, uint256 _amount);

    event Purchase(address indexed buyer, uint256 price, uint256 tokens);
}
