;--------------------------
; Program  : ycUnits(src/units.il)
; Language : Cadence Skill
;--------------------------

useNamespace("ycUnits")

; ---------- 基础字符 ----------

procedure(_isWs(n_b "x")  ; -> t | nil
    ; 判断字节是否为空白（内部实现）。
    ;
    ; **参数**
    ;   n_b  (int) - 字节值
    ;
    ; **返回**
    ;   (t|nil) - 空格、制表、换行、回车为 t
    n_b == 32 || n_b == 9 || n_b == 10 || n_b == 13
)

procedure(_isDigit(n_b "x")  ; -> t | nil
    ; 判断字节是否为十进制数字（内部实现）。
    ;
    ; **参数**
    ;   n_b  (int) - 字节值
    ;
    ; **返回**
    ;   (t|nil) - 0–9 为 t
    n_b >= 48 && n_b <= 57
)

procedure(_hasWs(t_s "t")  ; -> t | nil
    ; 判断字符串是否含空白（内部实现）。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;
    ; **返回**
    ;   (t|nil) - 含空白为 t
    let((n_i n_len g_found)
        n_i = 1
        n_len = length(t_s)
        while(n_i <= n_len && !g_found
            when(_isWs(charToInt(getchar(t_s n_i)))
                g_found = t
            )
            n_i = n_i + 1
        )
        g_found
    )
)

; ---------- 前缀 ----------

