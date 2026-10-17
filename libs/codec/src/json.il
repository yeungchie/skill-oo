useNamespace("ycCodec")

; 哨兵：false/null 不坍缩为 nil（nil 仅表示空数组）；jsonMissing 为对象缺键的默认标记。
jsonFalse = 'jsonFalse
jsonNull = 'jsonNull
jsonMissing = 'jsonMissing

; 解析与输出的嵌套深度上限。
_jsonMaxDepth = 1000


; ---------- 基础工具 ----------

procedure(_jsonCode(t_s n_i "tn")  ; -> int | nil
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

procedure(_jsonDigitp(g_c "g")  ; -> t | nil
    ; 判断字符码是否为 ASCII 数字（nil 安全）。
    ;
    ; **参数**
    ;   g_c  (any) - 字符码或 nil
    ;
    ; **返回**
    ;   (t|nil) - 48..57 时为 t，否则 nil
    g_c && g_c >= 48 && g_c <= 57
)

procedure(_jsonLineCol(t_s n_i "tn")  ; -> list
    ; 按字节索引计算行列：行/列均 1-based，列按行内字节偏移。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;   n_i  (int) - 1-based 字节索引
    ;
    ; **返回**
    ;   (list) - (行 列) 两元素表
    let((n_line n_last)
        n_line = 1
        n_last = 0
        when(1 < n_i
            for(n_k 1 n_i - 1
                when(_jsonCode(t_s n_k) == 10
                    n_line = n_line + 1
                    n_last = n_k
                )
            )
        )
        list(n_line n_i - n_last)
    )
)

procedure(_jsonError(t_s n_i t_msg "tnt")  ; -> never
    ; 按统一格式 error() 中断：ycCodec: <说明> at line <行>, column <列>。
    ;
    ; **参数**
    ;   t_s    (str) - 输入串
    ;   n_i    (int) - 1-based 字节索引（错误位置）
    ;   t_msg  (str) - 错误说明（英文短语）
    ;
    ; **返回**
    ;   (never) - 总是调用 error()，不返回
    let((l_pos)
        l_pos = _jsonLineCol(t_s n_i)
        error("ycCodec: %s at line %d, column %d" t_msg car(l_pos) cadr(l_pos))
    )
)

procedure(_jsonBuild(l_p "l")  ; -> str
    ; 将 tconc 头容器（或 nil）拼接为字符串。
    ;
    ; **参数**
    ;   l_p  (list) - tconc 头容器或 nil
    ;
    ; **返回**
    ;   (str) - 各片段顺序拼接
    buildString(car(l_p) "")
)


; ---------- 扫描器 ----------

procedure(_jsonSkipWs(t_s n_i g_relaxed "tng")  ; -> int
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
            n_c = _jsonCode(t_s n_i)
            cond(
                (n_c == 32 || n_c == 9 || n_c == 10 || n_c == 13
                    n_i = n_i + 1
                )
                (g_relaxed && n_c == 47 && _jsonCode(t_s n_i + 1) == 47
                    n_i = n_i + 2
                    while(n_i <= n_len && _jsonCode(t_s n_i) != 10
                        n_i = n_i + 1
                    )
                )
                (g_relaxed && n_c == 47 && _jsonCode(t_s n_i + 1) == 42
                    n_close = n_i + 2
                    while(n_close <= n_len - 1 && !(_jsonCode(t_s n_close) == 42 && _jsonCode(t_s n_close + 1) == 47)
                        n_close = n_close + 1
                    )
                    if(n_close <= n_len - 1
                        n_i = n_close + 2
                        _jsonError(t_s n_i "unterminated block comment")
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

procedure(_jsonHex4(t_s n_i "tn")  ; -> int
    ; 解析 \uXXXX 的 4 位十六进制（大小写均可）。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;   n_i  (int) - 首个十六进制位的位置
    ;
    ; **返回**
    ;   (int) - 0..65535 的码元值
    let((n_len n_v n_c n_d)
        n_len = length(t_s)
        when(n_i + 3 > n_len
            _jsonError(t_s n_len + 1 "invalid \\u escape")
        )
        n_v = 0
        for(n_k n_i n_i + 3
            n_c = _jsonCode(t_s n_k)
            cond(
                (n_c >= 48 && n_c <= 57 n_d = n_c - 48)
                (n_c >= 97 && n_c <= 102 n_d = n_c - 87)
                (n_c >= 65 && n_c <= 70 n_d = n_c - 55)
                (t _jsonError(t_s n_k "invalid \\u escape"))
            )
            n_v = n_v * 16 + n_d
        )
        n_v
    )
)

procedure(_jsonUtf8Str(n_cp "n")  ; -> str
    ; 将 Unicode 码点编码为 UTF-8 字节串（1..4 字节，逐字节拼接）。
    ;
    ; **参数**
    ;   n_cp  (int) - 0..0x10FFFF 的码点
    ;
    ; **返回**
    ;   (str) - UTF-8 字节串
    cond(
        (n_cp < 128
            strcat(intToChar(n_cp))
        )
        (n_cp < 2048
            strcat(intToChar(192 + n_cp/64) intToChar(128 + remainder(n_cp 64)))
        )
        (n_cp < 65536
            strcat(
                intToChar(224 + n_cp/4096)
                intToChar(128 + remainder(n_cp/64 64))
                intToChar(128 + remainder(n_cp 64))
            )
        )
        (t
            strcat(
                intToChar(240 + n_cp/262144)
                intToChar(128 + remainder(n_cp/4096 64))
                intToChar(128 + remainder(n_cp/64 64))
                intToChar(128 + remainder(n_cp 64))
            )
        )
    )
)

procedure(_jsonLiteral(t_s n_i "tn")  ; -> list
    ; 在位置处匹配 true/false/null 字面量（大小写敏感）。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;   n_i  (int) - 字面量首字符位置
    ;
    ; **返回**
    ;   (list) - (值 下一位置)；值分别为 t、jsonFalse、jsonNull
    cond(
        (substring(t_s n_i 4) == "true"
            list(t n_i + 4)
        )
        (substring(t_s n_i 5) == "false"
            list(jsonFalse n_i + 5)
        )
        (substring(t_s n_i 4) == "null"
            list(jsonNull n_i + 4)
        )
        (t
            _jsonError(t_s n_i "invalid literal")
        )
    )
)

procedure(_jsonNumber(t_s n_i "tn")  ; -> list
    ; 按 JSON 语法扫描数字：严格校验整数/小数/指数写法，超 fixnum 范围回 flonum。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;   n_i  (int) - 数字首字符位置（'-' 或数字）
    ;
    ; **返回**
    ;   (list) - (数值 下一位置)；整数走 fixnum（范围内），否则 flonum
    let((n_len n_k n_c t_tok n_v g_num)
        n_len = length(t_s)
        n_k = n_i
        n_c = _jsonCode(t_s n_k)
        when(n_c == 45
            n_k = n_k + 1
            n_c = _jsonCode(t_s n_k)
        )
        cond(
            (n_c == 48
                n_k = n_k + 1
            )
            (n_c >= 49 && n_c <= 57
                n_k = n_k + 1
                while(n_k <= n_len && _jsonDigitp(_jsonCode(t_s n_k))
                    n_k = n_k + 1
                )
            )
            (t
                _jsonError(t_s n_i "invalid number")
            )
        )
        when(n_c == 48 && _jsonDigitp(_jsonCode(t_s n_k))
            _jsonError(t_s n_k "invalid number")
        )
        when(_jsonCode(t_s n_k) == 46
            n_k = n_k + 1
            unless(_jsonDigitp(_jsonCode(t_s n_k))
                _jsonError(t_s n_i "invalid number")
            )
            while(n_k <= n_len && _jsonDigitp(_jsonCode(t_s n_k))
                n_k = n_k + 1
            )
        )
        n_c = _jsonCode(t_s n_k)
        when(n_c == 101 || n_c == 69
            n_k = n_k + 1
            n_c = _jsonCode(t_s n_k)
            when(n_c == 43 || n_c == 45
                n_k = n_k + 1
            )
            unless(_jsonDigitp(_jsonCode(t_s n_k))
                _jsonError(t_s n_i "invalid number")
            )
            while(n_k <= n_len && _jsonDigitp(_jsonCode(t_s n_k))
                n_k = n_k + 1
            )
        )
        t_tok = substring(t_s n_i n_k - n_i)
        if(pcreMatchp("[.eE]" t_tok)
            list(atof(t_tok) n_k)
            {
            n_v = atof(t_tok)
            if(n_v >= (-2147483647 - 1) && n_v <= 2147483647
                g_num = atoi(t_tok)
                g_num = n_v
            )
            list(g_num n_k)
            }
        )
    )
)

procedure(_jsonString(t_s n_i "tn")  ; -> list
    ; 扫描字符串：转义解出实际字符，\uXXXX 合成 UTF-8，代理对合并，孤立代理项报错。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;   n_i  (int) - 起始引号位置
    ;
    ; **返回**
    ;   (list) - (字符串值 闭引号后一位置)
    let((n_len n_k n_c n_run n_esc l_p n_cp n_lo g_done)
        n_len = length(t_s)
        n_k = n_i + 1
        n_run = n_k
        g_done = nil
        while(!g_done
            when(n_k > n_len
                _jsonError(t_s n_k "unterminated string")
            )
            n_c = _jsonCode(t_s n_k)
            cond(
                (n_c == 34
                    when(n_run < n_k
                        l_p = tconc(l_p substring(t_s n_run n_k - n_run))
                    )
                    g_done = t
                )
                (n_c == 92
                    {
                    when(n_run < n_k
                        l_p = tconc(l_p substring(t_s n_run n_k - n_run))
                    )
                    n_esc = n_k
                    n_k = n_k + 1
                    n_c = _jsonCode(t_s n_k)
                    when(!n_c
                        _jsonError(t_s n_esc "unterminated string")
                    )
                    cond(
                        (n_c == 34
                            {
                            l_p = tconc(l_p "\"")
                            n_k = n_k + 1
                            }
                        )
                        (n_c == 92
                            {
                            l_p = tconc(l_p "\\")
                            n_k = n_k + 1
                            }
                        )
                        (n_c == 47
                            {
                            l_p = tconc(l_p "/")
                            n_k = n_k + 1
                            }
                        )
                        (n_c == 98
                            {
                            l_p = tconc(l_p strcat(intToChar(8)))
                            n_k = n_k + 1
                            }
                        )
                        (n_c == 102
                            {
                            l_p = tconc(l_p strcat(intToChar(12)))
                            n_k = n_k + 1
                            }
                        )
                        (n_c == 110
                            {
                            l_p = tconc(l_p strcat(intToChar(10)))
                            n_k = n_k + 1
                            }
                        )
                        (n_c == 114
                            {
                            l_p = tconc(l_p strcat(intToChar(13)))
                            n_k = n_k + 1
                            }
                        )
                        (n_c == 116
                            {
                            l_p = tconc(l_p strcat(intToChar(9)))
                            n_k = n_k + 1
                            }
                        )
                        (n_c == 117
                            {
                            n_cp = _jsonHex4(t_s n_k + 1)
                            n_k = n_k + 5
                            when(n_cp >= 55296 && n_cp <= 56319
                                unless(_jsonCode(t_s n_k) == 92 && _jsonCode(t_s n_k + 1) == 117
                                    _jsonError(t_s n_esc "invalid surrogate pair")
                                )
                                n_lo = _jsonHex4(t_s n_k + 2)
                                unless(n_lo >= 56320 && n_lo <= 57343
                                    _jsonError(t_s n_esc "invalid surrogate pair")
                                )
                                n_cp = 65536 + (n_cp - 55296) * 1024 + n_lo - 56320
                                n_k = n_k + 6
                            )
                            when(n_cp >= 56320 && n_cp <= 57343
                                _jsonError(t_s n_esc "invalid surrogate pair")
                            )
                            l_p = tconc(l_p _jsonUtf8Str(n_cp))
                            }
                        )
                        (t
                            _jsonError(t_s n_esc "invalid escape")
                        )
                    )
                    n_run = n_k
                    }
                )
                (n_c < 32
                    _jsonError(t_s n_k "control character in string")
                )
                (t
                    n_k = n_k + 1
                )
            )
        )
        list(_jsonBuild(l_p) n_k + 1)
    )
)

procedure(_jsonValue(t_s n_i g_relaxed n_depth "tngn")  ; -> list
    ; 解析任意值：按首字符派发到字符串/对象/数组/字面量/数字。
    ;
    ; **参数**
    ;   t_s        (str) - 输入串
    ;   n_i        (int) - 值首字符位置
    ;   g_relaxed  (t|nil) - jsonc 放宽开关
    ;   n_depth    (int) - 当前嵌套深度（顶层值 0）
    ;
    ; **返回**
    ;   (list) - (值 下一位置)；深度超限或字符非法报错
    let((n_c)
        when(n_depth > _jsonMaxDepth
            _jsonError(t_s n_i lsprintf("nesting too deep (limit %d)" _jsonMaxDepth))
        )
        n_c = _jsonCode(t_s n_i)
        when(!n_c
            _jsonError(t_s n_i "unexpected end of input")
        )
        cond(
            (n_c == 34 _jsonString(t_s n_i))
            (n_c == 123 _jsonObject(t_s n_i g_relaxed n_depth))
            (n_c == 91 _jsonArray(t_s n_i g_relaxed n_depth))
            (n_c == 116 _jsonLiteral(t_s n_i))
            (n_c == 102 _jsonLiteral(t_s n_i))
            (n_c == 110 _jsonLiteral(t_s n_i))
            ((n_c == 45 || _jsonDigitp(n_c)) _jsonNumber(t_s n_i))
            (t _jsonError(t_s n_i "unexpected character"))
        )
    )
)

procedure(_jsonObject(t_s n_i g_relaxed n_depth "tngn")  ; -> list
    ; 解析对象：键值对写入 table（缺省标记 jsonMissing）；jsonc 模式允许尾逗号。
    ;
    ; **参数**
    ;   t_s        (str) - 输入串
    ;   n_i        (int) - '{' 位置
    ;   g_relaxed  (t|nil) - jsonc 放宽开关
    ;   n_depth    (int) - 当前嵌套深度
    ;
    ; **返回**
    ;   (list) - (table 闭括号后一位置)
    let((n_k n_c l_r t_key t_obj g_done)
        n_k = _jsonSkipWs(t_s n_i + 1 g_relaxed)
        t_obj = makeTable("ycCodec" jsonMissing)
        g_done = nil
        when(_jsonCode(t_s n_k) == 125
            g_done = t
            n_k = n_k + 1
        )
        while(!g_done
            n_k = _jsonSkipWs(t_s n_k g_relaxed)
            unless(_jsonCode(t_s n_k) == 34
                _jsonError(t_s n_k "expected string key")
            )
            l_r = _jsonString(t_s n_k)
            t_key = car(l_r)
            n_k = _jsonSkipWs(t_s cadr(l_r) g_relaxed)
            unless(_jsonCode(t_s n_k) == 58
                _jsonError(t_s n_k "expected ':'")
            )
            n_k = _jsonSkipWs(t_s n_k + 1 g_relaxed)
            l_r = _jsonValue(t_s n_k g_relaxed n_depth + 1)
            t_obj[t_key] = car(l_r)
            n_k = _jsonSkipWs(t_s cadr(l_r) g_relaxed)
            n_c = _jsonCode(t_s n_k)
            cond(
                (n_c == 125
                    {
                    g_done = t
                    n_k = n_k + 1
                    }
                )
                (n_c == 44
                    {
                    n_k = _jsonSkipWs(t_s n_k + 1 g_relaxed)
                    when(g_relaxed && _jsonCode(t_s n_k) == 125
                        g_done = t
                        n_k = n_k + 1
                    )
                    }
                )
                (t
                    _jsonError(t_s n_k "expected ',' or '}'")
                )
            )
        )
        list(t_obj n_k)
    )
)

procedure(_jsonArray(t_s n_i g_relaxed n_depth "tngn")  ; -> list
    ; 解析数组：元素累积为 list（空数组即 nil）；jsonc 模式允许尾逗号。
    ;
    ; **参数**
    ;   t_s        (str) - 输入串
    ;   n_i        (int) - '[' 位置
    ;   g_relaxed  (t|nil) - jsonc 放宽开关
    ;   n_depth    (int) - 当前嵌套深度
    ;
    ; **返回**
    ;   (list) - (列表或 nil 闭括号后一位置)
    let((n_k n_c l_res l_r g_done)
        n_k = _jsonSkipWs(t_s n_i + 1 g_relaxed)
        l_res = nil
        g_done = nil
        when(_jsonCode(t_s n_k) == 93
            g_done = t
            n_k = n_k + 1
        )
        while(!g_done
            n_k = _jsonSkipWs(t_s n_k g_relaxed)
            l_r = _jsonValue(t_s n_k g_relaxed n_depth + 1)
            l_res = tconc(l_res car(l_r))
            n_k = _jsonSkipWs(t_s cadr(l_r) g_relaxed)
            n_c = _jsonCode(t_s n_k)
            cond(
                (n_c == 93
                    {
                    g_done = t
                    n_k = n_k + 1
                    }
                )
                (n_c == 44
                    {
                    n_k = _jsonSkipWs(t_s n_k + 1 g_relaxed)
                    when(g_relaxed && _jsonCode(t_s n_k) == 93
                        g_done = t
                        n_k = n_k + 1
                    )
                    }
                )
                (t
                    _jsonError(t_s n_k "expected ',' or ']'")
                )
            )
        )
        list(car(l_res) n_k)
    )
)

procedure(_jsonParseText(t_s g_relaxed "tg")  ; -> any
    ; 解析单个 JSON 文档：前导/尾随空白允许，尾随非空白字符报错。
    ;
    ; **参数**
    ;   t_s        (str) - 输入串
    ;   g_relaxed  (t|nil) - jsonc 放宽开关
    ;
    ; **返回**
    ;   (any) - 解析产物
    let((n_k l_r g_val)
        n_k = _jsonSkipWs(t_s 1 g_relaxed)
        l_r = _jsonValue(t_s n_k g_relaxed 0)
        g_val = car(l_r)
        n_k = _jsonSkipWs(t_s cadr(l_r) g_relaxed)
        when(n_k <= length(t_s)
            _jsonError(t_s n_k "unexpected trailing characters")
        )
        g_val
    )
)


; ---------- jsonl 切分与辅助 ----------

procedure(_jsonLineSplit(t_s "t")  ; -> list
    ; 按 \n 切分文本为行列表（保留空行，供行号对应）。
    ;
    ; **参数**
    ;   t_s  (str) - 输入文本
    ;
    ; **返回**
    ;   (list) - 各行文本（不含 \n；行尾 \r 原样保留）
    let((l_res n_len n_start)
        l_res = nil
        n_len = length(t_s)
        when(0 < n_len
            n_start = 1
            for(n_k 1 n_len
                when(_jsonCode(t_s n_k) == 10
                    l_res = tconc(l_res substring(t_s n_start n_k - n_start))
                    n_start = n_k + 1
                )
            )
            when(n_start <= n_len
                l_res = tconc(l_res substring(t_s n_start n_len - n_start + 1))
            )
        )
        car(l_res)
    )
)

procedure(_jsonLineBlankp(t_line "t")  ; -> t | nil
    ; 判断一行是否全为空（空格/制表/回车）。
    ;
    ; **参数**
    ;   t_line  (str) - 行文本（不含 \n）
    ;
    ; **返回**
    ;   (t|nil) - 全空白或空串时为 t
    let((n_len n_c g_blank)
        g_blank = t
        n_len = length(t_line)
        when(0 < n_len
            for(n_k 1 n_len
                unless(_jsonCode(t_line n_k) == 32 || _jsonCode(t_line n_k) == 9 || _jsonCode(t_line n_k) == 13
                    g_blank = nil
                )
            )
        )
        g_blank
    )
)

procedure(_jsonNewlines(n_n "n")  ; -> str
    ; 生成 n_n 个换行符组成的串（jsonl 错误路径的行号前缀）。
    ;
    ; **参数**
    ;   n_n  (int) - 换行个数
    ;
    ; **返回**
    ;   (str) - n_n 个 "\n" 组成的串
    let((t_s)
        t_s = ""
        when(0 < n_n
            for(n_k 1 n_n
                t_s = strcat(t_s "\n")
            )
        )
        t_s
    )
)


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


; ---------- 公开 API ----------

procedure(jsonParse(t_str "t")  ; -> any
    ; 解析严格 JSON 单文档；前导/尾随空白允许，尾随非空白字符报错。
    ;
    ; **参数**
    ;   t_str  (str) - JSON 文本
    ;
    ; **返回**
    ;   (any) - 解析产物（table/list/fixnum/flonum/字符串/t/哨兵）
    unless(stringp(t_str)
        error("ycCodec: jsonParse expects a string")
    )
    _jsonParseText(t_str nil)
)

procedure(jsoncParse(t_str "t")  ; -> any
    ; 解析放宽 JSON 单文档：支持 // 与 /* */ 注释、数组/对象尾逗号。
    ;
    ; **参数**
    ;   t_str  (str) - JSON 文本
    ;
    ; **返回**
    ;   (any) - 解析产物（table/list/fixnum/flonum/字符串/t/哨兵）
    unless(stringp(t_str)
        error("ycCodec: jsoncParse expects a string")
    )
    _jsonParseText(t_str t)
)

procedure(jsonlParse(t_str "t")  ; -> list
    ; 逐行解析 JSON Lines：空行/全空白行跳过，各非空行须为完整文档，错误带原始行号。
    ;
    ; **参数**
    ;   t_str  (str) - JSON Lines 文本
    ;
    ; **返回**
    ;   (list) - 按行序的解析产物列表；无有效行时为 nil
    unless(stringp(t_str)
        error("ycCodec: jsonlParse expects a string")
    )
    let((l_lines l_res l_r t_line n_idx)
        l_lines = _jsonLineSplit(t_str)
        l_res = nil
        n_idx = 0
        while(l_lines
            t_line = car(l_lines)
            n_idx = n_idx + 1
            unless(_jsonLineBlankp(t_line)
                l_r = errset(_jsonParseText(t_line nil) nil)
                if(l_r
                    l_res = tconc(l_res car(l_r))
                    ; 行内报错：以等长换行前缀重跑，令错误行列指向原始行号
                    _jsonParseText(strcat(_jsonNewlines(n_idx - 1) t_line) nil)
                )
            )
            l_lines = cdr(l_lines)
        )
        car(l_res)
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

procedure(jsonlDump(l_vals \@key (sortKeys t) "lg")  ; -> str
    ; 逐行输出值列表为 JSON Lines 文本；非空输入末尾补一个换行。
    ;
    ; **参数**
    ;   l_vals     (list) - 待输出值列表（空表输出空串）
    ;   ?sortKeys  (t|nil) - 对象键排序开关；默认 t
    ;
    ; **返回**
    ;   (str) - 每值一行、行间换行的文本
    unless(listp(l_vals)
        error("ycCodec: jsonlDump expects a list")
    )
    let((l_p t_s)
        l_p = nil
        foreach(g_val l_vals
            l_p = tconc(l_p _jsonDumpValue(g_val 0 0 sortKeys))
        )
        t_s = buildString(car(l_p) "\n")
        if(t_s == ""
            ""
            strcat(t_s "\n")
        )
    )
)

unuseNamespace("ycCodec")

; END
