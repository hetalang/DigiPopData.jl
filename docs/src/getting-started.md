# Getting Started

This document provides a brief overview of how to get started with the DigiPopData.jl package. It covers installation, basic usage, and examples of implemented metrics for comparing simulated populations with experimental data.

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