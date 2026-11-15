useNamespace("ycSQLite")


procedure(_HexValue(t_ch t_context "tt")  ; -> int
    ; 把单个十六进制字符转换为 0..15。
    ;
    ; **参数**
    ;   t_ch       (str) - 单个字符
    ;   t_context  (str) - 错误消息上下文
    ;
    ; **返回**
    ;   (int) - 数值；非法字符时 error() 中断
    let((code)
        code = charToInt(getchar(t_ch 1))
        cond(
            (48 <= code && code <= 57 code - 48)
            (65 <= code && code <= 70 code - 55)
            (97 <= code && code <= 102 code - 87)
            (t
                error("%s: invalid hex digit %A" t_context t_ch)
            )
        )
    )
)


procedure(_HexDecode(t_hex t_context "tt")  ; -> str
    ; 把十六进制文本解码为字节串。
    ;
    ; **参数**
    ;   t_hex      (str) - 十六进制文本
    ;   t_context  (str) - 错误消息上下文
    ;
    ; **返回**
    ;   (str) - 字节串；长度非法时 error() 中断
    let((len res hi lo)
        unless(stringp(t_hex)
            error("%s: hex text must be a string, got %A" t_context t_hex)
        )
        len = length(t_hex)
        unless(remainder(len 2) == 0
            error("%s: hex length must be even, got %d" t_context len)
        )
        if(len == 0
        then
            ""
        else
            for(i 1 len / 2
                hi = _HexValue(substring(t_hex i * 2 - 1 1) t_context)
                lo = _HexValue(substring(t_hex i * 2 1) t_context)
                res = tconc(res intToChar(hi * 16 + lo))
            )
            buildString(car(res) "")
        )
    )
)


