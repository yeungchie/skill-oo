useNamespace("ycJson")

; 解码默认嵌套深度上限：实测约 900 层触语言栈上界，取 800 留安全余量；可用 ?maxDepth 调整。
_maxDecodeDepth = 800


; ---------- 扫描器 ----------

procedure(_skipWs(t_s n_i g_relaxed "tng")  ; -> int
    ; 跳过空白（空格/制表/换行/回车）；jsonc 模式另跳 // 与 /* */ 注释。
    ;
    ; **参数**
    ;   t_s        (str) - 输入串
    ;   n_i        (int) - 起始位置
    ;   g_relaxed  (t|nil) - jsonc 放宽开关（注释）
    ;
    ; **返回**
    ;   (int) - 首个非空白非注释字符的位置；到串尾为 length+1
    let((n_len n_c g_stop n_close)
        n_len = length(t_s)
        g_stop = nil
        while(!g_stop && n_i <= n_len
            n_c = _code(t_s n_i)
            cond(
                (n_c == 32 || n_c == 9 || n_c == 10 || n_c == 13
                    n_i = n_i + 1
                )
                (g_relaxed && n_c == 47 && _code(t_s n_i + 1) == 47
                    n_i = n_i + 2
                    while(n_i <= n_len && _code(t_s n_i) != 10
                        n_i = n_i + 1
                    )
                )
                (g_relaxed && n_c == 47 && _code(t_s n_i + 1) == 42
                    n_close = n_i + 2
                    while(n_close <= n_len - 1 && !(_code(t_s n_close) == 42 && _code(t_s n_close + 1) == 47)
                        n_close = n_close + 1
                    )
                    if(n_close <= n_len - 1
                        n_i = n_close + 2
                        _error(t_s n_i "unterminated block comment")
                    )
                )
                (t
                    g_stop = t
                )
            )
        )
        n_i
    )
)

procedure(_hex4(t_s n_i "tn")  ; -> int
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
            _error(t_s n_len + 1 "invalid \\u escape")
        )
        n_v = 0
        for(n_k n_i n_i + 3
            n_c = _code(t_s n_k)
            cond(
                (n_c >= 48 && n_c <= 57 n_d = n_c - 48)
                (n_c >= 97 && n_c <= 102 n_d = n_c - 87)
                (n_c >= 65 && n_c <= 70 n_d = n_c - 55)
                (t _error(t_s n_k "invalid \\u escape"))
            )
            n_v = n_v * 16 + n_d
        )
        n_v
    )
)

procedure(_utf8Str(n_cp "n")  ; -> str
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

procedure(_string(t_s n_i "tn")  ; -> list
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
                _error(t_s n_k "unterminated string")
            )
            n_c = _code(t_s n_k)
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
                    n_c = _code(t_s n_k)
                    when(!n_c
                        _error(t_s n_esc "unterminated string")
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
                            n_cp = _hex4(t_s n_k + 1)
                            n_k = n_k + 5
                            when(n_cp >= 55296 && n_cp <= 56319
                                unless(_code(t_s n_k) == 92 && _code(t_s n_k + 1) == 117
                                    _error(t_s n_esc "invalid surrogate pair")
                                )
                                n_lo = _hex4(t_s n_k + 2)
                                unless(n_lo >= 56320 && n_lo <= 57343
                                    _error(t_s n_esc "invalid surrogate pair")
                                )
                                n_cp = 65536 + (n_cp - 55296) * 1024 + n_lo - 56320
                                n_k = n_k + 6
                            )
                            when(n_cp >= 56320 && n_cp <= 57343
                                _error(t_s n_esc "invalid surrogate pair")
                            )
                            l_p = tconc(l_p _utf8Str(n_cp))
                            }
                        )
                        (t
                            _error(t_s n_esc "invalid escape")
                        )
                    )
                    n_run = n_k
                    }
                )
                (t
                    if(n_c < 32
                        _error(t_s n_k "control character in string")
                        n_k = n_k + 1
                    )
                )
            )
        )
        list(_build(l_p) n_k + 1)
    )
)

procedure(_value(t_s n_i g_relaxed n_depth n_max "tngnn")  ; -> list
    ; 解析任意值：按首字符派发到字符串/对象/数组/字面量/数字。
    ;
    ; **参数**
    ;   t_s        (str) - 输入串
    ;   n_i        (int) - 值首字符位置
    ;   g_relaxed  (t|nil) - jsonc 放宽开关
    ;   n_depth    (int) - 当前嵌套深度（顶层值 0）
    ;   n_max      (int) - 最大嵌套深度
    ;
    ; **返回**
    ;   (list) - (值 下一位置)；深度超限或字符非法报错
    let((n_c)
        when(n_depth > n_max
            _error(t_s n_i lsprintf("nesting too deep (limit %d)" n_max))
        )
        n_c = _code(t_s n_i)
        when(!n_c
            _error(t_s n_i "unexpected end of input")
        )
        case(n_c
            (34 _string(t_s n_i))
            (123 _object(t_s n_i g_relaxed n_depth n_max))
            (91 _array(t_s n_i g_relaxed n_depth n_max))
            (116 _literal(t_s n_i))
            (102 _literal(t_s n_i))
            (110 _literal(t_s n_i))
            (t
                if(n_c == 45 || _digitp(n_c)
                    _number(t_s n_i)
                    _error(t_s n_i "unexpected character")
                )
            )
        )
    )
)

