;--------------------------
; Program  : codec/toml(scalar.il)
; Language : Cadence Skill
;--------------------------

ycNamespace:::Require("ycCodec")

useNamespace("ycToml")

; ---------- 字符与数字小工具 ----------

procedure(_ReadHex(t_s n_i n_count "txx")  ; -> int
    ; 读取固定长度的十六进制数；任一位非法即报错。
    ;
    ; **参数**
    ;   t_s      (str) - 输入串
    ;   n_i      (int) - 首字符位置
    ;   n_count  (int) - 位数
    ;
    ; **返回**
    ;   (int) - 解析值
    let((n_v n_d n_c)
        n_v = 0
        for(n_k 1 n_count
            n_c = _HexVal(_Code(t_s n_i + n_k - 1))
            unless(n_c
                _Error(t_s n_i + n_k - 1 "invalid hexadecimal escape")
            )
            n_v = n_v * 16 + n_c
        )
        n_v
    )
)

; ---------- 字符串 ----------

procedure(_ParseBasicString(t_s n_i g_key "txg")  ; -> list
    ; 解析基本字符串（单行或三引号多行），处理 TOML 转义与行尾续行。
    ;
    ; **参数**
    ;   t_s    (str) - 输入串
    ;   n_i    (int) - 首个引号位置
    ;   g_key  (t|nil) - t 时按键解析，不接受三引号
    ;
    ; **返回**
    ;   (list) - (字符串值 闭引号后一位置)
    let((n_len n_k n_seg n_c n_run l_p g_done g_triple n_esc t_esc n_cp n_next n_probe)
        n_len = length(t_s)
        when(g_key && _Code(t_s n_i + 1) == 34 && _Code(t_s n_i + 2) == 34
            _Error(t_s n_i "triple-quoted keys are not allowed")
        )
        g_triple = !g_key && _Code(t_s n_i + 1) == 34 && _Code(t_s n_i + 2) == 34
        n_k = n_i + if(g_triple 3 1)
        when(g_triple && _Code(t_s n_k) == 10
            n_k = n_k + 1
        )
        n_seg = n_k
        g_done = nil
        while(!g_done
            when(n_k > n_len
                _Error(t_s n_k "unterminated string")
            )
            n_c = _Code(t_s n_k)
            cond(
                (n_c == 34
                    if(g_triple
                        {
                        n_run = 0
                        while(_Code(t_s n_k + n_run) == 34
                            n_run = n_run + 1
                        )
                        if(n_run >= 3
                            {
                            when(n_run > 5
                                _Error(t_s n_k "too many consecutive quotation marks")
                            )
                            when(n_seg < n_k
                                l_p = tconc(l_p substring(t_s n_seg n_k - n_seg))
                            )
                            for(n_q 1 n_run - 3
                                l_p = tconc(l_p "\"")
                            )
                            n_k = n_k + n_run
                            g_done = t
                            }
                            n_k = n_k + n_run
                        )
                        }
                        {
                        when(n_seg < n_k
                            l_p = tconc(l_p substring(t_s n_seg n_k - n_seg))
                        )
                        n_k = n_k + 1
                        g_done = t
                        }
                    )
                )
                (n_c == 92
                    {
                    when(n_seg < n_k
                        l_p = tconc(l_p substring(t_s n_seg n_k - n_seg))
                    )
                    n_esc = n_k
                    n_k = n_k + 1
                    when(n_k > n_len
                        _Error(t_s n_esc "unterminated escape")
                    )
                    n_c = _Code(t_s n_k)
                    if(g_triple && (n_c == 10 || n_c == 32 || n_c == 9)
                        {
                        n_probe = n_k
                        while(n_probe <= n_len
                            && (_Code(t_s n_probe) == 32 || _Code(t_s n_probe) == 9)
                            n_probe = n_probe + 1
                        )
                        unless(_Code(t_s n_probe) == 10
                            _Error(t_s n_esc "invalid escape")
                        )
                        n_k = n_probe + 1
                        while(n_k <= n_len
                            && (_Code(t_s n_k) == 32 || _Code(t_s n_k) == 9 || _Code(t_s n_k) == 10)
                            n_k = n_k + 1
                        )
                        n_seg = n_k
                        }
                        {
                        case(n_c
                            (34
                                {
                                t_esc = "\""
                                n_next = n_k + 1
                                }
                            )
                            (92
                                {
                                t_esc = "\\"
                                n_next = n_k + 1
                                }
                            )
                            (98
                                {
                                t_esc = intToChar(8)
                                n_next = n_k + 1
                                }
                            )
                            (116
                                {
                                t_esc = intToChar(9)
                                n_next = n_k + 1
                                }
                            )
                            (110
                                {
                                t_esc = intToChar(10)
                                n_next = n_k + 1
                                }
                            )
                            (102
                                {
                                t_esc = intToChar(12)
                                n_next = n_k + 1
                                }
                            )
                            (114
                                {
                                t_esc = intToChar(13)
                                n_next = n_k + 1
                                }
                            )
                            (117
                                {
                                n_cp = _ReadHex(t_s n_k + 1 4)
                                t_esc = _Utf8Str(n_cp)
                                n_next = n_k + 5
                                }
                            )
                            (85
                                {
                                n_cp = _ReadHex(t_s n_k + 1 8)
                                t_esc = _Utf8Str(n_cp)
                                n_next = n_k + 9
                                }
                            )
                            (t
                                _Error(t_s n_esc "invalid escape")
                            )
                        )
                        l_p = tconc(l_p t_esc)
                        n_k = n_next
                        n_seg = n_k
                        }
                    )
                    }
                )
                (t
                    when((n_c < 32 || n_c == 127) && n_c != 9 && !(g_triple && n_c == 10)
                        _Error(t_s n_k "control character in string")
                    )
                    n_k = n_k + 1
                )
            )
        )
        list(_Build(l_p) n_k)
    )
)

