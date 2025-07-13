# STX Collectible Split

A Clarity smart contract for splitting expensive NFTs into smaller, tradeable shares on the Stacks blockchain.

## Overview

The STX Collectible Split contract enables fractional ownership of NFTs by allowing users to split valuable collectibles into smaller shares. This makes expensive NFTs more accessible to a broader range of investors and collectors.

## Features

- **NFT Fractionalization**: Split any NFT into a specified number of shares
- **Decentralized Trading**: Buy and sell shares directly between users
- **Price Management**: Original owners can adjust share prices
- **Recombination**: Collect all shares to reconstruct the original NFT
- **Secure Transfers**: Direct peer-to-peer share transfers
- **Fungible Token Integration**: Shares are represented as fungible tokens

## How It Works

1. **Split**: An NFT owner calls `split-nft` to divide their NFT into shares
2. **Trade**: Users can buy/sell shares using STX tokens
3. **Transfer**: Direct share transfers between users without payment
4. **Recombine**: When someone owns all shares, they can reconstruct the original NFT

## Contract Functions

### Core Functions

#### `split-nft(nft-contract, nft-id, total-shares, price-per-share)`
Splits an NFT into fractional shares.

**Parameters:**
- `nft-contract`: Principal address of the NFT contract
- `nft-id`: Token ID of the NFT to split
- `total-shares`: Total number of shares to create
- `price-per-share`: Initial price per share in STX

**Returns:** Split ID for the newly created fractional NFT

#### `buy-shares(split-id, shares-to-buy, seller)`
Purchase shares from another user.

**Parameters:**
- `split-id`: ID of the split NFT
- `shares-to-buy`: Number of shares to purchase
- `seller`: Principal address of the seller

#### `sell-shares(split-id, shares-to-sell, buyer)`
Sell shares to another user.

**Parameters:**
- `split-id`: ID of the split NFT
- `shares-to-sell`: Number of shares to sell
- `buyer`: Principal address of the buyer

#### `transfer-shares(split-id, amount, recipient)`
Transfer shares directly to another user without payment.

**Parameters:**
- `split-id`: ID of the split NFT
- `amount`: Number of shares to transfer
- `recipient`: Principal address of the recipient

#### `update-share-price(split-id, new-price)`
Update the price per share (original owner only).

**Parameters:**
- `split-id`: ID of the split NFT
- `new-price`: New price per share in STX

#### `recombine-nft(split-id)`
Reconstruct the original NFT by burning all shares (requires ownership of all shares).

**Parameters:**
- `split-id`: ID of the split NFT

### Read-Only Functions

#### `get-split-info(split-id)`
Returns information about a split NFT.

#### `get-share-balance(split-id, holder)`
Returns the number of shares owned by a specific user.

#### `get-share-price(split-id)`
Returns the current price per share.

#### `get-next-split-id()`
Returns the next available split ID.

## Usage Examples

### Splitting an NFT

```clarity
;; Split an NFT into 100 shares at 10 STX per share
(contract-call? .stx-collectible-split split-nft
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7.my-nft-contract
  u1
  u100
  u10000000) ;; 10 STX in microSTX
```

### Buying Shares

```clarity
;; Buy 5 shares from a seller
(contract-call? .stx-collectible-split buy-shares
  u1
  u5
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

### Checking Share Balance

```clarity
;; Check how many shares a user owns
(contract-call? .stx-collectible-split get-share-balance
  u1
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

## Error Codes

- `u100`: Owner only operation
- `u101`: Split NFT not found
- `u102`: Insufficient shares
- `u103`: NFT already split
- `u104`: Not a shareholder
- `u105`: Invalid amount


## Installation & Deployment

1. Deploy the contract to the Stacks blockchain
2. The contract will automatically initialize with default values
3. Users can immediately start splitting NFTs and trading shares

## Dependencies

- Stacks blockchain
- Clarity smart contract language
- STX tokens for transactions
- Compatible NFT contracts

## Gas Considerations

- Contract calls consume STX for transaction fees
- Larger operations (splitting, recombining) may require more gas
- Share transfers are relatively low-cost operations
