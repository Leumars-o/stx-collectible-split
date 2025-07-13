;; STX Collectible Split Contract
;; Split expensive NFTs into smaller tradeable shares

;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-insufficient-shares (err u102))
(define-constant err-already-split (err u103))
(define-constant err-not-shareholder (err u104))
(define-constant err-invalid-amount (err u105))

;; Define data variables
(define-data-var next-split-id uint u1)

;; Define data maps
(define-map split-nfts
  uint
  {
    nft-contract: principal,
    nft-id: uint,
    total-shares: uint,
    shares-outstanding: uint,
    original-owner: principal,
    split-active: bool
  }
)

(define-map share-balances
  { split-id: uint, holder: principal }
  { shares: uint }
)

(define-map share-prices
  uint
  { price-per-share: uint }
)

;; Define fungible token for shares
(define-fungible-token collectible-shares)

;; Read-only functions
(define-read-only (get-split-info (split-id uint))
  (map-get? split-nfts split-id)
)

(define-read-only (get-share-balance (split-id uint) (holder principal))
  (default-to 
    { shares: u0 }
    (map-get? share-balances { split-id: split-id, holder: holder })
  )
)

(define-read-only (get-share-price (split-id uint))
  (map-get? share-prices split-id)
)

(define-read-only (get-next-split-id)
  (var-get next-split-id)
)

;; Private functions
(define-private (is-valid-split (split-id uint))
  (match (map-get? split-nfts split-id)
    split-info (get split-active split-info)
    false
  )
)

;; Public functions

;; Split an NFT into shares
(define-public (split-nft (nft-contract principal) (nft-id uint) (total-shares uint) (price-per-share uint))
  (let 
    (
      (split-id (var-get next-split-id))
    )
    (asserts! (> total-shares u0) err-invalid-amount)
    (asserts! (> price-per-share u0) err-invalid-amount)
    
    ;; Store split information
    (map-set split-nfts split-id {
      nft-contract: nft-contract,
      nft-id: nft-id,
      total-shares: total-shares,
      shares-outstanding: total-shares,
      original-owner: tx-sender,
      split-active: true
    })
    
    ;; Set initial share price
    (map-set share-prices split-id {
      price-per-share: price-per-share
    })
    
    ;; Give all shares to the original owner initially
    (map-set share-balances 
      { split-id: split-id, holder: tx-sender }
      { shares: total-shares }
    )
    
    ;; Mint fungible tokens representing the shares
    (try! (ft-mint? collectible-shares total-shares tx-sender))
    
    ;; Increment split ID for next use
    (var-set next-split-id (+ split-id u1))
    
    (ok split-id)
  )
)

;; Buy shares from the market
(define-public (buy-shares (split-id uint) (shares-to-buy uint) (seller principal))
  (let
    (
      (split-info (unwrap! (map-get? split-nfts split-id) err-not-found))
      (seller-balance (get shares (get-share-balance split-id seller)))
      (buyer-balance (get shares (get-share-balance split-id tx-sender)))
      (price-info (unwrap! (map-get? share-prices split-id) err-not-found))
      (total-cost (* shares-to-buy (get price-per-share price-info)))
    )
    (asserts! (get split-active split-info) err-not-found)
    (asserts! (>= seller-balance shares-to-buy) err-insufficient-shares)
    (asserts! (> shares-to-buy u0) err-invalid-amount)
    
    ;; Transfer STX from buyer to seller
    (try! (stx-transfer? total-cost tx-sender seller))
    
    ;; Transfer fungible tokens
    (try! (ft-transfer? collectible-shares shares-to-buy seller tx-sender))
    
    ;; Update seller balance
    (map-set share-balances
      { split-id: split-id, holder: seller }
      { shares: (- seller-balance shares-to-buy) }
    )
    
    ;; Update buyer balance
    (map-set share-balances
      { split-id: split-id, holder: tx-sender }
      { shares: (+ buyer-balance shares-to-buy) }
    )
    
    (ok true)
  )
)

;; Sell shares to the market
(define-public (sell-shares (split-id uint) (shares-to-sell uint) (buyer principal))
  (let
    (
      (split-info (unwrap! (map-get? split-nfts split-id) err-not-found))
      (seller-balance (get shares (get-share-balance split-id tx-sender)))
      (buyer-balance (get shares (get-share-balance split-id buyer)))
      (price-info (unwrap! (map-get? share-prices split-id) err-not-found))
      (total-cost (* shares-to-sell (get price-per-share price-info)))
    )
    (asserts! (get split-active split-info) err-not-found)
    (asserts! (>= seller-balance shares-to-sell) err-insufficient-shares)
    (asserts! (> shares-to-sell u0) err-invalid-amount)
    
    ;; Transfer STX from buyer to seller
    (try! (stx-transfer? total-cost buyer tx-sender))
    
    ;; Transfer fungible tokens
    (try! (ft-transfer? collectible-shares shares-to-sell tx-sender buyer))
    
    ;; Update seller balance
    (map-set share-balances
      { split-id: split-id, holder: tx-sender }
      { shares: (- seller-balance shares-to-sell) }
    )
    
    ;; Update buyer balance
    (map-set share-balances
      { split-id: split-id, holder: buyer }
      { shares: (+ buyer-balance shares-to-sell) }
    )
    
    (ok true)
  )
)

;; Update share price (only original owner can do this)
(define-public (update-share-price (split-id uint) (new-price uint))
  (let
    (
      (split-info (unwrap! (map-get? split-nfts split-id) err-not-found))
    )
    (asserts! (is-eq tx-sender (get original-owner split-info)) err-owner-only)
    (asserts! (> new-price u0) err-invalid-amount)
    
    (map-set share-prices split-id {
      price-per-share: new-price
    })
    
    (ok true)
  )
)

;; Recombine shares back to original NFT (requires all shares)
(define-public (recombine-nft (split-id uint))
  (let
    (
      (split-info (unwrap! (map-get? split-nfts split-id) err-not-found))
      (user-shares (get shares (get-share-balance split-id tx-sender)))
      (total-shares (get total-shares split-info))
    )
    (asserts! (get split-active split-info) err-not-found)
    (asserts! (is-eq user-shares total-shares) err-insufficient-shares)
    
    ;; Burn all fungible tokens
    (try! (ft-burn? collectible-shares total-shares tx-sender))
    
    ;; Mark split as inactive
    (map-set split-nfts split-id
      (merge split-info { split-active: false })
    )
    
    ;; Clear user's share balance
    (map-delete share-balances { split-id: split-id, holder: tx-sender })
    
    (ok true)
  )
)

;; Transfer shares between users
(define-public (transfer-shares (split-id uint) (amount uint) (recipient principal))
  (let
    (
      (split-info (unwrap! (map-get? split-nfts split-id) err-not-found))
      (sender-balance (get shares (get-share-balance split-id tx-sender)))
      (recipient-balance (get shares (get-share-balance split-id recipient)))
    )
    (asserts! (get split-active split-info) err-not-found)
    (asserts! (>= sender-balance amount) err-insufficient-shares)
    (asserts! (> amount u0) err-invalid-amount)
    
    ;; Transfer fungible tokens
    (try! (ft-transfer? collectible-shares amount tx-sender recipient))
    
    ;; Update sender balance
    (map-set share-balances
      { split-id: split-id, holder: tx-sender }
      { shares: (- sender-balance amount) }
    )
    
    ;; Update recipient balance
    (map-set share-balances
      { split-id: split-id, holder: recipient }
      { shares: (+ recipient-balance amount) }
    )
    
    (ok true)
  )
)