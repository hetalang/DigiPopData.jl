const PARSERS = Dict{String, Function}()

"""
    parse_metric_bindings(df::DataFrame) -> Vector{MetricBinding}

Parse a `DataFrame` with metric‑binding definitions and return a vector of [`MetricBinding`](@ref) objects.

The DataFrame should contain the following columns:
- `id`: Unique identifier for the metric binding.
- `scenario`: The scenario to which the metric binding applies.
- `endpoint`: The observable (endpoint) associated with the metric binding.
- `active`: (optional) A boolean indicating whether the metric binding is active (default is `true`).
- `metric`: (optional) Multiplier applied to this row's loss contribution (default is `1.0`).
- `metric.type`: The type of metric (e.g., "mean", "category", etc.).
- `metric.<parameter>`: Additional parameters for the metric, depending on its type.
The function uses the `PARSERS` dictionary to find the appropriate parser for the metric type.
The function iterates over each row of the DataFrame, extracting the relevant information and creating a `MetricBinding` object.
"""
function parse_metric_bindings(df::DataFrame)
    bindings = MetricBinding[]
    for row in eachrow(df)
        mb = try
            (; id, scenario, endpoint, var"metric.type") = row
            active = get(row, :active, true)
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
