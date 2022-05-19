pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Seller is Ownable {

    uint _listingIdCounter;

    struct Listing {
        address nftAddress;
        uint tokenId;
    }

    mapping (uint => Listing) private _idToListing;

    constructor(address owner_) {
        _transferOwnership(owner_);
    }

    function createListing(address nftAddress_, uint tokenId_) public onlyOwner {
        Listing memory l = Listing(nftAddress_, tokenId_);
        _idToListing[_listingIdCounter] = l;
        _listingIdCounter++;
    }

    function makeOffer( uint[] listingIds_, 
                        address[] nftAddresses_, 
                        uint[] tokenIds_,
                        address[] erc20Addresses_, 
                        uint[] erc20Amounts_, uint weiValue) 
                        public {
        require(nftAddresses_.length == tokenIds_.length, "not same length");

        // offer validation here
    }




}