# StackVault - Bitcoin-Secured NFT Management Protocol

[![Stacks](https://img.shields.io/badge/Stacks-Layer%202-purple)](https://stacks.co)
[![Bitcoin](https://img.shields.io/badge/Bitcoin-Secured-orange)](https://bitcoin.org)
[![Clarity](https://img.shields.io/badge/Clarity-Smart%20Contract-blue)](https://clarity-lang.org)

> Enterprise-grade NFT ecosystem on Stacks Layer 2 featuring collateralized minting, yield-generating staking, fractional ownership, and decentralized marketplace operations.

## 🚀 Overview

StackVault is a sophisticated NFT management protocol built on Stacks Layer 2 that leverages Bitcoin's security through Proof-of-Transfer consensus. The protocol combines traditional NFT functionality with advanced DeFi mechanics, creating an institutional-grade platform for digital asset management.

### Key Features

- **🔒 Collateralized Minting**: Dynamic ratio-based collateral requirements
- **💰 Yield Generation**: Bitcoin block-anchored staking rewards
- **📈 Fractional Ownership**: Compliant share transfer mechanisms
- **🏪 Decentralized Marketplace**: Non-custodial P2P trading with automated fees
- **🛡️ Bitcoin Security**: Trust-minimized architecture leveraging Bitcoin's consensus

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        StackVault Protocol                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   NFT Core      │  │   Marketplace   │  │   Staking       │  │
│  │                 │  │                 │  │                 │  │
│  │ • Minting       │  │ • Listing       │  │ • Yield Calc    │  │
│  │ • Transfers     │  │ • Purchases     │  │ • Rewards       │  │
│  │ • Collateral    │  │ • Fee Handling  │  │ • Time Locks    │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │  Fractional     │  │   Validation    │  │     Admin       │  │
│  │  Ownership      │  │                 │  │                 │  │
│  │                 │  │ • Input Checks  │  │ • Fee Updates   │  │
│  │ • Share Mgmt    │  │ • Overflow      │  │ • Rate Changes  │  │
│  │ • Transfers     │  │ • URI Validation│  │ • Ratio Adjust  │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                    Stacks Layer 2 Network                      │
├─────────────────────────────────────────────────────────────────┤
│                    Bitcoin Base Layer                          │
└─────────────────────────────────────────────────────────────────┘
```

## 📊 Contract Architecture

### Core Data Structures

#### Token Management

```clarity
(define-map tokens
    { token-id: uint }
    {
        owner: principal,
        uri: (string-ascii 256),
        collateral: uint,
        is-staked: bool,
        stake-timestamp: uint,
        fractional-shares: uint
    }
)
```

#### Marketplace Operations

```clarity
(define-map token-listings
    { token-id: uint }
    {
        price: uint,
        seller: principal,
        active: bool
    }
)
```

#### Fractional Ownership

```clarity
(define-map fractional-ownership
    { token-id: uint, owner: principal }
    { shares: uint }
)
```

#### Staking Rewards

```clarity
(define-map staking-rewards
    { token-id: uint }
    { 
        accumulated-yield: uint,
        last-claim: uint
    }
)
```

### Function Categories

| Category | Functions | Description |
|----------|-----------|-------------|
| **Core NFT** | `mint-nft`, `transfer-nft` | Basic NFT operations with collateral |
| **Marketplace** | `list-nft`, `purchase-nft` | P2P trading with automated fees |
| **Fractional** | `transfer-shares` | Share-based ownership management |
| **Staking** | `stake-nft`, `unstake-nft` | Yield generation mechanisms |
| **Admin** | `set-protocol-fee`, `set-yield-rate` | Protocol parameter management |

## 🔄 Data Flow

### NFT Minting Process

```
User Request → Collateral Check → STX Transfer → NFT Creation → Token ID Return
```

### Staking Workflow

```
Stake Request → Ownership Verify → Update Status → Initialize Rewards → Yield Accumulation
```

### Marketplace Transaction

```
List NFT → Purchase Request → Payment Processing → Ownership Transfer → Fee Distribution
```

## 🛠️ Installation & Deployment

### Prerequisites

- Stacks CLI installed
- Clarinet for local development
- STX tokens for deployment

### Local Development

```bash
# Clone repository
git clone https://github.com/your-org/stackvault
cd stackvault

# Install Clarinet
curl -L https://github.com/hirosystems/clarinet/releases/latest/download/clarinet-linux-x64.tar.gz | tar xz
sudo mv clarinet /usr/local/bin

# Initialize project
clarinet new stackvault-project
cd stackvault-project

# Add contract
clarinet contract new stackvault
```

### Deployment

```bash
# Deploy to testnet
clarinet deploy --testnet

# Deploy to mainnet (production)
clarinet deploy --mainnet
```

## 🔧 Configuration

### Protocol Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `min-collateral-ratio` | 150% | Minimum collateral for minting |
| `protocol-fee` | 2.5% | Marketplace transaction fee |
| `yield-rate` | 5% | Annual staking yield rate |

### Admin Functions

```clarity
;; Update protocol fee (max 10%)
(set-protocol-fee u25)

;; Update yield rate (max 20%)
(set-yield-rate u50)

;; Update collateral ratio (min 100%)
(set-min-collateral-ratio u150)
```

## 📋 API Reference

### Core Functions

#### `mint-nft`

```clarity
(mint-nft (uri (string-ascii 256)) (collateral uint))
```

Creates a new NFT with specified URI and collateral requirement.

#### `transfer-nft`

```clarity
(transfer-nft (token-id uint) (recipient principal))
```

Transfers NFT ownership to specified recipient.

#### `stake-nft`

```clarity
(stake-nft (token-id uint))
```

Stakes NFT for yield generation based on Bitcoin block intervals.

### Read-Only Functions

#### `get-token-info`

```clarity
(get-token-info (token-id uint))
```

Returns comprehensive token information including ownership and staking status.

#### `calculate-rewards`

```clarity
(calculate-rewards (token-id uint))
```

Calculates accumulated staking rewards based on Bitcoin block progression.

## 🔐 Security Features

- **Collateral Protection**: Dynamic ratio enforcement prevents under-collateralized minting
- **Overflow Protection**: SafeMath implementation prevents arithmetic overflow
- **Input Validation**: Comprehensive validation for all user inputs
- **Access Control**: Owner-only functions for critical parameter updates
- **Bitcoin Anchoring**: Leverages Bitcoin's security through Stacks PoX consensus

## 📈 Economics

### Fee Structure

- **Marketplace Fee**: 2.5% of transaction value
- **Staking Rewards**: 5% annual yield (adjustable)
- **Collateral Ratio**: 150% minimum (adjustable)

### Token Utility

- **STX**: Primary currency for all operations
- **Collateral**: Required for NFT minting
- **Fees**: Distributed to protocol treasury
- **Rewards**: Paid from staking pool

## 🧪 Testing

### Unit Tests

```bash
# Run all tests
clarinet test

# Run specific test
clarinet test tests/stackvault_test.ts
```

### Integration Tests

```bash
# Test full workflow
clarinet run scripts/integration-test.ts
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Resources

- [Stacks Documentation](https://docs.stacks.co)
- [Clarity Language Guide](https://clarity-lang.org)
- [Bitcoin Whitepaper](https://bitcoin.org/bitcoin.pdf)
- [Proof-of-Transfer](https://stacks.org/proof-of-transfer)
