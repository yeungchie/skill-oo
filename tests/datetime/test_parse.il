; ycDateTime parse suite: defaults, token fields, validation and error paths.

; --- 1. round-trips through format ---
let((p)
    p = ycDateTime::DateTime(1793715057)
    _Assert(ycDateTime::Parse(p->format("%F %T"))->epoch() == p->epoch()
        "parse: default pattern round-trip")
    _Assert(ycDateTime::Parse(p->format("%c"), "%c")->epoch() == p->epoch()
        "parse: %c round-trip")
    _Assert(ycDateTime::Parse(p->format("%s"), "%s")->epoch() == p->epoch()
        "parse: %s round-trip")
    _Assert(ycDateTime::Parse(p->format("%F %T")) == ycDateTime::Parse(p->format("%F %T"))
        "parse: same text yields the resident instance")
)

; --- 2. default pattern and date-only ---
let((tm n p q)
    tm = timeToTm(0)
    tm->tm_year = 126
    tm->tm_mon = 10
    tm->tm_mday = 3
    tm->tm_hour = 22
    tm->tm_min = 10
    tm->tm_sec = 57
    tm->tm_isdst = -1
    n = tmToTime(tm)
    p = ycDateTime::DateTime(n)
    _Assert(ycDateTime::Parse("2026-11-03 22:10:57")->epoch() == n
        "parse: default pattern reads date and time")
    q = ycDateTime::Parse(p->format("%F"), "%F")
    _Assert(q->format("%F") == p->format("%F")  "parse: date-only keeps the date")
    _Assert(q->hour() == 0 && q->minute() == 0 && q->second() == 0
        "parse: date-only starts at local midnight")
)

; --- 3. names are case-insensitive ---
let((tm n)
    tm = timeToTm(0)
    tm->tm_year = 126
    tm->tm_mon = 10
    tm->tm_mday = 3
    tm->tm_hour = 0
    tm->tm_min = 0
    tm->tm_sec = 0
    tm->tm_isdst = -1
    n = tmToTime(tm)
    _Assert(ycDateTime::Parse("03 november 2026", "%d %B %Y")->epoch() == n
        "parse: long month name is case-insensitive")
    _Assert(ycDateTime::Parse("03 nov 2026", "%d %b %Y")->epoch() == n
        "parse: short month name is case-insensitive")
    _Assert(ycDateTime::Parse("2026-11-03 Tue", "%F %a")->epoch() == n
        "parse: weekday name is accepted as a check")
)

; --- 3b. two-digit year, century and ISO weekday ---
_Assert(ycDateTime::Parse("26-11-03", "%y-%m-%d")->format("%F") == "2026-11-03"
    "parse: %y uses the 1969-2068 pivot")
_Assert(ycDateTime::Parse("20 26-11-03", "%C %y-%m-%d")->format("%F") == "2026-11-03"
    "parse: %C combines with %y")
_Assert(ycDateTime::Parse("2026-11-03 2", "%F %u")->format("%F") == "2026-11-03"
    "parse: %u is accepted as a weekday check")

; --- 4. 12-hour clock ---
let((tm n)
    tm = timeToTm(0)
    tm->tm_year = 126
    tm->tm_mon = 10
    tm->tm_mday = 3
    tm->tm_hour = 22
    tm->tm_min = 10
    tm->tm_sec = 57
    tm->tm_isdst = -1
    n = tmToTime(tm)
    _Assert(ycDateTime::Parse("2026-11-03 10:10:57 PM", "%F %I:%M:%S %p")->epoch() == n
        "parse: %I with PM")
    _Assert(ycDateTime::Parse("2026-11-03 10:10:57 pm", "%F %I:%M:%S %p")->epoch() == n
        "parse: %p is case-insensitive")
)
let((p)
    p = ycDateTime::Parse("2026-11-03 12:00:00 AM", "%F %I:%M:%S %p")
    _Assert(p->hour() == 0 && p->minute() == 0  "parse: 12 AM is midnight")
    p = ycDateTime::Parse("2026-11-03 12:00:00 PM", "%F %I:%M:%S %p")
    _Assert(p->hour() == 12  "parse: 12 PM is noon")
)

