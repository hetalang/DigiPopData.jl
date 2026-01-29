## Owerview of Metrics

Each metric compares simulated individuals with experimental data based on the following statistics:

| Julia struct | metric.type in DataFrame | BIP support | Description |
|--------------|--------------------------|------------------|-------------|
| `MeanMetric` | mean | + | Compare the mean. |
| `MeanSDMetric` | mean_sd | + |Compare the mean and standard deviation. |
| `CategoryMetric` | category | + | Compare the categorical distribution. |
| `QuantileMetric` | quantile | + | Compare the quantile values. |
| `SurvivalMetric` | survival | + | Compare the survival curves. |

**BIP support** indicates whether the metric is supported for *Binary Integer Programming* optimization, for example in [VPopMIP.jl](https://github.com/hetalang/VPopMIP.jl) package.