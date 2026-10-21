import Toybox.Lang;
import Toybox.Test;

(:test)
class BrushingTimerAssertions {
    static function assertValues(timer as BrushingTimer, state as BrushingTimer.State,
            elapsedMs as Number, remainingMs as Number, progress as Float, stage as Number) as Void {
        Test.assertEqual(timer.getState(), state);
        Test.assertEqual(timer.getElapsedMs(), elapsedMs);
        Test.assertEqual(timer.getRemainingMs(), remainingMs);
        Test.assert((timer.getProgress() - progress).abs() < 0.00001);
        Test.assertEqual(timer.getStage(), stage);
    }
}

(:test)
function timerInitialAndStart(logger as Test.Logger) as Boolean {
    var clock = new FakeClock(876543);
    var timer = new BrushingTimer(TimerConfig.createDefault(), clock);
    BrushingTimerAssertions.assertValues(timer, BrushingTimer.READY, 0, 120000, 0.0, 1);
    clock.advance(9999);
    Test.assertEqual(timer.synchronize(), BrushingTimer.NONE);
    BrushingTimerAssertions.assertValues(timer, BrushingTimer.READY, 0, 120000, 0.0, 1);
    Test.assertEqual(timer.handleAction(BrushingTimer.START), BrushingTimer.NONE);
    BrushingTimerAssertions.assertValues(timer, BrushingTimer.RUNNING, 0, 120000, 0.0, 1);
    clock.advance(1234);
    Test.assertEqual(timer.synchronize(), BrushingTimer.NONE);
    BrushingTimerAssertions.assertValues(timer, BrushingTimer.RUNNING, 1234, 118766, 1234.0 / 120000, 1);
    return true;
}

(:test)
function timerIntervalBoundaries(logger as Test.Logger) as Boolean {
    for (var boundary = 30000; boundary <= 90000; boundary += 30000) {
        var clock = new FakeClock(531);
        var timer = new BrushingTimer(TimerConfig.createDefault(), clock);
        Test.assertEqual(timer.handleAction(BrushingTimer.START), BrushingTimer.NONE);
        // Process earlier boundaries first so boundary-1 has no overdue event.
        for (var earlier = 30000; earlier < boundary; earlier += 30000) {
            clock.advance(30000);
            Test.assertEqual(timer.synchronize(), BrushingTimer.INTERVAL);
        }
        clock.advance(29999);
        Test.assertEqual(timer.synchronize(), BrushingTimer.NONE);
        BrushingTimerAssertions.assertValues(timer, BrushingTimer.RUNNING, boundary - 1, 120001 - boundary,
            (boundary - 1).toFloat() / 120000, boundary / 30000);
        clock.advance(1);
        Test.assertEqual(timer.synchronize(), BrushingTimer.INTERVAL);
        BrushingTimerAssertions.assertValues(timer, BrushingTimer.RUNNING, boundary, 120000 - boundary,
            boundary.toFloat() / 120000, boundary / 30000 + 1);
        Test.assertEqual(timer.synchronize(), BrushingTimer.NONE);
        clock.advance(1);
        Test.assertEqual(timer.synchronize(), BrushingTimer.NONE);
        BrushingTimerAssertions.assertValues(timer, BrushingTimer.RUNNING, boundary + 1, 119999 - boundary,
            (boundary + 1).toFloat() / 120000, boundary / 30000 + 1);
    }
    return true;
}

(:test)
function timerDelayedCallbacks(logger as Test.Logger) as Boolean {
    var clock = new FakeClock(1000);
    var timer = new BrushingTimer(TimerConfig.createDefault(), clock);
    Test.assertEqual(timer.handleAction(BrushingTimer.START), BrushingTimer.NONE);
    clock.advance(29800);
    Test.assertEqual(timer.synchronize(), BrushingTimer.NONE);
    clock.advance(30400);
    Test.assertEqual(timer.synchronize(), BrushingTimer.INTERVAL);
    BrushingTimerAssertions.assertValues(timer, BrushingTimer.RUNNING, 60200, 59800, 60200.0 / 120000, 3);
    Test.assertEqual(timer.synchronize(), BrushingTimer.NONE);
    clock.advance(7);
    Test.assertEqual(timer.synchronize(), BrushingTimer.NONE);
    clock.advance(29793);
    Test.assertEqual(timer.synchronize(), BrushingTimer.INTERVAL);
    Test.assertEqual(timer.getStage(), 4);
    Test.assertEqual(timer.synchronize(), BrushingTimer.NONE);
    return true;
}

