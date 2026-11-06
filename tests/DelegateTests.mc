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
    var effects as Array<String>;
    var exitSchedules as Number = 0;
    var scheduledDurationMs as Number = 0;
    private var _clock as FakeClock;
    private var _scheduledAtMs as Number = 0;
    private var _callback as (Method() as Void)?;

    function initialize(timer as BrushingTimer, view as ToothbrushTimerView,
            haptics as HapticsService, trace as Array<String>, config as TimerConfig, clock as FakeClock) {
        ToothbrushTimerDelegate.initialize(timer, view, haptics, config);
        _clock = clock;
        effects = trace;
    }

    protected function startTimer(callback as Method() as Void, durationMs as Number, repeat as Boolean) as Void {
        Test.assert(_callback == null);
        _callback = callback;
        _scheduledAtMs = _clock.nowMs();
        scheduledDurationMs = durationMs;
        updating = repeat;
        if (repeat) {
            starts += 1;
        } else {
            exitSchedules += 1;
            effects.add("schedule");
        }
    }

    protected function stopTimer() as Void {
        if (_callback != null) {
            stops += 1;
            updating = false;
            _callback = null;
            effects.add("stop");
        }
    }

    // Only the SDK boundary is replaced; deliver the actual captured callback.
    function deliverDueExit() as Void {
        var callback = _callback;
        if (callback != null && !updating &&
                _clock.nowMs() - _scheduledAtMs >= scheduledDurationMs) {
            _callback = null;
            callback.invoke();
        }
    }

    function getScheduledCallback() as (Method() as Void)? {
        return _callback;
    }

    protected function requestRedraw() as Void {
        redraws += 1;
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
        delegate = new TestTimerDelegate(timer, view, new DelegateTestHaptics(effects), effects, config, clock);
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
    Test.assert(!f.delegate.handleTap(start.x, start.y));
    Test.assert(f.delegate.handleTap(start.x, start.y + start.height / 2));
    var primary = f.view.layout.primary;
    Test.assert(!f.delegate.handleTap(primary.x, primary.y - 1));
    Test.assert(!f.delegate.handleTap(primary.x, primary.y + primary.height));
    Test.assertEqual(f.timer.getState(), BrushingTimer.RUNNING);
    Test.assert(!f.delegate.handleTap(primary.x + primary.width - 1, primary.y + primary.height - 1));
    Test.assert(f.delegate.handleTap(primary.x + primary.width - 1, primary.y + primary.height / 2));
    Test.assertEqual(f.timer.getState(), BrushingTimer.PAUSED);
    Test.assert(!f.delegate.handleTap(0, 0));
    var stop = f.view.layout.stop;
    Test.assert(!f.delegate.handleTap(stop.x + stop.width - 1, stop.y + stop.height - 1));
    Test.assert(f.delegate.handleTap(stop.x + stop.width / 2, stop.y + stop.height - 1));
    Test.assertEqual(f.timer.getState(), BrushingTimer.READY);
    f.delegate.cleanup();
    Test.assert(!f.tap(start));
    return true;
}

(:test)
function delegateCompletedControlsAreInert(logger as Test.Logger) as Boolean {
    var f = new DelegateFixture();
    // An authoritative COMPLETED state alone does not own a pending exit callback.
    f.timer.handleAction(BrushingTimer.START);
    f.clock.advance(120000);
    f.timer.synchronize();
    Test.assertEqual(f.timer.getState(), BrushingTimer.COMPLETED);
    Test.assert(!f.tap(f.view.layout.start));
    Test.assert(!f.tap(f.view.layout.primary));
    Test.assert(!f.tap(f.view.layout.stop));
    Test.assert(!f.delegate.onSelect());
    Test.assert(f.delegate.handleKey(WatchUi.KEY_ENTER));
    f.delegate.onTimer();
    f.delegate.onCompletionExit();
    Test.assertEqual(f.timer.getState(), BrushingTimer.COMPLETED);
    Test.assertEqual(f.timer.getElapsedMs(), 120000);
    Test.assertEqual(f.delegate.starts, 0);
    Test.assertEqual(f.delegate.redraws, 0);
    Test.assertEqual(f.effects.size(), 0);
    f.delegate.cleanup();
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
    Test.assertEqual(f.effects[3], "schedule");
    var redraws = f.delegate.redraws;
    f.delegate.onTimer();
    f.delegate.handleKey(WatchUi.KEY_ENTER);
    f.clock.advance(3000);
    f.delegate.deliverDueExit();
    f.delegate.onCompletionExit();
    f.delegate.onBack();
    f.delegate.cleanup();
    Test.assert(!f.tap(f.view.layout.stop));
    Test.assertEqual(f.effects.size(), 5);
    Test.assertEqual(f.effects[4], "exit");
    Test.assertEqual(f.delegate.redraws, redraws);
    Test.assertEqual(f.delegate.stops, 1);
    return true;
}

