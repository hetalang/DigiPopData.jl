using Documenter, DigiPopData

makedocs(
    sitename = "DigiPopData.jl",
    authors = "Ivan Borisov, Evgeny Metelkin",
    modules = [DigiPopData],
    format = Documenter.HTML(),
    pages = [
        "Home" => [
            "README" => "index.md",
            "Key Concepts" => "key-concepts.md",
            "Getting Started" => "getting-started.md",
            "Simulation Data Format" => "simulation-data-format.md",
            "Metric Data Format" => "metric-data-format.md",
            #"Loss Function" => "loss-function.md",
            #"FAQ" => "faq.md",
        ],
        "Metrics" => [
            "Overview" => "metrics.md",
            "Mean" => "mean.md",
            "MeanSD" => "mean-sd.md",
            "Category" => "category.md",
            "Quantile" => "quantile.md",
            "Survival" => "survival.md",
            #"New Metric" => "new-metric.md",
            #"New Loss Function" => "new-loss-function.md",
        ],
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
