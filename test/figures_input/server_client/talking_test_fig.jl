using Plots
function assing_valiables(scale)
    num_sent_vec_file = open("test/figures_input/server_client/data/num_sent_vec.txt")
    time_sent_vec_file = open("test/figures_input/server_client/data/time_sent_vec.txt")
    time_rec_vec_file = open("test/figures_input/server_client/data/time_rec_vec.txt")
    
    num_sent_vec = Vector{Any}()
    time_sent_vec = Vector{Any}()
    time_rec_vec = Vector{Any}()
    cnt = 1
    curline_num_sent_vec = "@"
    while true
        curline_num_sent_vec = readline(num_sent_vec_file)
        curline_time_sent_vec = readline(time_sent_vec_file)
        curline_time_rec_vec = readline(time_rec_vec_file)
        if curline_time_rec_vec == ""
            break
        end
        if cnt < scale # == 0
            push!(num_sent_vec, parse(Float64, curline_num_sent_vec))
            push!(time_sent_vec, parse(Float64, curline_time_sent_vec))
            push!(time_rec_vec, parse(Float64, curline_time_rec_vec))
        end
        cnt += 1
    end
    return [num_sent_vec, time_sent_vec, time_rec_vec]
end

result_vec = assing_valiables(100)

x_array = result_vec[1]
# x_array = x_array[1 : end - 1]
y_array_sent = result_vec[2]
# y_array_sent = y_array_sent[1 : end - 1]
y_array_rec = result_vec[3]
# y_array_rec = y_array_rec[1 : end - 1]

scatter(x_array, y_array_sent, label="Latency from sending side", mc=:white, msc=colorant"#EF4035", legend=:best, 
bg="floralwhite", background_color_outside="white", framestyle=:box, fg_legend=:transparent, lw=3)
scatter!(x_array, y_array_rec, label="Latency from receiving side", mc=:white, msc=colorant"#375CD9", legend=:best, 
bg="floralwhite", background_color_outside="white", framestyle=:box, fg_legend=:transparent, lw=3)
xlabel!("Number of Orders Sent", fontsize=18)
ylabel!("Latency (nanoseconds)", fontsize=18)

savefig("test/figures_input/server_client/data/latency.png")


# include("test/figures_input/server_client/talking_test_fig.jl")