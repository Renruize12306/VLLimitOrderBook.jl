abstract type Comparable end

import Base.==

function ==(a::T, b::T) where T <: Comparable
    f = fieldnames(T)
    getfield.(Ref(a),f) == getfield.(Ref(b),f)
end

struct B <: Comparable
    x
    y
end

b1 = B([1,2],[B(7,[1])]);
b2 = B([1,2],[B(7,[1])])

b1 == b2