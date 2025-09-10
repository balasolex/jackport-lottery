;; -----------------------------------------------------
;; STX Jackpot Lottery
;; - Players enter by sending STX
;; - After round ends, one winner gets the pot
;; -----------------------------------------------------

(define-constant ticket-price u1000000) ;; 1 STX (1_000_000 microstacks)
(define-constant round-length u20)      ;; lasts 20 blocks
(define-constant contract-owner 'ST3J2GVMMM2R07ZFBJDWTYEYAR8FZH5WKDTFJ9AHA)

(define-data-var round-start uint u0)
(define-data-var next-player-id uint u0)

(define-map players
  { id: uint }
  { player: principal })

;; Start a new round (only owner)
(define-public (start-round)
  (begin
    (asserts! (is-eq tx-sender contract-owner) (err u100))
    ;; Store the current block height
    (var-set round-start u0)
    ;; Reset the player counter
    (var-set next-player-id u0)
    (ok true)))

;; Enter lottery by buying a ticket
(define-public (buy-ticket)
  (let ((pid (var-get next-player-id)))
    (begin
      ;; First check if the sender has enough STX
      (try! (stx-transfer? ticket-price tx-sender (as-contract tx-sender)))
      ;; Record the player
      (map-set players { id: pid } { player: tx-sender })
      ;; Increment the player counter
      (var-set next-player-id (+ pid u1))
      ;; Return success
      (ok true))))

;; Draw winner after round ends
(define-public (draw-winner)
  (let (
        (start (var-get round-start))
        (pid (var-get next-player-id))
        (current-block u0)
        (duration (- current-block start)))
    (begin
      (asserts! (>= duration round-length) (err u102))
      (asserts! (> pid u0) (err u103)) ;; must be at least one player
      ;; pseudo-random: using block number mod number-of-players
      (let ((winner-id (mod current-block pid)))
        (match (map-get? players { id: winner-id })
          winner-data (ok (try! (as-contract
                            (stx-transfer? 
                              (stx-get-balance tx-sender)
                              tx-sender
                              (get player winner-data)))))
          (err u104))))))

;; View player entry
(define-read-only (get-player (id uint))
  (map-get? players { id: id }))
