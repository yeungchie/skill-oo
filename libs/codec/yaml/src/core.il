useNamespace("ycYaml")

; ---------- 基础工具 ----------

_MaxDecodeDepth = 800
_MaxEncodeDepth = 800
_Anchors = makeTable("yamlAnchors" nil)
_ActiveAnchors = makeTable("yamlActiveAnchors" nil)

procedure(_Nth1(n_i l_list "xl")  ; -> any
    ; 以 1-based 索引读取列表元素。
    ;
    ; **参数**
    ;   n_i     (int) - 1-based 索引
    ;   l_list  (list) - 列表
    ;
    ; **返回**
    ;   (any) - 元素；越界为 nil
    nth(n_i - 1 l_list)
)

procedure(_Build(l_p "l")  ; -> str
    ; 将 tconc 头容器（或 nil）拼接为字符串。
    ;
    ; **参数**
    ;   l_p  (list) - tconc 头容器、普通列表或 nil
    ;
    ; **返回**
    ;   (str) - 各片段顺序拼接
    if(l_p && listp(car(l_p))
        buildString(car(l_p) "")
        if(l_p buildString(l_p "") "")
    )
)

procedure(_JoinBuild(l_p t_sep "lt")  ; -> str
    ; 将片段列表按分隔符拼接；兼容 tconc 头容器与普通列表。
    ;
    ; **参数**
    ;   l_p    (list) - 片段列表
    ;   t_sep  (str) - 分隔符
    ;
    ; **返回**
    ;   (str) - 拼接结果；空列表为空串
    if(l_p && listp(car(l_p))
        buildString(car(l_p) t_sep)
        if(l_p buildString(l_p t_sep) "")
    )
)

procedure(_Ltrim(t_s "t")  ; -> str
    ; 去除字符串左侧空白。
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
        _Tail(t_s n_i)
    )
)

procedure(_Code(t_s n_i "tx")  ; -> int | nil
    ; 取字节索引处的字符码（1-based）；索引越界返回 nil。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;   n_i  (int) - 1-based 字节索引
    ;
    ; **返回**
    ;   (int|nil) - 该字符的码值；越界为 nil
    let((g_c)
        g_c = getchar(t_s n_i)
        when(g_c
            charToInt(g_c)
        )
    )
)

