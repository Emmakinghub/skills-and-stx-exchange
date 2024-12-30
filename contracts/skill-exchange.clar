;; Skill Exchange Smart Contract
;; This contract facilitates the exchange of skills (measured in hours) for STX, with a service fee.
;; Users can offer, remove, and exchange their skills at a set rate. The contract owner has 
;; administrative privileges to set the exchange rate, service fee, and skill reserve limits.
;; Key features include:
;; - Offering skills for exchange with a set rate.
;; - Exchanging skills for STX between users.
;; - Admin controls for setting parameters like skill exchange rate, service fee, and reserve limits.
;; - Checks and validations to ensure proper balances and authorization for actions.

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u200))
(define-constant err-insufficient-balance (err u201))
(define-constant err-invalid-skill (err u202))
(define-constant err-invalid-rate (err u203))
(define-constant err-reserve-limit-reached (err u204))
(define-constant err-unauthorized-user (err u205))

;; Data Variables
(define-data-var skill-rate uint u10) ;; Rate per hour for skills (in microstacks)
(define-data-var max-skills-per-user uint u100) ;; Max number of hours a user can offer
(define-data-var service-fee uint u10) ;; Service fee percentage (e.g., 10%)
(define-data-var total-skill-reserve uint u0) ;; Total hours of skills available (in hours)
(define-data-var skill-reserve-limit uint u1000) ;; Global limit for available skill hours (in hours)

;; Data Maps
(define-map user-skills-balance principal uint) ;; User's skill balance in hours
(define-map user-stx-balance principal uint) ;; User's STX balance
(define-map skills-for-exchange {user: principal} {skill-hours: uint, rate: uint})

;; Private functions

;; Calculate service fee
(define-private (calculate-service-fee (amount uint))
  (/ (* amount (var-get service-fee)) u100))

;; Update skill reserve
(define-private (update-skill-reserve (amount int))
  (let (
    (current-reserve (var-get total-skill-reserve))
    (new-reserve (if (< amount 0)
                     (if (>= current-reserve (to-uint (- 0 amount)))
                         (- current-reserve (to-uint (- 0 amount)))
                         u0)
                     (+ current-reserve (to-uint amount))))
  )
    (asserts! (<= new-reserve (var-get skill-reserve-limit)) err-reserve-limit-reached)
    (var-set total-skill-reserve new-reserve)
    (ok true)))

;; Public functions

;; Set skill exchange rate (only contract owner)
(define-public (set-skill-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> new-rate u0) err-invalid-rate) ;; Ensure rate is greater than 0
    (var-set skill-rate new-rate)
    (ok true)))

;; Set service fee (only contract owner)
(define-public (set-service-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= new-fee u100) err-invalid-rate) ;; Ensure fee is not more than 100%
    (var-set service-fee new-fee)
    (ok true)))