# Agent Team

**Phiên bản:** `0.3.1` (xem [`VERSION`](VERSION), lịch sử tại [`CHANGELOG.md`](CHANGELOG.md))

Repo này chưa có code ứng dụng. Đây là bộ cấu hình Cursor cho **Làm Mướn Team**: một workflow dùng nhiều vai trò AI để phân tích, code và verify task một cách có kiểm soát.

## Mục tiêu

- Chọn team nhỏ nhất có thể hoàn thành task an toàn.
- Tách rõ vai trò: PM, BA, Tester, Senior Developer.
- Hỗ trợ **Tester Team** cho luồng chỉ BA + Tester: BA đọc hiểu tính năng, Tester viết scenario rồi test.
- Chuẩn hóa cách agent giao tiếp, bàn giao và báo cáo tiến độ.
- Bắt buộc test case tiếng Việt và không khai test pass nếu chưa chạy.
- Bắt buộc build FE/BE tương ứng sau mọi thay đổi code/config trước khi báo hoàn thành.
- Giữ guardrail an toàn cho git, file, package, DB, API và infra.

## Cấu trúc

```text
.cursor/
  agents/
    lammuon-team.md
    lammuon-tester-team.md
    lammuon-pm.md
    lammuon-ba.md
    lammuon-tester.md
    lammuon-senior-dev.md
  rules/
    lammuon-guardrails.mdc
    lammuon-preflight.mdc
    lammuon-guardrails-detail.mdc
    lammuon-router.mdc
    lammuon-templates.mdc
    lammuon-speckit.mdc
    lammuon-testing.mdc
    lammuon-tooling.mdc
scripts/
  install.sh
  install.ps1
  check-rules.py
codex/
  skills/
    lammuon-team/
      SKILL.md
.gitattributes
VERSION
CHANGELOG.md
README.md
```

## Các agent

- **Làm Mướn Team**: router/orchestrator chính; chọn Tester/Small/Medium/Large Team và điều phối role.
- **lammuon-tester-team**: team QA-only gồm BA + Tester; BA đọc hiểu tính năng, Tester viết scenario detail rồi test, không sửa production code.
- **lammuon-pm**: chỉ dùng cho Large Team; lập plan, chia phase, quản trị scope/risk/rollback.
- **lammuon-ba**: dùng cho Tester/Medium/Large Team; làm rõ yêu cầu, mapping behavior, viết acceptance criteria.
- **lammuon-tester**: có ở mọi team; verify bug, viết test case, chạy test và regression.
- **lammuon-senior-dev**: có ở mọi task implement; đọc code, tìm root cause, sửa nhỏ nhất an toàn.

## Các rule chính

- **lammuon-guardrails.mdc**: rule an toàn core, always-on.
- **lammuon-preflight.mdc**: cầu chì always-on — Router header, Flow, Test Case Gate trước side effect (ngắn, khó bị rơi context).
- **lammuon-router.mdc**: phân loại task thành Tester/Small/Medium/Large Team và chọn flow (nạp khi cần chi tiết; không always-on vì dài).
- **lammuon-templates.mdc**: template output bắt buộc cho Small/Medium Team.
- **lammuon-speckit.mdc**: template SpecKit đầy đủ cho Large Team.
- **lammuon-testing.mdc**: quy tắc test case, UI/API/DB/regression testing.
- **Build gate**: khi Senior Dev thêm/sửa/xoá code hoặc config ảnh hưởng FE/BE, phải chạy build FE/BE tương ứng; build fail thì fix và rerun trước khi báo xong.
- **lammuon-tooling.mdc**: scan môi trường (MCP + Skills) đầu phiên, capability tier, đề xuất bổ sung MCP khi thiếu, enrich ngữ cảnh DB/data; gợi ý skill/MCP theo role và loại task.
- **lammuon-guardrails-detail.mdc**: checklist và template xác nhận cho hành động nhạy cảm.

## Flow làm việc

### Tester Team

