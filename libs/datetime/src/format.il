useNamespace("ycDateTime")

; 英文月名与星期名（C locale 口径，用于 %a/%A/%b/%B/%h）。
_MonthShort = list("Jan" "Feb" "Mar" "Apr" "May" "Jun"
    "Jul" "Aug" "Sep" "Oct" "Nov" "Dec")
_MonthLong = list("January" "February" "March" "April" "May" "June"
    "July" "August" "September" "October" "November" "December")
_DayShort = list("Sun" "Mon" "Tue" "Wed" "Thu" "Fri" "Sat")
_DayLong = list("Sunday" "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday")


procedure(_IsLeapYear(n_year "x")  ; -> t | nil
    ; 判断公历闰年。
    ;
    ; **参数**
    ;   n_year  (int) - 实际年份（如 2026）
    ;
    ; **返回**
    ;   (t|nil) - 闰年为 t
    remainder(n_year 4) == 0 && (remainder(n_year 100) != 0 || remainder(n_year 400) == 0)
)


procedure(_Jan1Weekday(n_year "x")  ; -> int
    ; 返回某年 1 月 1 日的星期（本地时间）。
    ;
    ; **参数**
    ;   n_year  (int) - 实际年份
    ;
    ; **返回**
    ;   (int) - 0～6，0 为周日
    let((tm tm2)
        tm = timeToTm(0)
        tm->tm_year = n_year - 1900
        tm->tm_mon = 0
        tm->tm_mday = 1
        tm->tm_hour = 12
        tm->tm_min = 0
        tm->tm_sec = 0
        tm->tm_isdst = -1
        tm2 = timeToTm(tmToTime(tm))
        tm2->tm_wday
    )
)


procedure(_WeeksInYear(n_year "x")  ; -> int
    ; 返回某年包含的 ISO 周数（52 或 53）。
    ;
    ; **参数**
    ;   n_year  (int) - 实际年份
    ;
    ; **返回**
    ;   (int) - 52 或 53（1 月 1 日为周四，或闰年时为周三，则 53 周）
    let((jan1)
        jan1 = _Jan1Weekday(n_year)
        jan1 = if(jan1 == 0 7 jan1)
        if(jan1 == 4 || (jan1 == 3 && _IsLeapYear(n_year)) 53 52)
    )
)


procedure(_IsoWeek(g_tm "g")  ; -> list[int]
    ; 由本地时间结构计算 ISO 8601 周序号与所属年份。
    ;
    ; **参数**
    ;   g_tm  (tm) - timeToTm 返回的本地时间结构
    ;
    ; **返回**
    ;   (list[int]) - (周序号 1～53, ISO 年份)
    let((year yday0 isoWday week)
        year = g_tm->tm_year + 1900
        yday0 = g_tm->tm_yday
        isoWday = if(g_tm->tm_wday == 0 7 g_tm->tm_wday)
        week = (yday0 - isoWday + 11) / 7
        cond(
            (week < 1
                year--
                week = _WeeksInYear(year)
            )
            (_WeeksInYear(year) < week
                week = 1
                year++
            )
        )
        list(week year)
    )
)


