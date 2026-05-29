const PARSERS = Dict{String, Function}()

"""
    parse_metric_bindings(df::DataFrame) -> Vector{MetricBinding}

Parse a metric definition table into [`MetricBinding`](@ref) objects.

Each row in `df` describes one metric binding: which experimental metric to
construct, which simulated scenario and endpoint it applies to, whether it is
active, and how much it contributes to the total loss.

# Required columns
- `id`: Unique identifier for the binding.
- `scenario`: Scenario label used to match rows in simulated data.
- `endpoint`: Name of the simulated data column used for comparison.
- `metric.type`: Metric parser key, such as `"mean"`, `"mean_sd"`,
  `"category"`, `"quantile"`, or `"survival"`.
- `metric.<property>`: Metric-specific columns required by the selected
  `metric.type`, for example `metric.mean`, `metric.sd`, or `metric.size`.

# Optional columns
- `active`: Whether the binding is included in loss calculations. Missing or
  empty values default to `true`. Accepted values are `Bool`, `0`/`1`, and the
  strings `"false"`, `"true"`, `"0"`, and `"1"`.
- `weight`: Non-negative, finite loss multiplier. Missing or empty values
  default to `1.0`.

# Throws
Throws `ErrorException` with the row number when a row cannot be parsed. The
wrapped error may come from an unknown `metric.type`, an invalid metric
parameter, an invalid `active` value, or an invalid `weight`.

# Examples
```julia
df = DataFrame(
    id = ["m_conc_mean"],
    active = [1],
    scenario = ["Tx"],
    endpoint = ["conc_t24"],
    var"metric.type" = ["mean"],
    var"metric.size" = [40],
    var"metric.mean" = [2.1],
    var"metric.sd" = [0.2],
    weight = [2.0],
)

bindings = parse_metric_bindings(df)
```
"""
function parse_metric_bindings(df::DataFrame)
    bindings = MetricBinding[]
    for row in eachrow(df)
        mb = try
            (; id, scenario, endpoint, var"metric.type") = row
            active = _parse_metric_active(row)
            haskey(PARSERS, var"metric.type") || throw(ArgumentError("Unknown metric type \"$(var"metric.type")\""))
            dp = PARSERS[var"metric.type"](row)
            weight = _parse_metric_weight(row)

            MetricBinding(id, scenario, dp, endpoint, active, weight)
        catch e
            msg = "Failed to process row $(rownumber(row)): $(e)"
            throw(ErrorException(msg))
        end

        push!(bindings, mb)
    end

    return bindings
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
