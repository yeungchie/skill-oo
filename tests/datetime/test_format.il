; ycDateTime format suite: defaults, tokens, composites, literals and error paths.

let((p tm l_mon l_day n_h12)
    p = ycDateTime::DateTime(1793715057)
    tm = timeToTm(1793715057)
    l_mon = list("Jan" "Feb" "Mar" "Apr" "May" "Jun"
        "Jul" "Aug" "Sep" "Oct" "Nov" "Dec")
    l_day = list("Sun" "Mon" "Tue" "Wed" "Thu" "Fri" "Sat")
    n_h12 = remainder(tm->tm_hour 12)
    when(n_h12 == 0
        n_h12 = 12
    )

    _Assert(p->format() == sprintf(nil "%04d-%02d-%02d %02d:%02d:%02d"
            tm->tm_year + 1900 tm->tm_mon + 1 tm->tm_mday
            tm->tm_hour tm->tm_min tm->tm_sec)
        "format: default is %F %T")
    _Assert(p->format("%Y") == sprintf(nil "%04d" tm->tm_year + 1900)  "format: %Y")
    _Assert(p->format("%y") == sprintf(nil "%02d" remainder(tm->tm_year + 1900 100))
        "format: %y")
    _Assert(p->format("%C") == sprintf(nil "%02d" (tm->tm_year + 1900) / 100)
        "format: %C")
    _Assert(p->format("%m") == sprintf(nil "%02d" tm->tm_mon + 1)  "format: %m")
    _Assert(p->format("%d") == sprintf(nil "%02d" tm->tm_mday)  "format: %d")
    _Assert(p->format("%e") == sprintf(nil "%2d" tm->tm_mday)  "format: %e")
    _Assert(p->format("%H") == sprintf(nil "%02d" tm->tm_hour)  "format: %H")
    _Assert(p->format("%I") == sprintf(nil "%02d" n_h12)  "format: %I")
    _Assert(p->format("%M") == sprintf(nil "%02d" tm->tm_min)  "format: %M")
    _Assert(p->format("%S") == sprintf(nil "%02d" tm->tm_sec)  "format: %S")
    _Assert(p->format("%j") == sprintf(nil "%03d" tm->tm_yday + 1)  "format: %j")
    _Assert(p->format("%w") == sprintf(nil "%d" tm->tm_wday)  "format: %w")
    _Assert(p->format("%u")
        == sprintf(nil "%d" if(tm->tm_wday == 0 7 tm->tm_wday))  "format: %u")
    _Assert(p->format("%a") == nth(tm->tm_wday l_day)  "format: %a")
    _Assert(p->format("%b") == nth(tm->tm_mon l_mon)  "format: %b")
    _Assert(p->format("%h") == nth(tm->tm_mon l_mon)  "format: %h")
    _Assert(p->format("%p") == if(tm->tm_hour < 12 "AM" "PM")  "format: %p")
    _Assert(p->format("%P") == if(tm->tm_hour < 12 "am" "pm")  "format: %P")
    _Assert(p->format("%s") == sprintf(nil "%d" 1793715057)  "format: %s")
    _Assert(p->format("%%") == "%"  "format: %% literal")
    _Assert(p->format("%n") == "\n"  "format: %n newline")
    _Assert(p->format("%t") == "\t"  "format: %t tab")
    _Assert(p->format("") == ""  "format: empty pattern")
    _Assert(p->format("no tokens") == "no tokens"  "format: literal text passes through")

    ; composites expand to the same text as their component tokens
    _Assert(p->format("%F") == sprintf(nil "%04d-%02d-%02d"
            tm->tm_year + 1900 tm->tm_mon + 1 tm->tm_mday)  "format: %F")
    _Assert(p->format("%T") == sprintf(nil "%02d:%02d:%02d"
            tm->tm_hour tm->tm_min tm->tm_sec)  "format: %T")
    _Assert(p->format("%R") == sprintf(nil "%02d:%02d" tm->tm_hour tm->tm_min)
        "format: %R")
    _Assert(p->format("%D") == sprintf(nil "%02d/%02d/%02d"
            tm->tm_mon + 1 tm->tm_mday remainder(tm->tm_year + 1900 100))  "format: %D")
    _Assert(p->format("%x") == sprintf(nil "%02d/%02d/%02d"
            tm->tm_mon + 1 tm->tm_mday remainder(tm->tm_year + 1900 100))  "format: %x")
    _Assert(p->format("%X") == sprintf(nil "%02d:%02d:%02d"
            tm->tm_hour tm->tm_min tm->tm_sec)  "format: %X")
    _Assert(p->format("%r") == sprintf(nil "%02d:%02d:%02d %s"
            n_h12 tm->tm_min tm->tm_sec if(tm->tm_hour < 12 "AM" "PM"))
        "format: %r")
    _Assert(p->format("%c") == sprintf(nil "%s %s %2d %02d:%02d:%02d %04d"
            nth(tm->tm_wday l_day) nth(tm->tm_mon l_mon) tm->tm_mday
            tm->tm_hour tm->tm_min tm->tm_sec tm->tm_year + 1900)
        "format: %c")
)

