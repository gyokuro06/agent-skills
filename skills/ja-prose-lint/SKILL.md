---
name: ja-prose-lint
description: >
  Use when the user explicitly asks to lint, proofread, or check Japanese prose
  readability（日本語校正、地の文チェック、直訳調チェック、読みにくさ判定）.
  Judges whether natural Japanese prose is hard to read (literal English calque
  or overly complex structure) and returns only OK or NG. Prefer the
  `ja-prose-lint` subagent (haiku / weak model). Do not use proactively, for
  code review, for rewriting text, or for non-Japanese content.
metadata:
  origin: gyokuro06-agent-skills
  tags: workflow, japanese, prose, lint, readability
---

# Japanese Prose Lint

判定専用。書き換え・要約・解説はしない。入力は親が渡したテキスト（または指定ファイルの地の文）のみ。

This skill is the **canonical playbook** for agent `ja-prose-lint`. Keep the agent thin; tune criteria here.

## Process

1. 入力から**判定対象外**を除く: コードブロック、識別子、コマンド引数、URL、ファイルパス、他人の発言・issue 引用と分かる部分
2. 残った**自然文**（説明文・issue 本文・コミットメッセージ等）だけを見る
3. 次のいずれかに当てはまるか判定する（迷ったら指摘＝過検知側）:
   - **直訳調**: 語彙・構文が英語の逐語訳で不自然
   - **構造が複雑**: 一度読んだだけでは意味が取れない（読点だけで複数主張を繋ぐ・長い修飾節の入れ子など）
4. 開発分野で定着したカタカナ（ハンドリング、コンポーネント、デプロイ、ログ等）は不自然としない
5. 下記の出力契約だけを返す

## Output contract

- 該当なし → 一行だけ: `OK`
- 該当あり → 一行だけ: `NG: <具体的な理由>`
- それ以外は一切出力しない（前置き・引用・修正案・空行なし）

複数箇所あっても **NG は一行**にまとめ、理由を簡潔に列挙してよい。

## Examples

### PASS → `OK`

```text
Gauge シナリオを先に書いて Red を確認してから、最小実装で Green にする。
```

```text
デプロイ後にログを確認し、コンポーネントのハンドリングを見直す。
```

### FAIL → `NG: …`

```text
それはユーザーによってリクエストされた機能が実装されるべきであるということに関して考慮される必要がある。
```

→ `NG: 英語直訳調の長い名詞句で、一度では意味が取りにくい`

```text
設定を変え、依存を更新し、テストを直し、ドキュメントも書き、レビューを依頼し、マージする手順を、環境ごとに分岐させつつ、失敗時はロールバックを含む形で、一つの文にまとめた。
```

→ `NG: 読点と修飾の入れ子で主張が多すぎて一読では構造が追えない`

## Anti-patterns

- プロアクティブ起動（ユーザーが校正・チェックを頼んでいない）
- コードや識別子を「カタカナが無い」等で NG にする
- 定着カタカナ用語を直訳調扱いする
- `OK`/`NG:` 以外の文を足す（「以下を修正すると」等）
- 判定と同時にリライト案を出す（親が必要なら別ターン）

## Related skills

- `scored-review` — 実装の定性レビュー。日本語地の文の読みやすさ判定には使わない
