import JuMP: VariableRef, AffExpr, GenericModel, @variable, @constraint

const RATE_TOL = 1e-6 # value to comare rates to 1 or 0

"""
    AbstractMetric

Abstract super‑type for all *metric* descriptors used by DigiPopData.

## Purpose
Group together heterogeneous metrics (Mean, MeanSD, Category, …) so they
can share the same dispatch points (`mismatch`, `mismatch_expression`, `get_loss`, ...).

## Required interface
- `mismatch`: Function to calculate the loss for a given metric and simulated data as a value.
- `mismatch_expression`: Function to calculate the loss for a given metric and simulated data as an expression.
- `validate`: Function to validate the simulated data against the metric.

The parsing rules for the metric type are defined in the `PARSERS` dictionary to convert from `DataFrame`
row to specific `Metric` struture. It is used in the `parse_metric_bindings` method.

    PARSERS["<metric_type>"] = (row) -> begin
        # parsing logic
    end
"""
abstract type AbstractMetric end

"""
    mismatch(sim::AbstractVector{<:Real}, metric::AbstractMetric) -> Float64

## Arguments
- `sim::AbstractVector{<:Real}`: A vector of simulated data.
- `metric::AbstractMetric`: An instance of a metric descriptor (e.g., `MeanMetric`, `CategoryMetric`, etc.).

Return a loss that quantifies the mismatch between simulated data `sim`
and the target metric `metric`.  
The concrete formula depends on the subtype of `AbstractMetric`.
"""
function mismatch(sim::AbstractVector{<:Real}, metric::AbstractMetric)
    throw(MethodError(mismatch, (sim, metric))) # fallback
end

"""
    mismatch_expression(sim::AbstractVector{<:Real}, metric::AbstractMetric, X::Vector{VariableRef}, X_len::Int) -> QuadExpr

## Arguments
- `sim::AbstractVector{<:Real}`: A vector of simulated data.
- `metric::AbstractMetric`: An instance of a metric descriptor (e.g., `MeanMetric`, `CategoryMetric`, etc.).
- `X::Vector{VariableRef}`: A vector of JuMP variable references.
- `X_len::Int`: The length of the vector of JuMP variable references.

Return an expression that quantifies the mismatch between simulated data `sim`
and the target metric `metric`.
The concrete formula depends on the subtype of `AbstractMetric`.
"""
function mismatch_expression(sim::AbstractVector{<:Real}, dp::AbstractMetric, X::Vector{VariableRef}, X_len::Int)
    throw(MethodError(mismatch_expression, (sim, dp, X, X_len))) # fallback
end

"""
    validate(sim::AbstractVector{<:Real}, metric::AbstractMetric)

## Arguments
- `sim::AbstractVector{<:Real}`: A vector of simulated data.
- `metric::AbstractMetric`: An instance of a metric descriptor (e.g., `MeanMetric`, `CategoryMetric`, etc.).

Validate the simulated data `sim` against the target metric `metric`. It throws an error
if the validation fails.
The concrete validation rules depend on the subtype of `AbstractMetric`.
"""
function validate(sim::AbstractVector{<:Real}, dp::AbstractMetric)
    throw(MethodError(validate, (sim, dp))) # fallback
end
