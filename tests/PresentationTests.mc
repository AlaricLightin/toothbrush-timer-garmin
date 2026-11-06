import Toybox.Lang;
import Toybox.Test;

(:test)
function countdownFormatting(logger as Test.Logger) as Boolean {
    var config = TimerConfig.createDefault();
    var view = new ToothbrushTimerView(new BrushingTimer(config, new FakeClock(0)), config);
    var inputs = [120000, 119999, 119000, 1000, 1, 0, 60001, 60000, 59999];
    var expected = ["2:00", "2:00", "1:59", "0:01", "0:01", "0:00", "1:01", "1:00", "1:00"];
    for (var i = 0; i < inputs.size(); i += 1) {
        Test.assertEqual(view.formatRemainingTime(inputs[i]), expected[i]);
    }
    return true;
}

(:test)
function presentationFollowsModel(logger as Test.Logger) as Boolean {
    var config = TimerConfig.createDefault();
    var clock = new FakeClock(0);
    var timer = new BrushingTimer(config, clock);
    var view = new ToothbrushTimerView(timer, config);
    Test.assertEqual(view.getPrimaryLabel(), "Start");
    Test.assertEqual(view.getStageLabel(), "Stage 1/4");
    timer.handleAction(BrushingTimer.START);
    Test.assertEqual(view.getPrimaryLabel(), "Pause");
    clock.advance(50000);
    timer.handleAction(BrushingTimer.PAUSE);
    Test.assertEqual(view.getPrimaryLabel(), "Resume");
    Test.assertEqual(view.getStageLabel(), "Stage 2/4");
    Test.assertEqual(view.formatRemainingTime(timer.getRemainingMs()), "1:10");
    clock.advance(90000);
    Test.assertEqual(view.getStageLabel(), "Stage 2/4");
    Test.assertEqual(view.formatRemainingTime(timer.getRemainingMs()), "1:10");
    timer.handleAction(BrushingTimer.STOP);
    Test.assertEqual(view.getPrimaryLabel(), "Start");
    Test.assertEqual(view.getStageLabel(), "Stage 1/4");
    Test.assertEqual(view.formatRemainingTime(timer.getRemainingMs()), "2:00");
    return true;
}

(:test)
function presentationUsesConfiguredStages(logger as Test.Logger) as Boolean {
    var config = new TimerConfig(150000, 25000);
    var clock = new FakeClock(0);
    var timer = new BrushingTimer(config, clock);
    var view = new ToothbrushTimerView(timer, config);
    Test.assertEqual(view.getStageLabel(), "Stage 1/6");
    Test.assertEqual(view.formatRemainingTime(timer.getRemainingMs()), "2:30");
    timer.handleAction(BrushingTimer.START);
    for (var stage = 2; stage <= config.getStageCount(); stage += 1) {
        clock.advance(config.getIntervalDurationMs());
        timer.synchronize();
        Test.assertEqual(view.getStageLabel(), "Stage " + stage + "/6");
    }
    return true;
}

(:test)
function controlGeometryHitTesting(logger as Test.Logger) as Boolean {
    var sizes = [240, 390, 454];
    for (var i = 0; i < sizes.size(); i += 1) {
        var layout = new TimerLayout(sizes[i], sizes[i]);
        var controls = [layout.start, layout.primary, layout.stop];
        for (var j = 0; j < controls.size(); j += 1) {
            var bounds = controls[j];
            Test.assert(bounds.contains(bounds.x, bounds.y));
            Test.assert(bounds.contains(bounds.x + bounds.width - 1, bounds.y + bounds.height - 1));
            Test.assert(bounds.contains(bounds.x + bounds.width / 2, bounds.y + bounds.height / 2));
            Test.assert(!bounds.contains(bounds.x - 1, bounds.y));
            Test.assert(!bounds.contains(bounds.x, bounds.y - 1));
            Test.assert(!bounds.contains(bounds.x + bounds.width, bounds.y));
            Test.assert(!bounds.contains(bounds.x, bounds.y + bounds.height));
        }
        Test.assert(!layout.primary.contains(layout.stop.x, layout.stop.y));
        Test.assert(!layout.stop.contains(layout.primary.x + layout.primary.width - 1, layout.primary.y));
    }
    return true;
}

(:test)
function controlsFitInsideProgressRing(logger as Test.Logger) as Boolean {
    var widths = [240, 390, 454, 320, 400];
    var heights = [240, 390, 454, 400, 320];
    for (var i = 0; i < widths.size(); i += 1) {
        var layout = new TimerLayout(widths[i], heights[i]);
        var outerRadius = layout.ringRadius + (layout.ringWidth + 1) / 2;
        Test.assert(layout.centerX - outerRadius > 0);
        Test.assert(layout.centerX + outerRadius < widths[i]);
        Test.assert(layout.ringY - outerRadius > 0);
        Test.assert(layout.ringY + outerRadius < heights[i]);
        var innerRadius = layout.ringRadius - (layout.ringWidth + 1) / 2;
        var controls = [layout.start, layout.primary, layout.stop];
        for (var j = 0; j < controls.size(); j += 1) {
            var bounds = controls[j];
            var edgesX = [bounds.x, bounds.x + bounds.width];
            var edgesY = [bounds.y, bounds.y + bounds.height];
            for (var x = 0; x < edgesX.size(); x += 1) {
                for (var y = 0; y < edgesY.size(); y += 1) {
                    var dx = edgesX[x] - layout.centerX;
                    var dy = edgesY[y] - layout.ringY;
                    Test.assert(dx * dx + dy * dy < innerRadius * innerRadius);
                }
            }
        }
    }
    return true;
}