procedure(_FormatToken(t_tok n_time n_nanos g_tm t_ctx "txxgt")  ; -> str
    ; 把单个 % 令牌展开为对应的本地时间文本。
    ;
    ; **参数**
    ;   t_tok    (str) - 令牌字母（% 之后的那一个字符）
    ;   n_time   (int) - Unix 秒（%s 使用）
    ;   n_nanos  (int) - 秒内纳秒（%N/%L 使用）
    ;   g_tm     (tm)  - timeToTm 返回的本地时间结构
    ;   t_ctx    (str) - 出错上下文名（拼入错误消息）
    ;
    ; **返回**
    ;   (str) - 展开结果；未知令牌时 error() 中断
    case(t_tok
        ("a" nth(g_tm->tm_wday _DayShort))
        ("A" nth(g_tm->tm_wday _DayLong))
        ("b" nth(g_tm->tm_mon _MonthShort))
        ("h" nth(g_tm->tm_mon _MonthShort))
        ("B" nth(g_tm->tm_mon _MonthLong))
        ("c" _FormatTime(n_time n_nanos "%a %b %e %H:%M:%S %Y" t_ctx))
        ("C" sprintf(nil "%02d" (g_tm->tm_year + 1900) / 100))
        ("d" sprintf(nil "%02d" g_tm->tm_mday))
        ("D" _FormatTime(n_time n_nanos "%m/%d/%y" t_ctx))
        ("e" sprintf(nil "%2d" g_tm->tm_mday))
        ("F" _FormatTime(n_time n_nanos "%Y-%m-%d" t_ctx))
        ("g" let((iso) iso = _IsoWeek(g_tm) sprintf(nil "%02d" remainder(nth(1 iso) 100))))
        ("G" sprintf(nil "%04d" nth(1 _IsoWeek(g_tm))))
        ("H" sprintf(nil "%02d" g_tm->tm_hour))
        ("I" let((h) h = remainder(g_tm->tm_hour 12) sprintf(nil "%02d" if(h == 0 12 h))))
        ("j" sprintf(nil "%03d" g_tm->tm_yday + 1))
        ("m" sprintf(nil "%02d" g_tm->tm_mon + 1))
        ("M" sprintf(nil "%02d" g_tm->tm_min))
        ("n" "\n")
        ("p" if(g_tm->tm_hour < 12 "AM" "PM"))
        ("P" if(g_tm->tm_hour < 12 "am" "pm"))
        ("r" _FormatTime(n_time n_nanos "%I:%M:%S %p" t_ctx))
        ("R" _FormatTime(n_time n_nanos "%H:%M" t_ctx))
        ("s" sprintf(nil "%d" n_time))
        ("S" sprintf(nil "%02d" g_tm->tm_sec))
        ("t" "\t")
        ("T" _FormatTime(n_time n_nanos "%H:%M:%S" t_ctx))
        ("u" sprintf(nil "%d" if(g_tm->tm_wday == 0 7 g_tm->tm_wday)))
        ("U" sprintf(nil "%02d" (g_tm->tm_yday + 7 - g_tm->tm_wday) / 7))
        ("V" sprintf(nil "%02d" car(_IsoWeek(g_tm))))
        ("w" sprintf(nil "%d" g_tm->tm_wday))
        ("W" sprintf(nil "%02d" (g_tm->tm_yday + 7 - remainder(g_tm->tm_wday + 6 7)) / 7))
        ("x" _FormatTime(n_time n_nanos "%m/%d/%y" t_ctx))
        ("X" _FormatTime(n_time n_nanos "%H:%M:%S" t_ctx))
        ("y" sprintf(nil "%02d" remainder(g_tm->tm_year + 1900 100)))
        ("Y" sprintf(nil "%04d" g_tm->tm_year + 1900))
        ("N" sprintf(nil "%09d" n_nanos))
        ("L" sprintf(nil "%03d" n_nanos / fix(1e6)))
        ("%" "%")
        (t error("%s: unknown format token %%%s" t_ctx t_tok))
    )
)


procedure(_FormatTime(n_time n_nanos t_pattern t_ctx "xxtt")  ; -> str
    ; 按模板把本地时间格式化为串（% 令牌见 _FormatToken）。
    ;
    ; **参数**
    ;   n_time     (int) - Unix 秒（1970-01-01 00:00:00 UTC 起算，可为负）
    ;   n_nanos    (int) - 秒内纳秒（0～999999999）
    ;   t_pattern  (str) - 模板；% 后跟一个令牌字母，%% 表示字面 %
    ;   t_ctx      (str) - 出错上下文名（拼入错误消息）
    ;
    ; **返回**
    ;   (str) - 格式化结果；模板末尾悬空 % 或未知令牌时 error() 中断
    let((tm out ch i len)
        tm = timeToTm(n_time)
        unless(tm
            error("%s: cannot convert time %A" t_ctx n_time)
        )
        out = nil
        len = length(t_pattern)
        i = 1
        while(i <= len
            ch = substring(t_pattern i 1)
            if(ch == "%"
            then
                i++
                when(len < i
                    error("%s: pattern ends with a dangling %%" t_ctx)
                )
                ch = _FormatToken(substring(t_pattern i 1) n_time n_nanos tm t_ctx)
            )
            out = tconc(out ch)
            i++
        )
        if(out
            buildString(car(out) "")
            ""
        )
    )
)


unuseNamespace("ycDateTime")

; END
