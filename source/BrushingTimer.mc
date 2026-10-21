import Toybox.Lang;

class BrushingTimer {
    enum State {
        READY,
        RUNNING,
        PAUSED,
        COMPLETED
    }

    enum Cue {
        NONE,
        INTERVAL,
        COMPLETION
    }

    enum Action {
        START,
        PAUSE,
        RESUME,
        STOP
    }

    private var _config as TimerConfig;
    private var _clock as Clock;
    private var _state as State = READY;
    private var _accumulatedElapsedMs as Number = 0;
    private var _runStartedAtMs as Number = 0;
    private var _elapsedMs as Number = 0;
    private var _processedBoundary as Number = 0;

    function initialize(config as TimerConfig, clock as Clock) {
        _config = config;
        _clock = clock;
    }

    // The caller consumes this result once. Drawing only reads the getters.
    function synchronize() as Cue {
        return synchronizeAt(_clock.nowMs());
    }

    // Synchronize and apply input with the same sample, returning any crossed cue
    // rather than consuming it inside a pause/stop helper. Completion wins input.
    function handleAction(action as Action) as Cue {
        var nowMs = _clock.nowMs();
        var cue = synchronizeAt(nowMs);
        if (_state == COMPLETED) {
            return cue;
        }

        if (action == START && _state == READY) {
            _runStartedAtMs = nowMs;
            _state = RUNNING;
        } else if (action == PAUSE && _state == RUNNING) {
            _accumulatedElapsedMs = _elapsedMs;
            _state = PAUSED;
        } else if (action == RESUME && _state == PAUSED) {
            _runStartedAtMs = nowMs;
            _state = RUNNING;
        } else if (action == STOP && (_state == RUNNING || _state == PAUSED)) {
            _state = READY;
            _accumulatedElapsedMs = 0;
            _runStartedAtMs = 0;
            _elapsedMs = 0;
            _processedBoundary = 0;
        }
        return cue;
    }

    private function synchronizeAt(nowMs as Number) as Cue {
        if (_state != RUNNING) {
            return NONE;
        }

        // Keep subtraction in rolling 32-bit Number arithmetic. For normal
        // running periods this yields a positive delta across either wrap edge.
        _elapsedMs = _accumulatedElapsedMs + (nowMs - _runStartedAtMs);
        if (_elapsedMs >= _config.getTotalDurationMs()) {
            _elapsedMs = _config.getTotalDurationMs();
            _state = COMPLETED;
            return COMPLETION;
        }

        var boundary = _elapsedMs / _config.getIntervalDurationMs();
        if (boundary > _processedBoundary) {
            // Collapse all overdue intermediate boundaries into one cue.
            _processedBoundary = boundary;
            return INTERVAL;
        }
        return NONE;
    }

    function getState() as State {
        return _state;
    }

    function getElapsedMs() as Number {
        return _elapsedMs;
    }

    function getRemainingMs() as Number {
        return _config.getTotalDurationMs() - _elapsedMs;
    }

    function getProgress() as Float {
        return _elapsedMs.toFloat() / _config.getTotalDurationMs();
    }

    function getStage() as Number {
        var stage = _elapsedMs / _config.getIntervalDurationMs() + 1;
        return stage > _config.getStageCount() ? _config.getStageCount() : stage;
    }
}
