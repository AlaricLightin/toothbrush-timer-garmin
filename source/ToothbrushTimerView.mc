import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class ToothbrushTimerView extends WatchUi.View {
    private var _timer as BrushingTimer;
    private var _config as TimerConfig;
    private var _layout as TimerLayout?;
    private var _ring as SegmentedRing;
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
        _ring = new SegmentedRing(config.getStageCount());
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
        dc.setColor(TimerPalette.BACKGROUND, TimerPalette.BACKGROUND);
        dc.clear();
        var layout = _layout;
        // onLayout precedes drawing; no COMPLETED screen is presented.
        if (layout == null || _timer.getState() == BrushingTimer.COMPLETED) {
            return;
        }
        drawProgress(dc, layout);
        _toothbrush.draw(dc);
        dc.setColor(TimerPalette.FOREGROUND, Graphics.COLOR_TRANSPARENT);
        dc.drawText(layout.centerX, layout.timeY, Graphics.FONT_NUMBER_HOT,
            formatRemainingTime(_timer.getRemainingMs()),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        if (_timer.getState() == BrushingTimer.READY) {
            drawControl(dc, layout.start, getPrimaryLabel());
        } else {
            dc.setColor(TimerPalette.SECONDARY_FOREGROUND, Graphics.COLOR_TRANSPARENT);
            dc.drawText(layout.centerX, layout.stageY, Graphics.FONT_SMALL,
                getStageLabel(), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            drawControl(dc, layout.primary, getPrimaryLabel());
            drawControl(dc, layout.stop, _stop);
        }
    }

    private function drawControl(dc as Dc, bounds as ControlBounds, label as String) as Void {
        dc.setColor(TimerPalette.FOREGROUND, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawRectangle(bounds.x, bounds.y, bounds.width, bounds.height);
        dc.drawText(bounds.x + bounds.width / 2, bounds.y + bounds.height / 2,
            Graphics.FONT_TINY, label, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawProgress(dc as Dc, layout as TimerLayout) as Void {
        dc.setPenWidth(layout.ringWidth);
        var progress = _timer.getProgress();
        var progressColor = _timer.getState() == BrushingTimer.PAUSED
            ? TimerPalette.PAUSED_PROGRESS : TimerPalette.ACCENT;
        for (var stage = 0; stage < _config.getStageCount(); stage += 1) {
            var startAngle = _ring.getStartAngle(stage);
            var endAngle = _ring.getEndAngle(stage);
            dc.setColor(TimerPalette.SECONDARY_SURFACE, TimerPalette.BACKGROUND);
            // Also skip tracks too small to survive SDK angle truncation.
            if (startAngle > endAngle) {
                dc.drawArc(layout.centerX, layout.ringY, layout.ringRadius,
                    Graphics.ARC_CLOCKWISE, startAngle, endAngle);
            }
            var sweep = _ring.getFilledSweep(progress, stage);
            if (sweep > 0) {
                dc.setColor(progressColor, TimerPalette.BACKGROUND);
                dc.drawArc(layout.centerX, layout.ringY, layout.ringRadius,
                    Graphics.ARC_CLOCKWISE, startAngle, startAngle - sweep);
            }
        }
        dc.setPenWidth(1);
    }
}
