# Team Collaboration Rules

## Task 8 — Git Workflow

### Branch Strategy

```
main (production-ready, tagged releases)
  │
  └── develop (integration branch, always buildable)
        │
        ├── feature/auth-login          (Arwah)
        ├── feature/home-product-grid   (Munaza)
        ├── feature/cart-local-storage  (Nimra)
        ├── feature/search-screen       (Naheed)
        └── fix/cart-delivery-fee       (Nimra)
```

**Two long-lived branches:**
- `main` — production releases only. Never commit directly. Only merged from `develop` via release PR.
- `develop` — integration branch. All feature branches merge here. Must always build and run.

**Short-lived branches:**
- Feature branches created from `develop`, merged back to `develop` via PR.
- Deleted after merge.

### Branch Naming

```
{type}/{feature}-{description}
```

| Type | When |
|------|------|
| `feature/` | New functionality |
| `fix/` | Bug fix |
| `refactor/` | Code restructuring (no behavior change) |
| `chore/` | Config, deps, docs |

Examples:
```
feature/auth-login
feature/auth-google-oauth
feature/home-product-grid
feature/cart-delivery-fee
feature/checkout-otp
fix/cart-persistence-null
refactor/product-card-cleanup
chore/update-dependencies
```

**Rules:**
- Lowercase only, hyphens for spaces
- Keep names short but descriptive
- Include feature area prefix

### Commit Messages

Format:
```
type(scope): short description

Optional longer description if needed.
```

| Type | When |
|------|------|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code change (no behavior change) |
| `style` | Formatting, lint fixes |
| `test` | Adding/updating tests |
| `chore` | Dependencies, config, docs |
| `wip` | Work in progress (will be squashed) |

Examples:
```
feat(auth): implement login screen with validation
feat(cart): add delivery fee calculation
fix(cart): handle null variant in cart persistence
refactor(home): extract product grid into separate widget
test(cart): add blocTest for delivery fee threshold
chore(deps): update flutter_bloc to 8.1.4
```

**Rules:**
- Present tense ("add" not "added")
- No period at end
- First line < 72 characters
- Scope is the feature area (auth, cart, home, core, etc.)

### Pull Requests

**When to open a PR:**
- Feature is complete (all acceptance criteria met)
- Tests pass locally (`flutter test`)
- Analyzer clean (`flutter analyze`)
- Code formatted (`dart format .`)

**PR title:** Same as commit message format
```
feat(auth): implement login screen with validation
```

**PR description template:**
```markdown
## What
Brief description of what this PR does.

## Changes
- Added login screen with email/password validation
- Created AuthRepository with login method
- Added AuthCubit with loading/error states

## Screenshots
[If UI changes, attach screenshots]

## Testing
- [ ] Tested on Android emulator
- [ ] Tested on iOS simulator (if applicable)
- [ ] Unit tests added
- [ ] No regressions

## Related
- Closes #[issue number]
- Depends on #[PR number] (if any)
```

### Code Review

**Reviewer assignment:**
| Developer | Reviewed By | Reviews |
|-----------|-------------|---------|
| Naheed | Arwah | Munaza's checkout, shared component changes |
| Arwah | Nimra | Naheed's search/seller, networking changes |
| Munaza | Naheed | Nimra's orders, model changes |
| Nimra | Munaza (or Arwah) | Arwah's auth/profile, shared widget changes |

**Review expectations:**
- Review within **24 hours** of PR creation
- Focus on: architecture compliance, design system usage, error handling, naming
- Don't nit-pick formatting (linter handles that)
- Approve if it follows conventions, even if you'd write it differently
- Request changes only for: bugs, architecture violations, missing error states, security issues

**Review checklist:**
- [ ] Correct folder/layer placement
- [ ] Uses AppColors/AppTypography/AppSpacing (no hardcoded values)
- [ ] Loading/error/empty states handled
- [ ] No `print()` or debug code
- [ ] No hardcoded API URLs
- [ ] Models use `@JsonSerializable`
- [ ] Cubit states are sealed classes
- [ ] Repository catches DioException → throws Failure

