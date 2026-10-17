useNamespace("ycCodec")


; ---------- 输出 ----------

procedure(_jsonKeyStr(g_key "g")  ; -> str
    ; 将 table 键转为输出用字符串：字符串原样、符号取名、fixnum 转十进制。
    ;
    ; **参数**
    ;   g_key  (any) - 键值（str/sym/int）
    ;
    ; **返回**
    ;   (str) - 键的字符串形式；其他键型报错
    cond(
        (stringp(g_key) g_key)
        (symbolp(g_key) symbolToString(g_key))
        (fixp(g_key) sprintf(nil "%d" g_key))
        (t
            error("ycCodec: unsupported table key of type %s" symbolToString(type(g_key)))
        )
    )
)

procedure(_jsonIndentStr(n_level n_indent "nn")  ; -> str
    ; 生成 n_level 层、每层 n_indent 个空格的缩进串。
    ;
    ; **参数**
    ;   n_level   (int) - 层数
    ;   n_indent  (int) - 每层空格数
    ;
    ; **返回**
    ;   (str) - 缩进空白串
    let((t_s)
        t_s = ""
        when(0 < n_level && 0 < n_indent
            for(n_k 1 n_level * n_indent
                t_s = strcat(t_s " ")
            )
        )
        t_s
    )
)

procedure(_jsonDumpString(t_s "t")  ; -> str
    ; 输出字符串：引号/反斜杠/控制字节转义，其余字节（含 UTF-8）原样透传。
    ;
    ; **参数**
    ;   t_s  (str) - 待输出字符串
    ;
    ; **返回**
    ;   (str) - 带双引号的 JSON 字符串文本
    let((n_len n_run l_p n_c)
        n_len = length(t_s)
        n_run = 1
        l_p = nil
        when(0 < n_len
            for(n_k 1 n_len
                n_c = _jsonCode(t_s n_k)
                cond(
                    (n_c == 34 || n_c == 92 || n_c < 32
                        {
                        when(n_run < n_k
                            l_p = tconc(l_p substring(t_s n_run n_k - n_run))
                        )
                        l_p = tconc(l_p
                            cond(
                                (n_c == 34 "\\\"")
                                (n_c == 92 "\\\\")
                                (n_c == 8 "\\b")
                                (n_c == 12 "\\f")
                                (n_c == 10 "\\n")
                                (n_c == 13 "\\r")
                                (n_c == 9 "\\t")
                                (t sprintf(nil "\\u%04x" n_c))
                            )
                        )
                        n_run = n_k + 1
                        }
                    )
                )
            )
            when(n_run <= n_len
                l_p = tconc(l_p substring(t_s n_run n_len - n_run + 1))
            )
        )
        lsprintf("\"%s\"" _jsonBuild(l_p))
    )
)

