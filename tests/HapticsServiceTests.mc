import Toybox.Attention;
import Toybox.Lang;
import Toybox.Test;

(:test)
class TestVibrationSettings {
    var vibrateOn as Boolean = true;

    function initialize() {
    }
}

(:test)
class TestDndSettings extends TestVibrationSettings {
    var doNotDisturb as Boolean = false;

    function initialize() {
        TestVibrationSettings.initialize();
    }
}

(:test)
class TestHapticsService extends HapticsService {
    var settings as HapticsSettings;
    var failAvailability as Boolean = false;
    var failVibration as Boolean = false;
    var checks as Number = 0;
    var requests as Number = 0;

    function initialize() {
        HapticsService.initialize();
        settings = new TestDndSettings();
    }

    protected function getDeviceSettings() as HapticsSettings {
        checks += 1;
        if (failAvailability) {
            throw new Lang.OperationNotAllowedException("Test availability failure");
        }
        return settings;
    }

    protected function sendVibration(profiles as Array<Attention.VibeProfile>) as Void {
        requests += 1;
        if (failVibration) {
            throw new Lang.OperationNotAllowedException("Test vibration failure");
        }
    }
}

(:test)
function hapticsCueRequests(logger as Test.Logger) as Boolean {
    var haptics = new TestHapticsService();
    haptics.intervalCue();
    Test.assertEqual(haptics.requests, 1);
    haptics.completionCue();
    Test.assertEqual(haptics.requests, 2);
    Test.assertEqual(haptics.checks, 2);
    return true;
}

(:test)
function hapticsVibrationDisabledAndReenabled(logger as Test.Logger) as Boolean {
    var haptics = new TestHapticsService();
    var settings = new TestDndSettings();
    haptics.settings = settings;
    settings.vibrateOn = false;
    haptics.intervalCue();
    haptics.completionCue();
    Test.assertEqual(haptics.requests, 0);
    // Availability is checked afresh; a previous restriction is not permanent.
    settings.vibrateOn = true;
    haptics.intervalCue();
    Test.assertEqual(haptics.requests, 1);
    Test.assertEqual(haptics.checks, 3);
    return true;
}

(:test)
function hapticsDndSuppressionAndReenabled(logger as Test.Logger) as Boolean {
    var haptics = new TestHapticsService();
    var settings = new TestDndSettings();
    haptics.settings = settings;
    settings.doNotDisturb = true;
    haptics.intervalCue();
    haptics.completionCue();
    Test.assertEqual(haptics.requests, 0);
    settings.doNotDisturb = false;
    haptics.completionCue();
    Test.assertEqual(haptics.requests, 1);
    Test.assertEqual(haptics.checks, 3);
    return true;
}

(:test)
function hapticsSettingsWithoutDnd(logger as Test.Logger) as Boolean {
    var haptics = new TestHapticsService();
    var settings = new TestVibrationSettings();
    haptics.settings = settings;
    haptics.intervalCue();
    haptics.completionCue();
    Test.assertEqual(haptics.requests, 2);
    settings.vibrateOn = false;
    haptics.intervalCue();
    haptics.completionCue();
    Test.assertEqual(haptics.requests, 2);
    Test.assertEqual(haptics.checks, 4);
    return true;
}

(:test)
function hapticsVibrationFailureIsNonfatal(logger as Test.Logger) as Boolean {
    var haptics = new TestHapticsService();
    haptics.failVibration = true;
    haptics.intervalCue();
    haptics.completionCue();
    Test.assertEqual(haptics.requests, 2);
    haptics.failVibration = false;
    haptics.completionCue();
    Test.assertEqual(haptics.requests, 3);
    return true;
}

(:test)
function hapticsAvailabilityFailureIsNonfatal(logger as Test.Logger) as Boolean {
    var haptics = new TestHapticsService();
    haptics.failAvailability = true;
    haptics.intervalCue();
    haptics.completionCue();
    Test.assertEqual(haptics.requests, 0);
    Test.assertEqual(haptics.checks, 2);
    haptics.failAvailability = false;
    haptics.completionCue();
    Test.assertEqual(haptics.requests, 1);
    Test.assertEqual(haptics.checks, 3);
    return true;
}

(:test)
class SimulatorHapticsService extends HapticsService {
    var completedRequests as Number = 0;

    function initialize() {
        HapticsService.initialize();
    }

    function isAvailable() as Boolean {
        return canVibrate();
    }

    protected function sendVibration(profiles as Array<Attention.VibeProfile>) as Void {
        HapticsService.sendVibration(profiles);
        completedRequests += 1;
    }
}

(:test)
function hapticsSimulatorCalls(logger as Test.Logger) as Boolean {
    var haptics = new SimulatorHapticsService();
    // A swallowed platform exception must not turn this smoke check into a pass.
    Test.assert(haptics.isAvailable());
    haptics.intervalCue();
    Test.assertEqual(haptics.completedRequests, 1);
    haptics.completionCue();
    Test.assertEqual(haptics.completedRequests, 2);
    return true;
}