; full names use the same local-time month/weekday
let((p tm l_monL l_dayL)
    p = ycDateTime::DateTime(1793715057)
    tm = timeToTm(1793715057)
    l_monL = list("January" "February" "March" "April" "May" "June"
        "July" "August" "September" "October" "November" "December")
    l_dayL = list("Sunday" "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday")
    _Assert(p->format("%B") == nth(tm->tm_mon l_monL)  "format: %B")
    _Assert(p->format("%A") == nth(tm->tm_wday l_dayL)  "format: %A")
)

; week numbers: build the local date from tm fields so the check is timezone-neutral
let((tm p)
    tm = timeToTm(0)
    tm->tm_year = 126
    tm->tm_mon = 10
    tm->tm_mday = 3
    tm->tm_hour = 12
    tm->tm_min = 0
    tm->tm_sec = 0
    tm->tm_isdst = -1
    p = ycDateTime::DateTime(tmToTime(tm))
    _Assert(p->format("%V") == "45"  "format: %V of 2026-11-03")
    _Assert(p->format("%G") == "2026"  "format: %G of 2026-11-03")
    _Assert(p->format("%g") == "26"  "format: %g of 2026-11-03")
    _Assert(p->format("%U") == "44"  "format: %U of 2026-11-03")
    _Assert(p->format("%W") == "44"  "format: %W of 2026-11-03")
)
let((tm p)
    tm = timeToTm(0)
    tm->tm_year = 125
    tm->tm_mon = 11
    tm->tm_mday = 31
    tm->tm_hour = 12
    tm->tm_min = 0
    tm->tm_sec = 0
    tm->tm_isdst = -1
    p = ycDateTime::DateTime(tmToTime(tm))
    _Assert(p->format("%V") == "01"  "format: %V of 2025-12-31 belongs to 2026")
    _Assert(p->format("%G") == "2026"  "format: %G of 2025-12-31")
    _Assert(p->format("%U") == "52"  "format: %U of 2025-12-31")
    _Assert(p->format("%W") == "52"  "format: %W of 2025-12-31")
)
let((tm p)
    tm = timeToTm(0)
    tm->tm_year = 124
    tm->tm_mon = 1
    tm->tm_mday = 29
    tm->tm_hour = 12
    tm->tm_min = 0
    tm->tm_sec = 0
    tm->tm_isdst = -1
    p = ycDateTime::DateTime(tmToTime(tm))
    _Assert(p->format("%V") == "09"  "format: %V of 2024-02-29")
    _Assert(p->format("%G") == "2024"  "format: %G of 2024-02-29")
    _Assert(p->format("%U") == "08"  "format: %U of 2024-02-29")
    _Assert(p->format("%W") == "09"  "format: %W of 2024-02-29")
)

; negative epochs format through timeToTm
let((p tm)
    p = ycDateTime::DateTime(-1)
    tm = timeToTm(-1)
    _Assert(p->format("%F %T") == sprintf(nil "%04d-%02d-%02d %02d:%02d:%02d"
            tm->tm_year + 1900 tm->tm_mon + 1 tm->tm_mday
            tm->tm_hour tm->tm_min tm->tm_sec)
        "format: negative epoch")
    _Assert(p->format("%s") == "-1"  "format: %s of a negative epoch")
)

; week numbers at year boundaries
let((p)
    p = ycDateTime::Parse("2024-01-01 12:00:00", "%F %T")
    _Assert(p->format("%U %W %V %G") == "00 01 01 2024"
        "format: Monday 2024-01-01 starts the first ISO week")
)
let((p)
    p = ycDateTime::Parse("2027-01-01 12:00:00", "%F %T")
    _Assert(p->format("%U %W %V %G") == "00 00 53 2026"
        "format: 2027-01-01 belongs to ISO week 53 of 2026")
)
let((p)
    p = ycDateTime::Parse("2021-01-01 12:00:00", "%F %T")
    _Assert(p->format("%V %G") == "53 2020"
        "format: 2021-01-01 belongs to ISO week 53 of 2020")
)

; --- error paths ---
let((p)
    p = ycDateTime::DateTime(0)
    _AssertError(lambda(() p->format("%Q") t)  "format: unknown token rejected")
    _AssertErrorMsg(lambda(() p->format("%Q") t)
        "unknown format token"  "format: unknown token message")
    _AssertError(lambda(() p->format("%Z") t)  "format: timezone token unsupported")
    _AssertError(lambda(() p->format("abc%") t)  "format: dangling % rejected")
    _AssertError(lambda(() p->format(42) t)  "format: non-string pattern rejected")
    _AssertError(lambda(() p->format("%Y" "x") t)  "format: extra argument rejected")
)

; current time formats to the default shape
_Assert(pcreMatchp("^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$"
        ycDateTime::Current()->format())
    "format: Current() matches the default shape")

_TestChildDone = t

; END
