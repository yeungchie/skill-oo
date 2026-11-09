ycNamespace:::Require("ycCodec")

useNamespace("ycYaml")
; ---------- 块结构 ----------
procedure(_SkipIgnorable(l_lines n_pos "lx")  ; -> int
    ; 跳过空白行与注释行。
    ;
    ; **参数**
    ;   l_lines  (list[str]) - 行列表
    ;   n_pos    (int) - 起始行号（1-based）
    ;
    ; **返回**
    ;   (int) - 下一非空白行号
    let((len)
        len = length(l_lines)
        while(n_pos <= len && _Blankp(_Nth1(n_pos l_lines))
            n_pos++
        )
        n_pos
    )
)
procedure(_InnerMessage(l_err "l")  ; -> str
    ; 取出 errset 结果中的原始错误说明，去掉 `*Error* ` 前缀与已有行列后缀。
    ;
    ; **参数**
    ;   l_err  (list) - errset 的错误信息
    ;
    ; **返回**
    ;   (str) - 规整后的错误说明
    let((msg)
        msg = car(last(l_err))
        when(listp(msg) && msg
            msg = car(msg)
        )
        unless(stringp(msg)
            error("ycYaml::Decode: unterminated or invalid flow value")
        )
        when(pcreMatchp("^\\*Error\\* " msg)
            msg = substring(msg 9 length(msg) - 8)
        )
        msg = pcreReplace(pcreCompile("^ycYaml::Decode: ") msg "" 0)
        pcreReplace(pcreCompile(" at line [0-9]+, column [0-9]+\\z") msg "" 0)
    )
)
procedure(_FindKeyColon(t_s "t")  ; -> int | nil
    ; 查找块映射键后的冒号：引号外且后随空白或行尾。
    ;
    ; **参数**
    ;   t_s  (str) - 行内容
    ;
    ; **返回**
    ;   (int|nil) - 冒号位置；不是映射行为 nil
    prog((len i c next sq dq esc flow)
        len = length(t_s)
        i = 1
        sq = nil
        dq = nil
        esc = nil
        flow = 0
        while(i <= len
            c = _Code(t_s i)
            cond(
                (dq
                    when(esc esc = nil)
                    when(!esc && c == 92 esc = t)
                    when(!esc && c == 34 dq = nil)
                )
                (sq
                    when(c == 39 sq = nil)
                )
                (c == 34 && _QuoteStart(t_s i flow > 0) dq = t)
                (c == 39 && _QuoteStart(t_s i flow > 0) sq = t)
                (c == 91 || c == 123 flow = flow + 1)
                (c == 93 || c == 125 when(flow > 0 flow = flow - 1))
                (c == 58 && flow == 0
                    next = _Code(t_s i + 1)
                    when(next == nil || next == 32 || next == 9
                        return(i)
                    )
                )
            )
            i++
        )
        return(nil)
    )
)
procedure(_MergeInto(g_map g_src "gg")  ; -> t
    ; 将源映射中当前表缺少的键并入（显式键优先）。
    ;
    ; **参数**
    ;   g_map  (table) - 目标映射
    ;   g_src  (table|list) - 源映射或映射列表
    ;
    ; **返回**
    ;   (t) - 合并完成
    foreach(item if(listp(g_src) g_src list(g_src))
        unless(tablep(item)
            error("ycYaml::Decode: merge value must be a mapping or a sequence of mappings")
        )
        foreach(key item
            when(g_map[key] == ycCodec:::Missing
                g_map[key] = item[key]
            )
        )
    )
    t
)
procedure(_ParseChild(l_lines n_pos n_parentIndent n_max \@key (indentless nil) "lxnng")  ; -> list
    ; 解析父节点之后的子块；无更深内容时返回 null。
    ;
    ; **参数**
    ;   l_lines        (list[str]) - 行列表
    ;   n_pos          (int) - 下一行号
    ;   n_parentIndent (int) - 父缩进
    ;   n_max          (int) - 最大嵌套深度
    ;   ?indentless    (t|nil) - t 时允许与父同缩进的序列（映射值紧接 `- `）
    ;
    ; **返回**
    ;   (list) - (值 下一行号)
    prog((ind line)
        n_pos = _SkipIgnorable(l_lines n_pos)
        when(n_pos > length(l_lines)
            return(list(ycCodec:::Null n_pos))
        )
        line = _Nth1(n_pos l_lines)
        ind = _LineIndent(line n_pos)
        return(
            cond(
                ((indentless && ind == n_parentIndent)
                    let((content)
                        content = _StripComment(substring(line ind + 1 length(line) - ind))
                        if(_Code(content 1) == 45 && (_Code(content 2) == nil || _Code(content 2) == 32)
                            _ParseSeq(l_lines n_pos ind n_max ?indentless t)
                            list(ycCodec:::Null n_pos)
                        )
                    )
                )
                ((ind <= n_parentIndent) list(ycCodec:::Null n_pos))
                (t _ParseBlock(l_lines n_pos ind n_max - 1))
            )
        )
    )
)
procedure(_ParseValueText(t_text l_lines n_pos n_parentIndent n_max n_line n_col \@key (indentless nil) "tlxnnnng")  ; -> list
    ; 解析一个值文本；空文本时解析下一层子块，支持标签、锚点、别名与块标量。
    ;
    ; **参数**
    ;   t_text         (str) - 当前行值文本
    ;   l_lines        (list[str]) - 行列表
    ;   n_pos          (int) - 下一行号
    ;   n_parentIndent (int) - 父缩进
    ;   n_max          (int) - 最大嵌套深度
    ;   n_line         (int) - 当前行号
    ;   n_col          (int) - 当前列号
    ;   ?indentless    (t|nil) - t 时允许与父同缩进的序列
    ;
    ; **返回**
    ;   (list) - (值 下一行号)
    prog((tag anchor token end v val i len c stop)
        t_text = _Rtrim(t_text)
        len = length(t_text)
        i = 1
        while(i <= len && _Code(t_text i) == 32
            i++
        )
        t_text = _Tail(t_text i)
        stop = nil
        while(!stop && t_text != ""
            c = _Code(t_text 1)
            cond(
                (c == 38
                    end = 2
                    while(end <= length(t_text) && _Code(t_text end) != 32
                        end++
                    )
                    anchor = substring(t_text 2 end - 2)
                    when(anchor == "" _ErrorLine("empty anchor name" n_line n_col))
                    t_text = _Rtrim(_StripComment(_Tail(t_text end)))
                )
                (c == 33
                    end = 2
                    while(end <= length(t_text) && _Code(t_text end) != 32
                        end++
                    )
                    tag = substring(t_text 1 end - 1)
                    t_text = _Rtrim(_StripComment(_Tail(t_text end)))
                )
                (t
                    stop = t
                )
            )
        )
        t_text = _Ltrim(t_text)
        when(_Code(t_text 1) == 42
            end = 2
            while(end <= length(t_text) && _Code(t_text end) != 32
                end++
            )
            unless(_Rtrim(_Tail(t_text end)) == ""
                _ErrorLine("unexpected characters after alias" n_line n_col)
            )
            val = _AliasValue(substring(t_text 2 end - 2))
            when(tag val = _TagValue(val tag))
            return(list(val n_pos))
        )
        when(anchor
            when(_ActiveAnchors[anchor]
                _ErrorLine("recursive anchor" n_line n_col)
            )
            _ActiveAnchors[anchor] = t
        )
        cond(
            (t_text == ""
                v = _ParseChild(l_lines n_pos n_parentIndent n_max ?indentless indentless)
            )
            ((_Code(t_text 1) == 124 || _Code(t_text 1) == 62)
                v = _ParseBlockScalar(l_lines n_pos n_parentIndent t_text n_line n_col)
            )
            (t
                if(_Code(t_text 1) == 91 || _Code(t_text 1) == 123
                then
                    v = errset(_FlowValue(t_text 1 n_max))
                    unless(v
                        _ErrorLine(_InnerMessage(errset.errset) n_line n_col)
                    )
                    v = car(v)
                    unless(_Rtrim(_Tail(t_text cadr(v))) == ""
                        _ErrorLine("unexpected characters after value" n_line n_col)
                    )
                    v = list(car(v) n_pos)
                else
                    v = list(_ParseScalarText(t_text n_line) n_pos)
                )
            )
        )
        val = car(v)
        when(tag val = _TagValue(val tag))
        when(anchor
            _Anchors[anchor] = val
            _ActiveAnchors[anchor] = nil
        )
        return(list(val cadr(v)))
    )
)
procedure(_ParseMapInto(g_map l_lines n_pos n_indent n_max g_inline n_line n_col "glxnngnn")  ; -> list
    ; 解析映射条目并写入目标 table；g_inline 用于序列内联映射的首条。
    ;
    ; **参数**
    ;   g_map    (table) - 目标映射
    ;   l_lines  (list[str]) - 行列表
    ;   n_pos    (int) - 下一行号
    ;   n_indent (int) - 映射缩进
    ;   n_max    (int) - 最大嵌套深度
    ;   g_inline (str|nil) - 内联首条文本
    ;   n_line   (int) - 首条行号
    ;   n_col    (int) - 首条列号
    ;
    ; **返回**
    ;   (list) - (table 下一行号)
    let((len line content ind colon key rest v key2 first stop)
        len = length(l_lines)
        first = g_inline
        stop = nil
        while(!stop && (first || n_pos <= len)
            content = nil
            cond(
                (first
                    content = first
                    first = nil
                )
                (t
                    n_pos = _SkipIgnorable(l_lines n_pos)
                    when(n_pos > len
                        n_pos = len + 1
                    )
                    when(n_pos <= len
                        line = _Nth1(n_pos l_lines)
                        ind = _LineIndent(line n_pos)
                        when(ind < n_indent
                            stop = t
                        )
                        when(ind > n_indent
                            _ErrorLine("unexpected indentation" n_pos ind + 1)
                        )
                        when(ind == n_indent
                            content = _StripComment(substring(line ind + 1 length(line) - ind))
                            n_col = ind + 1
                            n_line = n_pos
                            n_pos++
                        )
                    )
                )
            )
            when(content
                when(_Code(content 1) == 45 && (_Code(content 2) == nil || _Code(content 2) == 32)
                    _ErrorLine("mixed mapping and sequence" n_line n_col)
                )
                colon = _FindKeyColon(content)
                unless(colon
                    _ErrorLine("expected a mapping key" n_line n_col)
                )
                key = _ParseKeyText(substring(content 1 colon - 1) n_line)
                rest = _Tail(content colon + 1)
                v = _ParseValueText(rest l_lines n_pos n_indent n_max n_line n_col + colon ?indentless t)
                n_pos = cadr(v)
                cond(
                    (key == "<<" && (tablep(car(v)) || listp(car(v)))
                        _MergeInto(g_map car(v))
                    )
                    (t
                        g_map[key] = car(v)
                    )
                )
            )
        )
        list(g_map n_pos)
    )
)
procedure(_ParseMap(l_lines n_pos n_indent n_max "lxnn")  ; -> list
    ; 解析块映射。
    ;
    ; **参数**
    ;   l_lines  (list[str]) - 行列表
    ;   n_pos    (int) - 起始行号
    ;   n_indent (int) - 映射缩进
    ;   n_max    (int) - 最大嵌套深度
    ;
    ; **返回**
    ;   (list) - (table 下一行号)
    let((map)
        map = makeTable("ycYaml" ycCodec:::Missing)
        _ParseMapInto(map l_lines n_pos n_indent n_max nil 1 1)
    )
)
procedure(_ParseSeqNested(l_lines n_pos n_indent n_max t_first n_line n_col "lxnntnn")  ; -> list
    ; 解析 `- - ...` 形式的内联嵌套序列。
    ;
    ; **参数**
    ;   l_lines  (list[str]) - 行列表
    ;   n_pos    (int) - 下一行号
    ;   n_indent (int) - 嵌套序列缩进
    ;   n_max    (int) - 最大嵌套深度
    ;   t_first  (str) - 首个元素文本（`- ` 之后）
    ;   n_line   (int) - 行号
    ;   n_col    (int) - 列号
    ;
    ; **返回**
    ;   (list) - (列表 下一行号)
    let((res v len line ind content stop)
        when(n_max < 0
            error("ycYaml::Decode: nesting too deep")
        )
        len = length(l_lines)
        stop = nil
        v = _ParseValueText(t_first l_lines n_pos n_indent n_max n_line n_col)
        res = tconc(res car(v))
        n_pos = cadr(v)
        while(!stop && n_pos <= len
            n_pos = _SkipIgnorable(l_lines n_pos)
            when(n_pos > len
                stop = t
            )
            unless(stop
                line = _Nth1(n_pos l_lines)
                ind = _LineIndent(line n_pos)
                cond(
                    (ind < n_indent
                        stop = t
                    )
                    (ind > n_indent
                        _ErrorLine("unexpected indentation" n_pos ind + 1)
                    )
                    (t
                        content = _StripComment(substring(line ind + 1 length(line) - ind))
                        if(_Code(content 1) == 45 && (_Code(content 2) == nil || _Code(content 2) == 32)
                        then
                            v = _ParseValueText(_Tail(content 3) l_lines n_pos + 1 n_indent n_max n_pos ind + 3)
                            res = tconc(res car(v))
                            n_pos = cadr(v)
                        else
                            stop = t
                        )
                    )
                )
            )
        )
        list(car(res) n_pos)
    )
)
procedure(_ParseSeq(l_lines n_pos n_indent n_max \@key (indentless nil) "lxnng")  ; -> list
    ; 解析块序列。
    ;
    ; **参数**
    ;   l_lines     (list[str]) - 行列表
    ;   n_pos       (int) - 起始行号
    ;   n_indent    (int) - 序列缩进
    ;   n_max       (int) - 最大嵌套深度
    ;   ?indentless (t|nil) - t 时遇到同缩进的非序列行即结束（映射值紧接 `- `）
    ;
    ; **返回**
    ;   (list) - (列表 下一行号)
    let((len res line ind content rest lead v map stop)
        len = length(l_lines)
        stop = nil
        while(!stop && n_pos <= len
            n_pos = _SkipIgnorable(l_lines n_pos)
            when(n_pos <= len
                line = _Nth1(n_pos l_lines)
                ind = _LineIndent(line n_pos)
                cond(
                    (ind < n_indent
                        stop = t
                    )
                    (ind > n_indent
                        _ErrorLine("unexpected indentation" n_pos ind + 1)
                    )
                    (t
                        content = _StripComment(substring(line ind + 1 length(line) - ind))
                        if(_Code(content 1) == 45 && (_Code(content 2) == nil || _Code(content 2) == 32)
                        then
                            rest = _Tail(content 3)
                            lead = length(rest) - length(_Ltrim(rest))
                            rest = _Rtrim(_Ltrim(rest))
                            cond(
                                (rest == ""
                                    v = _ParseChild(l_lines n_pos + 1 n_indent n_max)
                                    res = tconc(res car(v))
                                    n_pos = cadr(v)
                                )
                                ((_Code(rest 1) == 45 && (_Code(rest 2) == nil || _Code(rest 2) == 32))
                                    v = _ParseSeqNested(l_lines n_pos + 1 n_indent + 2 + lead n_max - 1 _Tail(rest 3) n_pos ind + 5 + lead)
                                    res = tconc(res car(v))
                                    n_pos = cadr(v)
                                )
                                (_FindKeyColon(rest)
                                    map = makeTable("ycYaml" ycCodec:::Missing)
                                    v = _ParseMapInto(map l_lines n_pos + 1 n_indent + 2 + lead n_max rest n_pos ind + 3 + lead)
                                    res = tconc(res car(v))
                                    n_pos = cadr(v)
                                )
                                (t
                                    v = _ParseValueText(rest l_lines n_pos + 1 n_indent n_max n_pos ind + 3 + lead)
                                    res = tconc(res car(v))
                                    n_pos = cadr(v)
                                )
                            )
                        else
                            unless(indentless
                                _ErrorLine("expected a sequence item" n_pos ind + 1)
                            )
                            stop = t
                        )
                    )
                )
            )
        )
        list(car(res) n_pos)
    )
)
procedure(_ParseBlock(l_lines n_pos n_indent n_max "lxnn")  ; -> list
    ; 按缩进解析块节点：序列、映射或标量。
    ;
    ; **参数**
    ;   l_lines  (list[str]) - 行列表
    ;   n_pos    (int) - 起始行号
    ;   n_indent (int) - 期望缩进
    ;   n_max    (int) - 最大嵌套深度
    ;
    ; **返回**
    ;   (list) - (值 下一行号)
    prog((len line ind content)
        when(n_max < 0
            error("ycYaml::Decode: nesting too deep")
        )
        len = length(l_lines)
        n_pos = _SkipIgnorable(l_lines n_pos)
        when(n_pos > len
            return(list(ycCodec:::Null n_pos))
        )
        line = _Nth1(n_pos l_lines)
        ind = _LineIndent(line n_pos)
        when(ind < n_indent
            return(list(ycCodec:::Null n_pos))
        )
        n_indent = ind
        content = _StripComment(substring(line ind + 1 length(line) - ind))
        when(_Code(content 1) == 45 && (_Code(content 2) == nil || _Code(content 2) == 32)
            return(_ParseSeq(l_lines n_pos n_indent n_max))
        )
        when(_FindKeyColon(content)
            return(_ParseMap(l_lines n_pos n_indent n_max))
        )
        return(_ParseValueText(content l_lines n_pos + 1 n_indent n_max n_pos ind + 1))
    )
)
procedure(_SplitDocuments(t_s "t")  ; -> list
    ; 按 `---`/`...` 标记拆分 YAML 文档。
    ;
    ; **参数**
    ;   t_s  (str) - 输入文本
    ;
    ; **返回**
    ;   (list) - 每项的 line 列表
    let((lines docs cur active line rest i n_line)
        lines = _SplitLines(t_s)
        docs = nil
        active = nil
        n_line = 0
        foreach(line2 lines
            n_line++
            rest = _Rtrim(_StripComment(line2))
            cond(
                (pcreMatchp("^---([ \t].*)?\\z" rest)
                    when(active || cur
                        docs = tconc(docs car(cur))
                    )
                    cur = nil
                    active = t
                    when(length(rest) > 3
                        rest = _Rtrim(substring(rest 4 length(rest) - 3))
                        when(rest != "" cur = tconc(nil rest))
                    )
                )
                (pcreMatchp("^\\.\\.\\.[ \t]*(#.*)?\\z" rest)
                    when(active || cur
                        docs = tconc(docs car(cur))
                    )
                    cur = nil
                    active = nil
                )
                (pcreMatchp("^%[A-Za-z]" rest)
                    unless(pcreMatchp("^%(YAML|TAG)([ \t]|\\z)" rest)
                        _ErrorLine("unknown directive" n_line 1)
                    )
                )
                (t
                    when(rest != "" || active || cur
                        active = t
                        cur = tconc(cur line2)
                    )
                )
            )
        )
        when(active || cur
            docs = tconc(docs car(cur))
        )
        car(docs)
    )
)
procedure(_DecodeText(l_lines n_max "lx")  ; -> any
    ; 解析单个文档并检查尾随内容。
    ;
    ; **参数**
    ;   l_lines  (list[str]) - 文档行
    ;   n_max    (int) - 最大嵌套深度
    ;
    ; **返回**
    ;   (any) - 文档值
    let((r pos)
        _Anchors = makeTable("yamlAnchors" nil)
        _ActiveAnchors = makeTable("yamlActiveAnchors" nil)
        r = _ParseBlock(l_lines 1 0 n_max)
        pos = _SkipIgnorable(l_lines cadr(r))
        when(pos <= length(l_lines)
            _ErrorLine("unexpected trailing content" pos 1)
        )
        car(r)
    )
)
procedure(_DecodeStream(l_docs n_max "ln")  ; -> list
    ; 解析多文档流。
    ;
    ; **参数**
    ;   l_docs  (list) - 文档 line 列表的列表
    ;   n_max   (int) - 最大嵌套深度
    ;
    ; **返回**
    ;   (list) - 各文档值
    let((res)
        foreach(doc l_docs
            res = tconc(res _DecodeText(doc n_max))
        )
        car(res)
    )
)
procedure(Decode(t_str \@key (format "yaml") (maxDepth nil) "ttg")  ; -> any | list
    ; 解码 YAML 文本：?format "yaml" 解析单个文档，"yaml-stream" 解析多文档流。
    ;
    ; **参数**
    ;   t_str     (str) - 输入文本
    ;   ?format   (str) - "yaml" 或 "yaml-stream"；默认 "yaml"
    ;   ?maxDepth (int) - 最大嵌套深度；默认 800
    ;
    ; **返回**
    ;   (any|list) - 单文档值或文档列表；错误以 error() 中断
    let((docs)
        unless(stringp(t_str)
            error("ycYaml::Decode: expects a string")
        )
        when(maxDepth == nil
            maxDepth = _MaxDecodeDepth
        )
        unless(fixp(maxDepth) && maxDepth >= 1
            error("ycYaml::Decode: ?maxDepth must be a positive fixnum")
        )
        docs = _SplitDocuments(t_str)
        case(format
            ("yaml"
                cond(
                    (docs == nil ycCodec:::Null)
                    ((length(docs) > 1)
                        _ErrorLine("multiple documents; use yaml-stream" 1 1)
                    )
                    (t _DecodeText(car(docs) maxDepth))
                )
            )
            ("yaml-stream" _DecodeStream(docs maxDepth))
            (t error("ycYaml::Decode: unknown format %A" format))
        )
    )
)

unuseNamespace("ycYaml")

; END
