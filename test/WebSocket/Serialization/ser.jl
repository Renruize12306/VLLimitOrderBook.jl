using Serialization

# The target struct
struct Foo
    x::Int
    y::String #we do not want to serialize this field
end

# Custom Serialization of a Foo instance
function Serialization.serialize(s::AbstractSerializer, instance::Foo)
    Serialization.writetag(s.io, Serialization.OBJECT_TAG)
    Serialization.serialize(s, Foo)
    Serialization.serialize(s, instance.x)
    Serialization.serialize(s, instance.y)
end

# Custom Deserialization of a Foo instance
function Serialization.deserialize(s::AbstractSerializer, ::Type{Foo})
    x = Serialization.deserialize(s)
    y = Serialization.deserialize(s)
    Foo(x,y)
end

foo1 = Foo(1,"hello")

# Serialization
write_iob = IOBuffer()
serialize(write_iob, foo1)
seekstart(write_iob)
content = read(write_iob)

# Deserialization
read_iob = IOBuffer(content)
foo2 = deserialize(read_iob)

@show foo1
@show foo2

str1 = "hello string"
# Serialization
write_iob = IOBuffer()
serialize(write_iob, str1)
seekstart(write_iob)
content = read(write_iob)

# Deserialization
read_iob = IOBuffer(content)
str2 = deserialize(read_iob)
@show str1
@show str2
println(string(str2))