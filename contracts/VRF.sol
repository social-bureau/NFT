// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SubscriptionConsumer is VRFConsumerBaseV2Plus, ReentrancyGuard {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    event WinnersSelected(Winner[] firstPrizeWinners, Winner[] secondPrizeWinners, Winner[] thirdPrizeWinners);

    struct RequestStatus {
        bool fulfilled;
        bool exists;
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus) public s_requests;

    uint256 public s_subscriptionId;
    uint256[] public requestIds;
    uint256 public lastRequestId;

    bytes32 public keyHash =
        0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;

    uint32 public callbackGasLimit = 100000;
    uint16 public requestConfirmations = 3;
    uint32 public numWords = 2;

    IERC721Enumerable public nftContract;
    uint256 public totalSupply;

    struct Winner {
        uint256 tokenId;
        address wallet;
    }

    Winner[] public firstPrizeWinners;
    Winner[] public secondPrizeWinners;
    Winner[] public thirdPrizeWinners;
    mapping(uint256 => bool) public hasParticipated;
    mapping(uint256 => string) public prizeWinners;

    uint256 public constant FIRST_PRIZE_COUNT = 1;
    uint256 public constant SECOND_PRIZE_COUNT = 2;
    uint256 public constant THIRD_PRIZE_COUNT = 100;

    constructor(uint256 subscriptionId, address _nftContractAddress)
        VRFConsumerBaseV2Plus(0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B)
    {
        s_subscriptionId = subscriptionId;
        nftContract = IERC721Enumerable(_nftContractAddress);
        require(nftContract.totalSupply() > 0, "NFT contract must have tokens");
        totalSupply = nftContract.totalSupply();
    }

    function requestRandomWords(bool enableNativePayment)
        external
        onlyOwner
        returns (uint256 requestId)
    {
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({
                        nativePayment: enableNativePayment
                    })
                )
            })
        );
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] calldata _randomWords
    ) internal override nonReentrant {
        require(s_requests[_requestId].exists, "Request not found");
        require(_randomWords.length > 0, "No random words provided");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        selectWinners(_randomWords);
        emit RequestFulfilled(_requestId, _randomWords);
    }

    function selectWinners(uint256[] memory randomWords) private {
        require(randomWords.length > 0, "Random words are required");
        uint256 wordIndex = 0;
        uint256 pointer = randomWords[wordIndex] % 10000;

        for (uint256 i = 0; i < FIRST_PRIZE_COUNT; i++) {
            firstPrizeWinners.push(selectUniqueWinner(pointer, "First Prize"));
            wordIndex = (wordIndex + 1) % randomWords.length;
            pointer = randomWords[wordIndex] % 10000;
        }

        for (uint256 i = 0; i < SECOND_PRIZE_COUNT; i++) {
            secondPrizeWinners.push(selectUniqueWinner(pointer, "Second Prize"));
            wordIndex = (wordIndex + 1) % randomWords.length;
            pointer = randomWords[wordIndex] % 10000;
        }

        for (uint256 i = 0; i < THIRD_PRIZE_COUNT; i++) {
            thirdPrizeWinners.push(selectUniqueWinner(pointer, "Third Prize"));
            wordIndex = (wordIndex + 1) % randomWords.length;
            pointer = randomWords[wordIndex] % 10000;
        }

        emit WinnersSelected(firstPrizeWinners, secondPrizeWinners, thirdPrizeWinners);
    }

    function selectUniqueWinner(uint256 randomness, string memory prizeType) private returns (Winner memory) {
        uint256 winnerTokenId;
        address winnerWallet;
        bool uniqueWinner = false;

        while (!uniqueWinner) {
            winnerTokenId = (randomness % totalSupply) + 1;
            if (!hasParticipated[winnerTokenId]) {
                hasParticipated[winnerTokenId] = true;
                prizeWinners[winnerTokenId] = prizeType;
                winnerWallet = nftContract.ownerOf(winnerTokenId);
                uniqueWinner = true;
            }
            randomness = uint256(keccak256(abi.encode(randomness)));
        }

        return Winner(winnerTokenId, winnerWallet);
    }

    function getWinners() external view returns (Winner[] memory, Winner[] memory, Winner[] memory) {
        return (firstPrizeWinners, secondPrizeWinners, thirdPrizeWinners);
    }

    function checkNFTReward(uint256 tokenId) external view returns (string memory prize) {
        require(nftContract.ownerOf(tokenId) == msg.sender, "You do not own this token");
        require(hasParticipated[tokenId], "This token has not won any prize");
        return prizeWinners[tokenId];
    }
}