procedure(_jsonDumpNumber(g_n "g")  ; -> str
    ; 数字输出：fixnum 直出；flonum 用 %.15g、不可回环时回退 %.17g，缺小数点/指数时补 .0。
    ;
    ; **参数**
    ;   g_n  (num) - fixnum 或 flonum
    ;
    ; **返回**
    ;   (str) - JSON 数字文本；inf/nan 报错
    if(fixp(g_n)
        sprintf(nil "%d" g_n)
        let((t_s)
            when(isNaN(g_n) || isInfinity(g_n)
                error("ycCodec: cannot dump non-finite float")
            )
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

procedure(_jsonDumpValue(g_val n_depth n_indent g_sort "gnng")  ; -> str
    ; 单值输出分发：nil 即空数组、t/哨兵出字面量，其余按类型派发；超深或不可表示类型报错。
    ;
    ; **参数**
    ;   g_val     (any) - 待输出值
    ;   n_depth   (int) - 当前嵌套深度（顶层 0）
    ;   n_indent  (int) - 缩进空格数；0 为紧凑输出
    ;   g_sort    (t|nil) - 对象键是否排序输出
    ;
    ; **返回**
    ;   (str) - 该值的 JSON 文本
    when(n_depth > _jsonMaxDepth
        error("ycCodec: nesting too deep (limit %d)" _jsonMaxDepth)
    )
    cond(
        (g_val == nil "[]")
        (g_val == t "true")
        (g_val == jsonFalse "false")
        (g_val == jsonNull "null")
        (g_val == jsonMissing
            error("ycCodec: cannot dump the jsonMissing marker")
        )
        (stringp(g_val) _jsonDumpString(g_val))
        (fixp(g_val) _jsonDumpNumber(g_val))
        (floatp(g_val) _jsonDumpNumber(g_val))
        (tablep(g_val) _jsonDumpTable(g_val n_depth n_indent g_sort))
        (listp(g_val) _jsonDumpList(g_val n_depth n_indent g_sort))
        (t
            error("ycCodec: cannot dump value of type %s" symbolToString(type(g_val)))
        )
    )
)

procedure(_jsonDumpList(l_arr n_depth n_indent g_sort "lnng")  ; -> str
    ; 输出列表为 JSON 数组；n_indent 为正时逐元素换行缩进。
    ;
    ; **参数**
    ;   l_arr     (list) - 非空列表
    ;   n_depth   (int) - 当前嵌套深度
    ;   n_indent  (int) - 缩进空格数；0 为紧凑输出
    ;   g_sort    (t|nil) - 对象键排序开关（透传元素）
    ;
    ; **返回**
    ;   (str) - JSON 数组文本
    let((l_items l_q t_pad t_padIn)
        when(n_indent > 0
            t_pad = _jsonIndentStr(n_depth n_indent)
            t_padIn = _jsonIndentStr(n_depth + 1 n_indent)
        )
        l_items = nil
        foreach(g_item l_arr
            l_items = tconc(l_items _jsonDumpValue(g_item n_depth + 1 n_indent g_sort))
        )
        l_items = car(l_items)
        if(n_indent > 0
            {
            l_q = nil
            while(l_items
                l_q = tconc(l_q
                    lsprintf("%s%s%s"
                        t_padIn
                        car(l_items)
                        if(cdr(l_items) "," "")
                    )
                )
                l_items = cdr(l_items)
            )
            lsprintf("[\n%s\n%s]" buildString(car(l_q) "\n") t_pad)
            }
            lsprintf("[%s]" buildString(l_items ","))
        )
    )
)

procedure(_jsonDumpTable(t_obj n_depth n_indent g_sort "gnng")  ; -> str
    ; 输出 table 为 JSON 对象；键限字符串/符号/fixnum，g_sort 非 nil 时按 alphalessp 排序。
    ;
    ; **参数**
    ;   t_obj     (table) - 待输出表
    ;   n_depth   (int) - 当前嵌套深度
    ;   n_indent  (int) - 缩进空格数；0 为紧凑输出
    ;   g_sort    (t|nil) - 是否排序键
    ;
    ; **返回**
    ;   (str) - JSON 对象文本
    if(length(t_obj) == 0
        "{}"
        let((l_keys t_orig l_strs l_p t_pad t_padIn t_ks)
            l_keys = nil
            foreach(g_k t_obj
                l_keys = tconc(l_keys g_k)
            )
            l_keys = car(l_keys)
            t_orig = makeTable("ycCodecKeys")
            l_strs = nil
            foreach(g_k l_keys
                t_ks = _jsonKeyStr(g_k)
                l_strs = tconc(l_strs t_ks)
                t_orig[t_ks] = g_k
            )
            l_strs = car(l_strs)
            when(g_sort
                l_strs = sort(l_strs 'alphalessp)
            )
            when(n_indent > 0
                t_pad = _jsonIndentStr(n_depth n_indent)
                t_padIn = _jsonIndentStr(n_depth + 1 n_indent)
            )
            l_p = nil
            foreach(t_ks l_strs
                l_p = tconc(l_p
                    if(n_indent > 0
                        lsprintf("%s%s: %s"
                            t_padIn
                            _jsonDumpString(t_ks)
                            _jsonDumpValue(t_obj[t_orig[t_ks]] n_depth + 1 n_indent g_sort)
                        )
                        lsprintf("%s:%s"
                            _jsonDumpString(t_ks)
                            _jsonDumpValue(t_obj[t_orig[t_ks]] n_depth + 1 n_indent g_sort)
                        )
                    )
                )
            )
            if(n_indent > 0
                lsprintf("{\n%s\n%s}" buildString(car(l_p) "\n") t_pad)
                lsprintf("{%s}" buildString(car(l_p) ","))
            )
        )
    )
)

procedure(jsonDump(g_val \@key (indent nil) (sortKeys t) "ggg")  ; -> str
    ; 输出值为 JSON 文本；?indent 为正整数时按该空格数缩进美化，?sortKeys 默认排序对象键。
    ;
    ; **参数**
    ;   g_val      (any) - 待输出值
    ;   ?indent    (int) - 缩进空格数；默认 nil（紧凑输出）
    ;   ?sortKeys  (t|nil) - 对象键排序开关；默认 t
    ;
    ; **返回**
    ;   (str) - JSON 文本
    let((n_indent)
        n_indent = 0
        when(indent
            unless(fixp(indent)
                error("ycCodec: ?indent must be a fixnum")
            )
            when(indent > 0
                n_indent = indent
            )
        )
        _jsonDumpValue(g_val 0 n_indent sortKeys)
    )
)

unuseNamespace("ycCodec")

; END
