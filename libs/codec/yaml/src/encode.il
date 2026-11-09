ycNamespace:::Require("ycCodec")

useNamespace("ycYaml")

; ---------- 编码 ----------

procedure(_IndentStr(n_level n_indent "xx")  ; -> str
    ; 生成 n_level 层、每层 n_indent 个空格的缩进串。
    ;
    ; **参数**
    ;   n_level   (int) - 层数
    ;   n_indent  (int) - 每层空格数
    ;
    ; **返回**
    ;   (str) - 缩进空白串
    let((item i)
        item = ""
        when(0 < n_level && 0 < n_indent
            for(i2 1 n_level * n_indent
                item = strcat(item " ")
            )
        )
        item
    )
)

procedure(_PlainSafe(t_s \@key (flow nil) "tg")  ; -> t | nil
    ; 判断字符串能否安全地作为普通标量输出（不改变类型）。
    ;
    ; **参数**
    ;   t_s    (str) - 待检查字符串
    ;   ?flow  (t|nil) - t 时额外拒绝流式分隔符 `,`/`[`/`]`/`{`/`}`
    ;
    ; **返回**
    ;   (t|nil) - 可安全输出为 t
    prog((len c i bad)
        len = length(t_s)
        when(len == 0 || t_s == "..."
            return(nil)
        )
        c = _Code(t_s 1)
        when(c == 32 || c == 9 || c == 10 || c == 13
            return(nil)
        )
        c = _Code(t_s len)
        when(c == 32 || c == 9 || c == 10 || c == 13
            return(nil)
        )
        when(_SpecialStart(_Code(t_s 1))
            return(nil)
        )
        when(_Code(t_s 1) == 45 || _Code(t_s 1) == 63 || _Code(t_s 1) == 58
            return(nil)
        )
        bad = nil
        for(i2 1 len
            c = _Code(t_s i2)
            cond(
                (c == 10 || c == 13 || c == 9
                    bad = t
                )
                (c < 32
                    bad = t
                )
                (c == 35 && i2 > 1 && (_Code(t_s i2 - 1) == 32 || _Code(t_s i2 - 1) == 9)
                    bad = t
                )
                (c == 58 && i2 < len && (_Code(t_s i2 + 1) == 32 || _Code(t_s i2 + 1) == 9)
                    bad = t
                )
                (flow && or(c == 44 c == 91 c == 93 c == 123 c == 125)
                    bad = t
                )
            )
        )
        when(bad
            return(nil)
        )
        return(_ResolvePlain(t_s) == t_s)
    )
)

