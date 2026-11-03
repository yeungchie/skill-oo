useNamespace("ycDateTime")

; 十进制位权（0～8 次），用于把不定长小数位换算为纳秒/毫秒。
_Pow10 = list(1 10 100 1000 10000 100000 fix(1e6) fix(1e7) fix(1e8))


procedure(_ParseDigits(t_text n_pos n_min n_max "txnn")  ; -> (int . int) | nil
    ; 从给定位置读定长范围内的十进制数字。
    ;
    ; **参数**
    ;   t_text  (str) - 待解析文本
    ;   n_pos   (int) - 起始位置（1-based）
    ;   n_min   (int) - 最少位数
    ;   n_max   (int) - 最多位数
    ;
    ; **返回**
    ;   ((int . int)|nil) - (数值 . 下一位)；位数不足或位置越界时 nil
    let((n_len n_i n_val)
        n_len = length(t_text)
        n_i = n_pos
        n_val = 0
        while(n_i <= n_len && (n_i - n_pos) < n_max
                && pcreMatchp("^[0-9]$" substring(t_text n_i 1))
            n_val = n_val * 10 + atoi(substring(t_text n_i 1))
            n_i++
        )
        if(n_min <= (n_i - n_pos)
            list(n_val n_i)
            nil
        )
    )
)


procedure(_ParseSigned(t_text n_pos "tx")  ; -> (int . int) | nil
    ; 从给定位置读带可选负号的十进制整数。
    ;
    ; **参数**
    ;   t_text  (str) - 待解析文本
    ;   n_pos   (int) - 起始位置（1-based）
    ;
    ; **返回**
    ;   ((int . int)|nil) - (数值 . 下一位)；无数字时 nil
    let((n_sign l_res)
        n_sign = 1
        when(n_pos <= length(t_text) && substring(t_text n_pos 1) == "-"
            n_sign = -1
            n_pos++
        )
        l_res = _ParseDigits(t_text n_pos 1 12)
        when(l_res
            list(n_sign * car(l_res) cadr(l_res))
        )
    )
)


procedure(_ParseName(t_text n_pos l_names "txl")  ; -> (int . int) | nil
    ; 从给定位置匹配名称表（大小写不敏感）。
    ;
    ; **参数**
    ;   t_text   (str)  - 待解析文本
    ;   n_pos    (int)  - 起始位置（1-based）
    ;   l_names  (list) - 名称表（元素为 str）
    ;
    ; **返回**
    ;   ((int . int)|nil) - (名称下标 0-based . 下一位)；无匹配时 nil
    let((n_len n_i l_found t_name t_seg)
        n_len = length(t_text)
        n_i = 0
        while(n_i < length(l_names) && l_found == nil
            t_name = nth(n_i l_names)
            when(n_pos + length(t_name) - 1 <= n_len
                t_seg = substring(t_text n_pos length(t_name))
                when(lowerCase(t_seg) == lowerCase(t_name)
                    l_found = list(n_i n_pos + length(t_name))
                )
            )
            n_i++
        )
        l_found
    )
)


procedure(_MonthLength(n_year n_month "xx")  ; -> int
    ; 返回某年某月的天数。
    ;
    ; **参数**
    ;   n_year   (int) - 实际年份
    ;   n_month  (int) - 月份（1～12）
    ;
    ; **返回**
    ;   (int) - 当月天数
    case(n_month
        (2 if(_IsLeapYear(n_year) 29 28))
        ((4 6 9 11) 30)
        (t 31)
    )
)


procedure(_MonthDayFromYday(n_year n_yday "xx")  ; -> (int . int)
    ; 把年内的序日换算为（月 . 日）。
    ;
    ; **参数**
    ;   n_year  (int) - 实际年份
    ;   n_yday  (int) - 序日（1～366）
    ;
    ; **返回**
    ;   ((int . int)) - (月份 1～12 . 日 1～31)
    let((n_month n_left)
        n_month = 1
        n_left = n_yday
        while(_MonthLength(n_year n_month) < n_left
            n_left = n_left - _MonthLength(n_year n_month)
            n_month++
        )
        list(n_month n_left)
    )
)


