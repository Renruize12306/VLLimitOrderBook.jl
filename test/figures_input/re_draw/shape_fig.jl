using Plots
function assing_valiables(scale, dir)
    test_shape_fig_x_file = open("$(dir)/test_shape_fig_x.txt")
    test_shape_fig_y_file = open("$(dir)/test_shape_fig_y.txt")
    
    x_vec = Vector{Any}()
    y_vec = Vector{Any}()
    cnt = 1
    curline_fig_x_vec = "@"
    while true
        curline_fig_x_vec = readline(test_shape_fig_x_file)
        curline_fig_y_vec = readline(test_shape_fig_y_file)
        if curline_fig_x_vec == ""
            break
        end
        if cnt < scale # == 0
            push!(x_vec, parse(Float64, curline_fig_x_vec))
            push!(y_vec, parse(Float64, curline_fig_y_vec))
        end
        cnt += 1
    end
    return [x_vec, y_vec]
end

dir = pwd() * "/test/fig/test_shape_fig"
result_vec = assing_valiables(1000_000, dir)

x_array = result_vec[1]
# x_array = x_array[1 : end - 1]
y_array = result_vec[2]
# y_array_sent = y_array_sent[1 : end - 1]

scatter(x_array, y_array, label="Performance", mc=:white, msc=colorant"#EF4035", legend=:best, 
bg="floralwhite", background_color_outside="white", framestyle=:box, fg_legend=:transparent, lw=3)
xlabel!("Order Book Depth", fontsize=18)
ylabel!("Processing Time (seconds)", fontsize=18)


savefig("$(dir)/pic.pdf")


# include("test/figures_input/re_draw/shape_fig.jl")