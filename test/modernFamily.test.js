// const {setupUsers, setupUser} = require('./utils');
// const { expect } = require("chai");
// const { ethers, deployments, getNamedAccounts, getUnnamedAccounts } = require("hardhat");

// async function setup () {
//     // it first ensures the deployment is executed and reset (use of evm_snapshot for faster tests)
//     await deployments.fixture(["Token"]);
  
//     // we get an instantiated contract in the form of a ethers.js Contract instance:
//     const contracts = {
//       Token: (await ethers.getContract('Token')),
//     };
  
//     // we get the tokenOwner
//     const {tokenOwner} = await getNamedAccounts();
  
//     // Get the unnammedAccounts (which are basically all accounts not named in the config,
//     // This is useful for tests as you can be sure they have noy been given tokens for example)
//     // We then use the utilities function to generate user objects
//     // These object allow you to write things like `users[0].Token.transfer(....)`
//     const users = await setupUsers(await getUnnamedAccounts(), contracts);

//     // finally we return the whole object (including the tokenOwner setup as a User object)
//     return {
//       ...contracts,
//       users,
//       tokenOwner: await setupUser(tokenOwner, contracts),
//     };
//   }

// describe("Token contract", function() {

//   describe("Deployment", function () {

//     it("Should set the right owner", async function () {
//       // before the test, we call the fixture function.
//       const {Token} = await setup();
//       const {tokenOwner} = await getNamedAccounts();
//       expect(await Token.owner()).to.equal(tokenOwner);
//     });

//     it("Should assign the total supply of tokens to the owner", async function () {
//       const {Token, tokenOwner} = await setup();
//       const ownerBalance = await Token.balanceOf(tokenOwner.address);
//       expect(await Token.totalSupply()).to.equal(ownerBalance);
//     });
//   });

//   describe("Transactions", function () {
//     it("Should transfer tokens between accounts", async function () {
//       const {Token, users, tokenOwner} = await setup();
//       // Transfer 50 tokens from owner to users[0]
//       await tokenOwner.Token.transfer(users[0].address, 50);
//       const users0Balance = await Token.balanceOf(users[0].address);
//       expect(users0Balance).to.equal(50);

//       // Transfer 50 tokens from users[0] to users[1]
//       // We use .connect(signer) to send a transaction from another account
//       await users[0].Token.transfer(users[1].address, 50);
//       const users1Balance = await Token.balanceOf(users[1].address);
//       expect(users1Balance).to.equal(50);
//     });

//     it("Should fail if sender doesn’t have enough tokens", async function () {
//       const {Token, users, tokenOwner} = await setup();
//       const initialOwnerBalance = await Token.balanceOf(tokenOwner.address);

//       // Try to send 1 token from users[0] (0 tokens) to owner (1000 tokens).
//       // `require` will evaluate false and revert the transaction.
//       await expect(users[0].Token.transfer(tokenOwner.address, 1)
//       ).to.be.revertedWith("Not enough tokens");

//       // Owner balance shouldn't have changed.
//       expect(await Token.balanceOf(tokenOwner.address)).to.equal(
//         initialOwnerBalance
//       );
//     });

//     it("Should update balances after transfers", async function () {
//       const {Token, users, tokenOwner} = await setup();
//       const initialOwnerBalance = await Token.balanceOf(tokenOwner.address);

//       // Transfer 100 tokens from owner to users[0].
//       await tokenOwner.Token.transfer(users[0].address, 100);

//       // Transfer another 50 tokens from owner to users[1].
//       await tokenOwner.Token.transfer(users[1].address, 50);

//       // Check balances.
//       const finalOwnerBalance = await Token.balanceOf(tokenOwner.address);
//       expect(finalOwnerBalance).to.equal(initialOwnerBalance - 150);

//       const users0Balance = await Token.balanceOf(users[0].address);
//       expect(users0Balance).to.equal(100);

//       const users1Balance = await Token.balanceOf(users[1].address);
//       expect(users1Balance).to.equal(50);
//     });
//   });
// });



// //  If you needed that contract to be associated to a specific signer, you can pass the address as the extra argument
// // const users = await getUnnamedAccounts();
// // const TokenAsUser0 = await ethers.getContract("Token", users[0]);