### Merge Strategy

**Squash merge** for feature branches:
```bash
# On GitHub: "Squash and merge" button
# Results in one clean commit on develop per feature
```

**Why squash:** Feature branches often have messy WIP commits. Squash merge gives a clean history on `develop` — one commit per feature.

**Merge commit** for develop → main (release):
```bash
# Preserves the full feature history for the release
```

### Conflict Resolution

1. **Pull `develop` into your feature branch daily** (or before opening PR):
   ```bash
   git checkout feature/my-feature
   git pull origin develop
   # Resolve conflicts if any
   git push
   ```

2. **If conflict is in a shared file** (router, pubspec, constants):
   - Both developers' additions are usually correct — merge both
   - If in doubt, ask the file owner (see shared-foundation-ownership.md)

3. **If conflict is in a feature file:**
   - This shouldn't happen (exclusive folder ownership)
   - If it does: the feature owner's version wins

4. **Never force-push to `develop` or `main`**

---

## Task 9 — Shared File & Merge Conflict Strategy

### High-Conflict Files

| File | Why It Conflicts | Mitigation |
|------|-----------------|-----------|
| `pubspec.yaml` | Multiple devs add packages | Only Naheed adds. Others request via chat. |
| `app/router.dart` | All devs add routes | Each dev has a marked section. Add only in your section. |
| `app/app.dart` | Global providers added | Only Naheed modifies. Others request. |
| `core/constants/api_endpoints.dart` | All devs add endpoints | Append only. Never modify existing lines. |
| `core/constants/storage_keys.dart` | All devs add keys | Append only. |
| `.g.dart` files (generated) | Regenerated on build | Add to `.gitignore`. Each dev runs `build_runner` locally. |

### Router Section Convention

```dart
// app/router.dart

// ══════════════════════════════════════════
// NAHEED'S ROUTES (Search, Seller, Support)
// ══════════════════════════════════════════
GoRoute(path: '/search', ...),
GoRoute(path: '/seller/:slug', ...),
GoRoute(path: '/support/new', ...),

// ══════════════════════════════════════════
// ARWAH'S ROUTES (Auth, Profile, Notifications)
// ══════════════════════════════════════════
GoRoute(path: '/login', ...),
GoRoute(path: '/profile', ...),
GoRoute(path: '/profile/notifications', ...),

// ══════════════════════════════════════════
// MUNAZA'S ROUTES (Home, Products, Checkout)
// ══════════════════════════════════════════
GoRoute(path: '/product/:slug', ...),
GoRoute(path: '/checkout', ...),

// ══════════════════════════════════════════
// NIMRA'S ROUTES (Cart, Wishlist, Orders)
// ══════════════════════════════════════════
GoRoute(path: '/cart', ...),
GoRoute(path: '/orders', ...),
GoRoute(path: '/orders/:id/return', ...),
```

Each developer only adds/modifies routes in their section. This eliminates merge conflicts.

### pubspec.yaml Rule

**Process for adding a new package:**
1. Developer posts in team chat: "I need package X for reason Y"
2. Team confirms no one objects (30-min window)
3. Naheed adds it and pushes to `develop`
4. Everyone pulls

**Why:** Four people editing `pubspec.yaml` simultaneously guarantees conflicts. One person owns it.

### Shared Component Modification Rule

| Change Type | Process |
|-------------|---------|
| Bug fix in existing component | Fix + PR. Mention affected devs. |
| Add optional prop to component | PR + notify devs who use it. No breaking change. |
| Change component behavior | Discuss in chat first. All affected devs must approve. |
| New shared component | Request to Naheed. Naheed creates or assigns. |
| Remove component | Never (deprecate instead). |

---

## Task 10 — Pull Request Process

### Flow

