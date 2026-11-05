;--------------------------
; Program  : ycTextwrap(src/wrap.il)
; Language : Cadence Skill
;--------------------------

ycNamespace:::Require("ycUtf8")

useNamespace("ycTextwrap")

; ---------- 折行 ----------

procedure(_PackCps(l_words n_first n_rest g_breakLong g_hyphen t_unit n_amb "lxxggtx")  ; -> list
    ; 按逐行可用宽度贪心装词（内部实现）。
    ;
    ; **参数**
    ;   l_words     (list[list[int]]) - 词码点
    ;   n_first     (int) - 首行可用宽度
    ;   n_rest      (int) - 其余行可用宽度
    ;   g_breakLong (t|nil) - 非 nil 时长词硬切
    ;   g_hyphen    (t|nil) - 非 nil 时优先在连字符后断
    ;   t_unit      (str) - 单位
    ;   n_amb       (int) - Ambiguous 宽度
    ;
    ; **返回**
    ;   (list[list[int]]) - 行码点列表
    let((lines cur curw limit)
        limit = n_first
        foreach(word l_words
            let((ww place)
                ww = _WidthCps(word t_unit n_amb)
                if(cur
                    if(curw + 1 + ww <= limit
                    then
                        cur = append(cur list(32))
                        cur = append(cur word)
                        curw = curw + 1 + ww
                    else
                        lines = tconc(lines cur)
                        cur = nil
                        curw = 0
                        limit = n_rest
                        place = t
                    )
                    place = t
                )
                when(place
                    if(ww <= limit
                    then
                        cur = word
                        curw = ww
                    else
                        if(g_breakLong
                        then
                            let((rest chunk)
                                rest = word
                                while(rest && _WidthCps(rest t_unit n_amb) > limit
                                    chunk = _FirstChunk(rest limit g_hyphen t_unit n_amb)
                                    lines = tconc(lines chunk)
                                    rest = _DropCps(rest length(chunk))
                                    limit = n_rest
                                )
                                when(rest
                                    cur = rest
                                    curw = _WidthCps(rest t_unit n_amb)
                                )
                            )
                        else
                            cur = word
                            curw = ww
                        )
                    )
                )
            )
        )
        when(cur lines = tconc(lines cur))
        car(lines)
    )
)

procedure(_WrapCps(l_cps n_first n_rest g_breakLong g_hyphen t_unit n_amb "lxxggtx")  ; -> list | nil
    ; 折行单个逻辑行（内部实现）。
    ;
    ; **参数**
    ;   l_cps       (list[int]) - 逻辑行码点
    ;   n_first     (int) - 首行可用宽度
    ;   n_rest      (int) - 其余行可用宽度
    ;   g_breakLong (t|nil) - 非 nil 时长词硬切
    ;   g_hyphen    (t|nil) - 非 nil 时优先在连字符后断
    ;   t_unit      (str) - 单位
    ;   n_amb       (int) - Ambiguous 宽度
    ;
    ; **返回**
    ;   (list[list[int]]|nil) - 行码点列表；全空白为 nil
    let((words)
        words = _WordsFromCps(l_cps)
        when(words
            _PackCps(words n_first n_rest g_breakLong g_hyphen t_unit n_amb)
        )
    )
)

; ---------- 截断 ----------

procedure(_TrimTrailingSpaces(l_cps "l")  ; -> list[int]
    ; 去掉尾部空格码点（内部实现）。
    ;
    ; **参数**
    ;   l_cps  (list[int]) - 码点列表
    ;
    ; **返回**
    ;   (list[int]) - 去尾空格后的列表
    let((rev)
        rev = reverse(l_cps)
        while(rev && car(rev) == 32
            rev = cdr(rev)
        )
        reverse(rev)
    )
)

procedure(_CutAtSpace(l_cps n_max t_unit n_amb "lxtx")  ; -> list[int]
    ; 在宽度上限内按最后一个空格断词（内部实现）。
    ;
    ; **参数**
    ;   l_cps  (list[int]) - 码点列表
    ;   n_max  (int) - 内容宽度上限
    ;   t_unit (str) - 单位
    ;   n_amb  (int) - Ambiguous 宽度
    ;
    ; **返回**
    ;   (list[int]) - 断词后的前缀
    let((pre i last)
        pre = _TakeCps(l_cps _FitCount(l_cps n_max t_unit n_amb))
        pre = _TrimTrailingSpaces(pre)
        i = 1
        foreach(cp pre
            when(cp == 32 last = i)
            i++
        )
        when(last
            pre = _TrimTrailingSpaces(_TakeCps(pre last - 1))
        )
        pre
    )
)

