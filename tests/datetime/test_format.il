; ycDateTime format suite: tokens, defaults, literal text and error paths.

let((p tm l_mon l_day)
    p = ycDateTime::DateTime(1793715057)
    tm = timeToTm(1793715057)
    l_mon = list("Jan" "Feb" "Mar" "Apr" "May" "Jun"
        "Jul" "Aug" "Sep" "Oct" "Nov" "Dec")
    l_day = list("Sun" "Mon" "Tue" "Wed" "Thu" "Fri" "Sat")

    _Assert(p->format() == sprintf(nil "%04d-%02d-%02d %02d:%02d:%02d"
            tm->tm_year + 1900 tm->tm_mon + 1 tm->tm_mday
            tm->tm_hour tm->tm_min tm->tm_sec)
        "format: default is %Y-%m-%d %H:%M:%S")
    _Assert(p->format(?pattern "%Y") == sprintf(nil "%04d" tm->tm_year + 1900)
        "format: %Y")
    _Assert(p->format(?pattern "%y")
        == sprintf(nil "%02d" remainder(tm->tm_year + 1900 100))  "format: %y")
    _Assert(p->format(?pattern "%m") == sprintf(nil "%02d" tm->tm_mon + 1)
        "format: %m")
    _Assert(p->format(?pattern "%d") == sprintf(nil "%02d" tm->tm_mday)
        "format: %d")
    _Assert(p->format(?pattern "%H") == sprintf(nil "%02d" tm->tm_hour)
        "format: %H")
    _Assert(p->format(?pattern "%M") == sprintf(nil "%02d" tm->tm_min)
        "format: %M")
    _Assert(p->format(?pattern "%S") == sprintf(nil "%02d" tm->tm_sec)
        "format: %S")
    _Assert(p->format(?pattern "%j") == sprintf(nil "%03d" tm->tm_yday + 1)
        "format: %j")
    _Assert(p->format(?pattern "%w") == sprintf(nil "%d" tm->tm_wday)
        "format: %w")
    _Assert(p->format(?pattern "%a") == nth(tm->tm_wday l_day)  "format: %a")
    _Assert(p->format(?pattern "%b") == nth(tm->tm_mon l_mon)  "format: %b")
    _Assert(p->format(?pattern "%p") == if(tm->tm_hour < 12 "AM" "PM")
        "format: %p")
    _Assert(p->format(?pattern "100%% done") == "100% done"  "format: %% literal")
    _Assert(p->format(?pattern "") == ""  "format: empty pattern")
    _Assert(p->format(?pattern "no tokens") == "no tokens"
        "format: literal text passes through")
)

; full names use the same local-time month/weekday
let((p tm l_monL l_dayL)
    p = ycDateTime::DateTime(1793715057)
    tm = timeToTm(1793715057)
    l_monL = list("January" "February" "March" "April" "May" "June"
        "July" "August" "September" "October" "November" "December")
    l_dayL = list("Sunday" "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday")
    _Assert(p->format(?pattern "%B") == nth(tm->tm_mon l_monL)  "format: %B")
    _Assert(p->format(?pattern "%A") == nth(tm->tm_wday l_dayL)  "format: %A")
)

; negative epochs format through timeToTm
let((p tm)
    p = ycDateTime::DateTime(-1)
    tm = timeToTm(-1)
    _Assert(p->format(?pattern "%Y-%m-%d %H:%M:%S")
        == sprintf(nil "%04d-%02d-%02d %02d:%02d:%02d"
            tm->tm_year + 1900 tm->tm_mon + 1 tm->tm_mday
            tm->tm_hour tm->tm_min tm->tm_sec)
        "format: negative epoch")
)

; --- error paths ---
let((p)
    p = ycDateTime::DateTime(0)
    _AssertError(lambda(() p->format(?pattern "%Q") t)  "format: unknown token rejected")
    _AssertErrorMsg(lambda(() p->format(?pattern "%Q") t)
        "unknown format token"  "format: unknown token message")
    _AssertError(lambda(() p->format(?pattern "abc%") t)  "format: dangling % rejected")
    _AssertError(lambda(() p->format(?pattern 42) t)  "format: non-string pattern rejected")
)

; current time formats to the default shape
_Assert(pcreMatchp("^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$"
        ycDateTime::Now()->format())
    "format: Now() matches the default shape")

_TestChildDone = t

; END
