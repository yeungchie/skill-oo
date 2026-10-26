;--------------------------
; Program  : codec/ini(core.il)
; Language : Cadence Skill
;--------------------------

ycNamespace:::Require("ycCodec")

useNamespace("ycIni")

; ---------- 基础工具 ----------

procedure(_Build(l_p "l")  ; -> str
    ; 将 tconc 头容器（或 nil）拼接为字符串。
    ;
    ; **参数**
    ;   l_p  (list) - tconc 头容器或 nil
    ;
    ; **返回**
    ;   (str) - 各片段顺序拼接
    buildString(car(l_p) "")
)

procedure(_Code(t_s n_i "tx")  ; -> int | nil
    ; 取字节索引处的字符码（1-based）；索引越界返回 nil。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;   n_i  (int) - 1-based 字节索引
    ;
    ; **返回**
    ;   (int|nil) - 该字节的字符码；越界时为 nil
    let((g_c)
        g_c = getchar(t_s n_i)
        when(g_c
            charToInt(g_c)
        )
    )
)

procedure(_Find(t_s t_sub "tt")  ; -> int | nil
    ; 查找单字节子串首次出现的位置。
    ;
    ; **参数**
    ;   t_s    (str) - 输入串
    ;   t_sub  (str) - 单字节子串
    ;
    ; **返回**
    ;   (int|nil) - 1-based 位置；未找到为 nil
    let((n_len n_i n_c)
        n_len = length(t_s)
        n_c = _Code(t_sub 1)
        n_i = 1
        while(n_i <= n_len && _Code(t_s n_i) != n_c
            n_i = n_i + 1
        )
        when(n_i <= n_len
            n_i
        )
    )
)

procedure(_Ltrim(t_s "t")  ; -> str
    ; 去除字符串左侧的空格与制表符。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;
    ; **返回**
    ;   (str) - 去左侧空白后的串
    let((n_len n_i)
        n_len = length(t_s)
        n_i = 1
        while(n_i <= n_len && (_Code(t_s n_i) == 32 || _Code(t_s n_i) == 9)
            n_i = n_i + 1
        )
        if(n_i > n_len
            ""
            substring(t_s n_i n_len - n_i + 1)
        )
    )
)

procedure(_Rtrim(t_s "t")  ; -> str
    ; 去除字符串右侧的空格与制表符。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;
    ; **返回**
    ;   (str) - 去右侧空白后的串
    let((n_end)
        n_end = length(t_s)
        while(n_end > 0 && (_Code(t_s n_end) == 32 || _Code(t_s n_end) == 9)
            n_end = n_end - 1
        )
        if(n_end == 0
            ""
            substring(t_s 1 n_end)
        )
    )
)

procedure(_Trim(t_s "t")  ; -> str
    ; 去除字符串两侧的空格与制表符。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;
    ; **返回**
    ;   (str) - 去两侧空白后的串
    _Rtrim(_Ltrim(t_s))
)

procedure(_HasControl(t_s "t")  ; -> t | nil
    ; 判断字符串是否含换行、回车、NUL、DEL 等控制字节；制表符例外。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;
    ; **返回**
    ;   (t|nil) - 含控制字节时为 t
    let((n_len n_i n_c g_hit)
        n_len = length(t_s)
        n_i = 1
        while(!g_hit && n_i <= n_len
            n_c = _Code(t_s n_i)
            when((n_c < 32 && n_c != 9) || n_c == 127
                g_hit = t
            )
            n_i = n_i + 1
        )
        g_hit
    )
)

procedure(_LineIndent(t_line "t")  ; -> int
    ; 计算行首空格与制表符的数量。
    ;
    ; **参数**
    ;   t_line  (str) - 单行文本
    ;
    ; **返回**
    ;   (int) - 行首空白字节数
    let((n_len n_i)
        n_len = length(t_line)
        n_i = 1
        while(n_i <= n_len && (_Code(t_line n_i) == 32 || _Code(t_line n_i) == 9)
            n_i = n_i + 1
        )
        n_i - 1
    )
)

; ---------- 文本预处理 ----------

procedure(_Normalize(t_s "t")  ; -> str
    ; 去掉 UTF-8 BOM，并把 CRLF / CR 行尾统一为 LF。
    ;
    ; **参数**
    ;   t_s  (str) - 原始输入
    ;
    ; **返回**
    ;   (str) - 归一化文本
    let((n_i n_len l_p)
        when(length(t_s) >= 3 && _Code(t_s 1) == 239 && _Code(t_s 2) == 187 && _Code(t_s 3) == 191
            t_s = substring(t_s 4)
        )
        n_i = 1
        n_len = length(t_s)
        while(n_i <= n_len
            if(_Code(t_s n_i) == 13
                {
                l_p = tconc(l_p "\n")
                n_i = n_i + 1
                when(_Code(t_s n_i) == 10
                    n_i = n_i + 1
                )
                }
                {
                l_p = tconc(l_p substring(t_s n_i 1))
                n_i = n_i + 1
                }
            )
        )
        _Build(l_p)
    )
)

