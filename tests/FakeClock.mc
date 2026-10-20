import Toybox.Lang;

(:test)
class FakeClock {
    private var _nowMs as Number;

    function initialize(nowMs as Number) {
        _nowMs = nowMs;
    }

    function nowMs() as Number {
        return _nowMs;
    }

    function advance(elapsedMs as Number) as Void {
        // Number addition wraps like the production millisecond clock.
        _nowMs += elapsedMs;
    }
}
