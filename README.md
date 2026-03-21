# Paper Letter Animation Demo

## Overview
This is a SwiftUI demo project focused on motion and interaction design.

The goal is to prototype a delightful interaction:
turning a written note into a sent letter through animation.

This is not a production app.
This is a visual and interaction experiment.

---

## Core Idea

User writes a note and sends it as a virtual letter.

The flow:

1. A paper note is visible on screen
2. The note shrinks and visually "folds"
3. An envelope appears
4. The note moves into the envelope
5. The envelope closes
6. A stamp can be selected and placed on the envelope

---

## Scope (MVP)

We are NOT building a full product.

Focus only on:

- paper → envelope animation
- simple interaction (button tap)
- basic visual polish
- one screen

---

## Key States

The animation is built as a sequence of states:

- idle (paper visible)
- folding
- envelope appears
- inserting paper
- envelope closed
- stamp selection (later)

---

## Design Principles

- clean, minimal UI
- soft, tactile feeling
- "paper-like" aesthetics
- subtle shadows and depth
- no overcomplicated visuals

---

## Technical Constraints

- SwiftUI only
- no third-party libraries
- simple state-driven animations
- no complex architecture

---

## Development Approach

- build step by step
- start with simple working version
- iterate on animation quality later
- avoid overengineering

---

## Notes

This project is for exploring:
- motion design in code
- interaction storytelling
- rapid prototyping via AI

---

## Current Iteration (Step 1)

Implemented:
- compose screen with text input
- top bar (back, title, save)
- save action transitions to paper state
- paper can be folded/unfolded as the first simple interaction

Figma reference for compose state:
- https://www.figma.com/design/QVh3KmxAB6cDCDecaztEZn/Vibe-Coding?node-id=28-2053&t=bggfDa0VjXJpcJ8A-4

---

## Project Structure

- `LetterDemoApp.swift`
- `Domain/LetterDraft.swift`
- `DesignSystem/AppColors.swift`
- `DesignSystem/AppSpacing.swift`
- `Features/Compose/ComposeStage.swift`
- `Features/Compose/ComposeLetterView.swift`
- `Features/Compose/Components/PaperSheetView.swift`
