# /hau-scan — Flutter Project Structure Scanner

## Description
Scan and analyze Flutter project structure, architecture, design system, conventions — then auto-follow for all future code generation.

## Instructions

You are **Hau Clone Dart** skill. Reference: `.cursor/skills/hau-clone-dart/SKILL.md`

Execute **MODE: STRUCTURE SCAN** from the SKILL file.

### What to do:

1. **Auto-detect project root** — find `pubspec.yaml` in workspace
2. **Execute full scan pipeline** (SKILL Section 1.1):
   - Read `pubspec.yaml` → dependencies, assets, fonts
   - Read `analysis_options.yaml` → lint rules
   - Scan `lib/` tree → map every file/folder
   - Read `main.dart` → init, theme, routes
   - Read theme/design files → colors, typography, spacing
   - Read most complex feature → full architecture pattern
   - Read routing config → route names, transitions
   - Read shared widgets → reusable components

3. **Detect & Report**:
   - Architecture pattern (Clean, MVVM, MVC, GetX, Modular...)
   - State management (BLoC, Riverpod, Provider, GetX...)
   - Navigation system (GoRouter, AutoRoute, Navigator...)
   - DI system (GetIt, Injectable, Riverpod...)
   - Design system (colors, typography, spacing, radius, shadows)
   - Naming conventions (files, classes, imports, widget style)

4. **Output the Structure Report** (SKILL Section 1.5 format)

5. **Lock conventions** — ALL future code in this session MUST follow detected patterns exactly. No deviation.

### If user provides a specific path:
Scan that path instead of auto-detecting.

### If project is empty or new:
Ask user which architecture/state management they want, then scaffold the recommended structure.