# check PARSERS
@test haskey(PARSERS, "mean_sd")
@test PARSERS["mean_sd"] isa Function

df = DataFrame(
    var"metric.mean" = [1.0],
    var"metric.sd" = [0.1],
    var"metric.size" = [100],
)

raw1 = eachrow(df)[1]

m1 = PARSERS["mean_sd"](raw1)

@test m1 isa MeanSDMetric
@test m1.mean == 1.0
@test m1.sd == 0.1
@test m1.size == 100
