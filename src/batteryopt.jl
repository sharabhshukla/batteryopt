module batteryopt
using JuMP, SCS, Dates, PlotlyJS
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

struct ModelConfig
    optimizer::Any
    linear_solver::Any
    max_time::Int
    max_iter::Int
    tol::Float64
    accurate_soc_profile::Bool

    function ModelConfig(optimizer::Any, linear_solver::Any, max_time::Int, max_iter::Int, tol::Float64, accurate_soc_profile::Bool = false)
        return new(optimizer, linear_solver, max_time, max_iter, tol, accurate_soc_profile)
    end
end

mutable struct Results
    energy_prices::EnergyPrices
    charging_power::Vector{Float64}
    discharging_power::Vector{Float64}
    energy_stored::Vector{Float64}
    revenue::Float64
end


function energy_arbitrage!(battery::GenericBattery, energy_prices::EnergyPrices, initial_energy::Float64, model_config::ModelConfig)    
    t_idx = energy_prices.time_idx
    m = Model(model_config.optimizer)

    @variable(m,  0 <= charging_power[t_idx] <= battery.max_charging_power)
    @variable(m,  0 <= discharging_power[t_idx] <= battery.max_discharging_power)
    @variable(m, battery.min_energy * battery.capacity <= energy[t_idx] <= battery.max_energy * battery.capacity)
    if model_config.accurate_soc_profile
        @variable(m, charging_status[t_idx], Bin)
        @variable(m, discharging_status[t_idx], Bin)
    end
    @constraint(m, energy_dynamics_constr[t in 2: length(t_idx) - 1], energy[t_idx[t]] == energy[t_idx[t-1]] + sqrt(battery.rte_efficiency)*charging_power[t_idx[t]] - discharging_power[t_idx[t]]/sqrt(battery.rte_efficiency))
    @constraint(m, energy[t_idx[1]] == initial_energy)
    if model_config.accurate_soc_profile
        @constraint(m, charging_status_constr[t in t_idx], charging_power[t] <= charging_status[t] * battery.max_charging_power)
        @constraint(m, discharging_status_constr[t in t_idx], discharging_power[t] <= discharging_status[t] * battery.max_discharging_power)
        @constraint(m, charging_discharging_complemntarity_constr[t in t_idx], charging_status[t] + discharging_status[t] <= 1)
    end
    @objective(m, Max, sum(energy_prices.energy_sell[i]*discharging_power[t] - energy_prices.energy_buy[i]*charging_power[t] for (i, t) in enumerate(t_idx)))

    optimize!(m)

    return value.(charging_power), value.(discharging_power), value.(energy), objective_value(m)
end

function plot_results!(results::Results)
    time_idx = results.energy_prices.time_idx
    energy_buy = results.energy_prices.energy_buy
    energy_sell = results.energy_prices.energy_sell
    charging_power = Vector(results.charging_power)
    discharging_power = Vector(results.discharging_power)
    energy_stored = Vector(results.energy_stored)
    net_charging_power = charging_power .- discharging_power
    # Plot the data using PlotlyJS
    @info "Creating plots"

    trace1 = scatter(x=time_idx, y=energy_buy, mode="lines", name="Buy Price (USD/MWh)")
    trace2 = scatter(x=time_idx, y=energy_sell, mode="lines", name="Sell Price (USD/MWh)")
    layout1 = Layout(title="Energy Buy and Sell Prices", xaxis_title="Time", yaxis_title="Price (USD/MWh)")

    trace3 = scatter(x=time_idx, y=charging_power, mode="lines", name="Charging Power")
    trace4 = scatter(x=time_idx, y=discharging_power, mode="lines", name="Discharging Power")
    trace5 = scatter(x=time_idx, y=net_charging_power, mode="lines", name="Net Charging Power")
    layout2 = Layout(title="Charging and Discharging Power", xaxis_title="Time", yaxis_title="Power (MW)")

    trace6 = scatter(x=time_idx, y=energy_stored, mode="lines", name="Energy Stored")
    layout3 = Layout(title="Energy Stored in Battery", xaxis_title="Time", yaxis_title="Energy (MWh)")

    fig1 = plot([trace1, trace2], layout1)
    fig2 = plot([trace3, trace4, trace5], layout2)
    fig3 = plot([trace6], layout3)

    # Display the plots
    display(fig1)
    display(fig2)
    display(fig3)
end

export Battery, EnergyPrices,  ModelConfig, energy_arbitrage!, plot_results!
end # module batteryopt
