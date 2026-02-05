#=
    XXX: Currently we accept NaN values in simulation data.
    It means that value is not exist and must be excluded from statistics, so metrics was created on this data.
    XXX: It is possible the case when we have simulated data inside the group with 0 rate.
    It is not the error but we should decide what to do with it.
    Currently we ignore it.
    Another option could be to append this simulation to the active groups.
=#

"""
    QuantileMetric <: AbstractMetric

QuantileMetric is a metric descriptor for quantile data. It is based on the quantiles of the data and their corresponding values.

## Fields
- `size::Int`: The size of the dataset.
- `levels::Vector{Float64}`: The quantile levels (e.g. 0.25, 0.5, 0.75).
- `values::Vector{Float64}`: The corresponding values for the quantile levels.
- `skip_nan::Bool`: If `true``, NaN values are allowed in simulated data and will be ignored. If `false`, NaN values are not allowed.
- `cov_inv::Matrix{Float64}`: The inverse of the covariance matrix of the groups.
- `group_active::Vector{Bool}`: A boolean vector indicating which groups are active (non-zero rates).
- `rates::Vector{Float64}`: The probabilities of each group.

## Constructor
- `QuantileMetric(size::Int, levels::Vector{Float64}, values::Vector{Float64}; skip_nan::Bool = false)`: Creates a new instance of QuantileMetric. 
  It validates the input data and calculates the inverse covariance matrix.

"""
struct QuantileMetric <: AbstractMetric
    size::Int
    levels::Vector{Float64}
    values::Vector{Float64}
    skip_nan::Bool # if true NaN values are allowed in simulated data and will be ignored

    cov_inv::Matrix{Float64} # inverse of the covariance matrix of the groups
    group_active::Vector{Bool}
    rates::Vector{Float64} # rates of the groups

    QuantileMetric(size::Int, levels::Vector{Float64}, values::Vector{Float64}; skip_nan::Bool = false) = begin
        _validate_quantile(levels, values)

        extended_levels = [0; levels; 1.0]
        rates = [extended_levels[i+1] - extended_levels[i] for i in 1:length(levels) + 1]
        group_active = .!isapprox.(rates, 0., atol=RATE_TOL) # not 0

        len = sum(group_active) - 1 # degree of freedom
        rates_reduced = rates[group_active][1:len] # all non zero without last one
        diag = [i == j ? rates_reduced[i] : 0.0 for i in 1:len, j in 1:len]
        cov = diag - rates_reduced * rates_reduced'
        cov_inv = inv(cov) # TODO: can be done without the inverse matrix

        new(size, levels, values, skip_nan, cov_inv, group_active, rates)
    end
end

function _validate_quantile(levels::Vector{Float64}, values::Vector{Float64})
    # Check that levels and values are not empty
    !isempty(levels) || 
        throw(ArgumentError("`levels` cannot be empty"))
    
    # Check equal lengths
    length(levels) == length(values) || 
        throw(DimensionMismatch("`levels` and `values` must have the same length"))

    # Check that levels are in (0, 1)
    all(0 .< levels .< 1) || 
        throw(ArgumentError("All quantile levels must be in (0, 1), got $(levels)"))

    # Check that levels are sorted ascending
    issorted(levels) || 
        throw(ArgumentError("`levels` must be sorted in ascending order"))

    # Check that values are not NaN
    any(isnan, values) && 
        throw(ArgumentError("`values` cannot contain NaN values"))
        
    # check that values are sorted in ascending order
    issorted(values) || 
        throw(ArgumentError("`values` must be sorted in ascending order"))
end

function mismatch(sim::AbstractVector{<:Real}, dp::QuantileMetric)
    validate(sim, dp)

    len = sum(dp.group_active) - 1 # degree of freedom
    sim1 = filter(x -> !isnan(x), sim) # remove NaN values

    # calculate number of less than values
    count_virt_cum = [sum(sim1 .< dp.values[i]) for i in 1:length(dp.levels)]
    count_virt_cum_ext = [0; count_virt_cum; length(sim1)]
    count_virt = [count_virt_cum_ext[i+1] - count_virt_cum_ext[i] for i in 1:length(count_virt_cum_ext) - 1]
    
    ### TODO: check if the non-active groups are empty

    # calculate the loss
    diff = count_virt .- dp.rates * length(sim) # full count including NaN values
    diff_active = diff[dp.group_active][1:len] # all non zero without last one
    loss = diff_active' * dp.cov_inv * diff_active # quadratic form

    return loss
end

function add_mismatch_expression!(
    prob::GenericModel,
    sim::AbstractVector{<:Real},
    dp::QuantileMetric,
    X::Vector{VariableRef},
    X_len::Int,
)
    validate(sim, dp)
    # Check that the length of sim and X are equal
    length(sim) == length(X) || throw(DimensionMismatch("Length of simulation data and X must be equal"))
    # Check that X_len is less than sim
    X_len <= length(sim) || throw(DimensionMismatch("X_len must be less than or equal to the length of simulation data"))
    
    _init_loss(prob)

    len = sum(dp.group_active) - 1 # degree of freedom
    not_nan = .!isnan.(sim) # mark NaN values

    # calculate the loss
    values_ext = [-Inf; dp.values; Inf]
    z_quant = @variable(prob, [i=1:length(dp.rates)] )
    for i in 1:length(dp.rates)
        mask = Int.((values_ext[i] .<= sim .< values_ext[i+1]) .&& not_nan) # to sort to specific group
        @constraint(prob, z_quant[i] == sum(mask .* X) - round(Int, dp.rates[i] * X_len))
    end

    ### TODO: check if the non-active groups are empty
    
    diff_active = z_quant[dp.group_active][1:len] # all non zero without last one   
    loss = diff_active' * dp.cov_inv * diff_active / X_len

    push!(prob[:LOSS], loss)
    loss
end

function validate(sim::AbstractVector{<:Real}, dp::QuantileMetric)
    # Check that the simulation data is not empty
    isempty(sim) && 
        throw(ArgumentError("Simulation data cannot be empty"))

    # Check that the simulation data contains no missing values
    any(ismissing, sim) && 
        throw(ArgumentError("Simulation data contains missing values"))

    dp.skip_nan || any(isnan, sim) && 
        throw(ArgumentError("Simulation data contains NaN values which are not allowed when `skip_nan` is false"))    
end

PARSERS["quantile"] = (row) -> begin
    size = row[Symbol("metric.size")]
    levels_string = row[Symbol("metric.levels")]
    levels = parse.(Float64, split(levels_string, ";"))
    values_string = row[Symbol("metric.values")]
    values = parse.(Float64, split(values_string, ";"))
    skip_nan_string = row[Symbol("metric.skip_nan")]
    skip_nan = typeof(skip_nan_string) == String ?
        parse(Bool, skip_nan_string) : 
        skip_nan_string

    QuantileMetric(size, levels, values; skip_nan=Bool(skip_nan))
end
