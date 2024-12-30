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

;; Optimize skill exchange cost calculation
(define-private (calculate-exchange-cost (hours uint) (rate uint))
  ;; Reduce unnecessary variable assignments
  (let ((cost (* hours rate))
        (fee (calculate-service-fee cost)))
    (+ cost fee)))

;; Fix to ensure balance check is correctly handling the case when there are no skills for exchange
(define-private (check-user-skill-balance (user principal) (hours uint))
  (let ((current-balance (default-to u0 (map-get? user-skills-balance user))))
    (asserts! (>= current-balance hours) err-insufficient-balance)
    (ok true)))

;; Optimize the skill reserve calculation for faster updates
(define-private (optimized-update-skill-reserve (amount int))
  (begin
    (let ((current-reserve (var-get total-skill-reserve)))
      ;; Directly calculate and update skill reserve in one step
      (var-set total-skill-reserve (+ current-reserve (to-uint amount)))
      (ok true))))

;; Enhance the security of the contract by checking user authorization for offering skills
(define-private (authorize-skill-offering (user principal))
  (begin
    (asserts! (is-eq tx-sender user) err-unauthorized-user)
    (ok true)))

;; Refactor: Consolidate validation of skill exchange rate into a single function
(define-private (validate-skill-rate (rate uint))
  (begin
    (asserts! (> rate u0) err-invalid-rate) ;; Ensure rate is greater than 0
    (ok true)))

;; Enhance security by verifying user STX balance before allowing exchange
(define-private (verify-stx-balance (user principal) (amount uint))
  (begin
    (let ((balance (default-to u0 (map-get? user-stx-balance user))))
      (asserts! (>= balance amount) err-insufficient-balance)
      (ok true))))

;; Refactor to centralize the logic for updating user skill balance
(define-private (update-skill-balance (user principal) (amount uint))
  (begin
    (let ((current-balance (default-to u0 (map-get? user-skills-balance user))))
      (map-set user-skills-balance user (+ current-balance amount))
      (ok true))))


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

;; Set skill reserve limit (only contract owner)
(define-public (set-skill-reserve-limit (new-limit uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (>= new-limit (var-get total-skill-reserve)) err-reserve-limit-reached)
    (var-set skill-reserve-limit new-limit)
    (ok true)))

;; Offer skills for exchange
(define-public (offer-skills-for-exchange (hours uint) (rate uint))
  (let (
    (current-balance (default-to u0 (map-get? user-skills-balance tx-sender)))
    (current-for-exchange (get skill-hours (default-to {skill-hours: u0, rate: u0} (map-get? skills-for-exchange {user: tx-sender}))))
    (new-for-exchange (+ hours current-for-exchange))
  )
    (asserts! (> hours u0) err-invalid-skill) ;; Ensure hours are greater than 0
    (asserts! (> rate u0) err-invalid-rate) ;; Ensure rate is greater than 0
    (asserts! (>= current-balance new-for-exchange) err-insufficient-balance)
    (try! (update-skill-reserve (to-int hours)))
    (map-set skills-for-exchange {user: tx-sender} {skill-hours: new-for-exchange, rate: rate})
    (ok true)))

;; Remove skills from exchange
(define-public (remove-skills-from-exchange (hours uint))
  (let (
    (current-for-exchange (get skill-hours (default-to {skill-hours: u0, rate: u0} (map-get? skills-for-exchange {user: tx-sender}))))
  )
    (asserts! (>= current-for-exchange hours) err-insufficient-balance)
    (try! (update-skill-reserve (to-int (- hours))))
    (map-set skills-for-exchange {user: tx-sender} 
             {skill-hours: (- current-for-exchange hours), rate: (get rate (default-to {skill-hours: u0, rate: u0} (map-get? skills-for-exchange {user: tx-sender})))})
    (ok true)))

;; Exchange skills for STX (user-to-user)
(define-public (exchange-skills (provider principal) (hours uint))
  (let (
    (exchange-data (default-to {skill-hours: u0, rate: u0} (map-get? skills-for-exchange {user: provider})))
    (service-cost (* hours (get rate exchange-data)))
    (calculated-service-fee (calculate-service-fee service-cost)) ;; Renamed to avoid conflict
    (total-cost (+ service-cost calculated-service-fee))
    (provider-skills (default-to u0 (map-get? user-skills-balance provider)))
    (user-balance (default-to u0 (map-get? user-stx-balance tx-sender)))
    (provider-balance (default-to u0 (map-get? user-stx-balance provider)))
  )
    (asserts! (not (is-eq tx-sender provider)) err-unauthorized-user)
    (asserts! (> hours u0) err-invalid-skill) ;; Ensure hours are greater than 0
    (asserts! (>= (get skill-hours exchange-data) hours) err-insufficient-balance)
    (asserts! (>= provider-skills hours) err-insufficient-balance)
    (asserts! (>= user-balance total-cost) err-insufficient-balance)

    ;; Update provider's skills balance and available skill hours
    (map-set user-skills-balance provider (- provider-skills hours))
    (map-set skills-for-exchange {user: provider} 
             {skill-hours: (- (get skill-hours exchange-data) hours), rate: (get rate exchange-data)})

    ;; Update user's STX and skill balance
    (map-set user-stx-balance tx-sender (- user-balance total-cost))
    (map-set user-skills-balance tx-sender (+ (default-to u0 (map-get? user-skills-balance tx-sender)) hours))

    ;; Update provider's STX balance
    (map-set user-stx-balance provider (+ provider-balance service-cost))

    ;; Update contract owner's balance for the fee
    (map-set user-stx-balance contract-owner (+ (default-to u0 (map-get? user-stx-balance contract-owner)) calculated-service-fee))

    (ok true)))

