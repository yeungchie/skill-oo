useNamespace("ycDateTime")

; 英文月名与星期名（C locale 口径，用于 %b/%B/%a/%A）。
_MonthShort = list("Jan" "Feb" "Mar" "Apr" "May" "Jun"
    "Jul" "Aug" "Sep" "Oct" "Nov" "Dec")
_MonthLong = list("January" "February" "March" "April" "May" "June"
    "July" "August" "September" "October" "November" "December")
_DayShort = list("Sun" "Mon" "Tue" "Wed" "Thu" "Fri" "Sat")
_DayLong = list("Sunday" "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday")


procedure(_FormatToken(t_tok g_tm t_ctx "tgt")  ; -> str
    ; 把单个 % 令牌展开为对应的本地时间文本。
    ;
    ; **参数**
    ;   t_tok  (str) - 令牌字母（% 之后的那一个字符）
    ;   g_tm   (tm)  - timeToTm 返回的本地时间结构
    ;   t_ctx  (str) - 出错上下文名（拼入错误消息）
    ;
    ; **返回**
    ;   (str) - 展开结果；未知令牌时 error() 中断
    case(t_tok
        ("Y" sprintf(nil "%04d" g_tm->tm_year + 1900))
        ("y" sprintf(nil "%02d" remainder(g_tm->tm_year + 1900 100)))
        ("m" sprintf(nil "%02d" g_tm->tm_mon + 1))
        ("d" sprintf(nil "%02d" g_tm->tm_mday))
        ("H" sprintf(nil "%02d" g_tm->tm_hour))
        ("M" sprintf(nil "%02d" g_tm->tm_min))
        ("S" sprintf(nil "%02d" g_tm->tm_sec))
        ("j" sprintf(nil "%03d" g_tm->tm_yday + 1))
        ("w" sprintf(nil "%d" g_tm->tm_wday))
        ("a" nth(g_tm->tm_wday _DayShort))
        ("A" nth(g_tm->tm_wday _DayLong))
        ("b" nth(g_tm->tm_mon _MonthShort))
        ("B" nth(g_tm->tm_mon _MonthLong))
        ("p" if(g_tm->tm_hour < 12 "AM" "PM"))
        ("%" "%")
        (t error("%s: unknown format token %%%s" t_ctx t_tok))
    )
)


procedure(_FormatTime(n_time t_pattern t_ctx "xtt")  ; -> str
    ; 按模板把本地时间格式化为串（% 令牌见 _FormatToken）。
    ;
    ; **参数**
    ;   n_time     (int) - Unix 秒（1970-01-01 00:00:00 UTC 起算，可为负）
    ;   t_pattern  (str) - 模板；% 后跟一个令牌字母，%% 表示字面 %
    ;   t_ctx      (str) - 出错上下文名（拼入错误消息）
    ;
    ; **返回**
    ;   (str) - 格式化结果；模板末尾悬空 % 或未知令牌时 error() 中断
    let((tm l_out t_ch n_i n_len)
        tm = timeToTm(n_time)
        unless(tm
            error("%s: cannot convert time %A" t_ctx n_time)
        )
        l_out = nil
        n_len = length(t_pattern)
        n_i = 1
        while(n_i <= n_len
            t_ch = substring(t_pattern n_i 1)
            if(t_ch == "%"
            then
                n_i++
                when(n_len < n_i
                    error("%s: pattern ends with a dangling %%" t_ctx)
                )
                t_ch = _FormatToken(substring(t_pattern n_i 1) tm t_ctx)
            )
            l_out = tconc(l_out t_ch)
            n_i++
        )
        if(l_out
            buildString(car(l_out) "")
            ""
        )
    )
)


unuseNamespace("ycDateTime")

; END
