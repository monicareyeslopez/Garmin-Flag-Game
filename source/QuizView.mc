import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

class QuizView extends WatchUi.View {

    // Layout assumes flags fit the 260x174 BOX in tools/build_flags.py.
    private const FLAG_CENTER_Y = 160;
    private const NAME_CENTER_Y = 296;
    private const NAME_W = 240;
    private const NAME_H = 92;
    private const FLASH_MS = 300;

    private var _session as Session;
    private var _bitmap as WatchUi.BitmapResource?;
    private var _bitmapIndex as Number = -1;
    private var _flashColor as Graphics.ColorType?;
    private var _flashTimer as Timer.Timer;
    private var _hint as String;

    function initialize(session as Session) {
        View.initialize();
        _session = session;
        _flashTimer = new Timer.Timer();
        _hint = WatchUi.loadResource(Rez.Strings.TapToReveal) as String;
    }

    function onHide() as Void {
        _flashTimer.stop();
        _flashColor = null;
        // Free the flag while another view is on top.
        _bitmap = null;
        _bitmapIndex = -1;
    }

    // Briefly ring the screen in `color` to confirm which way a swipe was read.
    function flash(color as Graphics.ColorType) as Void {
        _flashColor = color;
        _flashTimer.stop();
        _flashTimer.start(method(:onFlashEnd), FLASH_MS, false);
        WatchUi.requestUpdate();
    }

    function onFlashEnd() as Void {
        _flashColor = null;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var cx = w / 2;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        if (_session.isDone()) {
            return;
        }

        drawStatus(dc, cx);
        drawFlag(dc, cx);

        if (_session.revealed) {
            drawName(dc, cx, Countries.NAMES[_session.current()]);
            drawSwipeHints(dc, w);
        } else {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, NAME_CENTER_Y, Graphics.FONT_XTINY, _hint,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        if (_flashColor != null) {
            dc.setColor(_flashColor, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(12);
            dc.drawCircle(cx, dc.getHeight() / 2, cx - 6);
            dc.setPenWidth(1);
        }
    }

    private function drawStatus(dc as Graphics.Dc, cx as Number) as Void {
        var text = (_session.answered() + 1) + "/" + _session.size();
        if (_session.answered() > 0) {
            text += "   " + _session.percent() + "%";
        }
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 44, Graphics.FONT_XTINY, text,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawFlag(dc as Graphics.Dc, cx as Number) as Void {
        var index = _session.current();
        if (_bitmapIndex != index) {
            _bitmap = null;
            _bitmap = WatchUi.loadResource(Countries.FLAGS[index]) as WatchUi.BitmapResource;
            _bitmapIndex = index;
        }
        var bmp = _bitmap as WatchUi.BitmapResource;
        var x = cx - bmp.getWidth() / 2;
        var y = FLAG_CENTER_Y - bmp.getHeight() / 2;
        dc.drawBitmap(x, y, bmp);
        // Outline so black or dark flag edges don't vanish into the background.
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(x - 1, y - 1, bmp.getWidth() + 2, bmp.getHeight() + 2);
    }

    private function drawName(dc as Graphics.Dc, cx as Number, name as String) as Void {
        var fonts = [Graphics.FONT_MEDIUM, Graphics.FONT_SMALL, Graphics.FONT_TINY, Graphics.FONT_XTINY];
        var font = fonts[fonts.size() - 1];
        var text = name;
        for (var i = 0; i < fonts.size(); i++) {
            var fitted = Graphics.fitTextToArea(name, fonts[i], NAME_W, NAME_H, false);
            if (fitted != null) {
                font = fonts[i];
                text = fitted;
                break;
            }
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, NAME_CENTER_Y, font, text,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Red cross on the left edge, green tick on the right, beside the flag.
    private function drawSwipeHints(dc as Graphics.Dc, w as Number) as Void {
        var y = FLAG_CENTER_Y;
        dc.setPenWidth(4);

        var lx = 34;
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(lx - 9, y - 9, lx + 9, y + 9);
        dc.drawLine(lx - 9, y + 9, lx + 9, y - 9);

        var rx = w - 34;
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(rx - 11, y, rx - 3, y + 9);
        dc.drawLine(rx - 3, y + 9, rx + 11, y - 9);

        dc.setPenWidth(1);
    }
}
