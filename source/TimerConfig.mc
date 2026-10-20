import Toybox.Lang;

class TimerConfig {
    static const DEFAULT_TOTAL_DURATION_MS = 120000;
    static const DEFAULT_INTERVAL_DURATION_MS = 30000;

    private var _totalDurationMs as Number;
    private var _intervalDurationMs as Number;
    private var _stageCount as Number;

    // Callers supply positive durations with total evenly divisible by interval.
    function initialize(totalDurationMs as Number, intervalDurationMs as Number) {
        _totalDurationMs = totalDurationMs;
        _intervalDurationMs = intervalDurationMs;
        _stageCount = totalDurationMs / intervalDurationMs;
    }

    static function createDefault() as TimerConfig {
        return new TimerConfig(DEFAULT_TOTAL_DURATION_MS, DEFAULT_INTERVAL_DURATION_MS);
    }

    function getTotalDurationMs() as Number {
        return _totalDurationMs;
    }

    function getIntervalDurationMs() as Number {
        return _intervalDurationMs;
    }

    function getStageCount() as Number {
        return _stageCount;
    }
}
