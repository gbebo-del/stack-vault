;; Title: StackVault - Bitcoin-Secured NFT Management Protocol
;; Summary: 
;; Enterprise-grade NFT ecosystem on Stacks Layer 2 featuring collateralized minting,
;; yield-generating staking, fractional ownership, and decentralized marketplace operations
;;
;; Description:
;; StackVault leverages Bitcoin's security through Stacks' Proof-of-Transfer consensus to
;; deliver institutional-grade NFT management capabilities. The protocol introduces novel
;; DeFi mechanics including collateral-backed minting, Bitcoin block-anchored staking rewards,
;; compliant fractional ownership structures, and a non-custodial P2P marketplace with
;; automated fee distribution. Built for scalability and regulatory compliance while
;; maintaining the decentralized ethos of Bitcoin.
;;
;; Key Features:
;; - Collateralized NFT minting with dynamic ratio enforcement
;; - Time-locked staking rewards calculated using Bitcoin block intervals
;; - Fractional ownership with compliant share transfer mechanisms
;; - Automated marketplace with protocol fee mechanics
;; - Trust-minimized architecture leveraging Bitcoin's security model

;; CONSTANTS & ERROR CODES
(define-constant CONTRACT-OWNER tx-sender)

;; Error codes with descriptive naming
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-NOT-TOKEN-OWNER (err u101))
(define-constant ERR-INSUFFICIENT-BALANCE (err u102))
(define-constant ERR-INVALID-TOKEN (err u103))
(define-constant ERR-LISTING-NOT-FOUND (err u104))
(define-constant ERR-INVALID-PRICE (err u105))
(define-constant ERR-INSUFFICIENT-COLLATERAL (err u106))
(define-constant ERR-ALREADY-STAKED (err u107))
(define-constant ERR-NOT-STAKED (err u108))
(define-constant ERR-INVALID-PERCENTAGE (err u109))
(define-constant ERR-INVALID-URI (err u110))
(define-constant ERR-INVALID-RECIPIENT (err u111))
(define-constant ERR-OVERFLOW (err u112))

;; DATA VARIABLES
(define-data-var min-collateral-ratio uint u150) ;; 150% minimum collateral ratio
(define-data-var protocol-fee uint u25) ;; 2.5% fee in basis points (250/10000)
(define-data-var total-staked uint u0) ;; Total number of staked NFTs
(define-data-var yield-rate uint u50) ;; 5% annual yield rate in basis points (500/10000)
(define-data-var total-supply uint u0) ;; Total NFTs minted

;; DATA MAPS

;; Core NFT data structure
(define-map tokens
  { token-id: uint }
  {
    owner: principal,
    uri: (string-ascii 256),
    collateral: uint,
    is-staked: bool,
    stake-timestamp: uint,
    fractional-shares: uint,
  }
)

;; Marketplace listings
(define-map token-listings
  { token-id: uint }
  {
    price: uint,
    seller: principal,
    active: bool,
  }
)

;; Fractional ownership tracking
(define-map fractional-ownership
  {
    token-id: uint,
    owner: principal,
  }
  { shares: uint }
)

;; Staking rewards accumulation
(define-map staking-rewards
  { token-id: uint }
  {
    accumulated-yield: uint,
    last-claim: uint,
  }
)

;; PRIVATE UTILITY FUNCTIONS

;; Validate URI format and length
(define-private (validate-uri (uri (string-ascii 256)))
  (let ((uri-len (len uri)))
    (and
      (> uri-len u0)
      (<= uri-len u256)
    )
  )
)

;; Validate recipient is not contract address
(define-private (validate-recipient (recipient principal))
  (not (is-eq recipient (as-contract tx-sender)))
)

;; Safe addition with overflow protection
(define-private (safe-add
    (a uint)
    (b uint)
  )
  (let ((sum (+ a b)))
    (asserts! (>= sum a) ERR-OVERFLOW)
    (ok sum)
  )
)

;; NFT CORE FUNCTIONS

;; Mint new NFT with collateral requirement
(define-public (mint-nft
    (uri (string-ascii 256))
    (collateral uint)
  )
  (let (
      (token-id (+ (var-get total-supply) u1))
      (collateral-requirement (/ (* (var-get min-collateral-ratio) collateral) u100))
    )
    ;; Input validation
    (asserts! (validate-uri uri) ERR-INVALID-URI)
    (asserts! (>= (stx-get-balance tx-sender) collateral-requirement)
      ERR-INSUFFICIENT-COLLATERAL
    )
    ;; Transfer collateral to contract
    (try! (stx-transfer? collateral-requirement tx-sender (as-contract tx-sender)))
    ;; Create NFT record
    (map-set tokens { token-id: token-id } {
      owner: tx-sender,
      uri: uri,
      collateral: collateral,
      is-staked: false,
      stake-timestamp: u0,
      fractional-shares: u0,
    })
    ;; Update total supply
    (var-set total-supply token-id)
    (ok token-id)
  )
)

;; Transfer NFT ownership
(define-public (transfer-nft
    (token-id uint)
    (recipient principal)
  )
  (let ((token (unwrap! (get-token-info token-id) ERR-INVALID-TOKEN)))
    ;; Validation checks
    (asserts! (validate-recipient recipient) ERR-INVALID-RECIPIENT)
    (asserts! (is-eq tx-sender (get owner token)) ERR-NOT-TOKEN-OWNER)
    (asserts! (not (get is-staked token)) ERR-ALREADY-STAKED)
    ;; Update ownership
    (map-set tokens { token-id: token-id } (merge token { owner: recipient }))
    (ok true)
  )
)