procedure(_SpecialStart(n_c "x")  ; -> t | nil
    ; 判断字符码是否为普通标量禁用起始字符。
    ;
    ; **参数**
    ;   n_c  (int) - 字符码
    ;
    ; **返回**
    ;   (t|nil) - 是危险起始字符时为 t
    member(n_c '(91 93 123 125 35 38 42 33 124 62 39 34 37 64 96 44)) && t
)

procedure(_EncodeString(t_s "t")  ; -> str
    ; 输出带双引号的 YAML 字符串，转义控制字符与引号/反斜杠。
    ;
    ; **参数**
    ;   t_s  (str) - 待输出字符串
    ;
    ; **返回**
    ;   (str) - 带双引号的 YAML 字符串
    let((len i c p run)
        len = length(t_s)
        run = 1
        for(i2 1 len
            c = _Code(t_s i2)
            when(c == 34 || c == 92 || c < 32
                when(run < i2
                    p = tconc(p substring(t_s run i2 - run))
                )
                p = tconc(p
                    case(c
                        (34 "\\\"")
                        (92 "\\\\")
                        (8 "\\b")
                        (12 "\\f")
                        (10 "\\n")
                        (13 "\\r")
                        (9 "\\t")
                        (t sprintf(nil "\\u%04x" c))
                    )
                )
                run = i2 + 1
            )
        )
        when(run <= len
            p = tconc(p substring(t_s run len - run + 1))
        )
        lsprintf("\"%s\"" _Build(p))
    )
)

procedure(_EncodeKey(g_key g_opt \@key (flow nil) "ggg")  ; -> str
    ; 将 table 键转为 YAML 映射键文本。
    ;
    ; **参数**
    ;   g_key  (any) - 键值
    ;   g_opt  (table) - 编码选项
    ;   ?flow  (t|nil) - t 时按流式规则引用键
    ;
    ; **返回**
    ;   (str) - 键文本
    let((item)
        when(g_opt["strict"] && !stringp(g_key)
            error("ycYaml::Encode: strict mode requires string keys, got %A" g_key)
        )
        item = cond(
            (stringp(g_key) g_key)
            (symbolp(g_key) symbolToString(g_key))
            (fixp(g_key) sprintf(nil "%d" g_key))
        )
        unless(item
            error("ycYaml::Encode: unsupported table key of type %s" symbolToString(type(g_key)))
        )
        cond(
            (fixp(g_key) item)
            (_PlainSafe(item ?flow flow) && !pcreMatchp("[ 	]" item) item)
            (t _EncodeString(item))
        )
    )
)

procedure(_NumText(n_num "n")  ; -> str
    ; 输出 YAML 数字文本；非有限浮点输出 .inf/-.inf/.nan。
    ;
    ; **参数**
    ;   n_num  (num) - fixnum 或 flonum
    ;
    ; **返回**
    ;   (str) - 数字文本
    if(fixp(n_num)
        sprintf(nil "%d" n_num)
        cond(
            (isNaN(n_num) ".nan")
            (isInfinity(n_num) if(n_num > 0 ".inf" "-.inf"))
            (t
                let((item)
                    item = sprintf(nil "%.15g" n_num)
                    unless(atof(item) == n_num
                        item = sprintf(nil "%.17g" n_num)
                    )
                    unless(pcreMatchp("[.eE]" item)
                        item = strcat(item ".0")
                    )
                    item
                )
            )
        )
    )
)

procedure(_EncodeScalar(g_val g_opt \@key (flow nil) "ggg")  ; -> str
    ; 输出标量值。
    ;
    ; **参数**
    ;   g_val  (any) - 标量
    ;   g_opt  (table) - 编码选项
    ;   ?flow  (t|nil) - t 时按流式规则引用字符串
    ;
    ; **返回**
    ;   (str) - 标量文本
    cond(
        (g_val == nil "[]")
        (or(g_val == t g_val == ycCodec:::True) "true")
        (g_val == ycCodec:::False "false")
        (g_val == ycCodec:::Null "null")
        (g_val == ycCodec:::Missing
            error("ycYaml::Encode: cannot dump the Missing marker")
        )
        (stringp(g_val)
            if(_PlainSafe(g_val ?flow flow)
                g_val
                _EncodeString(g_val)
            )
        )
        (numberp(g_val) _NumText(g_val))
        (t
            error("ycYaml::Encode: cannot dump value of type %s" symbolToString(type(g_val)))
        )
    )
)

procedure(_EncodeFlow(g_val n_level g_opt "gxg")  ; -> str
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
        error("ycYaml::Encode: nesting too deep (limit %d)" g_opt["maxDepth"])
    )
    cond(
        (g_val == nil "[]")
        (tablep(g_val)
            prog((keys p orig ks ksList)
                when(length(g_val) == 0
                    return("{}")
                )
                keys = nil
                foreach(k g_val
                    keys = tconc(keys k)
                )
                keys = car(keys)
                orig = makeTable("ycYamlKeys" ycCodec:::Missing)
                ksList = nil
                foreach(k keys
                    ks = _EncodeKey(k g_opt ?flow t)
                    when(orig[ks] != ycCodec:::Missing
                        error("ycYaml::Encode: duplicate mapping key %A after encoding" ks)
                    )
                    orig[ks] = k
                    ksList = tconc(ksList ks)
                )
                ksList = car(ksList)
                when(g_opt["sortKeys"]
                    ksList = sort(copy(ksList) 'alphalessp)
                )
                p = nil
                foreach(ks ksList
                    p = tconc(p lsprintf("%s: %s"
                        ks
                        _EncodeFlow(g_val[orig[ks]] n_level + 1 g_opt)
                    ))
                )
                return(lsprintf("{%s}" _JoinBuild(p ", ")))
            )
        )
        (listp(g_val)
            let((p)
                foreach(item g_val
                    p = tconc(p _EncodeFlow(item n_level + 1 g_opt))
                )
                lsprintf("[%s]" _JoinBuild(p ", "))
            )
        )
        (t
            _EncodeScalar(g_val g_opt ?flow t)
        )
    )
)

procedure(_BlockLines(g_val n_level g_opt "gxg")  ; -> list[str]
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
        error("ycYaml::Encode: nesting too deep (limit %d)" g_opt["maxDepth"])
    )
    when(g_opt["flow"]
        return(list(_EncodeFlow(g_val n_level g_opt)))
    )
    return(cond(
        (g_val == nil
            list("[]")
        )
        (tablep(g_val)
            when(length(g_val) == 0
                return(list("{}"))
            )
            prog((keys res ks orig pad child child2 first)
                keys = nil
                orig = makeTable("ycYamlKeys" ycCodec:::Missing)
                foreach(k g_val
                    ks = _EncodeKey(k g_opt)
                    when(orig[ks] != ycCodec:::Missing
                        error("ycYaml::Encode: duplicate mapping key %A after encoding" ks)
                    )
                    orig[ks] = k
                    keys = tconc(keys ks)
                )
                keys = car(keys)
                when(g_opt["sortKeys"]
                    keys = sort(copy(keys) 'alphalessp)
                )
                res = nil
                pad = _IndentStr(n_level g_opt["indent"])
                foreach(ks2 keys
                    g_k = orig[ks2]
                    cond(
                        (g_val[g_k] == nil
                            res = tconc(res lsprintf("%s%s: []" pad ks2))
                        )
                        ((tablep(g_val[g_k]) && length(g_val[g_k]) == 0)
                            res = tconc(res lsprintf("%s%s: {}" pad ks2))
                        )
                        ((tablep(g_val[g_k]) || listp(g_val[g_k]))
                            res = tconc(res lsprintf("%s%s:" pad ks2))
                            child2 = _BlockLines(g_val[g_k] n_level + 1 g_opt)
                            foreach(first2 child2
                                res = tconc(res first2)
                            )
                        )
                        (t
                            res = tconc(res lsprintf("%s%s: %s"
                                pad ks2 _EncodeScalar(g_val[g_k] g_opt)))
                        )
                    )
                )
                return(car(res))
            )
        )
        (listp(g_val)
            let((res pad child first item)
                res = nil
                pad = _IndentStr(n_level g_opt["indent"])
                foreach(item2 g_val
                    cond(
                        ((tablep(item2) && length(item2) == 0)
                            res = tconc(res lsprintf("%s- {}" pad))
                        )
                        ((tablep(item2) && length(item2) > 0)
                            child = _BlockLines(item2 n_level + 1 g_opt)
                            res = tconc(res lsprintf("%s- %s"
                                pad
                                _Ltrim(car(child))
                            ))
                            foreach(first2 cdr(child)
                                res = tconc(res first2)
                            )
                        )
                        ((listp(item2) && item2 != nil)
                            res = tconc(res strcat(pad "-"))
                            child = _BlockLines(item2 n_level + 1 g_opt)
                            foreach(first2 child
                                res = tconc(res first2)
                            )
                        )
                        (t
                            res = tconc(res lsprintf("%s- %s"
                                pad _EncodeScalar(item2 g_opt)))
                        )
                    )
                )
                car(res)
            )
        )
        (t
            list(_EncodeScalar(g_val g_opt))
        )
    )
    )
))

