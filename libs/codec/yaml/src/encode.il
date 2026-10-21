ycNamespace:::require("ycCodec")

useNamespace("ycYaml")

; ---------- 编码 ----------

procedure(_indentStr(n_level n_indent "xx")  ; -> str
    ; 生成 n_level 层、每层 n_indent 个空格的缩进串。
    ;
    ; **参数**
    ;   n_level   (int) - 层数
    ;   n_indent  (int) - 每层空格数
    ;
    ; **返回**
    ;   (str) - 缩进空白串
    let((t_s n_i)
        t_s = ""
        when(0 < n_level && 0 < n_indent
            for(n_i 1 n_level * n_indent
                t_s = strcat(t_s " ")
            )
        )
        t_s
    )
)

procedure(_plainSafe(t_s "t")  ; -> t | nil
    ; 判断字符串能否安全地作为普通标量输出（不改变类型）。
    ;
    ; **参数**
    ;   t_s  (str) - 待检查字符串
    ;
    ; **返回**
    ;   (t|nil) - 可安全输出为 t
    prog((n_len n_c n_i g_bad)
        n_len = length(t_s)
        when(n_len == 0
            return(nil)
        )
        n_c = _code(t_s 1)
        when(n_c == 32 || n_c == 9 || n_c == 10 || n_c == 13
            return(nil)
        )
        n_c = _code(t_s n_len)
        when(n_c == 32 || n_c == 9 || n_c == 10 || n_c == 13
            return(nil)
        )
        when(_specialStart(_code(t_s 1))
            return(nil)
        )
        when(_code(t_s 1) == 45 || _code(t_s 1) == 63 || _code(t_s 1) == 58
            return(nil)
        )
        g_bad = nil
        for(n_i 1 n_len
            n_c = _code(t_s n_i)
            cond(
                (n_c == 10 || n_c == 13 || n_c == 9
                    g_bad = t
                )
                (n_c < 32
                    g_bad = t
                )
                (n_c == 35 && n_i > 1 && (_code(t_s n_i - 1) == 32 || _code(t_s n_i - 1) == 9)
                    g_bad = t
                )
                (n_c == 58 && n_i < n_len && (_code(t_s n_i + 1) == 32 || _code(t_s n_i + 1) == 9)
                    g_bad = t
                )
            )
        )
        when(g_bad
            return(nil)
        )
        return(_resolvePlain(t_s) == t_s)
    )
)

procedure(_specialStart(n_c "x")  ; -> t | nil
    ; 判断字符码是否为普通标量禁用起始字符。
    ;
    ; **参数**
    ;   n_c  (int) - 字符码
    ;
    ; **返回**
    ;   (t|nil) - 是危险起始字符时为 t
    n_c == 91 || n_c == 93 || n_c == 123 || n_c == 125
        || n_c == 35 || n_c == 38 || n_c == 42 || n_c == 33
        || n_c == 124 || n_c == 62 || n_c == 39 || n_c == 34
        || n_c == 37 || n_c == 64 || n_c == 96 || n_c == 44
)

procedure(_encodeString(t_s "t")  ; -> str
    ; 输出带双引号的 YAML 字符串，转义控制字符与引号/反斜杠。
    ;
    ; **参数**
    ;   t_s  (str) - 待输出字符串
    ;
    ; **返回**
    ;   (str) - 带双引号的 YAML 字符串
    let((n_len n_i n_c l_p n_run)
        n_len = length(t_s)
        n_run = 1
        for(n_i 1 n_len
            n_c = _code(t_s n_i)
            when(n_c == 34 || n_c == 92 || n_c < 32
                when(n_run < n_i
                    l_p = tconc(l_p substring(t_s n_run n_i - n_run))
                )
                l_p = tconc(l_p
                    case(n_c
                        (34 "\\\"")
                        (92 "\\\\")
                        (8 "\\b")
                        (12 "\\f")
                        (10 "\\n")
                        (13 "\\r")
                        (9 "\\t")
                        (t sprintf(nil "\\u%04x" n_c))
                    )
                )
                n_run = n_i + 1
            )
        )
        when(n_run <= n_len
            l_p = tconc(l_p substring(t_s n_run n_len - n_run + 1))
        )
        lsprintf("\"%s\"" _build(l_p))
    )
)

procedure(_encodeKey(g_key g_opt "gg")  ; -> str
    ; 将 table 键转为 YAML 映射键文本。
    ;
    ; **参数**
    ;   g_key  (any) - 键值
    ;   g_opt  (table) - 编码选项
    ;
    ; **返回**
    ;   (str) - 键文本
    let((t_s)
        when(g_opt["strict"] && !stringp(g_key)
            error("ycYaml::encode: strict mode requires string keys, got %A" g_key)
        )
        t_s = cond(
            (stringp(g_key) g_key)
            (symbolp(g_key) symbolToString(g_key))
            (fixp(g_key) sprintf(nil "%d" g_key))
        )
        unless(t_s
            error("ycYaml::encode: unsupported table key of type %s" symbolToString(type(g_key)))
        )
        if(fixp(g_key)
            t_s
            if(_plainSafe(t_s) && !pcreMatchp("[ 	]" t_s)
                t_s
                _encodeString(t_s)
            )
        )
    )
)

