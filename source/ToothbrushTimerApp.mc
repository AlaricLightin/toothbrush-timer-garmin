import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class ToothbrushTimerApp extends Application.AppBase {
    private var _delegate as ToothbrushTimerDelegate?;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        // Suspension state is deliberately ignored, including a reported resume.
        cleanup();
    }

    function onStop(state as Dictionary?) as Void {
        cleanup();
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        cleanup();
        var config = TimerConfig.createDefault();
        var timer = new BrushingTimer(config, new SystemClock());
        var view = new ToothbrushTimerView(timer, config);
        var delegate = new ToothbrushTimerDelegate(timer, view, new HapticsService());
        _delegate = delegate;
        return [view, delegate];
    }

    private function cleanup() as Void {
        var delegate = _delegate;
        if (delegate != null) {
            delegate.cleanup();
            _delegate = null;
        }
    }
}

function getApp() as ToothbrushTimerApp {
    return Application.getApp() as ToothbrushTimerApp;
}
