import Toybox.Lang;
import Toybox.WatchUi;

// First screen: which part of the world to be quizzed on.
class RegionMenu extends WatchUi.Menu2 {

    function initialize() {
        Menu2.initialize({:title => WatchUi.loadResource(Rez.Strings.AppName) as String});
        for (var i = 0; i < Countries.REGION_NAMES.size(); i++) {
            var count = Session.regionSize(i);
            addItem(new WatchUi.MenuItem(Countries.REGION_NAMES[i], count.toString(), i, null));
        }
    }
}

class RegionMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var region = item.getId() as Number;
        WatchUi.pushView(new LengthMenu(region), new LengthMenuDelegate(region), WatchUi.SLIDE_LEFT);
    }
}

// Second screen: how many flags in this session.
class LengthMenu extends WatchUi.Menu2 {

    private const LENGTHS = [10, 20, 50] as Array<Number>;

    function initialize(region as Number) {
        Menu2.initialize({:title => WatchUi.loadResource(Rez.Strings.LengthTitle) as String});
        var total = Session.regionSize(region);
        for (var i = 0; i < LENGTHS.size(); i++) {
            if (LENGTHS[i] < total) {
                addItem(new WatchUi.MenuItem(LENGTHS[i].toString(), null, LENGTHS[i], null));
            }
        }
        var all = WatchUi.loadResource(Rez.Strings.All) as String;
        addItem(new WatchUi.MenuItem(all, total.toString(), total, null));
    }
}

class LengthMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _region as Number;

    function initialize(region as Number) {
        Menu2InputDelegate.initialize();
        _region = region;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var session = new Session(_region, item.getId() as Number);
        var view = new QuizView(session);
        // Replace this menu so that leaving the quiz lands on the region menu.
        WatchUi.switchToView(view, new QuizDelegate(session, view), WatchUi.SLIDE_LEFT);
    }
}
