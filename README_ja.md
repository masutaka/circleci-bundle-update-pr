# Circleci::Bundle::Update::Pr

[![CircleCI Status](https://img.shields.io/circleci/build/github/masutaka/circleci-bundle-update-pr/main?style=flat-square&logo=circieci&label=CircleCI)][circleci]
[![CI](https://github.com/masutaka/circleci-bundle-update-pr/actions/workflows/ci.yml/badge.svg?branch=main)][ci]
[![Schedule](https://github.com/masutaka/circleci-bundle-update-pr/actions/workflows/schedule.yml/badge.svg?branch=main)][schedule]
[![Gem Version](https://img.shields.io/gem/v/circleci-bundle-update-pr?style=flat-square&logo=rubygems&label=Gem)][gem]
[![Ask DeepWiki](https://deepwiki.com/badge.svg)][deepwiki]

[circleci]: https://app.circleci.com/pipelines/github/masutaka/circleci-bundle-update-pr?branch=main
[ci]: https://github.com/masutaka/circleci-bundle-update-pr/actions/workflows/ci.yml?query=branch%3Amain
[schedule]: https://github.com/masutaka/circleci-bundle-update-pr/actions/workflows/schedule.yml?query=branch%3Amain
[gem]: https://rubygems.org/gems/circleci-bundle-update-pr
[deepwiki]: https://deepwiki.com/masutaka/circleci-bundle-update-pr

<p>
  <a href="./README.md"><img alt="README in English" src="https://img.shields.io/badge/English-d9d9d9"></a>
  <a href="./README_ja.md"><img alt="日本語のREADME" src="https://img.shields.io/badge/日本語-d9d9d9"></a>
</p>

`circleci-bundle-update-pr` は、[CircleCI のスケジュール実行](https://circleci.com/docs/2.0/workflows/#scheduling-a-workflow)を使って bundle update を定期的に行い、Pull Request を作成するスクリプトです。

`circle.yml` または `.circleci/config.yml` に設定しておくと、CircleCI の定期ビルドで bundle update が実行されます。変更があればコミットし、GitHub のリポジトリに Pull Request を送ります。

## インストール

```
$ gem install circleci-bundle-update-pr
```

## 前提条件

bundle update を定期実行したいアプリケーションが、CircleCI でビルドできるようになっている必要があります。

## 使い方

### GitHub の fine-grained personal access token を CircleCI に設定する

リポジトリに Pull Request を送るには、GitHub の fine-grained personal access token が必要です。

1. [アカウントの設定ページ](https://github.com/settings/personal-access-tokens/new)で fine-grained personal access token を作成する
    * Repository access: 対象のリポジトリを選択
    * Repository permissions:
        * Contents: Read and write
        * Pull requests: Read and write
2. CircleCI のダッシュボードで、アプリケーションの "Project Settings" -> "Environment Variables" を開く
3. 環境変数 `GITHUB_ACCESS_TOKEN` に、作成した fine-grained personal access token を設定する
    * GitHub Enterprise を使う場合
        * `ENTERPRISE_OCTOKIT_ACCESS_TOKEN` に GitHub Enterprise の fine-grained personal access token を設定する
        * `ENTERPRISE_OCTOKIT_API_ENDPOINT` に GitHub Enterprise の API エンドポイントを設定する（例: https://www.example.com/api/v3）

### circle.yml を設定する

`circle.yml` または `.circleci/config.yml` に、`circleci-bundle-update-pr` を実行する設定を追加します。例:

```yaml
version: 2
jobs:
  build:
    # snip
  continuous_bundle_update:
    docker:
      - image: ruby:3.0.1-alpine
    working_directory: /work
    steps:
      - run:
          name: Install System Dependencies
          command: |
            # See also https://circleci.com/docs/2.0/custom-images/#required-tools-for-primary-containers
            apk add --update --no-cache git openssh-client tar gzip ca-certificates \
              tzdata
            gem install -N bundler
      - run:
          name: Set timezone to Asia/Tokyo
          command: cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
      - checkout
      - restore_cache:
          name: Restore bundler cache
          keys:
            - gems-{{ .Environment.COMMON_CACHE_KEY }}-{{ checksum "Gemfile.lock" }}
            - gems-{{ .Environment.COMMON_CACHE_KEY }}-
      - run:
          name: Setup requirements for continuous bundle update
          command: gem install -N circleci-bundle-update-pr
      - deploy:
          name: Continuous bundle update
          command: circleci-bundle-update-pr <username> <email>

workflows:
  version: 2
  build:
    jobs:
      - build:
          # snip
  nightly:
    triggers:
      - schedule:
          cron: "00 10 * * 5"
          filters:
            branches:
              only: main
    jobs:
      - continuous_bundle_update
```

NOTE: `<username>` と `<email>` は自分のものに置き換えてください。

`circleci-bundle-update-pr` 自身も、このスクリプトで定期的に更新しています。[.circleci/config.yml](.circleci/config.yml) も参考にしてください。

## CLI コマンドリファレンス

基本的な使い方:

```
$ circleci-bundle-update-pr <git username> <git email address>
```

デフォルトでは master と main ブランチでのみ動作します。引数にブランチを追加すると、それ以外のブランチでも動作します。

```
$ circleci-bundle-update-pr <git username> <git email address> main develop topic
```

次のオプションも使えます。

```
$ circleci-bundle-update-pr -h
Usage: circleci-bundle-update-pr [options]
    -a, --assignees alice,bob,carol  Assign the PR to them
    -r, --reviewers alice,bob,carol  Request PR review to them
    -l, --labels "In Review, Update" Add labels to the PR
    -d, --duplicate                  Make PR even if it has already existed
```

## Tips

### PR の説明文をカスタマイズする

`.circleci/BUNDLE_UPDATE_NOTE.md` があると、その内容が PR の説明文の末尾に追加されます。

たとえば `.circleci/BUNDLE_UPDATE_NOTE.md` が次の内容だとします。

```
## Notice

* example1
* example2
```

PR の説明文は次のようになります。

```
**Updated RubyGems:**

* [ ] [octokit](https://github.com/octokit/octokit.rb): [`4.9.0...4.10.0`](https://github.com/octokit/octokit.rb/compare/v4.9.0...v4.10.0)
* [ ] [public_suffix](https://github.com/weppos/publicsuffix-ruby): [`3.0.2...3.0.3`](https://github.com/weppos/publicsuffix-ruby/compare/v3.0.2...v3.0.3)

Powered by [circleci-bundle-update-pr](https://rubygems.org/gems/circleci-bundle-update-pr)

---

## Notice

* example1
* example2
```

ファイル名は `.circleci/BUNDLE_UPDATE_NOTE.md` と `CIRCLECI_BUNDLE_UPDATE_NOTE.md` のどちらでも構いません。両方ある場合は `.circleci/BUNDLE_UPDATE_NOTE.md` が優先されます。

### GitHub Actions で実行する

> [!WARNING]
> GitHub Actions は公式にはサポートしていません。あくまで Tips です。

`.github/workflows/bundle-update-pr.yml` に、circleci-bundle-update-pr を実行する設定を追加します。例:

```yaml
name: bundle-update-pr

on:
  schedule:
    - cron: "00 10 * * 5" # JST 19:00 (Fri)

jobs:
  build:
    runs-on: ubuntu-latest

    permissions:
      contents: write
      pull-requests: write

    steps:
      - uses: actions/checkout@v7

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '4.0'

      - name: Install dependencies
        run: |
          set -x
          gem install -N bundler circleci-bundle-update-pr

      - name: Set timezone to Asia/Tokyo
        run: |
          set -x
          cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

      - name: run circleci-bundle-update-pr
        run: |
          set -x

          export CIRCLE_BRANCH=$(echo $GITHUB_REF | sed -e 's!refs/heads/!!g')
          export CIRCLE_PROJECT_USERNAME=$(echo $GITHUB_REPOSITORY | cut -d "/" -f 1)
          export CIRCLE_PROJECT_REPONAME=$(echo $GITHUB_REPOSITORY | cut -d "/" -f 2)

          git checkout -b $CIRCLE_BRANCH

          circleci-bundle-update-pr "${GIT_USER_NAME}" "${GIT_USER_EMAIL}"
        env:
          GITHUB_ACCESS_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          GIT_USER_NAME:       "your name"
          GIT_USER_EMAIL:      "ci@example.com"
```

## コントリビューション

1. フォークする ( https://github.com/masutaka/circleci-bundle-update-pr/fork )
2. フィーチャーブランチを作成する (`git checkout -b my-new-feature`)
3. 変更をコミットする (`git commit -am 'Add some feature'`)
4. ブランチにプッシュする (`git push origin my-new-feature`)
5. Pull Request を作成する

## コントリビューターの皆さん

<a href="https://github.com/masutaka/circleci-bundle-update-pr/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=masutaka/circleci-bundle-update-pr" />
</a>

*[contrib.rocks](https://contrib.rocks) で作成。*
