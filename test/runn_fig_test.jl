begin
    arr = [
        # "validation/book_validation_benchmark.jl",
        # "test-2_time_num_limit_fig.jl",
        # "test-2_time_num_market_fig.jl",
        "stress_test_conc_20_pro_act_fig.jl",
        # "stress_test_conc_20_pro_avg_fig.jl",
        # "stress_test_conc_num_proc_fig.jl",
        ]
    for file in arr
        println("Started\t", file)
        include(file)
        println("Finished\t", file)
    end
end

# include("test/runn_fig_test.jl")