;; MARKETPLACE FUNCTIONS

;; List NFT for sale
(define-public (list-nft
    (token-id uint)
    (price uint)
  )
  (let ((token (unwrap! (get-token-info token-id) ERR-INVALID-TOKEN)))
    ;; Validation
    (asserts! (> price u0) ERR-INVALID-PRICE)
    (asserts! (is-eq tx-sender (get owner token)) ERR-NOT-TOKEN-OWNER)
    (asserts! (not (get is-staked token)) ERR-ALREADY-STAKED)
    ;; Create listing
    (map-set token-listings { token-id: token-id } {
      price: price,
      seller: tx-sender,
      active: true,
    })
    (ok true)
  )
)

;; Purchase listed NFT
(define-public (purchase-nft (token-id uint))
  (let (
      (listing (unwrap! (get-listing token-id) ERR-LISTING-NOT-FOUND))
      (price (get price listing))
      (seller (get seller listing))
      (fee (/ (* price (var-get protocol-fee)) u1000))
    )
    ;; Validation
    (asserts! (get active listing) ERR-LISTING-NOT-FOUND)
    ;; Process payment
    (try! (stx-transfer? price tx-sender seller))
    (try! (stx-transfer? fee tx-sender (as-contract tx-sender)))
    ;; Transfer NFT ownership
    (try! (transfer-nft token-id tx-sender))
    ;; Deactivate listing
    (map-set token-listings { token-id: token-id } {
      price: u0,
      seller: seller,
      active: false,
    })
    (ok true)
  )
)

;; FRACTIONAL OWNERSHIP FUNCTIONS

;; Transfer fractional shares
(define-public (transfer-shares
    (token-id uint)
    (recipient principal)
    (share-amount uint)
  )
  (let (
      (sender-shares (unwrap! (get-fractional-shares token-id tx-sender)
        ERR-INSUFFICIENT-BALANCE
      ))
      (current-recipient-shares (default-to { shares: u0 } (get-fractional-shares token-id recipient)))
      (recipient-new-shares (unwrap! (safe-add (get shares current-recipient-shares) share-amount)
        ERR-OVERFLOW
      ))
    )
    ;; Validation
    (asserts! (validate-recipient recipient) ERR-INVALID-RECIPIENT)
    (asserts! (>= (get shares sender-shares) share-amount)
      ERR-INSUFFICIENT-BALANCE
    )
    ;; Update sender's shares
    (map-set fractional-ownership {
      token-id: token-id,
      owner: tx-sender,
    } { shares: (- (get shares sender-shares) share-amount) }
    )
    ;; Update recipient's shares
    (map-set fractional-ownership {
      token-id: token-id,
      owner: recipient,
    } { shares: recipient-new-shares }
    )
    (ok true)
  )
)

;; STAKING FUNCTIONS

;; Stake NFT for yield generation
(define-public (stake-nft (token-id uint))
  (let ((token (unwrap! (get-token-info token-id) ERR-INVALID-TOKEN)))
    ;; Validation
    (asserts! (is-eq tx-sender (get owner token)) ERR-NOT-TOKEN-OWNER)
    (asserts! (not (get is-staked token)) ERR-ALREADY-STAKED)
    ;; Update token staking status
    (map-set tokens { token-id: token-id }
      (merge token {
        is-staked: true,
        stake-timestamp: stacks-block-height,
      })
    )
    ;; Initialize staking rewards
    (map-set staking-rewards { token-id: token-id } {
      accumulated-yield: u0,
      last-claim: stacks-block-height,
    })
    ;; Update total staked counter
    (var-set total-staked (+ (var-get total-staked) u1))
    (ok true)
  )
)

;; Unstake NFT and claim final rewards
(define-public (unstake-nft (token-id uint))
  (let (
      (token (unwrap! (get-token-info token-id) ERR-INVALID-TOKEN))
      (rewards (unwrap! (get-staking-rewards token-id) ERR-NOT-STAKED))
    )
    ;; Validation
    (asserts! (is-eq tx-sender (get owner token)) ERR-NOT-TOKEN-OWNER)
    (asserts! (get is-staked token) ERR-NOT-STAKED)
    ;; Claim final rewards
    (try! (claim-staking-rewards token-id))
    ;; Update token staking status
    (map-set tokens { token-id: token-id }
      (merge token {
        is-staked: false,
        stake-timestamp: u0,
      })
    )
    ;; Update total staked counter
    (var-set total-staked (- (var-get total-staked) u1))
    (ok true)
  )
)

;; STAKING REWARDS FUNCTIONS

;; Internal function to claim staking rewards
(define-private (claim-staking-rewards (token-id uint))
  (let (
      (rewards (unwrap! (calculate-rewards token-id) ERR-NOT-STAKED))
      (token (unwrap! (get-token-info token-id) ERR-INVALID-TOKEN))
    )
    ;; Ensure token is staked
    (asserts! (get is-staked token) ERR-NOT-STAKED)
    ;; Reset rewards accumulation
    (map-set staking-rewards { token-id: token-id } {
      accumulated-yield: u0,
      last-claim: stacks-block-height,
    })
    ;; Transfer rewards to token owner
    (as-contract (stx-transfer? rewards (as-contract tx-sender) (get owner token)))
  )
)