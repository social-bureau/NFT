# NFT RANDOM TOKENID DANHASH FOR WINNER

## Overview

This is a Solidity smart contract for securely generating random numbers using Chainlink's VRF (Verifiable Random Function). The contract manages a lottery-style selection where users can check if their NFT tokens have won a prize. It ensures fair and secure randomness through Chainlink VRF.

## Features

- Uses Chainlink VRF to generate secure, unbiased random numbers.
- Selects winners for First, Second, and Third prize categories.
- Supports interaction with ERC721 NFTs for prize verification.
- Implements access control to ensure only the contract owner can request random numbers and select winners.
- Supports checking the prize status of an NFT.

## Prizes

- **First Prize**: 1 winner.
- **Second Prize**: 2 winners.
- **Third Prize**: 100 winners.

## Installation

1. Clone the repository:

   ```sh
   git clone <repository-url>
   cd <repository-folder>
   ```

2. Install dependencies:

   ```sh
   npm install
   ```

3. Configure the contract addresses and Chainlink settings in `SimpleRandomNumberGenerator.sol`.

## Requirements

- **Solidity**: Version 0.8.25
- **Chainlink VRF Coordinator**: For random number generation
- **OpenZeppelin Contracts**: For security features and ERC721 support

## Deployment

1. Deploy the smart contract to your preferred Ethereum-compatible blockchain network.

2. Set the subscription ID for Chainlink VRF and the key hash required for random number requests.

3. Call the `requestRandomNumber` function to generate a random value.

## Usage

- **Owner** can call the `requestRandomNumber` function to initiate the randomness process.
- The `fulfillRandomWords` function (callback) will be automatically called by Chainlink to store the generated random values.
- The `selectWinners` function uses the generated random values to determine prize winners.
- Users can call `checkNFTReward(uint256 tokenId)` to determine if their NFT is a prize winner.

## Functions

- **requestRandomNumber**: Requests a random number using Chainlink VRF.
- **fulfillRandomWords**: Callback function used by Chainlink to fulfill random number requests.
- **selectWinners**: Selects winners using the random number generated.
- **checkNFTReward**: Allows users to check if their NFT has won a prize.
- **getWinners**: Returns the list of winners for all prize categories.

## Security

- Chainlink VRF ensures secure, verifiable randomness.
- **Access Control**: Only the owner can request random numbers and select winners.
- Reentrancy guards are in place to prevent attacks during critical functions.

## License

This project is licensed under the MIT License.

## Contact

- **Author**: Roongroj P.
- **Email**: roongroj@example.com

Feel free to contribute, suggest changes, or raise issues in the repository!