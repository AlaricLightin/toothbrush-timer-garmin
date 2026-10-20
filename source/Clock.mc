import Toybox.Lang;
import Toybox.System;

typedef Clock as interface {
    function nowMs() as Number;
};

class SystemClock {
    function initialize() {
    }

    // Preserve the raw rolling Number; the session model calculates durations.
    function nowMs() as Number {
        return System.getTimer();
    }
}
