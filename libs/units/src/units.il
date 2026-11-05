;--------------------------
; Program  : ycUnits(src/units.il)
; Language : Cadence Skill
;--------------------------

useNamespace("ycUnits")

; ---------- 基础字符 ----------

procedure(_IsWs(n_b "x")  ; -> t | nil
    ; 判断字节是否为空白（内部实现）。
    ;
    ; **参数**
    ;   n_b  (int) - 字节值
    ;
    ; **返回**
    ;   (t|nil) - 空格、制表、换行、回车为 t
    n_b == 32 || n_b == 9 || n_b == 10 || n_b == 13
)

procedure(_IsDigit(n_b "x")  ; -> t | nil
    ; 判断字节是否为十进制数字（内部实现）。
    ;
    ; **参数**
    ;   n_b  (int) - 字节值
    ;
    ; **返回**
    ;   (t|nil) - 0–9 为 t
    n_b >= 48 && n_b <= 57
)

procedure(_HasWs(t_s "t")  ; -> t | nil
    ; 判断字符串是否含空白（内部实现）。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;
    ; **返回**
    ;   (t|nil) - 含空白为 t
    let((i len found)
        i = 1
        len = length(t_s)
        while(i <= len && !found
            when(_IsWs(charToInt(getchar(t_s i)))
                found = t
            )
            i++
        )
        found
    )
)

; ---------- 前缀 ----------

procedure(_PrefixAliases()  ; -> list
    ; 返回长前缀别名表（内部实现）。
    ;
    ; **返回**
    ;   (list) - (名称 倍率) 列表，长名在前
    list(
        list("yotta" 1e24)
        list("zetta" 1e21)
        list("exa" 1e18)
        list("peta" 1e15)
        list("tera" 1e12)
        list("giga" 1e9)
        list("mega" 1e6)
        list("kilo" 1e3)
        list("milli" 1e-3)
        list("micro" 1e-6)
        list("nano" 1e-9)
        list("pico" 1e-12)
        list("femto" 1e-15)
        list("atto" 1e-18)
        list("zepto" 1e-21)
        list("yocto" 1e-24)
        list("meg" 1e6)
    )
)

procedure(_ShortFactor(n_ch "x")  ; -> num | nil
    ; 返回单字符 SI 前缀倍率（内部实现）。
    ;
    ; **参数**
    ;   n_ch  (int) - 前缀字节值
    ;
    ; **返回**
    ;   (num|nil) - 倍率；非前缀为 nil
    cond(
        (n_ch == 121 1e-24)
        (n_ch == 122 1e-21)
        (n_ch == 97 1e-18)
        (n_ch == 102 1e-15)
        (n_ch == 112 1e-12)
        (n_ch == 110 1e-9)
        (n_ch == 117 1e-6)
        (n_ch == 109 1e-3)
        (n_ch == 107 1e3)
        (n_ch == 75 1e3)
        (n_ch == 37 1e-2)
        (n_ch == 77 1e6)
        (n_ch == 71 1e9)
        (n_ch == 84 1e12)
        (n_ch == 80 1e15)
        (n_ch == 69 1e18)
        (n_ch == 90 1e21)
        (n_ch == 89 1e24)
        (t nil)
    )
)

procedure(_TailAfter(t_s n_start "tx")  ; -> str
    ; 取从 n_start 开始的尾部（内部实现）。
    ;
    ; **参数**
    ;   t_s      (str) - 输入串
    ;   n_start  (int) - 1-based 起始位置
    ;
    ; **返回**
    ;   (str) - 尾部；起点越界为空串
    if(n_start > length(t_s) "" substring(t_s n_start length(t_s) - n_start + 1))
)

procedure(_PrefixScale(t_rest g_space "tg")  ; -> list
    ; 把后缀拆为倍率与单位（内部实现）。
    ;
    ; **参数**
    ;   t_rest   (str) - 数值后的后缀
    ;   g_space  (t|nil) - 数值与后缀之间是否有空白
    ;
    ; **返回**
    ;   (list) - (倍率 单位)；空白分隔时不识别前缀
    if(g_space
        list(1.0 t_rest)
        let((found factor tail)
            foreach(pair _PrefixAliases()
                when(!found
                    let((name)
                        name = car(pair)
                        when(length(t_rest) >= length(name)
                            when(substring(t_rest 1 length(name)) == name
                                found = t
                                factor = cadr(pair)
                                tail = _TailAfter(t_rest length(name) + 1)
                            )
                        )
                    )
                )
            )
            cond(
                (found
                    list(factor tail)
                )
                (t_rest == ""
                    list(1.0 "")
                )
                (t
                    let((factor2)
                        factor2 = _ShortFactor(charToInt(getchar(t_rest 1)))
                        if(factor2
                            list(factor2 _TailAfter(t_rest 2))
                            list(1.0 t_rest)
                        )
                    )
                )
            )
        )
    )
)

procedure(_PrefixForExp(n_exp "x")  ; -> str
    ; 返回 3 的倍数指数对应的前缀（内部实现）。
    ;
    ; **参数**
    ;   n_exp  (int) - 指数
    ;
    ; **返回**
    ;   (str) - 前缀；0 或超范围为 ""
    cond(
        (n_exp == -24 "y")
        (n_exp == -21 "z")
        (n_exp == -18 "a")
        (n_exp == -15 "f")
        (n_exp == -12 "p")
        (n_exp == -9 "n")
        (n_exp == -6 "u")
        (n_exp == -3 "m")
        (n_exp == 3 "k")
        (n_exp == 6 "M")
        (n_exp == 9 "G")
        (n_exp == 12 "T")
        (n_exp == 15 "P")
        (n_exp == 18 "E")
        (n_exp == 21 "Z")
        (n_exp == 24 "Y")
        (t "")
    )
)

