---
title: "Juliaパッケージのバージョン管理方法"
emoji: "✌️"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: []
published: false
---


* 破壊的変更とは何か
* Semantic versioningとは何か
* CompatHelper.jlの仕事
* どのタイミングでリリースするべきか
* どのタイミングでPRを使った開発に移行するべきか
* 個人的に採用しているリリースの目安
    * `0.0.X`: 開発初期のリリース
    * `0.1.0`: JuliaのGeneral Registryに登録するときにつけるバージョン
    * `0.X.Y`: 開発中のバージョン
    * `1.0.0`: APIが安定したときに打つバージョン
    * `X.Y.Z`: 開発を更に続けるときのバージョン