procedure(Encode(g_val \@key (format "yaml") (indent nil) (sortKeys nil) (strict nil) (flow nil) (explicitStart nil) (explicitEnd nil) (finalNewline t) (maxDepth nil) "gtgggggggg")  ; -> str
    ; 编码值为 YAML 文本。
    ;
    ; **参数**
    ;   g_val         (any) - 待编码值；yaml-stream 时为文档列表
    ;   ?format       (str) - "yaml" 或 "yaml-stream"；默认 "yaml"
    ;   ?indent       (int) - 每层缩进空格数；默认 2
    ;   ?sortKeys     (t|nil) - 映射键排序；默认 nil
    ;   ?strict       (t|nil) - t 时映射键必须为字符串；默认 nil
    ;   ?flow         (t|nil) - t 时全部使用流式风格；默认 nil
    ;   ?explicitStart (t|nil) - 单文档添加 `---`；默认 nil
    ;   ?explicitEnd   (t|nil) - 单文档添加 `...`；默认 nil
    ;   ?finalNewline (t|nil) - 末尾换行；默认 t
    ;   ?maxDepth     (int) - 最大嵌套深度；默认 800
    ;
    ; **返回**
    ;   (str) - YAML 文本
    let((indent2 opt lines item docs)
        when(maxDepth == nil
            maxDepth = _MaxEncodeDepth
        )
        unless(fixp(maxDepth) && maxDepth >= 1
            error("ycYaml::Encode: ?maxDepth must be a positive fixnum")
        )
        when(indent == nil
            indent = 2
        )
        unless(fixp(indent) && indent >= 1
            error("ycYaml::Encode: ?indent must be a positive fixnum")
        )
        opt = makeTable("ycYamlOpt")
        opt["indent"] = indent
        opt["sortKeys"] = sortKeys
        opt["strict"] = strict
        opt["flow"] = flow
        opt["maxDepth"] = maxDepth
        case(format
            ("yaml"
                lines = _BlockLines(g_val 0 opt)
                item = buildString(lines "\n")
                when(explicitStart
                    item = strcat("---\n" item)
                )
                when(explicitEnd
                    item = strcat(item "\n...")
                )
                if(finalNewline strcat(item "\n") item)
            )
            ("yaml-stream"
                unless(listp(g_val)
                    error("ycYaml::Encode: format \"yaml-stream\" expects a list")
                )
                docs = nil
                foreach(item2 g_val
                    docs = tconc(docs
                        strcat("---\n" buildString(_BlockLines(item2 0 opt) "\n"))
                    )
                )
                item = buildString(car(docs) "\n")
                cond(
                    (item == "" "")
                    (finalNewline strcat(item "\n"))
                    (t item)
                )
            )
            (t
                error("ycYaml::Encode: unknown format %A" format)
            )
        )
    )
)

unuseNamespace("ycYaml")

; END
