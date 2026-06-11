---
description: "Health check for the dev environment and solana-ai-kit config — read-only, with one exact fix-it command per failure"
---

You are running a health check on this project's toolchain and solana-ai-kit configuration. **Read-only contract: this command never writes, edits, or deletes files.** It only inspects and reports.

## Related Commands

- [setup-mcp.md](setup-mcp.md) — fix missing MCP API keys
- [update.md](update.md) — update config to latest upstream
- [resync.md](resync.md) — resync external skill submodules

## Check 1: Core Toolchain

```bash
node --version 2>/dev/null || echo "MISSING node"
npm --version 2>/dev/null || echo "MISSING npm"
claude --version 2>/dev/null || echo "MISSING claude CLI"
```

- ✓ `node` ≥ 18, `npm`, `claude` all present
- ✗ Missing → fix-it: `brew install node` / `npm install -g @anthropic-ai/claude-code`

## Check 2: Solana CLI + Cluster

```bash
solana --version 2>/dev/null || echo "MISSING solana CLI"
solana config get 2>/dev/null | grep "RPC URL"        # active cluster
solana balance --url devnet 2>/dev/null || echo "NO devnet balance / no keypair"
```

- ✓ CLI installed, cluster configured, devnet balance > 0
- ! Devnet balance 0 → fix-it: `solana airdrop 2 --url devnet`
- ! Cluster is mainnet during development → fix-it: `solana config set --url devnet`
- ✗ No CLI → fix-it: `sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)"`

## Check 3: Rust / Anchor Toolchain

Only flag as ✗ if the project contains Rust programs (`Anchor.toml` or `programs/` present); otherwise report `-` (n/a).

```bash
rustc --version 2>/dev/null || echo "MISSING rustc"
cargo --version 2>/dev/null || echo "MISSING cargo"
anchor --version 2>/dev/null || echo "MISSING anchor"
avm --version 2>/dev/null || echo "MISSING avm"
```

- ✗ No rustc/cargo → fix-it: `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`
- ✗ No anchor → fix-it: `cargo install --git https://github.com/coral-xyz/anchor avm --force && avm install latest && avm use latest`
- ! `anchor --version` ≠ `Anchor.toml` `anchor_version` → fix-it: `avm use <version>`

## Check 4: Git Submodules

```bash
git submodule status
```

- ✓ Every line starts with a SHA (space or `+` prefix)
- ✗ Any line with a `-` prefix = uninitialized submodule → fix-it: `git submodule update --init --recursive`
- ! `+` prefix = checked-out commit differs from recorded SHA → fix-it: `git submodule update --recursive` (or `/resync` if intentional)

## Check 5: Environment Keys

Compare key **names** between `.env.example` and `.env`. **NEVER print, echo, or display values — names only.**

```bash
# Key names present in example but absent in .env (presence check only)
comm -23 \
  <(grep -oE '^[A-Z_]+=' .env.example 2>/dev/null | sort -u) \
  <(grep -oE '^[A-Z_]+=' .env 2>/dev/null | sort -u)
# Keys present but left empty in .env
grep -E '^[A-Z_]+=$' .env 2>/dev/null | cut -d= -f1
```

- ✓ All `.env.example` keys exist in `.env` with non-empty values
- ! Key missing or empty → fix-it: `/setup-mcp` (for MCP keys) or edit `.env` manually
- ✗ No `.env` at all → fix-it: `cp .env.example .env` then `/setup-mcp`

## Check 6: Config Version vs Upstream

```bash
cat .claude/VERSION
git ls-remote --tags --sort=-v:refname https://github.com/solanabr/solana-ai-kit | head -3
```

- ✓ Local version matches latest upstream tag
- ! Behind upstream → fix-it: `bash .claude/bin/update.sh` (preview first: `bash .claude/bin/update.sh --dry-run`)
- ✗ No `.claude/VERSION` → config is corrupted or pre-1.0 → fix-it: `bash .claude/bin/update.sh`

## Check 7: MCP Configuration

```bash
python3 -c "import json; d=json.load(open('.mcp.json')); print('\n'.join(d.get('mcpServers', {}).keys()))" \
  2>/dev/null || echo "INVALID or missing .mcp.json"
```

- ✓ `.mcp.json` parses; expected servers listed (helius, solana-dev, context7, playwright, ...)
- ✗ Parse failure → fix-it: `bash .claude/bin/update.sh` (restores stock `.mcp.json`)
- ! Server listed but its API key failed Check 5 → fix-it: `/setup-mcp`

## Output

Render exactly one summary table, then fix-its for non-✓ rows only:

```
## Doctor Report — <date>

| # | Check              | Status | Detail                          |
|---|--------------------|--------|---------------------------------|
| 1 | Core toolchain     | ✓      | node 22.x, npm 10.x, claude 2.x |
| 2 | Solana CLI         | !      | cluster=mainnet, devnet bal 0   |
| 3 | Rust/Anchor        | ✓      | anchor 0.31.1 = Anchor.toml     |
| 4 | Submodules         | ✗      | 2 uninitialized (-)             |
| 5 | .env keys          | !      | HELIUS_API_KEY empty            |
| 6 | Config version     | ✓      | 1.5.0 = upstream                |
| 7 | MCP config         | ✓      | 6 servers parsed                |

### Fix-its (run in order)
1. `git submodule update --init --recursive`
2. `/setup-mcp`
3. `solana airdrop 2 --url devnet`
```

Legend: ✓ healthy · ! degraded (works, but fix soon) · ✗ broken (blocks workflows) · - n/a.

## Guardrails

- Never write files — report only. If a fix-it would modify state, print it for the user to run.
- Never print `.env` values, keypair contents, or anything matching a secret pattern.
- Network access limited to read-only lookups (`git ls-remote`, `solana balance`). Never airdrop, deploy, or send transactions on the user's behalf.
- If a check errors unexpectedly, mark it `!` with the error one-liner — don't abort the remaining checks.
