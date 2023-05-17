begin
    arr = [
        "utility.jl",
        # "test_insertion.jl",
        # "test_shape_fig.jl",
        # "test_limit_fill_fig.jl",
        "test_model_cmp.jl",
        # "test_market_fill_fig.jl",
        # "stress_test_conc_20_pro_fig.jl",
        # "stress_test_conc_num_proc_fig.jl",
        # "../validation/book_validation_price_visualization.jl",
        ]
    for file in arr
        println("Started\t", file)
        include(file)
        println("Finished\t", file)
    end
end

# include("test/performance_evaluation/runnning_fig_test.jl")