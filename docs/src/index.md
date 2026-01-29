# Key Concepts

[DigiPopData.jl](https://github.com/hetalang/DigiPopData.jl) is an Julia package for comparing individual-level simulation outputs with aggregated experimental data in Virtual Patient QSP workflows.

In practice, experimental data reported in publications are usually available only as summary statistics
(e.g. mean, median, quantiles, survival curves), while QSP models produce individual-level simulations.
DigiPopData.jl provides a unified way to bridge this gap.

The package defines metric-based representations of experimental data and computes loss functions
that quantify the mismatch between simulated individuals and reported population-level statistics.

Experimental (real population) data are provided in a unified tabular format with explicitly defined metric types.
Data can be loaded from a DataFrame or CSV file.

Virtual population data are provided as a DataFrame containing individual-level simulation results.

## Typical use case

- define experimental target statistics using a unified metric-based data format,
- compute metric-based mismatch between simulations and reported data,
- use the loss for calibration or virtual population selection.

## License

This project is licensed under the MIT License. See the [LICENSE](https://github.com/hetalang/DigiPopData.jl/blob/main/LICENSE) file for details.

Copyright (c) 2025-2026 Heta project
