pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "hardhat/console.sol";



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

    function _verifySignature(
        bytes calldata _signature, 
        bytes memory _data, 
        address _expectedAddress) public pure returns(bool) {
        
        bytes32 dataHash = keccak256(_data);
        bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);
        address recoveredAddress = ECDSA.recover(message, _signature);
        require(recoveredAddress == _expectedAddress, "Signature not verified");
        return recoveredAddress == _expectedAddress;
    }

    /*
    _data SHOULD BE IN ORDER OF:
    uint listingsLength,
    uint offerNftLength,
    uint offerErc20Length,
    address[] listingNftAddresses,
    uint[] listingNftIds,
    address[] offerNftAddresses, 
    uint[] offerNftIds,
    address[] offerTokenAddresses,
    uint[] offerTokenAmounts
    */

    function executeTrade(
        bytes calldata _sellerSignature,
        bytes calldata _offererSignature,
        address _offererAddress,
        bytes calldata _data
        ) external {        

        require(_verifySignature(_sellerSignature, _data, msg.sender), "Seller signature not verified");
        require(_verifySignature(_offererSignature, _data, _offererAddress), "Offerer signature not verified");

        (address[] memory listingNftAddresses,
        uint[] memory listingNftIds,
        address[] memory offerNftAddresses, 
        uint[] memory offerNftIds,
        address[] memory offerTokenAddresses,
        uint[] memory offerTokenAmounts) = abi.decode(_data,(address[], uint[], address[], uint[], address[], uint[]));

        uint i;
        // transfer offerers ERC20 tokens
        for(i=0; i<offerTokenAddresses.length; i++){
            require(ERC20(offerTokenAddresses[i]).transferFrom(_offererAddress, msg.sender, offerTokenAmounts[i]), "Couldnt transfer offerer's ERC20 Tokens");
        }

        // transfer Owners NFTs
        for(i=0; i<listingNftAddresses.length; i++){
            require(ERC721(listingNftAddresses[i]).getApproved(listingNftIds[i]) == address(this), "contract not approved to transfer listed nft");
            ERC721(listingNftAddresses[i]).safeTransferFrom(msg.sender, _offererAddress, listingNftIds[i]);
        }

        // transfer offerers NFTs
        for(i=0; i<offerNftAddresses.length; i++){
            require(ERC721(offerNftAddresses[i]).getApproved(offerNftIds[i])==address(this), "Seller contract not authorized to transfer ERC721 tokens from offerer");
            ERC721(offerNftAddresses[i]).safeTransferFrom(_offererAddress, msg.sender, offerNftIds[i]);
        }
    }
}