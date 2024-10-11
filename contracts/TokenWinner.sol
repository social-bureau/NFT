// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SimpleRandomNumberGenerator is ReentrancyGuard {
    address public owner;
    uint256 public constant FIRST_PRIZE_COUNT = 1;
    uint256 public constant SECOND_PRIZE_COUNT = 2;
    uint256 public constant THIRD_PRIZE_COUNT = 100;

    IERC721 public nftContract;

    event RandomNumberGenerated(uint256 randomNumber);
    event WinnersSelected(uint256[] firstPrizeWinners, uint256[] secondPrizeWinners, uint256[] thirdPrizeWinners);

    uint256[] public firstPrizeWinners;
    uint256[] public secondPrizeWinners;
    uint256[] public thirdPrizeWinners;
    mapping(uint256 => bool) public hasChecked;
    mapping(uint256 => bool) public isWinner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor(address _nftContractAddress) {
        owner = msg.sender;
        nftContract = IERC721(_nftContractAddress);
    }

    function generateRandomNumber() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender))) % 10001;
    }

    function selectWinners() external onlyOwner nonReentrant {
        delete firstPrizeWinners;
        delete secondPrizeWinners;
        delete thirdPrizeWinners;

        uint256 randomNumber;
        uint256 selectedTokenId;

        // Select First Prize Winners
        for (uint256 i = 0; i < FIRST_PRIZE_COUNT; i++) {
            do {
                randomNumber = generateRandomNumber();
                selectedTokenId = randomNumber % 10001;
            } while (isWinner[selectedTokenId]);
            firstPrizeWinners.push(selectedTokenId);
            isWinner[selectedTokenId] = true;
        }

        // Select Second Prize Winners
        for (uint256 i = 0; i < SECOND_PRIZE_COUNT; i++) {
            do {
                randomNumber = generateRandomNumber();
                selectedTokenId = randomNumber % 10001;
            } while (isWinner[selectedTokenId]);
            secondPrizeWinners.push(selectedTokenId);
            isWinner[selectedTokenId] = true;
        }

        // Select Third Prize Winners
        for (uint256 i = 0; i < THIRD_PRIZE_COUNT; i++) {
            do {
                randomNumber = generateRandomNumber();
                selectedTokenId = randomNumber % 10001;
            } while (isWinner[selectedTokenId]);
            thirdPrizeWinners.push(selectedTokenId);
            isWinner[selectedTokenId] = true;
        }

        emit WinnersSelected(firstPrizeWinners, secondPrizeWinners, thirdPrizeWinners);
    }

    function checkNFTReward(uint256 tokenId) external nonReentrant returns (string memory prize) {
        require(nftContract.ownerOf(tokenId) == msg.sender, "You do not own this token");
        require(!hasChecked[tokenId], "This token has already been checked");

        hasChecked[tokenId] = true;

        if (isWinner[tokenId]) {
            for (uint256 i = 0; i < firstPrizeWinners.length; i++) {
                if (tokenId == firstPrizeWinners[i]) {
                    return "First Prize";
                }
            }
            for (uint256 i = 0; i < secondPrizeWinners.length; i++) {
                if (tokenId == secondPrizeWinners[i]) {
                    return "Second Prize";
                }
            }
            for (uint256 i = 0; i < thirdPrizeWinners.length; i++) {
                if (tokenId == thirdPrizeWinners[i]) {
                    return "Third Prize";
                }
            }
        }

        return "No Prize";
    }

    function getWinners() external view returns (uint256[] memory, uint256[] memory, uint256[] memory) {
        return (firstPrizeWinners, secondPrizeWinners, thirdPrizeWinners);
    }
}
