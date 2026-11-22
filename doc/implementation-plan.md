# Timer screen spacing

This plan covers the [shared layout](design/ui-design.md#shared-layout) for READY, RUNNING, and PAUSED.

- [x] **Adjust the shared positions.** In [TimerLayout.mc](../source/TimerLayout.mc), adjust the offsets relative to the ring’s inner radius. Move the toothbrush up most, the countdown less, and the stage label least. Keep the control row in place so each gap above it grows.
- [x] **Build and test for Vivoactive 6.** The debug and test builds succeeded and all 63 unit tests passed, including layout geometry. See the [verification record](verification.md#timer-screen-spacing-2026-11-22).
- [ ] **Check the simulator layout.** Run the “Shared timer layout” scenario in the [manual acceptance matrix](testing.md#manual-acceptance-matrix). Check the gaps and watch for movement of the toothbrush or countdown during Start, Pause, and Stop.
- [ ] **Check readability on the watch.** Run the physical part of the same scenario on Vivoactive 6. Record the tested artifact, results, and any pending checks in the [verification record](verification.md).
