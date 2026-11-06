import Toybox.Lang;

// Integer pixel bounds are shared by drawing and touch hit testing.
class ControlBounds {
    var x as Number;
    var y as Number;
    var width as Number;
    var height as Number;

    function initialize(left as Number, top as Number, w as Number, h as Number) {
        x = left;
        y = top;
        width = w;
        height = h;
    }

    function contains(px as Number, py as Number) as Boolean {
        if (px < x || px >= x + width || py < y || py >= y + height) {
            return false;
        }
        var radius = height / 2;
        var capX = px < x + radius ? x + radius : x + width - radius;
        if (px >= x + radius && px <= x + width - radius) {
            return true;
        }
        var dx = px - capX;
        var dy = py - (y + radius);
        return dx * dx + dy * dy <= radius * radius;
    }
}

class TimerLayout {
    var centerX as Number;
    var ringY as Number;
    var ringRadius as Number;
    var ringWidth as Number;
    var iconY as Number;
    var timeY as Number;
    var stageY as Number;
    var completedIconY as Number;
    var completionY as Number;
    var start as ControlBounds;
    var primary as ControlBounds;
    var stop as ControlBounds;

    function initialize(width as Number, height as Number) {
        var size = width < height ? width : height;
        centerX = width / 2;
        ringY = height / 2;
        ringRadius = (size * 0.46).toNumber();
        ringWidth = (size * 0.025).toNumber();
        var innerRadius = ringRadius - (ringWidth + 1) / 2;
        iconY = ringY - (innerRadius * 0.60).toNumber();
        timeY = ringY - (innerRadius * 0.08).toNumber();
        stageY = ringY + (innerRadius * 0.24).toNumber();
        completedIconY = ringY - (innerRadius * 0.32).toNumber();
        completionY = ringY + (innerRadius * 0.28).toNumber();
        // The lower outer corners stay inside the ring on a circular display.
        var top = ringY + (innerRadius * 0.43).toNumber();
        var controlHeight = (innerRadius * 0.30).toNumber();
        var startWidth = (innerRadius * 0.96).toNumber();
        var controlWidth = (innerRadius * 0.60).toNumber();
        var halfGap = (innerRadius * 0.06).toNumber();
        start = new ControlBounds(centerX - startWidth / 2, top,
            startWidth, controlHeight);
        primary = new ControlBounds(centerX - halfGap - controlWidth, top,
            controlWidth, controlHeight);
        stop = new ControlBounds(centerX + halfGap, top,
            controlWidth, controlHeight);
    }
}
