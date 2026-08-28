# Global Development Conventions

General, stack-agnostic rules for every project on this machine. Project-level
AGENTS.md files add scoped rules and take precedence — follow them when present.

## 0. Authorization & workflow
- DO NOT make any file, code, config, or infrastructure changes until you receive
  an explicit "go ahead" (or equivalent) instruction for that work.
- When the go-ahead is given, implement on a NEW branch created from `dev`.
- Branch naming: `feature/<short-desc>` or `fix/<short-desc>`.
- NEVER push directly to `main` or `dev`.
- `dev` is the only branch that may be merged into `main`.
- New features and fixes are always branched from `dev`; merge them back into
  `dev` (via PR), then `dev` → `main`.

## 1. Agent behavior
- Match the project's existing conventions before applying general rules.
- Be concise; ask when ambiguous.
- Do not commit, push, force-push, or open PRs unless explicitly asked (and see §0
  for branch discipline).
- Do not run destructive commands (`rm -rf`, `drop`, `format`, etc.) without
  explicit confirmation.
- Verify work: run the project's lint / test / build before reporting done.
- Prefer reading files and searching the codebase over guessing APIs.
- Cite `file:line` when referencing code.

## 2. Code style
- 2-space indent (unless the project specifies otherwise); no tabs.
- Files end with exactly one trailing newline; no trailing whitespace.
- Naming: `camelCase` for functions/variables; `PascalCase` for types, classes,
  components; `UPPER_SNAKE_CASE` for constants; `kebab-case` filenames where the
  ecosystem uses it.
- Match the project's quote style and line-length norms.
- Prefer explicit, readable code over clever or terse code.

## 3. Structure & design
- Read neighboring files first; mirror existing patterns and architecture.
- Single responsibility; small, composable functions/modules.
- DRY, but avoid premature abstraction — duplicate until a pattern is proven.
- Separate concerns: data access, business logic, presentation.
- Use framework idioms (e.g. server vs client components, hooks).

## 4. Error handling
- Handle errors at boundaries; never silently swallow exceptions.
- `try/catch` around I/O, network, and DB calls; log with context.
- Return safe, user-facing messages; never leak stack traces or secrets.
- Degrade gracefully (return a neutral default rather than crash the request).

## 5. Security
- Never commit secrets/keys/tokens or `.env` files; use env vars + `.env.example`.
- Parameterize all SQL/queries; never interpolate untrusted input.
- Validate and sanitize all external input; escape output (XSS/injection).
- Verify auth server-side; never trust client-side checks alone.
- Use vetted crypto/auth libraries; never hand-roll.

## 6. Databases & data
- Use migrations for schema changes; no manual production edits.
- Paginate large results; avoid N+1 queries (joins/batches).
- Use provided connection pooling; don't open ad-hoc connections.
- Wrap DB access in `try/catch` and degrade gracefully.

## 7. Testing & quality
- Run the project's lint / test / build before reporting completion.
- Add/adjust tests when changing logic; use the project's framework.
- Respect type-checker strictness (e.g. TypeScript).
- If no tests exist, manually verify happy path and edge cases.

## 8. Dependencies
- Check the manifest (`package.json`, etc.) before adding; reuse what exists.
- Prefer maintained, minimal libraries; avoid duplicate functionality.
- Update deps deliberately; avoid breaking major bumps without reason.

## 9. Git & commits
- Follow the branch discipline in §0.
- Conventional Commits: `type(scope): summary`
  (`feat:`, `fix:`, `chore:`, `refactor:`, `docs:`, `test:`, `perf:`, `style:`).
- Small, atomic, focused commits with clear messages.
- Don't commit secrets, lockfiles, or config casually.
- No force-push to shared branches without request.

## 10. Accessibility & UX (UI work)
- Semantic HTML + ARIA; full keyboard navigation.
- Sufficient contrast; respect `prefers-reduced-motion`.
- Touch targets >= 44px; label all form controls.

## 11. Performance
- Cache expensive work deliberately; invalidate on purpose.
- Lazy-load heavy modules/components; avoid blocking the main thread.
- Profile before optimizing; skip micro-optimizations that hurt clarity.

## 12. Local dev server & build
- Never start the dev server yourself. Instruct the user to run it (e.g.
  `npm run dev`); do not run `next dev` / `npm run dev` on their behalf.
- Before running any build command (e.g. `next build`), check whether the
  dev server is running and stop it first to avoid port/resource conflicts.
