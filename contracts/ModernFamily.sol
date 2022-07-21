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

    // ---- Chainlink VRF ----

    // Chainlink contract to request random number
    VRFCoordinatorV2Interface private immutable i_vrfCoordinatorV2;
    // Subscription ID for random number request
    uint64 private immutable i_subscriptionId;
    // Specifies the maximum gas price to bump to
    bytes32 private immutable i_gasLane;
    // Storing each word costs about 20,000 gas
    uint32 private immutable i_callbackGasLimit;


    // ---- Constants ----
    uint256 private constant MAX_CHANCE_VALUE = 100;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint32 private constant NUM_CHARS = 3;


    // ---- State variables ----

    // maintains counter as tokenID
    uint256 private tokenCounter = 0;
    // stores token URIs for the characters
    string[NUM_CHARS] private characterTokenUris;
    // stores mint fee per NFT
    uint256 private s_mintFee;
    // requestID -> user who made that request
    mapping(uint256 => address) private requestIdToSender;
    
    // characters
    enum Character {
        PUG,
        SHIBA_INU,
        ST_BERNARD
    }


    // ---- Events ----

    event NftRequested(uint256 indexed requestId, address indexed requester);
    event NftMinted(Character character, address minter);


    // ---- Initialisation ----

    constructor(address _vrfCoordinatorV2,
                uint64 _subscriptionId, 
                bytes32 _gasLane,
                uint32 _callbackGasLimit,
                uint256 _mintFee,
                string[NUM_CHARS] memory _characterTokeUris) ERC721("ModernFamily", "MF") VRFConsumerBaseV2(_vrfCoordinatorV2) Ownable() {
        
        i_vrfCoordinatorV2 = VRFCoordinatorV2Interface(_vrfCoordinatorV2);
        i_subscriptionId = _subscriptionId;
        i_gasLane = _gasLane;
        i_callbackGasLimit = _callbackGasLimit;
        s_mintFee = _mintFee;
        characterTokenUris = _characterTokeUris;
    }


    // --- Updating state variables ----

    function updateMintFee(uint256 _mintFee) public onlyOwner {
        s_mintFee = _mintFee;
    }


    // --- Getter functions ----

    function getMintFee() public view returns (uint256) {
        return s_mintFee;
    }

    function getCharacterTokenUri(uint256 index) public view returns (string memory) {
        return characterTokenUris[index];
    }

    function getTokenCounter() public view returns (uint256) {
        return tokenCounter;
    }


    // ---- Minting NFT ----

    // Assumes the subscription is funded sufficiently.
    // Will revert if subscription is not set and funded.
    function requestNFT() public payable returns (uint256 requestId) {

        if(msg.value < s_mintFee) {
            revert ModernFamily__InSufficientMintFee();
        }

        requestId = i_vrfCoordinatorV2.requestRandomWords(
                        i_gasLane,
                        i_subscriptionId,
                        REQUEST_CONFIRMATIONS,
                        i_callbackGasLimit,
                        NUM_WORDS);
        // arguments - keyHash, subscriptionId, requestConfirmations, callbackGasLimit, numWords

        requestIdToSender[requestId] = msg.sender;
        emit NftRequested(requestId, msg.sender);
    }
  

    // called by Chainlink node when request is fulfilled
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        // get user who sent request
        address minter = requestIdToSender[requestId];

        // compute which character to be minted
        uint256 moddedRng = randomWords[0] % MAX_CHANCE_VALUE;
        Character character = getCharacter(moddedRng);

        // mint and set URI
        _safeMint(minter, tokenCounter);
        _setTokenURI(tokenCounter, characterTokenUris[uint256(character)]);
        tokenCounter += 1;
        emit NftMinted(character, minter);
    }


    // ---- Helper functions ----

    function getChanceArray() public pure returns (uint256[NUM_CHARS + 1] memory) {
        return [0, 10, 30, MAX_CHANCE_VALUE];
    }

    function getCharacter(uint256 moddedRng) public pure returns (Character) {
        uint256[NUM_CHARS + 1] memory chanceArray = getChanceArray();
        // assign character based on which slab the rng falls in
        for(uint256 i = 0; i < chanceArray.length - 1; i++) {
            if(moddedRng >= chanceArray[i] && moddedRng < chanceArray[i+1]) {
                return Character(i);
            }
        }
        revert ModernFamily__RangeOutOfBounds();
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value:address(this).balance}("");
        if(!success){
            revert ModernFamily__TransferFailed();
        }
    }  

}