procedure(_prefixAliases()  ; -> list
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

procedure(_shortFactor(n_ch "x")  ; -> num | nil
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

procedure(_tailAfter(t_s n_start "tx")  ; -> str
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

procedure(_prefixScale(t_rest t_space "tg")  ; -> list
    ; 把后缀拆为倍率与单位（内部实现）。
    ;
    ; **参数**
    ;   t_rest   (str) - 数值后的后缀
    ;   t_space  (t|nil) - 数值与后缀之间是否有空白
    ;
    ; **返回**
    ;   (list) - (倍率 单位)；空白分隔时不识别前缀
    if(t_space
        list(1.0 t_rest)
        let((l_found t_factor t_tail)
            foreach(l_pair _prefixAliases()
                when(!l_found
                    let((t_name)
                        t_name = car(l_pair)
                        when(length(t_rest) >= length(t_name)
                            when(substring(t_rest 1 length(t_name)) == t_name
                                l_found = t
                                t_factor = cadr(l_pair)
                                t_tail = _tailAfter(t_rest length(t_name) + 1)
                            )
                        )
                    )
                )
            )
            if(l_found
                list(t_factor t_tail)
                if(t_rest == ""
                    list(1.0 "")
                    let((n_factor)
                        n_factor = _shortFactor(charToInt(getchar(t_rest 1)))
                        if(n_factor
                            list(n_factor _tailAfter(t_rest 2))
                            list(1.0 t_rest)
                        )
                    )
                )
            )
        )
    )
)

procedure(_prefixForExp(n_exp "x")  ; -> str
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

procedure(_parse(t_str t_ctx "tt")  ; -> list
    ; 解析工程计数串（内部实现）。
    ;
    ; **参数**
    ;   t_str  (str) - 输入文本
    ;   t_ctx  (str) - 错误消息上下文
    ;
    ; **返回**
    ;   (list) - (数值 单位)
    let((n_len n_i n_start n_b n_digits n_edigits n_expStart g_space t_num t_unit l_pf)
        n_len = length(t_str)
        n_i = 1
        while(n_i <= n_len && _isWs(charToInt(getchar(t_str n_i)))
            n_i = n_i + 1
        )
        unless(n_i <= n_len
            error("%s: expected a number (%A)" t_ctx t_str)
        )
        n_start = n_i
        n_b = charToInt(getchar(t_str n_i))
        when(n_b == 43 || n_b == 45
            n_i = n_i + 1
        )
        n_digits = 0
        while(n_i <= n_len && _isDigit(charToInt(getchar(t_str n_i)))
            n_i = n_i + 1
            n_digits = n_digits + 1
        )
        when(n_i <= n_len && charToInt(getchar(t_str n_i)) == 46
            n_i = n_i + 1
            while(n_i <= n_len && _isDigit(charToInt(getchar(t_str n_i)))
                n_i = n_i + 1
                n_digits = n_digits + 1
            )
        )
        unless(n_digits > 0
            error("%s: expected a number (%A)" t_ctx t_str)
        )
        when(n_i <= n_len && (charToInt(getchar(t_str n_i)) == 101 || charToInt(getchar(t_str n_i)) == 69)
            n_expStart = n_i
            n_i = n_i + 1
            n_b = if(n_i <= n_len charToInt(getchar(t_str n_i)) nil)
            when(n_b == 43 || n_b == 45
                n_i = n_i + 1
            )
            n_edigits = 0
            while(n_i <= n_len && _isDigit(charToInt(getchar(t_str n_i)))
                n_i = n_i + 1
                n_edigits = n_edigits + 1
            )
            unless(n_edigits > 0
                error("%s: invalid exponent (%A)" t_ctx t_str)
            )
        )
        t_num = substring(t_str n_start n_i - n_start)
        g_space = when(n_i <= n_len _isWs(charToInt(getchar(t_str n_i))))
        while(n_i <= n_len && _isWs(charToInt(getchar(t_str n_i)))
            n_i = n_i + 1
        )
        t_unit = if(n_i <= n_len substring(t_str n_i n_len - n_i + 1) "")
        while(
            length(t_unit) > 0
            && _isWs(charToInt(getchar(t_unit length(t_unit))))
            t_unit = substring(t_unit 1 length(t_unit) - 1)
        )
        when(_hasWs(t_unit)
            error("%s: whitespace inside unit (%A)" t_ctx t_str)
        )
        when(
            t_unit != ""
            && (_isDigit(charToInt(getchar(t_unit 1))) || charToInt(getchar(t_unit 1)) == 46)
            error("%s: invalid number (%A)" t_ctx t_str)
        )
        l_pf = _prefixScale(t_unit g_space)
        list(atof(t_num) * car(l_pf) cadr(l_pf))
    )
)

; ---------- 公开入口 ----------

procedure(parse(t_text "t")  ; -> list
    ; 解析工程计数串。
    ;
    ; **参数**
    ;   t_text  (str) - 输入文本，如 "1k"、"2.5uF"、"4.7meg"
    ;
    ; **返回**
    ;   (list) - (数值 单位)；无单位时单位为空串
    _parse(t_text "ycUnits::parse")
)

procedure(format(n_value \@key (unit "") (precision 6) "ntx")  ; -> str
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
        error("ycUnits::format: precision must be an integer from 1 to 15 (%A)" precision)
    )
    if(n_value == 0
        strcat("0" unit)
        let((n_abs n_exp n_mant t_fmt t_mant n_rounded)
            n_abs = abs(n_value)
            if(n_abs < 1e-24 || n_abs >= 1e27
                strcat(sprintf(nil "%g" n_value) unit)
                progn(
                    n_exp = floor(log10(n_abs) / 3) * 3
                    n_mant = n_value * expt(10.0 -n_exp)
                    t_fmt = lsprintf("%%.%dg" precision)
                    t_mant = sprintf(nil t_fmt n_mant)
                    n_rounded = atof(t_mant)
                    when(abs(n_rounded) >= 1000
                        if(n_exp < 24
                            progn(
                                n_exp = n_exp + 3
                                n_mant = n_value * expt(10.0 -n_exp)
                                t_mant = sprintf(nil t_fmt n_mant)
                            )
                            progn(
                                t_mant = sprintf(nil "%g" n_value)
                                n_exp = nil
                            )
                        )
                    )
                    if(n_exp
                        strcat(t_mant _prefixForExp(n_exp) unit)
                        strcat(t_mant unit)
                    )
                )
            )
        )
    )
)

procedure(toNumber(t_text "t")  ; -> num
    ; 解析工程计数串并返回数值。
    ;
    ; **参数**
    ;   t_text  (str) - 输入文本
    ;
    ; **返回**
    ;   (num) - 数值部分（前缀已折算）
    car(_parse(t_text "ycUnits::toNumber"))
)

procedure(toUnit(t_text "t")  ; -> str
    ; 解析工程计数串并返回单位。
    ;
    ; **参数**
    ;   t_text  (str) - 输入文本
    ;
    ; **返回**
    ;   (str) - 单位部分；无单位为 ""
    cadr(_parse(t_text "ycUnits::toUnit"))
)

unuseNamespace("ycUnits")

; END