procedure(_FitPlaceholder(l_cps t_ph n_max t_unit n_amb "ltxtx")  ; -> list[int]
    ; 为被截断的末行保留占位符宽度并去除余下内容（内部实现）。
    ;
    ; **参数**
    ;   l_cps  (list[int]) - 行码点
    ;   t_ph   (str) - 占位符
    ;   n_max  (int) - 行宽上限
    ;   t_unit (str) - 单位
    ;   n_amb  (int) - Ambiguous 宽度
    ;
    ; **返回**
    ;   (list[int]) - 截断后的码点
    let((ph ph2 room pre)
        ph = ycUtf8:::Decode(t_ph)
        ph2 = _WidthCps(ph t_unit n_amb)
        if(ph2 >= n_max
        then
            _TakeCps(ph _FitCount(ph n_max t_unit n_amb))
        else
            room = n_max - ph2
            pre = _CutAtSpace(l_cps room t_unit n_amb)
            append(pre ph)
        )
    )
)

procedure(_ShortenCps(l_cps n_max t_ph t_unit n_amb "lxttx")  ; -> list[int]
    ; 内容超宽时断词并追加占位符（内部实现）。
    ;
    ; **参数**
    ;   l_cps  (list[int]) - 内容码点
    ;   n_max  (int) - 宽度上限
    ;   t_ph   (str) - 占位符
    ;   t_unit (str) - 单位
    ;   n_amb  (int) - Ambiguous 宽度
    ;
    ; **返回**
    ;   (list[int]) - 截断后的码点
    if(_WidthCps(l_cps t_unit n_amb) <= n_max
        l_cps
        _FitPlaceholder(l_cps t_ph n_max t_unit n_amb)
    )
)

; ---------- 公开入口 ----------

