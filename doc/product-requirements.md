# Toothbrush Timer — Product Requirements

## 1. Overview

Toothbrush Timer is a Garmin Connect IQ watch app for two-minute brushing sessions, with visual progress, 30-second haptic cues, and a distinct completion signal. Vivoactive 6 is the primary target. The initial version is for personal use, with future publication kept practical.

## 2. Goals

The MVP should:

- make it easy to start a two-minute toothbrushing session;
- provide clear 30-second interval cues without requiring the user to look at the screen;
- clearly indicate the remaining brushing time when the user does look at the screen;
- make the current quarter of the brushing session visible;
- allow the user to pause, resume, or stop the timer;
- briefly acknowledge completion, then automatically return to the normal watch interface;
- remain simple and require no configuration;
- be structured so that localization and configurable durations/intervals can be added later without major redesign.

## 3. Non-Goals for MVP

The MVP does not include:

- configurable brushing duration;
- configurable interval duration;
- configurable vibration strength or vibration patterns;
- sound alerts;
- brushing history or statistics;
- persistent session tracking;
- user accounts;
- settings screens;
- cloud synchronization;
- achievements, reminders, streaks, or gamification;
- animated toothbrush graphics;
- multiple UI themes;
- non-English translations.

## 4. Primary User Flow

Screen appearance follows [UI design](design/ui-design.md); display behavior in every state follows [§7](#7-screen-behavior).

### 4.1 Application Launch

Every launch starts fresh in READY at `2:00`, with Start available. The timer does not begin automatically.

### 4.2 Starting a Session

When the user selects Start:

- the two-minute countdown begins;
- the timer screen becomes active;
- the remaining time updates continuously;
- visual progress through the four 30-second stages is shown;
- Pause and Stop controls are available.

### 4.3 Pausing

When the user selects Pause:

- countdown freezes, preserving elapsed time, remaining time, stage, and progress;
- the Pause control becomes Resume, with the PAUSED appearance defined in UI design.

When the user selects Resume, countdown continues from the exact paused position.

### 4.4 Stopping

When the user selects Stop before completion has been reached:

- the active session is cancelled immediately;
- no confirmation dialog is shown;
- the application returns to the initial screen;
- the timer is reset to `2:00`;
- the progress indicator is reset to its initial state.

If completion has been reached when Pause or Stop is processed, completion takes priority (§4.6).

### 4.5 Leaving the Application

Back and other system exit actions take priority in every state, including at the completion boundary. Exit immediately without confirmation or waiting for a cue or presentation to finish. Processing exit must not trigger a new cue or start a completion presentation.

Exit cancels pending callbacks and discards the session; timing never continues in the background. Actual suspension/termination also discards the session, and a later launch starts fresh. Callbacks from a discarded session must not affect a new launch.

### 4.6 Completing a Session

At the end of two minutes, unless system exit takes priority (§4.5):

- the final signal of three short vibrations separated by brief pauses is emitted once;
- the timer stops;
- the session is considered complete;
- the COMPLETED presentation replaces the countdown and controls;
- the completion screen is presented for approximately three seconds, then the application automatically exits;
- the user is returned to the normal watch interface.

Completion takes priority over Pause/Stop and overdue interval cues. The presentation duration is centrally defined and tunable without changing brushing duration or cue scheduling; it is not a user setting. The delay starts when completion is handled, even if observed late. Brushing time does not advance during it, and redraws or input must not repeat the cue. Haptic suppression or failure must not prevent presentation or automatic exit.

System-controlled dimming/blanking still applies; the app must not wake the display or extend the delay waiting for visibility.

## 5. Timer Behavior

### 5.1 MVP Timing

The MVP uses the following fixed timing values:

- total brushing duration: 120 seconds;
- stage duration: 30 seconds;
- number of stages: 4.

These values are fixed from the user's perspective. Centralize durations and derive stage count so future configuration does not require redesigning timer logic, UI, or cue scheduling.

### 5.2 Interval Signals

Identical short vibration signals occur at 30, 60, and 90 seconds of elapsed brushing time.

### 5.3 Completion Signal

The completion signal (§4.6) must be clearly distinguishable from the single-pulse interval cue. Pulse strength, duration, and spacing may be tuned on Vivoactive 6; no sound is used. All three pulses must remain perceptible through automatic exit when system settings permit haptics. User/system exit must not wait for the pattern to finish.

### 5.4 System Haptic Restrictions

Respect Garmin/system haptic restrictions, including Do Not Disturb; do not attempt to bypass them.

## 6. Timer Presentation

RUNNING and PAUSED share a layout showing remaining time, overall progress, current stage, and Pause/Resume and Stop controls. Prioritize time and progress over decoration; [UI design](design/ui-design.md) specifies appearance and state differences.

### 6.1 Remaining Time

Show remaining brushing time as `m:ss`, starting at `2:00`. Rounding follows [technical design §6.2](technical-design.md#62-running-and-paused-time).

### 6.2 Progress Indicator

The circular indicator represents elapsed brushing time continuously, with one segment per configured stage. READY is empty; PAUSED preserves the exact fraction; COMPLETED is full. Filled and remaining progress must be clearly distinguishable. Geometry and per-segment fill follow [UI design §4](design/ui-design.md#4-dynamic-progress-ring).

### 6.3 Stage Indicator

Display `Stage X/N`, where `X` is the current stage and `N` is the configured count (4 in the MVP). Stage changes occur at the same 30-second boundaries as intermediate cues.

## 7. Screen Behavior

The application must not control the backlight or request that the display remain awake in any state, including on Start or Resume. Display wake, brightness, dimming, and timeout are controlled exclusively by Garmin system mechanisms and the user's watch settings.

The display may dim or turn off during active countdown as well as while idle or paused. The user relies on the watch's normal wake mechanisms to view the timer; continuous visibility and gesture wake under all power/sleep settings are not guaranteed.

Display dimming or blanking alone must not pause or reset the session. While the application remains active, countdown, permitted haptic cues, and automatic completion/exit continue independently of display visibility. Actual application suspension or termination retains the existing session-discard behavior.

The implementation should avoid unnecessary battery usage beyond what is required for a short two-minute active session.

## 8. Controls

Support touch on touchscreen devices and equivalent hardware controls where practical without significant complexity. Device-specific mappings should follow Garmin conventions.

## 9. Localization

All user-visible text must use standard Connect IQ string resources, initially English only. This includes displayed control labels, the stage format with both current stage and stage count, and the completion message. Additional languages should require resources rather than application-logic changes.

## 10. Visual Design

The approved [UI design](design/ui-design.md) defines all four state layouts, palette, components, and separate launcher artwork. The interface must remain legible at a glance, avoid unnecessary text or dense controls, and follow Garmin conventions. Functional requirements take precedence over reference-image inaccuracies.

## 11. Device Support

### 11.1 Primary Device

Garmin Vivoactive 6 is the primary target and should be treated as the mandatory reference device for development and testing.

### 11.2 Additional Devices

Additional Garmin Connect IQ watches may be supported when:

- the required APIs are available;
- the display size and shape can be handled without a dedicated redesign;
- the interaction model can be supported reasonably;
- adding support does not significantly increase implementation complexity.

The MVP does not require support for all legacy Connect IQ devices.

Compatibility decisions should favor a maintainable common implementation over a large number of device-specific UI variants.

## 12. Data and Persistence

The MVP uses no persistence or network access; session disposal follows §4.5.

## 13. Future Extensions

The following features are explicitly outside the MVP but should remain reasonably possible without redesigning the application's core architecture:

- configurable total brushing duration;
- configurable stage/interval duration;
- configurable number of stages;
- alternative vibration patterns;
- additional languages;
- optional settings screen;
- support for additional Garmin device families;
- brushing history or statistics.

The MVP should not implement these features prematurely, but code structure should avoid assumptions that would make them unnecessarily difficult to introduce.

## 14. MVP Acceptance Criteria

Acceptance requires the following, verified using [testing.md](testing.md):

1. Fresh launch shows READY at `2:00`; only Start begins countdown (§4.1–4.2).
2. Remaining time, continuous progress, and current stage follow §6.
3. Pause preserves time/progress/stage, Resume continues exactly, and Stop resets immediately without confirmation (§4.3–4.4), subject to completion priority (§4.6).
4. Identical interval cues occur at 30/60/90 seconds; one distinct three-pulse cue occurs at completion, subject to system restrictions and exit priority (§§4.5–5).
5. Completion presentation and automatic exit follow §4.6, including when haptics fail or are suppressed.
6. Back/system exit takes priority immediately; cleanup cancels pending work, and relaunch is fresh (§4.5).
7. All four screens and the separate launcher icon follow [UI design](design/ui-design.md).
8. Display control is entirely system-owned; dimming/blanking alone does not interrupt timing, permitted cues, or completion/exit (§7).
9. Controls and resource-based English text follow §§8–9; Vivoactive 6 is tested as the primary target (§11).
10. No sound, user settings, persistence, or background timing is introduced (§§3, 4.5, and 12).

## 15. Implementation Principles

Follow [technical design](technical-design.md) for architecture, timing, lifecycle, and implementation constraints, and [AGENTS.md](../AGENTS.md) for development policy.
