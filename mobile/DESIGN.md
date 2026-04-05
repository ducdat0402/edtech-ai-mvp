# Design System Strategy: The Luminal Scholar

## 1. Overview & Creative North Star
The Creative North Star for this design system is **"The Luminal Scholar."** 

In the realm of Vietnamese Edtech, we are moving away from the "loud," toy-like aesthetics of traditional gamification. Instead, we are building a sophisticated, immersive atmosphere that feels like a premium nocturnal study lounge. The experience is defined by **Atmospheric Depth**—where the UI doesn't sit *on* the screen, but *within* it. We use intentional asymmetry and "breathing" layouts to ensure that while the app is gamified, it remains a serious tool for high-level learning.

By utilizing a dark-first, graphite-based palette with glowing blue-violet accents, we create a focus-driven environment. The "game" elements (coins and XP) are treated as elegant jewelry rather than flat icons, providing a sense of prestige to the user's progress.

---

## 2. Colors: Tonal Atmosphere
We do not use color to decorate; we use it to direct the soul of the experience.

### The "No-Line" Rule
**Explicit Instruction:** Traditional 1px solid borders are strictly prohibited for sectioning. We define space through **Tonal Transitions**. Use `surface_container_low` against a `surface` background to create a section. If a visual break is needed, use a 24px-48px vertical gap of "empty" space rather than a line.

### Surface Hierarchy & Nesting
Treat the UI as physical layers of obsidian and frosted glass.
*   **Base:** `surface` (#0b141b) for the overall background.
*   **Secondary Content Areas:** Use `surface_container` (#182127) for large content blocks.
*   **Nested Elements:** Use `surface_container_high` (#222b32) for cards or interactive modules inside a secondary area.
*   **Depth Interaction:** A `surface_container_lowest` (#060f16) can be used to create "recessed" areas (like an input field or a progress tray) to give the illusion of carving into the UI.

### Signature Textures & Glass
*   **The Primary Glow:** Main CTAs should not be flat. Apply a linear gradient from `primary_container` (#7354f5) to `primary` (#cabeff) at a 135-degree angle.
*   **Glassmorphism:** For mobile navigation bars or floating action buttons, use `surface_bright` at 60% opacity with a `backdrop-filter: blur(20px)`. This keeps the "lesson" content visible as the user scrolls, maintaining immersion.

---

## 3. Typography: Vietnamese Editorial
The typography system balances the modern geometric nature of **Be Vietnam Pro** for information density with the functional clarity of **Manrope** for utility.

*   **Display & Headlines (Be Vietnam Pro):** Large, bold, and authoritative. In Vietnamese, diacritics can make lines look "crowded." Use a `line-height` of 1.2x for headlines to give these marks room to breathe. Use `headline-lg` for lesson titles to create a high-end editorial feel.
*   **Body (Be Vietnam Pro):** `body-lg` (16px) is our standard for lesson content. Readability is king. We use `on_surface_variant` (#c8c4d7) for long-form text to reduce eye strain against the dark background.
*   **Labels (Manrope):** Used for the "game" mechanics—chips, coin counts, and XP. The slightly narrower stance of Manrope works perfectly for condensed mobile "HUD" elements without looking cluttered.

---

## 4. Elevation & Depth: Tonal Layering
We move away from the "Material 2" shadow-heavy look. Depth is felt, not seen.

*   **The Layering Principle:** Instead of a shadow, place a `surface_container_highest` (#2d363d) card on a `surface` background. The delta in luminance creates the lift.
*   **Ambient Shadows:** For floating elements (e.g., the Mascot's dialogue bubbles), use a shadow: `offset: 0 12px, blur: 32px, color: rgba(0, 0, 0, 0.4)`. The shadow must feel like it's melting into the graphite background.
*   **The "Ghost Border" Fallback:** If a button or chip requires a boundary (e.g., secondary actions), use `outline_variant` (#474554) at 20% opacity. It should be a "whisper" of a line.

---

## 5. Components: Sophisticated Gamification

### Buttons (The "Jewel" Approach)
*   **Primary:** Gradient (Violet-to-Blue) with `xl` (1.5rem) roundedness. No border. Text is `on_primary_container`.
*   **Secondary:** Ghost style. Transparent background with a 10% `outline_variant` border.
*   **Tertiary:** Text-only using `primary_fixed_dim`, used for "Skip" or "Later" actions.

### Progress & Status (The "Lume" Effect)
*   **XP Progress Bars:** Use `tertiary` (#41e184). For high-end polish, add a subtle outer glow (box-shadow) of the same color at 10% opacity to make the green feel like it's "lit" from within.
*   **Chips:** Use `md` (0.75rem) roundedness. Status chips (e.g., "Hoàn thành") use `surface_container_highest` with `tertiary` text. No heavy backgrounds.

### Cards (The "Frameless" Look)
*   **Lesson Cards:** Forbid dividers. Use 24px padding and a background shift to `surface_container_low`. 
*   **The Mascot (Empty States):** The mascot should never appear in a "box." They should overlap the layout, breaking the container edges to create a sense of life and spontaneity.

### Input Fields
*   **Style:** `surface_container_lowest` background, `sm` roundedness. 
*   **Focus State:** A subtle 1px "Ghost Border" using `primary` at 40% opacity.

---

## 6. Do's and Don'ts

### Do:
*   **DO** use white space as a structural element. If in doubt, add 8px more padding.
*   **DO** use "Vietnamese-first" testing. Ensure accent marks (dấu) do not clip when using `title-sm` or `label-md`.
*   **DO** use the `secondary` gold (#ffd647) sparingly—only for coins or "Level Up" moments to maintain its value.

### Don't:
*   **DON'T** use pure black (#000000). It kills the "Sophisticated Graphite" depth. Always use `surface`.
*   **DON'T** use 100% opaque borders. They create "visual noise" and break the premium feel.
*   **DON'T** use heavy HUD elements. In mobile-first, the content is the UI. The "game" stats should feel like they belong to the page, not a fixed plastic bar at the top.