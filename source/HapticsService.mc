import Toybox.Attention;
import Toybox.Lang;
import Toybox.System;

typedef HapticsSettings as interface {
    var vibrateOn as Boolean;
};

class HapticsService {
    function initialize() {
    }

    function intervalCue() as Void {
        playCue(false);
    }

    function completionCue() as Void {
        playCue(true);
    }

    private function playCue(completion as Boolean) as Void {
        // Keep capability/settings reads and profile creation inside the failure
        // boundary so a device refusal cannot interrupt completion and exit.
        try {
            if (canVibrate()) {
                if (completion) {
                    // Submit the whole pattern without separate pulse callbacks.
                    sendVibration([
                        new Attention.VibeProfile(75, 170),
                        new Attention.VibeProfile(0, 120),
                        new Attention.VibeProfile(75, 170),
                        new Attention.VibeProfile(0, 120),
                        new Attention.VibeProfile(75, 170)
                    ]);
                } else {
                    sendVibration([new Attention.VibeProfile(100, 250)]);
                }
            }
        } catch (exception instanceof Lang.Exception) {
            System.println("Haptics unavailable: " + exception.getErrorMessage());
        }
    }

    protected function canVibrate() as Boolean {
        if (!(Attention has :vibrate) || !(Attention has :VibeProfile)) {
            return false;
        }
        var settings = getDeviceSettings();
        if (!settings.vibrateOn) {
            return false;
        }
        // DND is optional in the structural type. After the capability guard,
        // use its Garmin-defined Boolean type for Strict checking.
        return !(settings has :doNotDisturb) || !(settings.doNotDisturb as Boolean);
    }

    // Replace only platform access in tests so the settings decision is exercised.
    protected function getDeviceSettings() as HapticsSettings {
        return System.getDeviceSettings();
    }

    protected function sendVibration(profiles as Array<Attention.VibeProfile>) as Void {
        Attention.vibrate(profiles);
    }
}