(:test)
function timerSeveralMissedIntervals(logger as Test.Logger) as Boolean {
    var clock = new FakeClock(10);
    var timer = new BrushingTimer(TimerConfig.createDefault(), clock);
    Test.assertEqual(timer.handleAction(BrushingTimer.START), BrushingTimer.NONE);
    clock.advance(95000);
    Test.assertEqual(timer.synchronize(), BrushingTimer.INTERVAL);
    BrushingTimerAssertions.assertValues(timer, BrushingTimer.RUNNING, 95000, 25000, 95000.0 / 120000, 4);
    for (var i = 0; i < 5; i += 1) {
        clock.advance(1);
        Test.assertEqual(timer.synchronize(), BrushingTimer.NONE);
    }
    return true;
}

(:test)
function timerFractionalPause(logger as Test.Logger) as Boolean {
    var clock = new FakeClock(700);
    var timer = new BrushingTimer(TimerConfig.createDefault(), clock);
    Test.assertEqual(timer.handleAction(BrushingTimer.START), BrushingTimer.NONE);
    clock.advance(12345);
    Test.assertEqual(timer.handleAction(BrushingTimer.PAUSE), BrushingTimer.NONE);
    BrushingTimerAssertions.assertValues(timer, BrushingTimer.PAUSED, 12345, 107655, 12345.0 / 120000, 1);
    clock.advance(900001);
    Test.assertEqual(timer.synchronize(), BrushingTimer.NONE);
    BrushingTimerAssertions.assertValues(timer, BrushingTimer.PAUSED, 12345, 107655, 12345.0 / 120000, 1);
    Test.assertEqual(timer.handleAction(BrushingTimer.RESUME), BrushingTimer.NONE);
    BrushingTimerAssertions.assertValues(timer, BrushingTimer.RUNNING, 12345, 107655, 12345.0 / 120000, 1);
    clock.advance(17654);
    Test.assertEqual(timer.synchronize(), BrushingTimer.NONE);
    Test.assertEqual(timer.getElapsedMs(), 29999);
    clock.advance(1);
    Test.assertEqual(timer.synchronize(), BrushingTimer.INTERVAL);
    Test.assertEqual(timer.getElapsedMs(), 30000);
    return true;
}

(:test)
function timerMultiplePauses(logger as Test.Logger) as Boolean {
    var clock = new FakeClock(42);
    var timer = new BrushingTimer(TimerConfig.createDefault(), clock);
    Test.assertEqual(timer.handleAction(BrushingTimer.START), BrushingTimer.NONE);
    var runningDurations = [12345, 6789, 4567];
    var expectedElapsed = 0;
    for (var i = 0; i < runningDurations.size(); i += 1) {
        clock.advance(runningDurations[i]);
        expectedElapsed += runningDurations[i];
        Test.assertEqual(timer.handleAction(BrushingTimer.PAUSE), BrushingTimer.NONE);
        clock.advance(200000 + i);
        Test.assertEqual(timer.synchronize(), BrushingTimer.NONE);
        Test.assertEqual(timer.getElapsedMs(), expectedElapsed);
        Test.assertEqual(timer.handleAction(BrushingTimer.RESUME), BrushingTimer.NONE);
    }
    clock.advance(6299);
    Test.assertEqual(timer.synchronize(), BrushingTimer.INTERVAL);
    BrushingTimerAssertions.assertValues(timer, BrushingTimer.RUNNING, 30000, 90000, 0.25, 2);
    return true;
}

(:test)
function timerPauseAroundInterval(logger as Test.Logger) as Boolean {
    for (var offset = -1; offset <= 1; offset += 1) {
        var clock = new FakeClock(120);
        var timer = new BrushingTimer(TimerConfig.createDefault(), clock);
        Test.assertEqual(timer.handleAction(BrushingTimer.START), BrushingTimer.NONE);
        clock.advance(30000 + offset);
        var expectedCue = offset < 0 ? BrushingTimer.NONE : BrushingTimer.INTERVAL;
        Test.assertEqual(timer.handleAction(BrushingTimer.PAUSE), expectedCue);
        Test.assertEqual(timer.getState(), BrushingTimer.PAUSED);
        Test.assertEqual(timer.getElapsedMs(), 30000 + offset);
        Test.assertEqual(timer.getStage(), offset < 0 ? 1 : 2);
        clock.advance(50000);
        Test.assertEqual(timer.synchronize(), BrushingTimer.NONE);
        Test.assertEqual(timer.handleAction(BrushingTimer.RESUME), BrushingTimer.NONE);
        clock.advance(1);
        Test.assertEqual(timer.synchronize(), offset < 0 ? BrushingTimer.INTERVAL : BrushingTimer.NONE);
        Test.assertEqual(timer.synchronize(), BrushingTimer.NONE);
    }
    return true;
}

