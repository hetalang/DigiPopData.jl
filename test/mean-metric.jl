# correct input
m1 = MeanMetric(100, 2.0, 0.5)

@test isapprox(mismatch([1.0, 2.0, 3.0], m1), 0.) # 0.0 = 3 * (2 - 2)^2 / 0.5^2
@test isapprox(mismatch([2., 3., 4.], m1), 12.0) # 12.0 = 3 * (3 - 2)^2 / 0.5^2

@test_throws ArgumentError mismatch(Float64[], m1) # too short
@test_throws ArgumentError mismatch([1., 2.], m1) # too short
@test_throws ArgumentError mismatch([1., 2., NaN], m1) # NaN value
@test_throws ArgumentError mismatch([1., 2., Inf], m1) # Inf value
@test_throws MethodError mismatch([1., 2., missing], m1) # missing value

# incorrect metric
@test_throws ArgumentError MeanMetric(100, 2.0, -0.5) # negative sd
@test_throws ArgumentError MeanMetric(100, 2.0, 0.0) # zero sd
@test_throws ArgumentError MeanMetric(100, 2.0, NaN) # NaN sd
@test_throws ArgumentError MeanMetric(100, 2.0, Inf) # Inf sd
@test_throws ArgumentError MeanMetric(100, NaN, 0.5) # NaN mean
@test_throws ArgumentError MeanMetric(100, Inf, 0.5) # Inf mean

# add_mismatch_expression! tests
model = JuMP.Model()
@variable(model, X[1:101], Bin)

m2 = MeanMetric(100, 10.0, 1.0)
simulated_data = collect(0.:1.:100.) # Simulated data for testing
expr1 = add_mismatch_expression!(model, simulated_data, m2, X, 10)

#@test expr1 isa QuadExpr

@test_throws DimensionMismatch add_mismatch_expression!(model, simulated_data, m2, X, 500) # too long X_len
simulated_data = collect(0.:1.:99.) # 
@test_throws DimensionMismatch add_mismatch_expression!(model, simulated_data, m2, X, 10) # length of sim and X are not equal