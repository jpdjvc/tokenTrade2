pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFT is ERC721, Ownable{
    uint256 _totalSupply;

    constructor()
    ERC721("NFT721NAME", "NFT721SYM") { }


    function mintTo(address to) onlyOwner public {
        _safeMint(to, _totalSupply);
        _totalSupply++;
    }

    function mint() public {
        _safeMint(msg.sender, _totalSupply);
        _totalSupply++;
    }

    
    function getSupply() public view returns(uint256) {
        return _totalSupply;
    }


}