(:test)
function delegateCompletionWinsPauseAndStop(logger as Test.Logger) as Boolean {
    for (var action = 0; action < 3; action += 1) {
        var f = new DelegateFixture();
        f.delegate.handleKey(WatchUi.KEY_ENTER);
        f.clock.advance(120000);
        if (action == 0) {
            f.tap(f.view.layout.primary);
        } else if (action == 1) {
            f.tap(f.view.layout.stop);
        } else {
            f.delegate.handleKey(WatchUi.KEY_ENTER);
        }
        Test.assertEqual(f.timer.getState(), BrushingTimer.COMPLETED);
        Test.assertEqual(f.effects.size(), 3);
        Test.assertEqual(f.effects[0], "stop");
        Test.assertEqual(f.effects[1], "completion");
        Test.assertEqual(f.effects[2], "schedule");
        Test.assertEqual(f.delegate.redraws, 2);
        f.delegate.cleanup();
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
function delegateBackBypassesOverdueCues(logger as Test.Logger) as Boolean {
    var exitTimes = [29999, 30000, 60200, 119999, 120000, 150000];
    for (var index = 0; index < exitTimes.size(); index += 1) {
        var f = new DelegateFixture();
        f.delegate.handleKey(WatchUi.KEY_ENTER);
        f.clock.advance(exitTimes[index]);
        var samples = f.clock.getSampleCount();
        Test.assert(f.delegate.onBack());
        Test.assertEqual(f.clock.getSampleCount(), samples);
        // A discarded model need not transition: exit must not synchronize it.
        Test.assertEqual(f.timer.getState(), BrushingTimer.RUNNING);
        Test.assertEqual(f.timer.getElapsedMs(), 0);
        Test.assertEqual(f.effects.size(), 2);
        Test.assertEqual(f.effects[0], "stop");
        Test.assertEqual(f.effects[1], "exit");
        Test.assert(!f.delegate.updating);
        f.delegate.cleanup();
        f.delegate.cleanup();
        f.delegate.onBack();
        f.delegate.onTimer();
        f.delegate.handleKey(WatchUi.KEY_ENTER);
        Test.assert(!f.tap(f.view.layout.stop));
        Test.assertEqual(f.effects.size(), 2);
        Test.assertEqual(f.delegate.stops, 1);
        Test.assertEqual(f.delegate.redraws, 1);
        Test.assertEqual(f.clock.getSampleCount(), samples);
    }
    return true;
}

(:test)
function delegateExternalCleanupIgnoresOverdueCues(logger as Test.Logger) as Boolean {
    var exitTimes = [29999, 30000, 60200, 119999, 120000, 150000];
    for (var index = 0; index < exitTimes.size(); index += 1) {
        var f = new DelegateFixture();
        f.delegate.handleKey(WatchUi.KEY_ENTER);
        f.clock.advance(exitTimes[index]);
        var samples = f.clock.getSampleCount();
        f.delegate.cleanup();
        f.delegate.cleanup();
        f.delegate.onTimer();
        f.delegate.onBack();
        f.delegate.handleKey(WatchUi.KEY_ENTER);
        Test.assertEqual(f.effects.size(), 1);
        Test.assertEqual(f.effects[0], "stop");
        Test.assertEqual(f.delegate.stops, 1);
        Test.assertEqual(f.delegate.redraws, 1);
        Test.assertEqual(f.clock.getSampleCount(), samples);
        Test.assertEqual(f.timer.getState(), BrushingTimer.RUNNING);
        Test.assertEqual(f.timer.getElapsedMs(), 0);
    }
    return true;
}

(:test)
function delegateHapticsFailureStillCompletes(logger as Test.Logger) as Boolean {
    var config = TimerConfig.createDefault();
    var clock = new FakeClock(0);
    var timer = new BrushingTimer(config, clock);
    var haptics = new TestHapticsService();
    var effects = [] as Array<String>;
    var delegate = new TestTimerDelegate(timer, new ToothbrushTimerView(timer, config), haptics, effects, config, clock);
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
    Test.assertEqual(effects[1], "schedule");
    Test.assertEqual(delegate.redraws, 3);
    clock.advance(3000);
    delegate.deliverDueExit();
    Test.assertEqual(effects.size(), 3);
    Test.assertEqual(effects[2], "exit");
    return true;
}

(:test)
function delegateCompletionDelayTiming(logger as Test.Logger) as Boolean {
    // Include delayed detection, an alternate delay, and signed clock rollover.
    for (var scenario = 0; scenario < 3; scenario += 1) {
        var delayMs = scenario == 1 ? 4500 : 3000;
        var config = new TimerConfig(120000, 30000, delayMs);
        var clock = new FakeClock(scenario == 2 ? 2147362000 : 1000);
        var timer = new BrushingTimer(config, clock);
        var view = new DelegateTestView(timer, config);
        var effects = [] as Array<String>;
        var delegate = new TestTimerDelegate(timer, view,
            new DelegateTestHaptics(effects), effects, config, clock);
        // An unsolicited callback in READY or RUNNING cannot exit.
        delegate.onCompletionExit();
        delegate.handleKey(WatchUi.KEY_ENTER);
        delegate.onCompletionExit();
        clock.advance(119999);
        delegate.onTimer();
        Test.assertEqual(timer.getState(), BrushingTimer.RUNNING);
        Test.assertEqual(delegate.exitSchedules, 0);
        clock.advance(scenario == 1 ? 30001 : 1);
        delegate.onTimer();
        Test.assertEqual(timer.getState(), BrushingTimer.COMPLETED);
        Test.assertEqual(effects[effects.size() - 1], "schedule");
        Test.assertEqual(delegate.exitSchedules, 1);
        Test.assertEqual(delegate.scheduledDurationMs, delayMs);
        var count = effects.size();
        var redraws = delegate.redraws;
        clock.advance(delayMs - 1);
        delegate.deliverDueExit();
        delegate.onTimer();
        delegate.handleKey(WatchUi.KEY_ENTER);
        Test.assert(!delegate.handleTap(view.layout.primary.x, view.layout.primary.y));
        Test.assert(!delegate.handleTap(view.layout.stop.x, view.layout.stop.y));
        // Repeated redraws have no orchestration side effects.
        Test.assertEqual(view.getSessionState(), BrushingTimer.COMPLETED);
        Test.assertEqual(timer.getRemainingMs(), 0);
        Test.assertEqual(timer.getProgress(), 1.0);
        Test.assertEqual(timer.getElapsedMs(), 120000);
        Test.assertEqual(effects.size(), count);
        Test.assertEqual(delegate.redraws, redraws);
        Test.assertEqual(delegate.exitSchedules, 1);
        clock.advance(1);
        delegate.deliverDueExit();
        delegate.onCompletionExit();
        delegate.deliverDueExit();
        delegate.onBack();
        Test.assertEqual(effects.size(), count + 1);
        Test.assertEqual(effects[count], "exit");
    }
    return true;
}

(:test)
function delegateCompletionCancellationAndStaleCallbacks(logger as Test.Logger) as Boolean {
    for (var action = 0; action < 2; action += 1) {
        var f = new DelegateFixture();
        f.delegate.handleKey(WatchUi.KEY_ENTER);
        f.clock.advance(120000);
        f.delegate.onTimer();
        var staleCallback = f.delegate.getScheduledCallback();
        Test.assert(staleCallback != null);
        f.clock.advance(1000);
        var samples = f.clock.getSampleCount();
        if (action == 0) {
            f.delegate.onBack();
        } else {
            f.delegate.cleanup();
        }
        Test.assertEqual(f.clock.getSampleCount(), samples);
        Test.assert(f.delegate.getScheduledCallback() == null);
        Test.assertEqual(f.effects.size(), action == 0 ? 5 : 4);
        Test.assertEqual(f.effects[3], "stop");
        if (action == 0) {
            Test.assertEqual(f.effects[4], "exit");
        }
        var fresh = new DelegateFixture();
        var count = f.effects.size();
        for (var state = 0; state < 2; state += 1) {
            if (state == 1) {
                fresh.tap(fresh.view.layout.start);
            }
            f.clock.advance(3000);
            if (staleCallback != null) {
                staleCallback.invoke();
            }
            f.delegate.onTimer();
            f.delegate.onCompletionExit();
            f.delegate.cleanup();
            f.delegate.onBack();
            Test.assertEqual(f.effects.size(), count);
            Test.assertEqual(f.delegate.exitSchedules, 1);
            Test.assertEqual(fresh.effects.size(), 0);
            Test.assertEqual(fresh.timer.getState(), state == 0 ? BrushingTimer.READY : BrushingTimer.RUNNING);
        }
        fresh.delegate.cleanup();
    }
    return true;
}

(:test)
function delegateSuppressedHapticsStillExits(logger as Test.Logger) as Boolean {
    for (var restriction = 0; restriction < 3; restriction += 1) {
        var config = TimerConfig.createDefault();
        var clock = new FakeClock(0);
        var timer = new BrushingTimer(config, clock);
        var haptics = new TestHapticsService();
        var settings = new TestDndSettings();
        settings.vibrateOn = restriction != 0;
        settings.doNotDisturb = restriction == 1;
        haptics.settings = settings;
        haptics.failAvailability = restriction == 2;
        var effects = [] as Array<String>;
        var delegate = new TestTimerDelegate(timer, new DelegateTestView(timer, config),
            haptics, effects, config, clock);
        delegate.handleKey(WatchUi.KEY_ENTER);
        clock.advance(150000);
        delegate.onTimer();
        Test.assertEqual(haptics.requests, 0);
        Test.assertEqual(haptics.checks, 1);
        Test.assertEqual(delegate.redraws, 2);
        Test.assertEqual(delegate.exitSchedules, 1);
        Test.assertEqual(effects[1], "schedule");
        clock.advance(3000);
        delegate.deliverDueExit();
        delegate.onCompletionExit();
        Test.assertEqual(effects.size(), 3);
        Test.assertEqual(effects[2], "exit");
        Test.assertEqual(timer.getState(), BrushingTimer.COMPLETED);
    }
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
    Test.assertEqual(view.getSessionState(), BrushingTimer.RUNNING);
    app.onStop(null);
    app.onStop(null);
    delegate.onTimer();
    delegate.handleKey(WatchUi.KEY_ENTER);
    Test.assertEqual(view.getSessionState(), BrushingTimer.RUNNING);
    app.onStart({:resume => true});
    var fresh = app.getInitialView() as [WatchUi.Views, WatchUi.InputDelegates];
    var freshView = fresh[0] as ToothbrushTimerView;
    var freshDelegate = fresh[1] as ToothbrushTimerDelegate;
    delegate.onTimer();
    delegate.onBack();
    delegate.cleanup();
    Test.assertEqual(freshView.getSessionState(), BrushingTimer.READY);
    Test.assertEqual(freshView.getStageLabel(), "Stage 1/4");
    freshDelegate.handleKey(WatchUi.KEY_ENTER);
    delegate.onTimer();
    delegate.onBack();
    Test.assertEqual(freshView.getSessionState(), BrushingTimer.RUNNING);
    // A reported resume also discards a controller before onStop is delivered.
    app.onStart({:resume => true});
    freshDelegate.onTimer();
    freshDelegate.handleKey(WatchUi.KEY_ENTER);
    Test.assertEqual(freshView.getSessionState(), BrushingTimer.RUNNING);
    var resumed = app.getInitialView();
    Test.assertEqual((resumed[0] as ToothbrushTimerView).getSessionState(), BrushingTimer.READY);
    app.onStop(null);
    return true;
}

// Exercise real SDK timer ownership while muting redraws.
(:test)
class OwnershipTestDelegate extends ToothbrushTimerDelegate {
    function initialize(timer as BrushingTimer, view as ToothbrushTimerView, config as TimerConfig) {
        ToothbrushTimerDelegate.initialize(timer, view, new HapticsService(), config);
    }

    protected function requestRedraw() as Void {
    }

    protected function exitApplication() as Void {
    }

    static function exerciseOwnership(completionMode as Number) as Array<WeakReference> {
        var config = TimerConfig.createDefault();
        var clock = new FakeClock(0);
        var timer = new BrushingTimer(config, clock);
        var view = new DelegateTestView(timer, config);
        var delegate = new OwnershipTestDelegate(timer, view, config);
        for (var session = 0; session < 40; session += 1) {
            delegate.handleKey(WatchUi.KEY_ENTER);
            delegate.handleKey(WatchUi.KEY_ENTER);
            delegate.handleKey(WatchUi.KEY_ENTER);
            delegate.handleTap(view.layout.stop.x, view.layout.stop.y + view.layout.stop.height / 2);
            Test.assertEqual(timer.getState(), BrushingTimer.READY);
        }
        // Also release a running timer from cleanup, including a repeated cleanup.
        delegate.handleKey(WatchUi.KEY_ENTER);
        if (completionMode > 0) {
            clock.advance(120000);
            delegate.onTimer();
            Test.assertEqual(timer.getState(), BrushingTimer.COMPLETED);
            if (completionMode == 2) {
                delegate.onCompletionExit();
            }
        }
        delegate.cleanup();
        delegate.cleanup();
        return [delegate.weak(), view.weak(), timer.weak()];
    }
}

(:test)
function delegateTimerOwnershipReleased(logger as Test.Logger) as Boolean {
    for (var mode = 0; mode < 3; mode += 1) {
        var references = OwnershipTestDelegate.exerciseOwnership(mode);
        // A retained repeating or one-shot callback cycle keeps these alive.
        for (var index = 0; index < references.size(); index += 1) {
            Test.assert(!references[index].stillAlive());
        }
    }
    return true;
}
