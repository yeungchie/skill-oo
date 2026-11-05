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
    let((len v c d)
        len = length(t_s)
        when(n_i + 3 > len
            _Error(t_s len + 1 "invalid \\u escape")
        )
        v = 0
        for(k n_i n_i + 3
            c = _Code(t_s k)
            cond(
                (c >= 48 && c <= 57 d = c - 48)
                (c >= 97 && c <= 102 d = c - 87)
                (c >= 65 && c <= 70 d = c - 55)
                (t _Error(t_s k "invalid \\u escape"))
            )
            v = v * 16 + d
        )
        v
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
    let((len k c run esc p cp lo done)
        len = length(t_s)
        k = n_i + 1
        run = k
        done = nil
        while(!done
            when(k > len
                _Error(t_s k "unterminated string")
            )
            c = _Code(t_s k)
            case(c
                (34
                    when(run < k
                        p = tconc(p substring(t_s run k - run))
                    )
                    done = t
                )
                (92
                    {
                    when(run < k
                        p = tconc(p substring(t_s run k - run))
                    )
                    esc = k
                    k++
                    c = _Code(t_s k)
                    when(!c
                        _Error(t_s esc "unterminated string")
                    )
                    case(c
                        (34
                            {
                            p = tconc(p "\"")
                            k++
                            }
                        )
                        (92
                            {
                            p = tconc(p "\\")
                            k++
                            }
                        )
                        (47
                            {
                            p = tconc(p "/")
                            k++
                            }
                        )
                        (98
                            {
                            p = tconc(p strcat(intToChar(8)))
                            k++
                            }
                        )
                        (102
                            {
                            p = tconc(p strcat(intToChar(12)))
                            k++
                            }
                        )
                        (110
                            {
                            p = tconc(p strcat(intToChar(10)))
                            k++
                            }
                        )
                        (114
                            {
                            p = tconc(p strcat(intToChar(13)))
                            k++
                            }
                        )
                        (116
                            {
                            p = tconc(p strcat(intToChar(9)))
                            k++
                            }
                        )
                        (117
                            {
                            cp = _Hex4(t_s k + 1)
                            k = k + 5
                            when(cp >= 55296 && cp <= 56319
                                unless(_Code(t_s k) == 92 && _Code(t_s k + 1) == 117
                                    _Error(t_s esc "invalid surrogate pair")
                                )
                                lo = _Hex4(t_s k + 2)
                                unless(lo >= 56320 && lo <= 57343
                                    _Error(t_s esc "invalid surrogate pair")
                                )
                                cp = 65536 + (cp - 55296) * 1024 + lo - 56320
                                k = k + 6
                            )
                            when(cp >= 56320 && cp <= 57343
                                _Error(t_s esc "invalid surrogate pair")
                            )
                            p = tconc(p _Utf8Str(cp))
                            }
                        )
                        (t
                            _Error(t_s esc "invalid escape")
                        )
                    )
                    run = k
                    }
                )
                (t
                    if(c < 32
                        _Error(t_s k "control character in string")
                        k++
                    )
                )
            )
        )
        list(_Build(p) k + 1)
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
    let((len k c tok v num)
        len = length(t_s)
        k = n_i
        c = _Code(t_s k)
        when(c == 45
            k++
            c = _Code(t_s k)
        )
        cond(
            (c == 48
                k++
            )
            (c >= 49 && c <= 57
                k++
                while(k <= len && _Digitp(_Code(t_s k))
                    k++
                )
            )
            (t
                _Error(t_s n_i "invalid number")
            )
        )
        when(c == 48 && _Digitp(_Code(t_s k))
            _Error(t_s k "invalid number")
        )
        when(_Code(t_s k) == 46
            k++
            unless(_Digitp(_Code(t_s k))
                _Error(t_s n_i "invalid number")
            )
            while(k <= len && _Digitp(_Code(t_s k))
                k++
            )
        )
        c = _Code(t_s k)
        when(c == 101 || c == 69
            k++
            c = _Code(t_s k)
            when(c == 43 || c == 45
                k++
            )
            unless(_Digitp(_Code(t_s k))
                _Error(t_s n_i "invalid number")
            )
            while(k <= len && _Digitp(_Code(t_s k))
                k++
            )
        )
        tok = substring(t_s n_i k - n_i)
        if(pcreMatchp("[.eE]" tok)
        then
            list(atof(tok) k)
        else
            v = atof(tok)
            if(v >= (-2147483647 - 1) && v <= 2147483647
                num = atoi(tok)
                num = v
            )
            list(num k)
        )
    )
)


unuseNamespace("ycJson")

; END
