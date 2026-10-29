import Toybox.Lang;
import Toybox.Test;
import Toybox.WatchUi;

(:test)
class DelegateTestView extends ToothbrushTimerView {
    var layout as TimerLayout = new TimerLayout(390, 390);

    function initialize(timer as BrushingTimer, config as TimerConfig) {
        ToothbrushTimerView.initialize(timer, config);
    }

    function getLayout() as TimerLayout? {
        return layout;
    }
}

(:test)
class DelegateTestHaptics extends HapticsService {
    var effects as Array<String>;

    function initialize(trace as Array<String>) {
        HapticsService.initialize();
        effects = trace;
    }

    function intervalCue() as Void {
        effects.add("interval");
    }

    function completionCue() as Void {
        effects.add("completion");
    }
}

(:test)
class TestTimerDelegate extends ToothbrushTimerDelegate {
    var starts as Number = 0;
    var stops as Number = 0;
    var redraws as Number = 0;
    var updating as Boolean = false;
    var backlightAvailable as Boolean = true;
    var failBacklight as Boolean = false;
    var backlightChecks as Number = 0;
    var backlightRequests as Number = 0;
    var effects as Array<String>;

    function initialize(timer as BrushingTimer, view as ToothbrushTimerView,
            haptics as HapticsService, trace as Array<String>) {
        ToothbrushTimerDelegate.initialize(timer, view, haptics);
        effects = trace;
    }

    protected function startUpdates() as Void {
        Test.assert(!updating);
        updating = true;
        starts += 1;
    }

    protected function stopUpdates() as Void {
        if (updating) {
            stops += 1;
            updating = false;
            effects.add("stop");
        }
    }

    protected function requestRedraw() as Void {
        redraws += 1;
    }

    protected function canRequestBacklight() as Boolean {
        backlightChecks += 1;
        return backlightAvailable;
    }

    protected function requestBacklight() as Void {
        backlightRequests += 1;
        if (failBacklight) {
            throw new Lang.OperationNotAllowedException("Test backlight refusal");
        }
    }

    protected function exitApplication() as Void {
        effects.add("exit");
    }
}

(:test)
class DelegateFixture {
    var clock as FakeClock;
    var timer as BrushingTimer;
    var view as DelegateTestView;
    var effects as Array<String> = [];
    var delegate as TestTimerDelegate;

    function initialize() {
        var config = TimerConfig.createDefault();
        clock = new FakeClock(0);
        timer = new BrushingTimer(config, clock);
        view = new DelegateTestView(timer, config);
        delegate = new TestTimerDelegate(timer, view, new DelegateTestHaptics(effects), effects);
    }

    function tap(bounds as ControlBounds) as Boolean {
        return delegate.handleTap(bounds.x + bounds.width / 2, bounds.y + bounds.height / 2);
    }
}

(:test)
function delegateTouchControls(logger as Test.Logger) as Boolean {
    var f = new DelegateFixture();
    Test.assert(!f.delegate.onSelect());
    Test.assert(!f.delegate.handleTap(0, 0));
    // The hidden Stop center overlaps READY's wider Start region. Use its far
    // edge, outside the visible Start, to check that hidden controls are inert.
    var stop = f.view.layout.stop;
    Test.assert(!f.delegate.handleTap(stop.x + stop.width - 1, stop.y));
    Test.assert(!f.delegate.handleKey(WatchUi.KEY_DOWN));
    Test.assertEqual(f.delegate.redraws, 0);
    Test.assert(f.tap(f.view.layout.start));
    Test.assertEqual(f.timer.getState(), BrushingTimer.RUNNING);
    Test.assertEqual(f.delegate.starts, 1);
    f.clock.advance(12345);
    Test.assert(f.tap(f.view.layout.primary));
    Test.assertEqual(f.timer.getState(), BrushingTimer.PAUSED);
    Test.assertEqual(f.timer.getElapsedMs(), 12345);
    Test.assert(!f.delegate.updating);
    f.clock.advance(100000);
    f.delegate.onTimer();
    Test.assertEqual(f.timer.getElapsedMs(), 12345);
    Test.assertEqual(f.delegate.redraws, 2);
    Test.assert(f.tap(f.view.layout.primary));
    Test.assertEqual(f.timer.getState(), BrushingTimer.RUNNING);
    f.clock.advance(1000);
    f.delegate.onTimer();
    Test.assertEqual(f.timer.getElapsedMs(), 13345);
    Test.assert(f.tap(f.view.layout.stop));
    Test.assertEqual(f.timer.getState(), BrushingTimer.READY);
    Test.assertEqual(f.timer.getElapsedMs(), 0);
    Test.assertEqual(f.delegate.starts, 2);
    Test.assertEqual(f.delegate.stops, 2);
    return true;
}

