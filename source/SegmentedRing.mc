import Toybox.Lang;

// Presentation arithmetic only; progress comes from the authoritative timer.
class SegmentedRing {
    private var _stageCount as Number;
    private var _slotDegrees as Float;
    private var _gapDegrees as Float;

    function initialize(stageCount as Number) {
        _stageCount = stageCount;
        _slotDegrees = 360.0 / stageCount;
        _gapDegrees = _slotDegrees * 0.06;
    }

    function getFillFraction(progress as Float, index as Number) as Float {
        var fraction = _stageCount * progress - index;
        if (fraction <= 0.0) {
            return 0.0;
        }
        return fraction >= 1.0 ? 1.0 : fraction;
    }

    // Garmin angles decrease clockwise from 90 degrees at the top. Quantize the
    // track endpoints first so overlays use exactly the same drawable arc.
    function getStartAngle(index as Number) as Number {
        return (90.0 - index * _slotDegrees - _gapDegrees / 2).toNumber();
    }

    function getEndAngle(index as Number) as Number {
        return (90.0 - (index + 1) * _slotDegrees + _gapDegrees / 2).toNumber();
    }

    function getFilledSweep(progress as Float, index as Number) as Number {
        var sweep = getStartAngle(index) - getEndAngle(index);
        var fraction = getFillFraction(progress, index);
        if (fraction <= 0.0) {
            return 0;
        }
        if (fraction >= 1.0) {
            return sweep;
        }
        // Sub-degree fills stay empty: equal drawArc endpoints draw a circle.
        return (fraction * sweep).toNumber();
    }
}
