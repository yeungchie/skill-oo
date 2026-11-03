useNamespace("ycDateTime")

; 十进制位权（0～8 次），用于把不定长小数位换算为纳秒/毫秒。
_Pow10 = list(1 10 100 1000 10000 100000 fix(1e6) fix(1e7) fix(1e8))


procedure(_ParseDigits(t_text n_pos n_min n_max "txnn")  ; -> (int, int) | nil
    ; 从给定位置读定长范围内的十进制数字。
    ;
    ; **参数**
    ;   t_text  (str) - 待解析文本
    ;   n_pos   (int) - 起始位置（1-based）
    ;   n_min   (int) - 最少位数
    ;   n_max   (int) - 最多位数
    ;
    ; **返回**
    ;   ((int, int)|nil) - (数值, 下一位)；位数不足或位置越界时 nil
    let((len i val)
        len = length(t_text)
        i = n_pos
        val = 0
        while(i <= len && (i - n_pos) < n_max
                && pcreMatchp("^[0-9]$" substring(t_text i 1))
            val = val * 10 + atoi(substring(t_text i 1))
            i++
        )
        if(n_min <= (i - n_pos)
            list(val i)
            nil
        )
    )
)


procedure(_ParseSigned(t_text n_pos "tx")  ; -> (int, int) | nil
    ; 从给定位置读带可选负号的十进制整数。
    ;
    ; **参数**
    ;   t_text  (str) - 待解析文本
    ;   n_pos   (int) - 起始位置（1-based）
    ;
    ; **返回**
    ;   ((int, int)|nil) - (数值, 下一位)；无数字或超出 32 位秒值范围时 nil
    let((sign start res val)
        sign = 1
        when(n_pos <= length(t_text) && substring(t_text n_pos 1) == "-"
            sign = -1
            n_pos++
        )
        start = n_pos
        ; 最多 10 位；用浮点复核数值，避免整数累加在越界后静默回绕
        res = _ParseDigits(t_text n_pos 1 10)
        when(res
            val = atof(substring(t_text start cadr(res) - start))
            when(val <= if(sign < 0 2.147483648e9 2.147483647e9)
                list(fix2(sign * val) cadr(res))
            )
        )
    )
)