(:test)
function delegateTouchEdgesAndOutside(logger as Test.Logger) as Boolean {
    var f = new DelegateFixture();
    var start = f.view.layout.start;
    Test.assert(!f.delegate.handleTap(start.x - 1, start.y));
    Test.assert(!f.delegate.handleTap(start.x + start.width, start.y));
    Test.assert(f.delegate.handleTap(start.x, start.y));
    var primary = f.view.layout.primary;
    Test.assert(!f.delegate.handleTap(primary.x, primary.y - 1));
    Test.assert(!f.delegate.handleTap(primary.x, primary.y + primary.height));
    Test.assertEqual(f.timer.getState(), BrushingTimer.RUNNING);
    Test.assert(f.delegate.handleTap(primary.x + primary.width - 1, primary.y + primary.height - 1));
    Test.assertEqual(f.timer.getState(), BrushingTimer.PAUSED);
    Test.assert(!f.delegate.handleTap(0, 0));
    var stop = f.view.layout.stop;
    Test.assert(f.delegate.handleTap(stop.x + stop.width - 1, stop.y + stop.height - 1));
    Test.assertEqual(f.timer.getState(), BrushingTimer.READY);
    f.delegate.cleanup();
    Test.assert(!f.tap(start));
    return true;
}

(:test)
function delegateEnterAndBoundaryPause(logger as Test.Logger) as Boolean {
    var f = new DelegateFixture();
    Test.assert(f.delegate.handleKey(WatchUi.KEY_ENTER));
    f.clock.advance(30000);
    Test.assert(!f.delegate.onSelect());
    Test.assert(f.delegate.handleKey(WatchUi.KEY_ENTER));
    Test.assertEqual(f.timer.getState(), BrushingTimer.PAUSED);
    Test.assertEqual(f.effects[0], "interval");
    Test.assertEqual(f.effects[1], "stop");
    f.delegate.onTimer();
    f.delegate.handleKey(WatchUi.KEY_ENTER);
    f.delegate.onTimer();
    Test.assertEqual(f.effects.size(), 2);
    Test.assertEqual(f.timer.getElapsedMs(), 30000);
    f.delegate.cleanup();
    return true;
}

(:test)
function delegateDelayedCallbacksAndCompletion(logger as Test.Logger) as Boolean {
    var f = new DelegateFixture();
    f.delegate.onTimer();
    Test.assertEqual(f.delegate.redraws, 0);
    f.delegate.handleKey(WatchUi.KEY_ENTER);
    f.clock.advance(60200);
    f.delegate.onTimer();
    Test.assertEqual(f.effects.size(), 1);
    Test.assertEqual(f.effects[0], "interval");
    f.delegate.onTimer();
    Test.assertEqual(f.effects.size(), 1);
    f.clock.advance(60000);
    f.delegate.onTimer();
    Test.assertEqual(f.timer.getState(), BrushingTimer.COMPLETED);
    Test.assertEqual(f.effects.size(), 4);
    Test.assertEqual(f.effects[1], "stop");
    Test.assertEqual(f.effects[2], "completion");
    Test.assertEqual(f.effects[3], "exit");
    var redraws = f.delegate.redraws;
    f.delegate.onTimer();
    f.delegate.handleKey(WatchUi.KEY_ENTER);
    f.delegate.onBack();
    f.delegate.cleanup();
    Test.assert(!f.tap(f.view.layout.stop));
    Test.assertEqual(f.effects.size(), 4);
    Test.assertEqual(f.delegate.redraws, redraws);
    Test.assertEqual(f.delegate.stops, 1);
    return true;
}