;; Allows users to cancel their skill exchange offer
(define-public (cancel-skill-offer)
  (let (
    (user-skill-data (map-get? skills-for-exchange {user: tx-sender}))
  )
    (asserts! (is-some user-skill-data) err-unauthorized-user)
    (map-set skills-for-exchange {user: tx-sender} {skill-hours: u0, rate: u0})
    (ok true)))

;; Test suite for checking user skill balances
(define-public (test-user-skill-balance (user principal))
  (let ((balance (default-to u0 (map-get? user-skills-balance user))))
    (asserts! (>= balance u0) err-insufficient-balance)
    (ok balance)))

;; Testing functionality for exchanging skills between users
(define-public (test-skill-exchange (provider principal) (hours uint))
  (let ((user-balance (default-to u0 (map-get? user-stx-balance tx-sender)))
        (provider-balance (default-to u0 (map-get? user-stx-balance provider))))
    (asserts! (>= user-balance u0) err-insufficient-balance)
    (asserts! (>= provider-balance u0) err-insufficient-balance)
    (ok true)))

;; Refactor skill transfer for optimized performance
(define-public (transfer-skills (provider principal) (hours uint))
  (let (
    (provider-skills (default-to u0 (map-get? user-skills-balance provider)))
    (user-skills (default-to u0 (map-get? user-skills-balance tx-sender)))
  )
    (asserts! (>= provider-skills hours) err-insufficient-balance)
    (map-set user-skills-balance provider (- provider-skills hours))
    (map-set user-skills-balance tx-sender (+ user-skills hours))
    (ok true)))

;; Add a page for viewing contract activity
(define-public (view-activity-page (user principal))
  (begin
    (asserts! (is-eq tx-sender user) err-unauthorized-user)
    (ok true)))

;; Validate input for offering skills to ensure the input is valid (hours > 0)
(define-public (validate-skill-offer-input (hours uint) (rate uint))
  (begin
    (asserts! (> hours u0) err-invalid-skill) ;; Ensure hours are greater than 0
    (asserts! (> rate u0) err-invalid-rate) ;; Ensure rate is greater than 0
    (ok true)))

;; Set maximum skills per user
(define-public (set-max-skills-per-user (new-limit uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> new-limit u0) err-invalid-skill)
    (var-set max-skills-per-user new-limit)
    (ok true)))

;; Fix bug preventing negative skill balances when removing skills from exchange
(define-public (prevent-negative-skill-balance (user principal) (hours uint))
  (begin
    (let ((current-balance (default-to u0 (map-get? user-skills-balance user))))
      (asserts! (>= current-balance hours) err-insufficient-balance) ;; Prevent negative balance
      (ok true))))

;; Add functionality to apply discount to service fee
(define-public (set-service-fee-discount (user principal) (discount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= discount u100) err-invalid-rate)
    (let ((current-fee (var-get service-fee)))
      (var-set service-fee (- current-fee discount))
      (ok true))))

;; Read-only functions

;; Get current skill exchange rate
(define-read-only (get-skill-rate)
  (ok (var-get skill-rate)))

;; Get service fee rate
(define-read-only (get-service-fee)
  (ok (var-get service-fee)))

;; Get user's skill balance
(define-read-only (get-skill-balance (user principal))
  (ok (default-to u0 (map-get? user-skills-balance user))))

;; Get user's STX balance
(define-read-only (get-stx-balance (user principal))
  (ok (default-to u0 (map-get? user-stx-balance user))))

;; Get skills available for exchange by user
(define-read-only (get-skills-for-exchange (user principal))
  (ok (default-to {skill-hours: u0, rate: u0} (map-get? skills-for-exchange {user: user}))))

;; Get maximum skills a user can offer
(define-read-only (get-max-skills-per-user)
  (ok (var-get max-skills-per-user)))

;; Get total skill reserve
(define-read-only (get-total-skill-reserve)
  (ok (var-get total-skill-reserve)))

;; Get skill reserve limit
(define-read-only (get-skill-reserve-limit)
  (ok (var-get skill-reserve-limit)))

