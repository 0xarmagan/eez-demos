---
name: EEZ Quickstarts
description: Dark-bench walkthroughs of the EEZ protocol, where real cited code sits under one green work light.
colors:
  eez-green: "#3BE57E"
  grad-mint: "#8AE5AC"
  grad-steel: "#6283BD"
  grad-indigo: "#4439CB"
  grad-mint-hover: "#9DEBBB"
  grad-steel-hover: "#7593CD"
  void: "#000000"
  canvas: "#0A0A0A"
  screen: "#161616"
  chrome: "#1F1F1F"
  edge: "#2E2E2E"
  control: "#141414"
  control-edge: "#2A2A2A"
  control-hover: "#1A1A1A"
  code-well: "#050505"
  ink: "#FFFFFF"
  ink-soft: "#D8D8D8"
  ink-quiet: "#8F8F8F"
  muted: "#9AA3B3"
  label: "#9BA6D6"
typography:
  display:
    fontFamily: "Geist, system-ui, -apple-system, 'Segoe UI', sans-serif"
    fontSize: "48px"
    fontWeight: 800
    lineHeight: 1.08
    letterSpacing: "-0.01em"
  stage-title:
    fontFamily: "Geist, system-ui, -apple-system, 'Segoe UI', sans-serif"
    fontSize: "56px"
    fontWeight: 600
    lineHeight: 1.14
  stage-lede:
    fontFamily: "Geist, system-ui, -apple-system, 'Segoe UI', sans-serif"
    fontSize: "25px"
    fontWeight: 400
    lineHeight: 1.5
  caption:
    fontFamily: "Geist, system-ui, -apple-system, 'Segoe UI', sans-serif"
    fontSize: "22px"
    fontWeight: 400
    lineHeight: 1.45
  title:
    fontFamily: "Geist, system-ui, -apple-system, 'Segoe UI', sans-serif"
    fontSize: "17.5px"
    fontWeight: 600
    lineHeight: 1.35
  body:
    fontFamily: "Geist, system-ui, -apple-system, 'Segoe UI', sans-serif"
    fontSize: "18px"
    fontWeight: 400
    lineHeight: 1.55
  body-small:
    fontFamily: "Geist, system-ui, -apple-system, 'Segoe UI', sans-serif"
    fontSize: "13.5px"
    fontWeight: 400
    lineHeight: 1.55
  code:
    fontFamily: "'Geist Mono', ui-monospace, 'SF Mono', Menlo, Consolas, monospace"
    fontSize: "19px"
    fontWeight: 400
    lineHeight: "34px"
  label:
    fontFamily: "'Geist Mono', ui-monospace, 'SF Mono', Menlo, Consolas, monospace"
    fontSize: "12px"
    fontWeight: 500
    letterSpacing: "0.1em"
rounded:
  hairline: "4px"
  control: "5px"
  field: "12px"
  card: "16px"
  pill: "100px"
spacing:
  grid-cell: "42px"
  gap: "16px"
  card-pad: "28px 26px 26px"
  gutter: "32px"
  gutter-mobile: "18px"
  section: "56px"
components:
  pill-solid:
    backgroundColor: "{colors.ink}"
    textColor: "{colors.void}"
    typography: "{typography.label}"
    rounded: "{rounded.pill}"
    padding: "5px 5px 5px 20px"
  pill-outline:
    backgroundColor: "transparent"
    textColor: "{colors.ink}"
    typography: "{typography.label}"
    rounded: "{rounded.pill}"
    padding: "5px 5px 5px 20px"
  button-play:
    textColor: "{colors.canvas}"
    rounded: "{rounded.pill}"
    padding: "12px 28px"
  button-step:
    backgroundColor: "{colors.control}"
    textColor: "{colors.ink-soft}"
    rounded: "{rounded.pill}"
    padding: "12px 22px"
  button-step-hover:
    backgroundColor: "{colors.control-hover}"
  card:
    backgroundColor: "{colors.screen}"
    textColor: "{colors.ink}"
    rounded: "{rounded.card}"
    padding: "{spacing.card-pad}"
  card-hover:
    backgroundColor: "#0D0D0D"
  filter-chip:
    backgroundColor: "#0D0D0D"
    textColor: "#888888"
    typography: "{typography.label}"
    rounded: "{rounded.pill}"
    padding: "6px 14px"
  filter-chip-active:
    backgroundColor: "{colors.ink}"
    textColor: "{colors.void}"
  search-input:
    backgroundColor: "#090909"
    textColor: "{colors.ink}"
    typography: "{typography.body-small}"
    rounded: "{rounded.field}"
    padding: "13px 44px 13px 42px"
  code-panel:
    backgroundColor: "{colors.screen}"
    textColor: "{colors.ink-soft}"
    typography: "{typography.code}"
  tool-chip:
    backgroundColor: "{colors.control-hover}"
    textColor: "{colors.muted}"
    rounded: "{rounded.control}"
    padding: "3px 8px"
