# Toothbrush Timer — Product Requirements

## Scope

Toothbrush Timer is a Garmin Connect IQ watch app for two-minute brushing sessions, with visual progress, 30-second haptic cues, and a distinct completion signal. Garmin Vivoactive 6 is the primary development and acceptance device. The app is for personal use, with future publication kept practical.

These requirements define current behavior. [Technical design](technical-design.md) defines implementation constraints, [UI design](design/ui-design.md) defines appearance, and [testing](testing.md) defines regression coverage.

The app requires no configuration and has English resources only. Current scope excludes user-configurable timing or vibration, sound, settings screens, history/statistics, persistence, accounts, networking/cloud synchronization, reminders, achievements/streaks/gamification, animated toothbrush graphics, and multiple themes.

## Session behavior

| State/action | Required behavior |
| --- | --- |
| Launch | Always start fresh in READY at `2:00`, with empty progress and Start. Never start automatically or restore a discarded session. |
| Start | Enter RUNNING; continuously update remaining time, progress, and stage; offer Pause and Stop. |
| Pause | Freeze elapsed/remaining time, stage, and exact progress; replace Pause with Resume. |
| Resume | Continue from the exact paused position; paused time never counts toward brushing time. |
| Stop | Before completion is reached, cancel immediately without confirmation and reset to READY. |
| Completion | Stop brushing time, emit one three-pulse cue, replace countdown and controls with COMPLETED, then exit automatically after approximately three seconds. |
| Back/system exit | Exit immediately in every state without confirmation, a new cue, or a new completion presentation. |

Priority is **Back/system exit, then completion, then Pause/Stop or overdue interval cues**. If completion has been reached when Pause or Stop is processed, completion wins.

Exit and actual suspension/termination cancel pending callbacks and discard the session. No timing continues in the background, and callbacks belonging to a discarded session must not affect a new launch. System exit never waits for a submitted vibration or completion presentation to finish.

### Completion presentation

The completion delay starts when completion is handled, even if observed late. It is centrally defined and tunable, separate from brushing duration and cue scheduling, and is not a user setting. Brushing time remains terminal during the delay; redraws or input must not repeat completion effects.

Haptic suppression or failure must not prevent the presentation or automatic exit to the normal watch interface. System dimming/blanking still applies: do not wake the display or extend the delay waiting for visibility.

## Timing and haptics

- Brushing duration is 120 seconds, divided into equal 30-second stages. Centralize durations and derive the stage count (currently four).
- Identical short single-pulse cues occur at 30, 60, and 90 seconds of active brushing time.
- Completion uses three short pulses separated by brief pauses, clearly distinct from interval cues. Strength, duration, and spacing may be tuned on Vivoactive 6; all three pulses must be perceptible through automatic exit when system settings permit.
- Respect Garmin/system haptic restrictions, including Do Not Disturb. Do not bypass them or use sound.

Delayed-callback handling and exactly-once cue processing follow the [timing model](technical-design.md#timing-and-cue-detection).

## Presentation and controls

RUNNING and PAUSED share remaining time, overall progress, current stage, and Pause/Resume and Stop controls. Prioritize legible time/progress over decoration; follow Garmin conventions and the approved [state layouts, palette, and separate launcher artwork](design/ui-design.md). Functional requirements take precedence over reference-image inaccuracies.

- **Time:** show `m:ss`, starting at `2:00`, using [ceiling rounding](technical-design.md#timing-and-cue-detection) so `0:01` remains until completion.
- **Progress:** continuously represent elapsed brushing time, with one segment per configured stage. READY is empty, PAUSED preserves the exact fraction, and COMPLETED is full. Filled and remaining progress must be distinct; geometry follows [UI design](design/ui-design.md#4-dynamic-progress-ring).
- **Stage:** display `Stage X/N` using the current stage and configured count. Stage changes coincide with interval boundaries.
- **Input:** support touch and equivalent hardware controls where practical without significant complexity; mappings follow Garmin conventions. COMPLETED exposes no active controls, but Back/system exit remains available.

## Screen behavior

Display wake, brightness, dimming, and timeout belong exclusively to Garmin system mechanisms and user settings. Do not control the backlight or request keep-awake behavior in any state, including Start or Resume.

The display may dim or turn off during active, paused, or idle sessions. Normal watch wake mechanisms apply; continuous visibility and gesture wake in every power/sleep mode are not guaranteed.

Dimming/blanking alone must not pause or reset the session. While the application remains active, timing, permitted cues, and automatic completion/exit continue independently of visibility. Actual suspension/termination discards the session as above. Avoid unnecessary battery usage beyond the short active session.

## Localization

Load all user-visible text through standard Connect IQ string resources, currently English only. This includes displayed control labels, completion text, and the stage format with both current stage and stage count as arguments. Additional languages should require resources rather than application-logic changes.

## Device support

Vivoactive 6 is mandatory. Additional devices may be supported when the required APIs, display geometry, and interaction model work without a dedicated redesign or significant complexity. Prefer a maintainable common implementation over device-specific views; supporting all legacy devices is not required.

## Possible extensions

Uncommitted possibilities include configurable total/stage durations and stage count, alternative vibration patterns, additional languages, settings, more device families, and brushing history/statistics. Do not implement them speculatively. Preserve centralized timing, derived stage count, resource-based text, and component boundaries so later requirements can be introduced without unnecessary redesign.

Acceptance requires the behavior above and the approved UI, verified through [testing.md](testing.md). [Verification](verification.md) records what was actually checked and its limits; a historical pass does not certify a later change.
