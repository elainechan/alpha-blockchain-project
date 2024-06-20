// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract DiplomaRegistry {
    struct Diploma {
        string studentName;
        string institutionName;
        string degree;
        string ipfsHash;
        address issuer;
        bool isIssued;
    }


    mapping(bytes32 => Diploma) public diplomas;
    mapping(address => bool) public authorizedIssuers;


    event DiplomaIssued(bytes32 indexed diplomaId, address indexed issuer, string studentName, string degree);


    modifier onlyAuthorizedIssuer() {
        require(authorizedIssuers[msg.sender], "Not an authorized issuer");
        _;
    }


    function authorizeIssuer(address issuer) public {
        // Only contract owner can authorize issuers (omitted for simplicity)
        authorizedIssuers[issuer] = true;
    }


    function issueDiploma(
        string memory studentName,
        string memory institutionName,
        string memory degree,
        string memory ipfsHash
    ) public onlyAuthorizedIssuer returns (bytes32) {
        bytes32 diplomaId = keccak256(abi.encodePacked(studentName, institutionName, degree, ipfsHash));
        require(!diplomas[diplomaId].isIssued, "Diploma already issued");


        diplomas[diplomaId] = Diploma({
            studentName: studentName,
            institutionName: institutionName,
            degree: degree,
            ipfsHash: ipfsHash,
            issuer: msg.sender,
            isIssued: true
        });


        emit DiplomaIssued(diplomaId, msg.sender, studentName, degree);
        return diplomaId;
    }


    function getDiploma(bytes32 diplomaId) public view returns (Diploma memory) {
        require(diplomas[diplomaId].isIssued, "Diploma not found");
        return diplomas[diplomaId];
    }
}
