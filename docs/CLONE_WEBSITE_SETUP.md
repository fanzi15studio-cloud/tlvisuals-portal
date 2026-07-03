# `/clone-website` — Setup & Requirements

This repo ships the **`clone-website`** Claude Code skill
(`.claude/skills/clone-website/SKILL.md`), which reverse-engineers a live
website into clean front-end code, section by section.

Source template: https://github.com/JCodesMore/ai-website-cloner-template

## Usage

In a Claude Code session on this repo:

```
/clone-website https://target-site.com [https://second-site.com ...]
```

## Requirement 1 — Browser automation (configured)

The skill cannot work without a browser-automation MCP server. This repo
declares one in `.mcp.json`: **Playwright MCP** (`@playwright/mcp`), run in
headless mode against the Chromium build pre-installed at
`/opt/pw-browsers/chromium` in Claude Code web/remote environments.

- On the remote environment the browser is already present — no
  `playwright install` is needed.
- If you run this repo on a different machine, remove the
  `--executable-path` / `PLAYWRIGHT_BROWSERS_PATH` lines so Playwright uses
  its own downloaded browser, and drop `--no-sandbox` if you are not root.

Approve the `playwright` MCP server when Claude Code prompts for it (or via
`/mcp`).

## Requirement 2 — Outbound network access to the target site

The skill loads the *target* URL in the browser, so the environment must be
allowed to make outbound HTTPS requests to that host.

Claude Code remote environments run behind a **policy-enforcing egress
proxy**. If the environment's network policy does not allow the target host,
the browser navigation fails with a `403` / `ERR_TUNNEL_CONNECTION_FAILED`
and the clone cannot proceed. This is a per-environment setting chosen when
the environment was created — it is not something the skill can work around.

To clone arbitrary external sites, the environment needs a network policy
that permits general outbound access. See:
https://code.claude.com/docs/en/claude-code-on-the-web (network policy /
egress configuration).

## Notes for this project

The skill's template assumes a Next.js 16 + shadcn/ui + Tailwind v4 +
TypeScript scaffold. This repo is Next.js 14 + JavaScript with static export
(`output: 'export'`). When you invoke the skill here, tell Claude to target
this stack (plain JS/JSX, no `tsc` typecheck step) or scaffold clone output
under a dedicated route/folder.
