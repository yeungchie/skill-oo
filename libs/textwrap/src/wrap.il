;--------------------------
; Program  : ycTextwrap(src/wrap.il)
; Language : Cadence Skill
;--------------------------

ycNamespace:::require("ycUtf8")

useNamespace("ycTextwrap")

; ---------- 折行 ----------

procedure(_packCps(l_words n_first n_rest g_breakLong g_hyphen t_unit n_amb "lxxggtx")  ; -> list
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
    let((l_lines l_cur n_curw n_limit)
        l_lines = cons(nil nil)
        n_limit = n_first
        foreach(l_word l_words
            let((n_ww g_place)
                n_ww = _widthCps(l_word t_unit n_amb)
                if(l_cur
                    if(n_curw + 1 + n_ww <= n_limit
                        progn(
                            l_cur = append(l_cur list(32))
                            l_cur = append(l_cur l_word)
                            n_curw = n_curw + 1 + n_ww
                        )
                        progn(
                            tconc(l_lines l_cur)
                            l_cur = nil
                            n_curw = 0
                            n_limit = n_rest
                            g_place = t
                        )
                    )
                    g_place = t
                )
                when(g_place
                    if(n_ww <= n_limit
                        progn(
                            l_cur = l_word
                            n_curw = n_ww
                        )
                        if(g_breakLong
                            let((l_rest l_chunk)
                                l_rest = l_word
                                while(l_rest && _widthCps(l_rest t_unit n_amb) > n_limit
                                    l_chunk = _firstChunk(l_rest n_limit g_hyphen t_unit n_amb)
                                    tconc(l_lines l_chunk)
                                    l_rest = _dropCps(l_rest length(l_chunk))
                                    n_limit = n_rest
                                )
                                when(l_rest
                                    l_cur = l_rest
                                    n_curw = _widthCps(l_rest t_unit n_amb)
                                )
                            )
                            progn(
                                l_cur = l_word
                                n_curw = n_ww
                            )
                        )
                    )
                )
            )
        )
        when(l_cur tconc(l_lines l_cur))
        car(l_lines)
    )
)

procedure(_wrapCps(l_cps n_first n_rest g_breakLong g_hyphen t_unit n_amb "lxxggtx")  ; -> list | nil
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
    let((l_words)
        l_words = _wordsFromCps(l_cps)
        when(l_words
            _packCps(l_words n_first n_rest g_breakLong g_hyphen t_unit n_amb)
        )
    )
)

; ---------- 截断 ----------

procedure(_trimTrailingSpaces(l_cps "l")  ; -> list[int]
    ; 去掉尾部空格码点（内部实现）。
    ;
    ; **参数**
    ;   l_cps  (list[int]) - 码点列表
    ;
    ; **返回**
    ;   (list[int]) - 去尾空格后的列表
    let((l_rev)
        l_rev = reverse(l_cps)
        while(l_rev && car(l_rev) == 32
            l_rev = cdr(l_rev)
        )
        reverse(l_rev)
    )
)

procedure(_cutAtSpace(l_cps n_max t_unit n_amb "lxtx")  ; -> list[int]
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
    let((l_pre n_i n_last)
        l_pre = _takeCps(l_cps _fitCount(l_cps n_max t_unit n_amb))
        l_pre = _trimTrailingSpaces(l_pre)
        n_i = 1
        foreach(n_cp l_pre
            when(n_cp == 32 n_last = n_i)
            n_i = n_i + 1
        )
        when(n_last
            l_pre = _trimTrailingSpaces(_takeCps(l_pre n_last - 1))
        )
        l_pre
    )
)

procedure(_fitPlaceholder(l_cps t_ph n_max t_unit n_amb "ltxtx")  ; -> list[int]
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
    let((l_ph n_ph n_room l_pre)
        l_ph = ycUtf8:::decode(t_ph)
        n_ph = _widthCps(l_ph t_unit n_amb)
        if(n_ph >= n_max
            _takeCps(l_ph _fitCount(l_ph n_max t_unit n_amb))
            progn(
                n_room = n_max - n_ph
                l_pre = _cutAtSpace(l_cps n_room t_unit n_amb)
                append(l_pre l_ph)
            )
        )
    )
)

procedure(_shortenCps(l_cps n_max t_ph t_unit n_amb "lxttx")  ; -> list[int]
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
    if(_widthCps(l_cps t_unit n_amb) <= n_max
        l_cps
        _fitPlaceholder(l_cps t_ph n_max t_unit n_amb)
    )
)

; ---------- 公开入口 ----------

