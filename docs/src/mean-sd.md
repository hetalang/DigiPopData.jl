# MeanSDMetric

`MeanSDMetric` is used for experimental endpoints reported as a **mean** together with a **standard deviation (SD)**.
It compares both the average level and the overall variability of individual-level simulation outputs
to the corresponding experimental targets.

See API reference: [`MeanSDMetric`](@ref DigiPopData.MeanSDMetric).

## Concept

Many publications report a mean and SD but do not provide individual observations.
`MeanSDMetric` treats these summary statistics as fixed targets and evaluates how well a simulated cohort matches them.

The loss is implemented as a sum of two terms:
- a mean-matching term (same structure as [`MeanMetric`](mean.md)),
- an SD-matching term that penalizes deviation of the simulated second central moment
  from the target variance.

**Implementation note.** For consistency between `mismatch` and `mismatch_expression`, the simulated variance proxy is computed around the *target mean* rather than the simulated mean.
This keeps the expression affine in binary selection variables (see below) and leads to a quadratic MIQP objective.

## Example

Assume experimental data report a mean value of 2.5 and an SD of 0.6
based on a cohort of 50 patients:

```julia
using DigiPopData

ms_metric = MeanSDMetric(
    50,     # experimental sample size
    2.5,    # experimental mean
    0.6     # experimental standard deviation
)
```

Simulated individual outcomes can be provided as a numeric vector:

```julia
sim_values = randn(1000) .* 0.7 .+ 2.4
loss = mismatch(sim_values, ms_metric)
```

## Mathematics

Let simulated individual values be $y_1,\dots,y_N$ with sample mean
```math
\mu_{virt} = \frac{1}{N}\sum_{i=1}^{N} y_i.
```

Let the experimental targets be $\mu_{exp}$ and $\sigma$ (SD).

### Mean term

The mean mismatch term is:
```math
\Lambda_\mu = N\,\frac{(\mu_{virt} - \mu_{exp})^2}{\sigma^2}.
```

### SD term (variance proxy)

In the current implementation, the simulated second central moment is evaluated around the target mean:
```math
s^2_{virt} = \frac{1}{N}\sum_{i=1}^{N}(y_i - \mu_{exp})^2.
```

The SD mismatch term penalizes deviation from the target variance $\sigma^2$:
```math
\Lambda_{\sigma}
= \frac{N}{2}\,\frac{(s^2_{virt} - \sigma^2)^2}{\sigma^4}.
```

The total loss is:
```math
\Lambda = \Lambda_\mu + \Lambda_{\sigma}.
```

This form is likelihood-inspired (Gaussian second-order / chi-square style scaling) and is designed
to be additive with other metric losses.

## Quadratic formulation for binary selection

For cohort selection, introduce a binary vector $X\in\{0,1\}^{N_{tot}}$ where $X_i=1$ means that individual $i$ is selected.
Assume the selected cohort size is fixed: $\sum_i X_i = N_{virt}$.

The selected-cohort mean is:
```math
\mu_{virt}(X) = \frac{1}{N_{virt}}\sum_{i=1}^{N_{tot}} X_i y_i.
```

The variance proxy used by the implementation is:
```math
s^2_{virt}(X) = \frac{1}{N_{virt}}\sum_{i=1}^{N_{tot}} X_i (y_i - \mu_{exp})^2.
```

Both $\mu_{virt}(X)$ and $s^2_{virt}(X)$ are affine in $X$ for fixed $N_{virt}$.
Therefore, each squared deviation term is a quadratic function of the binary decision variables,
and the total loss $\Lambda(X)$ defines a Mixed-Integer Quadratic Programming (MIQP) objective.

## Practical notes

- `size` is stored for consistency and potential future extensions but is not used in the current loss.
- The SD term uses a variance proxy computed around the target mean to preserve quadratic structure for MIQP.
- The loss is intended for engineering workflows (calibration / selection) and can be summed with other metric losses.
- As with all moment-based matching, rare heavy tails and strong outliers may affect SD matching and should be handled at the data preparation stage.