```
Developer completes feature
  │
  ├── Runs flutter analyze (zero warnings)
  ├── Runs dart format . (auto-format)
  ├── Runs flutter test (all pass)
  │
  ▼
Opens PR against develop
  │
  ├── Title: feat(scope): description
  ├── Description: What, Changes, Screenshots, Testing
  ├── Assigns reviewer
  ├── Links issue (Closes #N)
  │
  ▼
Reviewer reviews within 24h
  │
  ├── Approved → Merge (squash)
  │
  └── Changes requested
        │
        ├── Developer addresses comments
        ├── Pushes fixes
        ├── Re-requests review
        │
        └── Approved → Merge (squash)
```

### PR Size Guidelines

| Size | Lines Changed | Verdict |
|------|--------------|---------|
| Small | < 200 | Ideal. Review in < 30 min. |
| Medium | 200–500 | Acceptable. One feature. |
| Large | 500–1000 | Split if possible. Review in < 1 day. |
| Too Large | > 1000 | Must be split. Will not be reviewed effectively. |

**If a feature requires > 500 lines:** Break into logical sub-PRs:
1. PR 1: Model + Repository (data layer)
2. PR 2: Cubit + states (state management)
3. PR 3: Screen + widgets (UI)

Each sub-PR is reviewable independently and can be merged sequentially.

### When NOT to Open a PR

- Code doesn't compile
- `flutter analyze` has errors
- Tests fail
- Feature is half-implemented (no partial PRs without marking as Draft)
- Contains debug code (`print()`, hardcoded test data)

### Draft PRs

Use Draft PRs for:
- Work-in-progress that you want early feedback on
- Large features where you want directional review before completion
- Blocked work that needs discussion

Draft PRs are NOT reviewed for merge — they're discussion tools.

---

## Task 13 — Communication Rules

### Channels

| Channel | Purpose | Response Time |
|---------|---------|---------------|
| Team group chat (WhatsApp/Slack) | Daily communication, quick questions, blockers | < 1 hour during work |
| GitHub PR comments | Code-specific discussion | < 24 hours |
| GitHub Issues | Task tracking, bug reports | Next working day |
| Call/meeting | Architecture decisions, complex problems | Scheduled as needed |

### What Must Be Communicated

| Event | How | When |
|-------|-----|------|
| Starting a new task | Move card to In Progress | Immediately |
| PR ready for review | Tag reviewer in chat + GitHub | Immediately |
| Blocker discovered | Message in team chat + tag relevant person | Immediately (don't wait) |
| Need a shared component | Message Naheed: "I need X widget for Y feature" | As soon as discovered |
| Need a package added | Message team: "I need package X for reason Y" | Before starting work that needs it |
| Architecture question | Team chat: describe problem + proposed solution | Before implementing |
| Breaking change to shared code | Team chat + wait for all acknowledgments | Before merging PR |
| Backend API needed | Add to backend-team-requirements.md + message backend team | As early as possible |
| Finished a phase | Message team: "My Phase X work is merged and ready" | When Done |
| Found a bug in someone else's code | Open GitHub Issue, assign to owner | Same day |

### What Does NOT Need Communication

- Routine commits to your feature branch
- Fixing lint warnings in your code
- Adding models/repos in your own feature folder
- Style choices within your feature (your code, your style within conventions)

### Architecture Changes

**Any change that affects the architecture** (new interceptor, new global cubit, change to state pattern) must:
1. Be proposed in team chat with: problem, proposed solution, alternatives considered
2. Get explicit OK from Naheed (architecture owner)
3. Be implemented in a separate PR (not bundled with feature work)

### Conflict Between Developers

If two developers disagree on an approach:
1. Each states their position briefly in chat
2. Naheed decides (project lead, architecture owner)
3. Decision is final. Move on.

No meeting needed unless both approaches have equal merit and significant implications.

### Daily Standup (Optional but Recommended)

Quick async standup in team chat (2–3 lines per person):
```
Naheed: Yesterday: search screen + filter sheet. Today: seller store. Blocked: none.
Arwah: Yesterday: login + register. Today: Google OAuth. Blocked: need reCAPTCHA site key.
Munaza: Yesterday: product detail layout. Today: variant selector + gallery. Blocked: none.
Nimra: Yesterday: cart cubit + persistence. Today: wishlist. Blocked: none.
```

Takes 2 minutes. Keeps everyone aware.
