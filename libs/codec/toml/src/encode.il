;--------------------------
; Program  : codec/toml(encode.il)
; Language : Cadence Skill
;--------------------------

ycNamespace:::Require("ycCodec")

useNamespace("ycToml")

; 编码默认嵌套深度上限；与其它 codec 保持一致。
_MaxEncodeDepth = 800


; ---------- 键与字符串 ----------

procedure(_KeyStr(g_key g_opt "gg")  ; -> str
    ; 将 table 键转为文本：字符串原样、符号取名、fixnum 转十进制。
    ;
    ; **参数**
    ;   g_key  (any) - 键值（str/sym/int）
    ;   g_opt  (table) - 编码选项表
    ;
    ; **返回**
    ;   (str) - 键文本；其他键型报错
    when(g_opt["strict"] && !stringp(g_key)
        error("ycToml::Encode: strict mode requires string keys, got %A" g_key)
    )
    cond(
        (stringp(g_key) g_key)
        (symbolp(g_key) symbolToString(g_key))
        (fixp(g_key) sprintf(nil "%d" g_key))
        (t
            error("ycToml::Encode: unsupported table key of type %s" symbolToString(type(g_key)))
        )
    )
)

procedure(_KeyRender(t_key "t")  ; -> str
    ; 将单个键渲染为裸键或双引号键。
    ;
    ; **参数**
    ;   t_key  (str) - 键文本
    ;
    ; **返回**
    ;   (str) - TOML 键文本
    if(pcreMatchp("^[A-Za-z0-9_-]+\\z" t_key)
        t_key
        _EncodeString(t_key)
    )
)

procedure(_PathRender(l_path "l")  ; -> str
    ; 将键路径渲染为点分表头路径。
    ;
    ; **参数**
    ;   l_path  (list[str]) - 键路径
    ;
    ; **返回**
    ;   (str) - 点分路径
    let((p)
        foreach(key l_path
            p = tconc(p _KeyRender(key))
        )
        buildString(car(p) ".")
    )
)