procedure(_ParseName(t_text n_pos l_names "txl")  ; -> (int, int) | nil
    ; 从给定位置匹配名称表（大小写不敏感）。
    ;
    ; **参数**
    ;   t_text   (str)  - 待解析文本
    ;   n_pos    (int)  - 起始位置（1-based）
    ;   l_names  (list) - 名称表（元素为 str）
    ;
    ; **返回**
    ;   ((int, int)|nil) - (名称下标 0-based, 下一位)；无匹配时 nil
    let((len i found name seg)
        len = length(t_text)
        i = 0
        while(i < length(l_names) && found == nil
            name = nth(i l_names)
            when(n_pos + length(name) - 1 <= len
                seg = substring(t_text n_pos length(name))
                when(lowerCase(seg) == lowerCase(name)
                    found = list(i n_pos + length(name))
                )
            )
            i++
        )
        found
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


procedure(_MonthDayFromYday(n_year n_yday "xx")  ; -> (int, int)
    ; 把年内的序日换算为（月 . 日）。
    ;
    ; **参数**
    ;   n_year  (int) - 实际年份
    ;   n_yday  (int) - 序日（1～366）
    ;
    ; **返回**
    ;   (int, int) - (月份 1～12, 日 1～31)
    let((month left)
        month = 1
        left = n_yday
        while(_MonthLength(n_year month) < left
            left = left - _MonthLength(n_year month)
            month++
        )
        list(month left)
    )
)


procedure(_ExpandPattern(t_pattern t_ctx "tt")  ; -> str
    ; 把复合令牌展开为基础令牌（%F/%T/%R/%D/%r/%c/%x/%X）。
    ;
    ; **参数**
    ;   t_pattern  (str) - 用户模板
    ;   t_ctx      (str) - 出错上下文名（拼入错误消息）
    ;
    ; **返回**
    ;   (str) - 只含基础令牌的模板；末尾悬空 % 时 error() 中断
    let((out i len ch tok rep)
        len = length(t_pattern)
        i = 1
        while(i <= len
            ch = substring(t_pattern i 1)
            if(ch == "%"
            then
                when(len < i + 1
                    error("%s: pattern ends with a dangling %%" t_ctx)
                )
                tok = substring(t_pattern i + 1 1)
                rep = case(tok
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
                if(rep
                    out = tconc(out rep)
                    out = tconc(out strcat("%" tok))
                )
                i = i + 2
            else
                out = tconc(out ch)
                i++
            )
        )
        if(out
            buildString(car(out) "")
            ""
        )
    )
)


procedure(_ParseTime(t_text t_pattern t_ctx "ttt")  ; -> list[int]
    ; 按模板把文本解析为 (Unix 秒, 纳秒)。
    ;
    ; **参数**
    ;   t_text     (str) - 待解析文本
    ;   t_pattern  (str) - 模板（支持 format 的基础令牌，复合令牌自动展开）
    ;   t_ctx      (str) - 出错上下文名（拼入错误消息）
    ;
    ; **返回**
    ;   (list[int]) - (Unix 秒, 纳秒)；文本与模板不匹配、字段越界、
    ;                 日期不存在（如 2 月 30 日）、DST 空洞或明示的星期/序日不一致时 error() 中断
    let((pat plen pp tlen pos ch tok res
         year short century month mday
         hour hour12 minute second ampm
         wday wdayISO yday epoch nanos millis tm md digits)
        pat = _ExpandPattern(t_pattern t_ctx)
        plen = length(pat)
        tlen = length(t_text)
        pp = 1
        pos = 1
        while(pp <= plen
            ch = substring(pat pp 1)
            if(ch == "%"
            then
                pp++
                tok = substring(pat pp 1)
                pp++
                case(tok
                    ("Y"
                        res = _ParseDigits(t_text pos 1 4)
                        unless(res
                            error("%s: expected a year at position %d" t_ctx pos)
                        )
                        when(year != nil
                            error("%s: duplicate %%Y" t_ctx)
                        )
                        year = car(res)
                        pos = cadr(res)
                    )
                    ("y"
                        res = _ParseDigits(t_text pos 1 2)
                        unless(res
                            error("%s: expected a two-digit year at position %d" t_ctx pos)
                        )
                        when(short != nil
                            error("%s: duplicate %%y" t_ctx)
                        )
                        short = car(res)
                        pos = cadr(res)
                    )
                    ("C"
                        res = _ParseDigits(t_text pos 1 2)
                        unless(res
                            error("%s: expected a century at position %d" t_ctx pos)
                        )
                        when(century != nil
                            error("%s: duplicate %%C" t_ctx)
                        )
                        century = car(res)
                        pos = cadr(res)
                    )
                    ("m"
                        res = _ParseDigits(t_text pos 1 2)
                        unless(res
                            error("%s: expected a month at position %d" t_ctx pos)
                        )
                        when(month != nil
                            error("%s: duplicate month field" t_ctx)
                        )
                        month = car(res)
                        pos = cadr(res)
                    )
                    ("d"
                        res = _ParseDigits(t_text pos 1 2)
                        unless(res
                            error("%s: expected a day at position %d" t_ctx pos)
                        )
                        when(mday != nil
                            error("%s: duplicate day field" t_ctx)
                        )
                        mday = car(res)
                        pos = cadr(res)
                    )
                    ("e"
                        when(pos <= tlen && substring(t_text pos 1) == " "
                            pos++
                        )
                        res = _ParseDigits(t_text pos 1 2)
                        unless(res
                            error("%s: expected a day at position %d" t_ctx pos)
                        )
                        when(mday != nil
                            error("%s: duplicate day field" t_ctx)
                        )
                        mday = car(res)
                        pos = cadr(res)
                    )
                    ("H"
                        res = _ParseDigits(t_text pos 1 2)
                        unless(res
                            error("%s: expected an hour at position %d" t_ctx pos)
                        )
                        when(hour != nil || hour12 != nil
                            error("%s: duplicate hour field" t_ctx)
                        )
                        hour = car(res)
                        pos = cadr(res)
                    )
                    ("I"
                        res = _ParseDigits(t_text pos 1 2)
                        unless(res
                            error("%s: expected an hour at position %d" t_ctx pos)
                        )
                        when(hour != nil || hour12 != nil
                            error("%s: duplicate hour field" t_ctx)
                        )
                        hour12 = car(res)
                        pos = cadr(res)
                    )
                    ("M"
                        res = _ParseDigits(t_text pos 1 2)
                        unless(res
                            error("%s: expected a minute at position %d" t_ctx pos)
                        )
                        when(minute != nil
                            error("%s: duplicate minute field" t_ctx)
                        )
                        minute = car(res)
                        pos = cadr(res)
                    )
                    ("S"
                        res = _ParseDigits(t_text pos 1 2)
                        unless(res
                            error("%s: expected a second at position %d" t_ctx pos)
                        )
                        when(second != nil
                            error("%s: duplicate second field" t_ctx)
                        )
                        second = car(res)
                        pos = cadr(res)
                    )
                    ("j"
                        res = _ParseDigits(t_text pos 1 3)
                        unless(res
                            error("%s: expected a day-of-year at position %d" t_ctx pos)
                        )
                        when(yday != nil
                            error("%s: duplicate %%j" t_ctx)
                        )
                        yday = car(res)
                        pos = cadr(res)
                    )
                    ("w"
                        res = _ParseDigits(t_text pos 1 1)
                        unless(res
                            error("%s: expected a weekday at position %d" t_ctx pos)
                        )
                        when(wday != nil || wdayISO != nil
                            error("%s: duplicate weekday field" t_ctx)
                        )
                        wday = car(res)
                        pos = cadr(res)
                    )
                    ("u"
                        res = _ParseDigits(t_text pos 1 1)
                        unless(res
                            error("%s: expected a weekday at position %d" t_ctx pos)
                        )
                        when(wday != nil || wdayISO != nil
                            error("%s: duplicate weekday field" t_ctx)
                        )
                        wdayISO = car(res)
                        pos = cadr(res)
                    )
                    ("p"
                        res = _ParseName(t_text pos list("AM" "PM"))
                        unless(res
                            error("%s: expected AM or PM at position %d" t_ctx pos)
                        )
                        when(ampm != nil
                            error("%s: duplicate %%p" t_ctx)
                        )
                        ampm = car(res)
                        pos = cadr(res)
                    )
                    ("P"
                        res = _ParseName(t_text pos list("AM" "PM"))
                        unless(res
                            error("%s: expected AM or PM at position %d" t_ctx pos)
                        )
                        when(ampm != nil
                            error("%s: duplicate %%p" t_ctx)
                        )
                        ampm = car(res)
                        pos = cadr(res)
                    )
                    ("a"
                        res = _ParseName(t_text pos _DayShort)
                        unless(res
                            error("%s: expected a weekday name at position %d" t_ctx pos)
                        )
                        when(wday != nil || wdayISO != nil
                            error("%s: duplicate weekday field" t_ctx)
                        )
                        wday = car(res)
                        pos = cadr(res)
                    )
                    ("A"
                        res = _ParseName(t_text pos _DayLong)
                        unless(res
                            error("%s: expected a weekday name at position %d" t_ctx pos)
                        )
                        when(wday != nil || wdayISO != nil
                            error("%s: duplicate weekday field" t_ctx)
                        )
                        wday = car(res)
                        pos = cadr(res)
                    )
                    ("b"
                        res = _ParseName(t_text pos _MonthShort)
                        unless(res
                            error("%s: expected a month name at position %d" t_ctx pos)
                        )
                        when(month != nil
                            error("%s: duplicate month field" t_ctx)
                        )
                        month = car(res) + 1
                        pos = cadr(res)
                    )
                    ("h"
                        res = _ParseName(t_text pos _MonthShort)
                        unless(res
                            error("%s: expected a month name at position %d" t_ctx pos)
                        )
                        when(month != nil
                            error("%s: duplicate month field" t_ctx)
                        )
                        month = car(res) + 1
                        pos = cadr(res)
                    )
                    ("B"
                        res = _ParseName(t_text pos _MonthLong)
                        unless(res
                            error("%s: expected a month name at position %d" t_ctx pos)
                        )
                        when(month != nil
                            error("%s: duplicate month field" t_ctx)
                        )
                        month = car(res) + 1
                        pos = cadr(res)
                    )
                    ("s"
                        res = _ParseSigned(t_text pos)
                        unless(res
                            error("%s: expected an integer time at position %d" t_ctx pos)
                        )
                        when(epoch != nil
                            error("%s: duplicate %%s" t_ctx)
                        )
                        epoch = car(res)
                        pos = cadr(res)
                    )
                    ("N"
                        res = _ParseDigits(t_text pos 1 9)
                        unless(res
                            error("%s: expected fractional seconds at position %d" t_ctx pos)
                        )
                        when(nanos != nil
                            error("%s: duplicate fractional seconds" t_ctx)
                        )
                        digits = cadr(res) - pos
                        nanos = car(res) * nth(9 - digits _Pow10)
                        pos = cadr(res)
                    )
                    ("L"
                        res = _ParseDigits(t_text pos 1 3)
                        unless(res
                            error("%s: expected milliseconds at position %d" t_ctx pos)
                        )
                        when(nanos != nil || millis != nil
                            error("%s: duplicate fractional seconds" t_ctx)
                        )
                        digits = cadr(res) - pos
                        millis = car(res) * nth(3 - digits _Pow10)
                        pos = cadr(res)
                    )
                    ("n"
                        unless(substring(t_text pos 1) == "\n"
                            error("%s: expected a newline at position %d" t_ctx pos)
                        )
                        pos++
                    )
                    ("t"
                        unless(substring(t_text pos 1) == "\t"
                            error("%s: expected a tab at position %d" t_ctx pos)
                        )
                        pos++
                    )
                    ("%"
                        unless(substring(t_text pos 1) == "%"
                            error("%s: expected %% at position %d" t_ctx pos)
                        )
                        pos++
                    )
                    (t
                        error("%s: cannot parse token %%%s" t_ctx tok)
                    )
                )
            else
                unless(substring(t_text pos 1) == ch
                    error("%s: expected %A at position %d" t_ctx ch pos)
                )
                pos++
                pp++
            )
        )
        unless(tlen + 1 == pos
            error("%s: unexpected trailing text %A" t_ctx substring(t_text pos))
        )

        if(epoch != nil
        then
            when(year != nil || short != nil || century != nil || month != nil
                    || mday != nil || hour != nil || hour12 != nil
                    || minute != nil || second != nil || ampm != nil
                    || wday != nil || wdayISO != nil || yday != nil
                error("%s: %%s cannot be combined with date/time tokens" t_ctx)
            )
            when(nanos != nil && millis != nil
                error("%s: %%N cannot be combined with %%L" t_ctx)
            )
            when(nanos == nil && millis != nil
                nanos = millis * fix(1e6)
            )
            when(nanos == nil
                nanos = 0
            )
            list(epoch nanos)
        else
            ; --- year ---
            when(century != nil && short == nil
                error("%s: %%C requires %%y" t_ctx)
            )
            when(year != nil && (short != nil || century != nil)
                error("%s: %%Y cannot be combined with %%y or %%C" t_ctx)
            )
            when(year == nil && short != nil
                when(century == nil
                    century = if(short < 69 20 19)
                )
                year = century * 100 + short
            )
            unless(year != nil
                error("%s: pattern has no year field" t_ctx)
            )

            ; --- month and day (or day-of-year) ---
            when(yday != nil && (month == nil || mday == nil)
                when(month != nil || mday != nil
                    error("%s: %%j cannot be combined with a partial month/day" t_ctx)
                )
                when(yday < 1 || 366 < yday
                    error("%s: day-of-year %d is out of range" t_ctx yday)
                )
                when(yday == 366 && !_IsLeapYear(year)
                    error("%s: day-of-year 366 is invalid for %04d" t_ctx year)
                )
                md = _MonthDayFromYday(year yday)
                month = car(md)
                mday = cadr(md)
            )
            unless(month != nil && mday != nil
                error("%s: pattern needs month and day, or %%j" t_ctx)
            )
            when(month < 1 || 12 < month
                error("%s: month %d is out of range" t_ctx month)
            )
            when(mday < 1 || _MonthLength(year month) < mday
                error("%s: day %d is invalid for %04d-%02d" t_ctx mday year month)
            )

            ; --- time ---
            when(hour12 != nil
                when(hour12 < 1 || 12 < hour12
                    error("%s: hour %d is out of range for %%I" t_ctx hour12)
                )
                hour = remainder(hour12 12) + if(ampm == 1 12 0)
            )
            when(hour == nil
                hour = 0
            )
            when(hour < 0 || 23 < hour
                error("%s: hour %d is out of range" t_ctx hour)
            )
            when(ampm != nil && hour12 == nil
                when((hour < 12 && ampm == 1) || (12 <= hour && ampm == 0)
                    error("%s: %%p conflicts with %%H" t_ctx)
                )
            )
            when(minute == nil
                minute = 0
            )
            when(minute < 0 || 59 < minute
                error("%s: minute %d is out of range" t_ctx minute)
            )
            when(second == nil
                second = 0
            )
            when(second < 0 || 59 < second
                error("%s: second %d is out of range" t_ctx second)
            )
            when(wdayISO != nil
                when(wdayISO < 1 || 7 < wdayISO
                    error("%s: ISO weekday %d is out of range" t_ctx wdayISO)
                )
                wday = remainder(wdayISO 7)
            )
            when(wday != nil && (wday < 0 || 6 < wday)
                error("%s: weekday %d is out of range" t_ctx wday)
            )

            ; --- build and verify ---
            tm = timeToTm(0)
            tm->tm_year = year - 1900
            tm->tm_mon = month - 1
            tm->tm_mday = mday
            tm->tm_hour = hour
            tm->tm_min = minute
            tm->tm_sec = second
            tm->tm_isdst = -1
            epoch = tmToTime(tm)
            unless(fixp(epoch)
                error("%s: cannot convert %A to a time value" t_ctx t_text)
            )
            tm = timeToTm(epoch)
            unless(tm
                    && tm->tm_year + 1900 == year && tm->tm_mon + 1 == month
                    && tm->tm_mday == mday && tm->tm_hour == hour
                    && tm->tm_min == minute && tm->tm_sec == second
                when(year < 1902 || 2037 < year
                    error("%s: year %d is outside the representable time range" t_ctx year)
                )
                error("%s: invalid local time %A" t_ctx t_text)
            )
            when(wday != nil && tm->tm_wday != wday
                error("%s: weekday does not match %A" t_ctx t_text)
            )
            when(yday != nil && tm->tm_yday + 1 != yday
                error("%s: day-of-year does not match %A" t_ctx t_text)
            )
            when(nanos != nil && millis != nil
                error("%s: %%N cannot be combined with %%L" t_ctx)
            )
            when(nanos == nil && millis != nil
                nanos = millis * fix(1e6)
            )
            when(nanos == nil
                nanos = 0
            )
            list(epoch nanos)
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
    let((res)
        res = _ParseTime(t_text t_pattern "ycDateTime::Parse")
        _MkDateTime(car(res) cadr(res))
    )
)


unuseNamespace("ycDateTime")

; END