(:test)
function delegateCompletionWinsAllInput(logger as Test.Logger) as Boolean {
    for (var action = 0; action < 4; action += 1) {
        var f = new DelegateFixture();
        f.delegate.handleKey(WatchUi.KEY_ENTER);
        f.clock.advance(120000);
        if (action == 0) {
            f.tap(f.view.layout.primary);
        } else if (action == 1) {
            f.tap(f.view.layout.stop);
        } else if (action == 2) {
            f.delegate.handleKey(WatchUi.KEY_ENTER);
        } else {
            f.delegate.onBack();
        }
        Test.assertEqual(f.timer.getState(), BrushingTimer.COMPLETED);
        Test.assertEqual(f.effects.size(), 3);
        Test.assertEqual(f.effects[0], "stop");
        Test.assertEqual(f.effects[1], "completion");
        Test.assertEqual(f.effects[2], "exit");
        Test.assertEqual(f.delegate.redraws, 1);
    }
    return true;
}

(:test)
function delegateStopPausedAndRestart(logger as Test.Logger) as Boolean {
    var f = new DelegateFixture();
    f.tap(f.view.layout.start);
    f.clock.advance(30000);
    f.delegate.onTimer();
    f.tap(f.view.layout.primary);
    f.tap(f.view.layout.stop);
    Test.assertEqual(f.timer.getState(), BrushingTimer.READY);
    Test.assertEqual(f.timer.getRemainingMs(), 120000);
    Test.assertEqual(f.timer.getStage(), 1);
    Test.assertEqual(f.timer.getProgress(), 0.0);
    var redraws = f.delegate.redraws;
    f.delegate.onTimer();
    Test.assertEqual(f.delegate.redraws, redraws);
    f.tap(f.view.layout.start);
    f.clock.advance(30000);
    f.delegate.onTimer();
    Test.assertEqual(f.effects.size(), 3);
    Test.assertEqual(f.effects[2], "interval");
    f.delegate.cleanup();
    return true;
}

(:test)
function delegateBackAndCleanup(logger as Test.Logger) as Boolean {
    for (var state = 0; state < 3; state += 1) {
        var f = new DelegateFixture();
        if (state > 0) {
            f.delegate.handleKey(WatchUi.KEY_ENTER);
            f.clock.advance(1000);
        }
        if (state == 2) {
            f.delegate.handleKey(WatchUi.KEY_ENTER);
        }
        f.delegate.onBack();
        var count = f.effects.size();
        Test.assertEqual(f.effects[count - 1], "exit");
        Test.assert(!f.delegate.updating);
        f.delegate.onBack();
        f.delegate.cleanup();
        f.clock.advance(150000);
        f.delegate.onTimer();
        f.delegate.handleKey(WatchUi.KEY_ENTER);
        Test.assertEqual(f.effects.size(), count);
    }
    return true;
}

(:test)
function delegateExternalCleanupIgnoresOverdueCues(logger as Test.Logger) as Boolean {
    var f = new DelegateFixture();
    f.delegate.handleKey(WatchUi.KEY_ENTER);
    f.clock.advance(150000);
    f.delegate.cleanup();
    f.delegate.cleanup();
    f.delegate.onTimer();
    f.delegate.handleKey(WatchUi.KEY_ENTER);
    Test.assertEqual(f.effects.size(), 1);
    Test.assertEqual(f.effects[0], "stop");
    Test.assertEqual(f.delegate.stops, 1);
    Test.assertEqual(f.delegate.redraws, 1);
    return true;
}

