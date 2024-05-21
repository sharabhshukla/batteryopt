using batteryopt
using CSV, DataFrames, SCS, HiGHS, PlotlyJS


@info "Reading data from CSV"
# Read the data stored in a csv
data = CSV.read("data/realistic_energy_prices.csv", DataFrame)

@show first(data, 5)


@info "Extracting data from DataFrame"
# Extract the data from the DataFrame
time_idx = data[:, "Datetime"]
energy_buy = data[:, "Buy Price (USD/MWh)"]
energy_sell = data[:, "Sell Price (USD/MWh)"]

@assert length(energy_buy) == length(energy_sell) == length(time_idx)

GenericBattery = batteryopt.GenericBattery(
    "Ideal Battery",
    0.250,
    1.00,
    0.125,
    0.125,
    1.00,
    0.00
)


prices = batteryopt.EnergyPrices(energy_buy, energy_sell, time_idx)

config = batteryopt.ModelConfig(
    HiGHS.Optimizer,
    SCS.LinearSolver,
    60,
    1000,
    1e-6,
    true
)

# Run the optimization
@info "Running optimization"
charging_power, discharging_power, energy_stored, revenue = batteryopt.energy_arbitrage!(GenericBattery, prices, 0.0, config)
@info "Optimization complete"
@info "Revenue: $revenue"

results = batteryopt.Results(prices, charging_power, discharging_power, energy_stored, revenue)

batteryopt.plot_results!(results)