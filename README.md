# VolatilityVault

A synthetic assets smart contract for the Stacks blockchain that creates synthetic exposure to traditional volatility indices, particularly the VIX (Volatility Index). This contract enables users to gain exposure to volatility markets through collateralized synthetic tokens.

## 🚀 Features

- **Synthetic VIX Token Minting**: Create synthetic exposure to VIX without holding the underlying asset
- **Collateral Management**: STX-based collateral system with configurable ratios
- **Oracle Integration**: External price feed support for real-time volatility index pricing
- **Multiple Volatility Indices**: Support for VIX, VIX9D, and custom volatility indices
- **Risk Management**: Built-in liquidation thresholds and collateralization requirements
- **Emergency Controls**: Admin functions for market shutdown and recovery
- **Synthetic Asset Creation**: Framework for creating custom synthetic assets

## 📋 Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity 2.0
- **Epoch**: 2.5
- **Collateral Asset**: STX
- **Minimum Collateral Ratio**: 150%
- **Liquidation Threshold**: 120%
- **Price Precision**: 6 decimal places (1,000,000)

## 🛠 Installation

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) CLI tool
- Node.js (v16+)
- npm or yarn

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd VolatilityVault
```

2. Navigate to the contract directory:
```bash
cd VolatilityVault_contract
```

3. Install dependencies:
```bash
npm install
```

4. Run tests:
```bash
npm test
```

## 📖 Usage Examples

### Initializing the Contract

```clarity
;; Initialize volatility indices (Owner only)
(contract-call? .VolatilityVault initialize-indices)
```

### Setting Oracle

```clarity
;; Set oracle address for price updates (Owner only)
(contract-call? .VolatilityVault set-oracle 'SP1234567890ABCDEF)
```

### User Operations

#### Deposit Collateral
```clarity
;; Deposit 1000 STX as collateral
(contract-call? .VolatilityVault deposit-collateral u1000000000)
```

#### Mint Synthetic VIX Tokens
```clarity
;; Mint 100 synthetic VIX tokens
(contract-call? .VolatilityVault mint-synthetic-vix u100000000)
```

#### Burn Synthetic VIX Tokens
```clarity
;; Burn 50 synthetic VIX tokens
(contract-call? .VolatilityVault burn-synthetic-vix u50000000)
```

#### Withdraw Collateral
```clarity
;; Withdraw available collateral
(contract-call? .VolatilityVault withdraw-collateral u500000000)
```

### Price Updates

```clarity
;; Update VIX price to 25.50 (Oracle or Owner only)
(contract-call? .VolatilityVault update-vix-price u25500000)
```

## 📚 Contract Functions Documentation

### Public Functions

#### Administrative Functions

- **`initialize-indices()`**: Initialize default volatility indices (VIX, VIX9D)
- **`set-oracle(new-oracle: principal)`**: Set oracle address for price updates
- **`emergency-shutdown()`**: Emergency market shutdown
- **`resume-operations()`**: Resume normal operations
- **`create-synthetic-asset(...)`**: Create new synthetic assets

#### User Functions

- **`deposit-collateral(amount: uint)`**: Deposit STX collateral
- **`mint-synthetic-vix(amount: uint)`**: Mint synthetic VIX tokens
- **`burn-synthetic-vix(amount: uint)`**: Burn synthetic VIX tokens
- **`withdraw-collateral(amount: uint)`**: Withdraw available collateral

#### Oracle Functions

- **`update-vix-price(new-price: uint)`**: Update VIX price (Oracle/Owner only)

### Read-Only Functions

- **`get-vix-price()`**: Current VIX price
- **`get-user-collateral(user: principal)`**: User's collateral balance
- **`get-user-synthetic-position(user: principal)`**: User's synthetic token position
- **`get-volatility-index(symbol: string-ascii)`**: Volatility index information
- **`get-synthetic-asset(asset-id: uint)`**: Synthetic asset details
- **`get-collateralization-ratio(user: principal)`**: User's collateralization ratio
- **`is-liquidatable(user: principal)`**: Check if position is liquidatable
- **`get-contract-stats()`**: Overall contract statistics
- **`get-vix-token-balance(user: principal)`**: User's VIX token balance

### Error Codes

- `u100`: ERR-OWNER-ONLY - Only contract owner can perform this action
- `u101`: ERR-NOT-AUTHORIZED - Not authorized to perform this action
- `u102`: ERR-INVALID-AMOUNT - Invalid amount provided
- `u103`: ERR-INSUFFICIENT-BALANCE - Insufficient balance
- `u104`: ERR-INVALID-PRICE - Invalid price value
- `u105`: ERR-MARKET-CLOSED - Market is currently closed
- `u106`: ERR-ORACLE-NOT-SET - Oracle address not configured

## 🚀 Deployment Guide

### Local Development

1. Start Clarinet console:
```bash
clarinet console
```

2. Deploy contract:
```clarity
(contract-call? .VolatilityVault initialize-indices)
```

### Testnet Deployment

1. Configure testnet settings in `settings/Testnet.toml`
2. Deploy using Clarinet:
```bash
clarinet deployments generate --testnet
clarinet deployments apply --testnet
```

### Mainnet Deployment

1. Configure mainnet settings in `settings/Mainnet.toml`
2. Deploy using Clarinet:
```bash
clarinet deployments generate --mainnet
clarinet deployments apply --mainnet
```

## 🔒 Security Notes

### Risk Factors

- **Collateral Risk**: Users must maintain adequate collateral ratios to avoid liquidation
- **Oracle Risk**: Price accuracy depends on oracle reliability
- **Smart Contract Risk**: Standard smart contract risks apply
- **Market Risk**: Volatility exposure carries inherent market risks

### Security Features

- **Collateral Requirements**: 150% minimum collateralization protects the system
- **Liquidation Mechanism**: 120% threshold prevents undercollateralization
- **Owner Controls**: Emergency shutdown capability for crisis management
- **Oracle Authorization**: Only authorized oracles can update prices

### Best Practices

1. **Monitor Collateral Ratios**: Keep ratios well above the minimum requirement
2. **Oracle Verification**: Verify oracle addresses and price accuracy
3. **Testing**: Thoroughly test all interactions on testnet first
4. **Risk Management**: Understand volatility exposure and market conditions

## 🧪 Testing

Run the test suite:
```bash
npm test
```

For coverage and cost analysis:
```bash
npm run test:report
```

Watch mode for development:
```bash
npm run test:watch
```

## 📈 Contract Architecture

```
VolatilityVault
├── Fungible Tokens
│   ├── vix-token (Synthetic VIX)
│   └── volatility-share (Volatility shares)
├── Data Storage
│   ├── user-collateral (STX deposits)
│   ├── user-synthetic-positions (Synthetic holdings)
│   ├── volatility-indices (Index data)
│   └── synthetic-assets (Asset registry)
└── Core Functions
    ├── Collateral Management
    ├── Token Minting/Burning
    ├── Price Oracle Integration
    └── Risk Management
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## 📄 License

This project is licensed under the ISC License.

## ⚠️ Disclaimer

This software is provided "as is" without warranty. Users are responsible for understanding the risks associated with synthetic assets and volatility exposure. This is experimental software and should be used with caution, especially in production environments.

---

**Note**: This is a synthetic assets contract for educational and experimental purposes. Always conduct thorough testing and security audits before mainnet deployment.