---

# Design System: EEZ Quickstarts

## Overview

**Creative North Star: "The Lit Bench"**

EEZ Quickstarts is a dark workbench laid over graph paper. Every page sits on a near-black canvas ruled with a faint 42px grid, the cutting mat the parts are laid out on. The parts themselves are real: verbatim code, diagrams with real values, citations pinned to a commit. One green work light falls on whatever is live. The EEZ gradient, mint to steel to indigo, appears only where a reader's hand goes next.

The system is dense and quiet, and it keeps an engineer's discipline. Surfaces are flat grey layers split by 1px edges, never stacked with shadows. Type is split between Geist for anything read as prose and Geist Mono for anything read as a label, a number or code. Controls stay grey at rest and come alive when touched: a card lifts 4px and shows a gradient hairline, an arrow nudges sideways. Nothing in the design should look more finished, faster or more certain than the protocol behind it.

There are two surfaces. The **index** (`index.html`, `start-here.html`, `deploy.html`) is a document that flows at 1200px max width. The **walkthrough stage** is a fixed 1920×1080 frame scaled to the viewport. Below 1120px it unfolds into a normal stacked page.

**Key Characteristics:**
- A near-black canvas with a 42px hairline grid on every surface.
- Flat tonal layers (canvas → screen → chrome) separated by 1px edges.
- Geist for prose and Geist Mono for labels, numbers, eyebrows and code.
- One green signal (`eez-green`) for live state and focus. The gradient is reserved for the primary action and hover accents.
- Pill-shaped controls, cards with 16px corners, and small 4–5px chips for tool buttons and byte cells.
- Every page says EEZ is pre-mainnet, in text rather than a badge: the walkthrough intro's verified-against line. The index carries no PRE-MAINNET line (owner decision, 2026-10-20).

## Colors

A monochrome bench with one green light and one gradient, used sparingly.

### Primary
- **Work-Light Green** (`eez-green`): the live signal. Used for the focus ring (2px outline, 2px offset) on every link, card and button, stage eyebrows, "what you'll learn" step numbers, and highlighted values in diagrams. Never used for body text or large fills.

### Secondary
- **EEZ Gradient** (`grad-mint` → `grad-steel` → `grad-indigo`, 90°, stops at 0 / 55 / 100%): the brand signal path. Its two-stop form (mint → steel) fills the walkthrough's Play/Start button and lightens to `grad-mint-hover` → `grad-steel-hover` on hover. The three-stop form fills the step progress bar (`#timebar`) under the stage header as each step plays. Its stops also color the diagram arrows and nodes, and steel is the most-used diagram ink.

### Neutral
- **Void** (`void`): outside the stage frame, letterboxing the 1920×1080 stage. Also the text on solid white pills.
- **Bench Canvas** (`canvas`): the page and stage background, with the 42px grid drawn in `rgba(255,255,255,.045)`.
- **Screen** (`screen`): cards and the code panel, one step up from the canvas.
- **Chrome** (`chrome`): the code panel's title bar, the strip above the code that carries the file name.
- **Edge** (`edge`): every 1px border on cards, outline pills and panels.
- **Control / Control Edge / Control Hover** (`control`, `control-edge`, `control-hover`): step buttons, help and tool chips, and the circles in pills.
- **Code Well** (`code-well`): the deepest tone, used for the horizontal-scroll fade on mobile code panels.
- **Ink** (`ink`): titles and primary text.
- **Soft Ink** (`ink-soft`): stage ledes, captions and code text.
- **Quiet Ink** (`ink-quiet`): card hooks and index ledes.
- **Slate** (`muted`): mono labels, back links, CTAs at rest.
- **Lavender Label** (`label`): field labels inside diagrams, such as the key column of a struct.

### Named Rules
**The One Light Rule.** Green means live or focused. If an element isn't the current state, the focused element, or a value being traced, it isn't green.

**The Hover-Only Gradient Rule.** At rest, the gradient appears in only two places on a stage: the primary action (Play or Start) and the step progress bar. Everywhere else it shows up only on hover, as a 1px gradient ring around a hovered card or the fill of a CTA circle.

