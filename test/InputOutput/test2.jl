#=
io = open("test.txt", "w");
a = write(io,"o",'\n')
b = write(io,"ob",'\n')
c = write(io,"obc",'\n')
close(io)
=#

io = open("log.csv", "r");
price = parse(Float64, "98.989998")
