# check PARSERS
@test haskey(PARSERS, "survival")
@test PARSERS["survival"] isa Function

df = DataFrame(
    var"metric.values" = ["10;20;30"],
    var"metric.levels" = ["0.9;0.5;0.1"],
    var"metric.size" = [100],
)

raw1 = eachrow(df)[1]
m1 = PARSERS["survival"](raw1)

@test m1 isa SurvivalMetric
@test m1.values == [10.0, 20.0, 30.0]
@test m1.levels == [0.9, 0.5, 0.1]
@test m1.size == 100