**The Edge-to-Edge Gradient Rule.** Any gradient fill on an element with a border (pills, step chips, arrow circles, Play/Start) uses `border-box` in the `background` shorthand, e.g. `background: var(--eez-grad-btn) border-box`, and a transparent border. Without it the gradient repeats under the border and a 1px sliver of the start color shows on the far edge. That includes `:hover` rules, because the `background` shorthand resets the box to `padding-box`.

**Known drift (don't copy):**
- The index card hover ring and arrow circle use an older 180° gradient (`#8ce8ab → #3f2acd`) instead of `grad-mint → grad-indigo`.
- The live-dot pulse uses `rgba(63,185,80,…)`, which isn't `eez-green`.
- Two pages still define `screen` as `#0b0b0b` and `edge` as `#1f1f1f`.

Use the tokens above for new work.

## Typography

**Display Font:** Geist (with system-ui, -apple-system, Segoe UI)
**Body Font:** Geist
**Label/Mono Font:** Geist Mono (with ui-monospace, SF Mono, Menlo, Consolas)

**Character:** A neutral grotesque paired with its own mono. Prose reads like documentation, and every label reads like a terminal readout. The index hero splits weights inside one headline: heavy (800) on the words that carry the claim, light (300, `#DCDCDC`) on the connective words.

### Hierarchy
- **Display** (800 / 300 split, 48px, 1.08; 32px under 640px): the index hero only. `text-wrap: balance`.
- **Stage Title** (600, 56px on the 1920 stage, 1.14; 30px when reflowed): the walkthrough intro slide.
- **Stage Lede** (400, 25px, 1.5, max 1280px): intro copy on the stage, in Soft Ink.
- **Caption** (400, 22px, 1.45): the one-sentence narration under each diagram step, in Soft Ink. `text-wrap: pretty`.
- **Title** (600, 17.5px, 1.35): card titles.
- **Body** (400, 18px, 1.55, max 640px): the index hero subline. Ledes on secondary pages use 15.5px.
- **Body Small** (400, 13.5px, 1.55): card hooks and section notes, in Quiet Ink.
- **Code** (Geist Mono 400, 19px on a 34px line; 15px/28px reflowed): the code panel, revealed step by step.
- **Label** (Geist Mono 500, 11.5–12.5px, 0.04–0.16em tracking, uppercase): eyebrows, phase labels, filter chips, CTAs, card numbers.

### Named Rules
**The Readout Rule.** Anything that names, counts or points (eyebrows, step numbers, chips, CTAs, back links, citations) is set in Geist Mono. Anything that explains is set in Geist. Don't mix them in the same element.

**The Bracket Eyebrow Rule.** Index section heads are mono labels in square brackets, such as `[ DAPP DEVELOPERS — QUICKSTART ]`. They're section names, not decoration.

## Layout

- **Index:** one column with a 1200px max width, padded 48px 32px 100px (32px 18px 72px under 640px). Card grids use `repeat(auto-fit, minmax(300px, 1fr))` with 16px gaps, and two-column grids collapse to one under 700px. Quickstart phases are a 150px mono label column next to their card row, which stacks under 700px. Sections are separated by 56px heads, and the page closes with a hairline-topped footer row 72px down.
- **Walkthrough stage:** a fixed 1920×1080 frame scaled by `scaleStage()`.
  - Header bar at the top: home link (EEZ mark), title, NEXT link, step counter.
  - Diagram on the left and code panel on the right (712px tall).
  - Caption and Prev / Play / Next across the bottom.
  - The intro slide covers the stage below the 97px header, padded 96px to the sides, with a three-column "what you'll learn" index.
- **Readable minimums (1120px and up):** the scaled stage holds rendered text at 11px or more and every link and button at 24px or more, by counter-scaling only the elements that would fall below (`applyFloor` in each walkthrough). Code panels are exempt from that rule; instead, a 14px run-command panel grows toward 11px only as far as its longest line still fits the 662px column (so on a 1280 laptop it lands around 9.5-10px). Citation headers ellipsize the directory, never `file:LINE` or the file name. The tool chips (FULL / TEST / COPY) re-pack right to left when they grow. Letterbox bands around the stage use the canvas colour, not black.
- **Reflow:** below 1120px the stage stops scaling and becomes a stacked document. Inline flex rows are forced to wrap, the code panel caps at 60vh with a right-edge fade showing it scrolls sideways, and Prev / Play / Next stretch to full width.
- **Breakpoints:** 640px (index type and gutter), 700px (grids and phases), 1120px (stage reflow).

## Elevation & Depth

The system is flat. Depth comes from tone: canvas (`#0A0A0A`) → screen (`#161616`) → chrome (`#1F1F1F`), with 1px `edge` borders doing the separating. Shadows appear only in response to state, never at rest.

### Shadow Vocabulary
- **Card lift** (`box-shadow: 0 20px 44px -20px rgba(0,0,0,.75)`, with `translateY(-4px)`): card hover only.
- **Field focus** (`box-shadow: 0 0 0 3px rgba(59,229,126,.16)`, `eez-green` at 16%, with a green border): the search input on focus.
- **Live pulse** (`0 0 0 0 → 0 0 0 8px`, fading): a looping halo on "live" status dots.

### Named Rules
**The Flat-At-Rest Rule.** Nothing casts a shadow until the reader touches it. A card with a shadow at rest is a bug.

## Shapes

- **Pills** (100px) for everything you press or filter: CTAs, Play/Prev/Next, filter chips, badges, and the arrow circles inside them.
- **Gently rounded cards** (16px). The search field uses 12px.
- **Small squared chips** (4–5px) for tool buttons in the code panel (FULL, COPY), keyboard hints, and byte cells in diagrams.
- **Circles** (50%) for the help button and the arrow circles.
- **Borders** are always 1px, in `edge` or `control-edge`. On hover a card's border is overdrawn by a 1px gradient ring that follows its 16px corners.

## Components

### Buttons
Quiet until touched. Grey at rest, with one gradient action per stage.
- **Solid pill:** white fill, black mono label (12.5px, 600, 0.03em), padding 5px 5px 5px 20px, ending in a 30px black circle holding an arrow. The circle slides 3px right on hover. This is the index's primary entry, `START THE QUICKSTART · 00`, linking to card 00.
- **Outline pill:** the same shape on a transparent fill with an `edge` border. The circle is a `control` fill with an `edge` border. Used for track entries: `ROLLUP OPERATORS` and `PROTOCOL RESEARCHERS` beside the solid pill, jumping to their sections (and clearing any active filter or search).
- **Play / Start (stage primary):** the two-stop gradient fill running edge to edge (`border-box`), canvas-colored text, a 1px transparent border, 12px 28px (Start is 16px 34px at 20px text). It brightens to the hover gradient on hover, also `border-box`. No colored outline: a steel ring around the mint end reads as a stray stroke.
- **Step buttons (Prev/Next):** `control` fill, `control-edge` border, Soft Ink text, 12px 22px. They lift to `control-hover` on hover and drop to 38% opacity when disabled.
- **Focus:** every button and link gets a 2px `eez-green` outline with a 2px offset.

### Chips
- **Filter chips:** mono 11.5px uppercase with counts (`DAPP DEVS (14 + 1 SOON)`), on a dark fill with a `#222` border. Hover brightens the text and border. The active chip inverts to white with black text.
- **Badges:** mono 11px on a transparent fill with a `control-edge` border and pill shape, used for COMING SOON.

### Cards / Containers
- **Corner Style:** 16px.
- **Background:** `screen`, going to `#0D0D0D` on hover.
- **Shadow Strategy:** none at rest; card lift on hover (see Elevation).
- **Border:** 1px `edge`. On hover a 1px gradient ring fades in around the whole card (a masked `::before` at `inset:-1px`, `border-radius:inherit`, `border-box` gradient), so the card itself must not use `overflow:hidden`.
- **Internal Padding:** 28px 26px 26px, with a 16px vertical gap.
- **Anatomy:**
  - a mono card number (`00`, quiet `#808080`, 4.6:1 on `screen`, brightening on hover; it doesn't dim when visited);
  - a Title;
  - a Body Small hook that states the consequence;
  - a mono CTA row pinned to the bottom (`WATCH THE 3-STEP WALKTHROUGH`) with a 26px arrow circle that fills with the gradient on hover.
  - Visited cards dim their title to `#B8B8B8`.

### Inputs / Fields
- **Search:** a `#090909` fill with a `#222` border, 12px radius and a leading search icon. A trailing `/` keyboard hint sits in a 4px chip.
- **Focus:** the border turns `eez-green` and a soft 3px green halo appears.
- **Empty state:** a dashed `#262626` box with centered mono text that offers a way out ("Try another keyword or clear filters").

### Navigation
- **Logo:** the full EEZ lockup (mark plus "Ethereum Economic Zone" wordmark) at 46px tall on the index from 641px up, so the wordmark stays legible; the mark alone (36px) on phones. Walkthrough headers carry the mark (26px stage px) plus "Quickstarts" as the link home. Never shrink the lockup below 46px: the wordmark becomes unreadable.
- **Index header:** the EEZ logo on the left. Walkthroughs say PRE-MAINNET in the intro's verified-against line, with no header badge; the index has no PRE-MAINNET line. Mono 12px external links (`eez-core-protocol ↗`, `eez.dev testnet ↗`) in `#9A9A9A` on the right, going white on hover, plus a circular `?` help button. Wraps on narrow screens.
- **Index entry row:** under the hero, one solid pill (the Quickstart at 00) and two outline pills (operator and researcher tracks), stacking full-width on phones. Under it, two quiet mono text links: `First time here? Take the quick tour` (a button that opens the page tour; it has no gradient, so the index has no at-rest gradient at all) and `Reading order for operators and researchers`, to `start-here.html`.
- **Stage header:** the EEZ mark plus `Quickstarts` link home (mono 12px, Slate), title, `NEXT: … →` link (nudges right), the `STEP 1 OF 3` counter and `ALL EXAMPLES →`. The header link stays because it's the only way on while the lead-in hides the bottom bar.
- **Up-next button:** the main way on to the next walkthrough. It's a pill in the bottom bar right after `‹ Prev ▶ Play Next ›`, behind a hairline divider, because that's where the reader is when step 3 ends. It's an outline pill set entirely in mono: a muted `UP NEXT` kicker, the next title at 15/600, and a 34px `control` arrow circle. The circle fills with the gradient and slides 3px only on hover. On the last step (where `Next ›` disables) it gets `.is-final`: the edge and kicker turn `eez-green`, because that's the live state. There's no fill, glow or pulse. Below 1120px it becomes a full-width row under the step buttons. At the end of a track it reads `TRACK COMPLETE · Back to all examples`.

### Walkthrough Stage (signature component)
The site's core component.
- **Diagram (left):** real values, with byte cells as 4px mono chips and field labels in Lavender. Arrows and nodes are drawn in the gradient stops.
- **Code panel (right):** `screen` fill, Geist Mono at 19/34, lines revealed per step through `codeByStep`. FULL and COPY tool chips sit top-right. A citation line under it, such as `Verified against eez-core-protocol @ 9a1f815 — pre-mainnet; interfaces may move.`, is set as a tiny mono note.
- **Caption:** a single sentence across the bottom in Soft Ink, next to Prev / Play / Next.
- **Intro slide:** a green mono eyebrow (track name), Stage Title, Stage Lede, and three "what you'll learn" columns. Each column has a hairline top rule, a green mono step label and Soft Ink body, with no boxes and no fills.
- **Motion:**
  - `riseIn` (12px rise and fade, 0.4s) for entrances;
  - `flowByte` (14px slide) for bytes moving through a derivation;
  - all transitions are 0.15–0.25s `ease`;
  - `prefers-reduced-motion` turns every animation and transition off.

## Do's and Don'ts

### Do:
- **Do** start every new walkthrough from the `pr5` template (`scripts/new-demo.sh`) and keep the 1920×1080 stage, the `codeByStep` reveal, the intro's verified-against line (it carries "pre-mainnet"), the `NEXT:` chain and the 1120px reflow.
- **Do** use the `:root` custom properties (`--eez-green`, `--eez-screen`, `--eez-edge`, `--eez-grad-btn`, `--muted`, `--label`) rather than literal hex.
- **Do** set every label, number, chip, CTA and citation in Geist Mono, and every explanation in Geist.
- **Do** give every interactive element the 2px `eez-green` focus ring with a 2px offset, and a hit area of at least 24px on every device.
- **Do** put real values in diagrams (addresses, hashes, byte cells), never placeholder boxes.
- **Do** keep the 42px hairline grid on every canvas, index and stage alike.

### Don't:
- **Don't** put the gradient on any at-rest element besides the stage's primary action and step progress bar.
- **Don't** put a gradient on a bordered element without `border-box`, and don't outline a gradient fill with a solid colored border. Everything else gets it on hover only.
- **Don't** add shadows at rest, glows, or glassy blur to cards or panels. Depth is tonal.
- **Don't** color body text, warnings or decoration green. Green means live or focused.
- **Don't** put code on index cards. Cards carry a title, a consequence hook and a CTA.
- **Don't** make the pre-mainnet note or COMING SOON louder, such as red or amber banners, or drop them. The walkthrough header carries no PRE-MAINNET badge; the note lives in the intro line and the index footer.
- **Don't** copy the drift values listed under Colors (the 180° card gradient, `rgba(63,185,80)` green, `#0b0b0b`/`#1f1f1f` page overrides).
