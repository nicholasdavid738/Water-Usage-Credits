# 💧 Water Usage Credits

A blockchain-based water conservation incentive system that rewards sustainable farming practices with tradeable water credits.

## 🌱 Overview

Farmers earn Water Credits (WC) tokens by implementing sustainable water practices. Credits can be spent for water usage rights, creating a market-driven conservation economy.

## ⚡ Features

- **🎯 Earn Credits**: Get tokens for sustainable practices like drip irrigation, cover crops
- **💰 Spend Credits**: Use tokens for water usage allocation  
- **📊 Conservation Score**: Track your sustainability performance
- **🔍 Oracle Verified**: Trusted oracles validate practices and usage
- **💱 Tradeable**: Transfer credits between farmers

## 🚀 Getting Started

### For Farmers

1. **Register as Farmer**
   ```clarity
   (contract-call? .water-usage-credits register-farmer)
   ```

2. **Check Your Balance**
   ```clarity
   (contract-call? .water-usage-credits get-balance tx-sender)
   ```

3. **View Conservation Score**
   ```clarity
   (contract-call? .water-usage-credits get-conservation-score tx-sender)
   ```

### For Oracles

1. **Report Sustainable Practice**
   ```clarity
   (contract-call? .water-usage-credits report-sustainable-practice 
     'ST1FARMER123... 
     "drip-irrigation" 
     u85)
   ```

2. **Record Water Usage**
   ```clarity
   (contract-call? .water-usage-credits burn-for-water-usage 
     'ST1FARMER123... 
     u1000 
     "surface-water")
   ```

## 🏆 Sustainable Practices & Rewards

| Practice | Base Rate | Description |
|----------|-----------|-------------|
| 🚿 Drip Irrigation | 50 WC | Efficient water delivery system |
| 🌾 Cover Crops | 30 WC | Soil moisture retention |
| 📱 Soil Monitoring | 40 WC | Data-driven irrigation |
| 🌧️ Rainwater Harvesting | 60 WC | Natural water collection |
| 🔄 Crop Rotation | 25 WC | Sustainable farming cycles |
| 🎯 Precision Farming | 45 WC | Technology-optimized agriculture |

## 💧 Water Types & Burn Rates

- **Surface Water**: 1:1 ratio (1 WC per unit)
- **Groundwater**: 2:1 ratio (2 WC per unit) - higher conservation priority

## 📋 Contract Functions

### Public Functions
- `register-farmer()` - Register as a farmer
- `transfer(amount, from, to, memo)` - Transfer credits between accounts
- `report-sustainable-practice(farmer, practice, efficiency)` - Oracle reports sustainable practice
- `burn-for-water-usage(farmer, usage, water-type)` - Oracle records water usage

### Read-Only Functions
- `get-farmer-info(farmer)` - Get farmer statistics
- `get-conservation-score(farmer)` - Get conservation performance
- `calculate-water-allowance(farmer)` - Calculate enhanced water rights
- `is-farmer-registered(farmer)` - Check registration status
- `is-oracle-authorized(oracle)` - Check oracle authorization

### Owner Functions
- `authorize-oracle(oracle)` - Add trusted oracle
- `revoke-oracle(oracle)` - Remove oracle authorization
- `set-practice-rate(practice, rate)` - Update practice reward rates
- `emergency-mint(farmer, amount)` - Emergency credit allocation

## 🔧 Development

### Deploy Contract
```bash
clarinet deploy --devnet
```

### Run Tests
```bash
clarinet test
```

### Check Contract
```bash
clarinet check
```

## 🏗️ Architecture

The system uses a three-party model:
- **Farmers**: Earn and spend water credits
- **Oracles**: Verify practices and water usage
- **Contract Owner**: Manage system parameters

Conservation scores influence water allowances, creating incentives for long-term sustainable behavior.

## 🎮 Example Workflow

1. Farmer registers: `(contract-call? .water-usage-credits register-farmer)`
2. Oracle reports drip irrigation at 90% efficiency
3. Farmer earns 45 WC (50 base × 90% efficiency ÷ 10)
4. Farmer uses 500 units surface water → burns 500 WC
5. Conservation score increases, boosting future water allowance

## 📄 License

MIT License
