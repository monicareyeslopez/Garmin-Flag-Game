import Toybox.Attention;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class QuizDelegate extends WatchUi.BehaviorDelegate {

    private var _session as Session;
    private var _view as QuizView;

    function initialize(session as Session, view as QuizView) {
        BehaviorDelegate.initialize();
        _session = session;
        _view = view;
    }

    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        return reveal();
    }

    // Top-right button does the same as a tap.
    function onSelect() as Boolean {
        return reveal();
    }

    private function reveal() as Boolean {
        if (!_session.revealed) {
            _session.revealed = true;
            WatchUi.requestUpdate();
        }
        return true;
    }

    // Always returns true: an unhandled swipe right would be turned into
    // "back" by the system and end the session.
    function onSwipe(evt as WatchUi.SwipeEvent) as Boolean {
        var dir = evt.getDirection();
        if (_session.revealed) {
            if (dir == WatchUi.SWIPE_RIGHT) {
                answer(true);
            } else if (dir == WatchUi.SWIPE_LEFT) {
                answer(false);
            }
        } else if (dir == WatchUi.SWIPE_DOWN) {
            if (_session.undo()) {
                WatchUi.requestUpdate();
            }
        }
        return true;
    }

    private function answer(wasCorrect as Boolean) as Void {
        _session.answer(wasCorrect);
        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(50, wasCorrect ? 60 : 150)]);
        }
        if (_session.isDone()) {
            showSummary();
        } else {
            _view.flash(wasCorrect ? Graphics.COLOR_GREEN : Graphics.COLOR_RED);
        }
    }

    // Back button: finish early with whatever has been answered so far.
    function onBack() as Boolean {
        if (_session.answered() == 0) {
            return false;
        }
        showSummary();
        return true;
    }

    private function showSummary() as Void {
        WatchUi.switchToView(new SummaryView(_session), new SummaryDelegate(_session), WatchUi.SLIDE_LEFT);
    }
}