Dùng cho test-only/QA-only: cần BA đọc hiểu tính năng, rồi Tester viết scenario detail và test. Không dùng Senior Dev, không sửa production code.

```text
BA -> Tester
```

### Small Team

Dùng cho bug nhỏ, typo, UI text, API/query issue gọn.

```text
Tester -> Senior Developer -> Tester
```

### Medium Team

Dùng cho feature mapping, business rule vừa phải, UI workflow/API behavior có ý nghĩa nghiệp vụ.

```text
BA -> Tester -> Senior Developer -> Tester
```

### Large Team

Dùng cho feature phức tạp, multi-module/service, architecture, migration, rollout nhiều phase.

```text
PM -> BA -> Tester -> Senior Developer -> Tester
```

## Cách dùng trong Cursor

### Cài tự động từ GitHub trên macOS/Linux

Cài vào project hiện tại:

```bash
curl -fsSL https://raw.githubusercontent.com/nShieldSolo/AgentTeam/main/scripts/install.sh | bash
```

Cài vào project khác bằng path:

```bash
curl -fsSL https://raw.githubusercontent.com/nShieldSolo/AgentTeam/main/scripts/install.sh | bash -s -- /path/to/project
```

Script chỉ copy các file `lammuon-*` vào `.cursor/agents` và `.cursor/rules`. Nếu có file cũ trùng tên và khác nội dung, script sẽ backup file cũ thành `*.bak.<timestamp>` trước khi ghi đè.

### Cài tự động từ GitHub trên Windows

Chạy trong PowerShell tại project muốn cài:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/nShieldSolo/AgentTeam/main/scripts/install.ps1 | iex"
```

Cài vào project khác bằng path:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/nShieldSolo/AgentTeam/main/scripts/install.ps1'))) -ProjectPath 'C:\path\to\project'"
```

### Update bản đã cài

Chạy lại đúng lệnh cài là script sẽ tự update:

```bash
curl -fsSL https://raw.githubusercontent.com/nShieldSolo/AgentTeam/main/scripts/install.sh | bash -s -- --global all
```

Hoặc dùng rõ mode update cho project hiện tại:

```bash
curl -fsSL https://raw.githubusercontent.com/nShieldSolo/AgentTeam/main/scripts/install.sh | bash -s -- --update
```

Windows PowerShell:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/nShieldSolo/AgentTeam/main/scripts/install.ps1'))) -Update"
```

Cơ chế update:

- File giống nhau: giữ nguyên, báo `unchanged`.
- File khác nội dung: backup file cũ thành `*.bak.<timestamp>`, rồi ghi bản mới.
- File chưa có: tạo mới.
- Script ghi state để trace source/branch/revision:
  - Project: `.cursor/lammuon-agent.state`
  - Cursor global: `~/.cursor/agents/.lammuon-agent.state`
  - Codex global: `~/.codex/skills/lammuon-team/.lammuon-agent.state`

### ⚠️ Global install ≠ Project Rules

**Cursor global install chỉ cài subagents** (`~/.cursor/agents/lammuon-*.md`). **Không** cài `.cursor/rules`.

Nếu anh muốn `/lammuon-team` ép Router header, Test Case Gate và Build gate **trong repo đang làm**, bắt buộc chạy **project install** trong repo đó:

```bash
curl -fsSL https://raw.githubusercontent.com/nShieldSolo/AgentTeam/main/scripts/install.sh | bash
```

Kiểm tra nhanh trong project:

```bash
ls -la .cursor/agents/lammuon-team.md
ls -la .cursor/rules/lammuon-preflight.mdc .cursor/rules/lammuon-guardrails.mdc .cursor/rules/lammuon-router.mdc
```

Chỉ có `~/.cursor/agents/lammuon-team.md` mà project không có `.cursor/rules` → slash command chạy nhưng **không có** preflight/router/testing gates.

### Cài global cho Cursor/Codex

Cài global Cursor subagents vào `~/.cursor/agents`:

```bash
curl -fsSL https://raw.githubusercontent.com/nShieldSolo/AgentTeam/main/scripts/install.sh | bash -s -- --global cursor
```

Cài global Codex skill vào `~/.codex/skills/lammuon-team`:

```bash
curl -fsSL https://raw.githubusercontent.com/nShieldSolo/AgentTeam/main/scripts/install.sh | bash -s -- --global codex
```

Cài cả hai:

```bash
curl -fsSL https://raw.githubusercontent.com/nShieldSolo/AgentTeam/main/scripts/install.sh | bash -s -- --global all
```

Windows PowerShell cài global Cursor:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/nShieldSolo/AgentTeam/main/scripts/install.ps1'))) -Mode cursor"
```

