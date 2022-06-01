pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface ERC20{
function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface ERC721{
    function getApproved(uint256 tokenId) external view returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}



contract Seller is Ownable {

    uint private _listingIdCounter;
    uint private _validListingCount;
    uint private _offerCounter;
    uint private _validOfferCount;

    struct Listing {
        address nftAddress;
        uint256 tokenId;
        bool isValidListing;
    }

    struct Offer {
        //TODO:: reorder for storage optimization
        address offererAddress;
        uint[] listingIds;
        address[] nftAddresses;
        uint256[] tokenIds;
        address[] erc20Addresses;
        uint256[] erc20Amounts;
        bool isValidOffer;
    }

    mapping (uint => Listing) private _idToListing;
    mapping (uint => Offer) private _offers;

    function getListingCount() public view returns (uint){
        return _listingIdCounter;
    }
    function getOfferCount() public view returns (uint){
        return _offerCounter;
    }


    function createListing(address nftAddress_, uint256 tokenId_) public onlyOwner {
        Listing memory l = Listing(nftAddress_, tokenId_, true);
        _idToListing[_listingIdCounter] = l;
        _listingIdCounter++;
        _validListingCount++;
    }

    function makeOffer( uint[] calldata listingIds_, 
                        address[] calldata nftAddresses_, 
                        uint256[] calldata tokenIds_,
                        address[] calldata erc20Addresses_, 
                        uint256[] calldata erc20Amounts_) 
                        public {

        require(erc20Addresses_.length == erc20Amounts_.length, "erc not same length");
        require(nftAddresses_.length == tokenIds_.length, "tokens not same length");
        
        // offer validation here... should this be done here? -- Expensive?
        _offers[_offerCounter] = Offer(msg.sender, listingIds_, nftAddresses_, tokenIds_, erc20Addresses_, erc20Amounts_, true);
        _offerCounter++;
        _validOfferCount++;
    }


    function acceptOffer(uint offerId_) public onlyOwner{
        _validateOffer(offerId_);
        Offer memory offer = _offers[offerId_];

        // transfer offerers ERC20 tokens
        for(uint i=0; i<offer.erc20Addresses.length; i++){
            require(ERC20(offer.erc20Addresses[i]).transferFrom(offer.offererAddress, msg.sender, offer.erc20Amounts[i]));

        }

        // transfer Owners NFTs
        for(uint i=0; i<offer.listingIds.length; i++){
            Listing memory l = _idToListing[offer.listingIds[i]];
            ERC721(l.nftAddress).safeTransferFrom(msg.sender, offer.offererAddress, l.tokenId);
            _idToListing[offer.listingIds[i]].isValidListing = false;
            _validListingCount--;
        }

        // transfer offerers NFTs
        for(uint i=0; i<offer.tokenIds.length; i++){
            ERC721(offer.nftAddresses[i]).safeTransferFrom(offer.offererAddress, msg.sender, offer.tokenIds[i]);
        }
        _offers[offerId_].isValidOffer = false;
        _validOfferCount--;
    }

    function _validateOffer(uint offerId_) internal view {
        require(_offers[offerId_].isValidOffer, "Invalid offerId");
        
        Offer memory offer = _offers[offerId_];
        // ensure listing is still valid
        for(uint i=0; i<offer.listingIds.length; i++){
            Listing memory l = _idToListing[offer.listingIds[i]];
            require(l.isValidListing, "Invalid Listing");
            require(ERC721(l.nftAddress).getApproved(l.tokenId) == address(this), "contract not approved to transfer listed nft");
        }


        // require that Seller contract is approved to transfer all erc20 tokens
        for(uint i=0; i<offer.erc20Addresses.length; i++){
            require(ERC20(offer.erc20Addresses[i]).allowance(offer.offererAddress, address(this)) >= offer.erc20Amounts[i], "Seller contract not authorized to transfer ERC20s from offerer");
        }

        //require that Seller contract is approved to transfer ERC721 tokens
        for(uint i=0; i<offer.tokenIds.length; i++){
            require(ERC721(offer.nftAddresses[i]).getApproved(offer.tokenIds[i])==address(this), "Seller contract not authorized to transfer ERC721 tokens from offerer");
        }
    }

    // getOffers() NOT TESTED!!!! 
    function getOffers() external view returns (Offer[] memory){
        Offer[] memory validOffers = new Offer[](_validOfferCount);
        uint j = 0;
        for(uint i=0; i<_offerCounter; i++){
            if(_offers[i].isValidOffer){
                validOffers[j] = _offers[i];
                j++;
            }
        }
        require(j == _validOfferCount, "Error: did not get all valid offers");
        return validOffers;
    }


}