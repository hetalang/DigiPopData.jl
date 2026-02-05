
module DigiPopData

include("metric-types/abstract-metric.jl")
include("metric-binding.jl")
include("loaders.jl")

export mismatch, add_mismatch_expression!
export MetricBinding, get_loss
export parse_metric_bindings

# list of data point types can be extended by adding new types to this list
include("metric-types/mean-metric.jl")
include("metric-types/mean-sd-metric.jl")
include("metric-types/category-metric.jl")
include("metric-types/quantile-metric.jl")
include("metric-types/survival-metric.jl")

export MeanMetric, MeanSDMetric, CategoryMetric, QuantileMetric, SurvivalMetric

end
