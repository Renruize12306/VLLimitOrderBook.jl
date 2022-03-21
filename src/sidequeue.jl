
@kwder mutable struct OneSideUnmatchedBook  {Sz<:Real, Px<:Real, Oid<:Integer, Aid<:Integer, Dt<:DateTime}
    is_bid_side::Bool
    book::{MyPriority{Sz,Px,Oid,Dt}, OrderQueue{Sz,Px,Oid,Aid}} = AVLTree{MyPriority{Sz,Px,Oid,Dt}, OrderQueue{Sz,Px,Oid,Aid}}()
    total_volume::Sz = 0 # Total volume available in shares
    total_volume_funds::Float64 = 0.0 # Total volume available in underlying currency
    num_orders::Int32 = Int32(0) # Number of orders in the book
    best_price::Union{Px,Nothing} = nothing # best bid or ask
end

isbidunmatchedbook(sub::OneSideUnmatchedBook) = sub.is_bid_side
isaskunmatchedbook(sub::OneSideUnmatchedBook) = !sub.is_bid_side
Base.isempty(sub::OneSideUnmatchedBook) = isempty(sub.book)

"Compute total volume available below limit price"
function _size_available(sub::OneSideUnmatchedBook{Sz,Px,Oid,Aid,Dt}, current_priority::MyPriority) where {Sz,Px,Oid,Aid,Dt}
    t = Sz(0)
    if isbidunmatchedbook(sub)
        for q in sub.book
            (q.key >= current_priority && t < current_priority.size) ? (t += q[2].total_volume[]) : break
        end
    else
        for q in sub.book
            (q.key <= current_priority && t < current_priority.size) ? (t += q[2].total_volume[]) : break
        end
    end
    return t
end

_size_available(sub::OneSideUnmatchedBook,::Nothing) = sub.total_volume

"Updates the latest best price in a Sidebook (either :BID or :ASK book)."
function _update_next_best_price!(sub::OneSideUnmatchedBook)
    sub.best_price = isempty(sub.book) ? nothing : abs(first(sub.book)[1])
    return nothing
end


using Dates, Base
import Base: >, <, ==, !=, >=, <=

abstract type Comparable end

struct MyPriority{Sz<:Real, Px<:Real, Oid<:Integer, Dt<:DateTime}   <: Comparable
    size::Sz
    price::Px
    transcation_id::Oid
    create_time::Dt
    function MyPriority{Sz, Px, Oid, Dt}(
        size::Sz, price::Px, transcation_id::Oid, create_time::Dt
        )where{Sz, Px, Oid, Dt}
        new{Sz,Px,Oid,Dt}(
            Sz(size), Px(price), Oid(transcation_id), Dt(create_time)
            )
    end
end

function <(x::MyPriority, y::MyPriority) where MyPriority <: Comparable
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

function <=(x::MyPriority, y::MyPriority) where MyPriority <: Comparable
    x < y || x == y
end

function >(x::MyPriority, y::MyPriority) where MyPriority <: Comparable
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

function >=(x::MyPriority, y::MyPriority) where MyPriority <: Comparable
    x > y || x == y
end

function ==(x::MyPriority, y::MyPriority) where MyPriority <: Comparable
    x.price == y.price && x.create_time == y.create_time && x.size == y.size && x.transcation_id == y.transcation_id
end

function !=(x::MyPriority, y::MyPriority) where MyPriority <: Comparable
    x.price != y.price || x.create_time != y.create_time || x.size == y.size || x.transcation_id != y.transcation_id
end