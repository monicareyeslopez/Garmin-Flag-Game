import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class SummaryView extends WatchUi.View {

    private var _session as Session;

    function initialize(session as Session) {
        View.initialize();
        _session = session;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        var answered = _session.answered();
        var missed = answered - _session.correct();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 70, Graphics.FONT_XTINY, Countries.REGION_NAMES[_session.region], center);

        dc.setColor(missed == 0 ? Graphics.COLOR_GREEN : Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 35, Graphics.FONT_NUMBER_MEDIUM, _session.percent().toString(), center);

        var line = "% " + (WatchUi.loadResource(Rez.Strings.Correct) as String);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 30, Graphics.FONT_SMALL, line, center);

        var tally = _session.correct() + " " + (WatchUi.loadResource(Rez.Strings.Of) as String) + " " + answered;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 72, Graphics.FONT_TINY, tally, center);

        var footer = missed == 0 ? Rez.Strings.Perfect : Rez.Strings.TapForMissed;
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 122, Graphics.FONT_XTINY, WatchUi.loadResource(footer) as String, center);
    }
}

class SummaryDelegate extends WatchUi.BehaviorDelegate {

    private var _session as Session;

    function initialize(session as Session) {
        BehaviorDelegate.initialize();
        _session = session;
    }

    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        return showMissed();
    }

    function onSelect() as Boolean {
        return showMissed();
    }

    // Swipe right falls through to the default "back", which returns to the region menu.
    private function showMissed() as Boolean {
        var missed = _session.missed();
        if (missed.size() == 0) {
            return true;
        }
        var title = (WatchUi.loadResource(Rez.Strings.MissedTitle) as String) + " (" + missed.size() + ")";
        var menu = new WatchUi.Menu2({:title => title});
        for (var i = 0; i < missed.size(); i++) {
            menu.addItem(new WatchUi.MenuItem(Countries.NAMES[missed[i]], null, i, null));
        }
        WatchUi.pushView(menu, new WatchUi.Menu2InputDelegate(), WatchUi.SLIDE_LEFT);
        return true;
    }
}