procedure(wrap(t_text \@key (width 70) (initialIndent "") (subsequentIndent "") (breakLongWords t) (breakOnHyphens t) (maxLines nil) (placeholder "...") (unit "display") (ambiguous 1) "txttgggttx")  ; -> list[str] | nil
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
        error("ycTextwrap::wrap: text must be a string (%A)" t_text)
    )
    unless(fixp(width) && width >= 1
        error("ycTextwrap::wrap: width must be a positive integer (%A)" width)
    )
    unless(stringp(initialIndent)
        error("ycTextwrap::wrap: initialIndent must be a string (%A)" initialIndent)
    )
    unless(stringp(subsequentIndent)
        error("ycTextwrap::wrap: subsequentIndent must be a string (%A)" subsequentIndent)
    )
    unless(maxLines == nil || (fixp(maxLines) && maxLines >= 1)
        error("ycTextwrap::wrap: maxLines must be nil or a positive integer (%A)" maxLines)
    )
    unless(stringp(placeholder)
        error("ycTextwrap::wrap: placeholder must be a string (%A)" placeholder)
    )
    _checkUnit("ycTextwrap::wrap" unit ambiguous)
    let((n_availInit n_availSub)
        n_availInit = width - _widthText(initialIndent unit ambiguous)
        n_availSub = width - _widthText(subsequentIndent unit ambiguous)
        unless(n_availInit >= 1
            error("ycTextwrap::wrap: initialIndent leaves no room within width %d" width)
        )
        unless(n_availSub >= 1
            error("ycTextwrap::wrap: subsequentIndent leaves no room within width %d" width)
        )
        if(t_text == ""
            nil
            let((l_lines l_out l_meta g_first g_any)
                l_out = cons(nil nil)
                l_meta = cons(nil nil)
                l_lines = _logicalLines(_normalizeNewlines(t_text))
                g_first = t
                foreach(t_line l_lines
                    let((l_words l_packs t_indent n_avail)
                        l_words = _wordsFromCps(ycUtf8:::decode(t_line))
                        if(l_words
                            progn(
                                n_avail = if(g_first n_availInit n_availSub)
                                l_packs = _packCps(
                                    l_words
                                    n_avail
                                    n_availSub
                                    breakLongWords
                                    breakOnHyphens
                                    unit
                                    ambiguous
                                )
                                foreach(l_pack l_packs
                                    t_indent = if(g_first initialIndent subsequentIndent)
                                    tconc(l_out strcat(t_indent ycUtf8:::encode(l_pack)))
                                    tconc(l_meta list(t_indent n_avail))
                                    g_first = nil
                                    g_any = t
                                )
                            )
                            progn(
                                tconc(l_out "")
                                tconc(l_meta nil)
                            )
                        )
                    )
                )
                if(maxLines && length(car(l_out)) > maxLines
                    let((l_keep l_kmeta l_metaList l_final n_i t_last g_meta t_indent n_avail l_cps)
                        l_keep = cons(nil nil)
                        l_kmeta = cons(nil nil)
                        l_metaList = car(l_meta)
                        n_i = 0
                        foreach(t_line car(l_out)
                            when(n_i < maxLines
                                tconc(l_keep t_line)
                                tconc(l_kmeta nth(n_i l_metaList))
                            )
                            n_i = n_i + 1
                        )
                        l_final = car(l_keep)
                        t_last = car(reverse(l_final))
                        g_meta = car(reverse(car(l_kmeta)))
                        t_indent = car(g_meta)
                        n_avail = cadr(g_meta)
                        when(t_last != ""
                            l_cps = ycUtf8:::decode(substring(
                                t_last
                                length(t_indent) + 1
                                length(t_last) - length(t_indent)
                            ))
                            when(l_cps
                                t_last = strcat(
                                    t_indent
                                    ycUtf8:::encode(_fitPlaceholder(
                                        l_cps
                                        placeholder
                                        n_avail
                                        unit
                                        ambiguous
                                    ))
                                )
                                l_final = reverse(cons(t_last cdr(reverse(l_final))))
                            )
                        )
                        l_final
                    )
                    if(!g_any && index(t_text "\n") == nil
                        nil
                        car(l_out)
                    )
                )
            )
        )
    )
)

procedure(fill(t_text \@key (width 70) (initialIndent "") (subsequentIndent "") (breakLongWords t) (breakOnHyphens t) (maxLines nil) (placeholder "...") (unit "display") (ambiguous 1) (sep "\n") "txttgggttxt")  ; -> str
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
        error("ycTextwrap::fill: sep must be a string (%A)" sep)
    )
    let((l_lines)
        l_lines = wrap(
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
        if(l_lines buildString(l_lines sep) "")
    )
)

unuseNamespace("ycTextwrap")

; END
