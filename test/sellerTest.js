const { expect } = require("chai");
// const { mnemonicToEntropy } = require("ethers/lib/utils");
const { ethers } = require("hardhat");

describe("Seller Contract", function () {

    let Seller;
    let seller;

    let NFT;
    let nft;
    let nftAmounts;
    let nftIdToOwner;
    let nftSupply;

    let JPToken;
    let jpToken;
    let jpTokenSupply;
    let signerToTokenAmt;

    let owner;
    let addr1;
    let addr2;
    let signers;

    before(async function(){
        Seller = await ethers.getContractFactory("Seller");
        [owner, addr1, addr2] = await ethers.getSigners();
        seller = await Seller.deploy();
        signers = [owner, addr1, addr2];
        
        // create NFTs
        NFT = await ethers.getContractFactory("NFT");
        nft = await NFT.deploy();
        expect(await nft.owner()).to.equal(owner.address, "Wrong owner of NFT contract");
        
        nftAmounts = [10, 15, 20];
        
        nftIdToOwner = {};

        expect(signers.length).to.equal(nftAmounts.length, "Test bug: number of signers and nft owners not equal");
    
        // mint NFTs
        nftSupply = 0;
        for(let i = 0; i<signers.length; i++){
            for(let j = 0; j<nftAmounts[i]; j++){
                await nft.mint(signers[i].address, nftSupply);
                nftIdToOwner[nftSupply] = signers[i];
                nftSupply++;
                expect(Number(await nft.getSupply())).is.equal(nftSupply, "Error minting NFTs");
            }
        }

        // ensure correct owners of NFTs
        for(let i = 0; i<nftSupply; i++){
            expect(await nft.ownerOf(i)).is.equal(nftIdToOwner[i].address, "NFT owners not correct");
        }
        
        
        jpTokenSupply = 1000;
        rats = [0.2, 0.3, 0.5];
        signerToTokenAmt = {}
        
        JPToken = await ethers.getContractFactory("JPToken");
        jpToken = await JPToken.deploy(jpTokenSupply);

        for(let i = 1; i<signers.length; i++){
            signerToTokenAmt[signers[i]] = jpTokenSupply*rats[i];
            await jpToken.transfer(signers[i].address, signerToTokenAmt[signers[i]]);
            expect(Number(await jpToken.balanceOf(signers[i].address))).to.equal(signerToTokenAmt[signers[i]]);
        }
        signerToTokenAmt[owner] = jpTokenSupply*rats[0];
        expect(Number(await jpToken.balanceOf(owner.address))).to.equal(signerToTokenAmt[owner]);
    });


    describe("Seller Deployment", function(){
        it("Should set the right owner", async function(){
            expect(await seller.owner()).to.equal(owner.address, "Incorrect Owner or Seller contract");
        });

        it("Should create listings by owner and revert listings by other", async function(){
            let listingCount = 0;
            for(let i = 0; i< nftSupply; i++){
                if(nftIdToOwner[i] == owner){
                    await nft.approve(seller.address, i);
                    await seller.createListing(nft.address, i);
                    expect(Number(await seller.getListingCount())).to.equal(++listingCount);
                }else{
                    expect(seller.connect(nftIdToOwner[i]).createListing(nft.address, i)).to.be.reverted;
                }
            }
        });

        it("Should make offer", async function(){
            // approve contract to transfer items
            await nft.connect(addr1).approve(seller.address, 11);
            await nft.connect(addr1).approve(seller.address, 12);
            await jpToken.connect(addr1).approve(seller.address, signerToTokenAmt[addr1]);

            await seller.connect(addr1).makeOffer(
                [0, 3],
                [nft.address, nft.address],
                [11, 12],
                [jpToken.address],
                [signerToTokenAmt[addr1]]
            );
            expect(Number(await seller.getOfferCount())).to.equal(1, "Did not make offer");
        });

        it("Owner should accept Offer", async function(){
            await seller.acceptOffer(0);
        });

        it("Should not allow for accepting offer twice", async function(){
            await expect(seller.acceptOffer(0)).to.be.revertedWith("Invalid offerId");
        });

    });

});