procedure(_Utf8Str(n_cp "x")  ; -> str
    ; 将 Unicode 码点编码为 UTF-8 字节串。
    ;
    ; **参数**
    ;   n_cp  (int) - 码点
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

procedure(_Tail(t_s n_i "tx")  ; -> str
    ; 取从位置 n_i 起的剩余文本；越界返回空串。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;   n_i  (int) - 1-based 起始位置
    ;
    ; **返回**
    ;   (str) - 剩余文本或空串
    if(n_i > length(t_s) "" substring(t_s n_i length(t_s) - n_i + 1))
)

procedure(_LineCol(t_s n_i "tx")  ; -> list
    ; 按字节索引计算行列：行/列均 1-based。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;   n_i  (int) - 1-based 字节索引
    ;
    ; **返回**
    ;   (list) - (行 列)
    let((n_line n_last)
        n_line = 1
        n_last = 0
        when(1 < n_i
            for(n_k 1 n_i - 1
                when(_Code(t_s n_k) == 10
                    n_line = n_line + 1
                    n_last = n_k
                )
            )
        )
        list(n_line n_i - n_last)
    )
)

procedure(_ErrorLine(t_msg n_line n_col "txx")  ; -> never
    ; 按统一格式报错：ycYaml::Decode: <说明> at line <行>, column <列>。
    ;
    ; **参数**
    ;   t_msg   (str) - 错误说明（英文短语）
    ;   n_line  (int) - 行号
    ;   n_col   (int) - 列号
    ;
    ; **返回**
    ;   (never) - 总是 error()
    error("ycYaml::Decode: %s at line %d, column %d" t_msg n_line n_col)
)

procedure(_Rtrim(t_s "t")  ; -> str
    ; 删除行尾空格与制表符。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;
    ; **返回**
    ;   (str) - 去尾后的串
    let((n_end n_c)
        n_end = length(t_s)
        n_c = 0
        while(n_end > 0 && (n_c = _Code(t_s n_end)) && (n_c == 32 || n_c == 9)
            n_end = n_end - 1
        )
        if(n_end == 0
            ""
            substring(t_s 1 n_end)
        )
    )
)

procedure(_ChompCr(t_line "t")  ; -> str
    ; 删除行尾单个 CR（CRLF 输入）。
    ;
    ; **参数**
    ;   t_line  (str) - 单行文本
    ;
    ; **返回**
    ;   (str) - 去 CR 后的行
    let((n_len)
        n_len = length(t_line)
        if(n_len > 0 && _Code(t_line n_len) == 13
            substring(t_line 1 n_len - 1)
            t_line
        )
    )
)

procedure(_SplitLines(t_s "t")  ; -> list
    ; 按 LF 拆行并去掉行尾 CR。
    ;
    ; **参数**
    ;   t_s  (str) - 输入文本
    ;
    ; **返回**
    ;   (list[str]) - 行列表；空串为 nil
    let((l_res n_start n_len n_k)
        n_len = length(t_s)
        n_start = 1
        for(n_k 1 n_len
            when(_Code(t_s n_k) == 10
                l_res = tconc(l_res _ChompCr(substring(t_s n_start n_k - n_start)))
                n_start = n_k + 1
            )
        )
        when(n_start <= n_len
            l_res = tconc(l_res _ChompCr(substring(t_s n_start n_len - n_start + 1)))
        )
        car(l_res)
    )
)

procedure(_LineIndent(t_line n_line "tx")  ; -> int
    ; 计算行首空格数；缩进内的制表符报错。
    ;
    ; **参数**
    ;   t_line  (str) - 单行文本
    ;   n_line  (int) - 行号（错误消息）
    ;
    ; **返回**
    ;   (int) - 行首空格数
    let((n_i n_c g_stop)
        n_i = 0
        g_stop = nil
        while(!g_stop && n_i < length(t_line)
            n_c = _Code(t_line n_i + 1)
            cond(
                (n_c == 32 n_i = n_i + 1)
                (n_c == 9 _ErrorLine("tab character in indentation" n_line n_i + 1))
                (t g_stop = t)
            )
        )
        n_i
    )
)

procedure(_StripComment(t_line "t")  ; -> str
    ; 删除引号外的注释：`#` 位于行首或前一字符为空白时生效。
    ;
    ; **参数**
    ;   t_line  (str) - 单行文本
    ;
    ; **返回**
    ;   (str) - 去注释后的文本
    let((n_len n_i n_c n_cut n_prev g_sq g_dq g_esc)
        n_len = length(t_line)
        n_i = 1
        n_cut = nil
        g_sq = nil
        g_dq = nil
        g_esc = nil
        while(n_i <= n_len && !n_cut
            n_c = _Code(t_line n_i)
            n_prev = if(n_i > 1 _Code(t_line n_i - 1) 0)
            cond(
                (g_dq
                    when(g_esc
                        g_esc = nil
                    )
                    when(!g_esc && n_c == 92
                        g_esc = t
                    )
                    when(!g_esc && n_c == 34
                        g_dq = nil
                    )
                    n_i = n_i + 1
                )
                (g_sq
                    when(n_c == 39
                        if(_Code(t_line n_i + 1) == 39
                            n_i = n_i + 1
                            g_sq = nil
                        )
                    )
                    n_i = n_i + 1
                )
                (n_c == 34
                    g_dq = t
                    n_i = n_i + 1
                )
                (n_c == 39
                    g_sq = t
                    n_i = n_i + 1
                )
                (n_c == 35 && (n_i == 1 || n_prev == 32 || n_prev == 9)
                    n_cut = n_i
                )
                (t
                    n_i = n_i + 1
                )
            )
        )
        if(n_cut
            if(n_cut == 1
                ""
                _Rtrim(substring(t_line 1 n_cut - 1))
            )
            t_line
        )
    )
)

procedure(_Blankp(t_line "t")  ; -> t | nil
    ; 判断行是否为空白或注释行。
    ;
    ; **参数**
    ;   t_line  (str) - 单行文本
    ;
    ; **返回**
    ;   (t|nil) - 空白/注释为 t
    _Rtrim(_StripComment(t_line)) == ""
)

unuseNamespace("ycYaml")

; END