procedure(_numText(g_n "g")  ; -> str
    ; 输出 YAML 数字文本；非有限浮点输出 .inf/-.inf/.nan。
    ;
    ; **参数**
    ;   g_n  (num) - fixnum 或 flonum
    ;
    ; **返回**
    ;   (str) - 数字文本
    if(fixp(g_n)
        sprintf(nil "%d" g_n)
        cond(
            (isNaN(g_n) ".nan")
            (isInfinity(g_n) if(g_n > 0 ".inf" "-.inf"))
            (t
                let((t_s)
                    t_s = sprintf(nil "%.15g" g_n)
                    unless(atof(t_s) == g_n
                        t_s = sprintf(nil "%.17g" g_n)
                    )
                    unless(pcreMatchp("[.eE]" t_s)
                        t_s = strcat(t_s ".0")
                    )
                    t_s
                )
            )
        )
    )
)

procedure(_encodeScalar(g_val g_opt "gg")  ; -> str
    ; 输出标量值。
    ;
    ; **参数**
    ;   g_val  (any) - 标量
    ;   g_opt  (table) - 编码选项
    ;
    ; **返回**
    ;   (str) - 标量文本
    cond(
        (g_val == nil "[]")
        (g_val == t "true")
        (g_val == ycCodec:::True "true")
        (g_val == ycCodec:::False "false")
        (g_val == ycCodec:::Null "null")
        (g_val == ycCodec:::Missing
            error("ycYaml::encode: cannot dump the Missing marker")
        )
        (stringp(g_val)
            if(_plainSafe(g_val)
                g_val
                _encodeString(g_val)
            )
        )
        (fixp(g_val) _numText(g_val))
        (floatp(g_val) _numText(g_val))
        (t
            error("ycYaml::encode: cannot dump value of type %s" symbolToString(type(g_val)))
        )
    )
)

