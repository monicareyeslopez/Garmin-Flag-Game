import Toybox.Lang;
import Toybox.Test;

// Run with: monkeyc -t ... then monkeydo <prg> vivoactive5 -t

(:test)
function testDataIsConsistent(logger as Logger) as Boolean {
    var total = Countries.NAMES.size();
    var starts = Countries.REGION_START;
    return total == 195
        && Countries.FLAGS.size() == total
        && starts.size() == Countries.REGION_NAMES.size()
        && starts[0] == 0
        && starts[starts.size() - 1] == total;
}

(:test)
function testDeckHasNoRepeatsAndStaysInRegion(logger as Logger) as Boolean {
    for (var region = 0; region < Countries.REGION_NAMES.size(); region++) {
        var n = Session.regionSize(region);
        var lo = region == 0 ? 0 : Countries.REGION_START[region - 1];
        var s = new Session(region, n);
        if (s.size() != n) {
            logger.error("region " + region + " size " + s.size());
            return false;
        }
        var seen = {} as Dictionary<Number, Boolean>;
        while (!s.isDone()) {
            var c = s.current();
            if (seen.hasKey(c) || c < lo || c >= lo + n) {
                logger.error("region " + region + " bad card " + c);
                return false;
            }
            seen.put(c, true);
            s.answer(true);
        }
    }
    return true;
}

(:test)
function testLengthIsCappedAtRegionSize(logger as Logger) as Boolean {
    var oceania = Countries.REGION_NAMES.size() - 1;
    return new Session(oceania, 50).size() == Session.regionSize(oceania)
        && new Session(0, 10).size() == 10;
}

(:test)
function testScoringAndUndo(logger as Logger) as Boolean {
    var s = new Session(0, 10);
    var first = s.current();
    s.revealed = true;
    s.answer(true);
    var second = s.current();
    s.answer(false);
    s.answer(true);
    if (s.revealed || s.answered() != 3 || s.correct() != 2 || s.percent() != 67) {
        return false;
    }
    var missed = s.missed();
    if (missed.size() != 1 || missed[0] != second) {
        return false;
    }
    // Undo all three; the first flag comes back revealed with a clean score.
    var ok = s.undo() && s.undo() && s.undo() && !s.undo();
    return ok && s.revealed && s.answered() == 0 && s.correct() == 0
        && s.percent() == 0 && s.current() == first;
}
