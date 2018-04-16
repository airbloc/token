pragma solidity ^0.4.19;

import "./zeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "./zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./zeppelin-solidity/contracts/math/SafeMath.sol";


contract ABLG is StandardToken, Ownable {

    mapping (address => uint256) public holders;

    // Token Information
    string public name = "Airbloc Genesis Token";
    string public symbol = "ABLG";
    uint256 public decimals = 18;
    uint256 public totalSupply = 0;

    // Mint
    event Mint(address indexed to, uint256 amount);

    function mint(
        address _to,
        uint256 _amount
        )
        onlyOwner
        public returns (bool) {
            require(_to != 0x0);
            require(_amount >= 0);

            totalSupply = totalSupply.add(_amount);
            balances[_to] = balances[_to].add(_amount);
            emit Mint(_to, _amount);
            emit Transfer(address(0), _to, _amount);
            return true;
        }

    // Burn
    event Burn(address indexed from, uint256 amount);

    function burn(
        uint256 _amount
        )
        public {
            address from = msg.sender;
            require(_amount >= 0);
            require(_amount <= balances[from]);

            totalSupply = totalSupply.sub(_amount);
            balances[from] = balances[from].sub(_amount);
            emit Burn(from, _amount);
            emit Transfer(from, address(0), _amount);
        }
}
