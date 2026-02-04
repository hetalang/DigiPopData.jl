# SurvivalMetric

`SurvivalMetric` is used for experimental endpoints reported as **survival curves**
or, more generally, as **survival levels** associated with ordered values.
Typical examples include time-to-event data, progression-free survival,
or any endpoint where the probability of remaining below or above a threshold
is reported.

The metric does **not** assume a specific time scale or hazard model.
Survival levels are treated as cumulative probabilities that define
intervals over an ordered outcome axis.

See API reference: [`DigiPopData.SurvivalMetric`](@ref DigiPopData.SurvivalMetric).

## Concept

Experimental survival data are typically reported as decreasing survival levels
(e.g. 0.9, 0.8, 0.7) associated with increasing values
(e.g. time points or threshold values).

These survival levels define a partition of the outcome space into disjoint intervals.
Each interval corresponds to the fraction of the population whose outcome
falls between two consecutive survival levels.

Simulated individual outcomes are assigned to these intervals,
and the resulting interval counts are compared with the expected probabilities.
This reduces survival comparison to the same categorical framework
used by [`CategoryMetric`](category.md) and [`QuantileMetric`](quantile.md).

## Example

Assume experimental data report survival levels at increasing time points
for a cohort of 120 patients:

- Survival 0.9 at time 5
- Survival 0.7 at time 10
- Survival 0.4 at time 20

This can be encoded as a `SurvivalMetric`:

```julia
using DigiPopData

s_metric = SurvivalMetric(
    120,                # experimental sample size
    [0.9, 0.7, 0.4],    # survival levels (descending)
    [5.0, 10.0, 20.0]   # corresponding values (ascending)
)
```

Survival levels must be sorted in descending order,
while the associated values must be sorted in ascending order.

## Comparison with simulated data

Assume a virtual population where each individual produces
a single event time (or an ordered outcome value).

Simulation results are provided as a numeric vector:

```julia
using Random
sim_times = randexp(1000)
```

Each simulated value is assigned to one of the survival intervals
defined by the experimental data.
The resulting interval counts are used to compute the mismatch.

To compute the loss, we can use the `mismatch` function:
```julia
loss = mismatch(sim_times, s_metric)
```

## Mathematics

Let reported survival levels be
```math
1 \ge s_1 > s_2 > \dots > s_m \ge 0
```
with corresponding ordered values
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

The associated interval probabilities are derived as differences
of successive survival levels:
```math
p_1 = 1 - s_1,\quad
p_i = s_{i-1} - s_i\; (i=2,\dots,m),\quad
p_{m+1} = s_m.
```

For a virtual population of size `N`, simulated values produce counts
```math
\vec{k} = (k_1, \dots, k_{m+1}), \quad \sum_i k_i = N.
```

Under this construction, interval counts follow a multinomial distribution.
As in [`CategoryMetric`](category.md) and [`QuantileMetric`](quantile.md),
a Gaussian approximation of the multinomial likelihood is used,
leading to the quadratic loss:

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

- Survival information is treated as cumulative probability data,
  without assuming a specific hazard or time model.
- The resulting loss is a Gaussian approximation of a likelihood
  and can be combined with other likelihood-based metrics.
- The quadratic form enables use in optimization and
  mixed-integer quadratic programming workflows.
