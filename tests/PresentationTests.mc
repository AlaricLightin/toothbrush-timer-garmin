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
