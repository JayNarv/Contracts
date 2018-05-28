pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
interface ERC20 {
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Burn(address indexed from, uint256 value);
}
interface ERC223 {
    // function transfer(address to, uint value, bytes data) external
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}
contract ERC223ReceivingContract { 
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

/*
Copyright (c) 2016 Smart Contract Solutions, Inc.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
contract SGCTest is ERC20, ERC223, Ownable {
    using SafeMath for uint;
     
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    uint256 internal _decimalFactor;
    uint256 internal _totalSupply;
    uint256 internal _sellPrice;
    uint256 internal _buyPrice;
        
    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    mapping (address => bool) internal frozenAccount;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event FrozenFunds(address target, bool frozen);
    
    /**
     * Constructor function
     * 
     * Initializes contract with initial supply tokens to the creator of the contract
     */

    function SGCTest(string name, string symbol, uint8 decimals, uint256 totalSupply) public {
        _symbol = symbol;
        _name = name;
        _decimals = decimals;
        _decimalFactor = 10 ** uint256(decimals);
        _totalSupply = totalSupply;
        balances[msg.sender] = totalSupply;
    }

    // function SGCTest() public {
    //     _symbol = "SGCT";
    //     _name = "SGCTest";
    //     _decimals = 18;
    //     _decimalFactor = 10 ** uint256(_decimals);
    //     _totalSupply = 1000000000 * _decimalFactor;
    //     balances[msg.sender] = _totalSupply;
    // }
    /**
     * @dev Get token name
     */
    function name()
        public
        view
        returns (string) {
        return _name;
    }
    
    /**
     * @dev Get token symbol
     */
    function symbol()
        public
        view
        returns (string) {
        return _symbol;
    }
        
    /**
     * @dev Get token decimals
     */
    function decimals()
        public
        view
        returns (uint8) {
        return _decimals;
    }
        
    /**
     * @dev Get token total supply
     */
    function totalSupply()
        public
        view
        returns (uint256) {
        return _totalSupply;
    }
    
    /**
     * @dev Get token total supply
     */
    function sellPrice()
        public
        view
        returns (uint256) {
        return _sellPrice;
    }
    
    
    /**
     * @dev Get token total supply
     */
    function buyPrice()
        public
        view
        returns (uint256) {
        return _buyPrice;
    }
    
    /**
     * @dev Get a token owner's current balance
     */
    function balanceOf(address _owner) external view returns (uint256 balance) {
        return balances[_owner];
    }
    
    /**
     * @dev Get the current allowance a token owner has given a token spender
     */
    function allowance(address _owner, address _spender) external view returns (uint256) {
        return allowed[_owner][_spender];
    }
        
    /**
     * Internal, safe transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
         require(_to != 0x0);                                           // Prevent transfer to 0x0 address. Use burn() instead
         require(balances[_from] >= _value);                            // Check if the sender has enough
         require(balances[_to] + _value > balances[_to]);               // Check for overflows
         require(!frozenAccount[_from]);                                // Check if sender is frozen
         require(!frozenAccount[_to]);                                  // Check if recipient is frozen
         
         uint previousBalances = balances[_from] + balances[_to];       // Save this for an assertion in the future
         balances[_from] -= _value;                                     // Subtract from the sender
         balances[_to] += _value;                                       // Add the same to the recipient
         emit Transfer(_from, _to, _value);                                  // Activate event
         assert(balances[_from] + balances[_to] == previousBalances);   // Sanity check for bugs
    }
    withdraw (sender) {
        balances[] -= 1000;
    }

    deposit(receiver, amount){
        receiver = receiver;
        balances[msg.sender] -= 100;
        balances[contract] += 100;
    }
    /**
     * @dev Transfer tokens
     *
     * @notice Send `_value` tokens to `_to` from your account
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) external returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Transfer tokens from other address
     *
     * @notice Send `_value` tokens to `_to` in behalf of `_from`
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_value <= allowed[_from][msg.sender]);
        allowed[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Set allowance for other address
     *
     * @notice Allows `_spender` to spend no more than `_value` tokens in your behalf
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) external returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Add to allowance for other address
     *
     * @notice Adds `_addedValue` tokens to the amount `_spender` may spend on your behalf
     * @param _spender The address authorized to spend
     * @param _addedValue the amount to be added to their allowance
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = SafeMath.add(allowed[msg.sender][_spender], _addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Subtract from allowance for other address
     *
     * @notice Subtracts `_subtractedValue` tokens to the amount `_spender` may spend on your behalf
     * @param _spender The address authorized to spend
     * @param _subtractedValue the amount to be subtracted to their allowance
     */
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = SafeMath.sub(oldValue, _subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    /**
     * @dev Destroy tokens
     *
     * @notice Remove `_value` tokens from the system irreversibly
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool) {
        require(balances[msg.sender] >= _value);    // Check if the sender has enough
        balances[msg.sender] -= _value;             // Subtract from the sender
        _totalSupply -= _value;                     // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * @dev Destroy tokens from other account
     *
     * @notice Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool) {
        require(balances[_from] >= _value);                 // Check if the targeted balance is enough
        require(_value <= allowed[_from][msg.sender]);      // Check allowance
        balances[_from] -= _value;                          // Subtract from the targeted balance
        allowed[_from][msg.sender] -= _value;               // Subtract from the sender's allowance
        _totalSupply -= _value;                             // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }

    /**
     * @dev Transfer tokens between ERC223 owners
     *
     * @notice Send `_value` tokens to `_to` from your account
     * @param _to The address of the recipient
     * @param _value the amount to send
     * @param _data is... something
     */
    function transfer(address _to, uint _value, bytes _data) public {
        require(_value > 0 );
        if(isContract(_to)) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value, _data);
    }

    /**
     * @dev Check if someone is has a contract
     *
     * @notice Check account at `_addr`
     * @param _addr The address to check
     */
    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length>0);
    }
    
    /**
     * @dev Create new tokens and send them to an account
     *
     * @notice Create `mintedAmount` tokens and send it to `target`
     * @param target The address to send new tokens
     * @param mintedAmount The amount of tokens to mint
     */
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balances[target] += mintedAmount;
        _totalSupply += mintedAmount;
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }
    
    /**
     * @dev Prevent an account from making transactions using this token
     *
     * @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
     * @param target The address to either freeze or unfreeze
     * @param freeze New frozen status of the account
     */
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    
    /**
     * @dev Set new values for buying and selling tokens
     *
     * @notice Allow users to buy tokens for `newBuyPrice` eth and sell tokens at `newSellPrice` eth
     * @param newSellPrice Price the users can sell to the contract
     * @param newBuyPrice Price users can buy from the contract
     */
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        _sellPrice = newSellPrice;
        _buyPrice = newBuyPrice;
    }
    
    /**
     * @notice Buy tokens from contract by sending ether
     */
    function buy() payable public {
        uint amount = msg.value / _buyPrice;
        _transfer(this, msg.sender, amount);
    }
    
    /**
     * @notice Sell `amount` tokens to contract
     * @param amount Amount of tokens to be sold
     */
    function sell(uint256 amount) public {
        require(balances[msg.sender] >= amount * _sellPrice);
        _transfer(msg.sender, this, amount);
        msg.sender.transfer(amount * _sellPrice);
    }
}