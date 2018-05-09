pragma solidity ^0.4.19;

import "openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";


contract ABLG is StandardToken, Ownable {
    using SafeMath for uint256;

    // Token Information
    string public name = "Airbloc Genesis Token";
    string public symbol = "ABLG";
    uint256 public decimals = 18;
    uint256 public totalSupply = 0;

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

    event Mint(address to, uint256 amount);
    event Burn(address from, uint256 amount);
}
