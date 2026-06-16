# Bug Red Gate Design

Date: 2026-06-16

## Goal

When **Lam Muon Team** handles a bug fix, the team must prove the reported bug with an appropriate failing automated check before production code is fixed. A failing test is valid only when it fails for the same behavior described by the bug report.

This applies to all bug fixes:

- UI/web bugs use Playwright test automation when the repo has it, or Playwright MCP for reproduction when test code cannot be added yet.
- API bugs use existing API tests, command-line scripts, or `curl` evidence.
- DB/data/query bugs use DB read-first evidence and repo-level unit/integration tests when available.
- Non-UI bugs use the narrowest automated test that proves the behavior.

The rule must prevent agents from treating every Playwright failure as a production bug. When the input is copied from Playwright output, the fixing member must first decide whether the failure is caused by broken automation test code, flaky/env setup, or a real product bug found by Playwright.

## Current Context

The repo already has:

- Test-case-first rules in `.cursor/rules/lammuon-testing.mdc`, `.cursor/rules/lammuon-router.mdc`, `.cursor/rules/lammuon-templates.mdc`, and Cursor agent files.
- Build-before-done rules in guardrails, router, tester, senior-dev, and Codex skill docs.
- UI automation guidance that asks Tester to use Playwright when UI behavior changes.

The missing behavior is a hard **red phase**:

```text
write/run automation -> confirm it fails for the reported bug -> then fix -> rerun the same automation -> confirm pass
```

## Proposed Approach

Use a single concept across Cursor rules, agents, and Codex/Claude skill docs: **Bug Red Gate**.

Recommended approach:

1. Tester defines actual behavior, expected behavior, reproduction steps, and test cases.
2. Tester chooses the right automation path for the bug type.
3. Tester runs the automation before the fix.
4. If the automation fails for the exact reported bug, mark `Red Gate Passed`.
5. If the automation passes, fails for another reason, or cannot run, mark `Red Gate Blocked`.
6. Senior Developer may start fixing the original bug only after `Red Gate Passed`.
7. After the fix, Senior Developer runs build and relevant tests.
8. Tester reruns the same automation that failed in the red phase. It must pass before the bug can be reported fixed.
9. Tester runs regression checks and reports remaining risk.

This is stricter than only adding Playwright language. It keeps Playwright mandatory for UI/web flows while still enforcing red-first behavior for API, DB, and backend bugs.

## Bug Red Gate Workflow

```text
Tester confirms actual vs expected
-> Tester exports TC-001.. and expected failure
-> Tester creates or selects automation for the bug type
-> Tester runs automation before fix
-> If failure matches bug: Red Gate Passed
-> If test passes or fails differently: Red Gate Blocked
-> Senior Developer fixes only after Red Gate Passed
-> Senior Developer runs build and targeted tests
-> Tester reruns the same automation
-> Tester runs regression and reports result
```

### Tool Selection

| Bug type | Red gate evidence |
|---|---|
| UI/web flow | Playwright repo test when available; otherwise Playwright MCP reproduction/assertion |
| API | API test, script, or `curl` status/response evidence |
| DB/data/query | DB read-first evidence plus unit/integration test when available |
| Backend/business logic | Existing or new unit/integration test |
| Mixed UI/API/DB | Combine the narrowest checks needed to prove the reported failure |

### Valid Red Failure

A red failure is valid only when all are true:

- The failure maps to the reported behavior.
- The expected behavior is clear.
- The failure signature is recorded: assertion, status code, response body, screenshot, trace, log, or DB evidence.
- The failure is reproducible enough to guide the fix.

### Blocked Red Gate

The red gate is blocked when:

- The automation passes before the fix.
- The automation fails for a different reason.
- The bug cannot be reproduced.
- The required URL, account, env, DB access, or tool is missing after one blocking question.
- The test itself is clearly wrong or flaky.

When blocked, the agent must not fix the original bug as if it were proven. It must record a follow-up issue or limitation first.

## Playwright Failure Triage

When a user pastes a Playwright failure, stack trace, test report, trace viewer output, or prompt generated from Playwright, the fixbug member must classify the failure before changing production code.

### Triage Question

The first question is:

```text
Is this a bug in the automation test, an environment/flakiness problem, or a product bug found by Playwright?
```

### Classification

