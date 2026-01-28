using DigiPopData, JuMP
import DigiPopData: PARSERS
using DataFrames
using Test

@testset "DigiPopData Metric unit tests" begin
    @testset "MeanMetric unit tests" begin include("mean-metric.jl") end
    @testset "MeanSDMetric unit tests" begin include("mean-sd-metric.jl") end
    @testset "CategoryMetric unit tests" begin include("category-metric.jl") end
    @testset "QuantileMetric unit tests" begin include("quantile-metric.jl") end
    @testset "SurvivalMetric unit tests" begin include("survival-metric.jl") end

    @testset "MeanMetric parser tests" begin include("mean-metric-parser.jl") end
    @testset "MeanSDMetric parser tests" begin include("mean-sd-metric-parser.jl") end
    @testset "CategoryMetric parser tests" begin include("category-metric-parser.jl") end
    @testset "QuantileMetric parser tests" begin include("quantile-metric-parser.jl") end
    @testset "SurvivalMetric parser tests" begin include("survival-metric-parser.jl") end
end

@testset "DigiPopData other unit tests" begin
    @testset "MetricBinding unit tests" begin include("metric-binding.jl") end
    @testset "loaders unit tests" begin include("loaders.jl") end
end

@testset "DigiPopData invariance tests" begin
    include("category-metric-invariance.jl")
end
