; ycDateTime core suite: construction, residency, fields, arithmetic, comparison.

; --- 1. construction and residency ---
let((p)
    p = ycDateTime::Current()
    _Assert(0 < p->epoch()  "Current: epoch is positive")
    _Assert(printself(p) == lsprintf("ycDateTime::DateTime(%d)" p->epoch())
        "Current: printself is the constructor form")
)
let((p)
    p = ycDateTime::DateTime(0)
    _Assert(p->epoch() == 0  "DateTime: epoch round-trip")
)
_Assert(ycDateTime::DateTime(1234) == ycDateTime::DateTime(1234)
    "DateTime: same epoch shares one instance")
_Assert(ycDateTime::DateTime(1234) != ycDateTime::DateTime(1235)
    "DateTime: different epochs are different instances")
let((p)
    p = ycDateTime::DateTime(1234)
    _Assert(printself(p) == "ycDateTime::DateTime(1234)"
        "DateTime: printself literal form")
    _Assert(evalstring(printself(p)) == p
        "DateTime: printself round-trips to the resident instance")
)

; --- 2. local-time fields agree with timeToTm ---
let((p tm)
    p = ycDateTime::DateTime(1793715057)
    tm = timeToTm(1793715057)
    _Assert(p->year() == tm->tm_year + 1900  "year: matches timeToTm")
    _Assert(p->month() == tm->tm_mon + 1  "month: 1-based")
    _Assert(p->day() == tm->tm_mday  "day: matches timeToTm")
    _Assert(p->hour() == tm->tm_hour  "hour: matches timeToTm")
    _Assert(p->minute() == tm->tm_min  "minute: matches timeToTm")
    _Assert(p->second() == tm->tm_sec  "second: matches timeToTm")
    _Assert(p->weekday() == tm->tm_wday  "weekday: matches timeToTm")
    _Assert(p->yday() == tm->tm_yday + 1  "yday: 1-based")
)

; --- 3. add: fixed offsets, immutable receiver ---
let((p)
    p = ycDateTime::DateTime(1000)
    _Assert(p->add(?seconds 5)->epoch() == 1005  "add: seconds")
    _Assert(p->add(?minutes 1)->epoch() == 1060  "add: minutes")
    _Assert(p->add(?hours 1)->epoch() == 4600  "add: hours")
    _Assert(p->add(?days 1)->epoch() == 87400  "add: days")
    _Assert(p->add(?seconds -5)->epoch() == 995  "add: negative delta")
    _Assert(p->add() == p  "add: zero delta returns the same instance")
    _Assert(p->epoch() == 1000  "add: receiver unchanged")
)

; --- 4. diff and compare ---
let((a b)
    a = ycDateTime::DateTime(1000)
    b = ycDateTime::DateTime(1300)
    _Assert(b->diff(a) == 300  "diff: later minus earlier")
    _Assert(a->diff(b) == -300  "diff: earlier minus later")
    _Assert(a->diff(1000) == 0  "diff: accepts an integer time")
    _Assert(a->compare(b) == -1  "compare: earlier is -1")
    _Assert(b->compare(a) == 1  "compare: later is 1")
    _Assert(a->compare(1000) == 0  "compare: accepts an integer time")
    _Assert(a->compare(a) == 0  "compare: same instant is 0")
)

; --- 5. error paths ---
_AssertError(lambda(() ycDateTime::DateTime(1.5) t)  "DateTime: float rejected")
_AssertError(lambda(() ycDateTime::DateTime("1") t)  "DateTime: string rejected")
_AssertError(lambda(() ycDateTime::DateTime() t)  "DateTime: missing time rejected")
_AssertError(lambda(() ycDateTime::DateTime(1 2) t)  "DateTime: extra argument rejected")
_AssertError(lambda(() ycDateTime::DateTime(0)->diff("x") t)  "diff: non-time rejected")
_AssertError(lambda(() ycDateTime::DateTime(0)->compare(nil) t)  "compare: nil rejected")
_AssertError(lambda(() ycDateTime::DateTime(0)->add(?seconds 1.5) t)
    "add: float delta rejected")

_TestChildDone = t

; END
