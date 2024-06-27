// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DiplomaNFT
 * @dev A contract to manage the issuance and verification of diplomas as NFTs
 */
contract DiplomaNFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Struct to store issuer details
    struct Issuer {
        bool isActive; // Indicates if the issuer is currently active
        uint256 lastActiveTimestamp; // Timestamp of the last activity by the issuer
        uint256 lastVotedTimestamp; // Timestamp of the last vote cast by the issuer
    }

    // Struct to store issuer request details
    struct IssuerRequest {
        address requester; // Address of the requester
        uint256 approvals; // Number of approvals received
        uint256 rejections; // Number of rejections received
        bool processed; // Indicates if the request has been processed
        mapping(address => bool) voted; // Mapping to track if an issuer has voted on this request
    }

    // Mapping from issuer address to their details
    mapping(address => Issuer) public authorizedIssuers;

    // Mapping to track issuers
    mapping(address => bool) public issuers;

    // Mapping to track issuer requests
    mapping(bytes32 => IssuerRequest) public issuerRequests;

    // Constants
    uint256 public constant INACTIVITY_PERIOD = 5 * 365 * 24 * 60 * 60; // 5 years in seconds
    uint256 public constant VOTING_PERIOD = 30 * 24 * 60 * 60; // 30 days in seconds
    uint256 public constant REQUEST_COOLDOWN = 7 * 24 * 60 * 60; // 7 days in seconds
    uint256 public constant REQUEST_FEE = 0.001 ether; // Fee for submitting a request, increase after testing
    uint256 public constant MAX_PENDING_REQUESTS = 5; // Maximum number of pending requests allowed

    uint256 public pendingRequests; // Counter for pending requests

    // Events
    event DiplomaIssued(uint256 indexed tokenId, address indexed issuer, string studentName, string degree);
    event IssuerRequestSubmitted(bytes32 indexed requestId, address indexed requester);
    event IssuerRequestVoted(bytes32 indexed requestId, address indexed voter, bool approve);
    event IssuerAuthorized(address indexed issuer);
    event IssuerRevoked(address indexed issuer);

    // Modifiers

    // Ensures the caller is an authorized issuer
    modifier onlyAuthorizedIssuer() {
        require(authorizedIssuers[msg.sender].isActive, "Not an authorized issuer");
        _;
    }

    // Ensures the number of pending requests is within the limit
    modifier limitPendingRequests() {
        require(pendingRequests < MAX_PENDING_REQUESTS, "Too many pending requests");
        _;
    }

    // Constructor to initialize the contract
    constructor(address[] memory initialIssuers) ERC721("DiplomaNFT", "DiplTK") Ownable(msg.sender) {
        // Initialize issuers
        for (uint256 i = 0; i < initialIssuers.length; i++) {
            issuers[initialIssuers[i]] = true;
        }
    }

    /**
     * @dev Requests authorization as an issuer.
     */
    function requestAuthorization() public payable limitPendingRequests {
        require(msg.value >= REQUEST_FEE, "Insufficient fee"); // Check if the request fee is sufficient
        require(!authorizedIssuers[msg.sender].isActive, "Already an authorized issuer"); // Check if the issuer is already authorized
        require(block.timestamp > authorizedIssuers[msg.sender].lastVotedTimestamp + REQUEST_COOLDOWN, "Cooldown period active"); // Check if the cooldown period has passed

        // Generate a unique request ID based on the requester's address and current timestamp
        bytes32 requestId = keccak256(abi.encodePacked(msg.sender, block.timestamp));
        IssuerRequest storage request = issuerRequests[requestId];
        request.requester = msg.sender;
        pendingRequests++; // Increment the pending requests counter

        emit IssuerRequestSubmitted(requestId, msg.sender); // Emit an event for the new request
    }

    /**
     * @dev Stakeholders vote on issuer requests.
     * @param requestId The ID of the issuer request.
     * @param approve True to approve the request, false to reject.
     */
    function voteOnIssuerRequest(bytes32 requestId, bool approve) public onlyAuthorizedIssuer {
        IssuerRequest storage request = issuerRequests[requestId];
        require(!request.processed, "Request already processed"); // Check if the request has already been processed
        require(!request.voted[msg.sender], "Already voted"); // Check if the issuer has already voted on this request

        request.voted[msg.sender] = true;
        authorizedIssuers[msg.sender].lastVotedTimestamp = block.timestamp;

        if (approve) {
            request.approvals++; // Increment approvals if approved
        } else {
            request.rejections++; // Increment rejections if rejected
        }

        emit IssuerRequestVoted(requestId, msg.sender, approve); // Emit an event for the vote

        uint256 issuerCount = getIssuerCount(); // Get the current number of issuers
        uint256 requiredApprovals = (issuerCount * 65) / 100; // Calculate the required approvals threshold (65%)

        if (request.approvals >= requiredApprovals) {
            // If the approval threshold is met, authorize the new issuer
            authorizedIssuers[request.requester] = Issuer(true, block.timestamp, block.timestamp);
            request.processed = true;
            issuers[request.requester] = true; // Add the new issuer to the issuers mapping
            pendingRequests--; // Decrement the pending requests counter
            emit IssuerAuthorized(request.requester); // Emit an event for the new issuer authorization
        } else if (request.rejections > (issuerCount / 2)) {
            // If the rejection threshold is met (more than half of the issuers), mark the request as processed
            request.processed = true;
            pendingRequests--; // Decrement the pending requests counter
        }
    }

    /**
     * @dev Issues a diploma as an NFT.
     * @param studentName The name of the student.
     * @param studentID The ID number of the student.
     * @param institutionName The name of the institution.
     * @param degree The degree awarded.
     * @param ipfsHash The IPFS hash of the diploma document.
     * @param _tokenURI The URI of the token metadata.
     * @return tokenId The token ID of the issued diploma.
     */
    function issueDiploma(
        string memory studentName,
        string memory studentID,
        string memory institutionName,
        string memory degree,
        string memory ipfsHash,
        string memory _tokenURI
    ) public onlyAuthorizedIssuer returns (uint256 tokenId) {
        if (pendingRequests > 0) {
            // If there are pending requests, vote to approve the first pending request before issuing the diploma
            bytes32 firstRequestId = getFirstPendingRequest();
            voteOnIssuerRequest(firstRequestId, true);
        }

        // Mint the new diploma token
        tokenId = _tokenIds.current();
        _tokenIds.increment();

        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _tokenURI);

        emit DiplomaIssued(tokenId, msg.sender, studentName, degree); // Emit an event for the issued diploma
    }

    /**
     * @dev Gets the count of active issuers.
     * @return The count of active issuers.
     */
    function getIssuerCount() internal view returns (uint256) {
        uint256 count = 0;
        // Iterate through the token IDs and count the number of active issuers
        for (uint256 i = 0; i < _tokenIds.current(); i++) {
            if (issuers[address(uint160(i))]) {
                count++;
            }
        }
        return count;
    }

    /**
     * @dev Retrieves a diploma's details.
     * @param tokenId The token ID of the diploma.
     * @return The token URI.
     */
    function getDiploma(uint256 tokenId) public view returns (string memory) {
        require(ownerOf(tokenId) != address(0), "Diploma not found"); // Check if the diploma exists
        return tokenURI(tokenId); // Return the token URI
    }

    /**
     * @dev Gets the first pending request ID.
     * @return The ID of the first pending request.
     */
    function getFirstPendingRequest() internal view returns (bytes32) {
        // Iterate through the token IDs and find the first pending request
        for (uint256 i = 0; i < _tokenIds.current(); i++) {
            bytes32 requestId = keccak256(abi.encodePacked(address(uint160(i)), block.timestamp));
            if (!issuerRequests[requestId].processed) {
                return requestId;
            }
        }
        revert("No pending requests found"); // Revert if no pending requests are found
    }

    // The following functions are overrides required by Solidity.

    /**
     * @dev Returns the URI for a given token ID.
     * @param tokenId The token ID.
     * @return The token URI.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Checks if a given interface is supported.
     * @param interfaceId The interface ID.
     * @return True if the interface is supported, false otherwise.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}