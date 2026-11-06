# Toothbrush Timer — UI Design

## 1. Scope and References

This document specifies the approved visual design for Garmin Vivoactive 6, using relative layout that can extend to compatible displays. [Product requirements](../product-requirements.md) define behavior and acceptance; [technical design](../technical-design.md) defines architecture, timing, and lifecycle handling.

Approved references:

- [Application icon](reference/app-icon.png)
- [READY](reference/ready.png)
- [RUNNING](reference/running.png)
- [PAUSED](reference/paused.png)
- [COMPLETED](reference/completed.png)

These images establish appearance, composition, and visual hierarchy, not pixel-perfect specifications. Generated gradients, shape inconsistencies, and approximate progress do not override this specification or functional requirements. See [README](../../README.md) for implementation status.

## 2. Semantic Palette

Use flat colors and reuse these semantic values throughout the interface and static artwork. The values establish a consistent palette rather than sampling every shade in the generated references.

| Semantic color | Hexadecimal | Uses |
| --- | --- | --- |
| Background | `#000000` | Screen and icon background; primary-button text/icons; thin separation outline in the launcher icon |
| Primary foreground | `#FFFFFF` | Countdown, completion message, toothbrush body/bristles and toothpaste interior, Stop icon |
| Accent | `#00E6B0` | RUNNING/COMPLETED progress, Start/Pause/Resume buttons, toothpaste outline in every state, celebratory rays, filled launcher-icon arcs |
| Paused progress | `#FFD740` | Filled progress only while PAUSED; warm yellow |
| Secondary surface | `#3A4147` | Unfilled ring segments, Stop button, unfilled launcher-icon arcs |
| Secondary foreground | `#A6A6A6` | Stage label and other secondary text if required |

Avoid gradients, shadows, glows, and extra decorative colors. Use the same accent in exported toothpaste artwork and programmatically drawn elements.

## 3. Layout and Components

### Shared layout

Use a black canvas. Place the progress ring near the circular screen edge with a safe inset so its stroke is not clipped. Size its radius, stroke, and gaps relative to available display dimensions. The ring surrounds the entire interface, including the bottom controls; it is not a small ring around the toothbrush.

Center content inside the ring: toothbrush in the upper interior, countdown near the center, stage label immediately below when applicable, then controls. Reserve clearance for buttons and touch targets on the curved display. Tune relative stroke/gap sizes, typography, and button dimensions to actual display and touch constraints; no model-specific layout variant is required.

### Toothbrush

Use a consistent static illustration: a slightly angled white handle and white bristles beneath toothpaste with an accent outline and white interior. Preserve recognizability at watch size. The in-app illustration contains no ring of its own; it may be larger on COMPLETED to match the reduced content density.

### Text

The countdown is the dominant element: large, white, centered, and formatted as `m:ss`. The stage label is smaller, muted gray, and centered below it. Keep typography legible with standard Connect IQ fonts where practical and allow for localized text widths without hardcoded mockup dimensions.

Follow the requirements for [time](../product-requirements.md#61-remaining-time), [stage text](../product-requirements.md#63-stage-indicator), and [localization](../product-requirements.md#9-localization).

### Buttons

Use rounded, pill-like shapes with generous touch targets and the palette in §2:

- Start: one wide primary button with a centered label.
- Pause/Resume: primary button on the left, with two vertical bars for Pause or a right-pointing play triangle for Resume.
- Stop: secondary-surface button on the right with a square icon.

The active-state references use icon-only controls; visible labels are optional. Preserve identical button geometry between RUNNING and PAUSED.

## 4. Dynamic Progress Ring

Draw equal segments separated by small visible gaps, with rounded ends where practical. The MVP has four segments, one per 30-second stage. Derive the count and equal angular spacing from the configured stage count `N`, not a literal four.

Progress advances clockwise from the top (12 o'clock). A narrow separator is centered on each stage boundary, including the top seam; the first drawable arc begins just clockwise of that seam. Each stage occupies an angular slot of `360° / N`, with a small gap deducted consistently from its drawable arc. Keep the gaps visible even at full completion.

Use normalized elapsed brushing progress `p` from the authoritative timer, clamped to `0..1`. For zero-based segment index `i`, its filled fraction is:

```text
segmentFill = clamp(N * p - i, 0, 1)
```

Apply this fraction to that segment's drawable arc length. Gaps are decorative spacing, not extra elapsed-time intervals; do not fill a single unadjusted sweep and then erase separators if that shifts the per-stage fraction. Draw all unfilled track in the secondary-surface color, overlaying only the filled portions in the current state's progress color.

At exact stage boundaries the preceding segment is full and the next has zero fill. Partial progress advances throughout each stage using actual elapsed time, independently of rounded countdown text.

## 5. State Presentations

All states use the shared components above and the corresponding reference in §1.

| State | Presentation |
| --- | --- |
| READY | Empty ring, toothbrush, initial time derived from configured duration, Start; no stage label |
| RUNNING | Accent-filled progress, toothbrush, countdown, stage label, Pause and Stop |
| PAUSED | RUNNING layout and frozen values; only filled progress changes to paused yellow and Pause becomes Resume. Toothpaste, primary button, and unfilled track retain their colors |
| COMPLETED | Full accent ring with gaps, toothbrush above centered white `Nice job!`, small static accent rays on either side; no countdown, stage label, buttons, or active control hit regions |

Completion timing and exit priority follow [requirements §4](../product-requirements.md#4-primary-user-flow); display behavior follows [§7](../product-requirements.md#7-screen-behavior). No animation or complex effects are required.

## 6. Launcher Icon

Follow [app-icon.png](reference/app-icon.png): a dark background, white toothbrush and bristles, mint-green toothpaste outline, and a four-segment ring. Mint-green progress runs clockwise from the top to the toothbrush handle at the lower-left: the two right-hand segments are fully mint green, and the lower-left segment is mint green only from the bottom to the handle. The rest of the lower-left segment and the entire upper-left segment are dark gray. The toothbrush handle crosses the ring at the color transition, with a thin black outline separating it from the ring at the intersection.

This static four-segment motif is independent of runtime stage geometry. The launcher and in-app toothbrush share a visual style but use separate resources. Rendering and asset preparation follow [technical design §8](../technical-design.md#8-ui) and [§13](../technical-design.md#13-resources-and-localization).
