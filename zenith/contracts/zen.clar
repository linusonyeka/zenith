;; Zenith Decentralized Identity Contract
;; A self-sovereign identity management system on Stacks
;; Features:
;; - Decentralized Identity (DID) creation and management
;; - Credential management
;; - Identity revocation (temporary and permanent)
;; - Ownership transfer with history tracking
;; - Active status tracking

;; Constants
(define-constant CONTRACT-OWNER tx-sender)

;; Error codes
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-ALREADY-EXISTS (err u101))
(define-constant ERR-NOT-FOUND (err u102))
(define-constant ERR-MAX-CREDENTIALS (err u103))
(define-constant ERR-ALREADY-DEACTIVATED (err u104))
(define-constant ERR-DEACTIVATED (err u105))
(define-constant ERR-TRANSFER-IN-PROGRESS (err u106))
(define-constant ERR-NO-PENDING-TRANSFER (err u107))
(define-constant ERR-TRANSFER-EXPIRED (err u108))
(define-constant ERR-SELF-TRANSFER (err u109))
(define-constant ERR-HISTORY-FULL (err u110))

;; Data Maps

;; Main identity storage
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

;; Pending transfer storage with expiration
(define-map pending-transfers 
  principal  ;; current owner
  {
    new-owner: principal,
    initiated-at: uint,
    expires-at: uint
  }
)

;; Transfer history storage
(define-map transfer-history
  principal
  (list 10 {
    from: principal,
    to: principal,
    timestamp: uint
  })
)

;; Public Functions

;; DID Management

;; Create a new decentralized identity
(define-public (create-did (did (string-ascii 100)))
  (begin
    (asserts! (is-none (map-get? user-identities tx-sender)) ERR-ALREADY-EXISTS)
    
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
    (asserts! (get is-active current-identity) ERR-DEACTIVATED)
    (asserts! (< (len (get credentials current-identity)) u10) ERR-MAX-CREDENTIALS)
    
    (map-set user-identities tx-sender 
      (merge current-identity {
        credentials: (unwrap! (as-max-len? (append (get credentials current-identity) credential) u10) ERR-MAX-CREDENTIALS),
        updated-at: block-height
      })
    )
    
    (ok true)
  )
)

;; Revocation Functions

;; Deactivate a DID (temporary revocation)
(define-public (deactivate-did (reason (optional (string-ascii 200))))
  (let
    (
      (current-identity (unwrap! (map-get? user-identities tx-sender) ERR-NOT-FOUND))
    )
    (asserts! (get is-active current-identity) ERR-ALREADY-DEACTIVATED)
    
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
    (asserts! (not (get is-active current-identity)) ERR-ALREADY-DEACTIVATED)
    
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

;; Permanently delete/revoke a DID
(define-public (revoke-did)
  (begin
    (asserts! (is-some (map-get? user-identities tx-sender)) ERR-NOT-FOUND)
    (map-delete user-identities tx-sender)
    (ok true)
  )
)

;; Transfer Functions

;; Initiate transfer of DID ownership
(define-public (initiate-transfer (new-owner principal))
  (let
    (
      (current-identity (unwrap! (map-get? user-identities tx-sender) ERR-NOT-FOUND))
      (transfer-expiry (+ block-height u144)) ;; ~24 hours (assuming 10 min blocks)
    )
    (asserts! (get is-active current-identity) ERR-DEACTIVATED)
    (asserts! (is-none (map-get? pending-transfers tx-sender)) ERR-TRANSFER-IN-PROGRESS)
    (asserts! (not (is-eq tx-sender new-owner)) ERR-SELF-TRANSFER)
    (asserts! (is-none (map-get? user-identities new-owner)) ERR-ALREADY-EXISTS)
    
    (map-set pending-transfers tx-sender {
      new-owner: new-owner,
      initiated-at: block-height,
      expires-at: transfer-expiry
    })
    
    (ok true)
  )
)

;; Cancel a pending transfer
(define-public (cancel-transfer)
  (begin
    (asserts! (is-some (map-get? pending-transfers tx-sender)) ERR-NO-PENDING-TRANSFER)
    (map-delete pending-transfers tx-sender)
    (ok true)
  )
)

;; Accept transfer of DID ownership
(define-public (accept-transfer (current-owner principal))
  (let
    (
      (transfer-data (unwrap! (map-get? pending-transfers current-owner) ERR-NOT-FOUND))
      (identity (unwrap! (map-get? user-identities current-owner) ERR-NOT-FOUND))
      (current-history (default-to (list) (map-get? transfer-history current-owner)))
    )
    (asserts! (is-eq tx-sender (get new-owner transfer-data)) ERR-UNAUTHORIZED)
    (asserts! (get is-active identity) ERR-DEACTIVATED)
    (asserts! (<= block-height (get expires-at transfer-data)) ERR-TRANSFER-EXPIRED)
    
    ;; Transfer identity
    (map-set user-identities tx-sender 
      (merge identity {
        updated-at: block-height
      })
    )
    
    ;; Record in history
    (map-set transfer-history tx-sender
      (unwrap! (as-max-len? 
        (append current-history {
          from: current-owner,
          to: tx-sender,
          timestamp: block-height
        }) 
        u10)
        ERR-HISTORY-FULL)
    )
    
    ;; Cleanup
    (map-delete user-identities current-owner)
    (map-delete pending-transfers current-owner)
    
    (ok true)
  )
)

;; Read-Only Functions

;; Get user's DID information
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

;; Verify a specific credential
(define-read-only (verify-credential (user principal) (credential (string-ascii 200)))
  (match (map-get? user-identities user)
    identity (and 
              (get is-active identity)
              (is-some (index-of (get credentials identity) credential))
            )
    false
  )
)

;; Get transfer history for a DID
(define-read-only (get-transfer-history (user principal))
  (map-get? transfer-history user)
)

;; Get pending transfer details
(define-read-only (get-pending-transfer (user principal))
  (map-get? pending-transfers user)
)

;; Check if transfer is expired
(define-read-only (is-transfer-expired (user principal))
  (match (map-get? pending-transfers user)
    transfer-data (> block-height (get expires-at transfer-data))
    false
  )
)