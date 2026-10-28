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
        return px >= x && px < x + width && py >= y && py < y + height;
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
    var start as ControlBounds;
    var primary as ControlBounds;
    var stop as ControlBounds;

    function initialize(width as Number, height as Number) {
        var size = width < height ? width : height;
        centerX = width / 2;
        ringY = (height * 0.42).toNumber();
        ringRadius = (size * 0.34).toNumber();
        ringWidth = (size * 0.02).toNumber();
        iconY = (height * 0.24).toNumber();
        timeY = (height * 0.42).toNumber();
        stageY = (height * 0.57).toNumber();
        var top = (height * 0.77).toNumber();
        var controlHeight = (height * 0.11).toNumber();
        start = new ControlBounds((width * 0.30).toNumber(), top,
            (width * 0.40).toNumber(), controlHeight);
        primary = new ControlBounds((width * 0.18).toNumber(), top,
            (width * 0.30).toNumber(), controlHeight);
        stop = new ControlBounds((width * 0.52).toNumber(), top,
            (width * 0.30).toNumber(), controlHeight);
    }
}
