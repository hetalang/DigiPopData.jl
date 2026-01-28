using Documenter, DigiPopData

makedocs(
    sitename = "DigiPopData.jl",
    authors = "Ivan Borisov, Evgeny Metelkin",
    modules = [DigiPopData],
    format = Documenter.HTML(),
    pages = [
        "Home" => "index.md",
        "API" => "api.md",
    ],
    warnonly = [:missing_docs],
    # checkdocs = :none
)

deploydocs(
    repo = "github.com/hetalang/DigiPopData.jl.git",
    devbranch = "main",
    versions = ["stable" => "v^", "v#.#.#"], 
)
