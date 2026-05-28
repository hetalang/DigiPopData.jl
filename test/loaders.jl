# all correct
bindings_df = DataFrame(
    id = ["1", "2", "3"],
    active = [true, false, true],
    scenario = ["scn1", "scn2", "scn3"],
    endpoint = ["A", "B", "C"],
    var"metric.type" = ["mean", "mean", "mean_sd"],
    var"metric.mean" = [1.0, 2.0, 3.0],
    var"metric.sd" = [0.1, 0.2, 0.3],
    var"metric.size" = [100, 200, 300],
    var"weight" = [2.0, missing, 0.5],
)

bindings = parse_metric_bindings(bindings_df)

@test length(bindings) == 3
@test bindings[1].metric isa MeanMetric
@test bindings[2].metric isa MeanMetric
@test bindings[3].metric isa MeanSDMetric
@test bindings[1].active == true
@test bindings[2].active == false
@test bindings[3].active == true
@test bindings[1].weight == 2.0
@test bindings[2].weight == 1.0
@test bindings[3].weight == 0.5

# default active
bindings_df2 = DataFrame(
    id = ["1"],
    scenario = ["scn1"],
    endpoint = ["A"],
    var"metric.type" = ["mean"],
    var"metric.mean" = [1.0],
    var"metric.sd" = [0.1],
    var"metric.size" = [100],
)

bindings2 = parse_metric_bindings(bindings_df2)

@test length(bindings2) == 1
@test bindings2[1].active == true
@test bindings2[1].weight == 1.0

# active parsing from tabular data
bindings_df_active = DataFrame(
    id = string.(1:8),
    active = [1, 0, "1", "0", "true", "false", missing, ""],
    scenario = fill("scn1", 8),
    endpoint = fill("A", 8),
    var"metric.type" = fill("mean", 8),
    var"metric.mean" = fill(1.0, 8),
    var"metric.sd" = fill(0.1, 8),
    var"metric.size" = fill(100, 8),
)

bindings_active = parse_metric_bindings(bindings_df_active)

@test getproperty.(bindings_active, :active) == [true, false, true, false, true, false, true, true]

bindings_df_bad_active = DataFrame(
    id = ["1"],
    active = [2],
    scenario = ["scn1"],
    endpoint = ["A"],
    var"metric.type" = ["mean"],
    var"metric.mean" = [1.0],
    var"metric.sd" = [0.1],
    var"metric.size" = [100],
)

@test_throws ErrorException parse_metric_bindings(bindings_df_bad_active)

# parsing error
bindings_df3 = DataFrame(
    id = ["1"],
    scenario = ["scn1"],
    endpoint = ["A"],
    var"metric.type" = ["unknown"], # error here
    var"metric.mean" = [1.0],
    var"metric.sd" = [0.1],
    var"metric.size" = [100],
)

@test_throws ErrorException parse_metric_bindings(bindings_df3)
