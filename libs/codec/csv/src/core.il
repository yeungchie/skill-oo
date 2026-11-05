useNamespace("ycCsv")

; ---------- 基础工具 ----------

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

procedure(_LineCol(t_s n_i "tx")  ; -> list
    ; 按字节索引计算行列：LF、CR、CRLF 均计为一次换行，列按行内字节偏移。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;   n_i  (int) - 1-based 字节索引
    ;
    ; **返回**
    ;   (list) - (行 列) 两元素表，均 1-based
    let((line last c prevCr)
        line = 1
        last = 0
        when(1 < n_i
            for(k 1 n_i - 1
                c = _Code(t_s k)
                cond(
                    (c == 13
                        line++
                        last = k
                    )
                    (c == 10
                        unless(prevCr
                            line++
                        )
                        last = k
                    )
                )
                prevCr = c == 13
            )
        )
        list(line n_i - last)
    )
)

procedure(_Error(t_s n_i t_msg "txt")  ; -> never
    ; 按统一格式 error() 中断：ycCsv::Decode: <说明> at line <行>, column <列>。
    ;
    ; **参数**
    ;   t_s    (str) - 输入串
    ;   n_i    (int) - 1-based 字节索引（错误位置）
    ;   t_msg  (str) - 错误说明（英文短语）
    ;
    ; **返回**
    ;   (never) - 总是调用 error()，不返回
    let((pos)
        pos = _LineCol(t_s n_i)
        error("ycCsv::Decode: %s at line %d, column %d" t_msg car(pos) cadr(pos))
    )
)

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

procedure(_CopyRows(l_rows "l")  ; -> list
    ; 浅拷贝外层行列表与每行，隔离调用方的后续修改。
    ;
    ; **参数**
    ;   l_rows  (list[list[str]]) - 原始行列表
    ;
    ; **返回**
    ;   (list[list[str]]) - 新外层列表，每行也是新列表
    let((res)
        foreach(row l_rows
            res = tconc(res copy(row))
        )
        car(res)
    )
)

; ---------- 选项与校验 ----------

procedure(_FormatDelim(t_format t_ctx "tt")  ; -> int
    ; 校验格式名并返回默认分隔符字节码。
    ;
    ; **参数**
    ;   t_format  (str) - "csv" 或 "tsv"
    ;   t_ctx     (str) - 错误前缀（ycCsv::Decode / ycCsv::Encode）
    ;
    ; **返回**
    ;   (int) - 逗号（44）或制表符（9）；其他格式名报错
    case(t_format
        ("csv" 44)
        ("tsv" 9)
        (t
            error("%s: unknown format %A" t_ctx t_format)
        )
    )
)

procedure(_DelimCode(g_delim n_default t_ctx "gnt")  ; -> int
    ; 解析 ?delimiter：默认值或单字节字符串，拒绝引号与换行。
    ;
    ; **参数**
    ;   g_delim    (str|nil) - 用户给定分隔符；nil 用默认值
    ;   n_default  (int) - 默认分隔符字节码
    ;   t_ctx      (str) - 错误前缀
    ;
    ; **返回**
    ;   (int) - 分隔符字节码；类型/长度/字符非法时报错
    if(g_delim == nil
    then
        n_default
    else
        unless(stringp(g_delim) && length(g_delim) == 1
            error("%s: delimiter must be a single-byte string" t_ctx)
        )
        let((c)
            c = _Code(g_delim 1)
            when(c == 34 || c == 10 || c == 13
                error("%s: delimiter cannot be a quote or line break" t_ctx)
            )
            c
        )
    )
)

procedure(_EolText(t_eol "t")  ; -> str
    ; 校验编码行尾：只接受 LF 或 CRLF。
    ;
    ; **参数**
    ;   t_eol  (str) - 行尾串
    ;
    ; **返回**
    ;   (str) - 原样返回 "\n" 或 "\r\n"；其他值报错
    unless(t_eol == "\n" || t_eol == "\r\n"
        error("ycCsv::Encode: ?eol must be \"\\n\" or \"\\r\\n\"")
    )
    t_eol
)

procedure(_CheckHeader(l_header t_ctx "lt")  ; -> list[str] | nil
    ; 校验表头列表：nil 或非空字符串列表，列名唯一。
    ;
    ; **参数**
    ;   l_header  (list[str]|nil) - 表头
    ;   t_ctx     (str) - 错误前缀
    ;
    ; **返回**
    ;   (list[str]|nil) - 拷贝后的表头；类型/元素/重复列名报错
    when(l_header
        unless(listp(l_header)
            error("%s: header must be a list of strings or nil" t_ctx)
        )
        let((seen)
            seen = makeTable("ycCsvHeader" nil)
            foreach(name l_header
                unless(stringp(name)
                    error("%s: header names must be strings" t_ctx)
                )
                when(seen[name]
                    error("%s: duplicate header name %A" t_ctx name)
                )
                seen[name] = t
            )
            copy(l_header)
        )
    )
)

procedure(_CheckRows(l_rows t_ctx "lt")  ; -> list
    ; 校验行列表：每行非空且字段全为字符串。
    ;
    ; **参数**
    ;   l_rows  (list[list[str]]) - 行列表
    ;   t_ctx   (str) - 错误前缀
    ;
    ; **返回**
    ;   (list[list[str]]) - 原列表；类型/空行/非字符串字段报错
    unless(listp(l_rows)
        error("%s: rows must be a list" t_ctx)
    )
    for(i 1 length(l_rows)
        let((row)
            row = nth(i - 1 l_rows)
            unless(listp(row)
                error("%s: row %d is not a list" t_ctx i)
            )
            when(length(row) == 0
                error("%s: row %d is empty" t_ctx i)
            )
            for(j 1 length(row)
                let((cell)
                    cell = nth(j - 1 row)
                    unless(stringp(cell)
                        error("%s: row %d, field %d: expected a string, got %A"
                            t_ctx i j cell)
                    )
                )
            )
        )
    )
    l_rows
)

unuseNamespace("ycCsv")

; END
