# check PARSERS
@test haskey(PARSERS, "quantile")
@test PARSERS["quantile"] isa Function

df = DataFrame(
    var"metric.levels" = ["0.1;0.2;0.3"],
    var"metric.values" = ["1.0;2.0;3.0"],
    var"metric.size" = [100],
    var"metric.skip_nan" = [true],
)

raw1 = eachrow(df)[1]
m1 = PARSERS["quantile"](raw1)

@test m1 isa QuantileMetric
@test m1.levels == [0.1, 0.2, 0.3]
@test m1.values == [1.0, 2.0, 3.0]
@test m1.size == 100
@test m1.skip_nan == true

df_default_skip_nan = DataFrame(
    var"metric.levels" = ["0.1;0.2;0.3"],
    var"metric.values" = ["1.0;2.0;3.0"],
    var"metric.size" = [100],
)

m2 = PARSERS["quantile"](eachrow(df_default_skip_nan)[1])

@test m2 isa QuantileMetric
@test m2.skip_nan == false

df_empty_skip_nan = DataFrame(
    var"metric.levels" = ["0.1;0.2;0.3"],
    var"metric.values" = ["1.0;2.0;3.0"],
    var"metric.size" = [100],
    var"metric.skip_nan" = [""],
)

m3 = PARSERS["quantile"](eachrow(df_empty_skip_nan)[1])

@test m3 isa QuantileMetric
@test m3.skip_nan == false
