ycNamespace:::Require("ycCodec")

useNamespace("ycJson")

; 解码默认嵌套深度上限：实测约 900 层触语言栈上界，取 800 留安全余量；可用 ?maxDepth 调整。
_MaxDecodeDepth = 800


; ---------- 结构扫描 ----------

procedure(_SkipWs(t_s n_i g_relaxed "txg")  ; -> int
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
            n_c = _Code(t_s n_i)
            cond(
                (n_c == 32 || n_c == 9 || n_c == 10 || n_c == 13
                    n_i = n_i + 1
                )
                (g_relaxed && n_c == 47 && _Code(t_s n_i + 1) == 47
                    n_i = n_i + 2
                    while(n_i <= n_len && _Code(t_s n_i) != 10
                        n_i = n_i + 1
                    )
                )
                (g_relaxed && n_c == 47 && _Code(t_s n_i + 1) == 42
                    n_close = n_i + 2
                    while(n_close <= n_len - 1 && !(_Code(t_s n_close) == 42 && _Code(t_s n_close + 1) == 47)
                        n_close = n_close + 1
                    )
                    if(n_close <= n_len - 1
                        n_i = n_close + 2
                        _Error(t_s n_i "unterminated block comment")
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

procedure(_Value(t_s n_i g_relaxed n_depth n_max "txgxx")  ; -> list
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
            _Error(t_s n_i lsprintf("nesting too deep (limit %d)" n_max))
        )
        n_c = _Code(t_s n_i)
        when(!n_c
            _Error(t_s n_i "unexpected end of input")
        )
        case(n_c
            (34 _String(t_s n_i))
            (123 _Object(t_s n_i g_relaxed n_depth n_max))
            (91 _Array(t_s n_i g_relaxed n_depth n_max))
            (116 _Literal(t_s n_i))
            (102 _Literal(t_s n_i))
            (110 _Literal(t_s n_i))
            (t
                if(n_c == 45 || _Digitp(n_c)
                    _Number(t_s n_i)
                    _Error(t_s n_i "unexpected character")
                )
            )
        )
    )
)

procedure(_Object(t_s n_i g_relaxed n_depth n_max "txgxx")  ; -> list
    ; 解析对象：键值对写入 table（缺省标记 ycCodec::Missing）；jsonc 模式允许尾逗号。
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
        n_k = _SkipWs(t_s n_i + 1 g_relaxed)
        t_obj = makeTable("ycJson" ycCodec:::Missing)
        g_done = nil
        when(_Code(t_s n_k) == 125
            g_done = t
            n_k = n_k + 1
        )
        while(!g_done
            n_k = _SkipWs(t_s n_k g_relaxed)
            unless(_Code(t_s n_k) == 34
                _Error(t_s n_k "expected string key")
            )
            l_r = _String(t_s n_k)
            t_key = car(l_r)
            n_k = _SkipWs(t_s cadr(l_r) g_relaxed)
            unless(_Code(t_s n_k) == 58
                _Error(t_s n_k "expected ':'")
            )
            n_k = _SkipWs(t_s n_k + 1 g_relaxed)
            l_r = _Value(t_s n_k g_relaxed n_depth + 1 n_max)
            t_obj[t_key] = car(l_r)
            n_k = _SkipWs(t_s cadr(l_r) g_relaxed)
            n_c = _Code(t_s n_k)
            case(n_c
                (125
                    {
                    g_done = t
                    n_k = n_k + 1
                    }
                )
                (44
                    {
                    n_k = _SkipWs(t_s n_k + 1 g_relaxed)
                    when(g_relaxed && _Code(t_s n_k) == 125
                        g_done = t
                        n_k = n_k + 1
                    )
                    }
                )
                (t
                    _Error(t_s n_k "expected ',' or '}'")
                )
            )
        )
        list(t_obj n_k)
    )
)

procedure(_Array(t_s n_i g_relaxed n_depth n_max "txgxx")  ; -> list
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
        n_k = _SkipWs(t_s n_i + 1 g_relaxed)
        l_res = nil
        g_done = nil
        when(_Code(t_s n_k) == 93
            g_done = t
            n_k = n_k + 1
        )
        while(!g_done
            n_k = _SkipWs(t_s n_k g_relaxed)
            l_r = _Value(t_s n_k g_relaxed n_depth + 1 n_max)
            l_res = tconc(l_res car(l_r))
            n_k = _SkipWs(t_s cadr(l_r) g_relaxed)
            n_c = _Code(t_s n_k)
            case(n_c
                (93
                    {
                    g_done = t
                    n_k = n_k + 1
                    }
                )
                (44
                    {
                    n_k = _SkipWs(t_s n_k + 1 g_relaxed)
                    when(g_relaxed && _Code(t_s n_k) == 93
                        g_done = t
                        n_k = n_k + 1
                    )
                    }
                )
                (t
                    _Error(t_s n_k "expected ',' or ']'")
                )
            )
        )
        list(car(l_res) n_k)
    )
)

procedure(_DecodeText(t_s g_relaxed n_max "tgx")  ; -> any
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
        n_k = _SkipWs(t_s 1 g_relaxed)
        l_r = _Value(t_s n_k g_relaxed 0 n_max)
        g_val = car(l_r)
        n_k = _SkipWs(t_s cadr(l_r) g_relaxed)
        when(n_k <= length(t_s)
            _Error(t_s n_k "unexpected trailing characters")
        )
        g_val
    )
)

procedure(Decode(t_str \@key (format "json") (maxDepth nil) "ttg")  ; -> any | list
    ; 解码文本：?format 选 "json"（严格单文档）、"jsonc"（注释与尾逗号放宽）或 "jsonl"（逐行）。
    ;
    ; **参数**
    ;   t_str     (str) - 输入文本
    ;   ?format   (str) - 格式；默认 "json"
    ;   ?maxDepth (int) - 最大嵌套深度；默认 800
    ;
    ; **返回**
    ;   (any|list) - 解码产物；"jsonl" 返回按行序的列表
    unless(stringp(t_str)
        error("ycJson::Decode: expects a string")
    )
    when(maxDepth == nil
        maxDepth = _MaxDecodeDepth
    )
    unless(fixp(maxDepth) && maxDepth >= 1
        error("ycJson::Decode: ?maxDepth must be a positive fixnum")
    )
    case(format
        ("json" _DecodeText(t_str nil maxDepth))
        ("jsonc" _DecodeText(t_str t maxDepth))
        ("jsonl" _DecodeLines(t_str maxDepth))
        (t
            error("ycJson::Decode: unknown format %A" format)
        )
    )
)

unuseNamespace("ycJson")

; END
