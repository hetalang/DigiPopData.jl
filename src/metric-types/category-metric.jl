#=
    category data point represents a set of groups with their rates (probabilities).
    The probabilities are values from 0 to 1 and sum to 1.
    XXX: The special case is a group with 0 probability where members presented.
    Currently we check it in validate function and throw an error.
    Another option is to return a penalty for this case but it is not possible for working with JuMP.
=#
#const LOSS_PENALTY = Inf # when we found groups with 0 rates

"""
    CategoryMetric <: AbstractMetric

CategoryMetric is a metric descriptor for categorical data. It is based on polinomial distribution within the groups. 

## Fields
- `size::Int`: The size of the dataset.
- `groups::Vector{String}`: The names of the groups.
- `rates::Vector{Float64}`: The probabilities of each group.
- `cov_inv::Matrix{Float64}`: The inverse of the covariance matrix of the groups.
- `group_active::Vector{Bool}`: A boolean vector indicating which groups are active (non-zero rates).

## Constructor
- `CategoryMetric(size::Int, groups::Vector{String}, rates::Vector{Float64})`: Creates a new instance of CategoryMetric. 
  It validates the input data and calculates the inverse covariance matrix.
"""
struct CategoryMetric <: AbstractMetric
    size::Int
    groups::Vector{String} # names of the groups
    rates::Vector{Float64} # probabilities of each group
    cov_inv::Matrix{Float64} # inverse of the covariance matrix of the groups
    group_active::Vector{Bool}
    
    function CategoryMetric(size::Int, groups::Vector{String}, rates::Vector{Float64})
        _validate_category(groups, rates)

        # active groups are those with non-zero rates
        group_active = .!isapprox.(rates, 0., atol=RATE_TOL) # not 0
        len = sum(group_active) - 1 
        
        rates_reduced = rates[group_active][1:len] # all non zero without last one
        diag = [i == j ? rates_reduced[i] : 0.0 for i in 1:len, j in 1:len]
        cov = diag - rates_reduced * rates_reduced'
        cov_inv = inv(cov)

        new(size, groups, rates, cov_inv, group_active)
    end
end

_validate_category(groups::Vector{String}, rates::Vector{Float64}) = begin
    # Check that groups are unique
    length(unique(groups)) == length(groups) || 
        throw(ArgumentError("`groups` must be unique"))

    # rates must be in [0, 1)
    all(0 .<= rates .< 1) || 
        throw(ArgumentError("All rates must be in [0, 1)"))

    # Check that rates sum = 1
    isapprox(sum(rates), 1., atol=RATE_TOL) ||
        throw(ArgumentError("Sum of rates must be 1, got $(sum(rates))"))

    # groups and rates must be the same length
    length(groups) == length(rates) || 
        throw(DimensionMismatch("`groups` and `rates` must be the same length, got $(length(groups)) and $(length(rates))"))
end

function mismatch(
    sim::AbstractVector{<:AbstractString},  # we can also use sim::Vector{String} but it will not work with DataFrame
    dp::CategoryMetric
)
    validate(sim, dp)

    len = sum(dp.group_active) - 1
    # calculate number of simulations in each group
    count_virt = Int64[sum(sim .== group) for group in dp.groups]

    # return penalty if group with 0 rates is found in simulation
    #if any(count_virt[.!dp.group_active] .> 0)
    #    return LOSS_PENALTY
    #end

    # calculate the loss
    diff = count_virt .- dp.rates * length(sim)
    diff_active = diff[dp.group_active][1:len] # all non zero without last one
    loss = diff_active' * dp.cov_inv * diff_active / length(sim)

    return loss
end

function mismatch_expression(
    sim::AbstractVector{<:AbstractString},
    dp::CategoryMetric,
    X::Vector{VariableRef},
    X_len::Int
)
    validate(sim, dp)
    # Check that the length of sim and X are equal
    length(sim) == length(X) || throw(DimensionMismatch("Length of simulation data and X must be equal"))
    # Check that X_len is less than sim
    X_len <= length(sim) || throw(DimensionMismatch("X_len must be less than or equal to the length of simulation data"))
    
    len = sum(dp.group_active) - 1

    # calculate the loss
    diff = AffExpr[]
    for i in 1:length(dp.groups)
        mask = Int.(sim .== dp.groups[i])
        # adding round as the equations reflect number of persons 
        expr = sum(mask .* X) - round(Int, dp.rates[i] * X_len)
        push!(diff, expr)
    end

    diff_active = diff[dp.group_active][1:len] # all non zero without last one    
    loss = diff_active' * dp.cov_inv * diff_active / X_len

    loss
end

function add_mismatch_expression!(
    prob::GenericModel,
    sim::AbstractVector{<:AbstractString},
    dp::CategoryMetric,
    X::Vector{VariableRef},
    X_len::Int,
)
    validate(sim, dp)
    # Check that the length of sim and X are equal
    length(sim) == length(X) || throw(DimensionMismatch("Length of simulation data and X must be equal"))
    # Check that X_len is less than sim
    X_len <= length(sim) || throw(DimensionMismatch("X_len must be less than or equal to the length of simulation data"))
    
    len = sum(dp.group_active) - 1

    # calculate the loss
    z_ctg = @variable(prob, [i=1:length(dp.groups)] )
    for i in 1:length(dp.groups)
        mask = Int.(sim .== dp.groups[i])
        # adding round as the equations reflect number of persons 
        @constraint(prob, z_ctg[i] == sum(mask .* X) - round(Int, dp.rates[i] * X_len))
    end

    diff_active = z_ctg[dp.group_active][1:len] # all non zero without last one    
    loss = diff_active' * dp.cov_inv * diff_active / X_len

    loss
end

function validate(
    sim::AbstractVector{<:AbstractString},
    dp::CategoryMetric
) 
    # Check that the simulation data is not empty
    isempty(sim) && 
        throw(ArgumentError("Simulation data cannot be empty"))

    # Check that the simulation data contains only strings from groups
    all(x -> x in dp.groups, sim) || 
        throw(ArgumentError("Simulation data contains invalid groups, expected $(dp.groups)")) 

    # Check that the simulation data contains no missing values
    any(ismissing, sim) && 
        throw(ArgumentError("Simulation data contains missing values"))

    # Check that the simulation data contains no groups with 0 rates
    zero_groups = dp.groups[.!dp.group_active]
    for group in zero_groups
        count = sum(sim .== group)
        count > 0 && 
            throw(ArgumentError("Simulation data contains group \"$group\" with 0 rates but found $count in simulation"))
    end
end

PARSERS["category"] = (row) -> begin
    size = row[Symbol("metric.size")]
    groups_string = row[Symbol("metric.groups")]
    groups = split(groups_string, ";") .|> String
    rates_string = row[Symbol("metric.rates")]
    rates = parse.(Float64, split(rates_string, ";"))

    CategoryMetric(size, groups, rates)
end
