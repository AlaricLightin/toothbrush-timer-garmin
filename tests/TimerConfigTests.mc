import Toybox.Lang;
import Toybox.Test;

(:test)
function defaultTimerConfig(logger as Test.Logger) as Boolean {
    var config = TimerConfig.createDefault();
    Test.assertEqual(config.getTotalDurationMs(), 120000);
    Test.assertEqual(config.getIntervalDurationMs(), 30000);
    Test.assertEqual(config.getStageCount(), 4);
    Test.assert(config.getTotalDurationMs() > 0);
    Test.assert(config.getIntervalDurationMs() > 0);
    Test.assertEqual(config.getTotalDurationMs() % config.getIntervalDurationMs(), 0);
    return true;
}

(:test)
function alternateTimerConfig(logger as Test.Logger) as Boolean {
    var config = new TimerConfig(150000, 25000);
    Test.assertEqual(config.getTotalDurationMs(), 150000);
    Test.assertEqual(config.getIntervalDurationMs(), 25000);
    Test.assertEqual(config.getStageCount(), 6);
    return true;
}

(:test)
function singleStageTimerConfig(logger as Test.Logger) as Boolean {
    var config = new TimerConfig(1, 1);
    Test.assertEqual(config.getStageCount(), 1);
    Test.assertEqual(config.getTotalDurationMs(), config.getIntervalDurationMs());
    return true;
}

(:test)
function independentTimerConfigs(logger as Test.Logger) as Boolean {
    var defaultConfig = TimerConfig.createDefault();
    var alternateConfig = new TimerConfig(7000, 1000);
    Test.assertEqual(alternateConfig.getStageCount(), 7);
    Test.assertEqual(defaultConfig.getStageCount(), 4);
    Test.assertEqual(defaultConfig.getTotalDurationMs(), 120000);
    return true;
}