procedure(_EncodeString(t_s "t")  ; -> str
    ; 输出基本字符串：引号/反斜杠/控制字节转义，其余 UTF-8 字节原样透传。
    ;
    ; **参数**
    ;   t_s  (str) - 待输出字符串
    ;
    ; **返回**
    ;   (str) - 带双引号的 TOML 基本字符串
    unless(_ValidUtf8(t_s)
        error("ycToml::Encode: invalid UTF-8 string")
    )
    let((len run p c)
        len = length(t_s)
        run = 1
        p = nil
        when(0 < len
            for(k 1 len
                c = _Code(t_s k)
                cond(
                    (c == 34 || c == 92 || c < 32 || c == 127
                        {
                        when(run < k
                            p = tconc(p substring(t_s run k - run))
                        )
                        p = tconc(p
                            case(c
                                (34 "\\\"")
                                (92 "\\\\")
                                (8 "\\b")
                                (9 "\\t")
                                (10 "\\n")
                                (12 "\\f")
                                (13 "\\r")
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
    ; 数字输出：fixnum 十进制；flonum 最短可回环，inf/nan 按 TOML 字面量输出。
    ;
    ; **参数**
    ;   n_num  (num) - fixnum 或 flonum
    ;
    ; **返回**
    ;   (str) - TOML 数字文本
    cond(
        (fixp(n_num)
            sprintf(nil "%d" n_num)
        )
        (isNaN(n_num)
            "nan"
        )
        (isInfinity(n_num)
            if(0 < n_num "inf" "-inf")
        )
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

; ---------- 值输出 ----------

procedure(_EncodeValue(g_val n_depth g_opt "gxg")  ; -> str
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
        error("ycToml::Encode: nesting too deep (limit %d)" g_opt["maxDepth"])
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
            error("ycToml::Encode: TOML has no null value")
        )
        (g_val == ycCodec:::Missing
            error("ycToml::Encode: cannot dump the Missing marker")
        )
        (stringp(g_val)
            _EncodeString(g_val)
        )
        (numberp(g_val)
            _EncodeNumber(g_val)
        )
        (tablep(g_val)
            _EncodeTable(g_val n_depth g_opt)
        )
        (listp(g_val)
            _EncodeArray(g_val n_depth g_opt)
        )
        (t
            error("ycToml::Encode: cannot dump value of type %s" symbolToString(type(g_val)))
        )
    )
)

procedure(_EncodeArray(l_arr n_depth g_opt "lxg")  ; -> str
    ; 输出数组为方括号形式；元素递归输出为内联值。
    ;
    ; **参数**
    ;   l_arr    (list) - 数组
    ;   n_depth  (int) - 当前嵌套深度
    ;   g_opt    (table) - 编码选项表
    ;
    ; **返回**
    ;   (str) - 数组文本
    let((p)
        foreach(item l_arr
            p = tconc(p _EncodeValue(item n_depth + 1 g_opt))
        )
        lsprintf("[%s]" buildString(car(p) ", "))
    )
)

procedure(_EncodeTable(g_obj n_depth g_opt "gxg")  ; -> str
    ; 输出内联表；键按选项排序并递归输出值。
    ;
    ; **参数**
    ;   g_obj    (table) - 内联表
    ;   n_depth  (int) - 当前嵌套深度
    ;   g_opt    (table) - 编码选项表
    ;
    ; **返回**
    ;   (str) - 内联表文本
    let((keys p)
        keys = _TableKeys(g_obj g_opt)
        foreach(key keys
            p = tconc(p
                lsprintf("%s = %s"
                    _KeyRender(key)
                    _EncodeValue(g_obj[key] n_depth + 1 g_opt)
                )
            )
        )
        if(car(p)
            lsprintf("{ %s }" buildString(car(p) ", "))
            "{}"
        )
    )
)

; ---------- 文档输出 ----------

procedure(_TableKeys(g_obj g_opt "gg")  ; -> list
    ; 取出 table 的原始键，检测字符串化碰撞，并按选项排序。
    ;
    ; **参数**
    ;   g_obj    (table) - 待处理表
    ;   g_opt    (table) - 编码选项表
    ;
    ; **返回**
    ;   (list) - 原始键列表
    let((byText texts text key)
        byText = makeTable("ycTomlKeys" ycCodec:::Missing)
        texts = nil
        foreach(key2 g_obj
            text = _KeyStr(key2 g_opt)
            when(byText[text] != ycCodec:::Missing
                error("ycToml::Encode: duplicate key %A after string conversion" text)
            )
            byText[text] = key2
            texts = tconc(texts text)
        )
        texts = car(texts)
        when(g_opt["sortKeys"]
            texts = sort(texts 'alphalessp)
        )
        let((res)
            if(g_opt["sortKeys"]
                foreach(text2 texts
                    res = tconc(res byText[text2])
                )
                foreach(key2 g_obj
                    res = tconc(res key2)
                )
            )
            car(res)
        )
    )
)

procedure(_EmitHeader(l_p l_path g_array "llg")  ; -> list
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
            lsprintf("[[%s]]" _PathRender(l_path))
            lsprintf("[%s]" _PathRender(l_path))
        )
    )
)

procedure(_EmitElement(l_p g_obj l_path n_depth g_opt "lglxg")  ; -> list
    ; 输出一个表数组元素：[[path]] 后接该元素的键值。
    ;
    ; **参数**
    ;   l_p      (list) - tconc 行容器
    ;   g_obj    (table) - 元素表
    ;   l_path   (list[str]) - 完整表路径
    ;   n_depth  (int) - 当前嵌套深度
    ;   g_opt    (table) - 编码选项表
    ;
    ; **返回**
    ;   (list) - 更新后的行容器
    l_p = _EmitHeader(l_p l_path t)
    _EmitBody(l_p g_obj l_path n_depth g_opt)
)

procedure(_EmitTable(l_p g_obj l_path n_depth g_opt "lglxg")  ; -> list
    ; 输出普通子表：表头后接该表的键值。
    ;
    ; **参数**
    ;   l_p      (list) - tconc 行容器
    ;   g_obj    (table) - 子表
    ;   l_path   (list[str]) - 完整表路径
    ;   n_depth  (int) - 当前嵌套深度
    ;   g_opt    (table) - 编码选项表
    ;
    ; **返回**
    ;   (list) - 更新后的行容器
    when(n_depth > g_opt["maxDepth"]
        error("ycToml::Encode: nesting too deep (limit %d)" g_opt["maxDepth"])
    )
    l_p = _EmitHeader(l_p l_path nil)
    _EmitBody(l_p g_obj l_path n_depth g_opt)
)

procedure(_EmitBody(l_p g_obj l_path n_depth g_opt "lglxg")  ; -> list
    ; 输出表体的标量键值，再递归输出子表与表数组。
    ;
    ; **参数**
    ;   l_p      (list) - tconc 行容器
    ;   g_obj    (table) - 当前表
    ;   l_path   (list[str]) - 当前表路径
    ;   n_depth  (int) - 当前嵌套深度
    ;   g_opt    (table) - 编码选项表
    ;
    ; **返回**
    ;   (list) - 更新后的行容器
    when(n_depth > g_opt["maxDepth"]
        error("ycToml::Encode: nesting too deep (limit %d)" g_opt["maxDepth"])
    )
    let((keys val child)
        keys = _TableKeys(g_obj g_opt)
        foreach(key keys
            val = g_obj[key]
            unless(tablep(val) || _IsTableList(val)
                l_p = tconc(l_p
                    lsprintf("%s = %s"
                        _KeyRender(_KeyStr(key g_opt))
                        _EncodeValue(val n_depth g_opt)
                    )
                )
            )
        )
        foreach(key keys
            val = g_obj[key]
            when(tablep(val)
                l_p = _EmitTable(l_p val append1(l_path _KeyStr(key g_opt)) n_depth + 1 g_opt)
            )
            when(_IsTableList(val)
                foreach(child2 val
                    l_p = _EmitElement(l_p child2 append1(l_path _KeyStr(key g_opt)) n_depth + 1 g_opt)
                )
            )
        )
        l_p
    )
)

procedure(Encode(g_val \@key (sortKeys nil) (strict nil) (finalNewline t) (maxDepth nil) "ggggg")  ; -> str
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
        maxDepth = _MaxEncodeDepth
    )
    unless(fixp(maxDepth) && maxDepth >= 1
        error("ycToml::Encode: ?maxDepth must be a positive fixnum")
    )
    unless(tablep(g_val)
        error("ycToml::Encode: root value must be a table")
    )
    let((opt p out)
        opt = makeTable("ycTomlOpt")
        opt["sortKeys"] = sortKeys
        opt["strict"] = strict
        opt["maxDepth"] = maxDepth
        p = _EmitBody(nil g_val nil 0 opt)
        out = buildString(car(p) "\n")
        cond(
            (out == "" "")
            (finalNewline
                strcat(out "\n")
            )
            (t out)
        )
    )
)

unuseNamespace("ycToml")

; END
