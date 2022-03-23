#=
using Dates, Base, DataStructures
import Base: >, <, ==, !=, isless

abstract type Comparable end

mutable struct Priority{Sz<:Real, Px<:Real, Oid<:Integer, Aid<:Integer, Dt<:DateTime, Ip<:String}   <: Comparable
    size::Sz
    price::Px
    transcation_id::Oid
    account_id::Aid
    create_time::Dt
    ip_address::Ip
    function Priority{Sz, Px, Oid, Aid, Dt, Ip}(
        size::Sz, price::Px, transcation_id::Oid, account_id::Aid, create_time::Dt, ip_address::Ip
        )where{Sz, Px, Oid, Aid, Dt, Ip}
        new{Sz,Px,Oid, Aid,Dt,Ip}(
            Sz(size), Px(price), Oid(transcation_id), Aid(account_id), Dt(create_time), Ip(ip_address)
            )
    end
end
# price > size > timestamp > order id , account id will be ignored

function <(x::Priority, y::Priority) where Priority <: Comparable
    if x.price == y.price
        if x.size == y.size
            if x.create_time == y.create_time
                x.transcation_id < y.transcation_id
            else
                x.create_time < y.create_time
            end
        else
            x.size < y.size
        end
    else
        x.price < y.price
    end
end

function >(x::Priority, y::Priority) where Priority <: Comparable
    if x.price == y.price
        if x.size == y.size
            if x.create_time == y.create_time
                x.transcation_id > y.transcation_id
            else
                x.create_time > y.create_time
            end
        else
            x.size > y.size
        end
    else
        x.price > y.price
    end
end

function ==(x::Priority, y::Priority) where Priority <: Comparable
    x.price == y.price && x.create_time == y.create_time && x.size == y.size && x.transcation_id == y.transcation_id
end

function !=(x::Priority, y::Priority) where Priority <: Comparable
    x.price != y.price || x.create_time != y.create_time || x.size == y.size || x.transcation_id != y.transcation_id
end

function <=(x::Priority, y::Priority) where Priority <: Comparable
    x < y || x == y
end

function >=(x::Priority, y::Priority) where Priority <: Comparable
    x > y || x == y
end

isless(x::Priority, y::Priority) = (x < y)
=#
using Dates, Base, DataStructures
import Base: >, <, ==, !=, isless
import VL_LimitOrderBook
using VL_LimitOrderBook, Random, Dates, Test
Priority1 = Priority{Int64, Float64, Int64, Int64, DateTime, String}

using Test
p1 = Priority1(1, 10.0, 101, 0, now(),"192.168.1.1")
p2 = Priority1(1, 10.0, 102, 0, now(),"192.168.2.1")
println(p1)
println(p2)
@test p1 < p2
@test p1 != p2

p3 = Priority1(1,19.0,103, 0,now(),"192.268.1.1")
p3.price = p3.price - 1
p4 = Priority1(1,10.0,104, 0,now(),"192.268.1.1")
println(p3)
println(p4)
@test p3 > p4

p5 = Priority1(2,10.0,105, 0,now(),"192.2.1.1")
p6 = Priority1(1,10.0,106, 0,now(),"192.268.100.1")
println(p5)
println(p6)
@test p5 > p6

s = SortedSet{Priority}()
push!(s,p1)
push!(s,p2)
push!(s,p3)
push!(s,p4)
push!(s,p5)
push!(s,p6)

s1 = SortedSet{Int}()
push!(s1,0)
push!(s1,0)
push!(s1,2)
push!(s1,-2)
push!(s1,0)
push!(s1,-4)
push!(s1,6)



println("\n\nthis is a out put semitokens \n\n")
for (st,k) in semitokens(s1)
    println(st, "\t", k)
end

println("\n\nthis is a out put eachindex \n\n")

for ind in eachindex(s1)
    println(ind)
end

println("\n\nthis is a out put onlysemitokens \n\n")
for st in onlysemitokens(s1)
    println(st)
end

println("\n\naccess via semitoken\n\n")
for (st,k) in semitokens(s1)
    println(st, "\t", k)
    local tok = (s1,st)
    println(tok)
    de = deref(tok)
    println(de)
end


println("\n\naccess via searching exclusive\n\n")
firstsc = searchsortedfirst(s1, first(s1))
endsc = searchsortedfirst(s1,0)
for k in exclusive(s1,(firstsc,endsc))
    println(k)
end

println("\n\naccess via searching inclusive\n\n")
firstsc = searchsortedfirst(s1, first(s1))
endsc = searchsortedfirst(s1,0)
for k in inclusive(s1,(firstsc,endsc))
    println(k)
end

println("\n\nthis is a out put s \n\n")
for p in s
    println(p)
end

isempty(s)
println("\n\naccess via searching inclusive\n\n")

firstsc = searchsortedfirst(s1, first(s1))
endsc = searchsortedfirst(s1,1)
for k in inclusive(s1,(firstsc,endsc))
    println(k)
end

st = searchsortedfirst(s1, 0)
delete!((s1, st))
