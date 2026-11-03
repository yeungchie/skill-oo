; ycDateTime precision suite: seconds + nanoseconds storage, format, parse and arithmetic.

; --- 1. constructor, accessors and residency ---
let((p)
    p = ycDateTime::DateTime(12 345678901)
    _Assert(p->epoch() == 12  "precision: epoch keeps whole seconds")
    _Assert(p->nanos() == 345678901  "precision: nanos accessor")
    _Assert(p->millis() == 345  "precision: millis truncates the fraction")
    _Assert(printself(p) == "ycDateTime::DateTime(12 345678901)"
        "precision: printself carries nanos")
    _Assert(evalstring(printself(p)) == p
        "precision: printself round-trips to the resident instance")
)
_Assert(printself(ycDateTime::DateTime(12)) == "ycDateTime::DateTime(12)"
    "precision: zero nanos keeps the one-argument form")
_Assert(ycDateTime::DateTime(1 2) == ycDateTime::DateTime(1 2)
    "precision: same second and nanos share one instance")
_Assert(ycDateTime::DateTime(1 2) != ycDateTime::DateTime(1 3)
    "precision: different nanos differ")
_Assert(ycDateTime::DateTime(1 2) != ycDateTime::DateTime(2 2)
    "precision: different seconds differ")

; --- 2. fractional constructor ---
_Assert(ycDateTime::DateTime(1.5)->epoch() == 1
        && ycDateTime::DateTime(1.5)->nanos() == 5e8
    "precision: flonum seconds split into seconds and nanos")
_Assert(ycDateTime::DateTime(-0.25)->epoch() == -1
        && ycDateTime::DateTime(-0.25)->nanos() == 7.5e8
    "precision: negative flonum uses floor seconds")

; --- 3. validation ---
_AssertError(lambda(() ycDateTime::DateTime(0 -1) t)  "precision: negative nanos rejected")
_AssertError(lambda(() ycDateTime::DateTime(0 fix(1e9)) t)
    "precision: nanos equal to one second rejected")
_AssertError(lambda(() ycDateTime::DateTime(0 fix(2e9)) t)
    "precision: nanos beyond one second rejected")
_AssertError(lambda(() ycDateTime::DateTime(1.5 1) t)
    "precision: nanos with a flonum time rejected")
_AssertError(lambda(() ycDateTime::DateTime("1") t)  "precision: string time rejected")
_AssertError(lambda(() ycDateTime::DateTime(1 1.5) t)  "precision: flonum nanos rejected")
_AssertError(lambda(() ycDateTime::DateTime(1e10) t)
    "precision: time above the 32-bit range rejected")
_AssertError(lambda(() ycDateTime::DateTime(-1e10) t)
    "precision: time below the 32-bit range rejected")
_Assert(ycDateTime::DateTime(0.9999999999)->epoch() == 1
        && ycDateTime::DateTime(0.9999999999)->nanos() == 0
    "precision: flonum rounding up carries into the next second")

; --- 4. format with sub-second tokens ---
let((tm n p)
    tm = timeToTm(0)
    tm->tm_year = 126
    tm->tm_mon = 10
    tm->tm_mday = 3
    tm->tm_hour = 22
    tm->tm_min = 10
    tm->tm_sec = 57
    tm->tm_isdst = -1
    n = tmToTime(tm)
    p = ycDateTime::DateTime(n 345678901)
    _Assert(p->format("%F %T") == "2026-11-03 22:10:57"
        "precision: default pattern omits the fraction")
    _Assert(p->format("%N") == "345678901"  "precision: %N prints nine digits")
    _Assert(p->format("%L") == "345"  "precision: %L prints milliseconds")
    _Assert(p->format("%F %T.%N") == "2026-11-03 22:10:57.345678901"
        "precision: full fractional format")
    _Assert(p->format("%T.%L") == "22:10:57.345"  "precision: millisecond format")
)

; --- 5. parse with sub-second tokens ---
let((p)
    p = ycDateTime::Parse("2026-11-03 22:10:57.345678901", "%F %T.%N")
    _Assert(p->epoch() == ycDateTime::Parse("2026-11-03 22:10:57", "%F %T")->epoch()
        "precision: %N keeps the same whole second")
    _Assert(p->nanos() == 345678901  "precision: %N reads nine digits")
    _Assert(p->format("%F %T.%N") == "2026-11-03 22:10:57.345678901"
        "precision: %N round-trip")
)
let((p)
    p = ycDateTime::Parse("2026-11-03 22:10:57.4", "%F %T.%N")
    _Assert(p->nanos() == 4e8  "precision: short %N is right-padded")
    p = ycDateTime::Parse("2026-11-03 22:10:57.123", "%F %T.%L")
    _Assert(p->nanos() == 1.23e8  "precision: %L reads milliseconds")
    p = ycDateTime::Parse("2026-11-03 22:10:57.5", "%F %T.%L")
    _Assert(p->nanos() == 5e8  "precision: short %L is right-padded")
)
_AssertError(lambda(() ycDateTime::Parse("2026-11-03 22:10:57.12", "%F %T.%N%L") t)
    "precision: %N and %L cannot be combined")

