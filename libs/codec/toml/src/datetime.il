;--------------------------
; Program  : codec/toml(datetime.il)
; Language : Cadence Skill
;--------------------------

ycNamespace:::Require("ycCodec")

useNamespace("ycToml")

procedure(_ReadDigits(t_s n_i n_count "txx")  ; -> int
    ; 读取固定长度的十进制数字。
    ;
    ; **参数**
    ;   t_s      (str) - 输入串
    ;   n_i      (int) - 首字符位置
    ;   n_count  (int) - 位数
    ;
    ; **返回**
    ;   (int) - 解析值；非数字报错
    let((v)
        v = 0
        for(k 1 n_count
            unless(_Digitp(_Code(t_s n_i + k - 1))
                _Error(t_s n_i + k - 1 "expected a digit")
            )
            v = v * 10 + _Code(t_s n_i + k - 1) - 48
        )
        v
    )
)


; ---------- 日期时间 ----------

procedure(_LooksDate(t_s n_i "tx")  ; -> t | nil
    ; 判断当前位置是否形如 YYYY-MM-DD。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;   n_i  (int) - 起始位置
    ;
    ; **返回**
    ;   (t|nil) - 形如日期时为 t
    _Digitp(_Code(t_s n_i))
        && _Digitp(_Code(t_s n_i + 1))
        && _Digitp(_Code(t_s n_i + 2))
        && _Digitp(_Code(t_s n_i + 3))
        && _Code(t_s n_i + 4) == 45
        && _Digitp(_Code(t_s n_i + 5))
        && _Digitp(_Code(t_s n_i + 6))
        && _Code(t_s n_i + 7) == 45
        && _Digitp(_Code(t_s n_i + 8))
        && _Digitp(_Code(t_s n_i + 9))
)

procedure(_LooksTime(t_s n_i "tx")  ; -> t | nil
    ; 判断当前位置是否形如 HH:MM:SS。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;   n_i  (int) - 起始位置
    ;
    ; **返回**
    ;   (t|nil) - 形如时间时为 t
    _Digitp(_Code(t_s n_i))
        && _Digitp(_Code(t_s n_i + 1))
        && _Code(t_s n_i + 2) == 58
        && _Digitp(_Code(t_s n_i + 3))
        && _Digitp(_Code(t_s n_i + 4))
        && _Code(t_s n_i + 5) == 58
        && _Digitp(_Code(t_s n_i + 6))
        && _Digitp(_Code(t_s n_i + 7))
)


procedure(_DaysInMonth(n_year n_month "xx")  ; -> int
    ; 返回公历某年某月的天数。
    ;
    ; **参数**
    ;   n_year   (int) - 年
    ;   n_month  (int) - 月（1..12）
    ;
    ; **返回**
    ;   (int) - 天数
    let((days leap)
        case(n_month
            ((1 3 5 7 8 10 12) days = 31)
            ((4 6 9 11) days = 30)
            (2
                leap = (remainder(n_year 4) == 0 && remainder(n_year 100) != 0)
                    || remainder(n_year 400) == 0
                days = if(leap 29 28)
            )
            (t days = 0)
        )
        days
    )
)

procedure(_ParseTimeAt(t_s n_i g_offset "txg")  ; -> int
    ; 解析 HH:MM:SS[.frac] 与可选偏移，返回结束位置。
    ;
    ; **参数**
    ;   t_s       (str) - 输入串
    ;   n_i       (int) - 起始位置
    ;   g_offset  (t|nil) - t 时允许 Z/z 或 ±HH:MM 偏移
    ;
    ; **返回**
    ;   (int) - 时间部分结束后一位置
    let((hour minute second k c)
        unless(_Code(t_s n_i + 2) == 58 && _Code(t_s n_i + 5) == 58
            _Error(t_s n_i "invalid time")
        )
        hour = _ReadDigits(t_s n_i 2)
        minute = _ReadDigits(t_s n_i + 3 2)
        second = _ReadDigits(t_s n_i + 6 2)
        unless(hour <= 23 && minute <= 59 && second <= 60
            _Error(t_s n_i "invalid time")
        )
        k = n_i + 8
        when(_Code(t_s k) == 46
            k++
            unless(_Digitp(_Code(t_s k))
                _Error(t_s k "invalid fractional seconds")
            )
            while(_Digitp(_Code(t_s k))
                k++
            )
        )
        when(g_offset
            cond(
                ((_Code(t_s k) == 90 || _Code(t_s k) == 122)
                    k++
                )
                ((_Code(t_s k) == 43 || _Code(t_s k) == 45)
                    {
                    hour = _ReadDigits(t_s k + 1 2)
                    minute = _ReadDigits(t_s k + 4 2)
                    unless(hour <= 23 && minute <= 59 && _Code(t_s k + 3) == 58
                        _Error(t_s k "invalid timezone offset")
                    )
                    k = k + 6
                    }
                )
            )
        )
        k
    )
)

procedure(_ParseDateTime(t_s n_i "tx")  ; -> list
    ; 解析 TOML 日期、时间或日期时间，保留原文作为字符串。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;   n_i  (int) - 起始位置
    ;
    ; **返回**
    ;   (list) - (原文字符串 下一位置)
    let((year month day k days)
        if(_LooksTime(t_s n_i)
        then
            k = _ParseTimeAt(t_s n_i nil)
        else
            year = _ReadDigits(t_s n_i 4)
            month = _ReadDigits(t_s n_i + 5 2)
            day = _ReadDigits(t_s n_i + 8 2)
            unless(_Code(t_s n_i + 4) == 45 && _Code(t_s n_i + 7) == 45
                _Error(t_s n_i "invalid date")
            )
            days = _DaysInMonth(year month)
            unless(month >= 1 && month <= 12 && day >= 1 && day <= days
                _Error(t_s n_i "invalid date")
            )
            k = n_i + 10
            cond(
                ((_Code(t_s k) == 84 || _Code(t_s k) == 116)
                    k = _ParseTimeAt(t_s k + 1 t)
                )
                ((_Code(t_s k) == 32 && _LooksTime(t_s k + 1))
                    k = _ParseTimeAt(t_s k + 1 t)
                )
            )
        )
        list(substring(t_s n_i k - n_i) k)
    )
)
unuseNamespace("ycToml")

; END
