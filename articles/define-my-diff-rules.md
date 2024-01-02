---
title: "Juliaの自動微分のルールを決める！ 〜sqrtを例として〜"
emoji: "🔗"
type: "tech"
topics:
  - "julia"
  - "自動微分"
published: false
---

# TL;DR
自動微分のルールを決める方法を

* `ForwardDiff.jl`
* `ChainRules.jl`

の作法に従って解説します。

# はじめに
自動微分とはなにか。
→微分を自動的にいい感じに計算してくれるやつです！


`ForwardDiff`パッケージを使えば以下のように微分が計算できます！

```julia
julia> using ForwardDiff

julia> f(x) = exp(x) + x^2
f (generic function with 1 method)

julia> g(x) = exp(x) + 2x
g (generic function with 1 method)

julia> ForwardDiff.derivative(f, 2.4)
15.823176380641602

julia> g(2.4)
15.823176380641602
```

`Zygote`パッケージでは以下のように計算できます。

```julia
julia> using Zygote

julia> f(x) = exp(x) + x^2
f (generic function with 1 method)

julia> g(x) = exp(x) + 2x
g (generic function with 1 method)

julia> gradient(f, 2.4)
(15.823176380641602,)

julia> g(2.4)
15.823176380641602
```

# 微分のルール

## 三角関数の例

`sin`は多項式として定義されていますが

https://github.com/JuliaLang/julia/blob/v1.8.0/base/special/trig.jl#L54-L82

`sin`の微分を`ForwardDiff.gradient`で4回計算しても計算精度は全く落ちていません:

```julia
julia> DF(f) = x->ForwardDiff.derivative(f,x)
DF (generic function with 1 method)

julia> DF(DF(DF(DF(sin))))(0.3)
0.29552020666133955

julia> sin(0.3)
0.29552020666133955
```

有限次数の多項式近似されたものを微分しているだけなら、微分された関数は次数の落ちた多項式になっている筈で、精度も下がっていると予想されますがそうなっていません。
微分の「ルール」が定義されているためです。




Zygoteでも同様で、計算精度は落ちておらず

```julia
julia> DZ(f) = x->(gradient(f,x)[1])
DZ (generic function with 1 method)

julia> DZ(sin)(0.3)
0.955336489125606

julia> DZ(DZ(sin))(0.3)  # 2回微分で符号が反転
-0.29552020666133955

julia> DZ(DZ(DZ(DZ(sin))))(0.3)  # コンパイルが全然終わらない
```

これは...で微分のルールが


## 平方根(Newton法)の例



## 平方根(二分法)の例


# パッケージの開発状況と依存関係

* `DualNumbers.jl`
* `ChainRules.jl`
* `ForwardDiff.jl`
* `Zygote.jl`
* `ReverseDiff.jl`
* `ChainRulesCore.jl`
* `Enzyme.jl`
* `Diffractor.jl`

# まとめ




# 内部的にどうなっているのか
## 微分の連鎖律

## 自動微分のアルゴリズム
* 押し出し
* 引き戻し

# 自動微分が使えない例 (二分法で平方根)


# ルール定義 (ForwardDiff)



# ルール定義 (Zygote, ChainRules)



# 自動微分パッケージの依存関係



# 参考文献
