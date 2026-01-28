### check formulas for category-metric invariance

m1 = CategoryMetric(100, ["A", "B", "C"], [0.5, 0.3, 0.2])
m2 = CategoryMetric(100, ["B", "C", "A"], [0.3, 0.2, 0.5])
m3 = CategoryMetric(100, ["C", "A", "B"], [0.2, 0.5, 0.3])

## For QuadExpr
# use "evaluation" method because JuMP does not support substitution
# it would be better to use sum(X) = 6 substitution, but JuMP does not support it

# create JuMP model with binary variables
model = JuMP.Model()
@variable(model, X[1:10], Bin)

# create metric, add experimental data and compute objective function
of1 = mismatch_expression(["A", "A", "A", "A", "B", "B", "B", "C", "C", "C"], m1, X, 6)

# create another metric with same parameters, add experimental data in different order and compute objective function
of2 = mismatch_expression(["A", "A", "A", "A", "B", "B", "B", "C", "C", "C"], m2, X, 6)

# create third metric with different parameters and compute objective function
of3 = mismatch_expression(["A", "A", "A", "A", "B", "B", "B", "C", "C", "C"], m3, X, 6)

x_vals = [1, 0, 1, 0, 1, 0, 1, 0, 1, 1]

function eval_quad(expr::QuadExpr, vars, vals)
    result = expr.aff.constant
    
    # Линейные члены
    for (var, coef) in expr.aff.terms
        idx = findfirst(==(var), vars)
        result += coef * vals[idx]
    end
    
    # Квадратичные члены  
    for (pair, coef) in expr.terms
        i = findfirst(==(pair.a), vars)
        j = findfirst(==(pair.b), vars)
        result += coef * vals[i] * vals[j]
    end
    
    return result
end

val1 = eval_quad(of1 - of2, X, x_vals)
val2 = eval_quad(of1 - of3, X, x_vals)
val3 = eval_quad(of2 - of3, X, x_vals)

@test val1 ≈ val2
@test isapprox(val2, 0.0; atol=1e-9)
@test isapprox(val3, 0.0; atol=1e-9)

## For numbers

mm1 = mismatch(["A", "A", "A", "A", "A", "A", "A", "A", "A", "B"], m1)
mm2 = mismatch(["A", "A", "A", "A", "A", "A", "A", "A", "A", "B"], m2)
mm3 = mismatch(["A", "A", "A", "A", "A", "A", "A", "A", "A", "B"], m3)

@test mm1 ≈ mm2 ≈ mm3
