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
            "Data Format" => "data-format.md",
            #"Loss Function" => "loss-function.md",
            #FAQ" => "faq.md",
            #"Workflows" => "workflows.md",
        ],
        "Metrics" => [
            "Overview" => "metrics.md",
            "Mean" => "mean.md",
            "MeanSD" => "mean-sd.md",
            "Category" => "category.md",
            "Quantile" => "quantile.md",
            "Survival" => "survival.md",
            #"Implementing New Metric" => "implementing-new-metric.md",
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
