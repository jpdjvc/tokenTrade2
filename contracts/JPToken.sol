pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract JPToken is ERC20, Ownable{
    constructor(uint256 initialSupply)
    ERC20("JPTOKEN20NAME", "JPTOKEN20SYM")
    {
        _mint(msg.sender, initialSupply);
    }

    function mint(uint amount) public {
        _mint(msg.sender, amount);
    }
}