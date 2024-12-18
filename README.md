# Zenith: Decentralized Identity Management on Stacks

## Overview

Zenith is a self-sovereign identity management system built on the Stacks blockchain, providing users with complete control over their digital identity and credentials.

## Features

- Create a unique Decentralized Identifier (DID)
- Add and manage credentials
- Secure, blockchain-based identity verification
- Limit of 10 credentials per identity

## Smart Contract Functions

### `create-did`
- Creates a new decentralized identity
- Prevents duplicate DIDs for a single principal
- Stores creation timestamp

### `add-credential`
- Adds a new credential to user's identity
- Limits total credentials to 10
- Updates identity timestamp

### `get-did`
- Retrieves full identity information for a given principal
- Read-only function

### `verify-credential`
- Checks if a specific credential exists for a user
- Returns boolean verification result

## Prerequisites

- Stacks wallet
- Clarinet for local development
- Basic understanding of Clarity smart contracts

## Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   npm install
   ```

3. Deploy locally:
   ```bash
   clarinet console
   ```

## Security Considerations

- Only the identity owner can modify their DID
- Credentials are immutable once added
- Maximum of 10 credentials per identity

## Contribution

1. Fork the repository
2. Create your feature branch
3. Commit changes
4. Push to the branch
5. Create a Pull Request

