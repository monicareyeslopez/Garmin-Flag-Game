import Toybox.Lang;
import Toybox.Math;

// One run through a shuffled set of flags. Nothing here outlives the app.
class Session {

    private var _deck as Array<Number>;
    private var _results as Array<Boolean>;
    private var _correct as Number = 0;

    var region as Number;
    var revealed as Boolean = false;

    // region: index into Countries.REGION_NAMES (0 = whole world).
    static function regionSize(region as Number) as Number {
        if (region == 0) {
            return Countries.NAMES.size();
        }
        return Countries.REGION_START[region] - Countries.REGION_START[region - 1];
    }

    function initialize(region as Number, length as Number) {
        self.region = region;
        var start = region == 0 ? 0 : Countries.REGION_START[region - 1];
        var n = regionSize(region);
        if (length > n) {
            length = n;
        }

        var pool = new Array<Number>[n];
        for (var i = 0; i < n; i++) {
            pool[i] = start + i;
        }
        // Partial Fisher-Yates: only the first `length` slots need shuffling.
        for (var i = 0; i < length; i++) {
            var j = i + (Math.rand() & 0x7FFFFFFF) % (n - i);
            var tmp = pool[i];
            pool[i] = pool[j];
            pool[j] = tmp;
        }
        _deck = pool.slice(0, length);
        _results = [] as Array<Boolean>;
    }

    function size() as Number {
        return _deck.size();
    }

    function answered() as Number {
        return _results.size();
    }

    function correct() as Number {
        return _correct;
    }

    function isDone() as Boolean {
        return _results.size() >= _deck.size();
    }

    // Index into Countries.NAMES / FLAGS of the flag on screen.
    function current() as Number {
        return _deck[_results.size()];
    }

    function answer(wasCorrect as Boolean) as Void {
        _results.add(wasCorrect);
        if (wasCorrect) {
            _correct++;
        }
        revealed = false;
    }

    // Take back the last answer and show that flag again, already revealed.
    function undo() as Boolean {
        var n = _results.size();
        if (n == 0) {
            return false;
        }
        if (_results[n - 1]) {
            _correct--;
        }
        _results = _results.slice(0, n - 1);
        revealed = true;
        return true;
    }

    function percent() as Number {
        var n = _results.size();
        return n == 0 ? 0 : Math.round(100.0 * _correct / n).toNumber();
    }

    function missed() as Array<Number> {
        var out = [] as Array<Number>;
        for (var i = 0; i < _results.size(); i++) {
            if (!_results[i]) {
                out.add(_deck[i]);
            }
        }
        return out;
    }
}
