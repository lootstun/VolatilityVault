
;; title: VolatilityVault
;; version: 1.0.0
;; summary: A synthetic assets smart contract for volatility index tracking
;; description: Creates synthetic exposure to traditional assets with VIX and volatility index tracking

;; traits
;;

;; token definitions
(define-fungible-token vix-token)
(define-fungible-token volatility-share)

;; constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-INVALID-AMOUNT (err u102))
(define-constant ERR-INSUFFICIENT-BALANCE (err u103))
(define-constant ERR-INVALID-PRICE (err u104))
(define-constant ERR-MARKET-CLOSED (err u105))
(define-constant ERR-ORACLE-NOT-SET (err u106))

;; Oracle constants
(define-constant PRICE-PRECISION u1000000) ;; 6 decimal places
(define-constant MIN-COLLATERAL-RATIO u150) ;; 150% collateralization
(define-constant LIQUIDATION-THRESHOLD u120) ;; 120% liquidation threshold

;; data vars
(define-data-var contract-owner principal CONTRACT-OWNER)
(define-data-var oracle-address (optional principal) none)
(define-data-var vix-price uint u20000000) ;; Default VIX price 20.00
(define-data-var volatility-multiplier uint u100) ;; 1.00x multiplier
(define-data-var market-open bool true)
(define-data-var total-collateral uint u0)
(define-data-var total-synthetic-supply uint u0)

;; data maps
(define-map user-collateral principal uint)
(define-map user-synthetic-positions principal uint)
(define-map volatility-indices 
  { symbol: (string-ascii 10) }
  { 
    price: uint,
    last-updated: uint,
    volatility-factor: uint
  }
)

;; Asset tracking
(define-map synthetic-assets
  { asset-id: uint }
  {
    name: (string-ascii 20),
    symbol: (string-ascii 10),
    underlying-price: uint,
    volatility-index: uint,
    total-supply: uint,
    created-at: uint
  }
)

(define-data-var next-asset-id uint u1)

;; public functions

;; Initialize volatility indices
(define-public (initialize-indices)
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-OWNER-ONLY)
    (map-set volatility-indices 
      { symbol: "VIX" }
      { 
        price: u20000000,
        last-updated: block-height,
        volatility-factor: u100
      }
    )
    (map-set volatility-indices 
      { symbol: "VIX9D" }
      { 
        price: u22000000,
        last-updated: block-height,
        volatility-factor: u110
      }
    )
    (ok true)
  )
)

;; Set oracle address (only owner)
(define-public (set-oracle (new-oracle principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-OWNER-ONLY)
    (var-set oracle-address (some new-oracle))
    (ok true)
  )
)

;; Update VIX price (only oracle or owner)
(define-public (update-vix-price (new-price uint))
  (let ((oracle (var-get oracle-address)))
    (asserts! 
      (or 
        (is-eq tx-sender (var-get contract-owner))
        (and (is-some oracle) (is-eq tx-sender (unwrap-panic oracle)))
      ) 
      ERR-NOT-AUTHORIZED
    )
    (asserts! (> new-price u0) ERR-INVALID-PRICE)
    (var-set vix-price new-price)
    (map-set volatility-indices 
      { symbol: "VIX" }
      { 
        price: new-price,
        last-updated: block-height,
        volatility-factor: u100
      }
    )
    (ok true)
  )
)

;; Create synthetic asset
(define-public (create-synthetic-asset 
  (name (string-ascii 20))
  (symbol (string-ascii 10))
  (underlying-price uint)
  (volatility-index uint)
)
  (let ((asset-id (var-get next-asset-id)))
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-OWNER-ONLY)
    (asserts! (> underlying-price u0) ERR-INVALID-PRICE)
    (map-set synthetic-assets
      { asset-id: asset-id }
      {
        name: name,
        symbol: symbol,
        underlying-price: underlying-price,
        volatility-index: volatility-index,
        total-supply: u0,
        created-at: block-height
      }
    )
    (var-set next-asset-id (+ asset-id u1))
    (ok asset-id)
  )
)

;; Deposit collateral (STX)
(define-public (deposit-collateral (amount uint))
  (let ((current-balance (default-to u0 (map-get? user-collateral tx-sender))))
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (var-get market-open) ERR-MARKET-CLOSED)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set user-collateral tx-sender (+ current-balance amount))
    (var-set total-collateral (+ (var-get total-collateral) amount))
    (ok true)
  )
)

