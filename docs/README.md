## To run build locally

```julia
julia --project=docs
julia> ]
(docs) pkg> instantiate
(docs) pkg> dev .
```

## serve the built documentation locally

```ps
# npm install --global nodemon http-server

julia --project=docs docs/make.jl

http-server docs/build -p 8000
```