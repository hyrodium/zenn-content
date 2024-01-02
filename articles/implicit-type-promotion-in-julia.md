---
title: "Juliaの暗黙の型変換を制御する"
emoji: "🍣"
type: "tech"
topics:
  - "julia"
published: false
---

# TL;DR
* Juliaでは整数・浮動小数点数・有理数の間の型変換が自動で行われる
* 型変換は便利だが、ときに牙を剥く
* `Base`の関数を上書きして意図しない処理を検知できる


# はじめに
Juliaでは以下のように整数と浮動小数点数、有理数と整数のような演算がサポートされています。

```julia
julia> 1.0 + 3  ## 浮動小数点数と整数の演算
4.0

julia> 3 * 1//2  ## 整数と有理数の演算
3//2

julia> 3//2 - 4.2  ## 有理数と浮動小数点数の演算
-2.7
```

また、`Float64`が入った配列に`Int`の要素を入れると`Float64`に変換されます。

```julia
julia> vec = rand(3)
3-element Vector{Float64}:
 0.8648348846009392
 0.31777049514431754
 0.17965655890277576

julia> push!(vec, 3)
4-element Vector{Float64}:
 0.8648348846009392
 0.31777049514431754
 0.17965655890277576
 3.0
```

これらの性質が組み合わさると、紛らわしくなる場合があります。

# 例
以下のように`func1`と`func2`を定義しましょう。




