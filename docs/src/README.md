# README

## Run docs locally

```ps
# npm install --global nodemon http-server

julia --project=docs docs/make.jl

http-server docs/build -p 8000
```