procedure(_encodeFlow(g_val n_level g_opt "gxg")  ; -> str
    ; 以流式风格输出值。
    ;
    ; **参数**
    ;   g_val   (any) - 值
    ;   n_level (int) - 当前深度
    ;   g_opt   (table) - 编码选项
    ;
    ; **返回**
    ;   (str) - 流式文本
    when(n_level > g_opt["maxDepth"]
        error("ycYaml::encode: nesting too deep (limit %d)" g_opt["maxDepth"])
    )
    cond(
        (g_val == nil "[]")
        (tablep(g_val)
            prog((l_keys l_p t_orig t_ks)
                when(length(g_val) == 0
                    return("{}")
                )
                l_keys = nil
                foreach(g_k g_val
                    l_keys = tconc(l_keys g_k)
                )
                l_keys = car(l_keys)
                t_orig = makeTable("ycYamlKeys")
                l_p = nil
                foreach(g_k l_keys
                    t_ks = _encodeKey(g_k g_opt)
                    t_orig[t_ks] = g_k
                    l_p = tconc(l_p lsprintf("%s: %s"
                        t_ks
                        _encodeFlow(g_val[g_k] n_level + 1 g_opt)
                    ))
                )
                when(g_opt["sortKeys"]
                    l_p = sort(car(l_p) 'alphalessp)
                )
                return(lsprintf("{%s}" _joinBuild(l_p ", ")))
            )
        )
        (listp(g_val)
            let((l_p)
                foreach(g_item g_val
                    l_p = tconc(l_p _encodeFlow(g_item n_level + 1 g_opt))
                )
                lsprintf("[%s]" _joinBuild(l_p ", "))
            )
        )
        (t
            _encodeScalar(g_val g_opt)
        )
    )
)

procedure(_blockLines(g_val n_level g_opt "gxg")  ; -> list[str]
    ; 输出块风格值的行列表（不含末尾换行）。
    ;
    ; **参数**
    ;   g_val   (any) - 值
    ;   n_level (int) - 当前缩进深度
    ;   g_opt   (table) - 编码选项
    ;
    ; **返回**
    ;   (list[str]) - 行列表
    prog(nil
    when(n_level > g_opt["maxDepth"]
        error("ycYaml::encode: nesting too deep (limit %d)" g_opt["maxDepth"])
    )
    when(g_opt["flow"]
        return(list(_encodeFlow(g_val n_level g_opt)))
    )
    return(cond(
        (g_val == nil
            list("[]")
        )
        (tablep(g_val)
            when(length(g_val) == 0
                return(list("{}"))
            )
            prog((l_keys l_res t_ks t_orig t_pad t_child l_child t_first)
                l_keys = nil
                t_orig = makeTable("ycYamlKeys")
                foreach(g_k g_val
                    t_ks = _encodeKey(g_k g_opt)
                    t_orig[t_ks] = g_k
                    l_keys = tconc(l_keys t_ks)
                )
                l_keys = car(l_keys)
                when(g_opt["sortKeys"]
                    l_keys = sort(copy(l_keys) 'alphalessp)
                )
                l_res = nil
                t_pad = _indentStr(n_level g_opt["indent"])
                foreach(t_ks l_keys
                    g_k = t_orig[t_ks]
                    cond(
                        (g_val[g_k] == nil
                            l_res = tconc(l_res lsprintf("%s%s: []" t_pad t_ks))
                        )
                        ((tablep(g_val[g_k]) && length(g_val[g_k]) == 0)
                            l_res = tconc(l_res lsprintf("%s%s: {}" t_pad t_ks))
                        )
                        ((tablep(g_val[g_k]) || listp(g_val[g_k]))
                            l_res = tconc(l_res lsprintf("%s%s:" t_pad t_ks))
                            l_child = _blockLines(g_val[g_k] n_level + 1 g_opt)
                            foreach(t_first l_child
                                l_res = tconc(l_res t_first)
                            )
                        )
                        (t
                            l_res = tconc(l_res lsprintf("%s%s: %s"
                                t_pad t_ks _encodeScalar(g_val[g_k] g_opt)))
                        )
                    )
                )
                return(car(l_res))
            )
        )
        (listp(g_val)
            let((l_res t_pad l_child t_first l_item)
                l_res = nil
                t_pad = _indentStr(n_level g_opt["indent"])
                foreach(l_item g_val
                    cond(
                        ((tablep(l_item) && length(l_item) == 0)
                            l_res = tconc(l_res lsprintf("%s- {}" t_pad))
                        )
                        ((tablep(l_item) && length(l_item) > 0)
                            l_child = _blockLines(l_item n_level + 1 g_opt)
                            l_res = tconc(l_res lsprintf("%s- %s"
                                t_pad
                                _ltrim(car(l_child))
                            ))
                            foreach(t_first cdr(l_child)
                                l_res = tconc(l_res t_first)
                            )
                        )
                        ((listp(l_item) && l_item != nil)
                            l_res = tconc(l_res strcat(t_pad "-"))
                            l_child = _blockLines(l_item n_level + 1 g_opt)
                            foreach(t_first l_child
                                l_res = tconc(l_res t_first)
                            )
                        )
                        (t
                            l_res = tconc(l_res lsprintf("%s- %s"
                                t_pad _encodeScalar(l_item g_opt)))
                        )
                    )
                )
                car(l_res)
            )
        )
        (t
            list(_encodeScalar(g_val g_opt))
        )
    )
    )
))

procedure(encode(g_val \@key (format "yaml") (indent nil) (sortKeys nil) (strict nil) (flow nil) (explicitStart nil) (explicitEnd nil) (finalNewline t) (maxDepth nil) "gtgggggggg")  ; -> str
    ; 编码值为 YAML 文本。
    ;
    ; **参数**
    ;   g_val         (any) - 待编码值；yaml-stream 时为文档列表
    ;   ?format       (str) - "yaml" 或 "yaml-stream"
    ;   ?indent       (int) - 每层缩进空格数；默认 2
    ;   ?sortKeys     (t|nil) - 映射键排序；默认 nil
    ;   ?strict       (t|nil) - t 时映射键必须为字符串
    ;   ?flow         (t|nil) - t 时全部使用流式风格
    ;   ?explicitStart(t|nil) - 单文档添加 `---`
    ;   ?explicitEnd  (t|nil) - 单文档添加 `...`
    ;   ?finalNewline (t|nil) - 末尾换行；默认 t
    ;   ?maxDepth     (int) - 最大嵌套深度；默认 800
    ;
    ; **返回**
    ;   (str) - YAML 文本
    let((n_indent g_opt l_lines t_s l_docs)
        when(maxDepth == nil
            maxDepth = _maxEncodeDepth
        )
        unless(fixp(maxDepth) && maxDepth >= 1
            error("ycYaml::encode: ?maxDepth must be a positive fixnum")
        )
        when(indent == nil
            indent = 2
        )
        unless(fixp(indent) && indent >= 1
            error("ycYaml::encode: ?indent must be a positive fixnum")
        )
        g_opt = makeTable("ycYamlOpt")
        g_opt["indent"] = indent
        g_opt["sortKeys"] = sortKeys
        g_opt["strict"] = strict
        g_opt["flow"] = flow
        g_opt["maxDepth"] = maxDepth
        case(format
            ("yaml"
                l_lines = _blockLines(g_val 0 g_opt)
                t_s = buildString(l_lines "\n")
                when(explicitStart
                    t_s = strcat("---\n" t_s)
                )
                when(explicitEnd
                    t_s = strcat(t_s "\n...")
                )
                if(finalNewline strcat(t_s "\n") t_s)
            )
            ("yaml-stream"
                unless(listp(g_val)
                    error("ycYaml::encode: format \"yaml-stream\" expects a list")
                )
                l_docs = nil
                foreach(g_item g_val
                    l_docs = tconc(l_docs
                        strcat("---\n" buildString(_blockLines(g_item 0 g_opt) "\n"))
                    )
                )
                t_s = buildString(car(l_docs) "\n")
                if(t_s == ""
                    ""
                    if(finalNewline strcat(t_s "\n") t_s)
                )
            )
            (t
                error("ycYaml::encode: unknown format %A" format)
            )
        )
    )
)

unuseNamespace("ycYaml")

; END
