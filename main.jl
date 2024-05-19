using batteryopt
using CSV, DataFrames, SCS


# Read the data stored in a csv
data = CSV.read("data/realistic_energy_prices.csv", DataFrame)

# Extract the data from the DataFrame
time_idx = data[:, "Datetime"]
energy_buy = data[:, "Buy Price (USD/MWh)"]
energy_sell = data[:, "Sell Price (USD/MWh)"]

GenericBattery = batteryopt.GenericBattery(
    "Ideal Battery",
    250.00,
    1.0,
    125.0,
    125.0,
    1.00,
    0.00
)


prices = batteryopt.EnergyPrices(energy_buy, energy_sell, time_idx)

config = batteryopt.OptimizerConfig(
    optimizer = SCS.Optimizer,
    linear_solver = SCS.Direct,
    max_time = 60,
    max_iter = 1000
)

# Run the optimization



