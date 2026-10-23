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
    let((n_len)
        n_len = length(l_lines)
        while(n_pos <= n_len && _Blankp(_Nth1(n_pos l_lines))
            n_pos = n_pos + 1
        )
        n_pos
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
    prog((n_len n_i n_c n_next g_sq g_dq g_esc g_flow)
        n_len = length(t_s)
        n_i = 1
        g_sq = nil
        g_dq = nil
        g_esc = nil
        g_flow = 0
        while(n_i <= n_len
            n_c = _Code(t_s n_i)
            cond(
                (g_dq
                    when(g_esc g_esc = nil)
                    when(!g_esc && n_c == 92 g_esc = t)
                    when(!g_esc && n_c == 34 g_dq = nil)
                )
                (g_sq
                    when(n_c == 39 g_sq = nil)
                )
                (n_c == 34 g_dq = t)
                (n_c == 39 g_sq = t)
                (n_c == 91 || n_c == 123 g_flow = g_flow + 1)
                (n_c == 93 || n_c == 125 when(g_flow > 0 g_flow = g_flow - 1))
                (n_c == 58 && g_flow == 0
                    n_next = _Code(t_s n_i + 1)
                    when(n_next == nil || n_next == 32 || n_next == 9
                        return(n_i)
                    )
                )
            )
            n_i = n_i + 1
        )
        return(nil)
    )
)
procedure(_MergeInto(t_map g_src "gg")  ; -> t
    ; 将源映射中当前表缺少的键并入（显式键优先）。
    ;
    ; **参数**
    ;   t_map  (table) - 目标映射
    ;   g_src  (table|list) - 源映射或映射列表
    ;
    ; **返回**
    ;   (t) - 合并完成
    foreach(g_item if(listp(g_src) g_src list(g_src))
        unless(tablep(g_item)
            error("ycYaml::Decode: merge value must be a mapping or a sequence of mappings")
        )
        foreach(g_key g_item
            when(t_map[g_key] == ycCodec:::Missing
                t_map[g_key] = g_item[g_key]
            )
        )
    )
    t
)
procedure(_ParseChild(l_lines n_pos n_parentIndent n_max "lxnn")  ; -> list
    ; 解析父节点之后的子块；无更深内容时返回 null。
    ;
    ; **参数**
    ;   l_lines        (list[str]) - 行列表
    ;   n_pos          (int) - 下一行号
    ;   n_parentIndent (int) - 父缩进
    ;   n_max          (int) - 最大嵌套深度
    ;
    ; **返回**
    ;   (list) - (值 下一行号)
    prog((n_ind t_line)
        n_pos = _SkipIgnorable(l_lines n_pos)
        when(n_pos > length(l_lines)
            return(list(ycCodec:::Null n_pos))
        )
        t_line = _Nth1(n_pos l_lines)
        n_ind = _LineIndent(t_line n_pos)
        return(
            if(n_ind <= n_parentIndent
                list(ycCodec:::Null n_pos)
                _ParseBlock(l_lines n_pos n_ind n_max - 1)
            )
        )
    )
)
procedure(_ParseValueText(t_text l_lines n_pos n_parentIndent n_max n_line n_col "tlxnnnn")  ; -> list
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
    ;
    ; **返回**
    ;   (list) - (值 下一行号)
    prog((t_tag t_anchor t_token n_end l_v g_val n_i n_len n_c g_stop)
        t_text = _Rtrim(t_text)
        n_len = length(t_text)
        n_i = 1
        while(n_i <= n_len && _Code(t_text n_i) == 32
            n_i = n_i + 1
        )
        t_text = _Tail(t_text n_i)
        g_stop = nil
        while(!g_stop && t_text != ""
            n_c = _Code(t_text 1)
            cond(
                (n_c == 38
                    n_end = 2
                    while(n_end <= length(t_text) && _Code(t_text n_end) != 32
                        n_end = n_end + 1
                    )
                    t_anchor = substring(t_text 2 n_end - 2)
                    when(t_anchor == "" _ErrorLine("empty anchor name" n_line n_col))
                    t_text = _Rtrim(_StripComment(_Tail(t_text n_end)))
                )
                (n_c == 33
                    n_end = 2
                    while(n_end <= length(t_text) && _Code(t_text n_end) != 32
                        n_end = n_end + 1
                    )
                    t_tag = substring(t_text 1 n_end - 1)
                    t_text = _Rtrim(_StripComment(_Tail(t_text n_end)))
                )
                (t
                    g_stop = t
                )
            )
        )
        t_text = _Ltrim(t_text)
        when(_Code(t_text 1) == 42
            n_end = 2
            while(n_end <= length(t_text) && _Code(t_text n_end) != 32
                n_end = n_end + 1
            )
            unless(_Rtrim(_Tail(t_text n_end)) == ""
                _ErrorLine("unexpected characters after alias" n_line n_col)
            )
            g_val = _AliasValue(substring(t_text 2 n_end - 2))
            when(t_tag g_val = _TagValue(g_val t_tag))
            return(list(g_val n_pos))
        )
        when(t_anchor
            when(_ActiveAnchors[t_anchor]
                _ErrorLine("recursive anchor" n_line n_col)
            )
            _ActiveAnchors[t_anchor] = t
        )
        cond(
            (t_text == ""
                l_v = _ParseChild(l_lines n_pos n_parentIndent n_max)
            )
            ((_Code(t_text 1) == 124 || _Code(t_text 1) == 62)
                l_v = _ParseBlockScalar(l_lines n_pos n_parentIndent t_text n_line n_col)
            )
            (t
                if(_Code(t_text 1) == 91 || _Code(t_text 1) == 123
                    progn(
                        l_v = errset(_FlowValue(t_text 1 n_max))
                        unless(l_v
                            _ErrorLine("unterminated or invalid flow value" n_line n_col)
                        )
                        l_v = car(l_v)
                        unless(_Rtrim(_Tail(t_text cadr(l_v))) == ""
                            _ErrorLine("unexpected characters after value" n_line n_col)
                        )
                        l_v = list(car(l_v) n_pos)
                    )
                    l_v = list(_ParseScalarText(t_text) n_pos)
                )
            )
        )
        g_val = car(l_v)
        when(t_tag g_val = _TagValue(g_val t_tag))
        when(t_anchor
            _Anchors[t_anchor] = g_val
            _ActiveAnchors[t_anchor] = nil
        )
        return(list(g_val cadr(l_v)))
    )
)
procedure(_ParseMapInto(t_map l_lines n_pos n_indent n_max t_first n_line n_col "glxnngnn")  ; -> list
    ; 解析映射条目并写入目标 table；t_first 用于序列内联映射的首条。
    ;
    ; **参数**
    ;   t_map    (table) - 目标映射
    ;   l_lines  (list[str]) - 行列表
    ;   n_pos    (int) - 下一行号
    ;   n_indent (int) - 映射缩进
    ;   n_max    (int) - 最大嵌套深度
    ;   t_first  (str|nil) - 内联首条文本
    ;   n_line   (int) - 首条行号
    ;   n_col    (int) - 首条列号
    ;
    ; **返回**
    ;   (list) - (table 下一行号)
    let((n_len t_line t_content n_ind n_colon t_key t_rest l_v g_key g_first g_stop)
        n_len = length(l_lines)
        g_first = t_first
        g_stop = nil
        while(!g_stop && (g_first || n_pos <= n_len)
            t_content = nil
            cond(
                (g_first
                    t_content = g_first
                    g_first = nil
                )
                (t
                    n_pos = _SkipIgnorable(l_lines n_pos)
                    when(n_pos > n_len
                        n_pos = n_len + 1
                    )
                    when(n_pos <= n_len
                        t_line = _Nth1(n_pos l_lines)
                        n_ind = _LineIndent(t_line n_pos)
                        when(n_ind < n_indent
                            g_stop = t
                        )
                        when(n_ind > n_indent
                            _ErrorLine("unexpected indentation" n_pos 1)
                        )
                        when(n_ind == n_indent
                            t_content = _StripComment(substring(t_line n_ind + 1 length(t_line) - n_ind))
                            n_col = n_ind + 1
                            n_pos = n_pos + 1
                        )
                    )
                )
            )
            when(t_content
                when(_Code(t_content 1) == 45 && (_Code(t_content 2) == nil || _Code(t_content 2) == 32)
                    _ErrorLine("mixed mapping and sequence" n_pos - 1 n_col)
                )
                n_colon = _FindKeyColon(t_content)
                unless(n_colon
                    _ErrorLine("expected a mapping key" n_pos - 1 n_col)
                )
                t_key = _ParseKeyText(substring(t_content 1 n_colon - 1))
                t_rest = _Tail(t_content n_colon + 1)
                l_v = _ParseValueText(t_rest l_lines n_pos n_indent n_max n_pos - 1 n_col + n_colon)
                n_pos = cadr(l_v)
                cond(
                    (t_key == "<<" && (tablep(car(l_v)) || listp(car(l_v)))
                        _MergeInto(t_map car(l_v))
                    )
                    (t
                        t_map[t_key] = car(l_v)
                    )
                )
            )
        )
        list(t_map n_pos)
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
    let((t_map)
        t_map = makeTable("ycYaml" ycCodec:::Missing)
        _ParseMapInto(t_map l_lines n_pos n_indent n_max nil 1 1)
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
    let((l_res l_v n_len t_line n_ind t_content g_stop)
        when(n_max < 0
            error("ycYaml::Decode: nesting too deep")
        )
        n_len = length(l_lines)
        g_stop = nil
        l_v = _ParseValueText(t_first l_lines n_pos n_indent n_max n_line n_col)
        l_res = tconc(l_res car(l_v))
        n_pos = cadr(l_v)
        while(!g_stop && n_pos <= n_len
            n_pos = _SkipIgnorable(l_lines n_pos)
            when(n_pos > n_len
                g_stop = t
            )
            unless(g_stop
                t_line = _Nth1(n_pos l_lines)
                n_ind = _LineIndent(t_line n_pos)
                cond(
                    (n_ind < n_indent
                        g_stop = t
                    )
                    (n_ind > n_indent
                        _ErrorLine("unexpected indentation" n_pos 1)
                    )
                    (t
                        t_content = _StripComment(substring(t_line n_ind + 1 length(t_line) - n_ind))
                        if(_Code(t_content 1) == 45
                            progn(
                                l_v = _ParseValueText(_Tail(t_content 3) l_lines n_pos + 1 n_indent n_max n_pos n_ind + 3)
                                l_res = tconc(l_res car(l_v))
                                n_pos = cadr(l_v)
                            )
                            g_stop = t
                        )
                    )
                )
            )
        )
        list(car(l_res) n_pos)
    )
)
procedure(_ParseSeq(l_lines n_pos n_indent n_max "lxnn")  ; -> list
    ; 解析块序列。
    ;
    ; **参数**
    ;   l_lines  (list[str]) - 行列表
    ;   n_pos    (int) - 起始行号
    ;   n_indent (int) - 序列缩进
    ;   n_max    (int) - 最大嵌套深度
    ;
    ; **返回**
    ;   (list) - (列表 下一行号)
    let((n_len l_res t_line n_ind t_content t_rest l_v t_map g_stop)
        n_len = length(l_lines)
        g_stop = nil
        while(!g_stop && n_pos <= n_len
            n_pos = _SkipIgnorable(l_lines n_pos)
            when(n_pos <= n_len
                t_line = _Nth1(n_pos l_lines)
                n_ind = _LineIndent(t_line n_pos)
                cond(
                    (n_ind < n_indent
                        g_stop = t
                    )
                    (n_ind > n_indent
                        _ErrorLine("unexpected indentation" n_pos 1)
                    )
                    (t
                        t_content = _StripComment(substring(t_line n_ind + 1 length(t_line) - n_ind))
                        unless(_Code(t_content 1) == 45
                            _ErrorLine("expected a sequence item" n_pos n_ind + 1)
                        )
                        t_rest = _Rtrim(_Tail(t_content 3))
                        cond(
                            (t_rest == ""
                                l_v = _ParseChild(l_lines n_pos + 1 n_indent n_max)
                                l_res = tconc(l_res car(l_v))
                                n_pos = cadr(l_v)
                            )
                            ((_Code(t_rest 1) == 45 && (_Code(t_rest 2) == nil || _Code(t_rest 2) == 32))
                                l_v = _ParseSeqNested(l_lines n_pos + 1 n_indent + 2 n_max - 1 _Tail(t_rest 3) n_pos n_ind + 3)
                                l_res = tconc(l_res car(l_v))
                                n_pos = cadr(l_v)
                            )
                            (_FindKeyColon(t_rest)
                                t_map = makeTable("ycYaml" ycCodec:::Missing)
                                l_v = _ParseMapInto(t_map l_lines n_pos + 1 n_indent + 2 n_max t_rest n_pos n_ind + 3)
                                l_res = tconc(l_res car(l_v))
                                n_pos = cadr(l_v)
                            )
                            (t
                                l_v = _ParseValueText(t_rest l_lines n_pos + 1 n_indent n_max n_pos n_ind + 3)
                                l_res = tconc(l_res car(l_v))
                                n_pos = cadr(l_v)
                            )
                        )
                    )
                )
            )
        )
        list(car(l_res) n_pos)
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
    prog((n_len t_line n_ind t_content)
        when(n_max < 0
            error("ycYaml::Decode: nesting too deep")
        )
        n_len = length(l_lines)
        n_pos = _SkipIgnorable(l_lines n_pos)
        when(n_pos > n_len
            return(list(ycCodec:::Null n_pos))
        )
        t_line = _Nth1(n_pos l_lines)
        n_ind = _LineIndent(t_line n_pos)
        when(n_ind < n_indent
            return(list(ycCodec:::Null n_pos))
        )
        n_indent = n_ind
        t_content = _StripComment(substring(t_line n_ind + 1 length(t_line) - n_ind))
        when(_Code(t_content 1) == 45 && (_Code(t_content 2) == nil || _Code(t_content 2) == 32)
            return(_ParseSeq(l_lines n_pos n_indent n_max))
        )
        when(_FindKeyColon(t_content)
            return(_ParseMap(l_lines n_pos n_indent n_max))
        )
        return(_ParseValueText(t_content l_lines n_pos + 1 n_indent n_max n_pos n_ind + 1))
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
    let((l_lines l_docs l_cur g_active t_line t_rest n_i)
        l_lines = _SplitLines(t_s)
        l_docs = nil
        g_active = nil
        foreach(t_line l_lines
            t_rest = _Rtrim(_StripComment(t_line))
            cond(
                (pcreMatchp("^---([ \t].*)?\\z" t_rest)
                    when(g_active || l_cur
                        l_docs = tconc(l_docs car(l_cur))
                    )
                    l_cur = nil
                    g_active = t
                    when(length(t_rest) > 3
                        t_rest = _Rtrim(substring(t_rest 4 length(t_rest) - 3))
                        when(t_rest != "" l_cur = tconc(nil t_rest))
                    )
                )
                (pcreMatchp("^\\.\\.\\.[ \t]*(#.*)?\\z" t_rest)
                    when(g_active || l_cur
                        l_docs = tconc(l_docs car(l_cur))
                    )
                    l_cur = nil
                    g_active = nil
                )
                (pcreMatchp("^%[A-Za-z]" t_rest)
                    nil
                )
                (t
                    when(t_rest != "" || g_active || l_cur
                        g_active = t
                        l_cur = tconc(l_cur t_line)
                    )
                )
            )
        )
        when(g_active || l_cur
            l_docs = tconc(l_docs car(l_cur))
        )
        car(l_docs)
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
    let((l_r n_pos)
        _Anchors = makeTable("yamlAnchors" nil)
        _ActiveAnchors = makeTable("yamlActiveAnchors" nil)
        l_r = _ParseBlock(l_lines 1 0 n_max)
        n_pos = _SkipIgnorable(l_lines cadr(l_r))
        when(n_pos <= length(l_lines)
            _ErrorLine("unexpected trailing content" n_pos 1)
        )
        car(l_r)
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
    let((l_res)
        foreach(l_doc l_docs
            l_res = tconc(l_res _DecodeText(l_doc n_max))
        )
        car(l_res)
    )
)
procedure(Decode(t_str \@key (format "yaml") (maxDepth nil) "ttg")  ; -> any | list
    ; 解码 YAML 文本：?format "yaml" 解析单个文档，"yaml-stream" 解析多文档流。
    ;
    ; **参数**
    ;   t_str     (str) - 输入文本
    ;   ?format   (str) - "yaml" 或 "yaml-stream"
    ;   ?maxDepth (int) - 最大嵌套深度；默认 800
    ;
    ; **返回**
    ;   (any|list) - 单文档值或文档列表；错误以 error() 中断
    let((l_docs)
        unless(stringp(t_str)
            error("ycYaml::Decode: expects a string")
        )
        when(maxDepth == nil
            maxDepth = _MaxDecodeDepth
        )
        unless(fixp(maxDepth) && maxDepth >= 1
            error("ycYaml::Decode: ?maxDepth must be a positive fixnum")
        )
        l_docs = _SplitDocuments(t_str)
        case(format
            ("yaml"
                cond(
                    (l_docs == nil ycCodec:::Null)
                    (cadr(l_docs) _ErrorLine("multiple documents; use yaml-stream" 1 1))
                    (t _DecodeText(car(l_docs) maxDepth))
                )
            )
            ("yaml-stream" _DecodeStream(l_docs maxDepth))
            (t error("ycYaml::Decode: unknown format %A" format))
        )
    )
)

unuseNamespace("ycYaml")

; END
