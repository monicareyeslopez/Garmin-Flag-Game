import Toybox.Attention;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class QuizDelegate extends WatchUi.BehaviorDelegate {

    // A key event this recent is taken to belong to the onBack that follows it.
    private const BACK_KEY_WINDOW_MS = 1000;

    // True once this watch has been seen to report back-button key events.
    private static var _reportsBackKey as Boolean = false;

    private var _session as Session;
    private var _view as QuizView;
    private var _backKeyTime as Number?;

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
        if (dir == WatchUi.SWIPE_DOWN) {
            endSession();
        } else if (_session.revealed) {
            if (dir == WatchUi.SWIPE_RIGHT) {
                answer(true);
            } else if (dir == WatchUi.SWIPE_LEFT) {
                answer(false);
            }
        } else if (dir == WatchUi.SWIPE_UP) {
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

    // The key handlers only note that the physical back button was used;
    // onBack does the work. Which of them fires varies by device.
    function onKey(evt as WatchUi.KeyEvent) as Boolean {
        return noteBackKey(evt);
    }

    function onKeyPressed(evt as WatchUi.KeyEvent) as Boolean {
        return noteBackKey(evt);
    }

    function onKeyReleased(evt as WatchUi.KeyEvent) as Boolean {
        return noteBackKey(evt);
    }

    private function noteBackKey(evt as WatchUi.KeyEvent) as Boolean {
        if (evt.getKey() == WatchUi.KEY_ESC) {
            _backKeyTime = System.getTimer();
            _reportsBackKey = true;
        }
        return false;
    }

    // Reached by the back button and by a swipe starting at the left edge
    // (which never arrives as onSwipe). The button should end the session;
    // the edge swipe should count as a normal swipe right.
    function onBack() as Boolean {
        var keyTime = _backKeyTime;
        _backKeyTime = null;
        if (keyTime != null && System.getTimer() - keyTime < BACK_KEY_WINDOW_MS) {
            endSession();
        } else if (_session.revealed) {
            answer(true);
        } else if (!_reportsBackKey) {
            // No key events on this watch, so the two can't be told apart.
            // Swipes mean nothing before the reveal, so assume the button.
            endSession();
        }
        return true;
    }

    // Finish early: show the summary for what has been answered, or go
    // straight back to the menu if nothing has.
    private function endSession() as Void {
        if (_session.answered() == 0) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else {
            showSummary();
        }
    }

    private function showSummary() as Void {
        WatchUi.switchToView(new SummaryView(_session), new SummaryDelegate(_session), WatchUi.SLIDE_LEFT);
    }
}
