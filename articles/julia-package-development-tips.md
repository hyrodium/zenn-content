---
title: "Juliaパッケージ開発のアレってどうやんだっけ？となった時に見る記事"
emoji: "🤔"
type: "tech"
topics: [julia]
published: false
---

# はじめに
久々にJuliaのパッケージメンテナンスを再開した時にアレどうなってたっけ？となることが多かったので、雑多ですが列挙していきます。

- 共有パッケージ環境を使用する方法
- リリース時にドキュメントが生成されるようにする方法
- ローカル環境でのテストのcoverage取得
- Documenter.jlで生成したドキュメントをローカルで確認
- jldoctestの更新
- テストの実行環境を用意
- コード検索

[Julia Advent Calendar 2025](https://qiita.com/advent-calendar/2025/julia)の17日目の記事のはじまりでした。
よろしくおねがいします。

# 共有パッケージ環境を使用する方法

## 先に結論を提示

juliaのCLI引数で`--project=@pkgdev`のように指定すれば

```
julia --project=@pkgdev
```

## 詳細をもう少し解説

Juliaのパッケージには「」「」「」の3種類があって…みたいな話
(すいません書きかけです)

```
               _
   _       _ _(_)_     |  Documentation: https://docs.julialang.org
  (_)     | (_) (_)    |
   _ _   _| |_  __ _   |  Type "?" for help, "]?" for Pkg help.
  | | | | | | |/ _` |  |
  | | |_| | | | (_| |  |  Version 1.12.1 (2025-10-17)
 _/ |\__'_|_|_|\__'_|  |  Official https://julialang.org release
|__/                   |

(@pkgdev) pkg> st
Status `~/.julia/environments/pkgdev/Project.toml`
  [e30172f5] Documenter v1.16.1
  [35a29f4d] DocumenterTools v0.1.21
  [62bfec6d] Runic v1.5.1
  [1e6cf692] TestEnv v1.103.0
```

# リリース時にドキュメントが生成されるようにする方法
## 先に結論を提示
以下のコードをREPLとかで実行して出力に従ってキーをGitHubリポジトリに登録すれば良い。
```julia
using DocumenterTools
DocumenterTools.genkeys(; user="GitHubUserName", repo="MyPkg.jl")
```

## 詳細をもう少し解説
JuliaではDocumenter.jlでドキュメント生成する慣習があります。

通常の開発時のワークフローはこんな感じ:
1. `git push`かPRをmergeしてデフォルトブランチを更新
1. デフォルトブランチの更新を検知して`.github/workflows/Docs.yml`を起動
1. GitHub Actions上でドキュメントビルドして`gh-pages`ブランチにpush
1. デプロイされたドキュメントが閲覧できるようになる

リリース時のワークフローはこんな感じ:
1. `@JuliaRegistrator register`のように依頼してパッケージリリース申請
1. [General](https://github.com/JuliaRegistries/General)に登録されたことを検知して[TagBot](https://github.com/JuliaRegistries/TagBot)がリリースを打つ
1. **新規タグの更新を検知して`.github/workflows/Docs.yml`を起動**
1. GitHub Actions上でドキュメントビルドして`gh-pages`ブランチにpush
1. デプロイされたドキュメントが閲覧できるようになる

ここの「新規タグの更新を検知して`.github/workflows/Docs.yml`を起動」に失敗しているケースが多いんですよね。
`.github/workflows/Docs.yml`の設定にはタグ追加でトリガーされると記載されていても、botが作ったタグには反応してくれないみたいなんですよね。
これを解決するには、冒頭で述べたようなコマンドを実行して案内にしたがってキーを追加すればOKです。
私([hyrodium](https://github.com/hyrodium/))の作っている[Desmos.jl](https://github.com/hyrodium/Desmos.jl)というパッケージの場合だとこんな感じ:

```julia
using DocumenterTools
DocumenterTools.genkeys(; user="hyrodium", repo="Desmos.jl")
```

出力は以下のようになります。Infoの内側にURLが2つ記載されているので、ここにアクセスして登録するだけでOKです。

```
julia> DocumenterTools.genkeys(; user="hyrodium", repo="Desmos.jl")
┌ Info: Add the key below as a new 'Deploy key' on GitHub (https://github.com/hyrodium/Desmos.jl/settings/keys) with read and write access.
└ The 'Title' field can be left empty as GitHub can infer it from the key comment.

ssh-rsa AAAAB3Nz(中略)hmcQISM= Documenter

[ Info: Add a secure 'Repository secret' named 'DOCUMENTER_KEY' (to https://github.com/hyrodium/Desmos.jl/settings/secrets if you deploy using GitHub Actions) with value:

LS0tLS1C(中略)LS0tLQo=
```

すいません、書いてから気づきましたが、[ごまふあざらし](https://bsky.app/profile/gomahuazarashi.bsky.social)さんが同じ内容の記事を書いてくれてましたね。
https://zenn.dev/terasakisatoshi/articles/87e730a50915f9

以降のセクションでは、(たぶん)他の日本語記事と内容が被ってない気がするので許してください！！！

# ローカル環境でのテストのカバレッジ取得
## 先に結論を提示
以下のコマンドを`~/.julia/dev/MyPkg`以下で実行すればカバレッジが`~/.julia/dev/MyPkg/coverage/index.html`に出力されます。
```bash
julia --project=. -e 'using Pkg; Pkg.test(basename(pwd()); coverage=true)' && julia -e 'using Coverage; coverage=process_folder(); LCOV.writefile("coverage-lcov.info", coverage)' && genhtml coverage-lcov.info --output-directory coverage
```

## 詳細をもう少し解説
GitHub上でパブリックリポジトリとしてパッケージ開発を進めている場合には`.github/workflows/Test.yml`([Desmos.jlでの例](https://github.com/hyrodium/Desmos.jl/blob/main/.github/workflows/Test.yml))を設定すれば[codecov.io](https://about.codecov.io/)とかでカバレッジが取得できますよね。
具体的には以下のような手順です。

1. パッケージ本体(`src/`)とテスト(`test/`)の実装を進める
1. 定期的にcommitしてGitHubにpushする
1. CIが走ってcodecov.ioにカバレッジがアップロードされるので目視確認する

[![](/images/coverage-codecov-desmos-jl.png)](https://app.codecov.io/gh/hyrodium/Desmos.jl/tree/main/src)

しかし以下のようなケースではローカル環境でのカバレッジ取得が欲しくなります。
- プライベートリポジトリで作業しているので、codecov.ioを使いたくない
- CIを待つ時間がもったいないので、ローカル環境でカバレッジ確認したい
- Claude Code等のツールからカバレッジ取得するにはローカルファイルにカバレッジが出力される方が好ましい

そこで実行するのが前述のコマンドですね。
あれを実行すればカバレッジの測定結果が人間に見やすい形式で`~/.julia/dev/MyPkg/coverage/index.html`に出力されます。

![](/images/coverage-lcov-desmos-jl.png)

Codecovのようなイケてる見た目ではないですが、ローカルで現在のテストコードでのカバレッジを確認する分には十分でしょう。

冒頭のコードの解説に移ります。
`&&`で繋いでましたが、実質的に以下の3つのコマンドを実行していました。

```bash
# 現在のパッケージディレクトリでテストを実行。カバレッジ取得モードをtrueに設定。
julia --project=. -e 'using Pkg; Pkg.test(basename(pwd()); coverage=true)'

# Coverage.jlを利用して`coverage-lcov.info`ファイルを出力
julia -e 'using Coverage; coverage=process_folder(); LCOV.writefile("coverage-lcov.info", coverage)'

# `coverage-lcov.info`をベースに`coverage`ディレクトリに人間可読性の高いHTMLファイルを出力
genhtml coverage-lcov.info --output-directory coverage
```

最初のテストでは`src/*.jl.*.cov`のようなJulia言語特有のカバレッジ記録ファイルが出力されています。
これを、lcovという他の言語でも共通のカバレッジ記録用フォーマットに変換するのが[Coverage.jl](https://github.com/JuliaCI/Coverage.jl)の役割ですね。
lcovから人間の読みやすいフォーマットに変換するコマンドが最後の`genhtml`コマンドです。

# Documenter.jlで生成したドキュメントをローカルで確認
## 先に結論を提示

以下のコマンドを実行すれば localhost:8000 などのアドレスからドキュメントがプレビューできます。
```bash
julia --project=docs -e 'using Pkg;Pkg.develop(PackageSpec(path=pwd()));Pkg.instantiate();include("docs/make.jl");' && julia -e 'using LiveServer; serve(dir="docs/build")'
```

## 詳細をもう少し解説
GitHubでパッケージを管理している場合は、GitHub Pagesにデプロイされたドキュメントを直接確認することもできます。
しかしやっぱりローカル環境でドキュメントをプレビューできる方が使い勝手が良いですよね。
そういうときに前述のコマンドが役立ちます。

```bash
# ドキュメントを生成
julia --project=docs -e 'using Pkg;Pkg.develop(PackageSpec(path=pwd()));Pkg.instantiate();include("docs/make.jl");'

# ビルドされたドキュメントを表示するサーバーを立ち上げる
julia -e 'using LiveServer; serve(dir="docs/build")'
```

# jldoctestの更新

## 先に結論を提示
以下のコマンドを`~/.julia/dev/<MyPkg>`以下で実行すればjldoctestブロックが更新されます。

```bash
julia --project=docs -e 'using Pkg;Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate(); using Documenter; Documenter.deploydocs(kwargs...) = nothing; if isfile("docs/make.jl") try include("docs/make.jl") catch end else pkg_sym = Symbol(basename(pwd())); Core.eval(Main, :(using $pkg_sym; Documenter.DocMeta.setdocmeta!($pkg_sym, :DocTestSetup, :(using $pkg_sym); recursive=true))) end; thispkg = getfield(Main, Symbol(basename(pwd()))); doctest(thispkg; fix=true);'
```

## 詳細をもう少し解説
jldoctestというのはJulia言語で使用されるdoctestのことですね。
以下のように書くものです。

````julia
module MyPkg

"""
```jldoctest
julia> using MyPkg  # jldoctestに毎回書きたくはない。省略可能(後述)。

julia> myfunc(2)
3

julia> myfunc(-3)
8
```
"""
myfunc(x) = x^2 - 1

end
````

jldoctestは通常の`test`ディレクトリのテストとは別に、docstring内にREPLの出力結果として記述できることが特徴です。
しかしこのテスト、ドキュメントの更新がコード更新に間に合っていなかったり、出力フォーマットが微妙に変わったり[^2]とかで、最新の状態に保たれていないことが多いんですよね。

[^2]: 通常、`Base.show`で出力される文字列の変更は破壊的変更として扱われません。そのため、出力文字列の比較として実行されるjldoctestは依存パッケージでの`Base.show`を更新したりするだけで容易に壊れてしまいます。

この壊れがちなdoctestを更新するにはDocumenter.jlの力を借りて以下のようなコマンドを実行します。

```julia
using Documenter, MyPkg
doctest(MyPkg, fix=true)
```

もっとも短いケースではこれで十分なのですが、冒頭の`using MyPkg`を省略したいときには以下のように`Documenter.DocMeta.setdocmeta!`を宣言する必要があります。

```julia
using Documenter, MyPkg
Documenter.DocMeta.setdocmeta!(MyPkg, :DocTestSetup, :(using MyPkg); recursive=true)
doctest(MyPkg, fix=true)
```

JuliaのREPLは優秀で便利ではあるのですが、上記のコードをパッケージごとに毎回入力するのは面倒ではあります。
しかも`setdocmeta!`の引数はパッケージごとに単純に切り替えられるとは限らず、状況によっては`using MyOtherPkg`を読み込む必要があったり、`Random.seed!(42)`を呼び出したりすることがあるのですよね。

この問題を解決するコマンドが前述の結論で提示したJuliaコマンドです。
あれの中身を展開してインデントを揃えると以下のようになります。

```julia
using Pkg;Pkg.develop(PackageSpec(path=pwd()))
Pkg.instantiate()
using Documenter
Documenter.deploydocs(kwargs...) = nothing
if isfile("docs/make.jl")
    try
        include("docs/make.jl")
    catch
    end
else
    pkg_sym = Symbol(basename(pwd()))
    Core.eval(Main, :(using $pkg_sym; Documenter.DocMeta.setdocmeta!($pkg_sym, :DocTestSetup, :(using $pkg_sym); recursive=true)))
end
thispkg = getfield(Main, Symbol(basename(pwd())))
doctest(thispkg; fix=true)
```

まだ少し分かりにくいですね。
`Desmos.jl`が対象パッケージだとして変数を展開して、コメントも追加してみましょう。

```julia
# Desmos.jlをdevとして依存関係に追加
using Pkg;Pkg.develop(PackageSpec(path=pwd()))
Pkg.instantiate()
using Documenter
Documenter.deploydocs(kwargs...) = nothing
if isfile("docs/make.jl")
    try
        include("docs/make.jl")
    catch
    end
else
    using Desmos
    Documenter.DocMeta.setdocmeta!(Desmos, :DocTestSetup, :(using Desmos); recursive=true)
end
doctest(Desmos; fix=true)
```

CIではどうやってたっけ?
doctest更新CIも存在していたが、更新されていない

# テストの実行環境を用意
TestEnv.jlを使えば良い



# コード検索
Juliaには`@less`マクロがあって…
しかし、「この関数が他のパッケージでどのように使われているか知りたい」みたいに
ここでJuliaHubの

例として、`@rd_str`を確認してみましょう。
https://zenn.dev/link/comments/3d2a0b0e9bf563

GitHubにも同様の機能がありますが、こっちは
- 登録されていないパッケージやコード断片も検索対象になってしまう
- GitHubしか検索できない

# おわりに
- 他にTipsあればコメントで教えてください！
	- プロファイリングとかデバッグとかあまり詳しくないのでベストプラクティスがあれば知りたい
- ModernJuliaWorkflowとか
- 関連する質問があればコメントしてください！
- JuliaLangJaのDiscordのメンバーも募集中です！こちらで質問を投げてもらっても良いです！
