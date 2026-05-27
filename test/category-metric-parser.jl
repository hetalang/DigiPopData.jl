# check PARSERS
@test haskey(PARSERS, "category")
@test PARSERS["category"] isa Function

df = DataFrame(
    var"metric.groups" = ["A;B;C"],
    var"metric.rates" = ["0.2;0.3;0.5"],
    var"metric.size" = [100],
)

raw1 = eachrow(df)[1]
m1 = PARSERS["category"](raw1)

@test m1 isa CategoryMetric
@test m1.groups == ["A", "B", "C"]
@test m1.rates == [0.2, 0.3, 0.5]
@test m1.size == 100