| Classification | Meaning | Next action |
|---|---|---|
| Automation test bug | Locator, timing, fixture, mock, expectation, test data, or setup in the test is wrong | Fix the test or fixture; do not change production code unless product evidence appears |
| Env/flaky issue | App not running, auth/session missing, network/service unavailable, timeout not tied to product behavior, test data absent | Report limitation or stabilize env/test setup first |
| Product bug found by Playwright | Test is valid and app behavior violates expected behavior | Mark `Red Gate Passed`; Senior Dev may fix production code |
| Unclear | Evidence is not enough to distinguish | Inspect test code, app code, trace/logs, and ask one blocking question if needed |

### Required Evidence For Playwright Inputs

Before a production fix, the agent must read and summarize:

- Failing test name and assertion.
- Relevant locator/action and expected assertion.
- Actual UI state, screenshot, trace, console error, network response, or app log.
- Whether the failure is caused by test code/fixture/env or product behavior.
- The verdict: `Automation Bug`, `Env/Flaky`, `Product Bug`, or `Unclear`.

Only `Product Bug` can satisfy `Red Gate Passed` for the original bug fix.

## Output Contract

Bug investigation output must include:

```markdown
### Red Test / Bug Reproduction Automation
- Tool: <Playwright test | Playwright MCP | curl/API test | unit/integration test | DB read-first + test>
- Command / Steps Run: `<command or steps>`
- Expected Failure Signature: <how the reported bug should fail>
- Actual Failure Signature: <actual log/status/assert/screenshot>
- Verdict: <Red Gate Passed | Red Gate Blocked>
- Follow-up Bug: <BUG-xxx or short issue summary; use "Not applicable" only when Red Gate Passed>
```

When the input comes from Playwright, also include:

```markdown
### Playwright Failure Triage
- Failing Test: <test name>
- Failing Assertion / Locator: <assertion and locator/action>
- Evidence Reviewed: <trace/screenshot/log/network/test code>
- Classification: <Automation Bug | Env/Flaky | Product Bug | Unclear>
- Reason: <short evidence-backed reason>
```

## Rule Changes To Implement

The implementation should update these sources:

- `.cursor/rules/lammuon-testing.mdc`
  - Add the **Bug Red Gate** rule.
  - Add the **Playwright Failure Triage** rule.
  - Define valid red failure vs blocked red gate.

- `.cursor/rules/lammuon-router.mdc`
  - Update Small/Medium/Large bug flows so Tester must run red automation before Senior Dev.
  - Add `Red Gate Passed` as a prerequisite for Senior Dev in bug fix work.

- `.cursor/rules/lammuon-templates.mdc`
  - Add `### Red Test / Bug Reproduction Automation` to `## Tester Analysis`.
  - Add `### Playwright Failure Triage` when input comes from Playwright.
  - Update Definition of Done for Tester verify.

- `.cursor/agents/lammuon-tester.md`
  - Require Tester to create/select/run automation before bug handoff.
  - Require Playwright failure classification when the prompt is copied from Playwright.
  - Block handoff if the failure is test/env/flaky rather than product behavior.

- `.cursor/agents/lammuon-senior-dev.md`
  - Require `Red Gate Passed` before production bug fix.
  - If Playwright evidence is classified as automation/env issue, fix test/setup only when that is the requested scope.

- `.cursor/agents/lammuon-team.md`
  - Mirror the orchestrator flow and gate.

- `codex/skills/lammuon-team/SKILL.md`
  - Mirror the same behavior for Codex/Claude usage.

- `README.md` and `CHANGELOG.md`
  - Document the rule at a release-note level.

## Error Handling

- If expected behavior is unclear, hand off to BA before writing automation.
- If the red test cannot run because URL/account/env/tool is missing, ask one blocking question. If still unavailable, write `Test Execution Limitation` and do not claim the red gate passed.
- If the red test passes before the fix, treat the bug as not reproduced or the test as insufficient.
- If the red test fails differently, record a new bug/test issue and stop the original fix flow.
- If a repo has no Playwright framework, UI bug reproduction still uses Playwright MCP when available; missing committed test code must be reported as a limitation.

## Verification Plan

After implementing the rule changes:

1. Run `py -3 scripts/check-rules.py`.
2. Use `rg` to confirm these phrases exist in the intended sources:
   - `Bug Red Gate`
   - `Red Gate Passed`
   - `Red Gate Blocked`
   - `Playwright Failure Triage`
   - `Automation Bug`
   - `Product Bug`
3. Review the changed templates to ensure no required heading was removed.
4. Do not run Playwright for this repo because this repo contains rules/templates, not a web application.

## Out Of Scope

- Building a new Playwright framework for this repo.
- Changing install scripts unless the final implementation changes file packaging requirements.
- Enforcing this through executable linting beyond the existing `scripts/check-rules.py`.
- Creating a bug tracking integration for `Follow-up Bug`.