(:test)
function segmentFractionsAndBoundaries(logger as Test.Logger) as Boolean {
    var ring = new SegmentedRing(4);
    var progress = [-0.1, 0.0, 0.125, 0.25, 0.375, 0.5, 0.75, 1.0, 1.1];
    var expected = [
        [0.0, 0.0, 0.0, 0.0],
        [0.0, 0.0, 0.0, 0.0],
        [0.5, 0.0, 0.0, 0.0],
        [1.0, 0.0, 0.0, 0.0],
        [1.0, 0.5, 0.0, 0.0],
        [1.0, 1.0, 0.0, 0.0],
        [1.0, 1.0, 1.0, 0.0],
        [1.0, 1.0, 1.0, 1.0],
        [1.0, 1.0, 1.0, 1.0]
    ];
    for (var sample = 0; sample < progress.size(); sample += 1) {
        for (var stage = 0; stage < 4; stage += 1) {
            Test.assertEqual(ring.getFillFraction(progress[sample], stage), expected[sample][stage]);
        }
    }
    return true;
}

(:test)
function segmentFractionsUseConfiguredStages(logger as Test.Logger) as Boolean {
    var config = new TimerConfig(150000, 25000);
    var clock = new FakeClock(0);
    var timer = new BrushingTimer(config, clock);
    var ring = new SegmentedRing(config.getStageCount());
    timer.handleAction(BrushingTimer.START);
    for (var stage = 0; stage < config.getStageCount(); stage += 1) {
        clock.advance(12500);
        timer.synchronize();
        for (var index = 0; index < config.getStageCount(); index += 1) {
            var expected = index < stage ? 1.0 : (index == stage ? 0.5 : 0.0);
            var error = ring.getFillFraction(timer.getProgress(), index) - expected;
            Test.assert(error > -0.00001 && error < 0.00001);
        }
        clock.advance(12500);
        timer.synchronize();
        for (var index = 0; index < config.getStageCount(); index += 1) {
            Test.assertEqual(ring.getFillFraction(timer.getProgress(), index), index <= stage ? 1.0 : 0.0);
        }
    }
    return true;
}

(:test)
function segmentProgressIsIndependentOfRoundedTime(logger as Test.Logger) as Boolean {
    var config = TimerConfig.createDefault();
    var clock = new FakeClock(0);
    var timer = new BrushingTimer(config, clock);
    var view = new ToothbrushTimerView(timer, config);
    var ring = new SegmentedRing(config.getStageCount());
    timer.handleAction(BrushingTimer.START);
    clock.advance(29999);
    timer.synchronize();
    Test.assertEqual(view.formatRemainingTime(timer.getRemainingMs()), "1:31");
    Test.assert(ring.getFillFraction(timer.getProgress(), 0) < 1.0);
    Test.assertEqual(ring.getFillFraction(timer.getProgress(), 1), 0.0);
    clock.advance(1);
    timer.synchronize();
    Test.assertEqual(ring.getFillFraction(timer.getProgress(), 0), 1.0);
    Test.assertEqual(ring.getFillFraction(timer.getProgress(), 1), 0.0);
    clock.advance(1);
    timer.handleAction(BrushingTimer.PAUSE);
    Test.assertEqual(view.formatRemainingTime(timer.getRemainingMs()), "1:30");
    var fraction = ring.getFillFraction(timer.getProgress(), 1);
    Test.assert(fraction > 0.0);
    clock.advance(60000);
    timer.synchronize();
    Test.assertEqual(ring.getFillFraction(timer.getProgress(), 1), fraction);
    return true;
}

(:test)
function segmentAnglesPreserveGapsAndSkipTinyFills(logger as Test.Logger) as Boolean {
    // Seven stages exercise fractional slot angles, including negative endpoints.
    var counts = [1, 4, 6, 7];
    for (var sample = 0; sample < counts.size(); sample += 1) {
        var count = counts[sample];
        var ring = new SegmentedRing(count);
        Test.assert(ring.getStartAngle(0) < 90);
        Test.assert(ring.getEndAngle(count - 1) > -270);
        for (var index = 0; index < count; index += 1) {
            var start = ring.getStartAngle(index);
            var end = ring.getEndAngle(index);
            var fullSweep = start - end;
            Test.assert(fullSweep > 0 && fullSweep < 360);
            Test.assertEqual(ring.getFilledSweep(0.0, index), 0);
            Test.assertEqual(ring.getFilledSweep(1.0, index), fullSweep);
            var tinyProgress = (index + 0.0001) / count;
            Test.assert(ring.getFillFraction(tinyProgress, index) > 0.0);
            Test.assertEqual(ring.getFilledSweep(tinyProgress, index), 0);
            var halfProgress = (index + 0.5) / count;
            Test.assertEqual(ring.getFilledSweep(halfProgress, index), (fullSweep * 0.5).toNumber());
            if (index + 1 < count) {
                Test.assert(end > ring.getStartAngle(index + 1));
            }
        }
    }
    return true;
}