; --- 6. add with sub-second offsets ---
let((p)
    p = ycDateTime::DateTime(1 999999999)
    _Assert(p->add(?nanos 1)->epoch() == 2  "precision: nanos carry into seconds")
    _Assert(p->add(?nanos 1)->nanos() == 0  "precision: carried nanos reset to zero")
)
let((p)
    p = ycDateTime::DateTime(1 0)
    _Assert(p->add(?nanos -1)->epoch() == 0  "precision: nanos borrow from seconds")
    _Assert(p->add(?nanos -1)->nanos() == 999999999  "precision: borrowed nanos wrap")
    _Assert(p->add(?millis 1500)->epoch() == 2  "precision: millis carry into seconds")
    _Assert(p->add(?millis 1500)->nanos() == 5e8  "precision: millis remainder")
    _Assert(p->add() == p  "precision: zero delta returns the same instance")
)
let((p)
    p = ycDateTime::DateTime(1000)
    _Assert(p->add(?millis 2148)->epoch() == 1002
        "precision: millis past two seconds keeps whole seconds")
    _Assert(p->add(?millis 2148)->nanos() == 1.48e8
        "precision: millis past two seconds keeps the fraction")
    _Assert(p->add(?millis 3000)->epoch() == 1003  "precision: three seconds of millis")
    _Assert(p->add(?millis 10000)->epoch() == 1010  "precision: ten seconds of millis")
    _Assert(p->add(?millis -3000)->epoch() == 997  "precision: negative millis delta")
    _Assert(p->add(?millis 1500 ?seconds 2)->epoch() == 1003
        "precision: millis combines with other keys")
    _Assert(p->add(?millis 1500 ?seconds 2)->nanos() == 5e8
        "precision: combined millis fraction")
)
_AssertError(lambda(() ycDateTime::DateTime(0)->add(?days 30000) t)
    "precision: day delta beyond the 32-bit range rejected")
_AssertError(lambda(() ycDateTime::DateTime(fix(2.147483647e9))->add(?seconds 1) t)
    "precision: result beyond the 32-bit range rejected")
_AssertError(lambda(() ycDateTime::DateTime(fix(-2.147483648e9))->add(?nanos -1) t)
    "precision: nanos borrow below the 32-bit range rejected")
_AssertError(lambda(() ycDateTime::DateTime(fix(-2.147483648e9))->add(?millis -1) t)
    "precision: millis borrow below the 32-bit range rejected")
_Assert(ycDateTime::DateTime(fix(2.147483647e9))->add(?nanos 1)->nanos() == 1
    "precision: nanos still fit inside the last representable second")
_Assert(ycDateTime::DateTime(0)->add(?seconds fix(-2.147483648e9))->epoch()
        == fix(-2.147483648e9)
    "precision: the smallest 32-bit second is a valid delta")
_Assert(ycDateTime::DateTime(0)->add(?hours 596523 ?minutes -1)->epoch() == 2147482740
    "precision: cancelling deltas are summed in floating point")
_AssertError(lambda(() ycDateTime::DateTime(1e400 - 1e400) t)
    "precision: NaN time rejected")

; --- 7. diff and compare honour nanoseconds ---
_Assert(ycDateTime::DateTime(2 fix(5e8))->diff(ycDateTime::DateTime(1 0)) == 1.5
    "precision: diff includes the fractional part")
_Assert(ycDateTime::DateTime(1 0)->diff(ycDateTime::DateTime(1 fix(2.5e8))) == -0.25
    "precision: negative fractional diff")
_Assert(ycDateTime::DateTime(1 1)->compare(ycDateTime::DateTime(1 0)) == 1
    "precision: compare uses nanos when seconds tie")
_Assert(ycDateTime::DateTime(1 0)->compare(ycDateTime::DateTime(1 1)) == -1
    "precision: compare reports earlier nanos")
_Assert(ycDateTime::DateTime(1 1)->compare(ycDateTime::DateTime(1 1)) == 0
    "precision: compare equal instants")
_Assert(ycDateTime::DateTime(fix(2.147483647e9))->diff(ycDateTime::DateTime(fix(-2.147483648e9)))
        > 4.2e9
    "precision: diff spans the full 32-bit range")
_Assert(ycDateTime::DateTime(1 999999999)->millis() == 999
    "precision: millis truncates 999999999 to 999")

_TestChildDone = t

; END
