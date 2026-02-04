""""
    SurvivalMetric <: AbstractMetric

## Fields
- `size::Int`: The size of the dataset.
- `levels::Vector{Float64}`: The survival levels (e.g. 0.9, 0.8, 0.7).
- `values::Vector{Float64}`: The corresponding values for the survival levels.
- `cov_inv::Matrix{Float64}`: The inverse of the covariance matrix of the groups.
- `group_active::Vector{Bool}`: A boolean vector indicating which groups are active (non-zero rates).
- `rates::Vector{Float64}`: The probabilities of each group.

## Constructor
- `SurvivalMetric(size::Int, levels::Vector{Float64}, values::Vector{Float64})`: Creates a new instance of SurvivalMetric. 
  It validates the input data and calculates the inverse covariance matrix.
"""
struct SurvivalMetric <: AbstractMetric
    size::Int
    levels::Vector{Float64}
    values::Vector{Float64}

    cov_inv::Matrix{Float64} # inverse of the covariance matrix of the groups
    group_active::Vector{Bool}
    rates::Vector{Float64} # rates of the groups

    SurvivalMetric(size::Int, levels::Vector{Float64}, values::Vector{Float64}) = begin
        _validate_survival(levels, values)

        # current level minus prev level
        extended_levels = [1; levels; 0.0]
        rates = [extended_levels[i] - extended_levels[i+1] for i in 1:(length(extended_levels) - 1)]
        
        group_active = .!isapprox.(rates, 0., atol=RATE_TOL) # not 0
        len = sum(group_active) - 1 # degree of freedom 

        rates_reduced = rates[group_active][1:len] # all non zero without last one
        diag = [i == j ? rates_reduced[i] : 0.0 for i in 1:len, j in 1:len]
        cov = diag - rates_reduced * rates_reduced'
        cov_inv = inv(cov) 
        # This matrix has equal values of non-diagonal elements but it is ok
        # it is possible to calculate them without the inverse matrix
        # 1/rates[group_active][end]

        new(size, levels, values, cov_inv, group_active, rates)
    end
end

_validate_survival(levels::Vector{Float64}, values::Vector{Float64}) = begin
    # Check that the levels are not empty
    isempty(levels) && 
        throw(ArgumentError("`levels` cannot be empty"))
    
    # Check equal lengths
    length(levels) == length(values) || 
        throw(DimensionMismatch("`levels` and `values` must have the same length"))

    # Check that levels are in [0, 1]
    all(0 .<= levels .<= 1) || 
        throw(ArgumentError("All survival levels must be in [0, 1], got $(levels)"))
    
    # Check that levels are sorted descending
    issorted(levels, rev=true) || 
        throw(ArgumentError("`levels` must be sorted in descending order"))
        
    # Check that values are not NaN
    any(isnan, values) && 
        throw(ArgumentError("`values` cannot contain NaN values"))

    # Check that values are sorted in ascending order
    issorted(values) || 
        throw(ArgumentError("`values` must be sorted in ascending order"))
end

function mismatch(sim::Vector{Float64}, dp::SurvivalMetric)
    validate(sim, dp)

    len = sum(dp.group_active) - 1
    # calculate number of less than values
    count_virt_cum = [sum(sim .< dp.values[i]) for i in 1:length(dp.levels)] # group count - 1
    count_virt_cum_ext = [0; count_virt_cum; length(sim)] # group count + 1
    count_virt = [count_virt_cum_ext[i+1] - count_virt_cum_ext[i] for i in 1:length(count_virt_cum_ext) - 1] # group count

    # calculate the loss
    diff = count_virt .- dp.rates * length(sim)
    diff_active = diff[dp.group_active][1:len] # all non zero without last one
    loss = diff_active' * dp.cov_inv * diff_active / length(sim)
   
    return loss
end

function mismatch_expression(
    sim::Vector{Float64},
    dp::SurvivalMetric,
    X::Vector{VariableRef},
    X_len::Int
)
    validate(sim, dp)
    # Check that the length of sim and X are equal
    length(sim) == length(X) || throw(DimensionMismatch("Length of simulation data and X must be equal"))
    # Check that X_len is less than sim
    X_len <= length(sim) || throw(DimensionMismatch("X_len must be less than or equal to the length of simulation data"))

    len = sum(dp.group_active) - 1 # degree of freedom

    # calculate the loss
    values_ext = [-Inf; dp.values; Inf] # add 0 and 1 to the levels
    diff = AffExpr[]
    for i in 1:length(dp.rates)
        mask = Int.(values_ext[i] .< sim .<= values_ext[i+1])
        expr = sum(mask .* X) - round(Int, dp.rates[i] * X_len)
        push!(diff, expr)
    end

    ### TODO: check if the non-active groups are empty
    
    diff_active = diff[dp.group_active][1:len] # all non zero without last one
    loss = diff_active' * dp.cov_inv * diff_active / X_len # quadratic form
    
    return loss
end

function add_mismatch_expression!(
    prob::GenericModel,
    sim::Vector{Float64},
    dp::SurvivalMetric,
    X::Vector{VariableRef},
    X_len::Int
)
    validate(sim, dp)
    # Check that the length of sim and X are equal
    length(sim) == length(X) || throw(DimensionMismatch("Length of simulation data and X must be equal"))
    # Check that X_len is less than sim
    X_len <= length(sim) || throw(DimensionMismatch("X_len must be less than or equal to the length of simulation data"))

    len = sum(dp.group_active) - 1 # degree of freedom
    rates_len = length(dp.rates)

    # calculate the loss
    values_ext = [-Inf; dp.values; Inf] # add 0 and 1 to the levels
    z_srv = @variable(prob, [i=1:rates_len] )
    for i in 1:rates_len
        mask = Int.(values_ext[i] .< sim .<= values_ext[i+1])
        @constraint(prob, z_srv[i] == sum(mask .* X) - round(Int, dp.rates[i] * X_len))
    end

    ### TODO: check if the non-active groups are empty
    
    diff_active = z_srv[dp.group_active][1:len] # all non zero without last one
    loss = diff_active' * dp.cov_inv * diff_active / X_len # quadratic form
    
    return loss
end

function validate(sim::Vector{Float64}, dp::SurvivalMetric)
    # Check that the simulation data is not empty
    isempty(sim) && 
        throw(ArgumentError("Simulation data cannot be empty"))

    # Check that the simulation data is not NaN
    any(isnan, sim) && 
        throw(ArgumentError("Simulation data cannot contain NaN values"))
    
    # Check that the simulation data contains no missing values
    any(ismissing, sim) && 
        throw(ArgumentError("Simulation data contains missing values"))
end

PARSERS["survival"] = (row) -> begin
    size = row[Symbol("metric.size")]
    levels_string = row[Symbol("metric.levels")]
    levels = parse.(Float64, split(levels_string, ";"))
    values_string = row[Symbol("metric.values")]
    values = parse.(Float64, split(values_string, ";"))

    SurvivalMetric(size, levels, values)
end
