import Toybox.Application;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.WatchUi;

class FlagQuizApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        Math.srand(System.getTimer());
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [new RegionMenu(), new RegionMenuDelegate()];
    }
}
