pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";



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




contract Broker{
    using ECDSA for bytes32;

    function _validateTrade(
        address offererAddress,
        address[] calldata listingNftAddresses,
        uint[] calldata listingNftIds,
        address[] calldata offerNftAddresses, 
        uint[] calldata offerNftIds,
        address[] calldata offerTokenAddresses,
        uint[] calldata offerTokenAmounts
        ) internal view {
        
        require(listingNftAddresses.length == listingNftIds.length, "Listing NFT lengths not compatible");
        require(offerNftAddresses.length == offerNftIds.length, "Offer NFT lengths not compatible");
        require(offerTokenAddresses.length == offerTokenAmounts.length, "Offer Token lengths not compatible");

        // ensure listing is still valid
        for(uint i=0; i<listingNftAddresses.length; i++){
            require(ERC721(listingNftAddresses[i]).getApproved(listingNftIds[i]) == address(this), "contract not approved to transfer listed nft");
        }

        // require that Seller contract is approved to transfer all erc20 tokens
        for(uint i=0; i<offerTokenAddresses.length; i++){
            require(ERC20(offerTokenAddresses[i]).allowance(offererAddress, address(this)) >= offerTokenAmounts[i], "Seller contract not authorized to transfer ERC20s from offerer");
        }

        //require that Seller contract is approved to transfer ERC721 tokens
        for(uint i=0; i<offerNftAddresses.length; i++){
            require(ERC721(offerNftAddresses[i]).getApproved(offerNftIds[i])==address(this), "Seller contract not authorized to transfer ERC721 tokens from offerer");
        }
    }


    function _verifySignatures(
        bytes calldata sellerSignature,
        bytes calldata offererSignature,
        address offererAddress,
        
        address[] calldata listingNftAddresses,
        uint[] calldata listingNftIds,
        address[] calldata offerNftAddresses, 
        uint[] calldata offerNftIds,
        address[] calldata offerTokenAddresses,
        uint[] calldata offerTokenAmounts
        ) private view {

        bytes32 dataHashOffer = keccak256(abi.encodePacked(
            listingNftAddresses, 
            listingNftIds, 
            offerNftAddresses, 
            offerNftIds,
            offerTokenAddresses,
            offerTokenAmounts));

        bytes32 dataHashSeller = keccak256(abi.encodePacked(
            listingNftAddresses, 
            listingNftIds));

        bytes32 messageOffer = ECDSA.toEthSignedMessageHash(dataHashOffer);
        bytes32 messageSeller = ECDSA.toEthSignedMessageHash(dataHashSeller);
        address recoveredOffererAddress = ECDSA.recover(messageOffer, offererSignature);
        address recoveredSellerAddress = ECDSA.recover(messageSeller, sellerSignature);
        require(recoveredOffererAddress == offererAddress, "Corrupted offer data");
        require(recoveredSellerAddress == msg.sender, "Corrupted seller data");
    }



    function executeTrade(
        bytes calldata sellerSignature,
        bytes calldata offererSignature,
        address offererAddress,
        
        address[] calldata listingNftAddresses,
        uint[] calldata listingNftIds,
        address[] calldata offerNftAddresses, 
        uint[] calldata offerNftIds,
        address[] calldata offerTokenAddresses,
        uint[] calldata offerTokenAmounts
        ) public returns (bool){

        _verifySignatures(
            sellerSignature, 
            offererSignature, 
            offererAddress, 
            listingNftAddresses, 
            listingNftIds, 
            offerNftAddresses, 
            offerNftIds, 
            offerTokenAddresses, 
            offerTokenAmounts);
        
        // _validateTrade(
        //     offererAddress, 
        //     listingNftAddresses, 
        //     listingNftIds, 
        //     offerNftAddresses, 
        //     offerNftIds, 
        //     offerTokenAddresses, 
        //     offerTokenAmounts);


        // transfer offerers ERC20 tokens
        for(uint i=0; i<offerTokenAddresses.length; i++){
            require(ERC20(offerTokenAddresses[i]).transferFrom(offererAddress, msg.sender, offerTokenAmounts[i]));

        }

        // transfer Owners NFTs
        for(uint i=0; i<listingNftAddresses.length; i++){
            require(ERC721(listingNftAddresses[i]).getApproved(listingNftIds[i]) == address(this), "contract not approved to transfer listed nft");
            ERC721(listingNftAddresses[i]).safeTransferFrom(msg.sender, offererAddress, listingNftIds[i]);
        }

        // transfer offerers NFTs
        for(uint i=0; i<offerNftAddresses.length; i++){
            require(ERC721(offerNftAddresses[i]).getApproved(offerNftIds[i])==address(this), "Seller contract not authorized to transfer ERC721 tokens from offerer");
            ERC721(offerNftAddresses[i]).safeTransferFrom(offererAddress, msg.sender, offerNftIds[i]);
        }
        return true;
    }
}