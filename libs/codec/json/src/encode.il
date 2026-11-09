ycNamespace:::Require("ycCodec")

useNamespace("ycJson")

; 编码默认嵌套深度上限：实测约 1150 层触语言栈上界，取 800 留安全余量；可用 ?maxDepth 调整。
_MaxEncodeDepth = 800


; ---------- 输出 ----------

procedure(_KeyStr(g_key g_opt "gg")  ; -> str
    ; 将 table 键转为输出用字符串：字符串原样、符号取名、fixnum 转十进制。
    ;
    ; **参数**
    ;   g_key  (any) - 键值（str/sym/int）
    ;   g_opt  (table) - 编码选项表
    ;
    ; **返回**
    ;   (str) - 键的字符串形式；其他键型报错
    when(g_opt["strict"] && !stringp(g_key)
        error("ycJson::Encode: strict mode requires string keys, got %A" g_key)
    )
    cond(
        (stringp(g_key) g_key)
        (symbolp(g_key) symbolToString(g_key))
        (fixp(g_key) sprintf(nil "%d" g_key))
        (t
            error("ycJson::Encode: unsupported table key of type %s" symbolToString(type(g_key)))
        )
    )
)

procedure(_IndentStr(n_level n_indent "xx")  ; -> str
    ; 生成 n_level 层、每层 n_indent 个空格的缩进串。
    ;
    ; **参数**
    ;   n_level   (int) - 层数
    ;   n_indent  (int) - 每层空格数
    ;
    ; **返回**
    ;   (str) - 缩进空白串
    let((item)
        item = ""
        when(0 < n_level && 0 < n_indent
            for(k 1 n_level * n_indent
                item = strcat(item " ")
            )
        )
        item
    )
)