procedure(_ExpandPattern(t_pattern "t")  ; -> str
    ; 把复合令牌展开为基础令牌（%F/%T/%R/%D/%r/%c/%x/%X）。
    ;
    ; **参数**
    ;   t_pattern  (str) - 用户模板
    ;
    ; **返回**
    ;   (str) - 只含基础令牌的模板；末尾悬空 % 时 error() 中断
    let((l_out n_i n_len t_ch t_tok t_rep)
        n_len = length(t_pattern)
        n_i = 1
        while(n_i <= n_len
            t_ch = substring(t_pattern n_i 1)
            if(t_ch == "%"
            then
                when(n_len < n_i + 1
                    error("ycDateTime::Parse: pattern ends with a dangling %%")
                )
                t_tok = substring(t_pattern n_i + 1 1)
                t_rep = case(t_tok
                    ("F" "%Y-%m-%d")
                    ("T" "%H:%M:%S")
                    ("R" "%H:%M")
                    ("D" "%m/%d/%y")
                    ("r" "%I:%M:%S %p")
                    ("c" "%a %b %e %H:%M:%S %Y")
                    ("x" "%m/%d/%y")
                    ("X" "%H:%M:%S")
                    (t nil)
                )
                if(t_rep
                    l_out = tconc(l_out t_rep)
                    l_out = tconc(l_out strcat("%" t_tok))
                )
                n_i = n_i + 2
            else
                l_out = tconc(l_out t_ch)
                n_i++
            )
        )
        if(l_out
            buildString(car(l_out) "")
            ""
        )
    )
)


