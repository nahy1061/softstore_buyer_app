# Task Management Workflow

## Board Structure (Trello/Jira)

### Columns

```
Backlog → Ready → In Progress → Code Review → Testing → Done
```

| Column | Meaning | Who Moves Here |
|--------|---------|---------------|
| **Backlog** | All tasks not yet scheduled for current phase | Project lead |
| **Ready** | Task has no blockers, can be picked up | Project lead / developer |
| **In Progress** | Developer is actively working on it | Assigned developer |
| **Code Review** | PR opened, waiting for review | Developer (after PR) |
| **Testing** | Approved PR, manual testing on device | Reviewer / developer |
| **Done** | Merged to develop, verified working | After merge |

### Additional Column (Optional)

| Column | When to Use |
|--------|------------|
| **Blocked** | Task cannot proceed due to external dependency (backend API not ready, another task not merged) |

---

## Task Card Format

### Title
```
[Feature] Specific action
```

Examples:
- `[Auth] Build login screen`
- `[Cart] Implement delivery fee calculation`
- `[Home] Add pagination to product grid`
- `[Foundation] Create app_colors.dart`

### Card Fields

| Field | Required? | Example |
|-------|-----------|---------|
| Title | Yes | `[Cart] Implement pre-checkout validation` |
| Description | Yes | What to implement, acceptance criteria |
| Assignee | Yes | One developer only |
| Label(s) | Yes | `feature`, `UI`, `API` |
| Priority | Yes | P1 / P2 / P3 |
| Dependencies | If any | "Blocked by: [Auth] AuthCubit" |
| Phase | Yes | Phase 0 / Phase 1 / etc. |
| Due Date | Optional | End of phase week |

### Description Template

```markdown
## What
Brief description of what to implement.

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Dependencies
- Requires: [task name] to be merged first
- Uses: shared component X

## Notes
Any important context or backend requirements.
```

---

## Labels

| Label | Color | Meaning |
|-------|-------|---------|
| `foundation` | Purple | Project setup, infrastructure |
| `feature` | Blue | New feature implementation |
| `ui` | Green | UI-only work (no API) |
| `api` | Orange | Requires backend API integration |
| `bug` | Red | Something is broken |
| `testing` | Teal | Test writing |
| `blocked` | Grey | Cannot proceed |
| `urgent` | Red border | Must be done before anything else |
| `shared` | Yellow | Affects shared code (core/) |

---

## Priority Levels

| Priority | Meaning | Example |
|----------|---------|---------|
| **P1 — Critical** | Blocks other developers | Foundation tasks, AuthCubit, shared models |
| **P2 — High** | Core user journey | Login, product list, checkout, place order |
| **P3 — Normal** | Standard feature work | Wishlist, returns, notifications |
| **P4 — Low** | Nice-to-have polish | Animations, haptic feedback, edge cases |

---

## Workflow Rules

### Picking Up Tasks

1. Only pick tasks from **Ready** column
2. Only pick tasks assigned to you (or discuss with team if reassigning)
3. Check dependencies — if the dependency isn't in **Done**, the task stays in **Backlog**
4. Move to **In Progress** when you start working
5. Only have **1-2 tasks** in progress at a time (avoid context switching)

### Moving Between Columns

| From → To | Who | When |
|-----------|-----|------|
| Backlog → Ready | Project lead (Naheed) | When dependencies are met and phase starts |
| Ready → In Progress | Assigned developer | When starting work |
| In Progress → Code Review | Developer | When PR is opened |
| Code Review → Testing | Reviewer | When PR is approved |
| Testing → Done | Developer or reviewer | When tested on device and merged |
| Any → Blocked | Developer | When a blocker is discovered |
| Blocked → Ready | Developer | When blocker is resolved |

### Blocked Tasks

When you hit a blocker:
1. Move card to **Blocked**
2. Add a comment explaining what's blocking
3. Notify the blocking developer/team immediately (don't wait)
4. Pick up your next Ready task while waiting
5. When unblocked → move back to Ready (or In Progress if you resume immediately)

---

## Definition of Done (Per Task)

A task is **Done** when ALL of the following are true:

- [ ] Implementation matches acceptance criteria
- [ ] Architecture rules followed (correct layer, correct folder)
- [ ] Design system used (no hardcoded values)
- [ ] Loading state handled
- [ ] Error state handled
- [ ] Empty state handled (if applicable)
- [ ] API errors handled gracefully
- [ ] No `print()` statements or debug code
- [ ] No lint warnings (`flutter analyze` clean)
- [ ] PR reviewed and approved
- [ ] Merged to `develop`
- [ ] Tested on at least one device
- [ ] No regressions in existing features

---

## Sprint/Phase Rhythm

Since we're using phases (not traditional sprints), here's the rhythm:

| Day | Activity |
|-----|----------|
| Phase start (Day 1) | Naheed moves tasks from Backlog to Ready for the phase |
| Daily | Each dev picks from Ready, moves to In Progress |
| Daily | PRs opened and reviewed same day (< 24h review turnaround) |
| Phase end | All tasks for the phase should be in Done |
| Phase end | Quick team sync: what's done, what carried over, blockers for next phase |

---

## GitHub Issues as Alternative

If the team prefers GitHub Issues over Trello:

```
Repo: nahy1061/softstore_buyer_app

Labels: same as above
Milestones: Phase 0, Phase 1, Phase 2, ... Phase 6
Assignees: nahy1061, arwahimran, nimraqureshi-ai, munazamanzoorofficial-beep
Projects: Kanban board with same columns
```

GitHub Issues has the advantage of linking PRs directly to issues (`Fixes #42`), auto-closing on merge.