procedure(_ParseLiteralString(t_s n_i g_key "txg")  ; -> list
    ; 解析字面量字符串（单行或三引号多行），不处理反斜杠转义。
    ;
    ; **参数**
    ;   t_s    (str) - 输入串
    ;   n_i    (int) - 首个单引号位置
    ;   g_key  (t|nil) - t 时按键解析，不接受三引号
    ;
    ; **返回**
    ;   (list) - (字符串值 闭引号后一位置)
    let((n_len n_k n_seg n_c n_run l_p g_done g_triple)
        n_len = length(t_s)
        when(g_key && _Code(t_s n_i + 1) == 39 && _Code(t_s n_i + 2) == 39
            _Error(t_s n_i "triple-quoted keys are not allowed")
        )
        g_triple = !g_key && _Code(t_s n_i + 1) == 39 && _Code(t_s n_i + 2) == 39
        n_k = n_i + if(g_triple 3 1)
        when(g_triple && _Code(t_s n_k) == 10
            n_k = n_k + 1
        )
        n_seg = n_k
        g_done = nil
        while(!g_done
            when(n_k > n_len
                _Error(t_s n_k "unterminated literal string")
            )
            n_c = _Code(t_s n_k)
            if(n_c == 39
                if(g_triple
                    {
                    n_run = 0
                    while(_Code(t_s n_k + n_run) == 39
                        n_run = n_run + 1
                    )
                    if(n_run >= 3
                        {
                        when(n_run > 5
                            _Error(t_s n_k "too many consecutive quotation marks")
                        )
                        when(n_seg < n_k
                            l_p = tconc(l_p substring(t_s n_seg n_k - n_seg))
                        )
                        for(n_q 1 n_run - 3
                            l_p = tconc(l_p "'")
                        )
                        n_k = n_k + n_run
                        g_done = t
                        }
                        n_k = n_k + n_run
                    )
                    }
                    {
                    when(n_seg < n_k
                        l_p = tconc(l_p substring(t_s n_seg n_k - n_seg))
                    )
                    n_k = n_k + 1
                    g_done = t
                    }
                )
                {
                when((n_c < 32 || n_c == 127) && n_c != 9 && !(g_triple && n_c == 10)
                    _Error(t_s n_k "control character in literal string")
                )
                n_k = n_k + 1
                }
            )
        )
        list(_Build(l_p) n_k)
    )
)


; ---------- 数字 ----------

