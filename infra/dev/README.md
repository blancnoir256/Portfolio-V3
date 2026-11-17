# manifest用の開発環境

Traefikの公式CRDからJSON Schemaを生成します。
生成したスキーマは、manifestの隣の`.crd/`に配置します。
NeovimのYAML Language Serverは、YAML先頭のコメントで参照先を選びます。

## セットアップ

`infra/manifest/`で実行します。

```sh
cd infra/manifest
nix develop path:../dev
```

開発シェルに入ると、`.crd/`が作成・更新されます。
シェルを開かず、セットアップだけを行うこともできます。

```sh
nix run path:../dev#setup-crd
```

プロジェクトのルートから実行する場合は、生成先を指定します。

```sh
nix run path:./infra/dev#setup-crd -- ./infra/manifest
```

初回はNixの依存パッケージと公式CRDの取得に通信が必要です。
Linuxのx86_64・aarch64と、macOSのaarch64を定義しています。
Nixとflakesが利用できる環境を前提とします。

## Neovimからの参照

`ingress.yaml`の先頭に、次のコメントを指定しています。
相対パスの基準は、そのYAMLファイルのあるディレクトリです。

```yaml
# yaml-language-server: $schema=.crd/traefik.io-ingressroute-v1alpha1.json
```

この指定には、ホスト固有のパスやdotfilesのプロジェクト登録は不要です。
Neovim側ではYAML Language ServerとLSP補完が有効である必要があります。
セットアップ後も候補が出ない場合は、YAMLを開き直してください。

## 固定している情報と更新

- `flake.lock`：nixpkgsと、それに含まれるPython・PyYAMLなどを固定します。
- `crd-schemas.nix`：Traefik v3.6.25の公式CRDと、kubeconform v0.8.0の変換スクリプトをURL・SHA-256で固定します。
- `../manifest/.gitignore`：生成した`.crd/`をGitの管理対象から外します。

Traefikは3.6系という申告に合わせています。
配置先クラスタの正確なパッチ番号と、登録済みCRDの版は未確認です。
必要に応じて`traefikVersion`を合わせ、取得ファイルのハッシュも更新してください。
`apiVersion`が同じでも、製品バージョンによってフィールドが変わる場合があります。

```sh
# Run in infra/dev.
traefik_version=3.6.25
nix store prefetch-file --json \
  "https://raw.githubusercontent.com/traefik/traefik/v${traefik_version}/docs/content/reference/dynamic-configuration/kubernetes-crd-definition-v1.yml"
nix flake check path:.
```

`.crd/`は再生成できるローカルのキャッシュです。
スキーマを更新したらセットアップを再実行し、YAMLを開き直してください。
上記のコマンドでは、`path:`指定でflakeの入力を`infra/dev/`内に限定します。
`infra/manifest/secrets/`は入力に含めません。

## ファイルの役割

- `flake.nix`：パッケージ、セットアップコマンド、開発シェル、検証を公開します。
- `crd-schemas.nix`：公式CRDの取得とJSON Schemaへの変換を担当します。
- `setup-crd.sh`：生成済みスキーマを指定したmanifestディレクトリへ配置します。

公式資料：
[Traefik 3.6のCRD](https://doc.traefik.io/traefik/v3.6/reference/install-configuration/providers/kubernetes/kubernetes-crd/)、
[変換スクリプト](https://github.com/yannh/kubeconform/blob/v0.8.0/scripts/openapi2jsonschema.py)、
[YAML Language Serverのスキーマ指定](https://github.com/redhat-developer/yaml-language-server/blob/2.0.0/README.md#using-a-modeline)。