procedure(_IsBlob(g_value "g")  ; -> t | nil
    ; 判断值是否为 ycSQLite::Blob。
    ;
    ; **参数**
    ;   g_value  (any) - 待判断值
    ;
    ; **返回**
    ;   (t|nil) - 是 Blob 时为 t
    let((res)
        res = errset(className(g_value) == 'ycSQLite::Blob nil)
        res && car(res)
    )
)


procedure(_StrPos(t_text t_sub "tt")  ; -> int | nil
    ; 返回子串在文本中的 1-based 起点。
    ;
    ; **参数**
    ;   t_text  (str) - 输入文本
    ;   t_sub   (str) - 非空子串
    ;
    ; **返回**
    ;   (int|nil) - 起点；未找到为 nil
    let((len subLen i found)
        unless(stringp(t_text) && stringp(t_sub)
            error("ycSQLite::Database: text and substring must be strings")
        )
        subLen = length(t_sub)
        when(subLen == 0
            error("ycSQLite::Database: substring must not be empty")
        )
        len = length(t_text)
        i = 1
        while(i <= len - subLen + 1 && !found
            when(substring(t_text i subLen) == t_sub
                found = i
            )
            i++
        )
        found
    )
)


procedure(_ParseInteger(t_text t_context "tt")  ; -> int | str
    ; 把 SQLite 十进制整数解码为 fixnum 或字符串。
    ;
    ; **参数**
    ;   t_text     (str) - 十进制文本
    ;   t_context  (str) - 错误消息上下文
    ;
    ; **返回**
    ;   (int|str) - 能无损表示为 fixnum 时返回整数，否则返回原十进制字符串
    let((num)
        num = atoi(t_text)
        if(sprintf(nil "%d" num) == t_text
        then
            num
        else
            t_text
        )
    )
)


procedure(_QuoteIdentifier(t_name "t")  ; -> str
    ; 把 SQLite 标识符加双引号。
    ;
    ; **参数**
    ;   t_name  (str) - 标识符
    ;
    ; **返回**
    ;   (str) - 双引号包裹的标识符；双引号按 SQLite 规则双写
    unless(stringp(t_name)
        error("ycSQLite::Database: identifier must be a string, got %A"
            t_name)
    )
    strcat("\"" pcreReplace(pcreCompile("\"") t_name "\"\"" 0) "\"")
)


procedure(_SqlLiteral(g_value "g")  ; -> str
    ; 把 SKILL 值编码为 SQLite 字面量。
    ;
    ; **参数**
    ;   g_value  (any) - nil、整数、浮点、字符串或 Blob
    ;
    ; **返回**
    ;   (str) - SQL 字面量；不支持的类型 error() 中断
    cond(
        (g_value == nil "NULL")
        (fixp(g_value) sprintf(nil "%d" g_value))
        (floatp(g_value) sprintf(nil "%.17g" g_value))
        (stringp(g_value)
            strcat("'" pcreReplace(pcreCompile("'") g_value "''" 0) "'")
        )
        (_IsBlob(g_value)
            strcat("X'" g_value->hex() "'")
        )
        (t
            error("ycSQLite::Database: unsupported parameter type %A"
                g_value)
        )
    )
)


procedure(_BindSql(t_sql l_params "tl")  ; -> str
    ; 将位置参数 ? 替换为安全 SQL 字面量。
    ;
    ; **参数**
    ;   t_sql     (str) - SQL 文本
    ;   l_params  (list) - 参数值；nil 等价于空列表
    ;
    ; **返回**
    ;   (str) - 替换后的 SQL；参数数量/类型或引号状态非法时 error() 中断
    unless(stringp(t_sql)
        error("ycSQLite::Database: SQL must be a string, got %A" t_sql)
    )
    unless(l_params == nil || listp(l_params)
        error("ycSQLite::Database: parameters must be a list or nil, got %A"
            l_params)
    )
    let((len i c nxt state rest out)
        len = length(t_sql)
        state = 'normal
        rest = l_params
        out = ""
        i = 1
        while(i <= len
            c = substring(t_sql i 1)
            nxt = if(i < len substring(t_sql i + 1 1) "")
            cond(
                (state == 'normal
                    cond(
                        (c == "'"
                            out = strcat(out c)
                            state = 'single
                        )
                        (c == "\""
                            out = strcat(out c)
                            state = 'double
                        )
                        (c == "`"
                            out = strcat(out c)
                            state = 'backtick
                        )
                        (c == "["
                            out = strcat(out c)
                            state = 'bracket
                        )
                        (c == "-" && nxt == "-"
                            out = strcat(out "--")
                            state = 'lineComment
                            i++
                        )
                        (c == "/" && nxt == "*"
                            out = strcat(out "/*")
                            state = 'blockComment
                            i++
                        )
                        (c == "?"
                            unless(rest
                                error("ycSQLite::Database: not enough parameters for SQL")
                            )
                            out = strcat(out _SqlLiteral(car(rest)))
                            rest = cdr(rest)
                        )
                        (t
                            out = strcat(out c)
                        )
                    )
                )
                (state == 'single
                    out = strcat(out c)
                    when(c == "'"
                        if(nxt == "'"
                        then
                            out = strcat(out nxt)
                            i++
                        else
                            state = 'normal
                        )
                    )
                )
                (state == 'double
                    out = strcat(out c)
                    when(c == "\""
                        if(nxt == "\""
                        then
                            out = strcat(out nxt)
                            i++
                        else
                            state = 'normal
                        )
                    )
                )
                (state == 'backtick
                    out = strcat(out c)
                    when(c == "`"
                        if(nxt == "`"
                        then
                            out = strcat(out nxt)
                            i++
                        else
                            state = 'normal
                        )
                    )
                )
                (state == 'bracket
                    out = strcat(out c)
                    when(c == "]"
                        state = 'normal
                    )
                )
                (state == 'lineComment
                    out = strcat(out c)
                    when(c == "\n"
                        state = 'normal
                    )
                )
                (state == 'blockComment
                    out = strcat(out c)
                    when(c == "*" && nxt == "/"
                        out = strcat(out nxt)
                        i++
                        state = 'normal
                    )
                )
            )
            i++
        )
        unless(state == 'normal || state == 'lineComment
            error("ycSQLite::Database: unterminated SQL quote or comment")
        )
        when(rest
            error("ycSQLite::Database: too many parameters for SQL")
        )
        out
    )
)


procedure(_SplitBy(t_text t_sep "tt")  ; -> list[str]
    ; 按固定分隔符拆分文本，保留空字段。
    ;
    ; **参数**
    ;   t_text  (str) - 输入文本
    ;   t_sep   (str) - 非空分隔符
    ;
    ; **返回**
    ;   (list[str]) - 字段列表；空输入返回 ("")
    let((len sepLen i start res)
        unless(stringp(t_text) && stringp(t_sep)
            error("ycSQLite::Database: text and separator must be strings")
        )
        sepLen = length(t_sep)
        when(sepLen == 0
            error("ycSQLite::Database: separator must not be empty")
        )
        len = length(t_text)
        if(len == 0
        then
            list("")
        else
            i = 1
            while(i <= len
                start = i
                while(i <= len && substring(t_text i sepLen) != t_sep
                    i++
                )
                res = tconc(res substring(t_text start i - start))
                when(i <= len
                    i = i + sepLen
                )
            )
            car(res)
        )
    )
)


procedure(_SqlScan(t_sql t_context "tt")  ; -> list[str|nil int t|nil]
    ; 扫描 SQL 文本，返回首条语句的关键字、非空语句数与点命令标志。
    ;
    ; **参数**
    ;   t_sql      (str) - SQL 文本
    ;   t_context  (str) - 错误消息上下文
    ;
    ; **返回**
    ;   (list[str|nil int t|nil]) - 首条非空语句的首关键字（小写）、
    ;   语句数与「是否存在语句边界的行首点命令」标志；
    ;   引号或注释未闭合时 error() 中断
    unless(stringp(t_sql)
        error("%s: SQL must be a string, got %A" t_context t_sql)
    )
    let((len i c nxt state word keyword count content bol dot)
        len = length(t_sql)
        i = 1
        state = 'normal
        count = 0
        bol = t
        while(i <= len
            c = substring(t_sql i 1)
            nxt = if(i < len substring(t_sql i + 1 1) "")
            cond(
                (state == 'normal
                    cond(
                        (bol && !content && c == "."
                            dot = t
                            content = t
                        )
                        (c == "'" state = 'single)
                        (c == "\"" state = 'double)
                        (c == "`" state = 'backtick)
                        (c == "[" state = 'bracket)
                        (c == "-" && nxt == "-"
                            state = 'lineComment
                            i++
                        )
                        (c == "/" && nxt == "*"
                            state = 'blockComment
                            i++
                        )
                        (t
                            when(word && !pcreMatchp("[A-Za-z0-9_]" c)
                                when(!keyword && count == 0
                                    keyword = lowerCase(word)
                                )
                                word = nil
                            )
                            cond(
                                (c == ";"
                                    when(content count++)
                                    content = nil
                                )
                                ((c == " " || c == "\t" || c == "\n"
                                    || c == "\r") nil)
                                (t
                                    content = t
                                    when(pcreMatchp("[A-Za-z0-9_]" c)
                                        word = strcat(if(word word "") c)
                                    )
                                )
                            )
                        )
                    )
                )
                (state == 'single
                    content = t
                    when(c == "'"
                        if(nxt == "'"
                        then i++
                        else state = 'normal
                        )
                    )
                )
                (state == 'double
                    content = t
                    when(c == "\""
                        if(nxt == "\""
                        then i++
                        else state = 'normal
                        )
                    )
                )
                (state == 'backtick
                    content = t
                    when(c == "`"
                        if(nxt == "`"
                        then i++
                        else state = 'normal
                        )
                    )
                )
                (state == 'bracket
                    content = t
                    when(c == "]"
                        state = 'normal
                    )
                )
                (state == 'lineComment
                    when(c == "\n"
                        state = 'normal
                    )
                )
                (state == 'blockComment
                    when(c == "*" && nxt == "/"
                        i++
                        state = 'normal
                    )
                )
            )
            if(c == "\n"
            then
                bol = t
            else
                bol = nil
            )
            i++
        )
        unless(state == 'normal || state == 'lineComment
            error("%s: unterminated SQL quote or comment" t_context)
        )
        when(word
            when(!keyword && count == 0
                keyword = lowerCase(word)
            )
        )
        when(content count++)
        list(keyword count dot)
    )
)


procedure(_CheckNoDotCommands(t_sql t_context "tt")  ; -> t
    ; 拒绝 SQL 文本中出现在语句边界行首的客户端点命令。
    ;
    ; **参数**
    ;   t_sql      (str) - SQL 文本
    ;   t_context  (str) - 错误消息上下文
    ;
    ; **返回**
    ;   (t) - 无点命令；否则 error() 中断
    when(caddr(_SqlScan(t_sql t_context))
        error("%s: dot commands are not allowed in SQL" t_context)
    )
    t
)


procedure(_CheckQuery(t_sql "t")  ; -> t
    ; 校验 query 的 SQL 为单条只读 SELECT/WITH/VALUES。
    ;
    ; **参数**
    ;   t_sql  (str) - SQL 文本
    ;
    ; **返回**
    ;   (t) - 合法；否则 error() 中断
    let((scan keyword count)
        unless(stringp(t_sql)
            error("ycSQLite::Database->query: SQL must be a string, got %A"
                t_sql)
        )
        scan = _SqlScan(t_sql "ycSQLite::Database->query")
        keyword = car(scan)
        count = cadr(scan)
        unless(count <= 1
            error("ycSQLite::Database->query: SQL must contain a single statement")
        )
        unless(keyword && pcreMatchp("^(select|with|values)$" keyword)
            error("ycSQLite::Database->query: SQL must start with SELECT, WITH, or VALUES")
        )
        t
    )
)


procedure(_EncodedColumn(t_name "t")  ; -> str
    ; 生成单列的 type:hex 编码表达式。
    ;
    ; **参数**
    ;   t_name  (str) - 列名
    ;
    ; **返回**
    ;   (str) - SQL 表达式
    let((id)
        id = _QuoteIdentifier(t_name)
        lsprintf("typeof(%s) || ':' || hex(cast(case typeof(%s) when 'real' then quote(%s) else %s end as blob))"
            id id id id)
    )
)


procedure(_EncodedSelect(l_columns "l")  ; -> str
    ; 生成从临时表读取并按 type:hex 编码的 SELECT。
    ;
    ; **参数**
    ;   l_columns  (list[str]) - 列名
    ;
    ; **返回**
    ;   (str) - SQL 语句
    let((exprs)
        unless(l_columns && listp(l_columns)
            error("ycSQLite::Database->query: columns must be a non-nil list")
        )
        foreach(name l_columns
            exprs = tconc(exprs _EncodedColumn(name))
        )
        strcat("select " buildString(car(exprs) " || '|' || ")
            " from __yc_sqlite_q;")
    )
)


procedure(_SplitLines(t_text "t")  ; -> list[str]
    ; 按 LF 拆行并丢弃空行。
    ;
    ; **参数**
    ;   t_text  (str) - 输入文本
    ;
    ; **返回**
    ;   (list[str]) - 非空行列表
    let((res normalized)
        normalized = pcreReplace(pcreCompile("\r\n") t_text "\n" 0)
        foreach(line _SplitBy(normalized "\n")
            when(line != ""
                res = tconc(res line)
            )
        )
        car(res)
    )
)


procedure(_ParseHeader(t_text t_context "tt")  ; -> list[str]
    ; 解析查询表头。
    ;
    ; **参数**
    ;   t_text     (str) - SQLite CSV 表头文本
    ;   t_context  (str) - 错误消息上下文
    ;
    ; **返回**
    ;   (list[str]) - 列名；空表头或类型非法时 error() 中断
    let((rows header)
        rows = ycCsv:::Decode(t_text ?header nil)->rows()
        unless(rows
            error("%s: SQLite returned an empty result header" t_context)
        )
        header = car(rows)
        for(i 1 length(header)
            unless(stringp(nth(i - 1 header))
                error("%s: invalid column name at position %d" t_context i)
            )
        )
        header
    )
)


procedure(_ParseTableInfo(t_text t_context "tt")  ; -> list[str]
    ; 从 PRAGMA table_info 的 CSV 输出提取列名。
    ;
    ; **参数**
    ;   t_text     (str) - CSV 行
    ;   t_context  (str) - 错误消息上下文
    ;
    ; **返回**
    ;   (list[str]) - 列名；空输出或格式非法时 error() 中断
    let((rows names)
        rows = ycCsv:::Decode(t_text ?header nil)->rows()
        unless(rows
            error("%s: SQLite returned no column metadata" t_context)
        )
        foreach(row rows
            unless(2 <= length(row) && stringp(nth(1 row))
                error("%s: malformed table_info row %A" t_context row)
            )
            names = tconc(names nth(1 row))
        )
        car(names)
    )
)


procedure(_DecodeValue(t_type t_hex t_context "ttt")  ; -> any
    ; 按 SQLite 类型标签解码一个十六进制值。
    ;
    ; **参数**
    ;   t_type     (str) - typeof() 结果
    ;   t_hex      (str) - 值字节的十六进制文本
    ;   t_context  (str) - 错误消息上下文
    ;
    ; **返回**
    ;   (any) - nil、整数、字符串、flonum 或 Blob
    case(t_type
        ("null" nil)
        ("integer" _ParseInteger(_HexDecode(t_hex t_context) t_context))
        ("real" atof(_HexDecode(t_hex t_context)))
        ("text" _HexDecode(t_hex t_context))
        ("blob" Blob(t_hex))
        (t
            error("%s: unknown SQLite type %A" t_context t_type)
        )
    )
)


procedure(_ParseRows(t_text l_columns t_context "tlt")  ; -> list[Row]
    ; 解析编码后的查询行。
    ;
    ; **参数**
    ;   t_text     (str) - type:hex 行文本
    ;   l_columns  (list[str]) - 列名
    ;   t_context  (str) - 错误消息上下文
    ;
    ; **返回**
    ;   (list[Row]) - 行对象列表
    let((res)
        foreach(line _SplitLines(t_text)
            let((fields values pos field)
                fields = _SplitBy(line "|")
                unless(length(fields) == length(l_columns)
                    error("%s: row has %d fields but %d columns"
                        t_context length(fields) length(l_columns))
                )
                for(i 1 length(fields)
                    field = nth(i - 1 fields)
                    pos = _StrPos(field ":")
                    unless(pos
                        error("%s: malformed encoded field %A"
                            t_context field)
                    )
                    values = tconc(values _DecodeValue(
                        substring(field 1 pos - 1)
                        if(pos < length(field) substring(field pos + 1) "")
                        t_context
                    ))
                )
                res = tconc(res Row(car(values) l_columns))
            )
        )
        car(res)
    )
)


procedure(_ParseChanges(t_text t_context "tt")  ; -> list
    ; 解析 changes()、last_insert_rowid() 与 total_changes() 输出。
    ;
    ; **参数**
    ;   t_text     (str) - 一行三列输出
    ;   t_context  (str) - 错误消息上下文
    ;
    ; **返回**
    ;   (list(int int|str int|str)) - changes、lastInsertRowid 与 totalChanges
    let((lines fields changes lastId total)
        lines = _SplitLines(t_text)
        unless(lines
            error("%s: missing changes() output" t_context)
        )
        fields = _SplitBy(car(lines) "|")
        unless(length(fields) == 3
            error("%s: malformed changes() output %A" t_context car(lines))
        )
        changes = _ParseInteger(nth(0 fields) t_context)
        unless(fixp(changes)
            error("%s: changes() is not a fixnum" t_context)
        )
        lastId = _ParseInteger(nth(1 fields) t_context)
        total = _ParseInteger(nth(2 fields) t_context)
        list(changes lastId total)
    )
)

unuseNamespace("ycSQLite")

; END
