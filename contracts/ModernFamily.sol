// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

error ModernFamily__RangeOutOfBounds();
error ModernFamily__InSufficientMintFee();
error ModernFamily__TransferFailed();

contract ModernFamily is ERC721URIStorage, VRFConsumerBaseV2, Ownable {

    VRFCoordinatorV2Interface private immutable vrfCoordinator;
    // Your subscription ID.
    uint64 private immutable s_subscriptionId;
    bytes32 private immutable gasLane;


    mapping(uint256 => address) private requestIdToSender;
    uint256 private constant MAX_CHANCE_VALUE = 100;
    string[] private characterTokenUris;
    uint256 private mintFee;

    enum Character {
        PUG,
        SHIBA_INU,
        ST_BERNARD
    }

    uint256 private tokenCounter = 0;

    event NftRequested(uint256 indexed requestId, address indexed requester);
    event NftMinted(Character character, address minter);

    constructor(address vrfCoordinatorV2,
        uint64 subscriptionId, 
        bytes32 _gasLane,
        uint256 _mintFee,
        string[3] memory _characterTokeUris) 
    ERC721("ModernFamily", "MF") VRFConsumerBaseV2(vrfCoordinatorV2) Ownable() {
        s_subscriptionId = subscriptionId;
        vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        gasLane = _gasLane;
        characterTokenUris = _characterTokeUris;
        mintFee = _mintFee;
    }

    // Assumes the subscription is funded sufficiently.
    function requestNFT() public payable returns (uint256 requestId) {
        if(msg.value < mintFee) {
            revert ModernFamily__InSufficientMintFee();
        }

        // Will revert if subscription is not set and funded.
        requestId = vrfCoordinator.requestRandomWords(
                        gasLane,
                        s_subscriptionId,
                        3,
                        500000,
                        1
                        );
        // arguments - keyHash, subscriptionId, requestConfirmations, callbackGasLimit, numWords
        requestIdToSender[requestId] = msg.sender;
        emit NftRequested(requestId, msg.sender);
  }
  
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        address minter = requestIdToSender[requestId];
        uint256 moddedRng = randomWords[0] % MAX_CHANCE_VALUE;
        Character character = getCharacter(moddedRng);
        _safeMint(minter, tokenCounter);
        _setTokenURI(tokenCounter, characterTokenUris[uint256(character)]);
        tokenCounter += 1;
        emit NftMinted(character, minter);
    }

    function getChanceArray() public pure returns (uint256[3] memory) {
        return [10, 30, MAX_CHANCE_VALUE];
    }

    function getCharacter(uint256 moddedRng) public pure returns (Character) {
        uint256 cumulativeSum = 0;
        uint256[3] memory chanceArray = getChanceArray();
        for(uint256 i = 0; i < chanceArray.length; i++) {
            if(moddedRng >= cumulativeSum && moddedRng < cumulativeSum + chanceArray[i]) {
                return Character(i);
            }
            cumulativeSum += chanceArray[i];
        }
        revert ModernFamily__RangeOutOfBounds();
    }

    function withdraw() external onlyOwner() {
        (bool success, ) = payable(msg.sender).call{value:address(this).balance}("");
        if(!success){
            revert ModernFamily__TransferFailed();
        }
    }

    function getMintFee() public view returns (uint256) {
        return mintFee;
    }

    function getCharacterTokenUri(uint256 index) public view returns (string memory) {
        return characterTokenUris[index];
    }

    function getTokenCounter() public view returns (uint256) {
        return tokenCounter;
    }

}