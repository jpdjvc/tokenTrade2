pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Seller is Ownable {

    uint _listingIdCounter;

    struct Listing {
        address nftAddress;
        uint tokenId;
    }

    struct Offer {
        //TODO:: reorder for storage optimization
        uint[] listingIds;
        address[] nftAddresses;
        uint[] tokenIds;
        address[] erc20Addresses;
        uint[] erc20Amounts;
        uint weiValue;
    }

    mapping (uint => Listing) private _idToListing;
    Offer[] private _offers;

    constructor(address owner_) {
        _transferOwnership(owner_);
    }

    function createListing(address nftAddress_, uint tokenId_) public onlyOwner {
        Listing memory l = Listing(nftAddress_, tokenId_);
        _idToListing[_listingIdCounter] = l;
        _listingIdCounter++;
    }

    function makeOffer( uint[] calldata listingIds_, 
                        address[] calldata nftAddresses_, 
                        uint[] calldata tokenIds_,
                        address[] calldata erc20Addresses_, 
                        uint[] calldata erc20Amounts_, uint weiValue) 
                        public {
        require(nftAddresses_.length == tokenIds_.length, "not same length");
        // offer validation here


        _offers.push(Offer(listingIds_, nftAddresses_, tokenIds_, erc20Addresses_, erc20Amounts_, weiValue));
    }

}