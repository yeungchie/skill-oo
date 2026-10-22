;--------------------------
; Program  : codec/toml(encode.il)
; Language : Cadence Skill
;--------------------------

ycNamespace:::require("ycCodec")

useNamespace("ycToml")

; 编码默认嵌套深度上限；与其它 codec 保持一致。
_maxEncodeDepth = 800


; ---------- 键与字符串 ----------

procedure(_keyStr(g_key g_opt "gg")  ; -> str
    ; 将 table 键转为文本：字符串原样、符号取名、fixnum 转十进制。
    ;
    ; **参数**
    ;   g_key  (any) - 键值（str/sym/int）
    ;   g_opt  (table) - 编码选项表
    ;
    ; **返回**
    ;   (str) - 键文本；其他键型报错
    when(g_opt["strict"] && !stringp(g_key)
        error("ycToml::encode: strict mode requires string keys, got %A" g_key)
    )
    cond(
        (stringp(g_key) g_key)
        (symbolp(g_key) symbolToString(g_key))
        (fixp(g_key) sprintf(nil "%d" g_key))
        (t
            error("ycToml::encode: unsupported table key of type %s" symbolToString(type(g_key)))
        )
    )
)

procedure(_keyRender(t_key "t")  ; -> str
    ; 将单个键渲染为裸键或双引号键。
    ;
    ; **参数**
    ;   t_key  (str) - 键文本
    ;
    ; **返回**
    ;   (str) - TOML 键文本
    if(pcreMatchp("^[A-Za-z0-9_-]+\\z" t_key)
        t_key
        _encodeString(t_key)
    )
)

procedure(_pathRender(l_path "l")  ; -> str
    ; 将键路径渲染为点分表头路径。
    ;
    ; **参数**
    ;   l_path  (list[str]) - 键路径
    ;
    ; **返回**
    ;   (str) - 点分路径
    let((l_p)
        foreach(t_key l_path
            l_p = tconc(l_p _keyRender(t_key))
        )
        buildString(car(l_p) ".")
    )
)

