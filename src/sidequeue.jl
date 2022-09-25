using Dates, Base, DataStructures, Sockets
import Base: >, <, ==, !=, isless, <=, >=, !
abstract type Comparable end

"""
    Priority{Sz, Px, Oid, Aid, Dt, Ip, Pt}
 
Prioirty with order-id type Oid, account-id type Aid, size type Sz, price type 
px, date-time type Dt, ip address type Ip, port number type pt.
    
A `priority` is a self-defined data structure used when the user wants to submit an limit
order but can not be matched immediately, then eveything will be stored into
a queue. As soon as the opposite order in the market engine is available, the 
order will be poped as the prioiry indicated.

"""
mutable struct Priority{Sz<:Real, Px<:Real, Oid<:Integer, Aid<:Integer, Dt<:DateTime, Ip<:String, Pt<:Integer}   <: Comparable
    size::Sz
    price::Px
    transcation_id::Oid
    account_id::Aid
    create_time::Dt
    ip_address::Ip
    port::Pt
    function Priority{Sz, Px, Oid, Aid, Dt, Ip, Pt}(
        size::Real, 
        price::Real, 
        transcation_id::Oid, 
        account_id::Aid, 
        create_time::Dt, 
        ip_address::Ip, 
        port::Pt
        )where{Sz<:Real,Px<:Real,Oid<:Integer,Aid<:Integer,Dt<:DateTime,Ip<:String,Pt<:Integer}
        new{Sz, Px, Oid, Aid, Dt, Ip, Pt}(
            Sz(size), Px(price), transcation_id, account_id, Dt(create_time), Ip(ip_address), Pt(port)
            )
    end
end

"""
    <(x::Priority, y::Priority)

The `<` operators defines the circumstances when x order in the unmatched order boook have lower 
priority than y, the user can write prioirty itself, we will use this priority `price > size 
> timestamp > order id, account id will be ignored` as a default option.

"""
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

"""
    >(x::Priority, y::Priority)

The `>` operators defines the circumstances when x order in the unmatched order boook have higher 
priority than y, the user can write prioirty itself, we will use this priority `price > size 
> timestamp > order id, account id will be ignored` as a default option.

"""
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

import Base.@kwdef

"""
    OneSideUnmatchedBook{Sz, Px, Oid, Aid, Dt, Ip, Pt}

One-Sided UnmatchedBook with order-id type Oid, account-id type Aid, size type Sz, price type 
px, date-time type Dt, ip address type Ip, port number type pt.

OneSideUnmatchedBook is a one-sided book (i.e. :BID or :ASK) of order queues at
varying prices.
    
Order queue are stored in SortedSet(.unmatched_book) indexed by Priority defined earlier

The One side unmached order book keeps tracks of various statistics such as best price for best
bid or ask price, number of orders in the book as well as total valume in the book

"""
@kwdef mutable struct OneSideUnmatchedBook{Sz<:Real, Px<:Real, Oid<:Integer, Aid<:Integer, Dt<:DateTime, Ip<:String, Pt<:Integer}
    is_bid_side::Bool
    unmatched_book::SortedSet{Priority{Sz,Px,Oid,Aid,Dt,Ip,Pt}} = SortedSet{Priority{Sz,Px,Oid,Aid,Dt,Ip,Pt}}()
    total_volume::Sz = 0 # Total volume available in shares
    num_orders::Int32 = Int32(0) # Number of orders in the book
    best_price::Union{Px,Nothing} = nothing # best bid or ask
end

isbidunmatchedbook(sub::OneSideUnmatchedBook) = !sub.is_bid_side
isaskunmatchedbook(sub::OneSideUnmatchedBook) = sub.is_bid_side
Base.isempty(sub::OneSideUnmatchedBook) = isempty(sub.unmatched_book)

"Updates the latest best price in a OneSideUnmatchedBook (either :BID or :ASK book)."
function _update_next_best_price!(sub::OneSideUnmatchedBook)
    sub.best_price = isempty(sub.unmatched_book) ? nothing : abs(first(sub.unmatched_book).price)
    return nothing
end

"""
    insert_unmatched_order!(sub::OneSideUnmatchedBook, new_order_priority::Priority)
    
    unmatched order will be processed into waiting list

    For limit order,
        
        Considering the limit order fill type is FOK, IOC, and AON(all or none), both of FOK, IOC two kinds of fill type
        will be eliminate after the limit order with certain price is submitted, so there is no need for cancel order
        As for AON, this is similiar to the FOK but it will not be eliminated when there is no appropriate market feed.

        So as for limit order, we only need to conisder the fill_in type of AON.

    For market order,

        It's said that market order will be executed immediately, so that there is no usage for market order
        "Market orders are optimal when the primary goal is to execute the trade immediately."
        https://www.schwab.com/resource-center/insights/content/3-order-types-market-limit-and-stop-orders
        "A market order is an instruction to buy or sell a security immediately at the current price."
        https://www.investopedia.com/terms/m/marketorder.asp
        "A market order is an order to buy or sell a security immediately. "
        https://www.investor.gov/introduction-investing/investing-basics/how-stock-markets-work/types-orders#:~:text=A%20market%20order%20is%20an,for%20a%20buy%20order)%20price.
        
    So, only limit order with AON fill type are being considered

Cancels Order `o`, or order with matching information from OrderBook.

Provide `acct_id` if known to guarantee correct account tracking.
"""
function insert_unmatched_order!(
    sub::OneSideUnmatchedBook{Sz, Px, Oid, Aid, Dt, Ip, Pt},
    new_order_priority::Priority{Sz, Px, Oid, Aid, Dt, Ip, Pt}
) where {Sz, Px, Oid, Aid, Dt, Ip, Pt}
    price = isaskunmatchedbook(sub) ? new_order_priority.price : -new_order_priority.price
    new_order_priority_with_bool = Priority{Sz, Px, Oid, Aid, Dt, Ip, Pt}(
        new_order_priority.size, 
        price, 
        new_order_priority.transcation_id,
        new_order_priority.account_id, 
        new_order_priority.create_time, 
        new_order_priority.ip_address,
        new_order_priority.port
        )
    push!(sub.unmatched_book,new_order_priority_with_bool)
    sub.num_orders += 1
    sub.total_volume += new_order_priority_with_bool.size
    _update_next_best_price!(sub)
    
