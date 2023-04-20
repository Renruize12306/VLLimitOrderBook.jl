using Dates
t1 = now();
sleep(1)
t2 = now();
println(t2-t1)

t = @elapsed begin
t1 = now().instant.periods.value;
sleep(1)
t2 = now().instant.periods.value;
println(t2-t1)
end


t = @elapsed begin
    t1 = Int(time_ns());
    sleep(1)
    t2 = Int(time_ns());

    println(t2-t1)
end


# 1000 milliseconds = 1 second
# include("test/figures_input/simpletest/sptest.jl")