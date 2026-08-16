# Developer Workflow

## Daily Workflow

```
1. Pull latest develop
   git checkout develop
   git pull origin develop

2. Check task board
   - Pick next task from "Ready" column assigned to you
   - Move to "In Progress"

3. Verify dependencies
   - Is the task's dependency merged to develop?
   - If not → pick a different task or mark as Blocked

4. Create feature branch
   git checkout -b feature/{area}-{description}

5. Implement
   - Follow architecture (cubit → repository → model)
   - Use design system (AppColors, AppTypography, etc.)
   - Handle all states (loading, error, empty)
   - Write tests alongside implementation

6. Self-check before PR
   flutter analyze          # Zero warnings
   dart format .            # Auto-format
   flutter test             # All pass
   # Run app and verify feature works on device

7. Commit
   git add [specific files]
   git commit -m "feat(scope): description"

8. Push
   git push -u origin feature/{area}-{description}

9. Open PR
   - Title: feat(scope): description
   - Description: What, Changes, Screenshots, Testing
   - Assign reviewer
   - Link issue if using GitHub Issues

10. Address review
    - Fix requested changes
    - Push new commits (don't force-push)
    - Re-request review

11. After merge
    - Delete feature branch
    - Move task to "Done"
    - Pull develop into any other active branches
```

---

## Handling Common Situations

### I'm Blocked by Another Developer's Task

1. Check if their PR is open → add yourself as reviewer to speed it up
2. If not started yet → message them: "I need X for my Y task. When do you expect it?"
3. Move your task to **Blocked** column
4. Pick another task that has no dependencies
5. When unblocked → resume original task

**Don't:** Wait silently. Don't stall for a full day without communicating.

### I Need a Backend API That Doesn't Exist Yet

1. Add to `backend-team-requirements.md` if not already there
2. Message the backend team with: endpoint needed, request/response format, priority
3. Build your feature with a **mock repository**:
   ```dart
   class MockProductRepository implements ProductRepository {
     @override
     Future<List<ProductModel>> getProducts({int page = 1}) async {
       await Future.delayed(Duration(seconds: 1)); // Simulate network
       return _mockProducts; // Hardcoded data
     }
   }
   ```
4. UI, cubit, and tests work fully with mock data
5. When API is ready → replace mock with real implementation (one file change)

### I Need a Shared Component That Doesn't Exist

1. Check `core/widgets/` — maybe it exists under a different name
2. Check `shared-components.md` — is it planned?
3. If not listed: message Naheed: "I need a [component] for [feature]. Used by [N] features."
4. If it qualifies (3+ features): Naheed creates it or assigns you to create it
5. If it doesn't qualify: build it in your own `features/{name}/presentation/widgets/`

### I Discovered an Architecture Problem

1. Don't "fix" it silently across multiple features
2. Post in team chat:
   ```
   Problem: [description]
   Affected: [which features/files]
   Proposed fix: [what you'd change]
   Alternative: [if any]
   ```
3. Wait for Naheed to decide (architecture owner)
4. Implement the agreed solution in a dedicated `refactor/` PR (not bundled with feature work)

### I Need to Change a Shared File

| File | Process |
|------|---------|
| `pubspec.yaml` | Request in chat → Naheed adds |
| `app/router.dart` | Add your routes in YOUR section only. No approval needed. |
| `core/constants/api_endpoints.dart` | Append your endpoints. No approval needed. |
| `core/constants/storage_keys.dart` | Append your keys. No approval needed. |
| `core/widgets/*` | Bug fix: PR + notify users. New prop: PR + discuss. |
| `core/theme/*` | Message Naheed. Never modify without approval. |
| `core/network/*` | Message Arwah. Never modify without approval. |
| `app/app.dart` | Message Naheed. Never modify without approval. |

### My Feature Conflicts with Another Developer's

This shouldn't happen if everyone stays in their assigned folders. But if it does:

1. Identify the conflict point (a shared model? a shared widget?)
2. Message the other developer: "My [feature] needs [change] to [shared thing]"
3. Agree on the change together
4. One person makes the change in a separate PR
5. Both pull the change before continuing

### I'm Ahead of Schedule / All My Tasks Are Done

1. Check if any teammates are blocked — offer to help
2. Pick up tasks from the next phase (if dependencies are met)
3. Write tests for existing code (coverage is never 100%)
4. Review open PRs (faster reviews = faster team velocity)
5. Polish: accessibility, edge cases, animations in your features

### I Made a Mistake That Broke develop

1. **Don't panic.** It happens.
2. If simple fix: push a fix commit immediately
3. If complex: revert your merge commit, open a new PR with the fix
4. Message team: "develop was broken by [commit]. I've [fixed it / reverted]. Please pull."
5. Never force-push `develop`

---

## Pre-PR Checklist (Quick Version)

Before opening any PR, run these commands:

```bash
flutter analyze         # Must show: No issues found!
dart format .           # Auto-formats all files
flutter test            # All tests pass
flutter run             # App launches without crash
```

Then mentally verify:
- Did I handle loading state?
- Did I handle error state?
- Did I handle empty state?
- Did I use AppColors/AppTypography/AppSpacing everywhere?
- Did I leave any print() or debug code?
- Is my file in the correct folder?

---

## End-of-Phase Workflow

At the end of each development phase:

1. Ensure all your phase tasks are merged to `develop`
2. Pull latest `develop` and run the full app — verify nothing is broken
3. Post in team chat: "My Phase X work is done and merged."
4. Quick sync with team: any carry-over tasks? any blockers for next phase?
5. Naheed moves next phase tasks from Backlog to Ready

---

## Tools

| Tool | Purpose | When |
|------|---------|------|
| `flutter analyze` | Catch lint errors | Before every commit |
| `dart format .` | Auto-format code | Before every commit |
| `flutter test` | Run unit + widget tests | Before every PR |
| `dart run build_runner build` | Regenerate .g.dart files | After model changes |
| Flutter DevTools | Debug layout, performance | During development |
| Android Studio / VS Code | IDE | Always |
| GitHub CLI (`gh`) | PR management | Optional |
