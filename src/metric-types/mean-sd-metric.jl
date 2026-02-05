"""
    MeanSDMetric <: AbstractMetric

A metric that compares the mean and standard deviation (SD) of a simulated dataset to a target mean and SD.

## Fields
- `size::Int`: The size of the dataset.
- `mean::Float64`: The target mean value.
- `sd::Float64`: The target standard deviation value.
"""
struct MeanSDMetric <: AbstractMetric
    size::Int
    mean::Float64
    sd::Float64

    MeanSDMetric(size::Int, mean::Float64, sd::Float64) = begin
        _validate_mean_sd(mean, sd)
        new(size, mean, sd)
    end
end

_validate_mean_sd(mean::Float64, sd::Float64) = begin
    # Check that standard deviation is positive
    sd > 0 || throw(ArgumentError("Standard deviation must be positive"))
    # Check that standard deviation is finite
    isfinite(sd) || throw(ArgumentError("Standard deviation must be finite"))
    # Check that standard deviation is not NaN
    !isnan(sd) || throw(ArgumentError("Standard deviation must not be NaN"))
    # Check that mean is finite
    isfinite(mean) || throw(ArgumentError("Mean must be finite"))
    # Check that mean is not NaN
    !isnan(mean) || throw(ArgumentError("Mean must not be NaN"))
end

function mismatch(sim::AbstractVector{<:Real}, dp::MeanSDMetric)
    validate(sim, dp)

    mu_virt = sum(sim) / length(sim)
    #sigma_sq_virt = sum(sim .^2) / length(sim) - mu_virt^2
    # to satisfy similar results for mismatch and mismatch_expression
    sigma_sq_virt = sum((sim .- dp.mean) .^2) / length(sim) # AffExpr
    loss1 = length(sim) * (mu_virt - dp.mean)^2 / dp.sd^2 
    loss2 = length(sim) / 2 * (sigma_sq_virt - dp.sd^2)^2 / dp.sd^4

    loss1 + loss2
end

function add_mismatch_expression!(
    prob::GenericModel,
    sim::AbstractVector{<:Real},
    dp::MeanSDMetric,
    X::Vector{VariableRef},
    X_len::Int
)
    validate(sim, dp)
    # Check that the length of sim and X are equal
    length(sim) == length(X) || throw(DimensionMismatch("Length of simulation data and X must be equal"))
    # Check that X_len is less than sim
    X_len <= length(sim) || throw(DimensionMismatch("X_len must be less than or equal to the length of simulation data"))
    
    _init_loss(prob)

    z_mu = @variable(prob)
    z_sq = @variable(prob)
    @constraint(prob, z_mu == sum(sim .* X) / X_len - dp.mean)
    @constraint(prob, z_sq == sum((sim .- dp.mean) .^2 .* X) / X_len - dp.sd^2)

    z_mu_loss = @variable(prob)
    z_sq_loss = @variable(prob)
    @constraint(prob, z_mu_loss == X_len * (z_mu)^2 / dp.sd^2)
    @constraint(prob, z_sq_loss == X_len / 2 * (z_sq)^2 / dp.sd^4)

    loss = z_mu_loss + z_sq_loss

    push!(prob[:LOSS], loss)
    loss
end

function validate(sim::AbstractVector{<:Real}, ::MeanSDMetric)
    # length must be >= 3
    length(sim) >= 3 || 
        throw(ArgumentError("Simulation data must have at least 3 elements"))

    # no NaN values
    any(isnan, sim) && 
        throw(ArgumentError("Simulation data contains NaN values"))

    # no Inf values
    any(isinf, sim) && 
        throw(ArgumentError("Simulation data contains Inf values"))

    # no missing values
    any(ismissing, sim) && 
        throw(ArgumentError("Simulation data contains missing values"))
end

PARSERS["mean_sd"] = (row) -> begin
    size = row[Symbol("metric.size")]
    mean = row[Symbol("metric.mean")] |> safe_float
    sd = row[Symbol("metric.sd")] |> safe_float

    MeanSDMetric(size, mean, sd)
end
