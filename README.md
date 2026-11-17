# BN256のポートフォリオサイトV3

## 状況

誠意開発中

## 内容

### infra

V2から進化してTLS証明書をCertmanagerで取得することにしました。
CloudflareのOrigin CA証明書も良かったけどいちいちGUIポチポチするのが少し面倒だったので導入しました。
いずれExternal DNSも導入して完全にIaCできるといいなと思っています。

labelの使い方とかもだいぶマシになったのではないかなと思います。
唯一nvimの補完のためにcrdをDLする部分のflakeだけGPT-6.1 Sol君に書いてもらいました。

ArgoCDによるCI/CDは未実装です。
FluxCDを使うかもしれません。

### app

未着手
無限の可能性
