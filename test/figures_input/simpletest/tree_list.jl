using AVLTrees:AVLSet
using BenchmarkTools

function group()
    vec = Vector{Int}()
    
    running_time_vec_normal = @elapsed begin
        for i in 1 : 1_000_000
            push!(vec, i)
        end        
    end
    vec = Vector{Int}()
    running_time_vec_ben = @btime begin
        for i in 1 : 1_000_000
            push!(vec, i)
        end        
    end
    avl = AVLSet{Int}()
    running_time_tree_normal = @elapsed begin
        for i in 1 : 1_000_000
            push!(avl, i)
        end        
    end
    avl = AVLSet{Int}()
    running_time_tree_ben = @btime begin
        for i in 1 : 1_000_000
            push!(avl, i)
        end        
    end
    return [
        running_time_vec_normal, 
        running_time_vec_ben,
        running_time_tree_normal,
        running_time_tree_ben,
        ]
end

array_res_vector = Vector{Any}()
for cnt in 1 : 5
    # local input = 1 : 4
    res_sing = group()
    push!(array_res_vector, res_sing)
end
array_res = sum(array_res_vector) / length(array_res_vector)


# include("test/figures_input/simpletest/tree_list.jl")