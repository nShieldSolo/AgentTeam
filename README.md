# Agent Team — **Làm Mướn Team**

**Phiên bản:** `0.3.2` · [CHANGELOG](CHANGELOG.md)

Workflow PM / BA / Tester / Senior Dev cho Cursor, Codex và Claude Code — test case trước khi sửa code, build gate trước khi báo xong.

---

## Cài global (Cursor + Codex + Claude) — 1 lệnh

Cài **subagents Cursor** + **skill Codex** + **skill Claude Code**. Chạy lại lệnh để update.

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/nShieldSolo/AgentTeam/main/scripts/install.sh | bash -s -- --global all
```

### Windows (PowerShell)

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/nShieldSolo/AgentTeam/main/scripts/install.ps1'))) -Mode all"
```

| Tool | Sau khi cài |
|------|-------------|
| **Cursor** | `~/.cursor/agents/lammuon-*.md` → gõ `/lam` → **Làm Mướn Team** |
| **Codex** | `~/.codex/skills/lammuon-team/` → skill `lammuon-team` |
| **Claude Code** | `~/.claude/skills/lammuon-team/` → `/lammuon-team` |

Reload app sau khi cài (Cursor: reload window; Codex/Claude: thoát hẳn rồi mở lại).

---

## Cài vào project (Cursor rules — bắt buộc nếu cần gate cứng)

Global **không** copy `.cursor/rules` (preflight, router, testing…). Mỗi repo làm việc chạy **project install** một lần:

**macOS / Linux**

```bash
curl -fsSL https://raw.githubusercontent.com/nShieldSolo/AgentTeam/main/scripts/install.sh | bash
```

**Windows**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/nShieldSolo/AgentTeam/main/scripts/install.ps1 | iex"
```

Project khác: thêm path — Mac `bash -s -- /path/to/project` · Win `-ProjectPath 'C:\path\to\project'`.

---

## Dùng nhanh

```text
/lammuon-team xử lý bug này theo Làm Mướn Team
```

Phản hồi đầu phải có Router + Flow; trước khi sửa file phải có `TC-001`, `TC-002`, …

---

## Chi tiết / bảo trì

- Cấu trúc repo, flow team, rule map: xem source trong [`.cursor/`](.cursor/) và [`CHANGELOG.md`](CHANGELOG.md).
- Smoke test rule: `py -3 scripts/check-rules.py` (từ clone repo).
