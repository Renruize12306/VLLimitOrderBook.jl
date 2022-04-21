using Serialization
import VL_LimitOrderBook
using VL_LimitOrderBook, Random, Dates, Test

Priority1 = Priority{Int64, Float64, Int64, Int64, DateTime, String, Integer}

# Custom Serialization of a Priority1 instance
function Serialization.serialize(s::AbstractSerializer, instance::Priority1)
    Serialization.writetag(s.io, Serialization.OBJECT_TAG)
    Serialization.serialize(s, Priority1)
    Serialization.serialize(s, instance.size)
    Serialization.serialize(s, instance.price)
    Serialization.serialize(s, instance.transcation_id)
    Serialization.serialize(s, instance.account_id)
    Serialization.serialize(s, instance.create_time)
    Serialization.serialize(s, instance.ip_address)
    Serialization.serialize(s, instance.port)
end

# Custom Deserialization of a Priority1 instance
function Serialization.deserialize(s::AbstractSerializer, ::Type{Priority1})
    size = Serialization.deserialize(s)
    price = Serialization.deserialize(s)
    transcation_id = Serialization.deserialize(s)
    account_id = Serialization.deserialize(s)
    create_time = Serialization.deserialize(s)
    ip_address = Serialization.deserialize(s)
    port = Serialization.deserialize(s)
    Priority1(size,price,transcation_id,account_id,create_time,ip_address,port)
end

Priority1 = Priority{Int64, Float64, Int64, Int64, DateTime, String, Integer}
p2 = Priority1(2, 10.0, 101, 0, now(),"192.168.1.1", 8088)

# Serialization
write_iob = IOBuffer()
serialize(write_iob, p2)
seekstart(write_iob)
content = read(write_iob)
println(typeof(content))
# Deserialization
read_iob = IOBuffer(content)
p1 = deserialize(read_iob)

@show p2
@show p1