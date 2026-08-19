---
name: architecture-audit
description: >-
  Step-by-step runbook for performing an Architecture and Foundation layer audit on the Flutter codebase against defined standards.
---

# Architecture & Foundation Audit Skill

Use this skill when auditing any layer (Architecture, Foundation, Core, or Feature slices) in the SoftStore Buyer App repository.

---

## 1. Audit Objectives

Ensure that the audited code strictly adheres to:
1. **Layer Separation**: Clear boundaries between UI (`screens/`, `widgets/`), Business Logic (`cubit/`), Data Abstraction (`repository/`), and Network/Storage (`core/network/`, `core/storage/`).
2. **Design System Tokens**: 100% compliance with `lib/core/theme/` (`AppColors`, `AppSpacing`, `AppTypography`, `AppDimensions`, `AppDurations`). Zero hardcoded colors, margins, or inline text styles.
3. **Core Widget Reuse**: Standard buttons, text fields, cards, loaders, empty states, and error states must use `lib/core/widgets/`.
4. **State Management Cleanliness**: State immutability with `Equatable`, exhaustive state handling in UI (`loading`, `success`, `empty`, `error`).
5. **Error & Network Handling**: Robust failure transformation into domain `Failure` classes without leaking raw exceptions to the UI.

---

## 2. Step-by-Step Audit Procedure

### Step 1: Inventory Target Files
* Identify all files in the target directory (e.g. `lib/core/`, `lib/app/`, or `lib/features/<target>/`).
* Check dependencies in `pubspec.yaml` relevant to the layer.

### Step 2: Static Analysis & Compilation Check
* Verify whether the target files compile cleanly without warnings or deprecated API calls.
* Run or check `flutter analyze` lints.

### Step 3: Architecture & Invariant Inspection
* **Inspect imports**: Check for circular dependencies or illegal imports (e.g. UI widgets importing Dio directly).
* **Inspect design token usage**: Search for `Color(`, `Colors.`, `TextStyle(`, `EdgeInsets.all`, `BorderRadius.circular` to detect unmigrated hardcoded values.
* **Inspect error handling**: Verify `try/catch` blocks wrap async calls and emit typed `Failure` states.

### Step 4: Generate Structured Audit Report
Format the audit findings in markdown containing:
* **Compliance Score / Summary**: Overall health of the layer (Pass / Needs Refactor / Critical Issues).
* **Violations Table**: Specific file paths, line numbers, and exact rule broken.
* **Recommended Remediation Plan**: Prioritized list of actionable changes with zero breaking changes to sibling features.
