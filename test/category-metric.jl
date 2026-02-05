# correct metric
m1 = CategoryMetric(100, ["A", "B", "C"], [0.5, 0.3, 0.2])

@test m1.group_active == [true, true, true] # all groups are active
@test all(m1.cov_inv .≈ [7.0 5.0; 5.0 8.333333333333334])

@test isapprox(mismatch(["A", "A", "A", "B", "B", "C"], m1), 0.055555556)
@test isapprox(mismatch(["A", "B", "A", "A", "B", "C"], m1), 0.055555556)
@test isapprox(mismatch(["A", "A", "A", "A", "A", "A"], m1), 6.0)
@test_throws ArgumentError mismatch(["A", "B", "C", "D"], m1)
@test_throws MethodError mismatch([1,2,3,4,5,6], m1)
@test_throws ArgumentError mismatch(String[], m1)

m2 = CategoryMetric(100, ["A", "B", "C"], [0.5, 0.5, 0.0])
@test m2.group_active == [true, true, false] # only A and B are active
@test all(m2.cov_inv .≈ [4.0;;])

@test isapprox(mismatch(["A", "A", "A", "B", "B"], m2), 0.2)
@test isapprox(mismatch(["A", "B", "A", "B", "A"], m2), 0.2)
@test_throws ArgumentError mismatch(["A", "A", "A", "B", "C"], m2) # C is not active

# incorrect metric
@test_throws ArgumentError CategoryMetric(100, ["A", "B", "C"], [0.5, 0.3, -0.2]) # negative rate
@test_throws ArgumentError CategoryMetric(100, ["A", "B", "C"], [0.5, 0.3, 0.1]) # sum not 0
@test_throws ArgumentError CategoryMetric(100, ["A", "B", "C"], [0.5, 0.3, NaN]) # NaN rate
@test_throws DimensionMismatch CategoryMetric(100, ["A", "B", "C"], [0.5, 0.5]) # groups and rates not same length
@test_throws DimensionMismatch CategoryMetric(100, ["A", "B"], [0.5, 0.3, 0.2]) # groups and rates not same length
@test_throws ArgumentError CategoryMetric(100, ["A", "A", "C"], [0.5, 0.3, 0.2]) # non unique groups
@test_throws ArgumentError CategoryMetric(100, ["A"], [1.0])
@test_throws ArgumentError CategoryMetric(100, String[], Float64[]) # emty groups and rates

# add_mismatch_expression! tests
model = JuMP.Model()
@variable(model, X[1:101], Bin)
m3 = CategoryMetric(100, ["A", "B", "C"], [0.5, 0.3, 0.2])
simulated_data = [fill("A", 50); fill("B", 50); "C"]
expr1 = add_mismatch_expression!(model, simulated_data, m3, X, 10)

@test expr1 isa QuadExpr

@test_throws DimensionMismatch add_mismatch_expression!(model, simulated_data, m3, X, 500) # too long X_len
simulated_data = [fill("A", 50); fill("B", 50)]
@test_throws DimensionMismatch add_mismatch_expression!(model, simulated_data, m3, X, 10) # length of sim and X are not equal