procedure(_encodeString(t_s "t")  ; -> str
    ; 输出基本字符串：引号/反斜杠/控制字节转义，其余 UTF-8 字节原样透传。
    ;
    ; **参数**
    ;   t_s  (str) - 待输出字符串
    ;
    ; **返回**
    ;   (str) - 带双引号的 TOML 基本字符串
    let((n_len n_run l_p n_c)
        n_len = length(t_s)
        n_run = 1
        l_p = nil
        when(0 < n_len
            for(n_k 1 n_len
                n_c = _code(t_s n_k)
                cond(
                    (n_c == 34 || n_c == 92 || n_c < 32 || n_c == 127
                        {
                        when(n_run < n_k
                            l_p = tconc(l_p substring(t_s n_run n_k - n_run))
                        )
                        l_p = tconc(l_p
                            case(n_c
                                (34 "\\\"")
                                (92 "\\\\")
                                (8 "\\b")
                                (9 "\\t")
                                (10 "\\n")
                                (12 "\\f")
                                (13 "\\r")
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
    ; 数字输出：fixnum 十进制；flonum 最短可回环，inf/nan 按 TOML 字面量输出。
    ;
    ; **参数**
    ;   g_n  (num) - fixnum 或 flonum
    ;
    ; **返回**
    ;   (str) - TOML 数字文本
    if(fixp(g_n)
        sprintf(nil "%d" g_n)
        if(isNaN(g_n)
            "nan"
            if(isInfinity(g_n)
                if(0 < g_n "inf" "-inf")
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

; ---------- 值输出 ----------

procedure(_encodeValue(g_val n_depth g_opt "gxg")  ; -> str
    ; 输出内联值：nil 为空数组、布尔哨兵、字符串、数字、数组或内联表。
    ;
    ; **参数**
    ;   g_val    (any) - 待输出值
    ;   n_depth  (int) - 当前嵌套深度
    ;   g_opt    (table) - 编码选项表
    ;
    ; **返回**
    ;   (str) - TOML 值文本；不可表示时以 error() 中断
    when(n_depth > g_opt["maxDepth"]
        error("ycToml::encode: nesting too deep (limit %d)" g_opt["maxDepth"])
    )
    cond(
        (g_val == nil
            "[]"
        )
        (g_val == t || g_val == ycCodec:::True
            "true"
        )
        (g_val == ycCodec:::False
            "false"
        )
        (g_val == ycCodec:::Null
            error("ycToml::encode: TOML has no null value")
        )
        (g_val == ycCodec:::Missing
            error("ycToml::encode: cannot dump the Missing marker")
        )
        (stringp(g_val)
            _encodeString(g_val)
        )
        (numberp(g_val)
            _encodeNumber(g_val)
        )
        (tablep(g_val)
            _encodeTable(g_val n_depth g_opt)
        )
        (listp(g_val)
            _encodeArray(g_val n_depth g_opt)
        )
        (t
            error("ycToml::encode: cannot dump value of type %s" symbolToString(type(g_val)))
        )
    )
)

procedure(_encodeArray(l_arr n_depth g_opt "lxg")  ; -> str
    ; 输出数组为方括号形式；元素递归输出为内联值。
    ;
    ; **参数**
    ;   l_arr    (list) - 数组
    ;   n_depth  (int) - 当前嵌套深度
    ;   g_opt    (table) - 编码选项表
    ;
    ; **返回**
    ;   (str) - 数组文本
    let((l_p)
        foreach(g_item l_arr
            l_p = tconc(l_p _encodeValue(g_item n_depth + 1 g_opt))
        )
        lsprintf("[%s]" buildString(car(l_p) ", "))
    )
)

procedure(_encodeTable(t_obj n_depth g_opt "gxg")  ; -> str
    ; 输出内联表；键按选项排序并递归输出值。
    ;
    ; **参数**
    ;   t_obj    (table) - 内联表
    ;   n_depth  (int) - 当前嵌套深度
    ;   g_opt    (table) - 编码选项表
    ;
    ; **返回**
    ;   (str) - 内联表文本
    let((l_keys l_p)
        l_keys = _tableKeys(t_obj g_opt)
        foreach(t_key l_keys
            l_p = tconc(l_p
                lsprintf("%s = %s"
                    _keyRender(t_key)
                    _encodeValue(t_obj[t_key] n_depth + 1 g_opt)
                )
            )
        )
        if(car(l_p)
            lsprintf("{ %s }" buildString(car(l_p) ", "))
            "{}"
        )
    )
)

; ---------- 文档输出 ----------

procedure(_tableKeys(t_obj g_opt "gg")  ; -> list
    ; 取出 table 的原始键，检测字符串化碰撞，并按选项排序。
    ;
    ; **参数**
    ;   t_obj    (table) - 待处理表
    ;   g_opt    (table) - 编码选项表
    ;
    ; **返回**
    ;   (list) - 原始键列表
    let((t_byText l_texts t_text g_key)
        t_byText = makeTable("ycTomlKeys" ycCodec:::Missing)
        l_texts = nil
        foreach(g_key t_obj
            t_text = _keyStr(g_key g_opt)
            when(t_byText[t_text] != ycCodec:::Missing
                error("ycToml::encode: duplicate key %A after string conversion" t_text)
            )
            t_byText[t_text] = g_key
            l_texts = tconc(l_texts t_text)
        )
        l_texts = car(l_texts)
        when(g_opt["sortKeys"]
            l_texts = sort(l_texts 'alphalessp)
        )
        let((l_res)
            if(g_opt["sortKeys"]
                foreach(t_text l_texts
                    l_res = tconc(l_res t_byText[t_text])
                )
                foreach(g_key t_obj
                    l_res = tconc(l_res g_key)
                )
            )
            car(l_res)
        )
    )
)

procedure(_emitHeader(l_p l_path g_array "llg")  ; -> list
    ; 在行列表前追加空行与表头。
    ;
    ; **参数**
    ;   l_p      (list) - tconc 行容器
    ;   l_path   (list[str]) - 表路径
    ;   g_array  (t|nil) - t 时输出 [[...]]
    ;
    ; **返回**
    ;   (list) - 更新后的行容器
    when(car(l_p)
        l_p = tconc(l_p "")
    )
    tconc(l_p
        if(g_array
            lsprintf("[[%s]]" _pathRender(l_path))
            lsprintf("[%s]" _pathRender(l_path))
        )
    )
)

procedure(_emitElement(l_p t_obj l_path n_depth g_opt "lglxg")  ; -> list
    ; 输出一个表数组元素：[[path]] 后接该元素的键值。
    ;
    ; **参数**
    ;   l_p      (list) - tconc 行容器
    ;   t_obj    (table) - 元素表
    ;   l_path   (list[str]) - 完整表路径
    ;   n_depth  (int) - 当前嵌套深度
    ;   g_opt    (table) - 编码选项表
    ;
    ; **返回**
    ;   (list) - 更新后的行容器
    l_p = _emitHeader(l_p l_path t)
    _emitBody(l_p t_obj l_path n_depth g_opt)
)

procedure(_emitTable(l_p t_obj l_path n_depth g_opt "lglxg")  ; -> list
    ; 输出普通子表：表头后接该表的键值。
    ;
    ; **参数**
    ;   l_p      (list) - tconc 行容器
    ;   t_obj    (table) - 子表
    ;   l_path   (list[str]) - 完整表路径
    ;   n_depth  (int) - 当前嵌套深度
    ;   g_opt    (table) - 编码选项表
    ;
    ; **返回**
    ;   (list) - 更新后的行容器
    when(n_depth > g_opt["maxDepth"]
        error("ycToml::encode: nesting too deep (limit %d)" g_opt["maxDepth"])
    )
    l_p = _emitHeader(l_p l_path nil)
    _emitBody(l_p t_obj l_path n_depth g_opt)
)

procedure(_emitBody(l_p t_obj l_path n_depth g_opt "lglxg")  ; -> list
    ; 输出表体的标量键值，再递归输出子表与表数组。
    ;
    ; **参数**
    ;   l_p      (list) - tconc 行容器
    ;   t_obj    (table) - 当前表
    ;   l_path   (list[str]) - 当前表路径
    ;   n_depth  (int) - 当前嵌套深度
    ;   g_opt    (table) - 编码选项表
    ;
    ; **返回**
    ;   (list) - 更新后的行容器
    let((l_keys g_val l_child)
        l_keys = _tableKeys(t_obj g_opt)
        foreach(t_key l_keys
            g_val = t_obj[t_key]
            unless(tablep(g_val) || _isTableList(g_val)
                l_p = tconc(l_p
                    lsprintf("%s = %s"
                        _keyRender(_keyStr(t_key g_opt))
                        _encodeValue(g_val n_depth g_opt)
                    )
                )
            )
        )
        foreach(t_key l_keys
            g_val = t_obj[t_key]
            when(tablep(g_val)
                l_p = _emitTable(l_p g_val append1(l_path _keyStr(t_key g_opt)) n_depth + 1 g_opt)
            )
            when(_isTableList(g_val)
                foreach(l_child g_val
                    l_p = _emitElement(l_p l_child append1(l_path _keyStr(t_key g_opt)) n_depth + 1 g_opt)
                )
            )
        )
        l_p
    )
)

procedure(encode(g_val \@key (sortKeys nil) (strict nil) (finalNewline t) (maxDepth nil) "ggggg")  ; -> str
    ; 编码根 table 为 TOML 文本。
    ;
    ; **参数**
    ;   g_val         (table) - 根表
    ;   ?sortKeys     (t|nil) - 每层键排序开关；默认 nil（随表序）
    ;   ?strict       (t|nil) - t 时键必须为字符串；默认 nil
    ;   ?finalNewline (t|nil) - 非空输出末尾是否补换行；默认 t
    ;   ?maxDepth     (int) - 最大嵌套深度；默认 800
    ;
    ; **返回**
    ;   (str) - TOML 文本；不可表示时以 error() 中断
    when(maxDepth == nil
        maxDepth = _maxEncodeDepth
    )
    unless(fixp(maxDepth) && maxDepth >= 1
        error("ycToml::encode: ?maxDepth must be a positive fixnum")
    )
    unless(tablep(g_val)
        error("ycToml::encode: root value must be a table")
    )
    let((g_opt l_p t_out)
        g_opt = makeTable("ycTomlOpt")
        g_opt["sortKeys"] = sortKeys
        g_opt["strict"] = strict
        g_opt["maxDepth"] = maxDepth
        l_p = _emitBody(nil g_val nil 0 g_opt)
        t_out = buildString(car(l_p) "\n")
        if(t_out == ""
            ""
            if(finalNewline
                strcat(t_out "\n")
                t_out
            )
        )
    )
)

unuseNamespace("ycToml")

; END
