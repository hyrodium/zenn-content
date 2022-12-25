

@generated function bsplinebasisall(P::AbstractBSplineSpace{p}, i::Integer, t::Real) where p
    bs = [Symbol(:b,i) for i in 1:p]
    Bs = [Symbol(:B,i) for i in 1:p+1]
    K1s = [:((k[i+$(p+j)]-t)/(k[i+$(p+j)]-k[i+$(j)])) for j in 1:p]
    K2s = [:((t-k[i+$(j)])/(k[i+$(p+j)]-k[i+$(j)])) for j in 1:p]
    b = Expr(:tuple, bs...)
    B = Expr(:tuple, Bs...)
    exs = [:($(Bs[j+1]) = ($(K1s[j+1])*$(bs[j+1]) + $(K2s[j])*$(bs[j]))) for j in 1:p-1]
    Expr(:block,
        :($(Expr(:meta, :inline))),
        :(k = knotvector(P)),
        :($b = bsplinebasisall(_lower(P),i+1,t)),
        :($(Bs[1]) = $(K1s[1])*$(bs[1])),
        exs...,
        :($(Bs[p+1]) = $(K2s[p])*$(bs[p])),
        :(return SVector($(B)))
    )
end

p = 4
bs = [Symbol(:b,i) for i in 1:p]
Bs = [Symbol(:B,i) for i in 1:p+1]
K1s = [:((k[i+$(p+j)]-t)/(k[i+$(p+j)]-k[i+$(j)])) for j in 1:p]
K2s = [:((t-k[i+$(j)])/(k[i+$(p+j)]-k[i+$(j)])) for j in 1:p]
b = Expr(:tuple, bs...)
B = Expr(:tuple, Bs...)
exs = [:($(Bs[j+1]) = ($(K1s[j+1])*$(bs[j+1]) + $(K2s[j])*$(bs[j]))) for j in 1:p-1]
Expr(:block,
    :($(Expr(:meta, :inline))),
    :(k = knotvector(P)),
    :($b = bsplinebasisall(_lower(P),i+1,t)),
    :($(Bs[1]) = $(K1s[1])*$(bs[1])),
    exs...,
    :($(Bs[p+1]) = $(K2s[p])*$(bs[p])),
    :(return SVector($(B)))
)

using BasicBSpline
using Plots

k = KnotVector([0.0, 0.5, 1.5, 2.5, 3.5, 5.5, 8.0, 9.0, 9.5, 10.0])
P = BSplineSpace{3}(k)
plot(P, label="B-spline基底関数")
plot!(t->sum(bsplinebasis(P,i,t) for i in 1:dim(P)), 0, 10, label="基底関数の和", color=:black)
scatter!(k.vector, zero(k.vector), label="ノット列", color=:orange)