procedure(_SplitLines(t_s "t")  ; -> list
    ; 按 LF 拆行；输入须已归一化。
    ;
    ; **参数**
    ;   t_s  (str) - 归一化文本
    ;
    ; **返回**
    ;   (list[str]) - 行列表；空串为 nil，末尾换行不产生额外空行
    let((l_res n_start n_len n_k)
        n_len = length(t_s)
        n_start = 1
        for(n_k 1 n_len
            when(_Code(t_s n_k) == 10
                l_res = tconc(l_res substring(t_s n_start n_k - n_start))
                n_start = n_k + 1
            )
        )
        when(n_start <= n_len
            l_res = tconc(l_res substring(t_s n_start n_len - n_start + 1))
        )
        car(l_res)
    )
)

; ---------- 选项与名字 ----------

procedure(_Delim(g_delim t_ctx "gt")  ; -> str
    ; 校验分隔符：nil 取 "="，否则为单字节可打印字符，排除注释与括号字符。
    ;
    ; **参数**
    ;   g_delim  (str|nil) - 用户给定分隔符
    ;   t_ctx    (str) - 错误前缀
    ;
    ; **返回**
    ;   (str) - 分隔符；类型、长度或字符非法时报错
    when(g_delim == nil
        g_delim = "="
    )
    unless(stringp(g_delim) && length(g_delim) == 1
        error("%s: ?delimiter must be a single-byte string" t_ctx)
    )
    let((n_c)
        n_c = _Code(g_delim 1)
        when(n_c < 33 || n_c == 127 || n_c == 35 || n_c == 59 || n_c == 91 || n_c == 93
            error("%s: ?delimiter must be a printable character other than '#' ';' '[' ']'" t_ctx)
        )
        g_delim
    )
)

