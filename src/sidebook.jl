using AVLTrees
"""
    OneSidedBook{Sz,Px,Oid,Aid}

One-Sided book with order-id type Oid, account-id type Aid,
size type Sz and price type Px.

OneSidedBook is a one-sided book (i.e. :BID or :ASK) of order queues at
varying prices.

OrderQueues are stored in an AVLTree (.book) indexed
either by price (ASK side) or -price (BID side)

The book keeps track of various statistics such as the current best price,
total share and price volume, as well as total contained number of orders.

"""
@kwdef mutable struct OneSidedBook{Sz<:Real,Px<:Real,Oid<:Integer,Aid<:Any}
    is_bid_side::Bool
    book::AVLTree{Px,OrderQueue{Sz,Px,Oid,Aid}} = AVLTree{Px,OrderQueue{Sz,Px,Oid,Aid}}()
    total_volume::Sz = 0 # Total volume available in shares
    total_volume_funds::Float64 = 0.0 # Total volume available in underlying currency
    num_orders::Int32 = Int32(0) # Number of orders in the book
    best_price::Union{Px,Nothing} = nothing # best bid or ask
end

isbidbook(sb::OneSidedBook) = sb.is_bid_side
isaskbook(sb::OneSidedBook) = !sb.is_bid_side
Base.isempty(sb::OneSidedBook) = isempty(sb.book)


"Compute total volume available below limit price"
_size_available(sb::OneSidedBook,::Nothing) = sb.total_volume

"Compute currency volume available below limit price"
_funds_available(sb::OneSidedBook,::Nothing) = sb.total_volume_funds

"Updates the latest best price in a Sidebook (either :BID or :ASK book)."
function _update_next_best_price!(sb::OneSidedBook)
    sb.best_price = isempty(sb.book) ? nothing : abs(first(sb.book)[1])
    return nothing
end

"Retrieve order queue from OneSidedBook at given price"
function _get_price_queue(
    sb::OneSidedBook{<:Real,Px,<:Integer,<:Any}, price::Px
) where {Px}
    pricekey = isaskbook(sb) ? price : -price
    return AVLTrees.findkey(sb.book, pricekey) # Return the price queue
end

"Delete entire queue associated with given price from OneSidedBook and track stats"
function _popat_queue!(
    sb::OneSidedBook{Sz,Px,Oid,Aid}, price::Px
) where {Sz,Px,Oid,Aid}
    pricekey = isaskbook(sb) ? price : -price
    price_queue = pop!(sb.book, pricekey) # delete price queue
    # update book stats
    (price_queue.price == sb.best_price) && _update_next_best_price!(sb) # Update price only if best price was changed
    sb.num_orders -= price_queue.num_orders[]
    sb.total_volume -= price_queue.total_volume[]
    sb.total_volume_funds -= Float64(price_queue.total_volume[]*price_queue.price)
    return price_queue
end

"Pop first queue and track stats"
function _popfirst_queue!(
    sb::OneSidedBook{Sz,Px,Oid,Aid}
) where {Sz,Px,Oid,Aid}
    price_queue = popfirst!(sb.book) # pop price queue at best price
    # update book stats
    _update_next_best_price!(sb) # Update best price
    sb.num_orders -= price_queue.num_orders[]
    sb.total_volume -= price_queue.total_volume[]
    sb.total_volume_funds -= Float64(price_queue.total_volume[]*price_queue.price)
    return price_queue
end


"Insert entire price queue into OneSidedBook and track stats"
function _insert_queue!(
    sb::OneSidedBook{Sz,Px,Oid,Aid},
    price_queue::OrderQueue
) where {Sz,Px,Oid,Aid}
    pricekey = isaskbook(sb) ? price_queue.price : -price_queue.price
    insert!(sb.book,pricekey,price_queue)
    # update book stats
    (isnothing(sb.best_price) || (price_queue.price === sb.best_price)) && _update_next_best_price!(sb) # Update price only if best price was changed
    sb.num_orders += price_queue.num_orders[]
    sb.total_volume += price_queue.total_volume[]
    sb.total_volume_funds += Float64(price_queue.total_volume[]*price_queue.price)
    return nothing
end


"Insert new_order into OneSidedBook at given price, create new price queue if needed"
function insert_order!(
    sb::OneSidedBook{Sz,Px,Oid,Aid}, new_order::Order{Sz,Px,Oid,Aid}
) where {Sz,Px,Oid,Aid}
    pricekey = isaskbook(sb) ? new_order.price : -new_order.price
    # search for order queue at price
    order_queue = AVLTrees.findkey(sb.book, pricekey)
    if isnothing(order_queue) # If key not present (price doesnt exist in book)
        new_queue = OrderQueue{Sz,Px,Oid,Aid}(new_order.price) # Create new price queue
        push!(new_queue, new_order) # Add order to new price queue
        insert!(sb.book, pricekey, new_queue) # add new price queue to OneSidedBook
        # Update new best price depending on bid/ask
        if isnothing(sb.best_price)
            sb.best_price = new_order.price
        elseif isbidbook(sb)
            sb.best_price = max(new_order.price, sb.best_price)
        else
            sb.best_price = min(new_order.price, sb.best_price)
        end
    else # If order queue present, retrieve queue and insert new order
        push!(order_queue, new_order)
    end

    # Update Onesidedbook info
    sb.num_orders += 1
    sb.total_volume += new_order.size
    sb.total_volume_funds += Float64(new_order.price*new_order.size)
    return nothing
