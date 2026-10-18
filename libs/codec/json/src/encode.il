useNamespace("ycJson")


; ---------- 输出 ----------

procedure(_keyStr(g_key "g")  ; -> str
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
            error("ycJson::encode: unsupported table key of type %s" symbolToString(type(g_key)))
        )
    )
)

procedure(_indentStr(n_level n_indent "nn")  ; -> str
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

procedure(_encodeString(t_s "t")  ; -> str
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
                n_c = _code(t_s n_k)
                cond(
                    (n_c == 34 || n_c == 92 || n_c < 32
                        {
                        when(n_run < n_k
                            l_p = tconc(l_p substring(t_s n_run n_k - n_run))
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
                        n_run = n_k + 1
                        }
                    )
                )
            )
            when(n_run <= n_len
                l_p = tconc(l_p substring(t_s n_run n_len - n_run + 1))
            )
        )
        lsprintf("\"%s\"" _build(l_p))
    )
)

procedure(_encodeNumber(g_n "g")  ; -> str
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
                error("ycJson::encode: cannot dump non-finite float")
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

procedure(_encodeValue(g_val n_depth n_indent g_sort "gnng")  ; -> str
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
    when(n_depth > _maxDepth
        error("ycJson::encode: nesting too deep (limit %d)" _maxDepth)
    )
    cond(
        (g_val == nil "[]")
        (g_val == t "true")
        (g_val == True "true")
        (g_val == False "false")
        (g_val == Null "null")
        (g_val == Missing
            error("ycJson::encode: cannot dump the Missing marker")
        )
        (stringp(g_val) _encodeString(g_val))
        (fixp(g_val) _encodeNumber(g_val))
        (floatp(g_val) _encodeNumber(g_val))
        (tablep(g_val) _encodeTable(g_val n_depth n_indent g_sort))
        (listp(g_val) _encodeList(g_val n_depth n_indent g_sort))
        (t
            error("ycJson::encode: cannot dump value of type %s" symbolToString(type(g_val)))
        )
    )
)

procedure(_encodeList(l_arr n_depth n_indent g_sort "lnng")  ; -> str
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
            t_pad = _indentStr(n_depth n_indent)
            t_padIn = _indentStr(n_depth + 1 n_indent)
        )
        l_items = nil
        foreach(g_item l_arr
            l_items = tconc(l_items _encodeValue(g_item n_depth + 1 n_indent g_sort))
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

procedure(_encodeTable(t_obj n_depth n_indent g_sort "gnng")  ; -> str
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
            t_orig = makeTable("ycJsonKeys")
            l_strs = nil
            foreach(g_k l_keys
                t_ks = _keyStr(g_k)
                l_strs = tconc(l_strs t_ks)
                t_orig[t_ks] = g_k
            )
            l_strs = car(l_strs)
            when(g_sort
                l_strs = sort(l_strs 'alphalessp)
            )
            when(n_indent > 0
                t_pad = _indentStr(n_depth n_indent)
                t_padIn = _indentStr(n_depth + 1 n_indent)
            )
            l_p = nil
            foreach(t_ks l_strs
                l_p = tconc(l_p
                    if(n_indent > 0
                        lsprintf("%s%s: %s"
                            t_padIn
                            _encodeString(t_ks)
                            _encodeValue(t_obj[t_orig[t_ks]] n_depth + 1 n_indent g_sort)
                        )
                        lsprintf("%s:%s"
                            _encodeString(t_ks)
                            _encodeValue(t_obj[t_orig[t_ks]] n_depth + 1 n_indent g_sort)
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

procedure(encode(g_val \@key (format "json") (indent nil) (sortKeys t) "gtgg")  ; -> str
    ; 编码值为文本：?format 选 "json"/"jsonc"（单值）或 "jsonl"（值列表逐行）。
    ;
    ; **参数**
    ;   g_val      (any) - 待输出值；"jsonl" 时为列表
    ;   ?format    (str) - 格式；默认 "json"
    ;   ?indent    (int) - 缩进空格数；默认 nil（紧凑输出）
    ;   ?sortKeys  (t|nil) - 对象键排序开关；默认 t
    ;
    ; **返回**
    ;   (str) - 文本；无法表示时以 error() 中断
    case(format
        (("json" "jsonc")
            let((n_indent)
                n_indent = 0
                when(indent
                    unless(fixp(indent)
                        error("ycJson::encode: ?indent must be a fixnum")
                    )
                    when(indent > 0
                        n_indent = indent
                    )
                )
                _encodeValue(g_val 0 n_indent sortKeys)
            )
        )
        ("jsonl"
            unless(listp(g_val)
                error("ycJson::encode: format \"jsonl\" expects a list")
            )
            let((l_p t_s)
                l_p = nil
                foreach(g_item g_val
                    l_p = tconc(l_p _encodeValue(g_item 0 0 sortKeys))
                )
                t_s = buildString(car(l_p) "\n")
                if(t_s == ""
                    ""
                    strcat(t_s "\n")
                )
            )
        )
        (t
            error("ycJson::encode: unknown format %A" format)
        )
    )
)

unuseNamespace("ycJson")

; END
