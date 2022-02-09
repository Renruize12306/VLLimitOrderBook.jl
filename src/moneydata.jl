using FixedPointDecimals
import Base: print, show,
             convert, promote_rule, decompose,
             abs, sign, flipsign,
             round, trunc, floor, ceil,
             ==, <, <=,
             +, -, *, /,
             min, max, minmax, div, rem, divrem


struct Monetary{name,decimals} <: Real where {name<:Symbol, decimals<:Int}
    amount::FixedDecimal{BigInt,decimals}
end

"""
Get the number `d::Int` of stored digits after the decimal point.
"""
decimals(::Monetary{n,d}) where {n,d} = d

"""
Get the asset name `n::Symbol` of the monetary value.
"""
name(::Monetary{n,d}) where {n,d} = n


function Monetary(asset::Union{Symbol,String}, amount::A; decimal_digits = 18) where {A<:Union{AbstractString,Integer}}
    if typeof(asset) == Symbol
        s = asset
    else
        s = Symbol(asset)
    end

    if typeof(amount) <: AbstractString
        fd = parse(FixedDecimal{BigInt,decimal_digits}, amount)
    else
        fd = FixedDecimal{BigInt,decimal_digits}(amount)
    end

    Monetary{s,decimal_digits}(fd)
end

const M = Monetary

function show(io::IO, x::Monetary)
    asset_position    = get(io, :asset_position, :left)
    decimal_point     = get(io, :decimal_point, '.')
    thousands_point   = get(io, :thousands_point, ',')
    display_thousands = get(io, :display_thousands, false)
    digits_left       = get(io, :digits_left, -1)
    digits_right      = get(io, :digits_right, decimals(x))

    if asset_position == :left
        print(io, name(x), " ", x.amount)
    else
        print(io, x.amount, " ", name(x))
    end
end

print(io::IO, x::Monetary) = show(io, x)

struct AssetMismatch <: Exception
    base::Symbol
    counter::Symbol
end

function Base.showerror(io::IO, e::AssetMismatch)
    print(io, "Assets of different kinds: ", e.base, "/", e.counter)
end


convert(::Type{Monetary{n,d}}, x::Integer) where {n,d} = Monetary(n,x, decimal_digits=d)
convert(::Type{Monetary{n,d}}, x::String)  where {n,d} = Monetary(n,x, decimal_digits=d)

function convert(::Type{Monetary{n,d}}, x::N) where {n,d,N<:Number}
    if N <: FixedDecimal
        Monetary{n,d}(x)
    elseif N <: Monetary
        Monetary{n,d}(x.amount)
    else
        throw(InexactError(:convert,Monetary{n,d},x))
    end
end

function convert(::Type{Monetary{xn,xd}}, x::Monetary{yn,yd}) where {xn,yn,xd,yd}
    if xn != yn
        throw(AssetMismatch(xn,yn))
    end

    if xd != yd
        throw(InexactError(:convert,Monetary,x))
    end

    x
end

function promote_rule(::Type{Monetary{n,d}}, x::Type{N}) where {n,d,N<:Number}
    if N <: Union{Integer,FixedDecimal,Monetary}
        Monetary{n,d}
    else
        throw(InexactError(:convert,Monetary,x))
    end
end

function promote_rule(::Type{Monetary{n,d}}, x::Type{String}) where {n,d}
    Monetary{n,d}
end

function promote_rule(::Type{Monetary{xn,xd}},::Type{Monetary{yn,yd}}) where {xn,yn,xd,yd}
    if xn == yn
        Monetary{xn,max(xd,yd)}
    else
        # TODO: test if this makes sense
        # throw(AssetMismatch(xn,yn))
        Monetary{name,max(xd,yd)} where name
    end
end


# unary operators
abs(x::Monetary{n,d}) where {n,d} = Monetary{n,d}(abs(x.amount))
sign(x::Monetary) = sign(x.amount.i)
round(x::Monetary{n,d}, rm::RoundingMode{:Nearest}=RoundNearest) where {n,d} = Monetary{n,d}(round(x.amount, rm))
decompose(x::Monetary) = FixedPointDecimals.decompose(x.amount)
trunc(x::Monetary{n,d}) where {n,d} = Monetary{n,d}(trunc(x.amount))
floor(x::Monetary{n,d}) where {n,d} = Monetary{n,d}(floor(x.amount))
ceil(x::Monetary{n,d}) where {n,d} = Monetary{n,d}(ceil(x.amount))
+(x::Monetary{n,d}) where {n, d} = Monetary{n,d}(x.amount)
-(x::Monetary{n,d}) where {n, d} = Monetary{n,d}(-x.amount)