end

@inline _is_best_price_inside_limit(::OneSideUnmatchedBook, ::Nothing) = true

@inline function _is_best_price_inside_limit(
    sub::OneSideUnmatchedBook{Sz, Px, Oid, Aid, Dt, Ip, Pt}, limit_price::Px
) where {Sz, Px, Oid, Aid, Dt, Ip, Pt}
    if isbidunmatchedbook(sub)
        return sub.best_price >= limit_price
    else
        return sub.best_price <= limit_price
    end
end

"""
    pop_unmatched_order_withinfilter!(sub::OneSideUnmatchedBook, new_order_priority::Priority)

If there is an order in the unmatched order book matched, it will pop the top order 
    with the highest given prioiry.

"""
function pop_unmatched_order_withinfilter!(
    sub::OneSideUnmatchedBook{Sz, Px, Oid, Aid, Dt, Ip, Pt},
    new_order_priority::Priority{Sz, Px, Oid, Aid, Dt, Ip, Pt}
) where {Sz, Px, Oid, Aid, Dt, Ip, Pt}
    if _is_best_price_inside_limit(sub, new_order_priority.price)
        price = isaskunmatchedbook(sub) ? new_order_priority.price : -new_order_priority.price
        new_order_priority_with_bool = Priority{Sz, Px, Oid, Aid, Dt, Ip, Pt}(
            new_order_priority.size, 
            price, 
            new_order_priority.transcation_id,
            new_order_priority.account_id, 
            new_order_priority.create_time, 
            new_order_priority.ip_address,
            new_order_priority.port
            )
        current_book = sub.unmatched_book
        res = SortedSet{Priority}()
        poped_order = 0
        poped_volume = 0
        if !isaskunmatchedbook(sub)
            for single_unmatched in current_book
                if (single_unmatched <= new_order_priority_with_bool && new_order_priority.size - single_unmatched.size >= 0)
                    price = -single_unmatched.price
                    single_unmatched_with_bool = Priority{Sz, Px, Oid, Aid, Dt, Ip, Pt}(
                        single_unmatched.size, 
                        price, 
                        single_unmatched.transcation_id,
                        single_unmatched.account_id, 
                        single_unmatched.create_time, 
                        single_unmatched.ip_address,
                        single_unmatched.port
                        )
                    push!(res, single_unmatched_with_bool)
                    new_order_priority.size -= single_unmatched.size
                    poped_order += 1
                    poped_volume += single_unmatched.size
                    st = searchsortedfirst(current_book, single_unmatched)
                    delete!((current_book, st))
                else 
                    break
                end
            end
        else
            for single_unmatched in current_book
                if (single_unmatched <= new_order_priority && new_order_priority.size - single_unmatched.size >= 0)
                    push!(res, single_unmatched)
                    new_order_priority.size -= single_unmatched.size
                    poped_order += 1
                    poped_volume += single_unmatched.size
                    st = searchsortedfirst(current_book, single_unmatched)
                    delete!((current_book, st))
                else 
                    break
                end
            end
        end
        if !(isempty(res))
            println("\n\nthis is matched order,\nthis place will perform notify \n\n")
            for re in res
                println(re)
            end
            _notify_all(res)
            println("\n\n notify done \n\n")
        end
        sub.num_orders -= poped_order
        sub.total_volume -= poped_volume
        _update_next_best_price!(sub)
    end
end

using HTTP
using VL_LimitOrderBook, Dates, Serialization

MyPriority = Priority{Int64, Float64, Int64, Int64, DateTime, String, Integer}
# Custom Serialization of a MyPriority instance
function Serialization.serialize(s::AbstractSerializer, instance::MyPriority)
    Serialization.writetag(s.io, Serialization.OBJECT_TAG)
    Serialization.serialize(s, MyPriority)
    Serialization.serialize(s, instance.size)
    Serialization.serialize(s, instance.price)
    Serialization.serialize(s, instance.transcation_id)
    Serialization.serialize(s, instance.account_id)
    Serialization.serialize(s, instance.create_time)
    Serialization.serialize(s, instance.ip_address)
    Serialization.serialize(s, instance.port)
end

"""
    _notify_all(set::SortedSet)

    This function will be used to broadcast the message as long as an order in unmatched_book matched

"""
function _notify_all(set::SortedSet)
    HTTP.WebSockets.open("ws://127.0.0.1:8081") do ws
        io = IOBuffer()
        serialize(io, set)
        s = take!(io)
        Sockets.send(ws, s)
    end
end