# CategoryMetric

`CategoryMetric` is used for experimental endpoints where the outcome for each individual
is a **categorical label**.
Typical examples include responder status, disease subtype, toxicity grade, or any discrete classification without an inherent numeric scale.

This metric compares the **distribution of categories** observed in an experiment with the distribution produced by individual-level simulations.

See also: [`CategoryMetric`](@ref DigiPopData.CategoryMetric).

## Example

Consider a clinical study evaluating a new treatment.
Each patient is classified into one of three response categories:
- `Responder`
- `Non-Responder`
- `Partial Responder`

The experimental cohort consists of 100 patients with the following distribution:

- Responder: 40  
- Non-Responder: 50  
- Partial Responder: 10  

This information can be encoded as a `CategoryMetric` as follows:
```julia
using DigiPopData

cat_metric1 = CategoryMetric(
   100, # size
   ["Responder", "Non-Responder", "Partial Responder"], # groups
   [0.4, 0.5, 0.1] # rates
)
```
Here, the experimental data are represented as population-level proportions, without access to individual patient outcomes.

Simulation results are stored as a vector of categorical outcomes, where each element corresponds to one virtual patient.
```julia
resp = rand(["Responder", "Non-Responder", "Partial Responder"], 1000)
```

To compute the loss, we can use the `mismatch` function:
```julia
loss = mismatch(resp, cat_metric1)
```
This will calculate the discrepancy between the observed category distribution in the experimental data
and the distribution derived from the simulated individual outcomes.

## Mathematics

`CategoryMetric` compares simulated categorical outcomes with experimental category frequencies.
Let an experiment define a categorical distribution with probabilities
$\vec{p} = (p_1, \dots, p_g)$
estimated from an experimental cohort of size $\hat{N}$.

A virtual population of size $N$ produces counts
$\vec{k} = (k_1, \dots, k_g)$,
where $\sum_i k_i = N$.

### Exact likelihood

In principle, simulated counts follow a multinomial distribution:

```math
(k_1, \dots, k_g) \sim \mathrm{Multinomial}(N, \vec{p})
```

The corresponding negative log-likelihood is:

```math
-2 \log L
= -2 \sum_{i=1}^{g} k_i \log p_i
+ 2 \log(N!)
- 2 \sum_{i=1}^{g} \log(k_i!)
```

This exact formulation is rarely used directly in practice due to numerical
instability and strong parameter coupling.

### Gaussian approximation

For sufficiently large $N$ and non-degenerate probabilities,
the multinomial distribution can be approximated by a multivariate normal distribution:

```math
\vec{k} \sim \mathcal{N}(N\vec{p}, \Sigma')
```

with covariance matrix:

```math
\Sigma' = N \left( \mathrm{diag}(\vec{p}) - \vec{p}\vec{p}^T \right)
```

This covariance matrix is singular due to the constraint
$\sum_i k_i = N$.
To obtain a non-singular representation, one category is removed,
and only the first $g-1$ categories are used.

The resulting mismatch (loss) is computed as a Mahalanobis distance:

```math
\Lambda
\approx
(\vec{k} - N\vec{p})^T \Sigma'^{-1} (\vec{k} - N\vec{p})
```

Lower values of $\Lambda$ indicate better agreement between
simulated and experimental category distributions.

### Quadratic formulation for binary selection

In virtual population selection problems, each simulated individual is either included or excluded
from the cohort. This is represented by a binary selection vector
$X \in \{0,1\}^{N_{tot}}$, where $X_i = 1$ indicates that virtual patient $i$ is selected.

For a categorical endpoint with $g$ groups, define indicator vectors
$Z_1, \dots, Z_{g-1} \in \{0,1\}^{N_{tot}}$,
where $(Z_j)_i = 1$ if patient $i$ belongs to category $j$.
The number of selected patients in each category is then given by
$k_j = Z_j^T X$.

Using the Gaussian approximation of the multinomial distribution,
the mismatch between simulated and experimental category distributions
can be written as a Mahalanobis distance:
```math
\Lambda(X)
=
(\vec{k} - N_{virt} \vec{p})^T
\Sigma'^{-1}
(\vec{k} - N_{virt} \vec{p})
```
where $\vec{p}$ are experimental category probabilities,
$N_{virt} = \mathbf{1}^T X$,
and $\Sigma' = N_{virt}(\mathrm{diag}(\vec{p}) - \vec{p}\vec{p}^T)$.

Substituting $\vec{k} = Z^T X$ shows that $\Lambda(X)$ is a quadratic form
with respect to the binary decision variables $X$.
As a result, cohort selection based on `CategoryMetric`
can be formulated as a Mixed-Integer Quadratic Programming (MIQP) problem.