# binary operators
+(x::Monetary{n,d}, y::Monetary{n,d}) where {n,d} = Monetary{n,d}(x.amount + y.amount)
-(x::Monetary{n,d}, y::Monetary{n,d}) where {n,d} = Monetary{n,d}(x.amount - y.amount)
*(x::Monetary{n,d}, y::Monetary{n,d}) where {n,d} = Monetary{n,d}(x.amount * y.amount)
/(x::Monetary{n,d}, y::Monetary{n,d}) where {n,d} = Monetary{n,d}(x.amount / y.amount)

==(x::Monetary{n,d}, y::Monetary{n,d}) where {n,d} = x.amount == y.amount
 <(x::Monetary{n,d}, y::Monetary{n,d}) where {n,d} = x.amount  < y.amount
<=(x::Monetary{n,d}, y::Monetary{n,d}) where {n,d} = x.amount <= y.amount

min(x::Monetary{n,d}, y::Monetary{n,d}) where {n,d} = Monetary{n,d}(min(x.amount, y.amount))
max(x::Monetary{n,d}, y::Monetary{n,d}) where {n,d} = Monetary{n,d}(max(x.amount, y.amount))
minmax(x::Monetary{n,d}, y::Monetary{n,d}) where {n,d} = (min(x,y),max(x,y))

div(x::Monetary{n,d}, y::Monetary{n,d}) where {n,d} = Monetary{n,d}(div(x.amount, y.amount))
rem(x::Monetary{n,d}, y::Monetary{n,d}) where {n,d} = Monetary{n,d}(rem(x.amount, y.amount))
divrem(x::Monetary{n,d}, y::Monetary{n,d}) where {n,d} = (div(x,y), rem(x,y))

flipsign(x::Monetary{n,d}, y::Monetary{n,d}) where {n,d} = Monetary{n,d}(flipsign(x.amount,y.amount))

# promotion rules for n-ary operators
+(x::Monetary, y::Real) = +(promote(x,y)...)
-(x::Monetary, y::Real) = -(promote(x,y)...)
*(x::Monetary, y::Real) = *(promote(x,y)...)
/(x::Monetary, y::Real) = /(promote(x,y)...)

==(x::Monetary, y::Real) = ==(promote(x,y)...)
 <(x::Monetary, y::Real) =  <(promote(x,y)...)
<=(x::Monetary, y::Real) = <=(promote(x,y)...)

min(x::Monetary, y::Real) = min(promote(x,y)...)
max(x::Monetary, y::Real) = max(promote(x,y)...)
minmax(x::Monetary, y::Real) = minmax(promote(x,y)...)

div(x::Monetary, y::Real) = div(promote(x,y)...)
rem(x::Monetary, y::Real) = rem(promote(x,y)...)
divrem(x::Monetary, y::Real) = divrem(promote(x,y)...)

flipsign(x::Monetary, y::Real) = flipsign(promote(x,y)...)

# promotion for strings
+(x::Monetary, y::AbstractString) = +(promote(x,y)...)
-(x::Monetary, y::AbstractString) = -(promote(x,y)...)
*(x::Monetary, y::AbstractString) = *(promote(x,y)...)
/(x::Monetary, y::AbstractString) = /(promote(x,y)...)
+(x::AbstractString, y::Monetary) = +(promote(x,y)...)
-(x::AbstractString, y::Monetary) = -(promote(x,y)...)
*(x::AbstractString, y::Monetary) = *(promote(x,y)...)
/(x::AbstractString, y::Monetary) = /(promote(x,y)...)

==(x::Monetary, y::AbstractString) = ==(promote(x,y)...)
 <(x::Monetary, y::AbstractString) =  <(promote(x,y)...)
<=(x::Monetary, y::AbstractString) = <=(promote(x,y)...)
==(x::AbstractString, y::Monetary) = ==(promote(x,y)...)
 <(x::AbstractString, y::Monetary) =  <(promote(x,y)...)
<=(x::AbstractString, y::Monetary) = <=(promote(x,y)...)

min(x::Monetary, y::AbstractString) = min(promote(x,y)...)
max(x::Monetary, y::AbstractString) = max(promote(x,y)...)
minmax(x::Monetary, y::AbstractString) = minmax(promote(x,y)...)
min(x::AbstractString, y::Monetary) = min(promote(x,y)...)
max(x::AbstractString, y::Monetary) = max(promote(x,y)...)
minmax(x::AbstractString, y::Monetary) = minmax(promote(x,y)...)

div(x::Monetary, y::AbstractString) = div(promote(x,y)...)
rem(x::Monetary, y::AbstractString) = rem(promote(x,y)...)
divrem(x::Monetary, y::AbstractString) = divrem(promote(x,y)...)
div(x::AbstractString, y::Monetary) = div(promote(x,y)...)
rem(x::AbstractString, y::Monetary) = rem(promote(x,y)...)
divrem(x::AbstractString, y::Monetary) = divrem(promote(x,y)...)

flipsign(x::Monetary, y::AbstractString) = flipsign(promote(x,y)...)