procedure(Wrap(t_text \@key (width 70) (initialIndent "") (subsequentIndent "") (breakLongWords t) (breakOnHyphens t) (maxLines nil) (placeholder "...") (unit "display") (ambiguous 1) "txttgggttx")  ; -> list[str] | nil
    ; 按宽度折行文本，返回行列表。
    ;
    ; **参数**
    ;   t_text            (str) - 输入文本
    ;   ?width            (int) - 目标行宽（含缩进）；默认 70
    ;   ?initialIndent    (str) - 首行缩进；默认 ""
    ;   ?subsequentIndent (str) - 其余内容行缩进；默认 ""
    ;   ?breakLongWords   (t|nil) - 非 nil 时硬切超宽词；默认 t
    ;   ?breakOnHyphens   (t|nil) - 非 nil 时优先在连字符后断；默认 t
    ;   ?maxLines         (int|nil) - 最大输出行数；nil 不限
    ;   ?placeholder      (str) - 截断占位符；默认 "..."
    ;   ?unit             (str) - "display"（默认）或 "char"
    ;   ?ambiguous        (int) - East Asian Ambiguous 宽度（1 或 2）；默认 1
    ;
    ; **返回**
    ;   (list[str]|nil) - 行列表；空文本或全空白单行为 nil
    unless(stringp(t_text)
        error("ycTextwrap::Wrap: text must be a string (%A)" t_text)
    )
    unless(fixp(width) && width >= 1
        error("ycTextwrap::Wrap: width must be a positive integer (%A)" width)
    )
    unless(stringp(initialIndent)
        error("ycTextwrap::Wrap: initialIndent must be a string (%A)" initialIndent)
    )
    unless(stringp(subsequentIndent)
        error("ycTextwrap::Wrap: subsequentIndent must be a string (%A)" subsequentIndent)
    )
    unless(maxLines == nil || (fixp(maxLines) && maxLines >= 1)
        error("ycTextwrap::Wrap: maxLines must be nil or a positive integer (%A)" maxLines)
    )
    unless(stringp(placeholder)
        error("ycTextwrap::Wrap: placeholder must be a string (%A)" placeholder)
    )
    _CheckUnit("ycTextwrap::Wrap" unit ambiguous)
    let((availInit availSub)
        availInit = width - _WidthText(initialIndent unit ambiguous)
        availSub = width - _WidthText(subsequentIndent unit ambiguous)
        unless(availInit >= 1
            error("ycTextwrap::Wrap: initialIndent leaves no room within width %d" width)
        )
        unless(availSub >= 1
            error("ycTextwrap::Wrap: subsequentIndent leaves no room within width %d" width)
        )
        unless(t_text == ""
            let((lines out meta first any)
                lines = _LogicalLines(_NormalizeNewlines(t_text))
                first = t
                foreach(line lines
                    let((words packs indent avail)
                        words = _WordsFromCps(ycUtf8:::Decode(line))
                        if(words
                        then
                            avail = if(first availInit availSub)
                            packs = _PackCps(
                                words
                                avail
                                availSub
                                breakLongWords
                                breakOnHyphens
                                unit
                                ambiguous
                            )
                            foreach(pack packs
                                indent = if(first initialIndent subsequentIndent)
                                out = tconc(out strcat(indent ycUtf8:::Encode(pack)))
                                meta = tconc(meta list(indent avail))
                                first = nil
                                any = t
                            )
                        else
                            out = tconc(out "")
                            meta = tconc(meta nil)
                        )
                    )
                )
                if(maxLines && length(car(out)) > maxLines
                    let((keep kmeta metaList final i last meta2 indent avail cps)
                        metaList = car(meta)
                        i = 0
                        foreach(line car(out)
                            when(i < maxLines
                                keep = tconc(keep line)
                                kmeta = tconc(kmeta nth(i metaList))
                            )
                            i++
                        )
                        final = car(keep)
                        last = car(reverse(final))
                        meta2 = car(reverse(car(kmeta)))
                        indent = car(meta2)
                        avail = cadr(meta2)
                        when(last != ""
                            cps = ycUtf8:::Decode(substring(
                                last
                                length(indent) + 1
                                length(last) - length(indent)
                            ))
                            when(cps
                                last = strcat(
                                    indent
                                    ycUtf8:::Encode(_FitPlaceholder(
                                        cps
                                        placeholder
                                        avail
                                        unit
                                        ambiguous
                                    ))
                                )
                                final = reverse(cons(last cdr(reverse(final))))
                            )
                        )
                        final
                    )
                    unless(!any && index(t_text "\n") == nil
                        car(out)
                    )
                )
            )
        )
    )
)

procedure(Fill(t_text \@key (width 70) (initialIndent "") (subsequentIndent "") (breakLongWords t) (breakOnHyphens t) (maxLines nil) (placeholder "...") (unit "display") (ambiguous 1) (sep "\n") "txttgggttxt")  ; -> str
    ; 折行文本并以分隔符拼回。
    ;
    ; **参数**
    ;   t_text            (str) - 输入文本
    ;   ?width            (int) - 目标行宽；默认 70
    ;   ?initialIndent    (str) - 首行缩进；默认 ""
    ;   ?subsequentIndent (str) - 其余内容行缩进；默认 ""
    ;   ?breakLongWords   (t|nil) - 非 nil 时硬切超宽词；默认 t
    ;   ?breakOnHyphens   (t|nil) - 非 nil 时优先在连字符后断；默认 t
    ;   ?maxLines         (int|nil) - 最大输出行数；nil 不限
    ;   ?placeholder      (str) - 截断占位符；默认 "..."
    ;   ?unit             (str) - "display"（默认）或 "char"
    ;   ?ambiguous        (int) - East Asian Ambiguous 宽度（1 或 2）；默认 1
    ;   ?sep              (str) - 行分隔符；默认换行
    ;
    ; **返回**
    ;   (str) - 拼回后的文本；空输入为 ""
    unless(stringp(sep)
        error("ycTextwrap::Fill: sep must be a string (%A)" sep)
    )
    let((lines)
        lines = Wrap(
            t_text
            ?width width
            ?initialIndent initialIndent
            ?subsequentIndent subsequentIndent
            ?breakLongWords breakLongWords
            ?breakOnHyphens breakOnHyphens
            ?maxLines maxLines
            ?placeholder placeholder
            ?unit unit
            ?ambiguous ambiguous
        )
        if(lines buildString(lines sep) "")
    )
)

unuseNamespace("ycTextwrap")

; END
