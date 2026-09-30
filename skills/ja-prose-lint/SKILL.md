---
name: ja-prose-lint
description: >
  Use when the user explicitly asks to lint, proofread, or check Japanese prose
  readability（日本語校正、地の文チェック、直訳調チェック、読みにくさ判定）.
  Judges whether natural Japanese prose is hard to read (literal English calque
  or overly complex structure); on NG, also suggests concrete local rewrites.
  Prefer the `ja-prose-lint` subagent (haiku / weak model). Do not use
  proactively, for code review, or for non-Japanese content.
metadata:
  origin: gyokuro06-agent-skills
  tags: workflow, japanese, prose, lint, readability
---

# Japanese Prose Lint

判定＋局所修正案。全文の要約や解説エッセイはしない。入力は親が渡したテキスト（または指定ファイルの地の文）のみ。

This skill is the **canonical playbook** for agent `ja-prose-lint`. Keep the agent thin; tune criteria here.

## Process

1. 入力から**判定対象外**を除く: コードブロック、識別子、コマンド引数、URL、ファイルパス、他人の発言・issue 引用と分かる部分
2. 残った**自然文**（説明文・issue 本文・コミットメッセージ等）だけを見る
3. 次のいずれかに当てはまるか判定する（迷ったら指摘＝過検知側）:
   - **直訳調**: 語彙・構文が英語の逐語訳で不自然
   - **構造が複雑**: 一度読んだだけでは意味が取れない（読点だけで複数主張を繋ぐ・長い修飾節の入れ子など）
4. 開発分野で定着したカタカナ（ハンドリング、コンポーネント、デプロイ、ログ等）は不自然としない
5. NG のとき、問題箇所ごとに**原文の抜粋 → 直し方**を付ける
6. 下記の出力契約だけを返す

## Output contract

- 該当なし → 一行だけ: `OK`
- 該当あり → 次の形のみ（前置き・空行・契約外の解説なし）:

```text
NG: <具体的な理由（複数あれば簡潔に列挙）>
- 「<問題の原文抜粋>」→「<直し方（置換文または分割後の文）>」
```

- 指摘箇所が複数なら `- 「…」→「…」` を必要なだけ続ける
- 原文抜粋は短く（一文〜一文の核）。直し方は意味を変えず読みやすくする。全文の別稿は出さない

## Examples

### PASS → `OK`

```text
Gauge シナリオを先に書いて Red を確認してから、最小実装で Green にする。
```

```text
デプロイ後にログを確認し、コンポーネントのハンドリングを見直す。
```

### FAIL → `NG` + 局所修正

```text
それはユーザーによってリクエストされた機能が実装されるべきであるということに関して考慮される必要がある。
```

```text
NG: 英語直訳調の長い名詞句で、一度では意味が取りにくい
- 「それはユーザーによってリクエストされた機能が実装されるべきであるということに関して考慮される必要がある。」→「ユーザーが依頼した機能を実装すべきか、検討する必要がある。」
```

```text
設定を変え、依存を更新し、テストを直し、ドキュメントも書き、レビューを依頼し、マージする手順を、環境ごとに分岐させつつ、失敗時はロールバックを含む形で、一つの文にまとめた。
```

```text
NG: 読点と修飾の入れ子で主張が多すぎて一読では構造が追えない
- 「設定を変え、依存を更新し、…一つの文にまとめた。」→「設定変更・依存更新・テスト修正・ドキュメント更新・レビュー依頼・マージを、環境ごとに分岐した手順にまとめた。失敗時はロールバックも含める。」
```

## Anti-patterns

- プロアクティブ起動（ユーザーが校正・チェックを頼んでいない）
- コードや識別子を「カタカナが無い」等で NG にする
- 定着カタカナ用語を直訳調扱いする
- `OK` なのに修正案や解説を足す
- NG なのに `- 「…」→「…」` を付けない（理由だけ）
- 全文の別稿や「以下のように書き換えると良いです」などの契約外文

## Related skills

- `scored-review` — 実装の定性レビュー。日本語地の文の読みやすさ判定には使わない
