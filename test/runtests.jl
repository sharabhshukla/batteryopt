using Test, Dates, SCS
include("../src/batteryopt.jl")


#This is the main test file for the batteryopt module in julia
# Test 1: Test GenericBattery initialization
function test_generic_battery_initialization()
    battery = batteryopt.GenericBattery("Battery 1", 100.0, 0.9, 50.0, 50.0, 0.8, 0.2)
    @test battery.name == "Battery 1"
    @test battery.capacity == 100.0
    @test battery.rte_efficiency == 0.9
    @test battery.max_charging_power == 50.0
    @test battery.max_discharging_power == 50.0
    @test battery.max_energy == 0.8
    @test battery.min_energy == 0.2
end

# Test 2: Test EnergyPrices initialization
function test_energy_prices_initialization()
    energy_buy = [0.1, 0.2, 0.3, 0.4]
    energy_sell = [0.4, 0.3, 0.2, 0.1]
    time_idx = [Dates.DateTime(2022, 1, 1), Dates.DateTime(2022, 1, 2), Dates.DateTime(2022, 1, 3), Dates.DateTime(2022, 1, 4)]
    energy_prices = batteryopt.EnergyPrices(energy_buy, energy_sell, time_idx)
    @test energy_prices.energy_buy == energy_buy
    @test energy_prices.energy_sell == energy_sell
    @test energy_prices.time_idx == time_idx
end

# Test 3: Test OptimizerConfig initialization
function test_optimizer_config_initialization()
    optimizer = SCS.Optimizer
    linear_solver = SCS.LinearSolver
    max_time = 100
    max_iter = 1000
    tol = 1e-6
    optimizer_config = batteryopt.OptimizerConfig(optimizer, linear_solver, max_time, max_iter, tol)
    @test optimizer_config.optimizer == optimizer
    @test optimizer_config.max_time == max_time
    @test optimizer_config.max_iter == max_iter
    @test optimizer_config.tol == tol
    @test optimizer_config.linear_solver == linear_solver
end

# Test 4: Test energy_arbitrage! function
function test_energy_arbitrage()
    battery = batteryopt.GenericBattery("Battery 1", 100.0, 0.9, 50.0, 50.0, 0.8, 0.2)
    energy_buy = [0.1, 0.2, 0.3, 0.4]
    energy_sell = [0.4, 0.3, 0.2, 0.1]
    time_idx = [Dates.DateTime(2022, 1, 1), Dates.DateTime(2022, 1, 2), Dates.DateTime(2022, 1, 3), Dates.DateTime(2022, 1, 4)]
    energy_prices = batteryopt.EnergyPrices(energy_buy, energy_sell, time_idx)
    initial_energy = 0.5
    charging_power, discharging_power, energy_stored =  batteryopt.energy_arbitrage!(battery, energy_prices, initial_energy)
    # Add assertions here to test the results
    @assert maximum(charging_power) <= battery.max_charging_power + 1e-3
    @assert maximum(discharging_power) <= battery.max_discharging_power + 1e-3
    @assert maximum(energy_stored) <= battery.max_energy + 1e-3
    @assert minimum(energy_stored) >= battery.min_energy - 1e-3
end

# Run the tests
@testset "BatteryOpt Tests" begin
    @testset "GenericBattery" begin
        test_generic_battery_initialization()
    end

    @testset "EnergyPrices" begin
        test_energy_prices_initialization()
    end

    @testset "OptimizerConfig" begin
         test_optimizer_config_initialization()
    end

    @testset "energy_arbitrage!" begin
        test_energy_arbitrage()
    end
end