ycNamespace:::Require("ycCodec")

useNamespace("ycJson")


; ---------- 标量值解析（字符串/数字/字面量） ----------

procedure(_Hex4(t_s n_i "tx")  ; -> int
    ; 解析 \uXXXX 的 4 位十六进制（大小写均可）。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;   n_i  (int) - 首个十六进制位的位置
    ;
    ; **返回**
    ;   (int) - 0..65535 的码元值
    let((n_len n_v n_c n_d)
        n_len = length(t_s)
        when(n_i + 3 > n_len
            _Error(t_s n_len + 1 "invalid \\u escape")
        )
        n_v = 0
        for(n_k n_i n_i + 3
            n_c = _Code(t_s n_k)
            cond(
                (n_c >= 48 && n_c <= 57 n_d = n_c - 48)
                (n_c >= 97 && n_c <= 102 n_d = n_c - 87)
                (n_c >= 65 && n_c <= 70 n_d = n_c - 55)
                (t _Error(t_s n_k "invalid \\u escape"))
            )
            n_v = n_v * 16 + n_d
        )
        n_v
    )
)

procedure(_Utf8Str(n_cp "x")  ; -> str
    ; 将 Unicode 码点编码为 UTF-8 字节串（1..4 字节，逐字节拼接）。
    ;
    ; **参数**
    ;   n_cp  (int) - 0..0x10FFFF 的码点
    ;
    ; **返回**
    ;   (str) - UTF-8 字节串
    cond(
        (n_cp < 128
            strcat(intToChar(n_cp))
        )
        (n_cp < 2048
            strcat(intToChar(192 + n_cp/64) intToChar(128 + remainder(n_cp 64)))
        )
        (n_cp < 65536
            strcat(
                intToChar(224 + n_cp/4096)
                intToChar(128 + remainder(n_cp/64 64))
                intToChar(128 + remainder(n_cp 64))
            )
        )
        (t
            strcat(
                intToChar(240 + n_cp/262144)
                intToChar(128 + remainder(n_cp/4096 64))
                intToChar(128 + remainder(n_cp/64 64))
                intToChar(128 + remainder(n_cp 64))
            )
        )
    )
)

procedure(_String(t_s n_i "tx")  ; -> list
    ; 扫描字符串：转义解出实际字符，\uXXXX 合成 UTF-8，代理对合并，孤立代理项报错。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;   n_i  (int) - 起始引号位置
    ;
    ; **返回**
    ;   (list) - (字符串值 闭引号后一位置)
    let((n_len n_k n_c n_run n_esc l_p n_cp n_lo g_done)
        n_len = length(t_s)
        n_k = n_i + 1
        n_run = n_k
        g_done = nil
        while(!g_done
            when(n_k > n_len
                _Error(t_s n_k "unterminated string")
            )
            n_c = _Code(t_s n_k)
            case(n_c
                (34
                    when(n_run < n_k
                        l_p = tconc(l_p substring(t_s n_run n_k - n_run))
                    )
                    g_done = t
                )
                (92
                    {
                    when(n_run < n_k
                        l_p = tconc(l_p substring(t_s n_run n_k - n_run))
                    )
                    n_esc = n_k
                    n_k = n_k + 1
                    n_c = _Code(t_s n_k)
                    when(!n_c
                        _Error(t_s n_esc "unterminated string")
                    )
                    case(n_c
                        (34
                            {
                            l_p = tconc(l_p "\"")
                            n_k = n_k + 1
                            }
                        )
                        (92
                            {
                            l_p = tconc(l_p "\\")
                            n_k = n_k + 1
                            }
                        )
                        (47
                            {
                            l_p = tconc(l_p "/")
                            n_k = n_k + 1
                            }
                        )
                        (98
                            {
                            l_p = tconc(l_p strcat(intToChar(8)))
                            n_k = n_k + 1
                            }
                        )
                        (102
                            {
                            l_p = tconc(l_p strcat(intToChar(12)))
                            n_k = n_k + 1
                            }
                        )
                        (110
                            {
                            l_p = tconc(l_p strcat(intToChar(10)))
                            n_k = n_k + 1
                            }
                        )
                        (114
                            {
                            l_p = tconc(l_p strcat(intToChar(13)))
                            n_k = n_k + 1
                            }
                        )
                        (116
                            {
                            l_p = tconc(l_p strcat(intToChar(9)))
                            n_k = n_k + 1
                            }
                        )
                        (117
                            {
                            n_cp = _Hex4(t_s n_k + 1)
                            n_k = n_k + 5
                            when(n_cp >= 55296 && n_cp <= 56319
                                unless(_Code(t_s n_k) == 92 && _Code(t_s n_k + 1) == 117
                                    _Error(t_s n_esc "invalid surrogate pair")
                                )
                                n_lo = _Hex4(t_s n_k + 2)
                                unless(n_lo >= 56320 && n_lo <= 57343
                                    _Error(t_s n_esc "invalid surrogate pair")
                                )
                                n_cp = 65536 + (n_cp - 55296) * 1024 + n_lo - 56320
                                n_k = n_k + 6
                            )
                            when(n_cp >= 56320 && n_cp <= 57343
                                _Error(t_s n_esc "invalid surrogate pair")
                            )
                            l_p = tconc(l_p _Utf8Str(n_cp))
                            }
                        )
                        (t
                            _Error(t_s n_esc "invalid escape")
                        )
                    )
                    n_run = n_k
                    }
                )
                (t
                    if(n_c < 32
                        _Error(t_s n_k "control character in string")
                        n_k = n_k + 1
                    )
                )
            )
        )
        list(_Build(l_p) n_k + 1)
    )
)

