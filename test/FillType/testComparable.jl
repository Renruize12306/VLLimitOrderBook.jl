using Dates, Base
import Base: >, <, ==, !=

abstract type Comparable end

struct Priority{Sz<:Real, Px<:Real, Oid<:Integer, Dt<:DateTime, Ip<:String}   <: Comparable
    size::Sz
    price::Px
    transcation_id::Oid
    create_time::Dt
    ip_address::Ip
    function Priority{Sz, Px, Oid, Dt, Ip}(
        size::Sz, price::Px, transcation_id::Oid, create_time::Dt, ip_address::Ip
        )where{Sz, Px, Oid, Dt, Ip}
        new{Sz,Px,Oid,Dt,Ip}(
            Sz(size), Px(price), Oid(transcation_id), Dt(create_time), Ip(ip_address)
            )
    end
end

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
Priority1 = Priority{Int64, Float64, Int64, DateTime, String}

using Test
p1 = Priority1(1, 10.0, 100, now(),"192.168.1.1")
p2 = Priority1(1, 10.0, 100, now(),"192.168.2.1")
println(p1)
println(p2)
@test p1 < p2
@test p1 != p2



prize1 = Priority1(1,19.0,100,now(),"192.268.1.1")
prize2 = Priority1(1,10.0,100,now(),"192.268.1.1")
println(prize1)
println(prize2)
@test prize1 > prize2



prize3 = Priority1(2,10.0,100,now(),"192.2.1.1")
prize4 = Priority1(1,10.0,100,now(),"192.268.100.1")
println(prize3)
println(prize4)
@test prize3 > prize4



using DataStructures
s1 = SortedSet{Int}()
push!(s1,0)
push!(s1,0)

import Base: isless
isless(x::Priority, y::Priority) = (x < y)

s = SortedSet{Priority}()
push!(s,p1)
push!(s,p2)
push!(s,prize3)
push!(s,prize4)
push!(s,prize1)
push!(s,prize2)