(:test)
function delegateHapticsFailureStillCompletes(logger as Test.Logger) as Boolean {
    var config = TimerConfig.createDefault();
    var clock = new FakeClock(0);
    var timer = new BrushingTimer(config, clock);
    var haptics = new TestHapticsService();
    var effects = [] as Array<String>;
    var delegate = new TestTimerDelegate(timer, new ToothbrushTimerView(timer, config), haptics, effects);
    haptics.failVibration = true;
    delegate.handleKey(WatchUi.KEY_ENTER);
    clock.advance(30000);
    delegate.onTimer();
    Test.assertEqual(timer.getState(), BrushingTimer.RUNNING);
    clock.advance(90000);
    delegate.onTimer();
    delegate.onTimer();
    Test.assertEqual(haptics.requests, 2);
    Test.assertEqual(timer.getState(), BrushingTimer.COMPLETED);
    Test.assertEqual(effects.size(), 2);
    Test.assertEqual(effects[0], "stop");
    Test.assertEqual(effects[1], "exit");
    return true;
}

(:test)
function applicationStopAndResumeDiscardSession(logger as Test.Logger) as Boolean {
    var app = getApp();
    // getInitialView always returns this production view/delegate pair.
    var initial = app.getInitialView() as [WatchUi.Views, WatchUi.InputDelegates];
    var view = initial[0] as ToothbrushTimerView;
    var delegate = initial[1] as ToothbrushTimerDelegate;
    delegate.handleKey(WatchUi.KEY_ENTER);
    Test.assertEqual(view.getPrimaryLabel(), "Pause");
    app.onStop(null);
    app.onStop(null);
    delegate.onTimer();
    delegate.handleKey(WatchUi.KEY_ENTER);
    Test.assertEqual(view.getPrimaryLabel(), "Pause");
    app.onStart({:resume => true});
    var fresh = app.getInitialView();
    var freshView = fresh[0] as ToothbrushTimerView;
    Test.assertEqual(freshView.getPrimaryLabel(), "Start");
    Test.assertEqual(freshView.getStageLabel(), "Stage 1/4");
    app.onStop(null);
    return true;
}

(:test)
function delegateBacklightTransitionPolicy(logger as Test.Logger) as Boolean {
    var f = new DelegateFixture();
    f.delegate.onTimer();
    Test.assertEqual(f.delegate.backlightChecks, 0);
    f.tap(f.view.layout.start);
    Test.assertEqual(f.delegate.backlightRequests, 1);
    // Even delayed updates must not renew the request.
    f.clock.advance(60200);
    f.delegate.onTimer();
    f.delegate.onTimer();
    Test.assertEqual(f.delegate.backlightChecks, 1);
    f.tap(f.view.layout.primary);
    f.clock.advance(100000);
    f.delegate.onTimer();
    Test.assertEqual(f.delegate.backlightChecks, 1);
    Test.assertEqual(f.timer.getElapsedMs(), 60200);
    f.tap(f.view.layout.primary);
    Test.assertEqual(f.delegate.backlightRequests, 2);
    f.tap(f.view.layout.stop);
    f.delegate.onTimer();
    Test.assertEqual(f.delegate.backlightChecks, 2);
    Test.assertEqual(f.timer.getState(), BrushingTimer.READY);
    f.tap(f.view.layout.start);
    Test.assertEqual(f.delegate.backlightRequests, 3);
    f.tap(f.view.layout.primary);
    f.tap(f.view.layout.stop);
    f.delegate.onBack();
    f.delegate.cleanup();
    f.delegate.onTimer();
    f.delegate.handleKey(WatchUi.KEY_ENTER);
    Test.assertEqual(f.delegate.backlightChecks, 3);
    return true;
}