procedure(_Literal(t_s n_i "tx")  ; -> list
    ; 在位置处匹配 true/false/null 字面量（大小写敏感）。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;   n_i  (int) - 字面量首字符位置
    ;
    ; **返回**
    ;   (list) - (值 下一位置)；值分别为 ycCodec::True、ycCodec::False、ycCodec::Null
    cond(
        (substring(t_s n_i 4) == "true"
            list(ycCodec:::True n_i + 4)
        )
        (substring(t_s n_i 5) == "false"
            list(ycCodec:::False n_i + 5)
        )
        (substring(t_s n_i 4) == "null"
            list(ycCodec:::Null n_i + 4)
        )
        (t
            _Error(t_s n_i "invalid literal")
        )
    )
)

procedure(_Number(t_s n_i "tx")  ; -> list
    ; 按 JSON 语法扫描数字：严格校验整数/小数/指数写法，超 fixnum 范围回 flonum。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;   n_i  (int) - 数字首字符位置（'-' 或数字）
    ;
    ; **返回**
    ;   (list) - (数值 下一位置)；整数走 fixnum（范围内），否则 flonum
    let((n_len n_k n_c t_tok n_v g_num)
        n_len = length(t_s)
        n_k = n_i
        n_c = _Code(t_s n_k)
        when(n_c == 45
            n_k = n_k + 1
            n_c = _Code(t_s n_k)
        )
        cond(
            (n_c == 48
                n_k = n_k + 1
            )
            (n_c >= 49 && n_c <= 57
                n_k = n_k + 1
                while(n_k <= n_len && _Digitp(_Code(t_s n_k))
                    n_k = n_k + 1
                )
            )
            (t
                _Error(t_s n_i "invalid number")
            )
        )
        when(n_c == 48 && _Digitp(_Code(t_s n_k))
            _Error(t_s n_k "invalid number")
        )
        when(_Code(t_s n_k) == 46
            n_k = n_k + 1
            unless(_Digitp(_Code(t_s n_k))
                _Error(t_s n_i "invalid number")
            )
            while(n_k <= n_len && _Digitp(_Code(t_s n_k))
                n_k = n_k + 1
            )
        )
        n_c = _Code(t_s n_k)
        when(n_c == 101 || n_c == 69
            n_k = n_k + 1
            n_c = _Code(t_s n_k)
            when(n_c == 43 || n_c == 45
                n_k = n_k + 1
            )
            unless(_Digitp(_Code(t_s n_k))
                _Error(t_s n_i "invalid number")
            )
            while(n_k <= n_len && _Digitp(_Code(t_s n_k))
                n_k = n_k + 1
            )
        )
        t_tok = substring(t_s n_i n_k - n_i)
        if(pcreMatchp("[.eE]" t_tok)
            list(atof(t_tok) n_k)
            {
            n_v = atof(t_tok)
            if(n_v >= (-2147483647 - 1) && n_v <= 2147483647
                g_num = atoi(t_tok)
                g_num = n_v
            )
            list(g_num n_k)
            }
        )
    )
)


unuseNamespace("ycJson")

; END
