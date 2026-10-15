# Toothbrush Timer — Product Requirements

## 1. Overview

Toothbrush Timer is a simple Garmin Connect IQ watch application intended to help a user brush their teeth for the recommended two-minute duration.

The application provides:
- a two-minute countdown timer;
- haptic feedback every 30 seconds;
- a distinct longer haptic signal when the full two minutes have elapsed;
- a visual indication of overall progress and the current 30-second stage;
- simple pause, resume, and stop controls.

The primary target device is Garmin Vivoactive 6. Support for additional compatible Garmin watches is desirable when it does not require substantial device-specific UI variants or significant additional complexity.

The initial version is primarily intended for personal use, but the implementation should follow reasonable product and Connect IQ development best practices so that publishing the application later remains practical.

## 2. Goals

The MVP should:

- make it easy to start a two-minute toothbrushing session;
- provide clear 30-second interval cues without requiring the user to look at the screen;
- clearly indicate the remaining brushing time when the user does look at the screen;
- make the current quarter of the brushing session visible;
- allow the user to pause, resume, or stop the timer;
- automatically return to the normal watch interface when a completed session ends;
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

### 4.1 Application Launch

When the user opens the application, the initial screen is displayed.

The initial screen contains:

- a simple toothbrush icon near the top of the screen;
- the initial remaining time: `2:00`;
- a Start control.

The timer does not begin automatically.

### 4.2 Starting a Session

When the user selects Start:

- the two-minute countdown begins;
- the timer screen becomes active;
- the display should remain awake during active countdown;
- the remaining time updates continuously;
- visual progress through the four 30-second stages is shown;
- Pause and Stop controls are available.

### 4.3 Pausing

When the user selects Pause:

- countdown stops;
- elapsed time is preserved;
- remaining time is preserved;
- the current stage is preserved;
- the Pause control becomes Resume;
- normal system screen dimming behavior is allowed while paused.

When the user selects Resume:

- countdown continues from the exact paused position;
- the display should again remain awake during active countdown.

### 4.4 Stopping

When the user selects Stop:

- the active session is cancelled immediately;
- no confirmation dialog is shown;
- the application returns to the initial screen;
- the timer is reset to `2:00`;
- the progress indicator is reset to its initial state.

### 4.5 Leaving the Application

If the user invokes the standard Back or exit action during an active session:

- the session is cancelled;
- the timer does not continue in the background;
- the application exits normally.

No confirmation dialog is required.

### 4.6 Completing a Session

At the end of two minutes:

- the final, longer vibration signal is emitted;
- the timer stops;
- the session is considered complete;
- the application automatically exits;
- the user is returned to the normal watch interface.

No completion screen is required.

## 5. Timer Behavior

### 5.1 MVP Timing

The MVP uses the following fixed timing values:

- total brushing duration: 120 seconds;
- stage duration: 30 seconds;
- number of stages: 4.

These values are fixed from the user's perspective in the MVP.

However, the internal design should avoid unnecessarily coupling timer logic, UI layout, and vibration scheduling to literal hardcoded values. The implementation should make it reasonably straightforward to introduce configurable total duration and interval duration in a future version.

For example, timing values should be represented as centralized configuration or constants rather than duplicated throughout the codebase.

### 5.2 Interval Signals

Short vibration signals occur when elapsed brushing time reaches:

- 30 seconds;
- 60 seconds;
- 90 seconds.

All three intermediate vibration signals use the same pattern.

### 5.3 Completion Signal

At 120 seconds, the application produces a vibration that is clearly longer or otherwise more noticeable than the intermediate signals.

The final signal should be distinguishable from the 30-second interval signals through duration/pattern rather than sound.

### 5.4 System Haptic Restrictions

The application should respect normal Garmin/system restrictions and settings that affect haptic feedback.

The application should not attempt to bypass system behavior such as Do Not Disturb or other platform-level haptic restrictions.

## 6. Timer Screen

The active timer screen should contain the following elements:

- a simple toothbrush icon near the top;
- a prominent digital remaining-time display;
- a circular progress indicator divided into four quarters;
- a stage label in the format `Stage 1/4`;
- Pause/Resume control;
- Stop control.

The layout should prioritize the remaining time and overall progress over decorative elements.

## 7. Remaining Time

The application shows remaining time as minutes and seconds.

Examples:

- `2:00`
- `1:47`
- `0:30`
- `0:01`

The displayed value represents time remaining until the two-minute session is complete.

## 8. Progress Indicator

A circular progress indicator represents the complete two-minute brushing session.

The circle is divided visually into four equal quarters.

Each quarter represents one 30-second stage.

Progress should be continuous rather than changing only every 30 seconds.

For example, after 50 seconds:

