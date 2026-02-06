# Key Concepts

## The core mismatch problem

In practice, experimental data reported in publications are usually available only as **aggregated summary statistics**
(e.g. mean, median, quantiles, survival curves), while QSP models naturally produce **individual-level simulations**.
DigiPopData.jl provides a structured way to bridge this mismatch.

In many modeling workflows, models are calibrated against mean values, effectively treating the system as deterministic.
This approach ignores inter-individual variability and is often insufficient when modeling heterogeneous patient populations,
where the distribution of outcomes is clinically and mechanistically relevant.

When individual patient data are available, established approaches such as **NLME modeling** or **distribution-based statistical tests** (e.g. Kolmogorov–Smirnov) can be used to compare simulations and observations.
However, in many realistic scenarios **individual-level** experimental data are not accessible, and only **population-level** summary statistics are reported.

In this setting, there is no standard representation of experimental targets, and no unified way to define a statistically
meaningful **mismatch between individual simulations and aggregated data**.
As a result, comparison rules and loss functions are often implemented in an ad hoc manner, making results difficult to reproduce, justify, and compare across studies.

This problem is particularly relevant in **QSP modeling and virtual patient workflows**, where individual simulations must be evaluated against published population-level endpoints.

## Objectives of DigiPopData.jl

DigiPopData.jl is designed to provide a consistent and reusable framework for comparing individual-level simulations with aggregated experimental data.

**The main objectives of the package are:**

1. **Unified representation of experimental summary data.** Provide a general and extensible format for representing experimental data with variability at the population level. Experimental and simulation data are stored in structured formats and can be provided as tables (e.g. `DataFrame` or `CSV`), enabling reproducible and tool-independent workflows. Users may select existing metric types or define custom ones when needed.

2. **Statistically grounded loss functions.** Define Objective Function Values (OFV) that compare individual-level simulation outputs with aggregated experimental statistics. These loss functions are designed to be statistically interpretable and suitable for use in calibration, model comparison, and virtual population workflows.

3. **Reusable metric objects independent of downstream methods.** Provide metric objects that encapsulate experimental targets and comparison rules, allowing them to be reused across different methodologies, such as parameter optimization, virtual population selection, or weighting approaches.

_Currently, DigiPopData.jl focuses on **population-level** representations of experimental data.
Support for **individual-level** experimental data may be added in the future to enable more complete use of available information._

## Objects and data flow

At a high level, DigiPopData.jl can be understood as a sequence of well-defined data transformation and evaluation steps.

The workflow starts with the collection of experimental data that reflect variability in a patient population for selected endpoints (e.g. plasma drug concentration, biomarkers, clinical outcomes).
In most practical cases, such data are reported as aggregated summary statistics (mean values, medians, quantiles, survival curves, etc.).
Each of these statistics can be conceptually linked to model outputs, defining population-level targets that the QSP model should reproduce at the individual level.

Experimental data are decomposed into experimental metrics, where each metric represents a single aggregated statistic (e.g. mean concentration at a specific time point, a survival curve, or a quantile value).
Each metric is encoded as one row in a tabular format.
The table specifies the metric type, its parameters (statistic value, dispersion measures when available), and references to the corresponding model outputs to be used for comparison (e.g. a column representing plasma concentration at a given time point).

During data loading, the metric table is processed using `parse_metric_bindings`.
Each row is converted into a `MetricBinding` object, which combines a concrete `AbstractMetric` instance with references to the model output variables used for comparison.
A `MetricBinding` therefore establishes an explicit link between an experimental metric and simulated individual-level data.

The resulting collection, `Vector{MetricBinding}`, represents the complete set of experimental targets and can be reused across different analyses.
It serves as the primary input for loss computation between simulated individuals and experimental data.

In parallel, the user generates individual-level simulations of a QSP model for a virtual patient population.
Simulation results are stored in a tabular format in `CSV` file which then can be loaded into a table-like structure `DataFrame`, where each row corresponds to one virtual individual and columns contain model outputs such as concentrations, biomarkers, or event times.
Depending on the task (e.g. parameter calibration, virtual population selection, or model comparison), these simulation results can be combined with the metric bindings to evaluate model performance.

A standard entry point is the `get_loss` function, which takes a `Vector{MetricBinding}` and a table of individual simulations
and returns a scalar loss value representing the overall mismatch.

For finer-grained control, metric-level methods such as `mismatch` and `add_mismatch_expression!` allow evaluation of individual metrics independently.
Users may also implement custom analysis or optimization procedures that operate directly on `MetricBinding` objects and individual simulation data.

## Typical use case

- **Model calibration to summary endpoints**
    Define experimental target statistics (means, quantiles, survival curves, category proportions) using a unified metric-based data format, and compute statistically grounded mismatch between individual simulations and reported population-level data.

- **Virtual population selection and weighting**
    Evaluate large sets of simulated individuals against experimental metrics and use the resulting loss values to select or weight virtual patients so that the virtual population reproduces observed population variability.

- **Comparison of model variants or assumptions**
    Apply the same set of experimental metrics to different model versions, parameterizations, or simulation scenarios, and compare their ability to reproduce published summary statistics in a consistent way.

-  **Reusable experimental target definitions**
    Store experimental metrics in a structured, tool-independent format that can be reused across multiple studies, models, or optimization methods.

## Scope and non-goals

- DigiPopData.jl **does not implement QSP models** or simulation engines. It assumes that individual-level simulation results are generated externally.

- The package **does not provide optimization algorithms** or virtual population selection methods. Instead, it is designed to be used as a building block within external calibration, optimization, or selection workflows.

- The package **does not attempt to reconstruct individual-level experimental data from aggregated summary statistics**, as such reconstruction is fundamentally ill-posed and non-identifiable.
