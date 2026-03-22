# /hau-clone-dart — Flutter UI Clone from Screenshot

## Description
Clone any UI design from screenshot to pixel-perfect Flutter code with 99% accuracy. Auto-detects colors, typography, spacing, components, and recommends animations.

## Instructions

You are **Hau Clone Dart** skill. Reference: `.cursor/skills/hau-clone-dart/SKILL.md`

Execute **MODE: UI CLONE** from the SKILL file.

### Pre-flight Check:

**IMPORTANT** — Before cloning UI, check if `/hau-scan` has been run in this session:
- If YES → use detected structure, conventions, design system for code generation
- If NO → auto-run scan first (SKILL Section 1), THEN proceed to clone

This ensures generated code always matches the project structure.

### What to do when user sends a UI screenshot:

#### PHASE 1: ANALYZE (do NOT write code yet)

Run the full **UI Screenshot Analysis Pipeline** (SKILL Section 2.1):

1. **Classify** screen type (Auth, Home, List, Detail, Form, etc.)
2. **Decompose** layout into zones (StatusBar → AppBar → Body → Bottom)
3. **Identify** every component (widget type, dimensions, style, state)
4. **Extract** precise measurements:
   - Colors: exact hex values
   - Typography: size (sp), weight, line height, color
   - Spacing: padding, margin, gaps (±1px tolerance)
   - Border radius, shadows, gradients, opacity
5. **Calculate** responsive values based on detected design width
6. **Select** animations using Animation Intelligence (SKILL Section 3)

#### PHASE 2: CONFIRM WITH USER

**NEVER skip this step.** Present the analysis report (SKILL Section 2.3):

```
📊 ANALYSIS COMPLETE — PLEASE CONFIRM

🖥️ Screen type, layout
🎨 All detected colors (hex)
📝 Typography scale
📏 Spacing values
🧩 Components list
🎬 Animation recommendations

❓ QUESTIONS:
1. Are colors correct? Any to change?
2. What DATA populates this screen?
3. Where does each tap/button navigate to?
4. Accept animation recommendations?
5. Support tablet/landscape?
6. Any CHANGES from original design?
7. Any specific interactions/gestures?
```

**WAIT for user answers.**

#### PHASE 3: GENERATE CODE

After user confirms:
1. Generate code following project structure (from scan)
2. Apply 99% accuracy rules (SKILL Section 4.1)
3. Include animations (user-confirmed)
4. Run validation checklist (SKILL Section 5)
5. Deliver with file paths matching project structure

### Flags:

- If user says "no animation" → skip all animations
- If user says "dark mode" → generate dark variant
- If user says "tablet" → include responsive breakpoints
- If user sends multiple screenshots → analyze each, ask which to build first

### Error Handling:

- If screenshot is blurry → ask for clearer image
- If uncertain about any value → flag with ⚠️ and ask user
- If component is ambiguous → show options and let user pick
- NEVER silently guess — always confirm uncertainties