(:test)
function delegateBacklightUnavailableAndRefused(logger as Test.Logger) as Boolean {
    for (var failure = 0; failure < 2; failure += 1) {
        var f = new DelegateFixture();
        f.delegate.backlightAvailable = failure != 0;
        f.delegate.failBacklight = failure == 1;
        f.tap(f.view.layout.start);
        Test.assertEqual(f.delegate.backlightChecks, 1);
        Test.assertEqual(f.delegate.backlightRequests, failure);
        Test.assert(f.delegate.updating);
        f.clock.advance(12345);
        f.delegate.onTimer();
        f.tap(f.view.layout.primary);
        Test.assertEqual(f.timer.getState(), BrushingTimer.PAUSED);
        Test.assertEqual(f.timer.getElapsedMs(), 12345);
        f.clock.advance(100000);
        f.delegate.onTimer();
        Test.assertEqual(f.delegate.backlightChecks, 1);
        // A new running period can make a fresh request after platform recovery.
        f.delegate.backlightAvailable = true;
        f.delegate.failBacklight = false;
        f.tap(f.view.layout.primary);
        Test.assertEqual(f.delegate.backlightRequests, failure + 1);
        Test.assertEqual(f.timer.getElapsedMs(), 12345);
        f.clock.advance(107655);
        f.delegate.onTimer();
        Test.assertEqual(f.timer.getState(), BrushingTimer.COMPLETED);
        Test.assertEqual(f.effects[f.effects.size() - 1], "exit");
        f.delegate.onTimer();
        f.delegate.cleanup();
        Test.assertEqual(f.delegate.backlightChecks, 2);
    }
    return true;
}

(:test)
function delegateBacklightFailureThroughExit(logger as Test.Logger) as Boolean {
    for (var action = 0; action < 4; action += 1) {
        var f = new DelegateFixture();
        f.delegate.failBacklight = true;
        f.tap(f.view.layout.start);
        f.clock.advance(120000);
        if (action == 0) {
            f.tap(f.view.layout.primary);
        } else if (action == 1) {
            f.tap(f.view.layout.stop);
        } else if (action == 2) {
            f.delegate.onBack();
        } else {
            f.delegate.cleanup();
        }
        f.delegate.onTimer();
        f.delegate.cleanup();
        Test.assertEqual(f.delegate.backlightChecks, 1);
        Test.assertEqual(f.delegate.backlightRequests, 1);
        Test.assert(!f.delegate.updating);
        if (action < 3) {
            Test.assertEqual(f.timer.getState(), BrushingTimer.COMPLETED);
            Test.assertEqual(f.effects.size(), 3);
            Test.assertEqual(f.effects[1], "completion");
            Test.assertEqual(f.effects[2], "exit");
        } else {
            // External cleanup discards rather than synchronizes the session.
            Test.assertEqual(f.effects.size(), 1);
        }
    }
    return true;
}

// Exercise real SDK timer ownership while muting redraw and backlight effects.
(:test)
class OwnershipTestDelegate extends ToothbrushTimerDelegate {
    function initialize(timer as BrushingTimer, view as ToothbrushTimerView) {
        ToothbrushTimerDelegate.initialize(timer, view, new HapticsService());
    }

    protected function requestBacklight() as Void {
    }

    protected function requestRedraw() as Void {
    }

    static function exerciseOwnership() as Array<WeakReference> {
        var config = TimerConfig.createDefault();
        var timer = new BrushingTimer(config, new FakeClock(0));
        var view = new DelegateTestView(timer, config);
        var delegate = new OwnershipTestDelegate(timer, view);
        for (var session = 0; session < 40; session += 1) {
            delegate.handleKey(WatchUi.KEY_ENTER);
            delegate.handleKey(WatchUi.KEY_ENTER);
            delegate.handleKey(WatchUi.KEY_ENTER);
            delegate.handleTap(view.layout.stop.x, view.layout.stop.y);
            Test.assertEqual(timer.getState(), BrushingTimer.READY);
        }
        // Also release a running timer from cleanup, including a repeated cleanup.
        delegate.handleKey(WatchUi.KEY_ENTER);
        delegate.cleanup();
        delegate.cleanup();
        return [delegate.weak(), view.weak(), timer.weak()];
    }
}

(:test)
function delegateTimerOwnershipReleased(logger as Test.Logger) as Boolean {
    var references = OwnershipTestDelegate.exerciseOwnership();
    // The helper's locals have gone out of scope. A retained timer callback
    // cycle would keep the delegate and everything it owns alive here.
    for (var index = 0; index < references.size(); index += 1) {
        Test.assert(!references[index].stillAlive());
    }
    return true;
}
