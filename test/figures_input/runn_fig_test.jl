begin
    arr = [
        "utility.jl",
        "test_insertion.jl",
        # "test_shape_fig.jl",
        # "test-2_time_num_limit_fig.jl",
        # "test-2_time_num_market_fig.jl",
        # "stress_test_conc_20_pro_fig.jl",
        # "stress_test_conc_num_proc_fig.jl",
        # "../validation/book_validation_visualization.jl",
        ]
    for file in arr
        println("Started\t", file)
        include(file)
        println("Finished\t", file)
    end
end

# include("test/figures_input/runn_fig_test.jl")