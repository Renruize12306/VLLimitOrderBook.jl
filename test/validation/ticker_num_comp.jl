function check_date(str::String)
    for c in str
        if isdigit(c) || c == '/'
            
        else
            return false
        end
    end
    return true
end

function check_size(str::String)
    for c in str
        if !isdigit(c)
            return false
        end
    end
    return true
end
function validation(mp1::Dict{String, Any}, mp2::Dict{String, Any}, mp3::Dict{String, Any})
    ans = "test/validation/diff.txt"
    io_ans = open(ans, "w")
    write(io_ans, "==============Stock_Locate_Codes With different Tickers in different Venue=======================\n")
    write(io_ans, "We could use the size to locate the file.\n")
    write(io_ans, "If two file at the same date in different venue have different sizes, \n")
    write(io_ans, "this means there will be different tickers in those venues\n\n")
    for (key, value) in mp1
        if haskey(mp2, key) && value != get(mp2, key, "default")
            println("date_ndq\t", key, "\tfile_size_ndq\t", value)
            println("date__bx\t", key, "\tfile_size_bx\t", get(mp2, key, "default"),"\n")
            
            write(io_ans, "date_ndq\t"* key* "\tfile_size_ndq\t"* value*"\n")
            write(io_ans, "date__bx\t"* key* "\tfile_size_bx\t"* string(get(mp2, key, "default"))*"\n")
            # return false;
        end
        if haskey(mp3, key) && value != get(mp3, key, "default")
            println("date_ndq\t", key, "\tfile_size_ndq\t", value)
            println("date_psx\t", key, "\tfile_size_psx\t", get(mp3, key, "default"),"\n")

            write(io_ans, "date_ndq\t"* key* "\tfile_size_ndq\t"* value*"\n")
            write(io_ans,"date_psx\t"* key* "\tfile_size_psx\t"* string(get(mp3, key, "default"))*"\n")
            
            # return false;
        end
        
    end

    close(io_ans)

    return true
end
function f()
    try 
    msg = "test/validation/size.txt"
    ans = "test/validation/res.txt"
    io_msg = open(msg, "r")
    io_ans = open(ans, "w")
    map_bx = Dict{String, Any}()
    map_ndq = Dict{String, Any}()
    map_psx = Dict{String, Any}()
    while !eof(io_msg)
        str = readline(io_msg)
        str = replace(str, "<br>"=> " ")
        arr = split(str, r"\s+")


        if occursin("bx", str)
            if occursin("%", str)
                map_bx[string(arr[4])] = string(arr[7])
            else
                map_bx[string(arr[3])] = string(arr[6])
            end
        elseif occursin("ndq", str)
            # map_ndq[string(arr[3])] = string(arr[6])
            if occursin("%", str)
                map_ndq[string(arr[4])] = string(arr[7])
            else
                map_ndq[string(arr[3])] = string(arr[6])
            end
        elseif occursin("psx", str)
            # map_psx[string(arr[3])] = string(arr[6])
            if occursin("%", str)
                map_psx[string(arr[4])] = string(arr[7])
            else
                map_psx[string(arr[3])] = string(arr[6])
            end
        end
        if occursin("%", str)
            key = string(arr[4])
            val = string(arr[7])
            if check_date(key) && check_size(val)
                write(io_ans, "Date:\t"*key*"\tValue:\t"*val*"\n")
            else
                error("check_date(key) && check_size(val) is false")
            end
            
        else
            key = string(arr[3])
            val = string(arr[6])
            if check_date(key) && check_size(val)
                write(io_ans, "Date:\t"*key*"\tValue:\t"*val*"\n")
            else
                error("check_date(key) && check_size(val) is false")
            end
            
        end
        
    end
        close(io_ans)
        close(io_msg)
        return map_bx, map_ndq, map_psx, length(map_bx), length(map_ndq), length(map_psx)
    catch ex
        println(ex)
    end
end

map_bx, map_ndq, map_psx, len_bx, len_ndq, len_psx = f()
println("len_bx\t", len_bx)
println("len_ndq\t", len_ndq)
println("len_psx\t", len_psx)



flag = validation(map_ndq, map_bx, map_psx)

println(flag)