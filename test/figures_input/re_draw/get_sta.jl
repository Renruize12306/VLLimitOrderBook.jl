
using Plots
function assing_valiables(scale, dir)
    test_shape_fig_x_file = open("$(dir)/test_insertion_x.txt")
    test_shape_fig_y_file = open("$(dir)/test_insertion_y.txt")
    
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

dir = pwd() * "/test/fig/thesis_fig/test_insertion20_200_linux"
result_vec = assing_valiables(1000_000, dir)

vec = result_vec[2]
MEAN_VALUE = sum(vec) / length(vec)
MAX_VALUE = maximum(vec)
MIN_VALUE = minimum(vec)

function my_std(samples)
    samples_mean = sum(vec) / length(vec)
    samples_size = length(samples)
    samples = map(x -> (x - samples_mean)^2, samples)
    samples_sum = sum(samples)
    samples_std = sqrt(samples_sum / (samples_size - 1))
    return samples_std
end
STD_VALUE = my_std(vec)

# include("test/figures_input/re_draw/get_sta.jl")