procedure(_object(t_s n_i g_relaxed n_depth n_max "tngnn")  ; -> list
    ; 解析对象：键值对写入 table（缺省标记 Missing）；jsonc 模式允许尾逗号。
    ;
    ; **参数**
    ;   t_s        (str) - 输入串
    ;   n_i        (int) - '{' 位置
    ;   g_relaxed  (t|nil) - jsonc 放宽开关
    ;   n_depth    (int) - 当前嵌套深度
    ;   n_max      (int) - 最大嵌套深度
    ;
    ; **返回**
    ;   (list) - (table 闭括号后一位置)
    let((n_k n_c l_r t_key t_obj g_done)
        n_k = _skipWs(t_s n_i + 1 g_relaxed)
        t_obj = makeTable("ycJson" Missing)
        g_done = nil
        when(_code(t_s n_k) == 125
            g_done = t
            n_k = n_k + 1
        )
        while(!g_done
            n_k = _skipWs(t_s n_k g_relaxed)
            unless(_code(t_s n_k) == 34
                _error(t_s n_k "expected string key")
            )
            l_r = _string(t_s n_k)
            t_key = car(l_r)
            n_k = _skipWs(t_s cadr(l_r) g_relaxed)
            unless(_code(t_s n_k) == 58
                _error(t_s n_k "expected ':'")
            )
            n_k = _skipWs(t_s n_k + 1 g_relaxed)
            l_r = _value(t_s n_k g_relaxed n_depth + 1 n_max)
            t_obj[t_key] = car(l_r)
            n_k = _skipWs(t_s cadr(l_r) g_relaxed)
            n_c = _code(t_s n_k)
            case(n_c
                (125
                    {
                    g_done = t
                    n_k = n_k + 1
                    }
                )
                (44
                    {
                    n_k = _skipWs(t_s n_k + 1 g_relaxed)
                    when(g_relaxed && _code(t_s n_k) == 125
                        g_done = t
                        n_k = n_k + 1
                    )
                    }
                )
                (t
                    _error(t_s n_k "expected ',' or '}'")
                )
            )
        )
        list(t_obj n_k)
    )
)

procedure(_array(t_s n_i g_relaxed n_depth n_max "tngnn")  ; -> list
    ; 解析数组：元素累积为 list（空数组即 nil）；jsonc 模式允许尾逗号。
    ;
    ; **参数**
    ;   t_s        (str) - 输入串
    ;   n_i        (int) - '[' 位置
    ;   g_relaxed  (t|nil) - jsonc 放宽开关
    ;   n_depth    (int) - 当前嵌套深度
    ;   n_max      (int) - 最大嵌套深度
    ;
    ; **返回**
    ;   (list) - (列表或 nil 闭括号后一位置)
    let((n_k n_c l_res l_r g_done)
        n_k = _skipWs(t_s n_i + 1 g_relaxed)
        l_res = nil
        g_done = nil
        when(_code(t_s n_k) == 93
            g_done = t
            n_k = n_k + 1
        )
        while(!g_done
            n_k = _skipWs(t_s n_k g_relaxed)
            l_r = _value(t_s n_k g_relaxed n_depth + 1 n_max)
            l_res = tconc(l_res car(l_r))
            n_k = _skipWs(t_s cadr(l_r) g_relaxed)
            n_c = _code(t_s n_k)
            case(n_c
                (93
                    {
                    g_done = t
                    n_k = n_k + 1
                    }
                )
                (44
                    {
                    n_k = _skipWs(t_s n_k + 1 g_relaxed)
                    when(g_relaxed && _code(t_s n_k) == 93
                        g_done = t
                        n_k = n_k + 1
                    )
                    }
                )
                (t
                    _error(t_s n_k "expected ',' or ']'")
                )
            )
        )
        list(car(l_res) n_k)
    )
)

procedure(_decodeText(t_s g_relaxed n_max "tgn")  ; -> any
    ; 解析单个 JSON 文档：前导/尾随空白允许，尾随非空白字符报错。
    ;
    ; **参数**
    ;   t_s        (str) - 输入串
    ;   g_relaxed  (t|nil) - jsonc 放宽开关
    ;   n_max      (int) - 最大嵌套深度
    ;
    ; **返回**
    ;   (any) - 解析产物
    let((n_k l_r g_val)
        n_k = _skipWs(t_s 1 g_relaxed)
        l_r = _value(t_s n_k g_relaxed 0 n_max)
        g_val = car(l_r)
        n_k = _skipWs(t_s cadr(l_r) g_relaxed)
        when(n_k <= length(t_s)
            _error(t_s n_k "unexpected trailing characters")
        )
        g_val
    )
)

procedure(decode(t_str \@key (format "json") (maxDepth nil) "ttg")  ; -> any | list
    ; 解码文本：?format 选 "json"（严格单文档）、"jsonc"（注释与尾逗号放宽）或 "jsonl"（逐行）。
    ;
    ; **参数**
    ;   t_str     (str) - 输入文本
    ;   ?format   (str) - 格式；默认 "json"
    ;   ?maxDepth (int) - 最大嵌套深度；默认 1000
    ;
    ; **返回**
    ;   (any|list) - 解码产物；"jsonl" 返回按行序的列表
    unless(stringp(t_str)
        error("ycJson::decode: expects a string")
    )
    when(maxDepth == nil
        maxDepth = _maxDecodeDepth
    )
    unless(fixp(maxDepth) && maxDepth >= 1
        error("ycJson::decode: ?maxDepth must be a positive fixnum")
    )
    case(format
        ("json" _decodeText(t_str nil maxDepth))
        ("jsonc" _decodeText(t_str t maxDepth))
        ("jsonl" _decodeLines(t_str maxDepth))
        (t
            error("ycJson::decode: unknown format %A" format)
        )
    )
)

unuseNamespace("ycJson")

; END
