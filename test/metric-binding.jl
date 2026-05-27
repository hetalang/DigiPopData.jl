m1 = MeanMetric(100, 2.0, 0.5)
mb1 = MetricBinding("MB1", "scenario1", m1, "endpoint1", true)
mb2 = MetricBinding("MB2", "scenario1", m1, "endpoint2", true)
mb3 = MetricBinding("MB3", "scenario1", m1, "endpoint3", false)
mb4 = MetricBinding("MB4", "scenario1", m1, "endpoint2", true; weight=2.0)

@test mb1.weight == 1.0
@test mb4.weight == 2.0
@test mismatch([4.0, 5.0, 6.0], mb4) ≈ 216.0
@test_throws ArgumentError MetricBinding("MB5", "scenario1", m1, "endpoint2", true; weight=-1.0)

df1 = DataFrame(
    id = ["p1", "p2", "p3"],
    scenario = ["scenario1", "scenario1", "scenario1"],
    endpoint1 = [1., 2., 3.],
    endpoint2 = [4.0, 5.0, 6.0],
    endpoint3 = [7.0, 8.0, 9.0],
)

@test get_loss(df1, [mb1]) ≈ 0.0
@test get_loss(df1, [mb2]) ≈ 108.
@test get_loss(df1, [mb3]) ≈ 0.0
@test get_loss(df1, [mb4]) ≈ 216.0
@test get_loss(df1, [mb1, mb2, mb3]) ≈ 108.0
@test get_loss(df1, MetricBinding[]) ≈ 0.
