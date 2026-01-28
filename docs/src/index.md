# DigiPopData.jl
Data prep and visualization tools for Virtual Patient QSP modeling

## Overview

DigiPopData.jl is a Julia package designed to facilitate the preparation and visualization of data for Virtual Patient QSP (Quantitative Systems Pharmacology) modeling. It provides a set of tools and functions to streamline the process of data handling, making it easier for researchers and practitioners in the field of pharmacometrics and systems biology.

The package provides the unified table format for the real population data, divided to different metrics types. The data can be loaded from DataFrame or CSV file.

It also expect the specific format for the virtual population data, which is a DataFrame.

## Implemented metrics

Each metric compare real and virtual populations base on the following statistics:

| Julia struct | metric.type in DataFrame | Bin optimization | Description |
|--------------|--------------------------|------------------|-------------|
| [`MeanMetric`](@ref) | mean | + | Compare the mean. |
| [`MeanSDMetric`](@ref) | mean_sd | + |Compare the mean and standard deviation. |
| [`CategoryMetric`](@ref) | category | + | Compare the categorical distribution. |
| [`QuantileMetric`](@ref) | quantile | + | Compare the quantile values. |
| [`SurvivalMetric`](@ref) | survival | + | Compare the survival curves. |

Copyright (c) 2025-2026 Heta project
