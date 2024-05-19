using batteryopt
using CSV, DataFrames, SCS, Gadfly


@info "Reading data from CSV"
# Read the data stored in a csv
data = CSV.read("data/realistic_energy_prices.csv", DataFrame)


@info "Extracting data from DataFrame"
# Extract the data from the DataFrame
time_idx = data[:, "Datetime"]
energy_buy = data[:, "Buy Price (USD/MWh)"]
energy_sell = data[:, "Sell Price (USD/MWh)"]

@assert length(energy_buy) == length(energy_sell) == length(time_idx)

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
    SCS.Optimizer,
    SCS.LinearSolver,
    60,
    1000,
    1e-6
)

# Run the optimization
@info "Running optimization"
charging_power, discharging_power, energy_stored, revenue = batteryopt.energy_arbitrage!(GenericBattery, prices, 0.0, config)
@info "Optimization complete"
@info "Revenue: $revenue"

# Plot the results, in three vertically stacked graphs with linked xaxes
# (1) Plot energy buy and sell prices
# (2) Plot the energy charging and discharging
# (3) Plot the energy stored in the battery
p1 = plot(data, x=:"Datetime", y=:"Buy Price (USD/MWh)", Geom.line, Guide.title("Energy Prices"), Guide.ylabel("Price (USD/MWh)"))
#p2 = plot(data, x=:Datetime, y=[charging_power, discharging_power], Geom.line, Guide.title("Charging and Discharging Power"), Guide.ylabel("Power (MW)"))
#p3 = plot(data, x=:Datetime, y=energy_stored, Geom.line, Guide.title("Energy Stored in Battery"), Guide.ylabel("Energy (MWh)"))
# Now stack the plots vertically






