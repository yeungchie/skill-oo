ycNamespace:::Require("ycCodec")

useNamespace("ycCsv")

; ---------- 记录扫描 ----------

procedure(_ParseQuoted(t_s n_i n_delim "txn")  ; -> list
    ; 解析从引号开始的字段，返回字段值与下一位置（未消费分隔符/行尾）。
    ;
    ; **参数**
    ;   t_s      (str) - 输入文本
    ;   n_i      (int) - 开引号位置
    ;   n_delim  (int) - 分隔符字节码
    ;
    ; **返回**
    ;   (list) - (字段字符串 下一位置)；未闭合或闭合后有多余字符时报错
    let((len open run p closed c)
        len = length(t_s)
        open = n_i
        n_i++
        run = n_i
        while(n_i <= len && !closed
            c = _Code(t_s n_i)
            if(c == 34
            then
                when(run < n_i
                    p = tconc(p substring(t_s run n_i - run))
                )
                if(_Code(t_s n_i + 1) == 34
                then
                    p = tconc(p "\"")
                    n_i = n_i + 2
                    run = n_i
                else
                    n_i++
                    closed = t
                )
            else
                n_i++
            )
        )
        unless(closed
            _Error(t_s open "unterminated quoted field")
        )
        c = _Code(t_s n_i)
        unless(!c || c == n_delim || c == 10 || c == 13
            _Error(t_s n_i "unexpected character after closing quote")
        )
        list(_Build(p) n_i)
    )
)

procedure(_ParseField(t_s n_i n_delim "txn")  ; -> list
    ; 解析一个字段（引号或裸文本），返回字段值与下一位置。
    ;
    ; **参数**
    ;   t_s      (str) - 输入文本
    ;   n_i      (int) - 字段起点
    ;   n_delim  (int) - 分隔符字节码
    ;
    ; **返回**
    ;   (list) - (字段字符串 下一位置)；裸字段内出现引号时报错
    let((len start c stop)
        len = length(t_s)
        if(n_i <= len && _Code(t_s n_i) == 34
        then
            _ParseQuoted(t_s n_i n_delim)
        else
            start = n_i
            while(n_i <= len && !stop
                c = _Code(t_s n_i)
                cond(
                    (c == n_delim || c == 10 || c == 13
                        stop = t
                    )
                    (c == 34
                        _Error(t_s n_i "unexpected quote in unquoted field")
                    )
                    (t
                        n_i++
                    )
                )
            )
            list(if(start < n_i substring(t_s start n_i - start) "") n_i)
        )
    )
)

procedure(_ParseRecord(t_s n_i n_delim "txn")  ; -> list
    ; 解析一条记录（字段列表），返回记录与下一位置（行尾之后）。
    ;
    ; **参数**
    ;   t_s      (str) - 输入文本
    ;   n_i      (int) - 记录起点
    ;   n_delim  (int) - 分隔符字节码
    ;
    ; **返回**
    ;   (list) - (字段列表 下一位置)
    let((fields field c done)
        while(!done
            field = _ParseField(t_s n_i n_delim)
            fields = tconc(fields car(field))
            n_i = cadr(field)
            c = _Code(t_s n_i)
            cond(
                (!c
                    done = t
                )
                (c == n_delim
                    n_i++
                )
                (t
                    if(c == 13 && _Code(t_s n_i + 1) == 10
                        n_i = n_i + 2
                        n_i++
                    )
                    done = t
                )
            )
        )
        list(car(fields) n_i)
    )
)

procedure(_ScanRows(t_s n_delim g_skipEmpty "tng")  ; -> list
    ; 扫描全部记录，可选跳过单空字段记录；同时保留每条记录起点。
    ;
    ; **参数**
    ;   t_s         (str) - 输入文本
    ;   n_delim     (int) - 分隔符字节码
    ;   g_skipEmpty (t|nil) - 是否跳过单空字段记录
    ;
    ; **返回**
    ;   (list) - (行列表 起点列表)，两者按记录顺序对应
    let((len i start rows starts rec row)
        len = length(t_s)
        i = 1
        while(i <= len
            start = i
            rec = _ParseRecord(t_s i n_delim)
            row = car(rec)
            i = cadr(rec)
            unless(g_skipEmpty && length(row) == 1 && car(row) == ""
                rows = tconc(rows row)
                starts = tconc(starts start)
            )
        )
        list(car(rows) car(starts))
    )
)

procedure(_CheckWidths(l_rows l_starts n_width t_s "llnt")  ; -> t
    ; 校验有表头时每条记录宽度不超过列名数。
    ;
    ; **参数**
    ;   l_rows    (list[list[str]]) - 数据行
    ;   l_starts  (list[int]) - 各行在原文中的起点
    ;   n_width   (int) - 表头列数
    ;   t_s       (str) - 原始文本（用于行列定位）
    ;
    ; **返回**
    ;   (t) - 全部合法时返回 t；超宽行以 error() 中断
    for(i 1 length(l_rows)
        when(n_width < length(nth(i - 1 l_rows))
            _Error(t_s nth(i - 1 l_starts)
                lsprintf("row %d has %d fields but header has %d"
                    i length(nth(i - 1 l_rows)) n_width)
            )
        )
    )
    t
)

; ---------- 解码入口 ----------

procedure(Decode(t_str \@key (format "csv") (header nil) (delimiter nil) (skipEmpty nil) (stripBom t) "ttgggg")  ; -> Table
    ; 解码 CSV/TSV 文本为 Table。
    ;
    ; **参数**
    ;   t_str      (str) - 输入文本
    ;   ?format    (str) - "csv"（默认）或 "tsv"，决定默认分隔符
    ;   ?header    (t|list[str]|nil) - t 取首条记录作列名；list 使用给定列名；默认 nil
    ;   ?delimiter (str) - 单字节分隔符覆盖；默认按 format 取逗号/制表符
    ;   ?skipEmpty (t|nil) - t 时跳过单空字段记录；默认 nil
    ;   ?stripBom  (t|nil) - t 时剥离开头 UTF-8 BOM；默认 t
    ;
    ; **返回**
    ;   (Table) - 解码结果；格式/选项/引号/表头宽度非法时报错
    unless(stringp(t_str)
        error("ycCsv::Decode: expects a string")
    )
    let((delim header2 len body scan rows starts names)
        delim = _DelimCode(delimiter _FormatDelim(format "ycCsv::Decode") "ycCsv::Decode")
        header2 = cond(
            (header == nil nil)
            (header == t t)
            (t
                unless(listp(header)
                    error("ycCsv::Decode: ?header expects t, nil, or a list of strings")
                )
                _CheckHeader(header "ycCsv::Decode")
            )
        )
        len = length(t_str)
        body = t_str
        when(stripBom && 3 <= len
                && _Code(t_str 1) == 239
                && _Code(t_str 2) == 187
                && _Code(t_str 3) == 191
            body = if(3 < len substring(t_str 4) "")
        )
        scan = _ScanRows(body delim skipEmpty)
        rows = car(scan)
        starts = cadr(scan)
        cond(
            (header2 == t
                if(rows
                then
                    names = _CheckHeader(car(rows) "ycCsv::Decode")
                    _CheckWidths(cdr(rows) cdr(starts) length(names) body)
                    Table(cdr(rows) ?header names)
                else
                    Table(nil)
                )
            )
            (header2
                _CheckWidths(rows starts length(header2) body)
                Table(rows ?header header2)
            )
            (t
                Table(rows)
            )
        )
    )
)

unuseNamespace("ycCsv")

; END
