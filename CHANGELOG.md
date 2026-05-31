# Changelog

Mọi thay đổi đáng chú ý của repo **Agent Team** (workflow **Làm Mướn Team** / `lammuon-team`) được ghi tại đây.

Định dạng dựa trên [Keep a Changelog](https://keepachangelog.com/vi/1.1.0/).

## [Unreleased]

---

## [0.3.2] - 2026-05-31

### Added

- **Claude Code global install**: `--global claude` và `--global all` cài `~/.claude/skills/lammuon-team/` (skill + references agents/rules).

### Changed

- README rút gọn: 1 lệnh global (Mac/Win) cho Cursor + Codex + Claude; project install tách mục riêng.

---

## [0.3.1] - 2026-05-31

### Added

- **`lammuon-preflight.mdc`**: rule always-on ngắn — ép Router header + Flow + Test Case Gate (`TC-001`…) trước side effect; fail-fast `⛔ Test Case Gate blocked`.
- **HARD STARTUP CHECKLIST** trong `lammuon-team.md` (slash command chắc load agent file).

### Changed

- `lammuon-guardrails`: activation trỏ preflight trước khi nạp router dài.
- `lammuon-router` rule map: ghi `lammuon-preflight` always-on.
- README + `install.sh` / `install.ps1`: cảnh báo rõ global chỉ cài agents, không cài rules; hướng dẫn verify `.cursor/rules`.

---

## [0.3.0] - 2026-05-29

### Added

- **Environment scan gate** (BẮT BUỘC đầu phiên): agent scan MCP đang bật + Skills khả dụng, khai báo ở khối `## 🔌 Tooling` trong Router header.
- **Capability Tiers** trong `lammuon-tooling`: Tier 0 (code + shell + curl + unit test) luôn có; Tier 1 (Playwright E2E, DB read-first, agentmemory, sequential-thinking) khi có MCP.
- **Request Missing MCP**: agent chủ động đề xuất bổ sung MCP (nêu tên server + lý do + fallback Tier 0) khi MCP có ích nhưng chưa bật.
- **Context Enrichment qua MCP**: task đụng DB/data phải đọc code + đọc data thật read-first (schema, sample rows, phân bố giá trị, filter tenant/Site) rồi đối chiếu trước khi kết luận root cause / thiết kế fix.

### Changed

- `lammuon-router`: thêm khối `## 🔌 Tooling` vào Mandatory Response Header và bước scan môi trường vào Final Router Algorithm.
- `lammuon-team`: thêm Environment scan gate, nhắc tận dụng MCP/Skills và đề xuất bổ sung MCP.
- `lammuon-tester` / `lammuon-senior-dev`: bắt buộc đọc data thật qua DB MCP (read-first) để đủ ngữ cảnh khi đụng DB/data, không suy đoán chỉ từ code.
- Codex skill `SKILL.md`: mirror env scan + tiers + request MCP + context enrichment.

---

## [0.2.2] - 2026-05-29

### Added

- Agent **`lammuon-tester-team`** (alias `tester-team`) cho luồng QA-only: `BA -> Tester`.
- Router hỗ trợ **Tester Team**: BA đọc hiểu tính năng/AC, Tester viết scenario detail theo `templates/Detail.md`, merge `templates/Test Summary.md`, rồi mới viết/chạy Unit Test/E2E.
- Bộ template scenario-first cho QA:
  - `templates/Detail.md`: template detail cho từng tính năng.
  - `templates/detail_exam.md`: ví dụ detail thực tế để agent bám mức chi tiết.
  - `templates/Test Summary.md`: template tổng hợp nhiều detail.

### Changed

- Cập nhật `lammuon-team`, `lammuon-router`, README và Codex skill để nhận diện Tester Team, không kéo Senior Dev vào task test-only.
- Cập nhật `lammuon-tester` và `lammuon-testing` để bắt buộc đọc hiểu tính năng, hỏi BA khi chưa rõ, viết scenario detail trước rồi mới viết/chạy Unit Test/E2E Playwright.
- Cập nhật `lammuon-ba` để tham gia Tester Team và làm rõ behavior/business rule/acceptance criteria trước bước Tester.

---

## [0.2.0] - 2026-05-29

### Added

- File `VERSION` (semver, single source of truth).
- Banner ASCII **LÀM MƯỚN TEAM** khi gọi `/lammuon-team` — in **một lần mỗi session**; kèm dòng `v0.2.0` dưới tên team.
- File `CHANGELOG.md`.

### Changed

- Đổi tên hiển thị **lammuon team** / **lammuon-team** → **Làm Mướn Team** (in đậm) trên toàn bộ agents, rules, README và Codex skill.
- Giữ nguyên định danh kỹ thuật: `name: lammuon-team`, slash `/lammuon-team`, tên file `lammuon-*.md(c)`.
- Greeting mẫu: *Em là team **Làm Mướn** (v0.2.0)*.

---

## [2026-05-29]

### Added

- Agent router **`lammuon-team`** (orchestrator Small / Medium / Large Team).
- Script cài đặt Windows: `scripts/install.ps1`.
- Hướng dẫn cài Cursor + Codex trong `README.md`.
- Quy tắc **Tester tự chạy test** (bắt buộc):
  - UI/flow → Playwright MCP `user-playwright`
  - API → `curl` (Shell)
  - DB → MCP read-first (`user-mssql` / `user-mongodb`)
- Mục **Execution Mandate** trong `lammuon-testing.mdc`.
- Mục **Quy tắc TỰ CHẠY TEST** trong `lammuon-tester.md`.
- Fallback khi thiếu tool: template `## Test Execution Limitation` (không khai pass nếu chưa chạy).

### Changed

- Chuẩn hóa output template Small/Medium (`lammuon-templates.mdc`).
- Làm rõ SpecKit chỉ cho Large Team (`lammuon-speckit.mdc`).
- Sửa format test case / markdown trong `lammuon-testing.mdc`.
- Chuẩn hoá browser MCP → `user-playwright` trong `lammuon-tooling.mdc`.
- Cập nhật agents: model, handoff, SpecKit reference, guardrails.
- `README.md`: cấu trúc repo, agent/rule map, ví dụ slash command.

### Fixed

- Formatting / nhất quán tài liệu giữa `lammuon-speckit`, `lammuon-testing`, `lammuon-tooling`.

---

## [2026-05-29] — Khởi tạo

### Added

- Cấu trúc project: `.cursor/agents`, `.cursor/rules`, `scripts/`, `codex/skills/`.
- Agents: `lammuon-pm`, `lammuon-ba`, `lammuon-tester`, `lammuon-senior-dev`, `test`.
- Rules: `lammuon-guardrails`, `lammuon-guardrails-detail`, `lammuon-router`, `lammuon-templates`, `lammuon-speckit`, `lammuon-testing`, `lammuon-tooling`.
- Script `scripts/install.sh`, `scripts/check-rules.py`.
- Codex skill `codex/skills/lammuon-team/SKILL.md`.
- `README.md`, `.gitattributes`.
