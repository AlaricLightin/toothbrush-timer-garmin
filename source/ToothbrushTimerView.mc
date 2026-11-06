import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class ToothbrushTimerView extends WatchUi.View {
    private var _timer as BrushingTimer;
    private var _config as TimerConfig;
    private var _layout as TimerLayout?;
    private var _ring as SegmentedRing;
    private var _toothbrush as WatchUi.Bitmap;
    private var _toothbrushWidth as Number;
    private var _toothbrushHeight as Number;
    private var _start as String;
    private var _completionMessage as String;
    private var _stageFormat as String;
    private var _timeFormat as String;

    function initialize(timer as BrushingTimer, config as TimerConfig) {
        View.initialize();
        _timer = timer;
        _config = config;
        _ring = new SegmentedRing(config.getStageCount());
        // Let the drawable handle the platform's underlying bitmap resource type.
        _toothbrush = new WatchUi.Bitmap({:rezId => Rez.Drawables.Toothbrush});
        var dimensions = _toothbrush.getDimensions();
        _toothbrushWidth = dimensions[0].toNumber();
        _toothbrushHeight = dimensions[1].toNumber();
        _start = WatchUi.loadResource(Rez.Strings.Start) as String;
        _completionMessage = WatchUi.loadResource(Rez.Strings.CompletionMessage) as String;
        _stageFormat = WatchUi.loadResource(Rez.Strings.StageFormat) as String;
        _timeFormat = WatchUi.loadResource(Rez.Strings.TimeFormat) as String;
    }

    function onLayout(dc as Dc) as Void {
        var layout = new TimerLayout(dc.getWidth(), dc.getHeight());
        _layout = layout;
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

    function getSessionState() as BrushingTimer.State {
        return _timer.getState();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(TimerPalette.BACKGROUND, TimerPalette.BACKGROUND);
        dc.clear();
        var layout = _layout;
        if (layout == null) {
            return;
        }
        drawProgress(dc, layout);
        var completed = getSessionState() == BrushingTimer.COMPLETED;
        _toothbrush.setLocation(layout.centerX - _toothbrushWidth / 2,
            (completed ? layout.completedIconY : layout.iconY) - _toothbrushHeight / 2);
        _toothbrush.draw(dc);
        if (completed) {
            drawCompletion(dc, layout);
            return;
        }
        dc.setColor(TimerPalette.FOREGROUND, Graphics.COLOR_TRANSPARENT);
        dc.drawText(layout.centerX, layout.timeY, Graphics.FONT_NUMBER_HOT,
            formatRemainingTime(_timer.getRemainingMs()),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        if (getSessionState() == BrushingTimer.READY) {
            drawControl(dc, layout.start, TimerPalette.ACCENT);
            dc.setColor(TimerPalette.BACKGROUND, Graphics.COLOR_TRANSPARENT);
            dc.drawText(layout.centerX, layout.start.y + layout.start.height / 2,
                Graphics.FONT_SMALL, _start,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            dc.setColor(TimerPalette.SECONDARY_FOREGROUND, Graphics.COLOR_TRANSPARENT);
            dc.drawText(layout.centerX, layout.stageY, Graphics.FONT_SMALL,
                getStageLabel(), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            drawControl(dc, layout.primary, TimerPalette.ACCENT);
            drawPrimaryIcon(dc, layout.primary);
            drawControl(dc, layout.stop, TimerPalette.SECONDARY_SURFACE);
            var side = layout.stop.height * 2 / 5;
            dc.setColor(TimerPalette.FOREGROUND, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(layout.stop.x + (layout.stop.width - side) / 2,
                layout.stop.y + (layout.stop.height - side) / 2, side, side);
        }
    }

    private function drawControl(dc as Dc, bounds as ControlBounds, color as ColorType) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(bounds.x, bounds.y, bounds.width, bounds.height, bounds.height / 2);
    }

    private function drawPrimaryIcon(dc as Dc, bounds as ControlBounds) as Void {
        var centerX = bounds.x + bounds.width / 2;
        var centerY = bounds.y + bounds.height / 2;
        var halfSize = bounds.height / 5;
        dc.setColor(TimerPalette.BACKGROUND, Graphics.COLOR_TRANSPARENT);
        if (getSessionState() == BrushingTimer.PAUSED) {
            dc.fillPolygon([[centerX - halfSize, centerY - halfSize],
                [centerX + halfSize, centerY], [centerX - halfSize, centerY + halfSize]]);
        } else {
            var barWidth = bounds.height / 10;
            dc.fillRoundedRectangle(centerX - halfSize, centerY - halfSize,
                barWidth, halfSize * 2, barWidth / 2);
            dc.fillRoundedRectangle(centerX + halfSize - barWidth, centerY - halfSize,
                barWidth, halfSize * 2, barWidth / 2);
        }
    }

    private function drawCompletion(dc as Dc, layout as TimerLayout) as Void {
        dc.setColor(TimerPalette.FOREGROUND, Graphics.COLOR_TRANSPARENT);
        dc.drawText(layout.centerX, layout.completionY, Graphics.FONT_LARGE,
            _completionMessage, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(TimerPalette.ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(layout.ringWidth / 2);
        var innerOffset = _toothbrushWidth / 2 + layout.ringWidth;
        var rayLength = layout.ringRadius / 8;
        for (var side = -1; side <= 1; side += 2) {
            for (var ray = -1; ray <= 1; ray += 1) {
                dc.drawLine(layout.centerX + side * innerOffset,
                    layout.completedIconY + ray * rayLength,
                    layout.centerX + side * (innerOffset + rayLength),
                    layout.completedIconY + ray * rayLength * 2);
            }
        }
        dc.setPenWidth(1);
    }

    private function drawProgress(dc as Dc, layout as TimerLayout) as Void {
        dc.setPenWidth(layout.ringWidth);
        var progress = _timer.getProgress();
        var progressColor = getSessionState() == BrushingTimer.PAUSED
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
