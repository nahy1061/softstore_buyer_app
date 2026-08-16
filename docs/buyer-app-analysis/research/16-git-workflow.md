# Phase 4: Git Workflow

## Branch Strategy: GitHub Flow (Simplified)

```
main ────────────────────────────────────────────────────────────►
  │                                         ▲
  └── develop ──────────────────────────────┤──────────────────►
        │        ▲     │        ▲           │
        └── feat/home  └── feat/cart        │
                              │             │
                              └── release/1.0.0
```

### Branch Roles

| Branch | Purpose | Who Merges | Protected |
|--------|---------|-----------|-----------|
| `main` | Production releases only | Lead dev / CI | Yes (no direct push) |
| `develop` | Integration branch, always deployable to staging | Any dev via PR | Yes (requires 1 review) |
| `feature/*` | Active feature development | Author (into develop) | No |
| `bugfix/*` | Bug fixes | Author (into develop) | No |
| `hotfix/*` | Critical production fix | Lead (into main + develop) | No |
| `release/*` | Release candidate preparation | Lead | No |

---

## Branch Naming Convention

```
{type}/{feature-or-ticket}
```

### Prefixes

| Prefix | Usage | Example |
|--------|-------|---------|
| `feature/` | New feature | `feature/product-detail` |
| `feature/{dev}/` | Dev-scoped sub-feature | `feature/devb/image-gallery` |
| `bugfix/` | Bug fix | `bugfix/cart-total-calculation` |
| `hotfix/` | Urgent production fix | `hotfix/checkout-crash` |
| `chore/` | Non-feature (CI, deps, docs) | `chore/update-dio-version` |
| `refactor/` | Code restructuring | `refactor/cart-state-model` |

### Rules
- Lowercase only, hyphens for spaces
- Max 50 characters
- No issue numbers in branch name (put in commit message)
- Delete branch after merge

---

## Commit Conventions

### Format (Conventional Commits)

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

### Types

| Type | When |
|------|------|
| `feat` | New feature or functionality |
| `fix` | Bug fix |
| `refactor` | Code change that neither fixes nor adds |
| `style` | Formatting, whitespace (no logic change) |
| `test` | Adding or fixing tests |
| `docs` | Documentation only |
| `chore` | Build, deps, CI, tooling |
| `perf` | Performance improvement |

### Scopes (Match Feature Folders)

```
auth, home, search, product-detail, cart, checkout, orders, profile,
wishlist, notifications, support, seller, core, navigation, theme, models
```

### Examples

```
feat(cart): add swipe-to-delete on cart items
fix(checkout): prevent double-tap on place order button
refactor(core): extract retry logic into interceptor
test(auth): add unit tests for login cubit states
chore(deps): update dio to 5.4.0
```

### Rules
- Subject: imperative mood ("add" not "added"), no period, max 72 chars
- Body: explain WHY, not what (the diff shows what)
- Footer: `Closes #123` for issue references

---

## Pull Request Process

### PR Template

```markdown
## What
<!-- One-line description -->

## Why
<!-- Motivation: what problem this solves -->

## How
<!-- Brief implementation approach (if non-obvious) -->

## Screenshots
<!-- For UI changes: before/after or new screen -->

## Testing
- [ ] Unit tests pass
- [ ] Widget tests pass (if UI)
- [ ] Manually tested on Android
- [ ] Manually tested on iOS (if applicable)

## Checklist
- [ ] No TODO comments left
- [ ] No print() or debugPrint() in production code
- [ ] New strings are not hardcoded (use constants)
- [ ] Models have fromJson/toJson tests
- [ ] Cubit has unit tests for all states
```

### PR Rules

| Rule | Enforcement |
|------|------------|
| Minimum 1 approval required | Branch protection |
| CI must pass (lint + tests) | Branch protection |
| No self-merging | Honor system (small team) |
| PR title follows commit convention | Reviewer checks |
| Max 400 lines changed per PR | Guideline (split large features) |
| Draft PRs for WIP | Use GitHub draft status |
| Respond to reviews within 4 hours | Team agreement |

### PR Size Guidelines

