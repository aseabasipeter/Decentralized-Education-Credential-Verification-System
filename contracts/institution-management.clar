;; Institution Management Contract

(define-map authorized-institutions
  { institution: principal }
  { name: (string-ascii 100), website: (string-ascii 100) }
)

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u403))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_ALREADY_EXISTS (err u409))

(define-public (add-institution (institution principal) (name (string-ascii 100)) (website (string-ascii 100)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? authorized-institutions { institution: institution })) ERR_ALREADY_EXISTS)
    (ok (map-set authorized-institutions
      { institution: institution }
      { name: name, website: website }
    ))
  )
)

(define-public (remove-institution (institution principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? authorized-institutions { institution: institution })) ERR_NOT_FOUND)
    (ok (map-delete authorized-institutions { institution: institution }))
  )
)

(define-read-only (is-authorized-institution (institution principal))
  (is-some (map-get? authorized-institutions { institution: institution }))
)

(define-read-only (get-institution-info (institution principal))
  (map-get? authorized-institutions { institution: institution })
)

