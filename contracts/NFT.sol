pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFT is ERC721, Ownable{
    constructor()
    ERC721("NFT721NAME", "NFT721SYM"){
        _totalSupply=0;
    }

    uint256 _totalSupply;

    function mint(address to, uint256 tokenId) onlyOwner public {
        _safeMint(to, tokenId);
        _totalSupply++;
    }
    function getSupply() public view returns(uint256) {
        return _totalSupply;
    }


}