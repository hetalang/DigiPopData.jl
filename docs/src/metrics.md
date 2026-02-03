## Overview of Metrics

Each metric compares simulated individuals with experimental data based on the following statistics:

| Julia struct | metric.type in DataFrame | specific properties | BIP support | Description |
|--------------|--------------------------|------------------|-------------|---|
| `MeanMetric` | mean | `mean`, `sd`| + | Compare the mean. |
| `MeanSDMetric` | mean_sd | `mean`, `sd` | + | Compare the mean and standard deviation. |
| `CategoryMetric` | category | `groups`, `rates` | + | Compare the categorical distribution. |
| `QuantileMetric` | quantile | `levels`, `values` | + | Compare the quantile values. |
| `SurvivalMetric` | survival | `levels`, `values` | + | Compare the survival curves. |
**BIP support** indicates whether the metric is supported for *Binary Integer Programming* optimization, for example in [VPopMIP.jl](https://github.com/hetalang/VPopMIP.jl) package.