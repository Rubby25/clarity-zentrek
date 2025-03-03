;; ZenTrek - Mindfulness app contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-session (err u101))
(define-constant err-session-exists (err u102))
(define-constant err-not-in-session (err u103))
(define-constant err-session-expired (err u104))
(define-constant err-invalid-state (err u105))

;; Achievement constants
(define-constant achievement-beginner u1)
(define-constant achievement-intermediate u2)
(define-constant achievement-master u3)

;; Data variables
(define-data-var next-session-id uint u0)
(define-data-var next-achievement-id uint u0)

;; Maps
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
    last-session: uint,
    last-session-timestamp: uint
})

(define-map active-sessions principal {
    session-id: uint,
    start-time: uint,
    paused: bool,
    pause-time: uint
})

;; NFT for rewards
(define-non-fungible-token zentrek-achievement uint)

;; Private functions
(define-private (is-same-day (timestamp-1 uint) (timestamp-2 uint))
    (let ((day-1 (/ timestamp-1 u86400))
          (day-2 (/ timestamp-2 u86400)))
        (is-eq day-1 day-2)))

(define-private (update-streak (user principal) (current-time uint))
    (let ((stats (unwrap! (map-get? user-stats user) (err u0)))
          (last-timestamp (get last-session-timestamp stats)))
        (if (is-same-day last-timestamp current-time)
            (get streak stats)
            (if (is-eq (- (/ current-time u86400) (/ last-timestamp u86400)) u1)
                (+ (get streak stats) u1)
                u1))))

(define-private (mint-achievement (user principal) (achievement-id uint))
    (let ((token-id (+ (var-get next-achievement-id) u1)))
        (try! (nft-mint? zentrek-achievement token-id user))
        (var-set next-achievement-id token-id)
        (ok token-id)))

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
                (map-set active-sessions tx-sender {
                    session-id: session-id,
                    start-time: block-height,
                    paused: false,
                    pause-time: u0
                })
                (ok true))
            err-invalid-session)))

(define-public (pause-session)
    (let ((active-session (unwrap! (map-get? active-sessions tx-sender) err-not-in-session)))
        (if (get paused active-session)
            err-invalid-state
            (begin
                (map-set active-sessions tx-sender (merge active-session {
                    paused: true,
                    pause-time: block-height
                }))
                (ok true)))))

(define-public (resume-session)
    (let ((active-session (unwrap! (map-get? active-sessions tx-sender) err-not-in-session)))
        (if (not (get paused active-session))
            err-invalid-state
            (begin
                (map-set active-sessions tx-sender (merge active-session {
                    paused: false,
                    pause-time: u0
                }))
                (ok true)))))

(define-public (complete-session (session-id uint))
    (let ((active-session (unwrap! (map-get? active-sessions tx-sender) err-not-in-session))
          (session (unwrap! (map-get? sessions session-id) err-invalid-session))
          (current-time block-height)
          (stats (default-to {
              sessions-completed: u0,
              total-minutes: u0,
              streak: u0,
              last-session: u0,
              last-session-timestamp: u0
          } (map-get? user-stats tx-sender))))
        
        (if (is-eq (get session-id active-session) session-id)
            (begin
                (map-delete active-sessions tx-sender)
                (let ((new-streak (update-streak tx-sender current-time)))
                    (map-set user-stats tx-sender {
                        sessions-completed: (+ (get sessions-completed stats) u1),
                        total-minutes: (+ (get total-minutes stats) (get duration session)),
                        streak: new-streak,
                        last-session: current-time,
                        last-session-timestamp: current-time
                    })
                    ;; Check achievements
                    (if (is-eq (+ (get sessions-completed stats) u1) u10)
                        (mint-achievement tx-sender achievement-beginner)
                        (ok true))))
            err-not-in-session)))

;; Read-only functions
(define-read-only (get-session (session-id uint))
    (ok (map-get? sessions session-id)))

(define-read-only (get-user-stats (user principal))
    (ok (map-get? user-stats user)))

(define-read-only (get-active-session (user principal))
    (ok (map-get? active-sessions user)))
