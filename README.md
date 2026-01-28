[![CI](https://github.com/hetalang/DigiPopData.jl/actions/workflows/autotest.yml/badge.svg)](https://github.com/hetalang/DigiPopData.jl/actions/workflows/autotest.yml)
[![codecov](https://codecov.io/gh/hetalang/DigiPopData.jl/graph/badge.svg?token=939QCNXCYP)](https://codecov.io/gh/hetalang/DigiPopData.jl)
[![docs-stable](https://img.shields.io/badge/docs-dev-blue?logo=githubpages)](https://hetalang.github.io/DigiPopData.jl/dev/)
[![GitHub license](https://img.shields.io/github/license/hetalang/DigiPopdata.jl.svg)](https://github.com/hetalang/DigiPopdata.jl/blob/master/LICENSE)

# DigiPopData.jl
Data prep and visualization tools for Virtual Patient QSP modeling

## Overview

DigiPopData.jl is a Julia package designed to facilitate the preparation and visualization of data for Virtual Patient QSP (Quantitative Systems Pharmacology) modeling. It provides a set of tools and functions to streamline the process of data handling, making it easier for researchers and practitioners in the field of pharmacometrics and systems biology.

The package provides the unified table format for the real population data, divided to different metrics types. The data can be loaded from DataFrame or CSV file.

It also expect the specific format for the virtual population data, which is a DataFrame.

See the [documentation](https://hetalang.github.io/DigiPopData.jl/dev/) for more details.

## Implemented metrics

Each metric compare real and virtual populations base on the following statistics:

| Julia struct | metric.type in DataFrame | Bin optimization | Description |
|--------------|--------------------------|------------------|-------------|
| `MeanMetric` | mean | + | Compare the mean. |
| `MeanSDMetric` | mean_sd | + |Compare the mean and standard deviation. |
| `CategoryMetric` | category | + | Compare the categorical distribution. |
| `QuantileMetric` | quantile | + | Compare the quantile values. |
| `SurvivalMetric` | survival | + | Compare the survival curves. |

## Code examples

Calculation of the loss function for the `MeanMetric` metric type:

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

Get loss value for metrics and simulations from the CSV files

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
