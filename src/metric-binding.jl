using DataFrames

const DEFAULT_METRIC_WEIGHT = 1.0
const DEFAULT_METRIC_ACTIVE = true


"""
    MetricBinding(id, scenario, metric, endpoint; active = true, weight = 1.0)
    MetricBinding(id, scenario, metric, endpoint, active, weight)

Bind one experimental metric to one simulated endpoint in one scenario.

A `MetricBinding` tells loss calculations which simulated column should be
compared against a concrete [`AbstractMetric`](@ref), and how that metric should
contribute to the total loss.

# Arguments
- `id::String`: Unique identifier for this binding.
- `scenario::String`: Scenario label used to select rows from the simulated data.
- `metric::AbstractMetric`: Experimental target, such as `MeanMetric` or `CategoryMetric`.
- `endpoint::String`: Name of the simulated data column used for comparison.
- `active::Bool`: Whether this binding is included in loss calculations.
- `weight::Real`: Non-negative, finite multiplier applied to this binding's loss.

# Defaults
- `active` defaults to `true` when omitted from the keyword constructor.
- `weight` defaults to `1.0` when omitted from the keyword constructor.

# Throws
Throws `ArgumentError` when `weight` is negative, infinite, or `NaN`.

# Examples
```julia
metric = MeanMetric(40, 2.1, 0.2)
binding = MetricBinding("m_conc_mean", "Tx", metric, "conc_t24"; weight = 2.0)
```
"""
struct MetricBinding
    id::String # not sure this is needed
    scenario::String
    metric::AbstractMetric
    endpoint::String
    active::Bool
    weight::Float64

    function MetricBinding(
        id::String,
        scenario::String,
        metric::AbstractMetric,
        endpoint::String,
        active::Bool,
        weight::Real,
    )
        weight = Float64(weight)
        _validate_weight(weight)

        new(id, scenario, metric, endpoint, active, weight)
    end
end

MetricBinding(
    id::String,
    scenario::String,
    metric::AbstractMetric,
    endpoint::String;
    active::Bool = DEFAULT_METRIC_ACTIVE,
    weight::Real = DEFAULT_METRIC_WEIGHT,
) = MetricBinding(id, scenario, metric, endpoint, active, weight)

"""
    add_mismatch_expression!(prob::GenericModel, sim::AbstractVector, b::MetricBinding, X::Vector{VariableRef}, X_len::Int) -> QuadExpr

Create a metric mismatch expression, push it to `prob[:LOSS]`, and return it.
"""
function add_mismatch_expression!(
    prob::GenericModel,
    sim::AbstractVector,
    b::MetricBinding,
    X::Vector{VariableRef},
    X_len::Int,
)
    _init_loss(prob)

    if b.active
        loss = b.weight * mismatch_expression(prob, sim, b.metric, X, X_len)
        push!(prob[:LOSS], loss)
        return loss
    else
        return 0.0
    end
end

# TODO: for future use, when we need check all data before we start calculation
function _validate_simulated(simulated::DataFrame, metric_bindings::Vector{MetricBinding})

end

"""
    get_loss(simulated::DataFrame, metric_bindings::Vector{MetricBinding}, cohort::Vector{String}) -> Float64

Calculate total loss after restricting `simulated` to rows whose `id` is in `cohort`.

This method first filters the simulation table, then calls
`get_loss(simulated_subset, metric_bindings)`.
"""
function get_loss(simulated::DataFrame, metric_bindings::Vector{MetricBinding}, cohort::Vector{String}) 
    # select subset of DataFrame
    selected = in.(simulated.id, Ref(cohort))
    simulated_subset = simulated[selected, :]

    get_loss(simulated_subset, metric_bindings)
end

"""
    get_loss(simulated::DataFrame, metric_bindings::Vector{MetricBinding}) -> Float64

Calculate the total weighted loss for all active metric bindings.

For each active [`MetricBinding`](@ref), this function selects simulated values
from rows where `simulated.scenario .== binding.scenario` and from the column
named by `binding.endpoint`. It then adds the binding's weighted
[`mismatch`](@ref) to the total. Inactive bindings are ignored.

# Arguments
- `simulated::DataFrame`: Simulation table. It must contain a `scenario` column
  and every endpoint column referenced by active bindings.
- `metric_bindings::Vector{MetricBinding}`: Bindings that define which metrics
  to evaluate and how they are weighted.

# Returns
The sum of weighted mismatches as a `Float64`.

# Examples
```julia
df = DataFrame(scenario = ["Tx", "Tx", "Tx"], conc_t24 = [2.0, 2.1, 2.2])
metric = MeanMetric(40, 2.1, 0.2)
binding = MetricBinding("m_conc_mean", "Tx", metric, "conc_t24")

loss = get_loss(df, [binding])
```
"""
function get_loss(simulated::DataFrame, metric_bindings::Vector{MetricBinding})
    _validate_simulated(simulated, metric_bindings)

    loss = 0.0
    for b in metric_bindings
        !b.active && continue # skip inactive metric bindings
        # select only endpoint which refers to scenario
        selected = simulated[simulated.scenario .== b.scenario, b.endpoint]
        loss += get_loss(selected, b)
    end

    return loss
end

function get_loss(simulated::AbstractVector, binding::MetricBinding)
    binding.weight * mismatch(simulated, binding.metric)
end

function _validate_weight(weight::Float64)
    isfinite(weight) || throw(ArgumentError("Weight must be finite"))
    !isnan(weight) || throw(ArgumentError("Weight must not be NaN"))
    weight >= 0 || throw(ArgumentError("Weight must be non-negative"))
end

function _init_loss(prob::GenericModel)
    if !haskey(prob, :LOSS)
        prob[:LOSS] = Any[]
    end
end