| Size | Lines Changed | Expected Review Time |
|------|--------------|---------------------|
| Small | < 100 | 15 min |
| Medium | 100–300 | 30 min |
| Large | 300–500 | 1 hour |
| Too large | > 500 | Split into smaller PRs |

---

## Code Review Guidelines

### What Reviewers Check

1. **Correctness** — Does it do what the PR claims?
2. **Architecture** — Does it follow feature-first clean architecture?
3. **State management** — Is state in the right Cubit? Correct layer?
4. **Error handling** — Are failures surfaced to the user?
5. **Testing** — Are new states/logic covered?
6. **Security** — No hardcoded secrets, no sensitive data in logs
7. **Performance** — No unnecessary rebuilds, proper disposal

### What Reviewers Do NOT Block On

- Style preferences already handled by linter
- Minor naming disagreements (suggest, don't block)
- "I would have done it differently" (if it works and follows patterns)

### Review Response Protocol

| Comment Type | Prefix | Blocking? |
|-------------|--------|-----------|
| Must fix | `blocking:` | Yes |
| Suggestion | `nit:` or `suggestion:` | No |
| Question | `question:` | No (unless answer changes approach) |
| Praise | `nice:` | No |

---

## Merge Strategy

### Feature → Develop: Squash Merge

```bash
# GitHub: "Squash and merge" button
# Result: one clean commit on develop per feature
```

**Why squash:** Feature branches have WIP commits ("fix typo", "address review"). Squashing keeps `develop` history clean and each commit meaningful.

### Develop → Main: Merge Commit (no squash)

```bash
# GitHub: "Create a merge commit"
# Preserves the squashed feature commits from develop
```

### Release Process

```bash
# 1. Create release branch from develop
git checkout develop
git checkout -b release/1.0.0

# 2. Version bump in pubspec.yaml
# 3. Final testing on release branch
# 4. Merge to main (merge commit)
# 5. Tag: v1.0.0
# 6. Merge back to develop (merge commit)
```

---

## Conflict Prevention

### Strategies

| Strategy | Implementation |
|----------|----------------|
| Feature folders isolate files | Each dev works in their own directory |
| Daily rebase onto develop | Each morning: `git fetch && git rebase origin/develop` |
| Shared files frozen early | Models, router, theme defined in Phase 0, rarely changed |
| Router contributions via PR | Only Dev A modifies `router.dart`; others submit route additions |
| Communication before refactoring | Announce in team chat if touching shared code |
| Small, frequent PRs | Merge every 1–2 days, not at end of feature |

### High-Risk Shared Files

| File | Conflict Risk | Mitigation |
|------|--------------|------------|
| `app/router.dart` | High (all devs add routes) | Dev A owns; others PR route additions grouped by feature |
| `pubspec.yaml` | Medium (package additions) | Discuss in standup before adding; merge sequentially |
| `core/network/api_client.dart` | Low (rarely changed after Phase 0) | Dev B owns; changes require 2 approvals |
| Model files | Low (defined once) | Dev B owns; changes via PR with tests |
| `shared/providers/` | Medium (DI registration) | Add new providers at end of file to minimize conflicts |

### Conflict Resolution Protocol

1. Pull latest `develop`
2. If conflict in YOUR feature code → resolve yourself
3. If conflict in SHARED code → discuss with the other dev
4. If conflict in someone else's feature → something is wrong (imports violate architecture)
5. After resolving, run full test suite before pushing

---

## CI Pipeline (Recommended)

```yaml
# .github/workflows/ci.yml
on:
  pull_request:
    branches: [develop, main]

jobs:
  analyze:
    - flutter analyze
    - dart format --set-exit-if-changed

  test:
    - flutter test --coverage

  build:
    - flutter build apk --debug (smoke test)
```

### CI Must Pass Before Merge
- Zero lint warnings
- All tests pass
- Build succeeds (debug mode sufficient for CI)

---

## Git Hooks (Local, Optional)

```bash
# .githooks/pre-commit
flutter analyze --no-pub
dart format --set-exit-if-changed lib/

# .githooks/commit-msg
# Validate conventional commit format
```

Install: `git config core.hooksPath .githooks`
