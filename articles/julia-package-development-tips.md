---
title: "Juliaパッケージ開発のアレってどうやんだっけ？となった時に見る記事"
emoji: "🤔"
type: "tech"
topics: [julia, パッケージ管理, codecov, doctest]
published: true
---

# はじめに
久々にJuliaのパッケージメンテナンスを再開した時にアレどうなってたっけ？となることが多かったので、雑多ですが列挙していきます。

- 共有パッケージ環境を使用する方法
- リリース時にのみドキュメントが生成できない問題を解決する方法
- ローカル環境でのテストのcoverage取得
- Documenter.jlで生成したドキュメントをローカルで確認
- jldoctestの更新
- テストの実行環境を用意
- コード検索

[Julia Advent Calendar 2025](https://qiita.com/advent-calendar/2025/julia)の17日目の記事のはじまりでした。一日遅れですみません。
よろしくおねがいします。

# 共有パッケージ環境を使用する方法

## 先に結論を提示

juliaのCLI引数で`--project=@pkgdev`のように`@<shared env name>`を指定すれば共有パッケージ環境でJuliaが起動します。

```bash
julia --project=@pkgdev
```

(**重要**) 今回の記事で使用するパッケージは以下のコマンドでインストールできます。

```bash
julia --project=@pkgdev --startup-file=no -e 'using Pkg; Pkg.add(["Documenter", "DocumenterTools", "Coverage", "LiveServer"])'
```

## 詳細をもう少し解説

Juliaのパッケージ環境には大雑把に言って「グローバル環境の`v1.x`」「ディレクトリごとのプロジェクト環境」「共有プロジェクト環境」「スクリプト環境」の4種類があります。

- グローバル環境の`v1.x`
  - `--project`を指定しなかった場合に起動するデフォルトの環境
  - `~/.julia/environments/v1.x/Project.toml`
- ディレクトリごとのプロジェクト環境
  - `Project.toml`の配置されたディレクトリを直接指定して起動する環境
  - `path/to/Project.toml`
- **共有プロジェクト環境**
  - ディレクトリを指定せずに実行できるようなプロジェクト環境
  - `~/.julia/environments/<shared env name>/Project.toml`
- スクリプト環境
  - [JuliaLang/julia #50864](https://github.com/JuliaLang/julia/issues/50864), [JuliaLang/julia #53352](https://github.com/JuliaLang/julia/issues/53352)で追加されたパッケージ環境
  - 今回の記事を書くに当たって知った機能ですが、筆者は詳しく知りません

この共有プロジェクト環境というのが便利で、以下のような要望を満たしてくれるのですよね。

- デフォルトのグローバル環境のようにどのディレクトリに居たとしても使いたい
- しかしパッケージ間の依存関係を解決するために複数のグローバル環境を切り替えたい

[この機能はv1.7辺りから存在してた](https://docs.julialang.org/en/v1.7-dev/NEWS/#Command-line-option-changes)ようなのですが、私は最近になって[Runic.jl](https://github.com/fredrikekre/Runic.jl)のインストール方法を見て知りました。もしかして知らなかったの私だけか？？？？？？？？[^5]

[^5]: 現在(Julia v1.12.3)の`julia --help`のメッセージには少なくともこの機能の説明は無いんですよね。あとで余裕のあるときにPRつくります。

# リリース時にのみドキュメントが生成できない問題を解決する方法
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
`.github/workflows/Docs.yml`を用意してタグ追加でトリガーされると記載されていても、botが作ったタグには反応してくれないケースがあるんですよね。
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
以下のコマンドを`~/.julia/dev/MyPkg`以下で実行すればカバレッジが`~/.julia/dev/MyPkg/coverage/index.html`に出力されます。(注意: `genhtml`コマンドの事前インストールが必要)

```bash
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test(basename(pwd()); coverage=true)' && julia --project=@pkgdev --startup-file=no -e 'using Coverage; coverage=process_folder(); LCOV.writefile("coverage-lcov.info", coverage)' && genhtml coverage-lcov.info --output-directory coverage
```

## 詳細をもう少し解説
GitHub上でパブリックリポジトリとしてパッケージ開発を進めている場合には`.github/workflows/Test.yml`([Desmos.jlでの例](https://github.com/hyrodium/Desmos.jl/blob/main/.github/workflows/Test.yml))を設定すれば[codecov.io](https://about.codecov.io/)とかでカバレッジが閲覧できますよね。
具体的には以下のような手順です。

1. パッケージ本体(`src/`)とテスト(`test/`)の実装を進める
1. 定期的にcommitしてGitHubにpushする
1. CIが走ってcodecov.ioにカバレッジがアップロードされるので目視確認する

https://app.codecov.io/gh/hyrodium/Desmos.jl/tree/main/src

[![](/images/coverage-codecov-desmos-jl.png)](https://app.codecov.io/gh/hyrodium/Desmos.jl/tree/main/src)

しかし以下のようなケースではローカル環境でのカバレッジ取得が欲しくなります。
- プライベートリポジトリで作業しているので、codecov.ioを使えない
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
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test(basename(pwd()); coverage=true)'

# Coverage.jlを利用して`coverage-lcov.info`ファイルを出力
julia --project=@pkgdev --startup-file=no -e 'using Coverage; coverage=process_folder(); LCOV.writefile("coverage-lcov.info", coverage)'

# `coverage-lcov.info`をベースに`coverage`ディレクトリに人間可読性の高いHTMLファイルを出力
genhtml coverage-lcov.info --output-directory coverage
```

最初のテストでは`src/*.jl.*.cov`のようなJulia言語特有のカバレッジ記録ファイルが出力されています。
これを、lcov形式という他の言語でも共通のカバレッジ記録用フォーマットに変換するのが[Coverage.jl](https://github.com/JuliaCI/Coverage.jl)の役割ですね。
lcov形式から人間の読みやすいフォーマットに変換するコマンドが最後の`genhtml`コマンドです。[^genhtml]

[^genhtml]: `genhtml`コマンドはManjaroなどでは`pacman -S lcov`でインストール可能です。ところで、このコマンド名はImageMagickの`convert`くらい酷い命名じゃないですか？

# Documenter.jlで生成したドキュメントをローカルで確認
## 先に結論を提示

以下のコマンドをパッケージのルートディレクトリで実行すれば localhost:8000 などのアドレスからドキュメントがプレビューできます。
```bash
julia --project=docs --startup-file=no -e 'using Pkg;Pkg.develop(PackageSpec(path=pwd()));Pkg.instantiate();include("docs/make.jl");' && julia --project=@pkgdev --startup-file=no -e 'using LiveServer; serve(dir="docs/build")'
```

## 詳細をもう少し解説
GitHubでパッケージを管理している場合は、GitHub Pagesにデプロイされたドキュメントを直接確認することもできます。
しかしやっぱりローカル環境でドキュメントをプレビューできる方が使い勝手が良いですよね。
そういうときに前述のコマンドが役立ちます。

```bash
# ドキュメントを生成
julia --project=docs --startup-file=no -e 'using Pkg;Pkg.develop(PackageSpec(path=pwd()));Pkg.instantiate();include("docs/make.jl");'

# ビルドされたドキュメントを表示するサーバーを立ち上げる
julia --project=@pkgdev --startup-file=no -e 'using LiveServer; serve(dir="docs/build")'
```

# jldoctestの更新

## 先に結論を提示
以下のコマンドを`~/.julia/dev/<MyPkg>`以下で実行すればjldoctestブロックが更新されます。
忙しい人向け。長過ぎるワンライナーなので、本来ならちゃんとシェルスクリプトとして整備するのが良いでしょう。

```bash
[ -f docs/make.jl ] && julia --project=docs --startup-file=no -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate(); using Documenter; Documenter.deploydocs(kwargs...) = nothing; try include("docs/make.jl"); catch end; thispkg = getfield(Main, Symbol(basename(pwd()))); doctest(thispkg; fix=true)' || julia --project=@pkgdev --startup-file=no -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate(); mkpath("docs/src"); using Documenter; pkg_sym = Symbol(basename(pwd())); Core.eval(Main, :(using $pkg_sym)); thispkg = getfield(Main, pkg_sym); Documenter.DocMeta.setdocmeta!(thispkg, :DocTestSetup, :(using $pkg_sym); recursive=true); doctest(thispkg; fix=true)'
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

jldoctestは通常の`test`ディレクトリ内のテストとは別のもので、docstring内にREPLの出力結果として記述できることが特徴です。
しかしこのテスト、ドキュメントの更新がコード更新に間に合っていなかったり、出力フォーマットが微妙に変わったり[^2]とかで、最新の状態に保たれていないことが多いんですよね。

[^2]: 通常、`Base.show`で出力される文字列の変更は破壊的変更として扱われません。そのため、出力文字列の比較として実行されるjldoctestは依存パッケージでの`Base.show`が更新されたりするだけで容易に壊れてしまいます。

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

```julia: docs/make.jlが存在する場合
using Pkg
Pkg.develop(PackageSpec(path=pwd()))
Pkg.instantiate()
using Documenter
Documenter.deploydocs(kwargs...) = nothing
try
    include("docs/make.jl")
catch
end
thispkg = getfield(Main, Symbol(basename(pwd())))
doctest(thispkg; fix=true)
```

```julia: docs/make.jlが存在しない場合
using Pkg
Pkg.develop(PackageSpec(path=pwd()))
Pkg.instantiate()
mkpath("docs/src")
using Documenter
pkg_sym = Symbol(basename(pwd()))
Core.eval(Main, :(using $pkg_sym))
thispkg = getfield(Main, pkg_sym)
Documenter.DocMeta.setdocmeta!(thispkg, :DocTestSetup, :(using $pkg_sym); recursive=true)
doctest(thispkg; fix=true)
```

まだ少し分かりにくいですね。
`Desmos.jl`が対象パッケージだとして変数を展開して、コメントも追加してみましょう。

```julia: docs/make.jlが存在する場合
# Desmos.jlをdevとして依存関係に追加
using Pkg
Pkg.develop(PackageSpec(path=pwd()))
Pkg.instantiate()
using Documenter
# 以降の`make.jl`の実行時に不要なデプロイ処理を避けるためにメソッドを上書きして無効化しておく
Documenter.deploydocs(kwargs...) = nothing
try
    # `setdocmeta!`の設定を読み込むためにincludeする
    # このファイルの中で実行される`Documenter.makedocs`は不要に思えるが、後段の`doctest`で`makedocs`が呼ばれるので無効化してはいけない
    include("docs/make.jl")
catch
end
# ここでdoctestを更新する
doctest(Desmos; fix=true)
```

```julia: docs/make.jlが存在しない場合
# Desmos.jlをdevとして依存関係に追加
using Pkg
Pkg.develop(PackageSpec(path=pwd()))
Pkg.instantiate()
# doctestの実行には`docs/src`ディレクトリが必要らしいので作っておく (空でOK)
mkpath("docs/src")
using Documenter
using Desmos
# doctest実行時に`using MyPkg`を省略するのは標準的な作法だとして`setdocmeta!`しておく
Documenter.DocMeta.setdocmeta!(Desmos, :DocTestSetup, :(using Desmos); recursive=true)
# ここでdoctestを更新する
doctest(Desmos; fix=true)
```

このようなちょっと面倒なコードを実行してくれるのが前述のワンライナーでした。[^julia-fix-doctests]

[^julia-fix-doctests]: このような処理を自動でGitHub Actionsが定期的に実行してくれるのが理想的だと思いますよね？実は[actions/julia-fix-doctests](https://github.com/julia-actions/julia-fix-doctests)というものがあるんですが、数年間メンテナンスされておらず、本記事で示したように`docs/make.jl`を読み込んだりはしてくれません。気が向いた時にPR送ってみようと思います。

# テストの実行環境を用意

## 先に結論を提示

[TestEnv.jl](https://github.com/JuliaTesting/TestEnv.jl)を使えば良い。
ただしインストール先は「グローバル環境の`v1.x`」であって、「ディレクトリごとのプロジェクト環境」や「共有プロジェクト環境」ではない。[^test-env-env]

[^test-env-env]: もしかすると私が知らないだけで「共有プロジェクト環境」からTestEnv.jlを使う方法はあるかも知れないです。

```julia: ~/.julia/dev/Desmosをプロジェクト環境としてJuliaを起動した場合
julia> using TestEnv;

julia> TestEnv.activate();

julia> using Desmos, Aqua  # 通常のパッケージ環境だとAquaはusingできない
```

## 詳細をもう少し解説

パッケージのために定義される環境は「ディレクトリごとのプロジェクト環境」に該当します。
例えばDesmos.jlの場合は`~/.julia/dev/Desmos/Project.toml`に依存関係などが記載されています。
このプロジェクトファイルを指定した場合には「パッケージが依存しているパッケージ」のみが使用可能な状態でJuliaが起動します。

```julia: ~/.julia/dev/Desmosをプロジェクト環境としてJuliaを起動した場合
julia> using Desmos  # もちろんDesmos.jlはインポートできる

julia> using Aqua  # しかし[extras]内のAqua.jlは使用できない
ERROR: ArgumentError: Package Aqua not found in current path.
- Run `import Pkg; Pkg.add("Aqua")` to install the Aqua package.
Stacktrace:
 [...]
```

しかし、このプロジェクトファイルにはテスト用のパッケージ依存関係も`[extras]`として記載されています。[^test-project]
このようなテスト用パッケージまで使用可能な状態でJuliaを起動するときに便利なのが、前述の[TestEnv.jl](https://github.com/JuliaTesting/TestEnv.jl)です。
この関数を読み込んで`TestEnv.activate()`すればテスト用のパッケージ環境が揃った状態になります。

[^test-project]: `[extras]`の代わりに`test/Project.toml`ファイルを用意してテスト用のパッケージ環境を構築することも可能です。別ファイルで管理する方法の方が新しく、(どちらかと言えば)推奨されているようです。詳細は[Pkg.jlの公式ドキュメント](https://pkgdocs.julialang.org/v1/creating-packages/#Test-specific-dependencies)を確認してください。

```julia: ~/.julia/dev/Desmosをプロジェクト環境としてJuliaを起動した場合
julia> using TestEnv  # ~/.julia/dev/Desmos/Project.tomlの依存関係には記載されていないが、グローバル環境(v1.x)にインストール済みなので使用可能

julia> TestEnv.activate();

julia> using Desmos  # もちろんDesmos.jlはインポートできる

julia> using Aqua  # [extras]内のAqua.jlも使えるようになった！
```

便利で良いですね。

# コード検索

## 先に結論を提示

以下の2種類の方法でコード検索ができるので便利

- GitHub上のコード検索
- JuliaHubによるコード検索

## 詳細をもう少し解説

パッケージ開発中に「この関数は他のパッケージでどう使われているか」を知りたくなることがあります。
そんなときに便利なのがコード検索です。

### GitHub上のコード検索

多くのJuliaパッケージがGitHubにホストされているので、GitHubのコード検索が使えます。
[GitHub Code Search](https://github.com/search?type=code)にアクセスして、言語をJuliaに限定して検索すれば効率的です。

例えば`DocMeta.setdocmeta!`の使用例を探したい場合は以下のように入力します。

```
DocMeta.setdocmeta! language:Julia
```

他にも以下のような検索オプションが便利です:

| 検索条件 | 検索コマンド |
| :-- | :-- |
| 特定のディレクトリ内に限定 | `using Documenter path:docs/ language:Julia` |
| 特定のファイル名を指定 | `makedocs path:**/make.jl language:Julia` |
| 特定の組織/ユーザーのリポジトリに限定 | `@assert org:JuliaLang language:Julia` |
| ファイル拡張子で絞り込み | `struct path:*.jl` |

### JuliaHubによるコード検索

[JuliaHubのコード検索](https://juliahub.com/ui/Search?type=code)も便利です。

こちらにはGitHubのコード検索に比べて以下のようなメリットがあります:

- [General](https://github.com/JuliaRegistries/General)に登録済みパッケージに限定されるのでコード品質が多少は期待できる
- Julia言語に特化した検索機能が利用可能
- GitHubだけでなくGitLabなどの他のホスティングサービスも検索対象になる

特に開発者の立場からは以下のような場面で便利です。

- 新しくexportする識別子が他のパッケージと重複していないか確認したい
- 自分のメンテナンス中のパッケージの機能を廃止する際に与える、他のパッケージへの影響を確認したい

# おわりに
- 他にTipsあればコメントで教えてください！[^owarini]
- 本文では触れませんでしたが、[Modern Julia Workflows](https://modernjuliaworkflows.org/)にはJulia言語のtipsが体系的に整理されているのでオススメです。
- 質問あれば、本記事へのコメントでも[JuliaLangJa](https://julialangja.github.io/)のDiscordでの投稿でもOKです！

[^owarini]: 私はプロファイリングとかデバッグなどにあまり詳しくなく、その辺りのことは本記事で書いてませんでした。
