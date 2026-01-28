[![CI](https://github.com/hetalang/DigiPopData.jl/actions/workflows/autotest.yml/badge.svg)](https://github.com/hetalang/DigiPopData.jl/actions/workflows/autotest.yml)
[![codecov](https://codecov.io/gh/hetalang/DigiPopData.jl/graph/badge.svg?token=939QCNXCYP)](https://codecov.io/gh/hetalang/DigiPopData.jl)
[![docs-stable](https://img.shields.io/badge/docs-dev-blue?logo=githubpages)](https://hetalang.github.io/DigiPopData.jl/dev/)
[![GitHub license](https://img.shields.io/github/license/hetalang/DigiPopdata.jl.svg)](https://github.com/hetalang/DigiPopdata.jl/blob/master/LICENSE)

# DigiPopData.jl

Tools for comparing real and virtual populations in QSP using unified metrics and loss functions

## Overview

DigiPopData.jl is a Julia package for comparing individual-level simulation outputs with aggregated experimental data in Virtual Patient QSP workflows.

In practice, experimental data reported in publications are usually available only as summary statistics
(e.g. mean, median, quantiles, survival curves), while QSP models produce individual-level simulations.
DigiPopData.jl provides a unified way to bridge this gap.

The package defines metric-based representations of experimental data and computes loss functions
that quantify the mismatch between simulated individuals and reported population-level statistics.

Experimental (real population) data are provided in a unified tabular format with explicitly defined metric types.
Data can be loaded from a DataFrame or CSV file.

Virtual population data are provided as a DataFrame containing individual-level simulation results.

See the [documentation](https://hetalang.github.io/DigiPopData.jl/dev/) for more details.

## Typical use case

- define experimental target statistics using a unified metric-based data format,
- compute metric-based mismatch between simulations and reported data,
- use the loss for calibration or virtual population selection.

## Implemented metrics

Each metric compares simulated individuals with experimental data based on the following statistics:

| Julia struct | metric.type in DataFrame | BIP support | Description |
|--------------|--------------------------|------------------|-------------|
| `MeanMetric` | mean | + | Compare the mean. |
| `MeanSDMetric` | mean_sd | + |Compare the mean and standard deviation. |
| `CategoryMetric` | category | + | Compare the categorical distribution. |
| `QuantileMetric` | quantile | + | Compare the quantile values. |
| `SurvivalMetric` | survival | + | Compare the survival curves. |

**BIP support** indicates whether the metric is supported for *Binary Integer Programming* optimization, for example in [VPopMIP.jl](https://github.com/hetalang/VPopMIP.jl) package.

## Code examples

Calculation of the loss function for the `SurvivalMetric`:

```julia
using DigiPopData

# create metric based on Survival data
metric1 = SurvivalMetric(
    150,    # number of patients in the real population
    [0.8111, 0.3480, 0.2852, 0.2538, 0.2307, 0.2307, 0.1818, 0.1338], # survival values in descending order
    [2., 5., 8., 10., 12., 15., 20., 25.] # time points
)

# calculate loss function for data on metric -2ln(Likelihood)
loss_value = mismatch(
    [2., 1.4, 4.4, 6., 7.89], # individual survival times for 5 patients
    metric1
)
```

Compute the total loss between real and virtual populations defined in CSV files:

```julia
using DigiPopData
using DataFrames, CSV

# Load the real population data from CSV file
metrics_df = CSV.read("metrics.csv", DataFrame)
metrics = parse_metric_bindings(metrics_df)

# Load the virtual population data from CSV file
virtual_df = CSV.read("virtual_population.csv", DataFrame)

loss = get_loss(virtual_df, metrics)
```

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

Copyright (c) 2025-2026 Heta project
