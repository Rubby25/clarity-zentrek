;; ZenTrek - Mindfulness app contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-session (err u101))
(define-constant err-session-exists (err u102))
(define-constant err-not-in-session (err u103))

;; Data variables
(define-map sessions uint {
    name: (string-ascii 50),
    duration: uint,
    breaths: uint,
    active: bool
})

(define-map user-stats principal {
    sessions-completed: uint,
    total-minutes: uint,
    streak: uint,
    last-session: uint
})

(define-map active-sessions principal uint)

;; NFT for rewards
(define-non-fungible-token zentrek-achievement uint)

;; Public functions
(define-public (create-session (name (string-ascii 50)) (duration uint) (breaths uint))
    (let ((session-id (+ (var-get next-session-id) u1)))
        (if (is-eq tx-sender contract-owner)
            (begin
                (map-set sessions session-id {
                    name: name,
                    duration: duration,
                    breaths: breaths,
                    active: true
                })
                (var-set next-session-id session-id)
                (ok session-id))
            err-owner-only)))

(define-public (start-session (session-id uint))
    (let ((session (unwrap! (map-get? sessions session-id) err-invalid-session)))
        (if (get active session)
            (begin
                (map-set active-sessions tx-sender session-id)
                (ok true))
            err-invalid-session)))

(define-public (complete-session (session-id uint))
    (let (
        (active-session (unwrap! (map-get? active-sessions tx-sender) err-not-in-session))
        (session (unwrap! (map-get? sessions session-id) err-invalid-session))
        (stats (default-to {
            sessions-completed: u0,
            total-minutes: u0,
            streak: u0,
            last-session: u0
        } (map-get? user-stats tx-sender))))
        
        (if (is-eq active-session session-id)
            (begin
                (map-delete active-sessions tx-sender)
                (map-set user-stats tx-sender {
                    sessions-completed: (+ (get sessions-completed stats) u1),
                    total-minutes: (+ (get total-minutes stats) (get duration session)),
                    streak: (+ (get streak stats) u1),
                    last-session: block-height
                })
                (ok true))
            err-not-in-session)))

;; Read-only functions
(define-read-only (get-session (session-id uint))
    (ok (map-get? sessions session-id)))

(define-read-only (get-user-stats (user principal))
    (ok (map-get? user-stats user)))

;; Data variables
(define-data-var next-session-id uint u0)
