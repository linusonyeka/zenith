# Zenith Decentralized Identity Contract

A self-sovereign identity management system built on the Stacks blockchain that enables decentralized identity (DID) creation, management, and transfer.

## Features

- **Decentralized Identity (DID) Management**
  - Create and manage W3C-compliant DIDs with the `did:stx:` method
  - Secure input validation and format verification
  - Maximum length of 100 characters with minimum length requirements

- **Credential Management**
  - Store up to 10 credentials per identity
  - Credential validation and format verification
  - Verification system for credential authenticity

- **Identity Lifecycle Management**
  - Temporary deactivation with reason tracking
  - Permanent revocation capabilities
  - Active status monitoring

- **Ownership Transfer System**
  - Secure two-step transfer process
  - 24-hour transfer window
  - Transfer history tracking (up to 10 most recent transfers)
  - Protection against unauthorized transfers

## Contract Functions

### DID Management
- `create-did`: Create a new DID with format validation
- `add-credential`: Add a validated credential to existing DID
- `get-did`: Retrieve DID information
- `verify-credential`: Verify credential authenticity

### Revocation Functions
- `deactivate-did`: Temporarily deactivate a DID with optional reason
- `reactivate-did`: Reactivate a deactivated DID
- `revoke-did`: Permanently revoke a DID

### Transfer Functions
- `initiate-transfer`: Start DID ownership transfer
- `accept-transfer`: Accept DID ownership transfer
- `cancel-transfer`: Cancel pending transfer
- `get-transfer-history`: View transfer history
- `is-transfer-expired`: Check transfer expiration status

## Error Codes

| Code | Description |
|------|-------------|
| u100 | Unauthorized access |
| u101 | Entity already exists |
| u102 | Entity not found |
| u103 | Maximum credentials reached |
| u104 | Already deactivated |
| u105 | Entity is deactivated |
| u106 | Transfer in progress |
| u107 | No pending transfer |
| u108 | Transfer expired |
| u109 | Self-transfer attempted |
| u110 | History limit reached |
| u111 | Invalid DID format |
| u112 | Invalid credential format |

## Security Features

- Input validation for DIDs and credentials
- Format enforcement with prefix verification
- Length constraints and boundary checks
- Protection against common attack vectors
- Secure ownership transfer mechanism

## Usage Example

```clarity
;; Create a new DID
(contract-call? .zenith-did create-did "did:stx:ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM")

;; Add a credential
(contract-call? .zenith-did add-credential "Educational Degree: Bachelor of Science in Computer Science")

;; Initialize transfer
(contract-call? .zenith-did initiate-transfer 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

## Development

### Prerequisites
- Clarity CLI
- Stacks blockchain environment


## Security Considerations

- All DIDs must follow the `did:stx:` format
- Credentials have strict length and format requirements
- Transfer operations have built-in timeouts
- Input validation prevents injection attacks
- Resource constraints prevent DoS attacks

