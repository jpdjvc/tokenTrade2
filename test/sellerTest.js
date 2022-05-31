const { expect } = require("chai");
const { mnemonicToEntropy } = require("ethers/lib/utils");
const { ethers } = require("hardhat");

describe("Seller Contract", function () {

    let Seller;
    let seller;

    let NFT;
    let nft;
    let nftAmounts;
    let nftOwners;
    let nftSupply;

    let JPToken;
    let jptoken;

    let owner;
    let addr1;
    let addr2;
    let signers;

    beforeEach(async function(){
        Seller = await ethers.getContractFactory("Seller");
        [owner, addr1, addr2] = await ethers.getSigners();
        seller = await Seller.deploy();
        signers = [owner, addr1, addr2];
        
    
        NFT = await ethers.getContractFactory("NFT");
        nft = await NFT.deploy();
        expect(await nft.owner()).to.equal(owner.address, "Wrong owner of NFT contract");
        
        nftAmounts = [10, 15, 20];
        nftOwners = {};

        expect(signers.length).to.equal(nftAmounts.length, "Test bug: number of signers and nft owners not equal");

        nftSupply = 0;
        for(let i = 0; i<signers.length; i++){
            for(let j = 0; j<nftAmounts[i]; j++){
                await nft.mint(signers[i].address, nftSupply);
                nftOwners[nftSupply] = signers[i];
                nftSupply++;
                expect(Number(await nft.getSupply())).is.equal(nftSupply, "Error minting NFTs");
            }
        }

        for(let i = 0; i<nftSupply; i++){
            expect(await nft.ownerOf(i)).is.equal(nftOwners[i].address, "NFT owners not correct");
        }
    });


    describe("Seller Deployment", function(){
        it("Should set the right owner", async function(){
            expect(await seller.owner()).to.equal(owner.address, "Incorrect Owner or Seller contract");
        });

        it("Should create listings by owner and revert listings by other", async function(){
            let listingCount = 0;
            for(let i = 0; i< nftSupply; i++){
                if(nftOwners[i] == owner){
                    await seller.createListing(nft.address, i);
                    expect(Number(await seller.getListingCount())).to.equal(++listingCount);
                }else{
                    expect(seller.connect(nftOwners[i]).createListing(nft.address, i)).to.be.reverted;
                }
            }
        });

        it("Should make listings", async function(){
            seller.connect(nftOwners[1]).makeOffer(
                [0, 3, 2, 5],
                [nft.address, nft.address, nft.address, nft.address],
                [],
                []
            );
        });
    });

});