(:test)
function timerStopAndRestart(logger as Test.Logger) as Boolean {
    for (var paused = 0; paused <= 1; paused += 1) {
        var clock = new FakeClock(900);
        var timer = new BrushingTimer(TimerConfig.createDefault(), clock);
        Test.assertEqual(timer.handleAction(BrushingTimer.START), BrushingTimer.NONE);
        clock.advance(60001);
        Test.assertEqual(timer.synchronize(), BrushingTimer.INTERVAL);
        if (paused == 1) {
            clock.advance(2345);
            Test.assertEqual(timer.handleAction(BrushingTimer.PAUSE), BrushingTimer.NONE);
            clock.advance(700000);
        }
        Test.assertEqual(timer.handleAction(BrushingTimer.STOP), BrushingTimer.NONE);
        BrushingTimerAssertions.assertValues(timer, BrushingTimer.READY, 0, 120000, 0.0, 1);
        clock.advance(12345);
        Test.assertEqual(timer.synchronize(), BrushingTimer.NONE);
        Test.assertEqual(timer.handleAction(BrushingTimer.START), BrushingTimer.NONE);
        clock.advance(30000);
        Test.assertEqual(timer.synchronize(), BrushingTimer.INTERVAL);
        BrushingTimerAssertions.assertValues(timer, BrushingTimer.RUNNING, 30000, 90000, 0.25, 2);
        Test.assertEqual(timer.synchronize(), BrushingTimer.NONE);
    }
    return true;
}

(:test)
function timerStopReturnsCrossedCue(logger as Test.Logger) as Boolean {
    var clock = new FakeClock(88);
    var timer = new BrushingTimer(TimerConfig.createDefault(), clock);
    Test.assertEqual(timer.handleAction(BrushingTimer.START), BrushingTimer.NONE);
    clock.advance(60010);
    Test.assertEqual(timer.handleAction(BrushingTimer.STOP), BrushingTimer.INTERVAL);
    BrushingTimerAssertions.assertValues(timer, BrushingTimer.READY, 0, 120000, 0.0, 1);
    Test.assertEqual(timer.synchronize(), BrushingTimer.NONE);
    Test.assertEqual(timer.handleAction(BrushingTimer.START), BrushingTimer.NONE);
    clock.advance(30000);
    Test.assertEqual(timer.synchronize(), BrushingTimer.INTERVAL);
    return true;
}

(:test)
function timerCompletionBoundary(logger as Test.Logger) as Boolean {
    var clock = new FakeClock(81);
    var timer = new BrushingTimer(TimerConfig.createDefault(), clock);
    Test.assertEqual(timer.handleAction(BrushingTimer.START), BrushingTimer.NONE);
    clock.advance(90000);
    Test.assertEqual(timer.synchronize(), BrushingTimer.INTERVAL);
    clock.advance(29999);
    Test.assertEqual(timer.synchronize(), BrushingTimer.NONE);
    BrushingTimerAssertions.assertValues(timer, BrushingTimer.RUNNING, 119999, 1, 119999.0 / 120000, 4);
    clock.advance(1);
    Test.assertEqual(timer.synchronize(), BrushingTimer.COMPLETION);
    BrushingTimerAssertions.assertValues(timer, BrushingTimer.COMPLETED, 120000, 0, 1.0, 4);
    clock.advance(999999);
    Test.assertEqual(timer.synchronize(), BrushingTimer.NONE);
    BrushingTimerAssertions.assertValues(timer, BrushingTimer.COMPLETED, 120000, 0, 1.0, 4);
    return true;
}

(:test)
function timerCompletionPriority(logger as Test.Logger) as Boolean {
    var actions = [BrushingTimer.PAUSE, BrushingTimer.STOP, BrushingTimer.START, BrushingTimer.RESUME];
    for (var i = 0; i < actions.size(); i += 1) {
        // Input at the exact deadline and after several missed boundaries.
        for (var overshoot = 0; overshoot <= 12345; overshoot += 12345) {
            var clock = new FakeClock(20);
            var timer = new BrushingTimer(TimerConfig.createDefault(), clock);
            Test.assertEqual(timer.handleAction(BrushingTimer.START), BrushingTimer.NONE);
            clock.advance(29800);
            Test.assertEqual(timer.synchronize(), BrushingTimer.NONE);
            clock.advance(90200 + overshoot);
            Test.assertEqual(timer.handleAction(actions[i]), BrushingTimer.COMPLETION);
            BrushingTimerAssertions.assertValues(timer, BrushingTimer.COMPLETED, 120000, 0, 1.0, 4);
            Test.assertEqual(timer.synchronize(), BrushingTimer.NONE);
            for (var j = 0; j < actions.size(); j += 1) {
                clock.advance(1);
                Test.assertEqual(timer.handleAction(actions[j]), BrushingTimer.NONE);
                BrushingTimerAssertions.assertValues(timer, BrushingTimer.COMPLETED, 120000, 0, 1.0, 4);
            }
        }
    }
    return true;
}

