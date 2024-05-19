module batteryopt
using JuMP, SCS, Dates
struct GenericBattery
    name::String
    capacity::Float64
    rte_efficiency::Float64
    max_charging_power::Float64
    max_discharging_power::Float64
    max_energy::Float64
    min_energy::Float64

    function GenericBattery(name::String, 
                    capacity::Float64, 
                    rte_efficiency::Float64, 
                    max_charging_power::Float64, 
                    max_discharging_power::Float64, 
                    max_energy::Float64, 
                    min_energy::Float64)

        if max_energy > 1.0 || max_energy < 0.0
            throw(ArgumentError("max_energy must be less than or equal to 1.0"))
        end
        if min_energy < 0.0 || min_energy > 1.0
            throw(ArgumentError("min_energy must be between 0.0 and 1.0"))
        end
        if rte_efficiency > 1.0 || rte_efficiency < 0.0
            throw(ArgumentError("rte_efficiency must be between 0.0 and 1.0"))
        end
        if min_energy > max_energy
            throw(ArgumentError("min_energy must be less than or equal to max_energy"))
        end
        return new(name, capacity, rte_efficiency, max_charging_power, max_discharging_power, max_energy, min_energy)
    end
end

mutable struct EnergyPrices
    energy_buy::Vector{Float64}
    energy_sell::Vector{Float64}
    time_idx::Vector{DateTime}

    function EnergyPrices(energy_buy::Vector{Float64}, energy_sell::Vector{Float64}, time_idx::Vector{DateTime})
        if length(energy_buy) != length(energy_sell)
            throw(ArgumentError("energy_buy and energy_sell must have the same length"))
        end
        if length(energy_buy) != length(time_idx) || length(energy_sell) != length(time_idx)
            throw(ArgumentError("energy_buy or energy sell and time_idx must have the same length"))
        end
        return new(energy_buy, energy_sell, time_idx)
    end
end

struct OptimizerConfig
    optimizer::Any
    linear_solver::Any
    max_time::Int
    max_iter::Int
    tol::Float64

    function OptimizerConfig(optimizer::Any, linear_solver::Any, max_time::Int, max_iter::Int, tol::Float64)
        return new(optimizer, linear_solver, max_time, max_iter, tol)
    end
end

function energy_arbitrage!(battery::GenericBattery, energy_prices::EnergyPrices, initial_energy::Float64, optimizer_config::OptimizerConfig)    
    t_idx = energy_prices.time_idx
    m = Model(SCS.Optimizer)

    @variable(m,  0 <= charging_power[t_idx] <= battery.max_charging_power)
    @variable(m,  0 <= discharging_power[t_idx] <= battery.max_discharging_power)
    @variable(m, battery.min_energy <= energy[t_idx] <= battery.max_energy)

    @constraint(m, energy[t_idx[1]] == initial_energy)
    @constraint(m, energy_dynamics_constr[t in 2: length(t_idx) - 1], energy[t_idx[t]] == energy[t_idx[t-1]] + battery.rte_efficiency*charging_power[t_idx[t]] - discharging_power[t_idx[t]]/battery.rte_efficiency)

    @objective(m, Max, sum(energy_prices.energy_sell[i]*discharging_power[t] - energy_prices.energy_buy[i]*charging_power[t] for (i, t) in enumerate(t_idx)))

    optimize!(m)

    return value.(charging_power), value.(discharging_power), value.(energy), objective_value(m)
end

export Battery, EnergyPrices,  OptimizerConfig, energy_arbitrage!
end # module batteryopt
