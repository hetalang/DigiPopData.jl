# Metric Data Format
Experimental and clinical data are represented in DigiPopData.jl as a collection of **metrics**, i.e. aggregated summary statistics describing real patient populations.
Each metric defines a population-level experimental target that can be compared to individual-level simulations.

## Internal Julia representation

Internally, each row of experimental data is represented as a `MetricBinding`.
A `MetricBinding` links:
- an experimental metric (e.g. mean, quantile, category, survival),
- a `scenario` (e.g. treatment arm),
- and an `endpoint` column in the simulation table.

Example:

```julia
mb = MetricBinding(
    "m_mean_conc24_Tx",     # metric id
    "Tx",                   # scenario (e.g. treatment arm)
    MeanMetric(
        40,                 # experimental sample size
        2.1,                # mean value
        0.2                 # standard deviation
    ),
    "conc_t24",             # endpoint column in simulation data
    true                    # active flag
)
```

## Tabular metric definition

For practical workflows, metrics are usually defined in a table and loaded in bulk (e.g. from CSV or `DataFrame`) using `parse_metric_bindings`.
Each row corresponds to one metric.

### Core columns

A metric table typically includes:

- `id` — unique object identifier  
- `active` — whether the metric is included in the loss (`1` or `0`)  
- `scenario` — scenario identifier used to match simulation conditions  
- `endpoint` — name of the simulation output column used for comparison  
- `metric.type` — metric type (e.g. `mean`, `mean_sd`, `category`, `quantile`, `survival`)  
- `metric.size` — experimental sample size
- `metric.<prop>` — additional metric-specific properties, see more details in [Overview](metrics.md)

## Example table

The table below defines two metrics for the same scenario `Tx`:

| id | active | scenario | metric.type | metric.size | endpoint | metric.mean | metric.sd | metric.levels | metric.values |
|---|---:|---|---|---:|---|---:|---:|---:|---:|
| m\_conc24\_mean\_Tx | 1 | Tx | mean | 40 | conc_t24 | 2.10 | 0.2 |  |  |
| m\_biomarker\_q\_Tx | 1 | Tx | quantile | 40 | biomarker |  |  | 0.25;0.50;0.75 | 0.1;1.35;10.1 |

Interpretation:

- `m_conc24_mean_Tx` targets the **mean** of `conc_t24` in the experimental population.
- `m_biomarker_q_Tx` targets the **quantiles** (0.25, 0.50, 0.75) of `biomarker`.

In practice, you may store only the columns required by the metric types used in your dataset.

## Loading from CSV

```julia
using CSV, DataFrames

metrics_df = CSV.File("metrics.csv") |> DataFrame
metrics = parse_metric_bindings(metrics_df)
```
