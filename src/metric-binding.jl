using DataFrames

const DEFAULT_METRIC_WEIGHT = 1.0
const DEFAULT_METRIC_ACTIVE = true


"""
`MetricBinding` is container that binds a **scenario**, an **endpoint** and a concrete
`AbstractMetric` description into a single unit that can be logged,
displayed or passed to optimisation / validation routines.

# Fields
| Name        | Type                     | Description                                               |
|-------------|--------------------------|-----------------------------------------------------------|
| `id`        | `String`                 | Unique identifier of the binding |
| `scenario`  | `String`                 | Scenario (e.g. simulation arm) in which the metric is evaluated |
| `metric`    | `AbstractMetric`         | Metric implementation (`MeanMetric`, `CategoryMetric`, …) |
| `endpoint`  | `String`                 | Observable / model variable the metric is computed for    |
| `active`    | `Bool`                   | Whether the binding is enabled (`true` by default)        |
| `weight`    | `Float64`                | Multiplier applied to this binding's loss                 |

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
    endpoint::String,
    active::Bool;
    weight::Real = DEFAULT_METRIC_WEIGHT,
) = MetricBinding(id, scenario, metric, endpoint, active, weight)

mismatch(sim::AbstractVector, b::MetricBinding) = b.weight * mismatch(sim, b.metric)

function add_mismatch_expression!(
    prob::GenericModel,
    sim::AbstractVector,
    b::MetricBinding,
    X::Vector{VariableRef},
    X_len::Int,
)
    _init_loss(prob)

    loss = b.weight * mismatch_expression(prob, sim, b.metric, X, X_len)
    push!(prob[:LOSS], loss)
    loss
end

# TODO: for future use, when we need check all data before we start calculation
function _validate_simulated(simulated::DataFrame, metric_bindings::Vector{MetricBinding})

end

### Main function of the module

# calculated for selected patients in the cohort
function get_loss(simulated::DataFrame, metric_bindings::Vector{MetricBinding}, cohort::Vector{String}) 
    # select subset of DataFrame
    selected = in.(df.id, Ref(cohort))
    simulated_subset = simulated[selected, :]

    get_loss(simulated_subset, metric_bindings)
end

# calculate for all patients in the cohort
"""
    get_loss(simulated::DataFrame, metric_bindings::Vector{MetricBinding}) -> Float64

Calculate the loss for a given set of metric bindings and a simulated DataFrame.
The function iterates over the metric bindings, selecting the relevant data from the simulated DataFrame
 based on the scenario and endpoint specified in each binding. It then computes the loss using the `mismatch`
 function defined for the binding.

## Arguments
- `simulated::DataFrame`: A DataFrame containing the simulated data.
- `metric_bindings::Vector{MetricBinding}`: A vector of `MetricBinding` objects, each containing a scenario,
endpoint, and metric.

"""
function get_loss(simulated::DataFrame, metric_bindings::Vector{MetricBinding})
    _validate_simulated(simulated, metric_bindings)

    loss = 0.0
    for b in metric_bindings
        !b.active && continue # skip inactive metric bindings
        # select only endpoint which refers to scenario
        selected = simulated[simulated.scenario .== b.scenario, b.endpoint]
        loss += mismatch(selected, b)
    end

    return loss
end

function _validate_weight(weight::Float64)
    weight >= 0 || throw(ArgumentError("Weight must be non-negative"))
    isfinite(weight) || throw(ArgumentError("Weight must be finite"))
    !isnan(weight) || throw(ArgumentError("Weight must not be NaN"))
end

function _safe_weight(x)
    if x === missing || x == ""
        return DEFAULT_METRIC_WEIGHT
    end

    x isa AbstractString ? parse(Float64, x) : Float64(x)
end

_parse_metric_weight(row) = _safe_weight(get(row, Symbol("weight"), DEFAULT_METRIC_WEIGHT))

function _safe_active(x)
    if x === missing || x == ""
        return DEFAULT_METRIC_ACTIVE
    end

    if x isa Bool
        return x
    elseif x isa Integer
        x in (0, 1) || throw(ArgumentError("Active must be boolean or 0/1"))
        return Bool(x)
    elseif x isa AbstractString
        value = lowercase(strip(x))
        value == "" && return DEFAULT_METRIC_ACTIVE
        value in ("true", "1") && return true
        value in ("false", "0") && return false
    end

    throw(ArgumentError("Active must be boolean or 0/1"))
end

_parse_metric_active(row) = _safe_active(get(row, Symbol("active"), DEFAULT_METRIC_ACTIVE))
