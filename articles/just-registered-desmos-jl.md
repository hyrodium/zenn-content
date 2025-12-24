---
title: "Desmos.jlをつくってGeneralに登録したよ"
emoji: "〽"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["desmos", "julia"]
published: true
---

これは[Julia Advent Calendar 2025](https://qiita.com/advent-calendar/2025/julia)の20日目の記事です。遅くなってすみません。記事のネタのためのDemsos.jlの開発を優先しちゃって遅くなっちゃいました。

# はじめに
- Desmosはウェブブラウザ上でグラフを書ける数学ツールだよ
- Julia言語は科学技術計算に特化しているから、Desmosと相互にデータを受け渡して使えると嬉しいよね
- [Desmos.jl](https://github.com/hyrodium/Desmos.jl)というパッケージを作ってGeneralに登録したよ

https://github.com/hyrodium/Desmos.jl

# デモ
Juliaが動かせる環境を持っている人は、とりあえず下記のコードをコピペで動かしてみよう！
```julia
using Desmos

state = @desmos begin
    @text "First example"
    @expression cos(x) color=RGB(0, 0.5, 1) color="#f0f"
    @expression (cosh(t), sinh(t)) parametric_domain=-2..3
end
```

vscodeだと以下のように表示されます！

![](/images/desmos-vscode.png)

Pluto.jlだと以下のように表示されます！

![](/images/desmos-pluto.png)

Jupyterだと以下のように表示されます！

![](/images/desmos-jupyter.png)

いや、普通に https://desmos.com/calculator にアクセスして使う方が手軽で良いのでは…？
そう思う気持ちもよく分かります。しかし色んな応用例があるんですよ！！！！

# もっと使い方

## もう少し複雑な式の例
Juliaでの関数とDesmosでの関数は似たものが多いですが、微妙に違って困ることも多いです。
`@desmos`マクロはこの差分を吸収していい感じにしてくれます。

```julia
using Desmos

@desmos begin
    sin(x)
    a1 = 2
    gradient(sin(a1*x), x)
    sum(n^2 for n in 1:5)
    sum([n^2 for n in 1:5])
end
```

![](/images/desmos-compatibility.png)

- `sin(x)`は $\sin(x)$ になる
- 識別子`a1`は下付き文字を使って $a_1$ になる
- 微分は`gradient`を使って実現可能
- 数列の和は $\sum$ になる
- 配列の和は $\operatorname{total}$ になる

詳細は[Desmos.jlのドキュメントの Function Compatibility のセクション](https://hyrodium.github.io/Desmos.jl/dev/function-compatibility/)もどうぞ！

## プロットライブラリとして使う

Juliaでのプロットライブラリは[Plots.jl](https://docs.juliaplots.org/stable/)や[Makie.jl](https://docs.makie.org/stable/)が有名です。
これらの代わりにDesmos.jlを使うことができます！

```julia
using Desmos
# xの範囲を-10から+10まで
xs = -10:0.1:10
# yは適当につくる
ys = xs.^2/10 .* randn(length(xs))
# NamedTupleに詰めればDesmosのテーブルとして描画可能！
nt = (; xs, ys)
@desmos begin
    @table $nt color="#ffaa00"
end
```

![](/images/desmos-plots.png)

インタラクティブにプロット結果を触れるのが、Desmos.jlを使う一つのメリットですね。

## GLM.jl vs Desmos.jl
適当な2次元上の点列を放物線でフィッテングすることを考えましょう。

```julia
using Random
rng = Xoshiro(42)

# sinから点列をつくる
f(x) = sin(2x)

# x座標は(0,2)の範囲でランダムに
x1 = 2rand(rng, 100)

# y座標はf(x)をベースにランダム要素も入れる
y1 = f.(x1) + randn(rng, 100)/10
```

Desmosだと $\sim$ 記号を使うだけで簡単に回帰できます。

```julia
nt = (; x1, y1)
@desmos begin
    sin(2x)
    @table $nt color="#ff0000"
    @expression y1 ~ a*x1^2+b*x1+c color=RGB(0,1,1)
end
```

![](/images/desmos-sim.png)

係数がそれぞれ以下のように求まってますね。

$$
\begin{aligned}
a&=-1.29853 \\
b&=2.11994 \\
c&=0.0415522
\end{aligned}
$$

これをJuliaでやるには、例えば[GLM.jl](https://juliastats.org/GLM.jl/)パッケージを使えばよいです。

```julia
using GLM
using DataFrames
df = (;x1,y1,x12=x1.^2)
fit(LinearModel, @formula(y1 ~ x1 + x12), df)
```

実行後には以下のような表が示され、確かに前述の係数が`Coef.`の列に記載されていることが分かりますね。

```
y1 ~ 1 + x1 + x12

Coefficients:
────────────────────────────────────────────────────────────────────────────
                  Coef.  Std. Error       t  Pr(>|t|)   Lower 95%  Upper 95%
────────────────────────────────────────────────────────────────────────────
(Intercept)   0.0415522   0.0374524    1.11    0.2700  -0.0327805   0.115885
x1            2.11994     0.0865312   24.50    <1e-42   1.9482      2.29168
x12          -1.29853     0.0400957  -32.39    <1e-53  -1.37811    -1.21895
────────────────────────────────────────────────────────────────────────────
```

もちろんGLM.jlを悪く言いたいわけではないのですが、以下の部分は初心者にはちょっとつらい訳です。

- [DataFrames.jl](https://dataframes.juliadata.org/stable/)パッケージもついでに呼び出さなきゃいけない
- `@formula`とか`fit`とか`LinearModel`の使い方は直感的ではなく、ドキュメントを頑張って読む必要がある

Desmos.jlが便利なのはこういう場面です。

- Desmosに慣れていれば、数式を編集してリアルタイムにグラフを確認できる
- Desmosを使って直感的なGUIを使って実験できる
- 他のJuliaスクリプトで計算した結果の検算に使える

もちろんデメリットもあります。

- Desmosでの計算結果をJuliaに持ってくることができない
- Juliaで定義したオブジェクト(e.g. 関数)をそのままDesmosで使うことはできない

必要に応じて使い分けるのが便利でしょう。

## Newton法の例

以下のような非線形方程式を近似的に解くことを考えてみましょう。

$$
\begin{aligned}
    f(x,y) &= x^2+y^2-3.9-x/2 \\
    g(x,y) &= x^2-y^2-2
\end{aligned}
$$

解に十分近い初期値があれば、Newton法の反復計算によって近似解が得られます。
この非線形方程式の解は4つあり、この収束先ごとに色分けしている背景画像を用意すれば、Desmos上で初期値変更に依存した収束先の変更を観察できて楽しくなります。

```julia
using Desmos
# https://github.com/hyrodium/Visualize2dimNewtonMethod で生成した画像
image_url = "https://raw.githubusercontent.com/hyrodium/Visualize2dimNewtonMethod/b3fcb1f935439d671e3ddb3eb3b19fd261f6b067/example1a.png"
state = @desmos begin
    f(x,y) = x^2+y^2-3.9-x/2
    g(x,y) = x^2-y^2-2
    @expression 0 = f(x,y) color = Gray(0.3)
    @expression 0 = g(x,y) color = Gray(0.6)
    f_x(x,y) = gradient(f(x,y), x)
    f_y(x,y) = gradient(f(x,y), y)
    g_x(x,y) = gradient(g(x,y), x)
    g_y(x,y) = gradient(g(x,y), y)
    d(x,y) = f_x(x,y)*g_y(x,y)-f_y(x,y)*g_x(x,y)
    A(x,y) = x-(g_y(x,y)*f(x,y)-f_y(x,y)*g(x,y))/d(x,y)
    B(x,y) = y-(-g_x(x,y)*f(x,y)+f_x(x,y)*g(x,y))/d(x,y)
    a₀ = 1
    b₀ = 1
    a(0) = a₀
    b(0) = b₀
    a(i) = A(a(i-1),b(i-1))
    b(i) = B(a(i-1),b(i-1))
    @expression L"I = [0,...,10]"
    (a₀,b₀)
    @expression (a(I),b(I)) lines = true
    @image image_url = $image_url width = 20 height = 20 name = "regions"
end
```

![](/images/desmos-newton.gif)

今回は簡単のために背景画像の生成は省略しましたが、画像生成からDesmosグラフ作成までJuliaで一貫して作業できるのは便利ですね。[^6]

[^6]: あまり整理できていないですが、http://github.com/hyrodium/Visualize2dimNewtonMethod に背景画像生成するスクリプトがあります。

## Desmos Text I/Oとの連携

Desmos Text I/Oというのは私が作ったブラウザ拡張です。

https://www.youtube.com/watch?v=cwNIwvL-a2U

Desmosで描画したグラフは、内部的にはJavascriptのオブジェクトとして扱われています。
この拡張機能をインストールすれば、このオブジェクトをJSONとして入出力できるようになります。

Desmos.jlには`clipboard_desmos_state`という関数が用意されていて、クリップボードを経由してコピペすればブラウザのDesmosと連携することが可能になります。

```julia
using Desmos

# クリップボードボタンを有効化
Desmos.set_desmos_display_config(clipboard=true)

# グラフを作成
state = @desmos begin
    @text "My graph"
    @expression sin(x) + cos(2x)
    @expression y = x^2
end

# クリップボードにグラフをコピー (グラフ下のボタンからでも可能)
clipboard_desmos_state(state)
```

![](/images/desmos-clipboard.png)

# 内部処理の解説

## JSON.jlとの連携
前のセクションで少し触れたように、Desmos.jlではDesmosのグラフをJSONとして入出力して扱っています。

少し昔話ですが、Desmos.jlの開発を始めたのが2023年3月[^1]で、[JSON.jlのv1](https://github.com/JuliaIO/JSON.jl/releases/tag/v1.0.0)がリリースされたのが2025年10月です。[^2] JSON.jlのv1は以前のAPIから大きく変更されており、Desmos.jlではこのリリースに合わせて全面的に書き換えることになりました。[^3]

前述の`@desmos`ブロックが出力する型は`DesmosState`ですが、現在の実装ではこれがそのままJSONの型に一致するようになっています。以前の実装では「Julia内部でグラフの状態を管理するための型」と「Desmosで扱うJSONの構造」が一致しておらず、メンテナンスコストが高かったのですが、JSON.jl v1の柔軟性によってこの問題が解決できました。

[^1]: JuliaTokai#14で[「Desmos.jlをつくってる話」という発表](https://hackmd.io/@hyrodium/BJ9Nmxnx3#/1)をしていました。
[^2]: JSON.jlのv1がリリースされる前のJSON用JuliaパッケージはJSON.jlやJSON3.jl、その他色々なパッケージが存在して混沌としていました。現在では基本的には迷わずJSON.jlのv1を使うだけで良いようになったので、ユーザーとしては嬉しい限りです。
[^3]: Desmos.jlを全面的に書き換えたと書きましたが、元々の私の実装がイケてなかったのも大きいとは思います。

```julia
julia> using Desmos

julia> state = @desmos begin
           @text "First example"
           @expression cos(x) color=RGB(0, 0.5, 1) color="#f0f"
           @expression (cosh(t), sinh(t)) parametric_domain=-2..3
       end;

julia> typeof(state)
DesmosState
```

## Desmos API
`DesmosState`型がJSONに対応するとして、それをどのようにブラウザ外で描画すれば良いでしょうか？

これを叶えてくれるのが[Desmos API](https://www.desmos.com/api/v1.11/docs/index.html)です！ ライブラリがjsファイルとして公開されていて、気軽に誰でもDesmosのグラフを自分のウェブページに埋め込んで利用できるようになっています。

記事執筆時点において、最新のドキュメントのAPIバージョンはv1.12、https://desmos.com/calculator で使用されているAPIバージョンはv1.11、ドキュメントでAPIキーが公開されているバージョンはv1.10です。[^4]

[^4]: [v1.10のドキュメント](https://www.desmos.com/api/v1.10/docs/index.html)ではAPIキーが最初のコード例に記載されています。v1.11以降のドキュメントでは自分でAPIキーを

Desmos APIは個人利用では無料、商用利用では有料のようです。Desmos.jlの開発は趣味でやっているのでタダ、ありがたいですね。[^5]

[^5]: Desmos.jlはMITライセンスとして公開されていますが、APIの利用に当たっては商用利用が制限される建付けになっています。ご注意ください。

## Base.showの実装
さてDesmosのグラフをHTMLファイルに埋め込めるのが分かったとして、どのようにvscodeやPluto.jlやJupyterの出力に埋め込めば良いでしょうか？

答え: 以下の2つのメソッドを定義すればOKです。

- `Base.show(io::IO, ::MIME"text/html", state::DesmosState)`
- `Base.show(io::IO, ::MIME"juliavscode/html", state::DesmosState)`

https://github.com/hyrodium/Desmos.jl/blob/280af48ebe0de44e0cf3605b2aa855525000095b/src/show.jl#L73-L81

これらを定義すればそのまま前述のようにプロットが表示されるようになります。
多重ディスパッチ万歳！！！

## 独自実装のlatexify
さて、Desmosグラフを表すJSONでは、それぞれの数式ブロックがLaTeX形式で保存されています。Desmosの描画エンジンは内部的にこのLaTeXをいい感じにパースしてグラフを描画してくれている訳ですね。

Desmos.jlでは`@desmos`マクロの実現ために`Expr`型から`LaTeXString`型へ変換する必要がありました。
この要求を満たすJuliaパッケージの一つに[Latexify.jl](https://korsbo.github.io/Latexify.jl/dev/)というものがあり、以前はこのパッケージを利用していましたが、現在は独自実装になっています。

```julia
julia> using Latexify, Desmos

julia> ex = :(sin(x))
:(sin(x))

julia> Latexify.latexify(ex)  # Latexify.jlでは$やスペースが入ったりする
L"$\sin\left( x \right)$"

julia> desmos_latexify(ex)  # Desmosの標準的なフォーマットに合わせている
"\\sin\\left(x\\right)"

julia> ex = :([1,2,5])
:([1, 2, 5])

julia> Latexify.latexify(ex)  # Latexify.jl
L"$\left[
\begin{array}{c}
1 \\
2 \\
5 \\
\end{array}
\right]$"

julia> desmos_latexify(ex)  # Desmosだと[]は配列のように扱われる
"\\left[1,2,5\\right]"
```

こういう独自実装の管理は面倒で大変です。Claude Codeに手伝ってもらって大変助かりました。

## マクロの実装

`@desmos`のように`@`で始まるものがJuliaのマクロです。
今回のマクロは以下のような実装になっていて少し工夫が必要でした。

- `@desmos`の内部で`$`が使用された場合は変数の中身が展開される
- `@desmos`の内部で`@expression`や`@table`が使用可能だが、Desmos.jlからexportされている訳ではない
- `@expression`などでは`color`などがキーワード引数のように設定可能

```julia
using Desmos
xs = -10:0.1:10
ys = xs.^2/10 .* randn(length(xs))
nt = (; xs, ys)
@desmos begin
    sin(x)
    @expression a=4 slider=1:2:7
    @table $nt color="#ffaa00"
end
```

## ユーザー定義型をDesmosで描画するには

私が作っているパッケージ[QuadraticOptimizer.jl](https://github.com/hyrodium/QuadraticOptimizer.jl)では $D$ 変数2次関数を`Quadratic{D}`で定義しており、これをDesmos.jlで使うことも可能です。

```julia
using Desmos
using QuadraticOptimizer
using StaticArrays
q2 = Quadratic(SVector(2,1,4), SVector(1,2), 5)
a, b = rand(2)
@desmos begin
    @expression f(x,y)=$q2
    -100:5:100 = f(x,y)
    f(a, b)
    a = $a
    b = $b
end
q2(SVector(a,b))
```

![](/images/desmos-quadratic.png)

この型`Quadratic{D}`をDesmos.jlで使うために定義されているメソッドは以下の2つのみです。

- `desmos_latexify(::Quadratic{1})`
- `desmos_latexify(::Quadratic{2})`

これらのメソッドの追加は[パッケージ拡張(package extension)](https://pkgdocs.julialang.org/v1/creating-packages/#Conditional-loading-of-code-in-packages-(Extensions))として実現できるので、ユーザー定義型で使いたいときはお気軽にどうぞ！

https://github.com/hyrodium/Desmos.jl/blob/c9dfc7d7f216f3c195152a348f81f878c83da470/ext/DesmosQuadraticOptimizerExt.jl#L7-L24

## たぶん原理的に実装できなさそうなこと
以下の項目がDesmos.jlで実現できると便利ではあるのですが、たぶん無理だろうと考えています。

- Juliaで定義した関数をDesmosの関数として扱う
- Desmosでの計算結果をJulia側で取得する
- Desmosで定義したアクションを経由してJuliaの関数を実行する

# Desmos.jlというパッケージ名の持つ責任
例えば、Google.jlという名前のJuliaパッケージは現在[General](https://github.com/JuliaRegistries/General)に登録されていません。では、第三者がGoogle検索するためのJuliaパッケージものを作った時にGoogle.jlと名付けてGeneralに登録して問題ないでしょうか？
→これはかなり怪しい、というか避けるべきでしょう。

一度登録されたパッケージは基本的には取り消すことが不可能で、特にそれが外部サービス名であれば「俺は責任を持ってこのパッケージをメンテナンスし続けるぜ」という強い意志が求められます。[^7]
ではDesmos.jlの場合はどうか。

- [私(hyrodium)](https://github.com/hyrodium/)はDesmosの中の人ではありません。
- しかしDesmos本体の日本語訳にボランティアで参加した経験があります。[^8]
- 10年以上使っていてツールに対する愛着は強い方だと思います。
- Desmos.jlの開発開始からGeneralに登録していない状態で2年以上経過しており、その間に他の人が同名のパッケージを公開するなどの問題は発生しませんでした。
- ちゃんと「Unofficial Julia package for Desmos」と明記しています。

これくらいの状況であれば…Desmos.jlをGeneralに登録しても倫理的に問題はないはず…。
引き続き、気を引き締めて開発に取り組んでいきます。

[^7]: ちなみに[Slack.jl](github.com/JuliaLangSlack/Slack.jl)という非公式パッケージがGeneralに登録されていますが、全然メンテナンスされていなかったりします。
[^8]: [Desmosユーザーガイド](https://desmos.s3.amazonaws.com/Desmos_User_Guide_JA.pdf)に私の名前があります。

# 今後の予定
- Desmos.jlをPlots.jlのバックエンドとして使いたいね
	- Plots.jlのメンテナ不足が大変そうなので、そこのお手伝いもやってみたい
	- みんなMakie.jlに浮気しているか、Plots.jlを使っているけどcontributionに興味ないかだね
- もっとDesmosの機能を取り込みたいね
	- 3Dプロットできるようにする
	- 複素数を扱えるようにする
	- etc.
