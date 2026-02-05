# correct input
m1 = SurvivalMetric(100, [0.75, 0.5, 0.25], [24., 48., 72.])

@test m1.group_active == [true, true, true, true]
@test all(m1.cov_inv .≈ [8. 4. 4.; 4. 8. 4.; 4. 4. 8.])

@test mismatch([12., 36., 60., 84.], m1) ≈ 0.
@test mismatch([0., 36., 60., Inf], m1) ≈ 0.
@test mismatch([12., 36., 60., 12.], m1) ≈ 2.
@test_throws ArgumentError mismatch([12., 36., 60., NaN], m1)
@test_throws ArgumentError mismatch(Float64[], m1)

# correct input with equal levels
m2 = SurvivalMetric(100, [0.75, 0.5, 0.5, 0.25], [24., 48., 60., 72.])

@test m2.group_active == [true, true, false, true, true]
@test all(m2.cov_inv .≈ [8. 4. 4.; 4. 8. 4.; 4. 4. 8.])
@test mismatch([12., 36., 61., 80.], m2) ≈ 0.0
@test_broken mismatch([12., 36., 59., 80.], m2) ≈ 0.0 # inactive group uses next active

# correct input with level 1.0
m3 = SurvivalMetric(100, [1.0, 0.75, 0.5, 0.25], [12., 24., 48., 72.])

@test m3.group_active == [false, true, true, true, true]
@test all(m3.cov_inv .≈ [8. 4. 4.; 4. 8. 4.; 4. 4. 8.])
@test mismatch([13., 36., 60., 84.], m3) ≈ 0.0
@test_broken mismatch([11., 36., 60., 84.], m3) ≈ 0.0

# correct input with level 0.
m4 = SurvivalMetric(100, [0.75, 0.5, 0.25, 0.0], [24., 48., 72., 120.])

@test m4.group_active == [true, true, true, true, false]
@test all(m4.cov_inv .≈ [8. 4. 4.; 4. 8. 4.; 4. 4. 8.])
@test mismatch([12., 36., 60., 119.], m4) ≈ 0.0
@test mismatch([12., 36., 60., 121.], m4) ≈ 0.0

# incorrect metric
@test_throws ArgumentError SurvivalMetric(100, [0.5, 0.3, -0.2], [1., 10., 100.]) # negative rate
@test_throws ArgumentError SurvivalMetric(100, [0.3, 0.4, 0.1], [1., 10., 100.]) # not decenting
@test_throws ArgumentError SurvivalMetric(100, [0.5, 0.3, 0.1], [1., 100., 10.]) # not ascenting
@test_throws ArgumentError SurvivalMetric(100, [0.5, 0.3, 0.1], [1., 10., NaN]) # NaN rate
@test_throws DimensionMismatch SurvivalMetric(100, [0.5, 0.3, 0.1], [1., 10., 100., 1000.]) # wrong length
@test_throws ArgumentError SurvivalMetric(100, Float64[], Float64[]) # empty

# add_mismatch_expression! tests
model = JuMP.Model()
@variable(model, X[1:101], Bin)
m5 = SurvivalMetric(100, [0.75, 0.5, 0.25], [24., 48., 72.])
simulated_data = [fill(5., 50); fill(15., 50); 20.]
expr1 = add_mismatch_expression!(model, simulated_data, m5, X, 10)

@test expr1 isa QuadExpr

@test_throws DimensionMismatch add_mismatch_expression!(model, simulated_data, m5, X, 500) # too long X_len
simulated_data = [fill(5., 50); fill(15., 50)]
@test_throws DimensionMismatch add_mismatch_expression!(model, simulated_data, m5, X, 10) # length of sim and X are not equal