;; Mint synthetic VIX tokens
(define-public (mint-synthetic-vix (amount uint))
  (let (
    (user-collateral-balance (default-to u0 (map-get? user-collateral tx-sender)))
    (vix-price-current (var-get vix-price))
    (required-collateral (/ (* amount vix-price-current MIN-COLLATERAL-RATIO) (* PRICE-PRECISION u100)))
    (current-synthetic (default-to u0 (map-get? user-synthetic-positions tx-sender)))
  )
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (var-get market-open) ERR-MARKET-CLOSED)
    (asserts! (>= user-collateral-balance required-collateral) ERR-INSUFFICIENT-BALANCE)
    
    ;; Mint VIX tokens to user
    (try! (ft-mint? vix-token amount tx-sender))
    
    ;; Update user synthetic position
    (map-set user-synthetic-positions tx-sender (+ current-synthetic amount))
    (var-set total-synthetic-supply (+ (var-get total-synthetic-supply) amount))
    
    (ok true)
  )
)

;; Burn synthetic VIX tokens
(define-public (burn-synthetic-vix (amount uint))
  (let (
    (current-synthetic (default-to u0 (map-get? user-synthetic-positions tx-sender)))
    (vix-token-balance (ft-get-balance vix-token tx-sender))
  )
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (<= amount current-synthetic) ERR-INSUFFICIENT-BALANCE)
    (asserts! (<= amount vix-token-balance) ERR-INSUFFICIENT-BALANCE)
    
    ;; Burn VIX tokens from user
    (try! (ft-burn? vix-token amount tx-sender))
    
    ;; Update user synthetic position
    (map-set user-synthetic-positions tx-sender (- current-synthetic amount))
    (var-set total-synthetic-supply (- (var-get total-synthetic-supply) amount))
    
    (ok true)
  )
)

;; Withdraw collateral
(define-public (withdraw-collateral (amount uint))
  (let (
    (user-collateral-balance (default-to u0 (map-get? user-collateral tx-sender)))
    (user-synthetic-balance (default-to u0 (map-get? user-synthetic-positions tx-sender)))
    (vix-price-current (var-get vix-price))
    (required-collateral (/ (* user-synthetic-balance vix-price-current MIN-COLLATERAL-RATIO) (* PRICE-PRECISION u100)))
    (available-collateral (- user-collateral-balance required-collateral))
  )
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (<= amount available-collateral) ERR-INSUFFICIENT-BALANCE)
    
    ;; Transfer STX back to user
    (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
    
    ;; Update user collateral
    (map-set user-collateral tx-sender (- user-collateral-balance amount))
    (var-set total-collateral (- (var-get total-collateral) amount))
    
    (ok true)
  )
)

;; Emergency shutdown (owner only)
(define-public (emergency-shutdown)
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-OWNER-ONLY)
    (var-set market-open false)
    (ok true)
  )
)

;; Resume operations (owner only)
(define-public (resume-operations)
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-OWNER-ONLY)
    (var-set market-open true)
    (ok true)
  )
)

;; read only functions

;; Get VIX price
(define-read-only (get-vix-price)
  (var-get vix-price)
)

;; Get user collateral
(define-read-only (get-user-collateral (user principal))
  (default-to u0 (map-get? user-collateral user))
)

;; Get user synthetic position
(define-read-only (get-user-synthetic-position (user principal))
  (default-to u0 (map-get? user-synthetic-positions user))
)

;; Get volatility index
(define-read-only (get-volatility-index (symbol (string-ascii 10)))
  (map-get? volatility-indices { symbol: symbol })
)

;; Get synthetic asset info
(define-read-only (get-synthetic-asset (asset-id uint))
  (map-get? synthetic-assets { asset-id: asset-id })
)

;; Calculate collateralization ratio
(define-read-only (get-collateralization-ratio (user principal))
  (let (
    (user-collateral-balance (default-to u0 (map-get? user-collateral user)))
    (user-synthetic-balance (default-to u0 (map-get? user-synthetic-positions user)))
    (vix-price-current (var-get vix-price))
  )
    (if (is-eq user-synthetic-balance u0)
      u0
      (/ (* user-collateral-balance PRICE-PRECISION u100) (* user-synthetic-balance vix-price-current))
    )
  )
)

;; Check if position is liquidatable
(define-read-only (is-liquidatable (user principal))
  (let ((ratio (get-collateralization-ratio user)))
    (and 
      (> ratio u0)
      (< ratio LIQUIDATION-THRESHOLD)
    )
  )
)

;; Get contract stats
(define-read-only (get-contract-stats)
  {
    total-collateral: (var-get total-collateral),
    total-synthetic-supply: (var-get total-synthetic-supply),
    vix-price: (var-get vix-price),
    market-open: (var-get market-open),
    next-asset-id: (var-get next-asset-id)
  }
)

;; Get VIX token balance
(define-read-only (get-vix-token-balance (user principal))
  (ft-get-balance vix-token user)
)

;; private functions

;; Calculate required collateral
(define-private (calculate-required-collateral (synthetic-amount uint) (price uint))
  (/ (* synthetic-amount price MIN-COLLATERAL-RATIO) (* PRICE-PRECISION u100))
)

;; Validate collateral ratio
(define-private (validate-collateral-ratio (user principal))
  (let ((ratio (get-collateralization-ratio user)))
    (>= ratio MIN-COLLATERAL-RATIO)
  )
)
