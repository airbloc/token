pragma solidity ^0.4.19;

import "zeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "../util/OwnableToken.sol";


contract ABL is StandardToken, OwnableToken {
    using SafeMath for uint256;

    // Token Distribution Rate
    uint256 public constant SUM = 400000000;   // totalSupply
    uint256 public constant DISTRIBUTION = 221450000; // distribution
    uint256 public constant DEVELOPERS = 178550000;   // developer

    // Token Information
    string public name = "Airbloc Token";
    string public symbol = "ABL";
    uint256 public decimals = 18;
    uint256 public totalSupply = SUM;

    function ABL(
        address _dtb,
        address _dev
        ) public {
        require(_dtb != address(0));
        require(_dev != address(0));
        require(DISTRIBUTION + DEVELOPERS == SUM);

        balances[_dtb] = DISTRIBUTION.mul(10 ** uint256(decimals));
        emit Transfer(address(0), _dtb, balances[_dtb]);

        balances[_dev] = DEVELOPERS.mul(10 ** uint256(decimals));
        emit Transfer(address(0), _dev, balances[_dev]);
    }

/////////////////////////
//  override transfer  //
/////////////////////////
    bool isLocked = true;

    modifier locked() {
        require(!isLocked);
        _;
    }

    function unlock() public onlyOwner {
        isLocked = false;
    }

/////////////////////////////////////////////
//       should remove this only test      //
    function lock() public onlyOwner {
        isLocked = true;
    }
/////////////////////////////////////////////

    function transfer(address _to, uint256 _value) public locked returns (bool) {
        require(_to != address(this));
        return super.transfer(_to, _value);
    }

//////////////////////
//  mint and burn   //
//////////////////////
    function mint(
        address _to,
        uint256 _amount
        ) onlyOwner public returns (bool) {
        require(_to != address(0));
        require(_amount >= 0);

        uint256 amount = _amount.mul(10 ** uint256(decimals));

        totalSupply = totalSupply.add(amount);
        balances[_to] = balances[_to].add(amount);

        emit Mint(_to, amount);
        emit Transfer(address(0), _to, amount);

        return true;
    }

    function burn(
        uint256 _amount
        ) onlyOwner public {
        require(_amount >= 0);
        require(_amount <= balances[msg.sender]);

        totalSupply = totalSupply.sub(_amount.mul(10 ** uint256(decimals)));
        balances[msg.sender] = balances[msg.sender].sub(_amount.mul(10 ** uint256(decimals)));

        emit Burn(msg.sender, _amount.mul(10 ** uint256(decimals)));
        emit Transfer(msg.sender, address(0), _amount.mul(10 ** uint256(decimals)));
    }

    event Mint(address indexed _to, uint256 _amount);
    event Burn(address indexed _from, uint256 _amount);
}
