import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.WatchUi;

class ToothbrushTimerView extends WatchUi.View {
    private var _timer as BrushingTimer;
    private var _config as TimerConfig;
    private var _layout as TimerLayout?;
    private var _toothbrush as WatchUi.Bitmap;
    private var _start as String;
    private var _pause as String;
    private var _resume as String;
    private var _stop as String;
    private var _stageFormat as String;
    private var _timeFormat as String;

    function initialize(timer as BrushingTimer, config as TimerConfig) {
        View.initialize();
        _timer = timer;
        _config = config;
        // Let the drawable handle the platform's underlying bitmap resource type.
        _toothbrush = new WatchUi.Bitmap({:rezId => Rez.Drawables.Toothbrush});
        _start = WatchUi.loadResource(Rez.Strings.Start) as String;
        _pause = WatchUi.loadResource(Rez.Strings.Pause) as String;
        _resume = WatchUi.loadResource(Rez.Strings.Resume) as String;
        _stop = WatchUi.loadResource(Rez.Strings.Stop) as String;
        _stageFormat = WatchUi.loadResource(Rez.Strings.StageFormat) as String;
        _timeFormat = WatchUi.loadResource(Rez.Strings.TimeFormat) as String;
    }

    function onLayout(dc as Dc) as Void {
        var layout = new TimerLayout(dc.getWidth(), dc.getHeight());
        _layout = layout;
        var dimensions = _toothbrush.getDimensions();
        _toothbrush.setLocation(layout.centerX - dimensions[0] / 2,
            layout.iconY - dimensions[1] / 2);
    }

    // Null only before the platform supplies the display dimensions.
    function getLayout() as TimerLayout? {
        return _layout;
    }

    function formatRemainingTime(remainingMs as Number) as String {
        var seconds = remainingMs / 1000;
        if (remainingMs % 1000 != 0) {
            seconds += 1;
        }
        return Lang.format(_timeFormat, [seconds / 60, (seconds % 60).format("%02d")]);
    }

    function getStageLabel() as String {
        return Lang.format(_stageFormat, [_timer.getStage(), _config.getStageCount()]);
    }

    function getPrimaryLabel() as String {
        if (_timer.getState() == BrushingTimer.READY) {
            return _start;
        }
        return _timer.getState() == BrushingTimer.PAUSED ? _resume : _pause;
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        var layout = _layout;
        // onLayout precedes drawing; no COMPLETED screen is presented.
        if (layout == null || _timer.getState() == BrushingTimer.COMPLETED) {
            return;
        }
        if (_timer.getState() != BrushingTimer.READY) {
            drawProgress(dc, layout);
        }
        _toothbrush.draw(dc);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(layout.centerX, layout.timeY, Graphics.FONT_NUMBER_HOT,
            formatRemainingTime(_timer.getRemainingMs()),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        if (_timer.getState() == BrushingTimer.READY) {
            drawControl(dc, layout.start, getPrimaryLabel());
        } else {
            dc.drawText(layout.centerX, layout.stageY, Graphics.FONT_SMALL,
                getStageLabel(), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            drawControl(dc, layout.primary, getPrimaryLabel());
            drawControl(dc, layout.stop, _stop);
        }
    }

    private function drawControl(dc as Dc, bounds as ControlBounds, label as String) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawRectangle(bounds.x, bounds.y, bounds.width, bounds.height);
        dc.drawText(bounds.x + bounds.width / 2, bounds.y + bounds.height / 2,
            Graphics.FONT_TINY, label, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawProgress(dc as Dc, layout as TimerLayout) as Void {
        dc.setPenWidth(layout.ringWidth);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
        dc.drawCircle(layout.centerX, layout.ringY, layout.ringRadius);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        var sweep = (_timer.getProgress() * 360).toNumber();
        // drawArc truncates angles and draws a full circle for equal endpoints.
        if (sweep >= 360) {
            dc.drawCircle(layout.centerX, layout.ringY, layout.ringRadius);
        } else if (sweep > 0) {
            dc.drawArc(layout.centerX, layout.ringY, layout.ringRadius,
                Graphics.ARC_CLOCKWISE, 90, 90 - sweep);
        }
        dc.setPenWidth(2);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        for (var stage = 0; stage < _config.getStageCount(); stage += 1) {
            var angle = 2 * Math.PI * stage / _config.getStageCount() - Math.PI / 2;
            var inner = layout.ringRadius - layout.ringWidth;
            var outer = layout.ringRadius + layout.ringWidth;
            dc.drawLine(layout.centerX + inner * Math.cos(angle), layout.ringY + inner * Math.sin(angle),
                layout.centerX + outer * Math.cos(angle), layout.ringY + outer * Math.sin(angle));
        }
        dc.setPenWidth(1);
    }
}