procedure(_IntValue(t_s n_i n_end "txx")  ; -> int
    ; 校验并转换 TOML 整数；超出 32 位 fixnum 范围报错。
    ;
    ; **参数**
    ;   t_s    (str) - 输入串
    ;   n_i    (int) - 起始位置
    ;   n_end  (int) - 结束位置（不含）
    ;
    ; **返回**
    ;   (int) - fixnum 值
    let((t_tok t_clean n_base n_pos n_v n_c n_sign)
        t_tok = substring(t_s n_i n_end - n_i)
        n_sign = 1
        when(_Code(t_tok 1) == 45 || _Code(t_tok 1) == 43
            when(_Code(t_tok 1) == 45
                n_sign = -1
            )
            t_tok = substring(t_tok 2)
        )
        n_base = 10
        when(_Code(t_tok 1) == 48 && length(t_tok) > 1
            case(_Code(t_tok 2)
                (120 n_base = 16)
                (111 n_base = 8)
                (98 n_base = 2)
            )
            when(n_base != 10
                t_tok = substring(t_tok 3)
            )
        )
        t_clean = pcreReplace(pcreCompile("_") t_tok "" 0)
        when(t_clean == ""
            _Error(t_s n_i "invalid integer")
        )
        if(n_base == 10
            {
            n_v = atof(t_clean)
            when(n_v > 2147483647
                unless(n_sign < 0 && t_clean == "2147483648"
                    _Error(t_s n_i "integer out of fixnum range")
                )
            )
            if(n_sign < 0 && t_clean == "2147483648"
                (-2147483647 - 1)
                {
                n_v = atoi(t_clean)
                when(n_sign < 0
                    n_v = -n_v
                )
                n_v
                }
            )
            }
            {
            n_v = 0
            n_pos = 1
            while(n_pos <= length(t_clean)
                n_c = _HexVal(_Code(t_clean n_pos))
                unless(n_c != nil && n_c < n_base
                    _Error(t_s n_i "invalid integer")
                )
                when(n_v > (2147483647 - n_base + 1) / n_base
                    _Error(t_s n_i "integer out of fixnum range")
                )
                n_v = n_v * n_base + n_c
                when(n_v > 2147483647
                    _Error(t_s n_i "integer out of fixnum range")
                )
                n_pos = n_pos + 1
            )
            n_v
            }
        )
    )
)

procedure(_ParseNumber(t_s n_i "tx")  ; -> list
    ; 解析 TOML 整数、浮点、inf 与 nan。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;   n_i  (int) - 起始位置
    ;
    ; **返回**
    ;   (list) - (数值 下一位置)
    let((n_len n_end n_c t_tok t_clean)
        n_len = length(t_s)
        n_end = n_i
        while(n_end <= n_len
            && !(_Code(t_s n_end) == 32
                || _Code(t_s n_end) == 9
                || _Code(t_s n_end) == 10
                || _Code(t_s n_end) == 35
                || _Code(t_s n_end) == 44
                || _Code(t_s n_end) == 93
                || _Code(t_s n_end) == 125)
            n_end = n_end + 1
        )
        t_tok = substring(t_s n_i n_end - n_i)
        cond(
            (pcreMatchp("^[+-]?inf\\z" t_tok)
                list(if(_Code(t_tok 1) == 45 -atof("1e999") atof("1e999")) n_end)
            )
            (pcreMatchp("^[+-]?nan\\z" t_tok)
                list(atof("nan") n_end)
            )
            (pcreMatchp("^[+-]?(?:0|[1-9](?:_?[0-9])*)\\z" t_tok)
                list(_IntValue(t_s n_i n_end) n_end)
            )
            (pcreMatchp("^0x[0-9A-Fa-f](?:_?[0-9A-Fa-f])*\\z" t_tok)
                list(_IntValue(t_s n_i n_end) n_end)
            )
            (pcreMatchp("^0o[0-7](?:_?[0-7])*\\z" t_tok)
                list(_IntValue(t_s n_i n_end) n_end)
            )
            (pcreMatchp("^0b[01](?:_?[01])*\\z" t_tok)
                list(_IntValue(t_s n_i n_end) n_end)
            )
            (pcreMatchp("^[+-]?(?:(?:0|[1-9](?:_?[0-9])*)\\.[0-9](?:_?[0-9])*(?:[eE][+-]?[0-9](?:_?[0-9])*)?|(?:0|[1-9](?:_?[0-9])*)[eE][+-]?[0-9](?:_?[0-9])*)\\z" t_tok)
                {
                t_clean = pcreReplace(pcreCompile("_") t_tok "" 0)
                list(atof(t_clean) n_end)
                }
            )
            (t
                _Error(t_s n_i "invalid value")
            )
        )
    )
)

unuseNamespace("ycToml")

; END
