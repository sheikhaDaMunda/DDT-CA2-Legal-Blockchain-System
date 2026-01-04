// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LegalEscrow {
    
    // State variables - these store information
    address public client;           // Person buying property
    address public solicitor;        // Lawyer handling the deal
    address public admin;            // Someone who can resolve disputes
    
    uint public escrowAmount;        // Amount of money held
    bool public fundsDeposited;      // Track if money is deposited
    bool public dealCompleted;       // Track if deal is done
    bool public disputed;            // Track if there's a problem
    
    // Events - these announce when something happens
    event FundsDeposited(address indexed client, uint amount);
    event FundsReleased(address indexed solicitor, uint amount);
    event FundsRefunded(address indexed client, uint amount);
    event DisputeRaised(address indexed by);
    
    // Constructor - runs once when contract is created
    constructor(address _solicitor, address _admin) {
        client = msg.sender;         // Person creating contract is the client
        solicitor = _solicitor;      // Set the solicitor's address
        admin = _admin;              // Set admin's address
        fundsDeposited = false;
        dealCompleted = false;
        disputed = false;
    }
    
    // Function 1: Client deposits money into escrow
    function depositFunds() public payable {
        require(msg.sender == client, "Only client can deposit");
        require(!fundsDeposited, "Funds already deposited");
        require(msg.value > 0, "Must deposit some amount");
        
        escrowAmount = msg.value;
        fundsDeposited = true;
        
        emit FundsDeposited(client, msg.value);
    }
    
    // Function 2: Release money to solicitor when deal is complete
    function releaseFunds() public {
        require(msg.sender == client || msg.sender == admin, "Not authorized");
        require(fundsDeposited, "No funds to release");
        require(!dealCompleted, "Deal already completed");
        require(!disputed, "Cannot release during dispute");
        
        dealCompleted = true;
        
        // Use call instead of transfer
        (bool success, ) = payable(solicitor).call{value: escrowAmount}("");
        require(success, "Transfer to solicitor failed");
        
        emit FundsReleased(solicitor, escrowAmount);
    }
    
    // Function 3: Refund money to client if deal fails
    function refundClient() public {
        require(msg.sender == solicitor || msg.sender == admin, "Not authorized");
        require(fundsDeposited, "No funds to refund");
        require(!dealCompleted, "Deal already completed");
        
        fundsDeposited = false;
        
        // Use call instead of transfer
        (bool success, ) = payable(client).call{value: escrowAmount}("");
        require(success, "Transfer to client failed");
        
        emit FundsRefunded(client, escrowAmount);
    }
    
    // Function 4: Raise a dispute
    function raiseDispute() public {
        require(msg.sender == client || msg.sender == solicitor, "Not authorized");
        require(fundsDeposited, "No active escrow");
        require(!dealCompleted, "Deal already completed");
        
        disputed = true;
        
        emit DisputeRaised(msg.sender);
    }
    
    // Function 5: Admin resolves dispute
    function resolveDispute(bool releaseToSolicitor) public {
        require(msg.sender == admin, "Only admin can resolve");
        require(disputed, "No active dispute");
        require(!dealCompleted, "Deal already completed");
        
        disputed = false;
        dealCompleted = true;
        
        if (releaseToSolicitor) {
            // Use call instead of transfer
            (bool success, ) = payable(solicitor).call{value: escrowAmount}("");
            require(success, "Transfer to solicitor failed");
            emit FundsReleased(solicitor, escrowAmount);
        } else {
            // Use call instead of transfer
            (bool success, ) = payable(client).call{value: escrowAmount}("");
            require(success, "Transfer to client failed");
            emit FundsRefunded(client, escrowAmount);
        }
    }
    
    // Function 6: Check contract balance
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}