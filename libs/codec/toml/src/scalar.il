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
    let((v d c)
        v = 0
        for(k 1 n_count
            c = _HexVal(_Code(t_s n_i + k - 1))
            unless(c
                _Error(t_s n_i + k - 1 "invalid hexadecimal escape")
            )
            v = v * 16 + c
        )
        v
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
    let((len k seg c run p done triple esc esc2 cp next probe)
        len = length(t_s)
        when(g_key && _Code(t_s n_i + 1) == 34 && _Code(t_s n_i + 2) == 34
            _Error(t_s n_i "triple-quoted keys are not allowed")
        )
        triple = !g_key && _Code(t_s n_i + 1) == 34 && _Code(t_s n_i + 2) == 34
        k = n_i + if(triple 3 1)
        when(triple && _Code(t_s k) == 10
            k++
        )
        seg = k
        done = nil
        while(!done
            when(k > len
                _Error(t_s k "unterminated string")
            )
            c = _Code(t_s k)
            cond(
                (c == 34
                    if(triple
                    then
                        run = 0
                        while(_Code(t_s k + run) == 34
                            run++
                        )
                        if(run >= 3
                        then
                            when(run > 5
                                _Error(t_s k "too many consecutive quotation marks")
                            )
                            when(seg < k
                                p = tconc(p substring(t_s seg k - seg))
                            )
                            for(q 1 run - 3
                                p = tconc(p "\"")
                            )
                            k = k + run
                            done = t
                        else
                            k = k + run
                        )
                    else
                        when(seg < k
                            p = tconc(p substring(t_s seg k - seg))
                        )
                        k++
                        done = t
                    )
                )
                (c == 92
                    {
                    when(seg < k
                        p = tconc(p substring(t_s seg k - seg))
                    )
                    esc = k
                    k++
                    when(k > len
                        _Error(t_s esc "unterminated escape")
                    )
                    c = _Code(t_s k)
                    if(triple && (c == 10 || c == 32 || c == 9)
                    then
                        probe = k
                        while(probe <= len
                            && (_Code(t_s probe) == 32 || _Code(t_s probe) == 9)
                            probe++
                        )
                        unless(_Code(t_s probe) == 10
                            _Error(t_s esc "invalid escape")
                        )
                        k = probe + 1
                        while(k <= len
                            && (_Code(t_s k) == 32 || _Code(t_s k) == 9 || _Code(t_s k) == 10)
                            k++
                        )
                        seg = k
                    else
                        case(c
                            (34
                                {
                                esc2 = "\""
                                next = k + 1
                                }
                            )
                            (92
                                {
                                esc2 = "\\"
                                next = k + 1
                                }
                            )
                            (98
                                {
                                esc2 = intToChar(8)
                                next = k + 1
                                }
                            )
                            (116
                                {
                                esc2 = intToChar(9)
                                next = k + 1
                                }
                            )
                            (110
                                {
                                esc2 = intToChar(10)
                                next = k + 1
                                }
                            )
                            (102
                                {
                                esc2 = intToChar(12)
                                next = k + 1
                                }
                            )
                            (114
                                {
                                esc2 = intToChar(13)
                                next = k + 1
                                }
                            )
                            (117
                                {
                                cp = _ReadHex(t_s k + 1 4)
                                esc2 = _Utf8Str(cp)
                                next = k + 5
                                }
                            )
                            (85
                                {
                                cp = _ReadHex(t_s k + 1 8)
                                esc2 = _Utf8Str(cp)
                                next = k + 9
                                }
                            )
                            (t
                                _Error(t_s esc "invalid escape")
                            )
                        )
                        p = tconc(p esc2)
                        k = next
                        seg = k
                    )
                    }
                )
                (t
                    when((c < 32 || c == 127) && c != 9 && !(triple && c == 10)
                        _Error(t_s k "control character in string")
                    )
                    k++
                )
            )
        )
        list(_Build(p) k)
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
    let((len k seg c run p done triple)
        len = length(t_s)
        when(g_key && _Code(t_s n_i + 1) == 39 && _Code(t_s n_i + 2) == 39
            _Error(t_s n_i "triple-quoted keys are not allowed")
        )
        triple = !g_key && _Code(t_s n_i + 1) == 39 && _Code(t_s n_i + 2) == 39
        k = n_i + if(triple 3 1)
        when(triple && _Code(t_s k) == 10
            k++
        )
        seg = k
        done = nil
        while(!done
            when(k > len
                _Error(t_s k "unterminated literal string")
            )
            c = _Code(t_s k)
            if(c == 39
            then
                if(triple
                then
                    run = 0
                    while(_Code(t_s k + run) == 39
                        run++
                    )
                    if(run >= 3
                    then
                        when(run > 5
                            _Error(t_s k "too many consecutive quotation marks")
                        )
                        when(seg < k
                            p = tconc(p substring(t_s seg k - seg))
                        )
                        for(q 1 run - 3
                            p = tconc(p "'")
                        )
                        k = k + run
                        done = t
                    else
                        k = k + run
                    )
                else
                    when(seg < k
                        p = tconc(p substring(t_s seg k - seg))
                    )
                    k++
                    done = t
                )
            else
                when((c < 32 || c == 127) && c != 9 && !(triple && c == 10)
                    _Error(t_s k "control character in literal string")
                )
                k++
            )
        )
        list(_Build(p) k)
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
    let((tok clean base pos v c sign)
        tok = substring(t_s n_i n_end - n_i)
        sign = 1
        when(_Code(tok 1) == 45 || _Code(tok 1) == 43
            when(_Code(tok 1) == 45
                sign = -1
            )
            tok = substring(tok 2)
        )
        base = 10
        when(_Code(tok 1) == 48 && length(tok) > 1
            case(_Code(tok 2)
                (120 base = 16)
                (111 base = 8)
                (98 base = 2)
            )
            when(base != 10
                tok = substring(tok 3)
            )
        )
        clean = pcreReplace(pcreCompile("_") tok "" 0)
        when(clean == ""
            _Error(t_s n_i "invalid integer")
        )
        if(base == 10
        then
            v = atof(clean)
            when(v > 2147483647
                unless(sign < 0 && clean == "2147483648"
                    _Error(t_s n_i "integer out of fixnum range")
                )
            )
            if(sign < 0 && clean == "2147483648"
            then
                (-2147483647 - 1)
            else
                v = atoi(clean)
                when(sign < 0
                    v = -v
                )
                v
            )
        else
            v = 0
            pos = 1
            while(pos <= length(clean)
                c = _HexVal(_Code(clean pos))
                unless(c != nil && c < base
                    _Error(t_s n_i "invalid integer")
                )
                when(v > (2147483647 - base + 1) / base
                    _Error(t_s n_i "integer out of fixnum range")
                )
                v = v * base + c
                when(v > 2147483647
                    _Error(t_s n_i "integer out of fixnum range")
                )
                pos++
            )
            v
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
    let((len end c tok clean)
        len = length(t_s)
        end = n_i
        while(end <= len
            && !(_Code(t_s end) == 32
                || _Code(t_s end) == 9
                || _Code(t_s end) == 10
                || _Code(t_s end) == 35
                || _Code(t_s end) == 44
                || _Code(t_s end) == 93
                || _Code(t_s end) == 125)
            end++
        )
        tok = substring(t_s n_i end - n_i)
        cond(
            (pcreMatchp("^[+-]?inf\\z" tok)
                list(if(_Code(tok 1) == 45 -atof("1e999") atof("1e999")) end)
            )
            (pcreMatchp("^[+-]?nan\\z" tok)
                list(atof("nan") end)
            )
            (pcreMatchp("^[+-]?(?:0|[1-9](?:_?[0-9])*)\\z" tok)
                list(_IntValue(t_s n_i end) end)
            )
            (pcreMatchp("^0x[0-9A-Fa-f](?:_?[0-9A-Fa-f])*\\z" tok)
                list(_IntValue(t_s n_i end) end)
            )
            (pcreMatchp("^0o[0-7](?:_?[0-7])*\\z" tok)
                list(_IntValue(t_s n_i end) end)
            )
            (pcreMatchp("^0b[01](?:_?[01])*\\z" tok)
                list(_IntValue(t_s n_i end) end)
            )
            (pcreMatchp("^[+-]?(?:(?:0|[1-9](?:_?[0-9])*)\\.[0-9](?:_?[0-9])*(?:[eE][+-]?[0-9](?:_?[0-9])*)?|(?:0|[1-9](?:_?[0-9])*)[eE][+-]?[0-9](?:_?[0-9])*)\\z" tok)
                {
                clean = pcreReplace(pcreCompile("_") tok "" 0)
                list(atof(clean) end)
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
