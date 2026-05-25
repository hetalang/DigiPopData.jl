# check PARSERS
@test haskey(PARSERS, "quantile")
@test PARSERS["quantile"] isa Function

df = DataFrame(
    var"metric.levels" = ["0.1;0.2;0.3"],
    var"metric.values" = ["1.0;2.0;3.0"],
    var"metric.size" = [100],
    var"metric.skip_nan" = [true],
    var"metric.weight" = [2.0],
)

raw1 = eachrow(df)[1]
m1 = PARSERS["quantile"](raw1)

@test m1 isa QuantileMetric
@test m1.levels == [0.1, 0.2, 0.3]
@test m1.values == [1.0, 2.0, 3.0]
@test m1.size == 100
@test m1.skip_nan == true
@test m1.weight == 2.0