Windows PowerShell cài global Codex:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/nShieldSolo/AgentTeam/main/scripts/install.ps1'))) -Mode codex"
```

Windows PowerShell cài cả hai:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/nShieldSolo/AgentTeam/main/scripts/install.ps1'))) -Mode all"
```

Lưu ý: xem mục **⚠️ Global install ≠ Project Rules** ở trên — mỗi repo cần project install để có `lammuon-preflight` và các rule trong `.cursor/rules`.

### Gọi agent/rule

Trong Cursor, gõ `/lam` rồi chọn:

- **Làm Mướn Team** (`lammuon-team`): dùng mặc định cho hầu hết task; đóng vai trò router/orchestrator.
- `lammuon-tester-team`: dùng khi muốn gọi riêng Tester Team / `tester-team` chỉ gồm BA + Tester.
- `lammuon-ba`: chỉ gọi riêng khi muốn BA phân tích requirement/mapping.
- `lammuon-pm`: chỉ gọi riêng cho task lớn cần plan/phase/risk.
- `lammuon-tester`: chỉ gọi riêng khi muốn test case/verify/regression.
- `lammuon-senior-dev`: chỉ gọi riêng khi muốn implement/debug kỹ thuật.

Ví dụ:

```text
/lammuon-team xử lý bug này theo **Làm Mướn Team**
```

Lưu ý: `lammuon-router.mdc` là **Cursor Project Rule**, không phải slash command/subagent nên sẽ không hiện trong popup `/lam`. Rule này được dùng nội bộ để hướng dẫn **Làm Mướn Team** (`lammuon-team`) chọn flow và team size.

Với task nhỏ, **Làm Mướn Team** sẽ ưu tiên Small Team. Chỉ lên Medium/Large khi task cần BA/PM thật sự.
Với task test-only hoặc khi user gọi `tester-team`, router chọn **Tester Team** để chạy `BA -> Tester` và không kéo Senior Dev vào.

## Nguyên tắc bảo trì

- Giữ `lammuon-guardrails.mdc` ngắn, chỉ để rule an toàn core.
- Template chỉ nên có một source of truth để tránh drift.
- Khi thêm rule mới, cập nhật README và rule map trong `lammuon-router.mdc`.
- Khi thêm hành động nhạy cảm mới, thêm checklist vào `lammuon-guardrails-detail.mdc`.
- Chạy kiểm tra markdown/frontmatter trước khi commit nếu có sửa nhiều rule.

## Kiểm tra (smoke test)

Script `scripts/check-rules.py` kiểm tra toàn bộ agent/rule:

- Frontmatter có block `---` mở/đóng.
- Code fence cân bằng (hỗ trợ fence 4 backtick bọc 3 backtick kiểu template).
- Mọi reference `lammuon-xxx` đều tồn tại file tương ứng.

Chạy trước khi commit nếu sửa nhiều rule:

```bash
python3 scripts/check-rules.py
```

Exit code 0 = pass, 1 = có lỗi.

## Tình trạng hiện tại

- Repo tập trung vào workflow và rule cho Cursor, chưa có code ứng dụng.
- Đã có smoke test (`scripts/check-rules.py`) cho frontmatter, markdown fence và reference giữa các rule.