procedure(_Policy(g_dup t_ctx "gt")  ; -> str
    ; 校验重复键策略：nil 取 "error"，允许 "error" / "first" / "last"。
    ;
    ; **参数**
    ;   g_dup  (str|nil) - 用户给定策略
    ;   t_ctx  (str) - 错误前缀
    ;
    ; **返回**
    ;   (str) - 策略名；非法值报错
    when(g_dup == nil
        g_dup = "error"
    )
    unless(stringp(g_dup) && member(g_dup '("error" "first" "last"))
        error("%s: ?duplicates must be \"error\", \"first\", or \"last\"" t_ctx)
    )
    g_dup
)

procedure(_Error(n_line n_col t_msg "xxt")  ; -> never
    ; 按统一格式 error() 中断：ycIni::Decode: <说明> at line <行>, column <列>。
    ;
    ; **参数**
    ;   n_line  (int) - 行号（1-based）
    ;   n_col   (int) - 列号（1-based，按字节）
    ;   t_msg   (str) - 错误说明（英文短语）
    ;
    ; **返回**
    ;   (never) - 总是调用 error()，不返回
    error("ycIni::Decode: %s at line %d, column %d" t_msg n_line n_col)
)

procedure(_NewTable()  ; -> table
    ; 创建使用 ycCodec::Missing 作为缺省值的 INI 表。
    ;
    ; **返回**
    ;   (table) - 空表
    makeTable("ycIniTable" ycCodec:::Missing)
)

procedure(_HasKey(t_obj t_key "gt")  ; -> t | nil
    ; 判断表是否已有该键；缺省哨兵不算存在。
    ;
    ; **参数**
    ;   t_obj  (table) - 目标表
    ;   t_key  (str) - 键名
    ;
    ; **返回**
    ;   (t|nil) - 存在时为 t
    t_obj[t_key] != ycCodec:::Missing
)

procedure(_KeyText(g_key g_opt "gg")  ; -> str
    ; 把 table 键转为可写回 INI 的键文本。
    ;
    ; **参数**
    ;   g_key  (any) - 键（str/sym/fixnum）
    ;   g_opt  (table) - 编码选项（strict、delimiter）
    ;
    ; **返回**
    ;   (str) - 键文本；严格模式或不可回写内容报错
    when(g_opt["strict"] && !stringp(g_key)
        error("ycIni::Encode: strict mode requires string keys, got %A" g_key)
    )
    let((t_key n_c)
        t_key = cond(
            (stringp(g_key) g_key)
            (symbolp(g_key) symbolToString(g_key))
            (fixp(g_key) sprintf(nil "%d" g_key))
            (t
                error("ycIni::Encode: unsupported table key of type %s" symbolToString(type(g_key)))
            )
        )
        when(t_key == ""
            error("ycIni::Encode: key must not be empty")
        )
        unless(_Trim(t_key) == t_key
            error("ycIni::Encode: key must not have leading or trailing whitespace")
        )
        when(_HasControl(t_key)
            error("ycIni::Encode: control character in key %A" t_key)
        )
        n_c = _Code(t_key 1)
        when(n_c == 91 || n_c == 35 || n_c == 59
            error("ycIni::Encode: key cannot start with '[' '#' or ';'")
        )
        when(_Find(t_key g_opt["delimiter"])
            error("ycIni::Encode: key must not contain the delimiter %A" g_opt["delimiter"])
        )
        t_key
    )
)

procedure(_SectionText(g_key g_opt "gg")  ; -> str
    ; 把 table 键转为可写回 INI 的段名。
    ;
    ; **参数**
    ;   g_key  (any) - 键（str/sym/fixnum）
    ;   g_opt  (table) - 编码选项（strict）
    ;
    ; **返回**
    ;   (str) - 段名；严格模式或不可回写内容报错
    when(g_opt["strict"] && !stringp(g_key)
        error("ycIni::Encode: strict mode requires string keys, got %A" g_key)
    )
    let((t_name)
        t_name = cond(
            (stringp(g_key) g_key)
            (symbolp(g_key) symbolToString(g_key))
            (fixp(g_key) sprintf(nil "%d" g_key))
            (t
                error("ycIni::Encode: unsupported table key of type %s" symbolToString(type(g_key)))
            )
        )
        when(t_name == ""
            error("ycIni::Encode: section name must not be empty")
        )
        unless(_Trim(t_name) == t_name
            error("ycIni::Encode: section name must not have leading or trailing whitespace")
        )
        when(_HasControl(t_name)
            error("ycIni::Encode: control character in section name %A" t_name)
        )
        when(_Find(t_name "[") || _Find(t_name "]")
            error("ycIni::Encode: section name must not contain '[' or ']'")
        )
        t_name
    )
)

procedure(_NameText(g_key g_val g_opt t_mode "gggt")  ; -> str
    ; 按使用位置把键转为键文本或段名。
    ;
    ; **参数**
    ;   g_key   (any) - 键
    ;   g_val   (any) - 键对应值
    ;   g_opt   (table) - 编码选项
    ;   t_mode  (str) - "root" 或 "section"
    ;
    ; **返回**
    ;   (str) - 键文本或段名
    if(t_mode == "root" && tablep(g_val)
        _SectionText(g_key g_opt)
        _KeyText(g_key g_opt)
    )
)

procedure(_NumText(g_n t_ctx "nt")  ; -> str
    ; 把有限数值转为最短可回读文本。
    ;
    ; **参数**
    ;   g_n    (num) - fixnum 或 flonum
    ;   t_ctx  (str) - 错误前缀
    ;
    ; **返回**
    ;   (str) - 数字文本；inf / nan 报错
    cond(
        (fixp(g_n)
            sprintf(nil "%d" g_n)
        )
        (isNaN(g_n) || isInfinity(g_n)
            error("%s: cannot represent non-finite numbers" t_ctx)
        )
        (t
            let((t_s)
                t_s = sprintf(nil "%.15g" g_n)
                unless(atof(t_s) == g_n
                    t_s = sprintf(nil "%.17g" g_n)
                )
                t_s
            )
        )
    )
)

procedure(_ValueText(g_val t_ctx "gt")  ; -> str
    ; 把值转为可写回 INI 的文本。
    ;
    ; **参数**
    ;   g_val  (any) - 值
    ;   t_ctx  (str) - 错误前缀
    ;
    ; **返回**
    ;   (str) - 文本；容器、哨兵、控制字符或首尾空白报错
    let((t_text)
        t_text = cond(
            (g_val == nil "")
            (g_val == t || g_val == ycCodec:::True "true")
            (g_val == ycCodec:::False "false")
            (g_val == ycCodec:::Null
                error("%s: cannot dump the Null marker" t_ctx)
            )
            (g_val == ycCodec:::Missing
                error("%s: cannot dump the Missing marker" t_ctx)
            )
            (stringp(g_val) g_val)
            (numberp(g_val) _NumText(g_val t_ctx))
            (symbolp(g_val) symbolToString(g_val))
            (tablep(g_val)
                error("%s: nested tables are not supported" t_ctx)
            )
            (listp(g_val)
                error("%s: list values are not supported" t_ctx)
            )
            (t
                error("%s: unsupported value of type %s" t_ctx symbolToString(type(g_val)))
            )
        )
        unless(_Trim(t_text) == t_text
            error("%s: value must not have leading or trailing whitespace" t_ctx)
        )
        when(_HasControl(t_text)
            error("%s: control character in value %A" t_ctx t_text)
        )
        t_text
    )
)

procedure(_TableKeys(t_obj g_opt t_mode "ggt")  ; -> list
    ; 校验并取出表键；检测字符串化碰撞，并按选项排序。
    ;
    ; **参数**
    ;   t_obj   (table) - 待处理表
    ;   g_opt   (table) - 编码选项
    ;   t_mode  (str) - "root" 或 "section"
    ;
    ; **返回**
    ;   (list) - 原始键列表；键非法或文本碰撞时报错
    let((t_byText l_texts t_text g_key)
        t_byText = makeTable("ycIniKeys" ycCodec:::Missing)
        foreach(g_key t_obj
            t_text = _NameText(g_key t_obj[g_key] g_opt t_mode)
            when(t_byText[t_text] != ycCodec:::Missing
                error("ycIni::Encode: duplicate key %A after string conversion" t_text)
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

unuseNamespace("ycIni")

; END
