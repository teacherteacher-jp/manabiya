# ティーチャーティーチャーの学び舎

さまざまな便利機能を実装していく予定

# インストール・起動

## credentialsの設定

clone したら以下のファイルを作成して、keyを入力。keyの値は @juneboku か @Saki-htr に聞きましょう。

- config/master.key
- config/credentials/development.key


## セットアップ・起動

```
# セットアップ
$ bin/setup

# 起動
$ bin/dev 
```
http://localhost:3000 にアクセス。

## バックグラウンドジョブ

このアプリケーションはバックグラウンドジョブの処理にSolid Queueを使用しています。ジョブワーカーを起動するには：

```
$ bin/solid_queue
```

以下の環境変数で、ワーカー数とポーリング間隔を設定できます：
- SOLID_QUEUE_CONCURRENCY (デフォルト: 5)
- SOLID_QUEUE_POLLING_INTERVAL (デフォルト: 0.1)
