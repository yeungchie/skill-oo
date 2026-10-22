;--------------------------
; Program  : codec/toml(datetime.il)
; Language : Cadence Skill
;--------------------------

ycNamespace:::require("ycCodec")

useNamespace("ycToml")

procedure(_readDigits(t_s n_i n_count "txx")  ; -> int
    ; 读取固定长度的十进制数字。
    ;
    ; **参数**
    ;   t_s      (str) - 输入串
    ;   n_i      (int) - 首字符位置
    ;   n_count  (int) - 位数
    ;
    ; **返回**
    ;   (int) - 解析值；非数字报错
    let((n_v)
        n_v = 0
        for(n_k 1 n_count
            unless(_digitp(_code(t_s n_i + n_k - 1))
                _error(t_s n_i + n_k - 1 "expected a digit")
            )
            n_v = n_v * 10 + _code(t_s n_i + n_k - 1) - 48
        )
        n_v
    )
)


; ---------- 日期时间 ----------

procedure(_looksDate(t_s n_i "tx")  ; -> t | nil
    ; 判断当前位置是否形如 YYYY-MM-DD。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;   n_i  (int) - 起始位置
    ;
    ; **返回**
    ;   (t|nil) - 形如日期时为 t
    _digitp(_code(t_s n_i))
        && _digitp(_code(t_s n_i + 1))
        && _digitp(_code(t_s n_i + 2))
        && _digitp(_code(t_s n_i + 3))
        && _code(t_s n_i + 4) == 45
        && _digitp(_code(t_s n_i + 5))
        && _digitp(_code(t_s n_i + 6))
        && _code(t_s n_i + 7) == 45
        && _digitp(_code(t_s n_i + 8))
        && _digitp(_code(t_s n_i + 9))
)

procedure(_looksTime(t_s n_i "tx")  ; -> t | nil
    ; 判断当前位置是否形如 HH:MM:SS。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;   n_i  (int) - 起始位置
    ;
    ; **返回**
    ;   (t|nil) - 形如时间时为 t
    _digitp(_code(t_s n_i))
        && _digitp(_code(t_s n_i + 1))
        && _code(t_s n_i + 2) == 58
        && _digitp(_code(t_s n_i + 3))
        && _digitp(_code(t_s n_i + 4))
        && _code(t_s n_i + 5) == 58
        && _digitp(_code(t_s n_i + 6))
        && _digitp(_code(t_s n_i + 7))
)


procedure(_daysInMonth(n_year n_month "xx")  ; -> int
    ; 返回公历某年某月的天数。
    ;
    ; **参数**
    ;   n_year   (int) - 年
    ;   n_month  (int) - 月（1..12）
    ;
    ; **返回**
    ;   (int) - 天数
    let((n_days g_leap)
        case(n_month
            ((1 3 5 7 8 10 12) n_days = 31)
            ((4 6 9 11) n_days = 30)
            (2
                g_leap = (remainder(n_year 4) == 0 && remainder(n_year 100) != 0)
                    || remainder(n_year 400) == 0
                n_days = if(g_leap 29 28)
            )
            (t n_days = 0)
        )
        n_days
    )
)

procedure(_parseTimeAt(t_s n_i g_offset "txg")  ; -> int
    ; 解析 HH:MM:SS[.frac] 与可选偏移，返回结束位置。
    ;
    ; **参数**
    ;   t_s       (str) - 输入串
    ;   n_i       (int) - 起始位置
    ;   g_offset  (t|nil) - t 时允许 Z/z 或 ±HH:MM 偏移
    ;
    ; **返回**
    ;   (int) - 时间部分结束后一位置
    let((n_hour n_minute n_second n_k n_c)
        unless(_code(t_s n_i + 2) == 58 && _code(t_s n_i + 5) == 58
            _error(t_s n_i "invalid time")
        )
        n_hour = _readDigits(t_s n_i 2)
        n_minute = _readDigits(t_s n_i + 3 2)
        n_second = _readDigits(t_s n_i + 6 2)
        unless(n_hour <= 23 && n_minute <= 59 && n_second <= 60
            _error(t_s n_i "invalid time")
        )
        n_k = n_i + 8
        when(_code(t_s n_k) == 46
            n_k = n_k + 1
            unless(_digitp(_code(t_s n_k))
                _error(t_s n_k "invalid fractional seconds")
            )
            while(_digitp(_code(t_s n_k))
                n_k = n_k + 1
            )
        )
        when(g_offset
            cond(
                ((_code(t_s n_k) == 90 || _code(t_s n_k) == 122)
                    n_k = n_k + 1
                )
                ((_code(t_s n_k) == 43 || _code(t_s n_k) == 45)
                    {
                    n_hour = _readDigits(t_s n_k + 1 2)
                    n_minute = _readDigits(t_s n_k + 4 2)
                    unless(n_hour <= 23 && n_minute <= 59 && _code(t_s n_k + 3) == 58
                        _error(t_s n_k "invalid timezone offset")
                    )
                    n_k = n_k + 6
                    }
                )
            )
        )
        n_k
    )
)

procedure(_parseDateTime(t_s n_i "tx")  ; -> list
    ; 解析 TOML 日期、时间或日期时间，保留原文作为字符串。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;   n_i  (int) - 起始位置
    ;
    ; **返回**
    ;   (list) - (原文字符串 下一位置)
    let((n_year n_month n_day n_k n_days)
        if(_looksTime(t_s n_i)
            {
            n_k = _parseTimeAt(t_s n_i nil)
            }
            {
            n_year = _readDigits(t_s n_i 4)
            n_month = _readDigits(t_s n_i + 5 2)
            n_day = _readDigits(t_s n_i + 8 2)
            unless(_code(t_s n_i + 4) == 45 && _code(t_s n_i + 7) == 45
                _error(t_s n_i "invalid date")
            )
            n_days = _daysInMonth(n_year n_month)
            unless(n_month >= 1 && n_month <= 12 && n_day >= 1 && n_day <= n_days
                _error(t_s n_i "invalid date")
            )
            n_k = n_i + 10
            cond(
                ((_code(t_s n_k) == 84 || _code(t_s n_k) == 116)
                    n_k = _parseTimeAt(t_s n_k + 1 t)
                )
                ((_code(t_s n_k) == 32 && _looksTime(t_s n_k + 1))
                    n_k = _parseTimeAt(t_s n_k + 1 t)
                )
            )
            }
        )
        list(substring(t_s n_i n_k - n_i) n_k)
    )
)
unuseNamespace("ycToml")

; END
