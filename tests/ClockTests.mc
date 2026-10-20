import Toybox.Lang;
import Toybox.System;
import Toybox.Test;

(:test)
function fakeClockControlledTime(logger as Test.Logger) as Boolean {
    var fakeClock = new FakeClock(12345);
    var clock = fakeClock;
    Test.assertEqual(clock.nowMs(), 12345);
    Test.assertEqual(clock.nowMs(), 12345);
    fakeClock.advance(0);
    Test.assertEqual(clock.nowMs(), 12345);
    fakeClock.advance(678);
    Test.assertEqual(clock.nowMs(), 13023);
    return true;
}

(:test)
function fakeClockSignedRollover(logger as Test.Logger) as Boolean {
    var clock = new FakeClock(2147483647);
    clock.advance(1);
    Test.assertEqual(clock.nowMs(), -2147483648);
    clock.advance(37);
    Test.assertEqual(clock.nowMs(), -2147483611);
    return true;
}

(:test)
function fakeClockNegativeToZero(logger as Test.Logger) as Boolean {
    var clock = new FakeClock(-1);
    Test.assertEqual(clock.nowMs(), -1);
    clock.advance(1);
    Test.assertEqual(clock.nowMs(), 0);
    return true;
}

(:test)
function systemClockUsesTimer(logger as Test.Logger) as Boolean {
    var before = System.getTimer();
    var clock = new SystemClock();
    var sampled = clock.nowMs();
    var after = System.getTimer();
    Test.assert(sampled - before >= 0);
    Test.assert(after - sampled >= 0);
    return true;
}
