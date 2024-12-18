;; Zenith Decentralized Identity Contract
;; A self-sovereign identity management system on Stacks

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-ALREADY-EXISTS (err u101))
(define-constant ERR-NOT-FOUND (err u102))
(define-constant ERR-MAX-CREDENTIALS (err u103))
(define-constant ERR-ALREADY-DEACTIVATED (err u104))
(define-constant ERR-DEACTIVATED (err u105))

;; Store user identity data with revocation status
(define-map user-identities 
  principal 
  {
    did: (string-ascii 100),
    credentials: (list 10 (string-ascii 200)),
    created-at: uint,
    updated-at: uint,
    is-active: bool,
    revocation-reason: (optional (string-ascii 200))
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
      updated-at: block-height,
      is-active: true,
      revocation-reason: none
    })
    
    (ok true)
  )
)

;; Add a credential to user's identity
(define-public (add-credential (credential (string-ascii 200)))
  (let 
    (
      (current-identity (unwrap! (map-get? user-identities tx-sender) ERR-NOT-FOUND))
    )
    ;; Check if identity is active
    (asserts! (get is-active current-identity) ERR-DEACTIVATED)
    ;; Check if max credentials reached
    (asserts! (< (len (get credentials current-identity)) u10) ERR-MAX-CREDENTIALS)
    
    ;; Update identity with new credential
    (map-set user-identities tx-sender 
      (merge current-identity {
        credentials: (unwrap! (as-max-len? (append (get credentials current-identity) credential) u10) ERR-MAX-CREDENTIALS),
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

;; Check if a DID is active
(define-read-only (is-did-active (user principal))
  (match (map-get? user-identities user)
    identity (get is-active identity)
    false
  )
)

;; Verify a specific credential for active DIDs only
(define-read-only (verify-credential (user principal) (credential (string-ascii 200)))
  (match (map-get? user-identities user)
    identity (and 
              (get is-active identity)
              (is-some (index-of (get credentials identity) credential))
            )
    false
  )
)

;; Deactivate a DID (temporary revocation)
(define-public (deactivate-did (reason (optional (string-ascii 200))))
  (let
    (
      (current-identity (unwrap! (map-get? user-identities tx-sender) ERR-NOT-FOUND))
    )
    ;; Check if already deactivated
    (asserts! (get is-active current-identity) ERR-ALREADY-DEACTIVATED)
    
    ;; Update identity to deactivated state
    (map-set user-identities tx-sender 
      (merge current-identity {
        is-active: false,
        revocation-reason: reason,
        updated-at: block-height
      })
    )
    
    (ok true)
  )
)

;; Reactivate a deactivated DID
(define-public (reactivate-did)
  (let
    (
      (current-identity (unwrap! (map-get? user-identities tx-sender) ERR-NOT-FOUND))
    )
    ;; Check if already active
    (asserts! (not (get is-active current-identity)) ERR-ALREADY-DEACTIVATED)
    
    ;; Update identity to active state
    (map-set user-identities tx-sender 
      (merge current-identity {
        is-active: true,
        revocation-reason: none,
        updated-at: block-height
      })
    )
    
    (ok true)
  )
)

;; Permanently delete/revoke a user's decentralized identity
(define-public (revoke-did)
  (begin
    ;; Check if DID exists
    (asserts! (is-some (map-get? user-identities tx-sender)) ERR-NOT-FOUND)
    
    ;; Delete the identity entry
    (map-delete user-identities tx-sender)
    
    (ok true)
  )
)

;; Store pending transfers
(define-map pending-transfers 
  principal  ;; current owner
  principal  ;; new owner
)

;; Initiate transfer of DID ownership
(define-public (initiate-transfer (new-owner principal))
  (let
    (
      (current-identity (unwrap! (map-get? user-identities tx-sender) ERR-NOT-FOUND))
    )
    ;; Check if sender's DID is active
    (asserts! (get is-active current-identity) ERR-DEACTIVATED)
    ;; Prevent transfer to self
    (asserts! (not (is-eq tx-sender new-owner)) (err u106))
    ;; Check if new owner already has a DID
    (asserts! (is-none (map-get? user-identities new-owner)) ERR-ALREADY-EXISTS)
    
    ;; Store the pending transfer
    (map-set pending-transfers tx-sender new-owner)
    
    (ok true)
  )
)

;; Accept transfer of DID ownership
(define-public (accept-transfer (current-owner principal))
  (let
    (
      (pending-owner (unwrap! (map-get? pending-transfers current-owner) ERR-NOT-FOUND))
      (identity (unwrap! (map-get? user-identities current-owner) ERR-NOT-FOUND))
    )
    ;; Verify sender is the pending new owner
    (asserts! (is-eq tx-sender pending-owner) ERR-UNAUTHORIZED)
    ;; Check if the DID being transferred is active
    (asserts! (get is-active identity) ERR-DEACTIVATED)
    
    ;; Transfer the identity to new owner
    (map-set user-identities tx-sender 
      (merge identity {
        updated-at: block-height
      })
    )
    
    ;; Delete old identity entry and pending transfer
    (map-delete user-identities current-owner)
    (map-delete pending-transfers current-owner)
    
    (ok true)
  )
)