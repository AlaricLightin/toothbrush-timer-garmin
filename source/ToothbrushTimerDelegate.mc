import Toybox.Lang;
import Toybox.WatchUi;

class ToothbrushTimerDelegate extends WatchUi.BehaviorDelegate {
    protected var _timer as BrushingTimer;
    protected var _view as ToothbrushTimerView;

    function initialize(timer as BrushingTimer, view as ToothbrushTimerView) {
        BehaviorDelegate.initialize();
        _timer = timer;
        _view = view;
    }

}