(:test)
function timerDelayedCompletion(logger as Test.Logger) as Boolean {
    var clock = new FakeClock(234);
    var timer = new BrushingTimer(TimerConfig.createDefault(), clock);
    Test.assertEqual(timer.handleAction(BrushingTimer.START), BrushingTimer.NONE);
    clock.advance(170000);
    Test.assertEqual(timer.synchronize(), BrushingTimer.COMPLETION);
    BrushingTimerAssertions.assertValues(timer, BrushingTimer.COMPLETED, 120000, 0, 1.0, 4);
    Test.assertEqual(timer.synchronize(), BrushingTimer.NONE);
    return true;
}

(:test)
function timerSignedRollover(logger as Test.Logger) as Boolean {
    var clock = new FakeClock(2147483600);
    var timer = new BrushingTimer(TimerConfig.createDefault(), clock);
    Test.assertEqual(timer.handleAction(BrushingTimer.START), BrushingTimer.NONE);
    clock.advance(100);
    Test.assertEqual(timer.synchronize(), BrushingTimer.NONE);
    Test.assertEqual(timer.getElapsedMs(), 100);
    clock.advance(29900);
    Test.assertEqual(timer.synchronize(), BrushingTimer.INTERVAL);
    BrushingTimerAssertions.assertValues(timer, BrushingTimer.RUNNING, 30000, 90000, 0.25, 2);
    clock.advance(90000);
    Test.assertEqual(timer.synchronize(), BrushingTimer.COMPLETION);
    BrushingTimerAssertions.assertValues(timer, BrushingTimer.COMPLETED, 120000, 0, 1.0, 4);
    return true;
}

(:test)
function timerNegativeToZeroRollover(logger as Test.Logger) as Boolean {
    var clock = new FakeClock(-1);
    var timer = new BrushingTimer(TimerConfig.createDefault(), clock);
    Test.assertEqual(timer.handleAction(BrushingTimer.START), BrushingTimer.NONE);
    clock.advance(1);
    Test.assertEqual(timer.synchronize(), BrushingTimer.NONE);
    Test.assertEqual(timer.getElapsedMs(), 1);
    clock.advance(29999);
    Test.assertEqual(timer.handleAction(BrushingTimer.PAUSE), BrushingTimer.INTERVAL);
    BrushingTimerAssertions.assertValues(timer, BrushingTimer.PAUSED, 30000, 90000, 0.25, 2);
    return true;
}

(:test)
function timerRolloverDuringPause(logger as Test.Logger) as Boolean {
    var clock = new FakeClock(2147463647);
    var timer = new BrushingTimer(TimerConfig.createDefault(), clock);
    Test.assertEqual(timer.handleAction(BrushingTimer.START), BrushingTimer.NONE);
    clock.advance(12345);
    Test.assertEqual(timer.handleAction(BrushingTimer.PAUSE), BrushingTimer.NONE);
    clock.advance(50000);
    Test.assertEqual(timer.synchronize(), BrushingTimer.NONE);
    Test.assertEqual(timer.getElapsedMs(), 12345);
    Test.assertEqual(timer.handleAction(BrushingTimer.RESUME), BrushingTimer.NONE);
    clock.advance(17655);
    Test.assertEqual(timer.synchronize(), BrushingTimer.INTERVAL);
    BrushingTimerAssertions.assertValues(timer, BrushingTimer.RUNNING, 30000, 90000, 0.25, 2);
    return true;
}

(:test)
function timerAlternateConfiguration(logger as Test.Logger) as Boolean {
    var clock = new FakeClock(76);
    var timer = new BrushingTimer(new TimerConfig(3500, 500), clock);
    Test.assertEqual(timer.handleAction(BrushingTimer.START), BrushingTimer.NONE);
    for (var stage = 2; stage <= 7; stage += 1) {
        clock.advance(500);
        Test.assertEqual(timer.synchronize(), BrushingTimer.INTERVAL);
        BrushingTimerAssertions.assertValues(timer, BrushingTimer.RUNNING, (stage - 1) * 500,
            3500 - (stage - 1) * 500, (stage - 1).toFloat() / 7, stage);
        Test.assertEqual(timer.synchronize(), BrushingTimer.NONE);
    }
    clock.advance(500);
    Test.assertEqual(timer.synchronize(), BrushingTimer.COMPLETION);
    BrushingTimerAssertions.assertValues(timer, BrushingTimer.COMPLETED, 3500, 0, 1.0, 7);
    return true;
}

