pragma solidity ^0.4.0;
//import "./ERC20.sol";
interface Itoken { function transfer(address _to, uint256 _value) external returns (bool success); 
                   function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);}
contract Bank{
    
    struct Payout{
        uint256 amount;
        uint256 depositedAt; //creation time
        uint256 lockedFor;   // time payment is locked for in minutes (while testing)
        bool returned;
    }

    mapping (uint256=>Payout) payouts;
    mapping (address=>uint256[]) clientsIndices;
    address testToken = address(0xcc5a3e48dc55b9b7b699855d4910e83beb505bae);
    uint256 index = 0; 
        
    event LogReceivedFunds(address sender, uint amount, uint256 lockedFor);
    event LogReturnedFunds(address recipient, uint amount);
    
    constructor() public { 
    }
    
    function addPayout (uint256 _amount,
                        uint256 _lockedFor) public returns (bool){
        Itoken token = Itoken(testToken);
        if(!token.transferFrom(msg.sender, address(this), _amount)) { revert(); }
        else{
            var payout = Payout(_amount, now, _lockedFor, false);
            payouts[index] = payout;
            clientsIndices[msg.sender].push(index);
            index++;
            emit LogReceivedFunds(msg.sender, _amount, _lockedFor);
            return true;
        }
        return false;
    }
    
    function withdraw(uint256 _amount,
                      uint256 _lockedFor)public payable returns(bool){
            for(uint256 i = 0; i < clientsIndices[msg.sender].length; i++){
            if( payouts[clientsIndices[msg.sender][i]].amount == _amount && 
                payouts[clientsIndices[msg.sender][i]].lockedFor == _lockedFor &&
                now >= payouts[clientsIndices[msg.sender][i]].lockedFor * 1 minutes + payouts[clientsIndices[msg.sender][i]].depositedAt &&
                !payouts[clientsIndices[msg.sender][i]].returned){
                    Itoken token = Itoken(testToken);
                    if(token.transfer(msg.sender, _amount)){
                        payouts[clientsIndices[msg.sender][i]].returned = true;
                        emit LogReturnedFunds(msg.sender, _amount);
                }
                return true; 
            }
        }
        return false;
    }
}
