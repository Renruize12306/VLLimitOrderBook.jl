function write_io(file_name::String, data_vector::Vector)
    io = open(file_name, "w");
    for data in data_vector
        # println(data)
        write(io, string(data) * "\n")
    end
    close(io)
end