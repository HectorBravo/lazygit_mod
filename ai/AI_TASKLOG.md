# AI Tasks Log

## Summary

| Created | Task | Status | Type | Subtasks | Time Spent | Blockers |
|---------|------|--------|------|----------|------------|----------|
| 04-10-2026 16:28:30 | [T1: Show commits for all branches (no reflog)](#task-t1-show-commits-for-all-branches-no-reflog) | <span style="background-color:#0969da;color:#fff;padding:2px 8px;border-radius:12px;font-size:12px;">in_progress</span> | <span style="background-color:#22863a;color:#fff;padding:2px 8px;border-radius:12px;font-size:12px;">feat</span> | 0/6 | 0m | none |

> ✅ **0 completed task(s)** — [View completed tasks](#completed-tasks)

---

## Task T1: Show commits for all branches (no reflog)

- **Status**: <span style="background-color:#0969da;color:#fff;padding:2px 8px;border-radius:12px;font-size:12px;">in_progress</span>
- **Type**: <span style="background-color:#22863a;color:#fff;padding:2px 8px;border-radius:12px;font-size:12px;">feat</span>
- **Created**: 04-10-2026 16:28:30
- **Last Updated**: 04-10-2026 16:28:30
- **Time Spent**: 0m
- **Branch**: [`feat/ai-show-commits-all-branches`](https://github.com/HectorBravo/lazygit_mod/tree/feat/ai-show-commits-all-branches)
- **Commit(s)**: pending
- **Blockers**: none
- **Findings & Notes**:
  - lazygit already ships `git.log.showWholeGraph` which drives `git log --all`. That is the "rubbish" source: `--all` pulls in `refs/stash`, `refs/original/*` (pre-rebase/reflog) and tags.
  - Verified empirically in a scratch repo: `git log --all` shows `refs/stash` + `index on ...` commits; `git log --branches --remotes` shows only real branch commits (local + remote), no stash/reflog/tags. That is the clean set the user wants.
  - Both the short commits pane and the maximised (`+`) pane render the **same** `c.Model().Commits` data, fed by a single code path `refreshCommitsWithLimit` (refresh_helper.go:861). So one change covers both panes.
  - The sub-commits view (`refreshSubCommitsWithLimit`, refresh_helper.go:1040) is a separate path and does not set `All`; out of scope.
  - Plan: add an independent `git.log.showCommitsForAllBranches` bool (default false) that drives `git log --branches --remotes`, leaving `showWholeGraph` untouched.

### User Confirmations

**Pending (awaiting user response):**

- [ ] (04-10-2026 16:28:30) Confirm the new option name `showCommitsForAllBranches` and that it should be config-only (no runtime Log-menu toggle, unlike `showWholeGraph`).

**Confirmed (user provided):**

- (04-10-2026 16:20:00) "showWholeGraph already does something similar but shows a lot of reflog rubbish" → user wants the same all-branches view **without** the reflog/stash/tag refs.

### Subtasks / Plan

- [ ] Add `ShowCommitsForAllBranches` to `LogConfig` + default in `pkg/config/user_config.go`
- [ ] Add `AllBranches` to `GetCommitsOptions` and emit `--branches --remotes` in `getLogCmd` (`pkg/commands/git_commands/commit_loader.go`)
- [ ] Wire `AllBranches` from config in `refreshCommitsWithLimit` (`pkg/gui/controllers/helpers/refresh_helper.go`)
- [ ] Regenerate docs via `just generate`
- [ ] `just format` / `build` / `unit-test` / `lint` all green
- [ ] Commit code to branch; commit + push task log to `master`

### Full Context Notes for AI Agents

> **Purpose**: Self-contained recovery source. Read this to resume without other context.

- **Repo**: `/home/hbravo/repos/lazygit_mod` (lazygit fork). Remote origin `git@github.com:HectorBravo/lazygit_mod.git` → hyperlink base `https://github.com/HectorBravo/lazygit_mod`. Current branch `master`.
- **AI identity** (env vars per command, never `git config`): `GIT_AUTHOR_NAME=AI_bot`, `GIT_AUTHOR_EMAIL=noreply@cuic.net`, `GIT_COMMITTER_NAME=AI_bot`, `GIT_COMMITTER_EMAIL=noreply@cuic.net`. Domain `cuic.net` derived from user's `git config user.email` = `hbravo@cuic.net` (commit history has no company domain — all personal/GitHub).
- **Goal**: New config `git.log.showCommitsForAllBranches` (bool, default false). When true, the commits pane (short AND maximised `+`) lists commits reachable from all local + remote branches, excluding reflog/stash/tag refs. Implemented by passing `--branches --remotes` to `git log` instead of `--all`.
- **Data flow (existing `showWholeGraph`)**:
  - config `UserConfig().Git.Log.ShowWholeGraph` (`pkg/config/user_config.go:436`, default `false` at :964)
  - → view-model flag `showWholeGitGraph` (`pkg/gui/context/local_commits_context.go:227`, initialised from config at :233; getters/setters :314-:320)
  - → captured at refresh `captured.showWholeGitGraph` (`pkg/gui/controllers/helpers/refresh_helper.go:796`)
  - → `GetCommitsOptions.All` (`refresh_helper.go:872`)
  - → `getLogCmd` adds `--all` (`pkg/commands/git_commands/commit_loader.go:609`, `ArgIf(opts.All, "--all")`).
  - `GetCommitsOptions.All` declared at `commit_loader.go:66`.
- **Both panes share one path**: `refreshCommitsWithLimit` (`refresh_helper.go:861`) builds the `GetCommitsOptions` (lines 864-876) and writes `c.Model().Commits` (:892). The maximised view only changes the view width, not the data. So setting `AllBranches` here covers short + long panes.
- **New code to add**:
  1. `pkg/config/user_config.go` — in `LogConfig` struct (after `ShowWholeGraph bool` at :436) add `ShowCommitsForAllBranches bool \`yaml:"showCommitsForAllBranches"\`` with a single-unwrapped-line doc comment (userConfig doc rule). In the default `Log: LogConfig{...}` block (after `ShowWholeGraph: false` at :964) add `ShowCommitsForAllBranches: false,`.
  2. `pkg/commands/git_commands/commit_loader.go` — in `GetCommitsOptions` (after `All bool` at :66) add `AllBranches bool`. In `getLogCmd` (after `ArgIf(opts.All, "--all")` at :609) add `ArgIf(opts.AllBranches, "--branches", "--remotes")`.
  3. `pkg/gui/controllers/helpers/refresh_helper.go` — in `refreshCommitsWithLimit` (after `All: captured.showWholeGitGraph,` at :872) add `AllBranches: self.c.UserConfig().Git.Log.ShowCommitsForAllBranches,`.
- **Docs**: `pkg/config/user_config.go` field doc comments feed the generator. After editing, run `just generate` to refresh `docs-master/Config.md` + `schema-master/config.json`. Do NOT hand-edit `docs/` or `docs-master/Config.md`.
- **Commands** (prefer `just`): `just generate`, `just format` (gofumpt), `just build`, `just unit-test`, `just lint`.
- **Commit conventions (AGENTS.md overrides git-rule Rule 4 for code commits)**: plain English imperative, NO conventional-commit prefixes; body wrapped at 72; end with `Co-authored-by:` trailer naming the model. Task-log commits use `docs(ai):` per git rules. No PRs ever. Use `fixup!` commits for refinements, never `--amend` directly.
- **Edge cases**: If both `showWholeGraph` and `showCommitsForAllBranches` are true, the command becomes `git log <ref> --all --branches --remotes` (`--all` is a superset → effectively `--all`); harmless, user error to set both. `RefToShowDivergenceFrom` is only set in the sub-commits path, not here.
- **Current state**: Context gathered and verified. No code changed yet. Next: create branch, make the 3 edits, `just generate`, run checks, commit.

---

## Completed Tasks

| Created | Task | Type | Subtasks | Time Spent |
|---------|------|------|----------|------------|