; ---------- 解析 ----------

procedure(_Parse(t_str t_ctx "tt")  ; -> list
    ; 解析工程计数串（内部实现）。
    ;
    ; **参数**
    ;   t_str  (str) - 输入文本
    ;   t_ctx  (str) - 错误消息上下文
    ;
    ; **返回**
    ;   (list) - (数值 单位)
    let((len i start b digits edigits expStart space num unit2 pf)
        len = length(t_str)
        i = 1
        while(i <= len && _IsWs(charToInt(getchar(t_str i)))
            i++
        )
        unless(i <= len
            error("%s: expected a number (%A)" t_ctx t_str)
        )
        start = i
        b = charToInt(getchar(t_str i))
        when(b == 43 || b == 45
            i++
        )
        digits = 0
        while(i <= len && _IsDigit(charToInt(getchar(t_str i)))
            i++
            digits++
        )
        when(i <= len && charToInt(getchar(t_str i)) == 46
            i++
            while(i <= len && _IsDigit(charToInt(getchar(t_str i)))
                i++
                digits++
            )
        )
        unless(digits > 0
            error("%s: expected a number (%A)" t_ctx t_str)
        )
        when(i <= len && (charToInt(getchar(t_str i)) == 101 || charToInt(getchar(t_str i)) == 69)
            expStart = i
            i++
            b = when(i <= len charToInt(getchar(t_str i)))
            when(b == 43 || b == 45
                i++
            )
            edigits = 0
            while(i <= len && _IsDigit(charToInt(getchar(t_str i)))
                i++
                edigits++
            )
            unless(edigits > 0
                error("%s: invalid exponent (%A)" t_ctx t_str)
            )
        )
        num = substring(t_str start i - start)
        space = when(i <= len _IsWs(charToInt(getchar(t_str i))))
        while(i <= len && _IsWs(charToInt(getchar(t_str i)))
            i++
        )
        unit2 = if(i <= len substring(t_str i len - i + 1) "")
        while(
            unit2 != ""
            && _IsWs(charToInt(getchar(unit2 length(unit2))))
            unit2 = substring(unit2 1 length(unit2) - 1)
        )
        when(_HasWs(unit2)
            error("%s: whitespace inside unit (%A)" t_ctx t_str)
        )
        when(
            unit2 != ""
            && (_IsDigit(charToInt(getchar(unit2 1))) || charToInt(getchar(unit2 1)) == 46)
            error("%s: invalid number (%A)" t_ctx t_str)
        )
        pf = _PrefixScale(unit2 space)
        list(atof(num) * car(pf) cadr(pf))
    )
)

; ---------- 公开入口 ----------

procedure(Parse(t_text "t")  ; -> list
    ; 解析工程计数串。
    ;
    ; **参数**
    ;   t_text  (str) - 输入文本，如 "1k"、"2.5uF"、"4.7meg"
    ;
    ; **返回**
    ;   (list) - (数值 单位)；无单位时单位为空串
    _Parse(t_text "ycUnits::Parse")
)

procedure(Format(n_value \@key (unit "") (precision 6) "ntx")  ; -> str
    ; 把数值格式化为工程计数。
    ;
    ; **参数**
    ;   n_value    (num) - 待格式化数值
    ;   ?unit      (str) - 附加单位；默认 ""
    ;   ?precision (int) - 有效数字位数（1–15）；默认 6
    ;
    ; **返回**
    ;   (str) - 工程计数文本，如 "1.234k"、"2.5uF"
    unless(fixp(precision) && precision >= 1 && precision <= 15
        error("ycUnits::Format: precision must be an integer from 1 to 15 (%A)" precision)
    )
    if(n_value == 0
        strcat("0" unit)
        let((abs exp mant fmt mant2 rounded)
            abs = abs(n_value)
            fmt = lsprintf("%%.%dg" precision)
            if(abs < 1e-24 || abs >= 1e27
            then
                strcat(sprintf(nil fmt n_value) unit)
            else
                exp = floor(log10(abs) / 3) * 3
                mant = n_value * expt(10.0 -exp)
                mant2 = sprintf(nil fmt mant)
                rounded = atof(mant2)
                when(abs(rounded) >= 1000
                    if(exp < 24
                    then
                        exp = exp + 3
                        mant = n_value * expt(10.0 -exp)
                        mant2 = sprintf(nil fmt mant)
                    else
                        mant2 = sprintf(nil fmt n_value)
                        exp = nil
                    )
                )
                if(exp
                    lsprintf("%s%s%s" mant2 _PrefixForExp(exp) unit)
                    strcat(mant2 unit)
                )
            )
        )
    )
)

procedure(ToNumber(t_text "t")  ; -> num
    ; 解析工程计数串并返回数值。
    ;
    ; **参数**
    ;   t_text  (str) - 输入文本
    ;
    ; **返回**
    ;   (num) - 数值部分（前缀已折算）
    car(_Parse(t_text "ycUnits::ToNumber"))
)

procedure(ToUnit(t_text "t")  ; -> str
    ; 解析工程计数串并返回单位。
    ;
    ; **参数**
    ;   t_text  (str) - 输入文本
    ;
    ; **返回**
    ;   (str) - 单位部分；无单位为 ""
    cadr(_Parse(t_text "ycUnits::ToUnit"))
)

unuseNamespace("ycUnits")

; END
