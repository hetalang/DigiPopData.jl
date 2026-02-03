# Simulation Data Format

Simulated data are provided to DigiPopData.jl as individual-level results of QSP model simulations.
They are represented as a tabular structure and are typically produced by an external simulator.

## Structure

Simulation data are expected to be loaded as a `DataFrame` with the following columns:

- `id`  
  Identifier of a virtual patient.  
  Used to distinguish individuals and for selection or weighting procedures.  
  Type: `String`, or `Int64`

- `scenario`  
  Identifier of a simulation scenario (e.g. treatment, dosing regimen, condition).  
  Allows multiple scenarios per virtual patient.  
  Type: `String`.

- `<endpoint columns>`  
  One or more columns containing simulated model outputs
  that correspond to experimental metrics
  (e.g. concentration, biomarker value, event time).  
  Column names must match the identifiers referenced by experimental metrics.
  Type: `String`, `Int64`, or `Float64`

Each row corresponds to one simulated individual under one scenario.
For a given workflow, it is typically expected that all required endpoint values are present.

## CSV file format

Simulation results can be stored and loaded from a CSV file.
This is particularly useful when simulation and analysis are performed in separate tools
or when virtual patient selection is applied to precomputed results.

Simulation data can be loaded as follows:
```julia
using CSV, DataFrames

simulation_df = CSV.File("simulation_data.csv") |> DataFrame
```

## Example

Example of a simulation table for a virtual population:

| id   | scenario | conc_t24 | conc_t48 | biomarker_t48 | response |
|------|----------|----------|----------| ------------- | -------- |
| VP1  | placebo  | 1.23     | 0.45     | 13 | NonResponder |
| VP2  | placebo  | 0.98     | 0.52     | 10 | NonResponder |
| VP3  | placebo  | 1.10     | 0.48     | 12 | NonResponder |
| VP1  | treated  | 3.42     | 0.30     | 8  | Responder |
| VP2  | treated  | 2.95     | 0.33     | 4  | NonResponder |

In this example:
- `id` identifies virtual patients,
- `scenario` distinguishes treatment conditions,
- `conc_t24`, `conc_t48`, and `biomarker_t48` are simulated numerical endpoints,
- `response` is a categorical simulated endpoint,
  that can be referenced by experimental metrics.

This table can be directly used together with experimental metric definitions to compute mismatch and loss values.
