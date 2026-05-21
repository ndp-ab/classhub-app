# ClassHub Design System

## Base Style Reference

Base style inspired by:
- Mike Matas minimalist typography system
- Linear clean productivity UI
- Todoist mobile productivity layout
- Apple-style mobile spacing comfort

This design system is adapted specifically for:
- Flutter mobile app
- Material 3 foundation
- Student productivity & classroom management

---

# Design Philosophy

ClassHub should feel:

- clean
- calm
- modern
- lightweight
- readable
- productivity-focused
- student-friendly

Avoid:
- flashy gradients
- crypto/SaaS aesthetics
- excessive shadows
- playful gamification
- neon colors
- desktop-heavy layouts

The UI should resemble a real modern mobile productivity app.

---

# Colors

## Base

| Role | Value |
|---|---|
| Background | #FFFFFF |
| Surface | #FFFFFF |
| Primary Text | #000000 |
| Secondary Text | #999999 |
| Border | #EAEAEA |
| Divider | #F0F0F0 |

## Accent

| Role | Value |
|---|---|
| Primary Accent | #6366F1 |
| Success | #22C55E |
| Warning | #F59E0B |
| Danger | #EF4444 |

---

# Typography

## Font Family

Use:
- Inter
- SF Pro Display
- system-ui fallback

Avoid decorative fonts.

---

## Type Scale

| Role | Size | Weight |
|---|---|---|
| Display | 32 | 700 |
| Heading Large | 28 | 700 |
| Heading | 24 | 600 |
| Title | 20 | 600 |
| Subtitle | 16 | 500 |
| Body | 16 | 400 |
| Caption | 14 | 400 |
| Small | 12 | 400 |

---

# Spacing

## Base Unit

8px system.

---

## Recommended Spacing

| Role | Value |
|---|---|
| Tiny gap | 4 |
| Small gap | 8 |
| Element gap | 12 |
| Card padding | 16 |
| Section padding | 20 |
| Screen horizontal padding | 20 |
| Large section gap | 24 |
| Large vertical spacing | 32 |

Avoid desktop-like giant spacing.

---

# Radius

| Element | Radius |
|---|---|
| Buttons | 16 |
| Inputs | 16 |
| Cards | 20 |
| Bottom sheets | 24 |
| Chips | 999 |
| Dialogs | 24 |

Avoid:
- sharp 0px corners
- exaggerated 90px+ radius

---

# Shadows

Use extremely subtle shadows only.

Preferred:
- soft border
- minimal elevation
- clean surfaces

Avoid:
- heavy blur shadows
- floating/glass effects

---

# Material 3 Foundation

Use Material 3 as:
- accessibility foundation
- component behavior
- responsive structure

Do NOT use:
- default Material blue appearance
- default filled Material look everywhere

All Material components should follow this design system.

---

# Mobile UX Rules

Prioritize:
- touch comfort
- readability
- simple hierarchy
- clean scrolling
- minimal visual noise

Buttons must:
- be easy to tap
- minimum 48px height

Cards must:
- feel breathable
- have enough internal padding
- separate information clearly

Lists should:
- resemble Todoist productivity layouts
- use clear hierarchy
- avoid table-like density

---

# Shared Components

Create reusable components:

- AppCard
- AppButton
- AppInput
- AppSectionTitle
- AppEmptyState
- AppErrorState
- AppLoading

Do not duplicate styles inside screens.

---

# Screen Design Direction

## Login / Signup

- centered clean forms
- strong typography
- minimal distractions
- soft inputs
- obvious CTA

---

## HomeScreen

- classroom cards
- soft white cards
- clean statistics
- obvious create/join actions

---

## Classroom Detail

- clean tabs
- sticky hierarchy
- soft sections

---

## Fund Screens

Inspired by:
- Todoist lists
- Revolut financial clarity

Must feel:
- trustworthy
- readable
- calm

Use:
- payment status chips
- clean amount hierarchy
- comfortable spacing

---

## Events

Use:
- productivity app layout
- clean event cards
- clear CTA buttons

---

# Flutter Rules

Convert all design tokens into:

- app_colors.dart
- app_spacing.dart
- app_radius.dart
- app_text_styles.dart
- app_theme.dart

Use shared reusable widgets.

Do not:
- hardcode colors
- hardcode spacing
- hardcode text styles
- invent inconsistent UI patterns

---

# Important

This app is:
- mobile-first
- productivity-focused
- information-heavy

Consistency is more important than creativity.

The UI should feel:
- intentional
- clean
- calm
- trustworthy
- modern

# Implementation Guardrails

When applying this design system:
- Do not change API endpoints.
- Do not change services.
- Do not change models.
- Do not change providers.
- Do not change navigation flow.
- Do not rename existing screen classes.
- Do not rewrite business logic.
- Do not remove polling, confirm dialogs, or payment status logic.
- Only change UI layout, styling, theme, and reusable widgets.

Work in small steps:
1. First create theme files and shared widgets.
2. Then stop for review.
3. Only refactor screens after approval.