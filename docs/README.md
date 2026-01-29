## To run build locally

```julia
julia --project=docs
julia> ]
(docs) pkg> instantiate
(docs) pkg> dev .
```

After each change to the documentation source files, run:

```julia
include("docs/make.jl")
```