; --- 5. day-of-year ---
let((tm n)
    tm = timeToTm(0)
    tm->tm_year = 126
    tm->tm_mon = 10
    tm->tm_mday = 3
    tm->tm_hour = 0
    tm->tm_min = 0
    tm->tm_sec = 0
    tm->tm_isdst = -1
    n = tmToTime(tm)
    _Assert(ycDateTime::Parse("2026 307", "%Y %j")->epoch() == n
        "parse: %j supplies the date")
)
let((p)
    p = ycDateTime::Parse("2024 060", "%Y %j")
    _Assert(p->format("%F") == "2024-02-29"  "parse: %j handles leap day")
)

; --- 6. literal text and %% ---
_Assert(ycDateTime::Parse("at 2026-11-03", "at %F")->format("%F") == "2026-11-03"
    "parse: literal text matches exactly")
_Assert(ycDateTime::Parse("100% 2026-11-03", "100%% %F")->format("%F") == "2026-11-03"
    "parse: %% matches a literal percent")

; --- 7. epoch seconds ---
_Assert(ycDateTime::Parse("1793715057", "%s")->epoch() == 1793715057
    "parse: %s reads an epoch")
_Assert(ycDateTime::Parse("-1", "%s")->epoch() == -1  "parse: %s accepts negative epochs")

; --- 8. validation ---
_Assert(ycDateTime::Parse("2024-02-29", "%F")->format("%F") == "2024-02-29"
    "parse: leap day accepted")
_AssertError(lambda(() ycDateTime::Parse("2026-02-29", "%F") t)
    "parse: non-leap Feb 29 rejected")
_AssertError(lambda(() ycDateTime::Parse("2026-02-30", "%F") t)
    "parse: Feb 30 rejected")
_AssertError(lambda(() ycDateTime::Parse("2026-13-01", "%F") t)
    "parse: month 13 rejected")
_AssertError(lambda(() ycDateTime::Parse("2026-04-31", "%F") t)
    "parse: day beyond month length rejected")
_AssertError(lambda(() ycDateTime::Parse("2025 366", "%Y %j") t)
    "parse: day-of-year 366 in a common year rejected")
_AssertError(lambda(() ycDateTime::Parse("2026-11-03 Mon", "%F %a") t)
    "parse: inconsistent weekday rejected")
_Assert(ycDateTime::Parse("2026 001", "%Y %j")->format("%F") == "2026-01-01"
    "parse: day-of-year 1 is January 1")
_AssertError(lambda(() ycDateTime::Parse("2026-11-03 13:00 AM", "%F %H:%M %p") t)
    "parse: %p conflicting with %H rejected")
_AssertError(lambda(() ycDateTime::Parse("2026-11-03 25:00", "%F %H:%M") t)
    "parse: hour 25 rejected")
_AssertError(lambda(() ycDateTime::Parse("2026-11-03 22:61", "%F %H:%M") t)
    "parse: minute 61 rejected")

; --- 9. text/pattern mismatches ---
_AssertError(lambda(() ycDateTime::Parse("2026-11-03", "%F %T") t)
    "parse: default pattern requires a time part")
_AssertError(lambda(() ycDateTime::Parse("2026/11/03", "%F") t)
    "parse: literal separator mismatch rejected")
_AssertError(lambda(() ycDateTime::Parse("2026-11-03 extra", "%F") t)
    "parse: trailing text rejected")
_AssertError(lambda(() ycDateTime::Parse("2026-11-03", "%G-%V") t)
    "parse: week-number tokens unsupported")

; --- 10. argument errors ---
_AssertError(lambda(() ycDateTime::Parse(42) t)  "parse: non-string text rejected")
_AssertError(lambda(() ycDateTime::Parse("2026-11-03", 42) t)
    "parse: non-string pattern rejected")
_AssertError(lambda(() ycDateTime::Parse() t)  "parse: missing text rejected")
_AssertError(lambda(() ycDateTime::Parse("2026-11-03", "%F" "x") t)
    "parse: extra argument rejected")

_TestChildDone = t

; END