procedure(_EncodeString(t_s "t")  ; -> str
    ; 输出字符串：引号/反斜杠/控制字节转义，其余字节（含 UTF-8）原样透传。
    ;
    ; **参数**
    ;   t_s  (str) - 待输出字符串
    ;
    ; **返回**
    ;   (str) - 带双引号的 JSON 字符串文本
    let((len run p c)
        len = length(t_s)
        run = 1
        p = nil
        when(0 < len
            for(k 1 len
                c = _Code(t_s k)
                cond(
                    (c == 34 || c == 92 || c < 32
                        {
                        when(run < k
                            p = tconc(p substring(t_s run k - run))
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
                        run = k + 1
                        }
                    )
                )
            )
            when(run <= len
                p = tconc(p substring(t_s run len - run + 1))
            )
        )
        lsprintf("\"%s\"" _Build(p))
    )
)

procedure(_EncodeNumber(n_num "n")  ; -> str
    ; 数字输出：fixnum 直出；flonum 用 %.15g、不可回环时回退 %.17g，缺小数点/指数时补 .0。
    ;
    ; **参数**
    ;   n_num  (num) - fixnum 或 flonum
    ;
    ; **返回**
    ;   (str) - JSON 数字文本；inf/nan 报错
    if(fixp(n_num)
        sprintf(nil "%d" n_num)
        let((item)
            when(isNaN(n_num) || isInfinity(n_num)
                error("ycJson::Encode: cannot dump non-finite float")
            )
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

procedure(_EncodeValue(g_val n_depth g_opt "gxg")  ; -> str
    ; 单值输出分发：nil 即空数组、t/哨兵出字面量，其余按类型派发；超深或不可表示类型报错。
    ;
    ; **参数**
    ;   g_val     (any) - 待输出值
    ;   n_depth   (int) - 当前嵌套深度（顶层 0）
    ;   g_opt     (table) - 编码选项表（indent/sortKeys/strict/nilAs/maxDepth）
    ;
    ; **返回**
    ;   (str) - 该值的 JSON 文本
    when(n_depth > g_opt["maxDepth"]
        error("ycJson::Encode: nesting too deep (limit %d)" g_opt["maxDepth"])
    )
    cond(
        (g_val == nil
            if(g_opt["nilAs"] == "array" "[]" "false")
        )
        (member(g_val list(t ycCodec:::True)) "true")
        (g_val == ycCodec:::False "false")
        (g_val == ycCodec:::Null "null")
        (g_val == ycCodec:::Missing
            error("ycJson::Encode: cannot dump the Missing marker")
        )
        (stringp(g_val) _EncodeString(g_val))
        (numberp(g_val) _EncodeNumber(g_val))
        (tablep(g_val) _EncodeTable(g_val n_depth g_opt))
        (listp(g_val) _EncodeList(g_val n_depth g_opt))
        (t
            error("ycJson::Encode: cannot dump value of type %s" symbolToString(type(g_val)))
        )
    )
)

procedure(_EncodeList(l_arr n_depth g_opt "lxg")  ; -> str
    ; 输出列表为 JSON 数组；缩进为正时逐元素换行缩进。
    ;
    ; **参数**
    ;   l_arr     (list) - 非空列表
    ;   n_depth   (int) - 当前嵌套深度
    ;   g_opt     (table) - 编码选项表
    ;
    ; **返回**
    ;   (str) - JSON 数组文本
    let((indent2 items q pad padIn)
        indent2 = g_opt["indent"]
        when(indent2 > 0
            pad = _IndentStr(n_depth indent2)
            padIn = _IndentStr(n_depth + 1 indent2)
        )
        items = nil
        foreach(item l_arr
            items = tconc(items _EncodeValue(item n_depth + 1 g_opt))
        )
        items = car(items)
        if(indent2 > 0
        then
            q = nil
            while(items
                q = tconc(q
                    lsprintf("%s%s%s"
                        padIn
                        car(items)
                        if(cdr(items) "," "")
                    )
                )
                items = cdr(items)
            )
            lsprintf("[\n%s\n%s]" buildString(car(q) "\n") pad)
        else
            lsprintf("[%s]" buildString(items ","))
        )
    )
)

procedure(_EncodeTable(g_obj n_depth g_opt "gxg")  ; -> str
    ; 输出 table 为 JSON 对象；键限字符串/符号/fixnum，sortKeys 非 nil 时按 alphalessp 排序。
    ;
    ; **参数**
    ;   g_obj     (table) - 待输出表
    ;   n_depth   (int) - 当前嵌套深度
    ;   g_opt     (table) - 编码选项表
    ;
    ; **返回**
    ;   (str) - JSON 对象文本
    if(length(g_obj) == 0
        "{}"
        let((keys orig strs p pad padIn ks indent2)
            indent2 = g_opt["indent"]
            keys = nil
            foreach(k g_obj
                keys = tconc(keys k)
            )
            keys = car(keys)
            orig = makeTable("ycJsonKeys" ycCodec:::Missing)
            strs = nil
            foreach(k keys
                ks = _KeyStr(k g_opt)
                when(orig[ks] != ycCodec:::Missing
                    error("ycJson::Encode: duplicate object key %A after string conversion" ks)
                )
                strs = tconc(strs ks)
                orig[ks] = k
            )
            strs = car(strs)
            when(g_opt["sortKeys"]
                strs = sort(strs 'alphalessp)
            )
            when(indent2 > 0
                pad = _IndentStr(n_depth indent2)
                padIn = _IndentStr(n_depth + 1 indent2)
            )
            p = nil
            foreach(ks2 strs
                p = tconc(p
                    if(indent2 > 0
                        lsprintf("%s%s: %s"
                            padIn
                            _EncodeString(ks2)
                            _EncodeValue(g_obj[orig[ks2]] n_depth + 1 g_opt)
                        )
                        lsprintf("%s:%s"
                            _EncodeString(ks2)
                            _EncodeValue(g_obj[orig[ks2]] n_depth + 1 g_opt)
                        )
                    )
                )
            )
            if(indent2 > 0
                lsprintf("{\n%s\n%s}" buildString(car(p) "\n") pad)
                lsprintf("{%s}" buildString(car(p) ","))
            )
        )
    )
)

procedure(Encode(g_val \@key (format "json") (indent nil) (sortKeys nil) (strict nil) (nilAs "array") (finalNewline t) (maxDepth nil) "gtgggtgg")  ; -> str
    ; 编码值为文本：?format 选 "json"/"jsonc"（单值）或 "jsonl"（值列表逐行）。
    ;
    ; **参数**
    ;   g_val         (any) - 待输出值；"jsonl" 时为列表
    ;   ?format       (str) - 格式；默认 "json"
    ;   ?indent       (int) - 缩进空格数；默认 nil（紧凑输出）
    ;   ?sortKeys     (t|nil) - 对象键排序开关；默认 nil（随表序）
    ;   ?strict       (t|nil) - t 时对象键必须为字符串；默认 nil
    ;   ?nilAs        (str) - nil 的输出形式："array"（默认）或 "false"
    ;   ?finalNewline (t|nil) - jsonl 末尾换行；默认 t
    ;   ?maxDepth     (int) - 最大嵌套深度；默认 800
    ;
    ; **返回**
    ;   (str) - 文本；无法表示时以 error() 中断
    unless(nilAs == "array" || nilAs == "false"
        error("ycJson::Encode: unknown ?nilAs value %A" nilAs)
    )
    when(maxDepth == nil
        maxDepth = _MaxEncodeDepth
    )
    unless(fixp(maxDepth) && maxDepth >= 1
        error("ycJson::Encode: ?maxDepth must be a positive fixnum")
    )
    let((indent2 opt)
        indent2 = 0
        when(indent
            unless(fixp(indent)
                error("ycJson::Encode: ?indent must be a fixnum")
            )
            when(indent > 0
                indent2 = indent
            )
        )
        opt = makeTable("ycJsonOpt")
        opt["indent"] = indent2
        opt["sortKeys"] = sortKeys
        opt["strict"] = strict
        opt["nilAs"] = nilAs
        opt["maxDepth"] = maxDepth
        case(format
            (("json" "jsonc")
                _EncodeValue(g_val 0 opt)
            )
            ("jsonl"
                unless(listp(g_val)
                    error("ycJson::Encode: format \"jsonl\" expects a list")
                )
                let((p item)
                    ; jsonl 每条记录必须单行，?indent 不参与
                    opt["indent"] = 0
                    p = nil
                    foreach(item2 g_val
                        p = tconc(p _EncodeValue(item2 0 opt))
                    )
                    item = buildString(car(p) "\n")
                    cond(
                        (item == "" "")
                        (finalNewline
                            strcat(item "\n")
                        )
                        (t item)
                    )
                )
            )
            (t
                error("ycJson::Encode: unknown format %A" format)
            )
        )
    )
)

unuseNamespace("ycJson")

; END
