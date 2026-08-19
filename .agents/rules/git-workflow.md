# Rule: Git & Version Control Guidelines

This rule defines the Git workflow, safety boundaries, and commit message standards for the SoftStore Buyer App.

## 1. Branch Strategy

* `main`: Production releases only (Protected - no direct push).
* `develop`: Active integration branch.
* `feature/<feature-name>`: Feature branch for new capabilities.
* `bugfix/<fix-name>`: Bug fix branch.

## 2. Agent Safety Guardrails (Strictly Enforced)

1. **NO Destructive Commands**:
   * NEVER execute `git push`, `git push --force`, `git push -u origin <branch>` unless the user explicitly commands it.
   * NEVER execute `git reset --hard` or `git clean -fd` which can wipe user's uncommitted work.
   * NEVER switch branches (`git checkout`, `git switch`) without user authorization.
2. **Atomic Commits**:
   * Group related changes into focused, clean commits.
   * Do not mix architecture refactors with unrelated UI tweaks in the same commit.

## 3. Conventional Commit Format

All commit messages must follow the Conventional Commits specification:

```
<type>(<scope>): <short description in imperative, present tense>

[optional body explaining why this change was made]
```

### Supported Types:
* `feat`: A new user-facing feature or enhancement.
* `fix`: A bug fix.
* `refactor`: Code restructuring without changing behavior.
* `style`: Formatting, missing semicolons, design system alignment.
* `docs`: Documentation updates.
* `test`: Adding or refactoring unit/bloc tests.
* `chore`: Build configuration, dependencies, script adjustments.

### Common Scopes:
* `auth`, `cart`, `catalog`, `checkout`, `orders`, `product`, `profile`, `support`, `theme`, `network`, `storage`, `router`, `core`

### Examples:
* `feat(catalog): implement category filtering and product search grid`
* `fix(cart): correct subtotal calculation on item quantity change`
* `refactor(network): migrate softstore api client to centralized interceptors`