- the first quarter is fully completed;
- the second quarter is partially completed;
- the remaining quarters are not yet completed.

The visual design should make completed progress clearly distinguishable from remaining progress while remaining readable on small watch displays.

## 9. Stage Indicator

The application displays the current stage using the following format:

`Stage X/4`

where `X` is the current stage number.

Examples:

- `Stage 1/4`
- `Stage 2/4`
- `Stage 3/4`
- `Stage 4/4`

Stage changes occur at the same 30-second boundaries as the intermediate vibration signals.

## 10. Screen Behavior

During active countdown:

- the application should request that the display remain awake, subject to platform limitations and normal Garmin behavior.

During pause:

- normal system dimming behavior is allowed.

The implementation should avoid unnecessary battery usage beyond what is required for a short two-minute active session.

## 11. Controls

The application should support touch input on devices that provide a touchscreen.

Where practical and supported by the device, standard Garmin hardware buttons should also provide equivalent control paths.

The application should not depend exclusively on touchscreen interaction if hardware-button support can be added without significant complexity.

Exact button mappings may vary by device and should follow Garmin platform conventions.

## 12. Localization

The MVP user interface is English-only.

However, the application must be implemented using the standard Connect IQ localization/resource mechanisms.

User-visible strings must not be embedded directly in application logic or UI code.

The initial localization resources should contain only English strings.

Examples of localizable strings include:

- `Start`
- `Pause`
- `Resume`
- `Stop`
- `Stage %d/4`

The architecture should allow additional languages to be added later by supplying additional localization resources rather than changing application logic.

## 13. Visual Design

The MVP visual style should be simple and functional.

### 13.1 Toothbrush Icon

The application should use a simple static toothbrush illustration/icon.

Requirements:

- visually recognizable at watch-screen size;
- monochrome or limited-color design;
- no animation required;
- no dependence on large or high-resolution assets.

### 13.2 General UI

The UI should:

- remain legible at a glance;
- prioritize the countdown;
- avoid unnecessary text;
- avoid dense controls;
- follow Garmin/Connect IQ interaction conventions where practical.

## 14. Device Support

### 14.1 Primary Device

Garmin Vivoactive 6 is the primary target and should be treated as the mandatory reference device for development and testing.

### 14.2 Additional Devices

Additional Garmin Connect IQ watches may be supported when:

- the required APIs are available;
- the display size and shape can be handled without a dedicated redesign;
- the interaction model can be supported reasonably;
- adding support does not significantly increase implementation complexity.

The MVP does not require support for all legacy Connect IQ devices.

Compatibility decisions should favor a maintainable common implementation over a large number of device-specific UI variants.

## 15. Data and Persistence

The MVP does not require persistent user data.

The application does not need to store:

- completed sessions;
- interrupted sessions;
- brushing history;
- statistics;
- preferences.

Closing the application may discard all current session state.

No network access is required.

## 16. Future Extensions

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

## 17. MVP Acceptance Criteria

The MVP is considered functionally complete when all of the following are true:

1. The application launches to a screen showing a toothbrush icon, `2:00`, and Start.
2. Selecting Start begins a two-minute countdown.
3. Remaining time is visibly updated during the session.
4. A circular four-quarter progress indicator shows continuous session progress.
5. The current stage is displayed as `Stage X/4`.
6. A short vibration occurs at 30 seconds.
7. A short vibration occurs at 60 seconds.
8. A short vibration occurs at 90 seconds.
9. The three intermediate vibrations use the same pattern.
10. A clearly longer/distinct vibration occurs at 120 seconds.
11. The application exits automatically after the final signal.
12. Pause freezes the countdown and preserves progress.
13. Resume continues from the paused position.
14. Stop immediately cancels the session and returns to the initial screen.
15. Back/exit during a session cancels the session and exits the application.
16. Active countdown keeps the display awake as far as supported by the platform.
17. Paused state allows normal system dimming.
18. No sound is produced by the application.
19. No user settings are required for MVP operation.
20. User-visible strings are loaded from localization resources rather than hardcoded in application logic.
21. Garmin Vivoactive 6 is supported and tested as the primary target device.
22. The application does not store brushing history or other persistent session data.

## 18. Implementation Principles

The implementation should favor simplicity, reliability, and maintainability.

In particular:

- timer state should have a single authoritative source;
- vibration scheduling should derive from timer/stage configuration;
- timing constants should be centralized;
- UI strings should come from localization resources;
- device-specific code should be minimized;
- application behavior should remain correct across pause/resume transitions;
- duplicate vibration events must be avoided after pause/resume or UI refreshes;
- completion should occur exactly once per session;
- timer behavior should not depend solely on screen refresh frequency.
