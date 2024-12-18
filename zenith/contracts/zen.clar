;; Zenith Decentralized Identity Contract
;; A self-sovereign identity management system on Stacks

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-ALREADY-EXISTS (err u101))
(define-constant ERR-NOT-FOUND (err u102))
(define-constant ERR-MAX-CREDENTIALS (err u103))

;; Store user identity data
(define-map user-identities 
  principal 
  {
    did: (string-ascii 100),
    credentials: (list 10 (string-ascii 200)),
    created-at: uint,
    updated-at: uint
  }
)

;; Create a new decentralized identity
(define-public (create-did (did (string-ascii 100)))
  (begin
    ;; Check if DID already exists
    (asserts! (is-none (map-get? user-identities tx-sender)) ERR-ALREADY-EXISTS)
    
    ;; Create new identity entry
    (map-set user-identities tx-sender {
      did: did,
      credentials: (list),
      created-at: block-height,
      updated-at: block-height
    })
    
    (ok true)
  )
)

;; Add a credential to user's identity
(define-public (add-credential (credential (string-ascii 200)))
  (let 
    (
      (current-identity (unwrap! (map-get? user-identities tx-sender) ERR-NOT-FOUND))
      (current-credentials (get credentials current-identity))
    )
    ;; Check if max credentials reached
    (asserts! (< (len current-credentials) u10) ERR-MAX-CREDENTIALS)
    
    ;; Update identity with new credential
    (map-set user-identities tx-sender 
      (merge current-identity {
        credentials: (unwrap! (as-max-len? (append current-credentials credential) u10) ERR-MAX-CREDENTIALS),
        updated-at: block-height
      })
    )
    
    (ok true)
  )
)

;; Retrieve user's DID
(define-read-only (get-did (user principal))
  (map-get? user-identities user)
)

;; Verify a specific credential
(define-read-only (verify-credential (user principal) (credential (string-ascii 200)))
  (let 
    (
      (identity (unwrap! (map-get? user-identities user) false))
    )
    (is-some (index-of (get credentials identity) credential))
  )
)

;; Delete/revoke a user's decentralized identity
(define-public (revoke-did)
  (begin
    ;; Check if DID exists
    (asserts! (is-some (map-get? user-identities tx-sender)) ERR-NOT-FOUND)
    
    ;; Delete the identity entry
    (map-delete user-identities tx-sender)
    
    (ok true)
  )
)