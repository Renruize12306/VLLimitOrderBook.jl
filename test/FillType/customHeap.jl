struct MyStruct
    a::Int64
    b::Int64
    c::Int64
end

struct FieldOrder
    sym::Symbol
    ord::Base.Ordering
end

struct MyStructOrdering <: Base.Ordering
    field_orderings::AbstractVector{FieldOrder}
end

function Base.lt(struct_ordering::MyStructOrdering, a, b)
    for field_ordering in struct_ordering.field_orderings
        sym = field_ordering.sym
        ord = field_ordering.ord
        va = getproperty(a, sym)
        vb = getproperty(b, sym)
        Base.lt(ord, va, vb) && return true
        Base.lt(ord, vb, va) && return false
    end
    false # a and b are equal
end

function DataStructures.compare(comp::MyStructOrdering, a, b)
    Base.lt(comp, a, b)
end

h = BinaryHeap{MyStruct,MyStructOrdering}(comparer=mystruct_ordering)


mystruct_ordering = MyStructOrdering([
    FieldOrder(:a, Base.Reverse),
    FieldOrder(:b, Base.Forward),
    FieldOrder(:c, Base.Reverse)
    ])

mystructs = collect(MyStruct(rand(-1:1, 3)...) for x=1:9)
    
sorted = sort(mystructs, order=mystruct_ordering)