end

# "Bulk insert orders into `OneSidedBook`"
# function insert_order!(
#     sb::OneSidedBook{Sz,Px,Oid,Aid}, new_orders::AbstractVector{Order{Sz,Px,Oid,Aid}}
# ) where {Sz,Px,Oid,Aid}
#     for ord in new_orders
#         insert_order!(sb, ord)
#     end
#     return nothing
# end

"Delete order with given price/tick_id from book"
function pop_order!(
    sb::OneSidedBook{Sz,Px,Oid,Aid}, price::Px, orderid::Oid
) where {Oid,Aid,Sz<:Real,Px<:Real}
    # Get price queue and delete order from it
    order_queue = _get_price_queue(sb, price)
    if !isnothing(order_queue)
        Δvolm = order_queue.total_volume[] # get stats before deletion
        ord = popat_orderid!(order_queue, orderid)
        Δvolm -= order_queue.total_volume[] # get stats after deletion
        
        # If order deletion depleted price queue, delete the whole queue
        if isempty(order_queue)
            _popat_queue!(sb, price) # note: this function will update price
        end

        if !isnothing(ord)
            # Update Onesidedbook info
            sb.num_orders -= 1
            sb.total_volume -= Δvolm
            sb.total_volume_funds -= Float64(Δvolm*price)
        end

        return ord # return popped order, is nothing if no order found
    else
        return nothing
    end
end

function pop_order_with_size!(
    sb::OneSidedBook{Sz,Px,Oid,Aid}, price::Px, orderid::Oid, size::Sz
) where {Oid,Aid,Sz<:Real,Px<:Real}
    # Get price queue and delete order from it
    order_queue = _get_price_queue(sb, price)
    if !isnothing(order_queue)
        Δvolm = order_queue.total_volume[] # get stats before deletion
        # ord = popat_orderid!(order_queue, orderid)
        ret_ind = findfirst(order_id_match(orderid), order_queue.queue)
        order_queue.queue[ret_ind].size -= size
        order_queue.total_volume[] -= size # get stats after deletion
        

        if size > 0
            sb.total_volume -= Δvolm
            sb.total_volume_funds -= Float64(Δvolm*price)
        end

        if order_queue.queue[ret_ind].size == 0
            deleteat!(order_queue.queue, ret_ind)
        end       
         # If order deletion depleted price queue, delete the whole queue
        if isempty(order_queue)
            _popat_queue!(sb, price) # note: this function will update price
        end

        return size # return popped order, is nothing if no order found
    else
        return nothing
    end
end


function check_order_with_id_and_price!(
    sb::OneSidedBook{Sz,Px,Oid,Aid}, price::Px, orderid::Oid
) where {Oid,Aid,Sz<:Real,Px<:Real}
    order_queue = _get_price_queue(sb, price)
    if !isnothing(order_queue)
        ret_ind = findfirst(order_id_match(orderid), order_queue.queue)
        return ret_ind
    else
        return nothing
    end
end

function raise_sidebook_priorty_via_display_property!(
    sb::OneSidedBook{Sz,Px,Oid,Aid}, price::Px, orderid::Oid, displayable::Bool
)where {Oid,Aid,Sz<:Real,Px<:Real}
    order_queue = _get_price_queue(sb, price)
    if !isnothing(order_queue)
        ret_ind = findfirst(order_id_match(orderid), order_queue.queue)
        if isnothing(ret_ind)
            return 0
        else
            for ind_to_modify in 1 : (ret_ind - 1)
                # fill_mode is now a static variable, we need to assign to each order
                order_queue.queue[ind_to_modify].display = displayable
            end
            return (ret_ind - 1)
        end
    else
        return 0
    end
end

function reduce_sidebook_priorty_via_display_property!(
    sb::OneSidedBook{Sz,Px,Oid,Aid}, price::Px, orderid::Oid, displayable::Bool
)where {Oid,Aid,Sz<:Real,Px<:Real}
    order_queue = _get_price_queue(sb, price)
    if !isnothing(order_queue)
        ret_ind = findfirst(order_id_match(orderid), order_queue.queue)
        if isnothing(ret_ind)
            return 0
        else
            order_queue.queue[ret_ind].display = displayable
            return 1
        end
    else
        return 0
    end
end
function elevate_sidebook_priority!(
    sb::OneSidedBook{Sz,Px,Oid,Aid}, price::Px, checked_id::Int,
)where {Oid,Aid,Sz<:Real,Px<:Real}
    order_queue = _get_price_queue(sb, price)
    if !isnothing(order_queue)
        return !order_queue.queue[checked_id].display
    else
        return true
    end
end