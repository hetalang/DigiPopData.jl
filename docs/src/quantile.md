# QuantileMetric

`QuantileMetric` is used for experimental endpoints reported as **quantiles**
(e.g. median, quartiles, or arbitrary percentiles).
It allows comparison of individual-level simulation results with aggregated
quantile information published for a real population.

The metric does **not** attempt to reconstruct an underlying continuous distribution.
Instead, quantile information is represented in a structured way that enables
statistically consistent comparison with simulated data.

See API reference: [`QuantileMetric`](@ref DigiPopData.QuantileMetric).

## Concept

Experimental quantiles define thresholds that partition the outcome space
into disjoint intervals.
Each interval is associated with a known probability mass derived from the
reported quantile levels.

Simulated individual values are assigned to these intervals,
and the resulting interval counts are compared to the expected probabilities.
This reduces the quantile comparison problem to a categorical one,
allowing reuse of the same statistical framework as in [CategoryMetric](category.md).

## Example

Assume experimental data report the 25%, 50%, and 75% quantiles
of a biomarker measured in a cohort of 80 patients:

- 25% quantile: 1.2
- 50% quantile (median): 1.8
- 75% quantile: 2.6

This can be encoded as a `QuantileMetric`:

```julia
using DigiPopData

q_metric = QuantileMetric(
    80,                         # experimental sample size
    [0.25, 0.50, 0.75],         # quantile levels
    [1.2, 1.8, 2.6],            # quantile values
    skip_nan = true             # ignore NaN values in simulations
)
```

Here, quantile levels must be strictly increasing and lie in the open interval `(0, 1)`.
Quantile values must also be sorted in ascending order.

## Comparison with simulated data

Assume a virtual population of simulated individuals,
where each individual produces a single numeric outcome.

Simulation results can be provided as a vector:

```julia
sim_values = randn(1000) .+ 1.8
```

NaN values in simulation data are allowed if `skip_nan = true`
and are excluded from the comparison.

Each simulated value is assigned to one of the intervals defined by the quantiles,
and the resulting interval counts are used to compute the mismatch.

To compute the loss, we can use the `mismatch` function:
```julia
loss = mismatch(sim_values, q_metric)
```

## Mathematics

Let reported quantile levels be
```math
0 < q_1 < q_2 < \dots < q_m < 1
```
with corresponding quantile values
```math
v_1 < v_2 < \dots < v_m.
```

These values define `m+1` disjoint intervals:
```math
(-\infty, v_1),\;
[v_1, v_2),\;
\dots,\;
[v_m, +\infty).
```

The associated experimental probabilities are:
```math
p_1 = q_1,\quad
p_i = q_i - q_{i-1}\; (i=2,\dots,m),\quad
p_{m+1} = 1 - q_m.
```

For a virtual population of size `N`, simulated values produce interval counts
```math
\vec{k} = (k_1, \dots, k_{m+1}), \quad \sum_i k_i = N.
```

Under this construction, interval counts follow a multinomial distribution.
As in [CategoryMetric](category.md), a Gaussian approximation of the multinomial likelihood
is used, leading to the quadratic loss:

```math
\Lambda
\approx
(\vec{k} - N\vec{p})^T
\Sigma'^{-1}
(\vec{k} - N\vec{p}),
```

where
```math
\Sigma' = N (\mathrm{diag}(\vec{p}) - \vec{p}\vec{p}^T).
```

One interval is removed to eliminate linear dependence,
and the reduced quadratic form is evaluated.

## Practical notes

- Quantile-based comparison is robust to outliers
  and suitable for skewed or heavy-tailed distributions.
- No assumptions are made about the shape of the underlying distribution
  beyond the reported quantiles.
- The resulting loss is a Gaussian approximation of a likelihood
  and can be combined with other likelihood-based metrics.
- The quadratic form enables use in optimization and
  mixed-integer quadratic programming workflows.