procedure(_ParseTime(t_text t_pattern t_ctx "ttt")  ; -> list[int]
    ; 按模板把文本解析为 Unix 秒。
    ;
    ; **参数**
    ;   t_text     (str) - 待解析文本
    ;   t_pattern  (str) - 模板（支持 format 的基础令牌，复合令牌自动展开）
    ;   t_ctx      (str) - 出错上下文名（拼入错误消息）
    ;
    ; **返回**
    ;   (list[int]) - (Unix 秒, 纳秒)；文本与模板不匹配、字段越界、
    ;                 日期不存在（如 2 月 30 日）、DST 空洞或明示的星期/序日不一致时 error() 中断
    let((t_pat n_plen n_pp n_tlen n_pos t_ch t_tok l_r
         n_year n_short n_century n_month n_mday
         n_hour n_hour12 n_minute n_second n_ampm
         n_wday n_wdayISO n_yday n_epoch n_nanos n_millis tm l_md n_digits)
        t_pat = _ExpandPattern(t_pattern)
        n_plen = length(t_pat)
        n_tlen = length(t_text)
        n_pp = 1
        n_pos = 1
        while(n_pp <= n_plen
            t_ch = substring(t_pat n_pp 1)
            if(t_ch == "%"
            then
                n_pp++
                when(n_plen < n_pp
                    error("%s: pattern ends with a dangling %%" t_ctx)
                )
                t_tok = substring(t_pat n_pp 1)
                n_pp++
                case(t_tok
                    ("Y"
                        l_r = _ParseDigits(t_text n_pos 1 4)
                        unless(l_r
                            error("%s: expected a year at position %d" t_ctx n_pos)
                        )
                        when(n_year != nil
                            error("%s: duplicate %%Y" t_ctx)
                        )
                        n_year = car(l_r)
                        n_pos = cadr(l_r)
                    )
                    ("y"
                        l_r = _ParseDigits(t_text n_pos 1 2)
                        unless(l_r
                            error("%s: expected a two-digit year at position %d" t_ctx n_pos)
                        )
                        when(n_short != nil
                            error("%s: duplicate %%y" t_ctx)
                        )
                        n_short = car(l_r)
                        n_pos = cadr(l_r)
                    )
                    ("C"
                        l_r = _ParseDigits(t_text n_pos 1 2)
                        unless(l_r
                            error("%s: expected a century at position %d" t_ctx n_pos)
                        )
                        when(n_century != nil
                            error("%s: duplicate %%C" t_ctx)
                        )
                        n_century = car(l_r)
                        n_pos = cadr(l_r)
                    )
                    ("m"
                        l_r = _ParseDigits(t_text n_pos 1 2)
                        unless(l_r
                            error("%s: expected a month at position %d" t_ctx n_pos)
                        )
                        when(n_month != nil
                            error("%s: duplicate month field" t_ctx)
                        )
                        n_month = car(l_r)
                        n_pos = cadr(l_r)
                    )
                    ("d"
                        l_r = _ParseDigits(t_text n_pos 1 2)
                        unless(l_r
                            error("%s: expected a day at position %d" t_ctx n_pos)
                        )
                        when(n_mday != nil
                            error("%s: duplicate day field" t_ctx)
                        )
                        n_mday = car(l_r)
                        n_pos = cadr(l_r)
                    )
                    ("e"
                        when(n_pos <= n_tlen && substring(t_text n_pos 1) == " "
                            n_pos++
                        )
                        l_r = _ParseDigits(t_text n_pos 1 2)
                        unless(l_r
                            error("%s: expected a day at position %d" t_ctx n_pos)
                        )
                        when(n_mday != nil
                            error("%s: duplicate day field" t_ctx)
                        )
                        n_mday = car(l_r)
                        n_pos = cadr(l_r)
                    )
                    ("H"
                        l_r = _ParseDigits(t_text n_pos 1 2)
                        unless(l_r
                            error("%s: expected an hour at position %d" t_ctx n_pos)
                        )
                        when(n_hour != nil || n_hour12 != nil
                            error("%s: duplicate hour field" t_ctx)
                        )
                        n_hour = car(l_r)
                        n_pos = cadr(l_r)
                    )
                    ("I"
                        l_r = _ParseDigits(t_text n_pos 1 2)
                        unless(l_r
                            error("%s: expected an hour at position %d" t_ctx n_pos)
                        )
                        when(n_hour != nil || n_hour12 != nil
                            error("%s: duplicate hour field" t_ctx)
                        )
                        n_hour12 = car(l_r)
                        n_pos = cadr(l_r)
                    )
                    ("M"
                        l_r = _ParseDigits(t_text n_pos 1 2)
                        unless(l_r
                            error("%s: expected a minute at position %d" t_ctx n_pos)
                        )
                        when(n_minute != nil
                            error("%s: duplicate minute field" t_ctx)
                        )
                        n_minute = car(l_r)
                        n_pos = cadr(l_r)
                    )
                    ("S"
                        l_r = _ParseDigits(t_text n_pos 1 2)
                        unless(l_r
                            error("%s: expected a second at position %d" t_ctx n_pos)
                        )
                        when(n_second != nil
                            error("%s: duplicate second field" t_ctx)
                        )
                        n_second = car(l_r)
                        n_pos = cadr(l_r)
                    )
                    ("j"
                        l_r = _ParseDigits(t_text n_pos 1 3)
                        unless(l_r
                            error("%s: expected a day-of-year at position %d" t_ctx n_pos)
                        )
                        when(n_yday != nil
                            error("%s: duplicate %%j" t_ctx)
                        )
                        n_yday = car(l_r)
                        n_pos = cadr(l_r)
                    )
                    ("w"
                        l_r = _ParseDigits(t_text n_pos 1 1)
                        unless(l_r
                            error("%s: expected a weekday at position %d" t_ctx n_pos)
                        )
                        when(n_wday != nil || n_wdayISO != nil
                            error("%s: duplicate weekday field" t_ctx)
                        )
                        n_wday = car(l_r)
                        n_pos = cadr(l_r)
                    )
                    ("u"
                        l_r = _ParseDigits(t_text n_pos 1 1)
                        unless(l_r
                            error("%s: expected a weekday at position %d" t_ctx n_pos)
                        )
                        when(n_wday != nil || n_wdayISO != nil
                            error("%s: duplicate weekday field" t_ctx)
                        )
                        n_wdayISO = car(l_r)
                        n_pos = cadr(l_r)
                    )
                    ("p"
                        l_r = _ParseName(t_text n_pos list("AM" "PM"))
                        unless(l_r
                            error("%s: expected AM or PM at position %d" t_ctx n_pos)
                        )
                        when(n_ampm != nil
                            error("%s: duplicate %%p" t_ctx)
                        )
                        n_ampm = car(l_r)
                        n_pos = cadr(l_r)
                    )
                    ("P"
                        l_r = _ParseName(t_text n_pos list("AM" "PM"))
                        unless(l_r
                            error("%s: expected AM or PM at position %d" t_ctx n_pos)
                        )
                        when(n_ampm != nil
                            error("%s: duplicate %%p" t_ctx)
                        )
                        n_ampm = car(l_r)
                        n_pos = cadr(l_r)
                    )
                    ("a"
                        l_r = _ParseName(t_text n_pos _DayShort)
                        unless(l_r
                            error("%s: expected a weekday name at position %d" t_ctx n_pos)
                        )
                        when(n_wday != nil || n_wdayISO != nil
                            error("%s: duplicate weekday field" t_ctx)
                        )
                        n_wday = car(l_r)
                        n_pos = cadr(l_r)
                    )
                    ("A"
                        l_r = _ParseName(t_text n_pos _DayLong)
                        unless(l_r
                            error("%s: expected a weekday name at position %d" t_ctx n_pos)
                        )
                        when(n_wday != nil || n_wdayISO != nil
                            error("%s: duplicate weekday field" t_ctx)
                        )
                        n_wday = car(l_r)
                        n_pos = cadr(l_r)
                    )
                    ("b"
                        l_r = _ParseName(t_text n_pos _MonthShort)
                        unless(l_r
                            error("%s: expected a month name at position %d" t_ctx n_pos)
                        )
                        when(n_month != nil
                            error("%s: duplicate month field" t_ctx)
                        )
                        n_month = car(l_r) + 1
                        n_pos = cadr(l_r)
                    )
                    ("h"
                        l_r = _ParseName(t_text n_pos _MonthShort)
                        unless(l_r
                            error("%s: expected a month name at position %d" t_ctx n_pos)
                        )
                        when(n_month != nil
                            error("%s: duplicate month field" t_ctx)
                        )
                        n_month = car(l_r) + 1
                        n_pos = cadr(l_r)
                    )
                    ("B"
                        l_r = _ParseName(t_text n_pos _MonthLong)
                        unless(l_r
                            error("%s: expected a month name at position %d" t_ctx n_pos)
                        )
                        when(n_month != nil
                            error("%s: duplicate month field" t_ctx)
                        )
                        n_month = car(l_r) + 1
                        n_pos = cadr(l_r)
                    )
                    ("s"
                        l_r = _ParseSigned(t_text n_pos)
                        unless(l_r
                            error("%s: expected an integer time at position %d" t_ctx n_pos)
                        )
                        when(n_epoch != nil
                            error("%s: duplicate %%s" t_ctx)
                        )
                        n_epoch = car(l_r)
                        n_pos = cadr(l_r)
                    )
                    ("N"
                        l_r = _ParseDigits(t_text n_pos 1 9)
                        unless(l_r
                            error("%s: expected fractional seconds at position %d" t_ctx n_pos)
                        )
                        when(n_nanos != nil
                            error("%s: duplicate fractional seconds" t_ctx)
                        )
                        n_digits = cadr(l_r) - n_pos
                        n_nanos = car(l_r) * nth(9 - n_digits _Pow10)
                        n_pos = cadr(l_r)
                    )
                    ("L"
                        l_r = _ParseDigits(t_text n_pos 1 3)
                        unless(l_r
                            error("%s: expected milliseconds at position %d" t_ctx n_pos)
                        )
                        when(n_nanos != nil || n_millis != nil
                            error("%s: duplicate fractional seconds" t_ctx)
                        )
                        n_digits = cadr(l_r) - n_pos
                        n_millis = car(l_r) * nth(3 - n_digits _Pow10)
                        n_pos = cadr(l_r)
                    )
                    ("n"
                        unless(substring(t_text n_pos 1) == "\n"
                            error("%s: expected a newline at position %d" t_ctx n_pos)
                        )
                        n_pos++
                    )
                    ("t"
                        unless(substring(t_text n_pos 1) == "\t"
                            error("%s: expected a tab at position %d" t_ctx n_pos)
                        )
                        n_pos++
                    )
                    ("%"
                        unless(substring(t_text n_pos 1) == "%"
                            error("%s: expected %% at position %d" t_ctx n_pos)
                        )
                        n_pos++
                    )
                    (t
                        error("%s: cannot parse token %%%s" t_ctx t_tok)
                    )
                )
            else
                unless(substring(t_text n_pos 1) == t_ch
                    error("%s: expected %A at position %d" t_ctx t_ch n_pos)
                )
                n_pos++
                n_pp++
            )
        )
        unless(n_tlen + 1 == n_pos
            error("%s: unexpected trailing text %A" t_ctx substring(t_text n_pos))
        )

        if(n_epoch != nil
        then
            when(n_year != nil || n_short != nil || n_century != nil || n_month != nil
                    || n_mday != nil || n_hour != nil || n_hour12 != nil
                    || n_minute != nil || n_second != nil || n_ampm != nil
                    || n_wday != nil || n_wdayISO != nil || n_yday != nil
                error("%s: %%s cannot be combined with date/time tokens" t_ctx)
            )
            list(n_epoch 0)
        else
            ; --- year ---
            when(n_century != nil && n_short == nil
                error("%s: %%C requires %%y" t_ctx)
            )
            when(n_year != nil && (n_short != nil || n_century != nil)
                error("%s: %%Y cannot be combined with %%y or %%C" t_ctx)
            )
            when(n_year == nil && n_short != nil
                when(n_century == nil
                    n_century = if(n_short < 69 20 19)
                )
                n_year = n_century * 100 + n_short
            )
            unless(n_year != nil
                error("%s: pattern has no year field" t_ctx)
            )

            ; --- month and day (or day-of-year) ---
            when(n_yday != nil && (n_month == nil || n_mday == nil)
                when(n_month != nil || n_mday != nil
                    error("%s: %%j cannot be combined with a partial month/day" t_ctx)
                )
                when(n_yday < 1 || 366 < n_yday
                    error("%s: day-of-year %d is out of range" t_ctx n_yday)
                )
                when(n_yday == 366 && !_IsLeapYear(n_year)
                    error("%s: day-of-year 366 is invalid for %04d" t_ctx n_year)
                )
                l_md = _MonthDayFromYday(n_year n_yday)
                n_month = car(l_md)
                n_mday = cadr(l_md)
            )
            unless(n_month != nil && n_mday != nil
                error("%s: pattern needs month and day, or %%j" t_ctx)
            )
            when(n_month < 1 || 12 < n_month
                error("%s: month %d is out of range" t_ctx n_month)
            )
            when(n_mday < 1 || _MonthLength(n_year n_month) < n_mday
                error("%s: day %d is invalid for %04d-%02d" t_ctx n_mday n_year n_month)
            )

            ; --- time ---
            when(n_hour12 != nil
                when(n_hour12 < 1 || 12 < n_hour12
                    error("%s: hour %d is out of range for %%I" t_ctx n_hour12)
                )
                n_hour = remainder(n_hour12 12) + if(n_ampm == 1 12 0)
            )
            when(n_hour == nil
                n_hour = 0
            )
            when(n_hour < 0 || 23 < n_hour
                error("%s: hour %d is out of range" t_ctx n_hour)
            )
            when(n_ampm != nil && n_hour12 == nil
                when((n_hour < 12 && n_ampm == 1) || (12 <= n_hour && n_ampm == 0)
                    error("%s: %%p conflicts with %%H" t_ctx)
                )
            )
            when(n_minute == nil
                n_minute = 0
            )
            when(n_minute < 0 || 59 < n_minute
                error("%s: minute %d is out of range" t_ctx n_minute)
            )
            when(n_second == nil
                n_second = 0
            )
            when(n_second < 0 || 59 < n_second
                error("%s: second %d is out of range" t_ctx n_second)
            )
            when(n_wdayISO != nil
                when(n_wdayISO < 1 || 7 < n_wdayISO
                    error("%s: ISO weekday %d is out of range" t_ctx n_wdayISO)
                )
                n_wday = remainder(n_wdayISO 7)
            )

            ; --- build and verify ---
            tm = timeToTm(0)
            tm->tm_year = n_year - 1900
            tm->tm_mon = n_month - 1
            tm->tm_mday = n_mday
            tm->tm_hour = n_hour
            tm->tm_min = n_minute
            tm->tm_sec = n_second
            tm->tm_isdst = -1
            n_epoch = tmToTime(tm)
            unless(fixp(n_epoch)
                error("%s: cannot convert %A to a time value" t_ctx t_text)
            )
            tm = timeToTm(n_epoch)
            unless(tm
                    && tm->tm_year + 1900 == n_year && tm->tm_mon + 1 == n_month
                    && tm->tm_mday == n_mday && tm->tm_hour == n_hour
                    && tm->tm_min == n_minute && tm->tm_sec == n_second
                error("%s: invalid local time %A" t_ctx t_text)
            )
            when(n_wday != nil && tm->tm_wday != n_wday
                error("%s: weekday does not match %A" t_ctx t_text)
            )
            when(n_yday != nil && tm->tm_yday + 1 != n_yday
                error("%s: day-of-year does not match %A" t_ctx t_text)
            )
            when(n_nanos != nil && n_millis != nil
                error("%s: %%N cannot be combined with %%L" t_ctx)
            )
            when(n_nanos == nil && n_millis != nil
                n_nanos = n_millis * fix(1e6)
            )
            when(n_nanos == nil
                n_nanos = 0
            )
            list(n_epoch n_nanos)
        )
    )
)


procedure(Parse(t_text \@optional t_pattern("%F %T") "tt")  ; -> DateTime
    ; 按模板把文本解析为时间对象。
    ;
    ; **参数**
    ;   t_text     (str) - 待解析文本
    ;   t_pattern  (str) - 模板；默认 "%F %T"，可省略
    ;
    ; **返回**
    ;   (DateTime) - 解析结果（驻留实例）；文本与模板不匹配、字段越界、
    ;                 日期不存在或明示的星期/序日不一致时 error() 中断
    let((l_res)
        l_res = _ParseTime(t_text t_pattern "ycDateTime::Parse")
        _MkDateTime(car(l_res) cadr(l_res))
    )
)


unuseNamespace("ycDateTime")

; END
