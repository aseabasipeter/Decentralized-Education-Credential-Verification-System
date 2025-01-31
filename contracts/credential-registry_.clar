;; Credential Registry Contract

(define-map credentials
  { credential-id: uint }
  {
    issuer: principal,
    recipient: principal,
    credential-type: (string-ascii 50),
    issue-date: uint,
    expiration-date: (optional uint),
    revoked: bool
  }
)

(define-map credential-metadata
  { credential-id: uint }
  {
    name: (string-ascii 100),
    description: (string-utf8 500),
    additional-data: (optional (string-utf8 1000))
  }
)

(define-data-var credential-id-nonce uint u0)

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u403))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_ALREADY_EXISTS (err u409))

(define-read-only (get-credential (credential-id uint))
  (map-get? credentials { credential-id: credential-id })
)

(define-read-only (get-credential-metadata (credential-id uint))
  (map-get? credential-metadata { credential-id: credential-id })
)

(define-public (issue-credential
    (recipient principal)
    (credential-type (string-ascii 50))
    (name (string-ascii 100))
    (description (string-utf8 500))
    (expiration-date (optional uint))
    (additional-data (optional (string-utf8 1000))))
  (let
    ((new-credential-id (+ (var-get credential-id-nonce) u1)))
    (map-set credentials
      { credential-id: new-credential-id }
      {
        issuer: tx-sender,
        recipient: recipient,
        credential-type: credential-type,
        issue-date: block-height,
        expiration-date: expiration-date,
        revoked: false
      }
    )
    (map-set credential-metadata
      { credential-id: new-credential-id }
      {
        name: name,
        description: description,
        additional-data: additional-data
      }
    )
    (var-set credential-id-nonce new-credential-id)
    (ok new-credential-id)
  )
)

(define-public (revoke-credential (credential-id uint))
  (let
    ((credential (unwrap! (get-credential credential-id) ERR_NOT_FOUND)))
    (asserts! (is-eq (get issuer credential) tx-sender) ERR_UNAUTHORIZED)
    (asserts! (not (get revoked credential)) ERR_ALREADY_EXISTS)
    (map-set credentials
      { credential-id: credential-id }
      (merge credential { revoked: true })
    )
    (ok true)
  )
)

(define-read-only (is-credential-valid (credential-id uint))
  (match (get-credential credential-id)
    credential (and
      (not (get revoked credential))
      (match (get expiration-date credential)
        expiration-date (> expiration-date block-height)
        true
      )
    )
    false
  )
)

(define-read-only (get-all-credentials)
  (ok (var-get credential-id-nonce))
)

