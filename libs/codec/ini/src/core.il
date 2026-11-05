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
    let((c)
        c = getchar(t_s n_i)
        when(c
            charToInt(c)
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
    let((len i c)
        len = length(t_s)
        c = _Code(t_sub 1)
        i = 1
        while(i <= len && _Code(t_s i) != c
            i++
        )
        when(i <= len
            i
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
    let((len i)
        len = length(t_s)
        i = 1
        while(i <= len && (_Code(t_s i) == 32 || _Code(t_s i) == 9)
            i++
        )
        if(i > len
            ""
            substring(t_s i len - i + 1)
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
    let((end)
        end = length(t_s)
        while(end > 0 && (_Code(t_s end) == 32 || _Code(t_s end) == 9)
            end--
        )
        if(end == 0
            ""
            substring(t_s 1 end)
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
    let((len i c hit)
        len = length(t_s)
        i = 1
        while(!hit && i <= len
            c = _Code(t_s i)
            when((c < 32 && c != 9) || c == 127
                hit = t
            )
            i++
        )
        hit
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
    let((len i)
        len = length(t_line)
        i = 1
        while(i <= len && (_Code(t_line i) == 32 || _Code(t_line i) == 9)
            i++
        )
        i - 1
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
    let((i len p)
        when(length(t_s) >= 3 && _Code(t_s 1) == 239 && _Code(t_s 2) == 187 && _Code(t_s 3) == 191
            t_s = substring(t_s 4)
        )
        i = 1
        len = length(t_s)
        while(i <= len
            if(_Code(t_s i) == 13
            then
                p = tconc(p "\n")
                i++
                when(_Code(t_s i) == 10
                    i++
                )
            else
                p = tconc(p substring(t_s i 1))
                i++
            )
        )
        _Build(p)
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
    let((res start len k)
        len = length(t_s)
        start = 1
        for(k2 1 len
            when(_Code(t_s k2) == 10
                res = tconc(res substring(t_s start k2 - start))
                start = k2 + 1
            )
        )
        when(start <= len
            res = tconc(res substring(t_s start len - start + 1))
        )
        car(res)
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
    let((c)
        c = _Code(g_delim 1)
        when(c < 33 || c == 127 || c == 35 || c == 59 || c == 91 || c == 93
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

procedure(_HasKey(g_obj t_key "gt")  ; -> t | nil
    ; 判断表是否已有该键；缺省哨兵不算存在。
    ;
    ; **参数**
    ;   g_obj  (table) - 目标表
    ;   t_key  (str) - 键名
    ;
    ; **返回**
    ;   (t|nil) - 存在时为 t
    g_obj[t_key] != ycCodec:::Missing
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
    let((key c)
        key = cond(
            (stringp(g_key) g_key)
            (symbolp(g_key) symbolToString(g_key))
            (fixp(g_key) sprintf(nil "%d" g_key))
            (t
                error("ycIni::Encode: unsupported table key of type %s" symbolToString(type(g_key)))
            )
        )
        when(key == ""
            error("ycIni::Encode: key must not be empty")
        )
        unless(_Trim(key) == key
            error("ycIni::Encode: key must not have leading or trailing whitespace")
        )
        when(_HasControl(key)
            error("ycIni::Encode: control character in key %A" key)
        )
        c = _Code(key 1)
        when(c == 91 || c == 35 || c == 59
            error("ycIni::Encode: key cannot start with '[' '#' or ';'")
        )
        when(_Find(key g_opt["delimiter"])
            error("ycIni::Encode: key must not contain the delimiter %A" g_opt["delimiter"])
        )
        key
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
    let((name)
        name = cond(
            (stringp(g_key) g_key)
            (symbolp(g_key) symbolToString(g_key))
            (fixp(g_key) sprintf(nil "%d" g_key))
            (t
                error("ycIni::Encode: unsupported table key of type %s" symbolToString(type(g_key)))
            )
        )
        when(name == ""
            error("ycIni::Encode: section name must not be empty")
        )
        unless(_Trim(name) == name
            error("ycIni::Encode: section name must not have leading or trailing whitespace")
        )
        when(_HasControl(name)
            error("ycIni::Encode: control character in section name %A" name)
        )
        when(_Find(name "[") || _Find(name "]")
            error("ycIni::Encode: section name must not contain '[' or ']'")
        )
        name
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

procedure(_NumText(n_num t_ctx "nt")  ; -> str
    ; 把有限数值转为最短可回读文本。
    ;
    ; **参数**
    ;   n_num    (num) - fixnum 或 flonum
    ;   t_ctx  (str) - 错误前缀
    ;
    ; **返回**
    ;   (str) - 数字文本；inf / nan 报错
    cond(
        (fixp(n_num)
            sprintf(nil "%d" n_num)
        )
        (isNaN(n_num) || isInfinity(n_num)
            error("%s: cannot represent non-finite numbers" t_ctx)
        )
        (t
            let((item)
                item = sprintf(nil "%.15g" n_num)
                unless(atof(item) == n_num
                    item = sprintf(nil "%.17g" n_num)
                )
                item
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
    let((text)
        text = cond(
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
        unless(_Trim(text) == text
            error("%s: value must not have leading or trailing whitespace" t_ctx)
        )
        when(_HasControl(text)
            error("%s: control character in value %A" t_ctx text)
        )
        text
    )
)

procedure(_TableKeys(g_obj g_opt t_mode "ggt")  ; -> list
    ; 校验并取出表键；检测字符串化碰撞，并按选项排序。
    ;
    ; **参数**
    ;   g_obj   (table) - 待处理表
    ;   g_opt   (table) - 编码选项
    ;   t_mode  (str) - "root" 或 "section"
    ;
    ; **返回**
    ;   (list) - 原始键列表；键非法或文本碰撞时报错
    let((byText texts text key)
        byText = makeTable("ycIniKeys" ycCodec:::Missing)
        foreach(key2 g_obj
            text = _NameText(key2 g_obj[key2] g_opt t_mode)
            when(byText[text] != ycCodec:::Missing
                error("ycIni::Encode: duplicate key %A after string conversion" text)
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

unuseNamespace("ycIni")

; END
