import Toybox.Lang;

(:test)
class FakeClock {
    private var _nowMs as Number;
    private var _sampleCount as Number = 0;

    function initialize(nowMs as Number) {
        _nowMs = nowMs;
    }

    function nowMs() as Number {
        _sampleCount += 1;
        return _nowMs;
    }

    function getSampleCount() as Number {
        return _sampleCount;
    }

    function advance(elapsedMs as Number) as Void {
        // Number addition wraps like the production millisecond clock.
        _nowMs += elapsedMs;
    }
}
