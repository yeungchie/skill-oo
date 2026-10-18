useNamespace("ycJson")

; 解码默认嵌套深度上限：实测约 900 层触语言栈上界，取 800 留安全余量；可用 ?maxDepth 调整。
_maxDecodeDepth = 800


; ---------- 结构扫描 ----------

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
