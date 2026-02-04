# MeanMetric

`MeanMetric` is used for experimental endpoints reported as a **mean value** with an associated variability measure.
It compares the mean of individual-level simulation outputs to a target experimental mean.

The metric assumes that experimental summary statistics are fixed targets and does not attempt to model uncertainty of the experimental mean itself.

See API reference: [`MeanMetric`](@ref DigiPopData.MeanMetric).

## Concept

Many experimental datasets report only a population mean and a standard deviation, without providing individual-level observations.
In such cases, model calibration often proceeds by matching simulated population averages to reported mean values.

`MeanMetric` formalizes this comparison by measuring the discrepancy between the mean of simulated individuals and the experimental target mean, scaled by the reported variability.

The experimental standard deviation is treated as a known scale parameter and is used to normalize the mismatch.

## Example

Assume experimental data report a mean biomarker value of 2.5 with a standard deviation of 0.6, based on a cohort of 50 patients.

This can be encoded as a `MeanMetric`:

```julia
using DigiPopData

m_metric = MeanMetric(
    50,     # experimental sample size
    2.5,    # experimental mean
    0.6     # experimental standard deviation
)
```

Assume a virtual population where each individual produces a single numeric outcome:

```julia
sim_values = randn(1000) .* 0.6 .+ 2.5
```

The mismatch between simulation and experiment is computed as:

```julia
loss = mismatch(sim_values, m_metric)
```

## Mathematics

Let simulated individual values be
$y_1, \dots, y_N$,
with sample mean
```math
\mu_{virt} = \frac{1}{N} \sum_{i=1}^{N} y_i.
```

Let the experimental target be a mean value $\mu_{exp}$
with reported standard deviation $\sigma$.

The mismatch is computed as:
```math
\Lambda
=
N \frac{(\mu_{virt} - \mu_{exp})^2}{\sigma^2}.
```

This expression corresponds to a Gaussian
(second-order) approximation of the negative log-likelihood
under the assumption that individual observations are normally distributed
with known variance $\sigma^2$.

### Quadratic formulation for binary selection

In virtual population selection problems, each simulated individual is either included
or excluded from the selected cohort.
This is represented by a binary selection vector
$X \in \{0,1\}^{N_{tot}}$, where $X_i = 1$ indicates that individual $i$ is selected.

Let simulated individual outcomes be $y_1, \dots, y_{N_{tot}}$.
The mean of the selected virtual cohort of fixed size $N_{virt}$ is

```math
\mu_{virt}(X) = \frac{1}{N_{virt}} \sum_{i=1}^{N_{tot}} X_i y_i.
```

The mismatch defined by `MeanMetric` can then be written as

```math
\Lambda(X)
=
N_{virt}
\frac{(\mu_{virt}(X) - \mu_{exp})^2}{\sigma^2}.
```

Substituting the expression for $\mu_{virt}(X)$ yields

```math
\Lambda(X)
=
\frac{1}{\sigma^2 N_{virt}}
\left( \sum_{i=1}^{N_{tot}} X_i y_i - N_{virt} \mu_{exp} \right)^2.
```

This expression is a **quadratic function of the binary variables $X$**.
Therefore, virtual population selection based on `MeanMetric`
can be formulated as a Mixed-Integer Quadratic Programming (MIQP) problem,
provided that the cohort size $N_{virt}$ is fixed
(e.g. enforced via a constraint $\sum_i X_i = N_{virt}$).

## Practical notes

- The reported standard deviation is treated as a fixed scale parameter
  and is not re-estimated from simulated data.
- The experimental sample size is stored for consistency with other metrics
  but is not currently used in the loss computation.
- The resulting loss is likelihood-based and can be combined
  with other metric losses.
- The quadratic form enables use in optimization workflows,
  including mixed-integer quadratic programming formulations.