(:test)
function timerSingleStageConfiguration(logger as Test.Logger) as Boolean {
    var clock = new FakeClock(90);
    var timer = new BrushingTimer(new TimerConfig(1, 1), clock);
    Test.assertEqual(timer.handleAction(BrushingTimer.START), BrushingTimer.NONE);
    BrushingTimerAssertions.assertValues(timer, BrushingTimer.RUNNING, 0, 1, 0.0, 1);
    clock.advance(1);
    Test.assertEqual(timer.synchronize(), BrushingTimer.COMPLETION);
    BrushingTimerAssertions.assertValues(timer, BrushingTimer.COMPLETED, 1, 0, 1.0, 1);
    Test.assertEqual(timer.synchronize(), BrushingTimer.NONE);
    return true;
}

(:test)
function timerSamplesAndObservation(logger as Test.Logger) as Boolean {
    var clock = new FakeClock(321);
    var timer = new BrushingTimer(TimerConfig.createDefault(), clock);
    Test.assertEqual(clock.getSampleCount(), 0);
    Test.assertEqual(timer.handleAction(BrushingTimer.START), BrushingTimer.NONE);
    Test.assertEqual(clock.getSampleCount(), 1);
    clock.advance(30000);
    // Drawing sees the last synchronized snapshot, without stealing the cue.
    BrushingTimerAssertions.assertValues(timer, BrushingTimer.RUNNING, 0, 120000, 0.0, 1);
    Test.assertEqual(clock.getSampleCount(), 1);
    Test.assertEqual(timer.synchronize(), BrushingTimer.INTERVAL);
    Test.assertEqual(clock.getSampleCount(), 2);
    clock.advance(1234);
    Test.assertEqual(timer.handleAction(BrushingTimer.PAUSE), BrushingTimer.NONE);
    BrushingTimerAssertions.assertValues(timer, BrushingTimer.PAUSED, 31234, 88766, 31234.0 / 120000, 2);
    Test.assertEqual(clock.getSampleCount(), 3);
    Test.assertEqual(timer.handleAction(BrushingTimer.RESUME), BrushingTimer.NONE);
    Test.assertEqual(clock.getSampleCount(), 4);
    Test.assertEqual(timer.handleAction(BrushingTimer.STOP), BrushingTimer.NONE);
    Test.assertEqual(clock.getSampleCount(), 5);
    return true;
}

(:test)
function timerRepeatedActions(logger as Test.Logger) as Boolean {
    var clock = new FakeClock(123);
    var timer = new BrushingTimer(TimerConfig.createDefault(), clock);
    Test.assertEqual(timer.handleAction(BrushingTimer.PAUSE), BrushingTimer.NONE);
    Test.assertEqual(timer.handleAction(BrushingTimer.RESUME), BrushingTimer.NONE);
    Test.assertEqual(timer.handleAction(BrushingTimer.STOP), BrushingTimer.NONE);
    Test.assertEqual(timer.getState(), BrushingTimer.READY);
    Test.assertEqual(timer.handleAction(BrushingTimer.START), BrushingTimer.NONE);
    clock.advance(12345);
    Test.assertEqual(timer.handleAction(BrushingTimer.START), BrushingTimer.NONE);
    Test.assertEqual(timer.handleAction(BrushingTimer.RESUME), BrushingTimer.NONE);
    Test.assertEqual(timer.handleAction(BrushingTimer.PAUSE), BrushingTimer.NONE);
    clock.advance(60000);
    Test.assertEqual(timer.handleAction(BrushingTimer.PAUSE), BrushingTimer.NONE);
    Test.assertEqual(timer.handleAction(BrushingTimer.START), BrushingTimer.NONE);
    BrushingTimerAssertions.assertValues(timer, BrushingTimer.PAUSED, 12345, 107655, 12345.0 / 120000, 1);
    Test.assertEqual(timer.handleAction(BrushingTimer.RESUME), BrushingTimer.NONE);
    clock.advance(17655);
    Test.assertEqual(timer.synchronize(), BrushingTimer.INTERVAL);
    BrushingTimerAssertions.assertValues(timer, BrushingTimer.RUNNING, 30000, 90000, 0.25, 2);
    return true;
}
