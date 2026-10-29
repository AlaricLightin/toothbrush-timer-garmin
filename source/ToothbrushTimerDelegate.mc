import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

class ToothbrushTimerDelegate extends WatchUi.BehaviorDelegate {
    protected var _timer as BrushingTimer;
    protected var _view as ToothbrushTimerView;
    private var _haptics as HapticsService;
    private var _updateTimer as Timer.Timer?;
    private var _active as Boolean = true;

    function initialize(timer as BrushingTimer, view as ToothbrushTimerView, haptics as HapticsService) {
        BehaviorDelegate.initialize();
        _timer = timer;
        _view = view;
        _haptics = haptics;
    }

    // Let raw taps retain their coordinates and Enter use the same primary action.
    function onSelect() as Boolean {
        return false;
    }

    function onKey(event as WatchUi.KeyEvent) as Boolean {
        return handleKey(event.getKey());
    }

    function handleKey(key as WatchUi.Key) as Boolean {
        if (key != WatchUi.KEY_ENTER) {
            return false;
        }
        primaryAction();
        return true;
    }

    function onTap(event as WatchUi.ClickEvent) as Boolean {
        var coordinates = event.getCoordinates();
        return handleTap(coordinates[0], coordinates[1]);
    }

    function handleTap(x as Number, y as Number) as Boolean {
        var layout = _view.getLayout();
        if (!_active || layout == null) {
            return false;
        }
        var state = _timer.getState();
        if (state == BrushingTimer.READY) {
            if (layout.start.contains(x, y)) {
                primaryAction();
                return true;
            }
        } else if (state == BrushingTimer.RUNNING || state == BrushingTimer.PAUSED) {
            if (layout.primary.contains(x, y)) {
                primaryAction();
                return true;
            }
            if (layout.stop.contains(x, y)) {
                applyAction(BrushingTimer.STOP);
                return true;
            }
        }
        return false;
    }

    private function primaryAction() as Void {
        if (!_active) {
            return;
        }
        var state = _timer.getState();
        if (state == BrushingTimer.READY) {
            applyAction(BrushingTimer.START);
        } else if (state == BrushingTimer.RUNNING) {
            applyAction(BrushingTimer.PAUSE);
        } else if (state == BrushingTimer.PAUSED) {
            applyAction(BrushingTimer.RESUME);
        }
    }

    private function applyAction(action as BrushingTimer.Action) as Void {
        if (consumeCue(_timer.handleAction(action))) {
            return;
        }
        if (_timer.getState() == BrushingTimer.RUNNING) {
            startUpdates();
        } else {
            stopUpdates();
        }
        requestRedraw();
    }

    function onTimer() as Void {
        if (!_active || _timer.getState() != BrushingTimer.RUNNING) {
            return;
        }
        if (!consumeCue(_timer.synchronize())) {
            requestRedraw();
        }
    }

    // True means terminal handling won; callers must not process input or redraw.
    private function consumeCue(cue as BrushingTimer.Cue) as Boolean {
        if (cue == BrushingTimer.COMPLETION) {
            cleanup();
            _haptics.completionCue();
            exitApplication();
            return true;
        }
        if (cue == BrushingTimer.INTERVAL) {
            _haptics.intervalCue();
        }
        return false;
    }

    function onBack() as Boolean {
        if (!_active) {
            return true;
        }
        if (consumeCue(_timer.synchronize())) {
            return true;
        }
        cleanup();
        exitApplication();
        return true;
    }

    // AppBase.onStop owns termination cleanup; hiding the view is not termination.
    function cleanup() as Void {
        if (!_active) {
            return;
        }
        _active = false;
        stopUpdates();
    }

    protected function startUpdates() as Void {
        var updateTimer = new Timer.Timer();
        _updateTimer = updateTimer;
        updateTimer.start(method(:onTimer), 250, true);
    }

    protected function stopUpdates() as Void {
        var updateTimer = _updateTimer;
        if (updateTimer != null) {
            updateTimer.stop();
            // Release our timer reference even if stop retains its callback.
            _updateTimer = null;
        }
    }

    protected function requestRedraw() as Void {
        WatchUi.requestUpdate();
    }

    protected function exitApplication() as Void {
        System.exit();
    }
}
