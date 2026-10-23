useNamespace("ycRegEx")


; ---------- Match helpers ----------

procedure(_GroupWhole(self "g")  ; -> str
    ; 取整体匹配串（group() / group(0) 路径）：按 span 位置从主题串切片。
    ;
    ; **返回**
    ;   (str) - 主题串上 [start, end) 字节区间的切片；span 未定位时先经 span() 慢路径回填
    let((l_sp)
        l_sp = self->span()
        _Prefix(_Suffix(self->_data->subject car(l_sp) + 1) car(cdr(l_sp)) - car(l_sp))
    )
)

procedure(_GroupAt(self n_i n_g "gxx")  ; -> str
    ; 按组序号取组值（group 单参与多参路径共用；0 表示整体）。
    ;
    ; **参数**
    ;   n_i  (int) - 组序号：0 = 整体，1..n_g = 对应捕获组
    ;   n_g  (int) - 捕获组总数（Match 组值列表的长度）
    ;
    ; **返回**
    ;   (str) - 0 返回整体串，其余返回对应组值（非参与组为 ""）；n_i < 1 或 > n_g 时 error() 中断
    cond(
        (n_i == 0
            _GroupWhole(self)
        )
        (n_i < 1 || n_i > n_g
            error("ycRegEx::Match->group: no such group: %d" n_i)
        )
        (t
            _Nth1(self->_data->groups n_i)
        )
    )
)


; ---------- extraction templates: "&" whole + delimited groups, one substitute ----------

procedure(_WholeTemplate(n_g "x")  ; -> str
    ; 构造「整体 + 组值」提取模板：& 后按 <YC-B> 定界各组反向引用。
    ;
    ; **参数**
    ;   n_g  (int) - 捕获组数（≥ 0）
    ;
    ; **返回**
    ;   (str) - 形如 "&<YC-B>\{1}<YC-B>\{2}" 的模板，供一次 pcreSubstitute 展开
    let((t_t n_k)
        t_t = "&"
        n_k = 1
        while(n_k <= n_g
            t_t = lsprintf("%s<YC-B>%s" t_t _Backref(n_k))
            n_k = n_k + 1
        )
        t_t
    )
)

procedure(_SplitTemplate(n_g "x")  ; -> str
    ; 构造 split 替换模板：匹配处整体换成 <YC-S> 定界与组值交替的串。
    ;
    ; **参数**
    ;   n_g  (int) - 捕获组数（≥ 0）
    ;
    ; **返回**
    ;   (str) - 形如 "<YC-S>\{1}<YC-S>" 的模板，替换后按 <YC-S> 拆分
    let((t_t n_k)
        t_t = "<YC-S>"
        n_k = 1
        while(n_k <= n_g
            t_t = lsprintf("%s%s<YC-S>" t_t _Backref(n_k))
            n_k = n_k + 1
        )
        t_t
    )
)

procedure(_ExtractParts(g_pat g_obj "gg")  ; -> (str . list[str])
    ; 从 g_obj 刚建立的匹配状态提取整体与各捕获组值（须在 pcreReplace 之前）。
    ;
    ; **参数**
    ;   g_pat  (Pattern)  - 提供捕获组数的 Pattern 实例
    ;   g_obj  (compiled) - 已 pcreMatchp 成功的编译对象
    ;
    ; **返回**
    ;   (str . list[str]) - 点对 (整体串 . 组值列表)；0 个捕获组时组值列表为空
    let((t_buf)
        t_buf = pcreSubstitute(g_obj _WholeTemplate(g_pat->_data->nGroups))
        if(g_pat->_data->nGroups == 0
            list(t_buf)
            _SplitBy(t_buf "<YC-B>")
        )
    )
)

procedure(_AnchorAt(g_pat n_off "gx")  ; -> compiled
    ; 生成在字节偏移 n_off 处精确锚定的编译对象，不截断左侧上下文。
    ;
    ; **参数**
    ;   g_pat  (Pattern) - Pattern 实例
    ;   n_off  (int)     - 0-based 起始字节偏移
    ;
    ; **返回**
    ;   (compiled) - n_off 为 0 时复用 span 对象；否则以 (?<=\A[\s\S]{n_off})(?:…) 编译；
    ;                n_off > 65535 或编译失败时 error() 中断
    when(n_off > 65535
        error("ycRegEx: anchor offset %d exceeds the 65535-byte limit" n_off)
    )
    if(n_off == 0
        g_pat->_data->span
        let((g_obj)
            g_obj = _CompileChecked(
                lsprintf("%s(?<=\\A[\\s\\S]{%d})(?:%s)" g_pat->_data->flags n_off g_pat->_data->pattern)
                lsprintf("ycRegEx: anchor at offset %d" n_off)
                g_pat->_data->compileOpts
            )
            g_obj
        )
    )
)

procedure(_PosMarker(t_subj "t")  ; -> str
    ; 返回一个在主题串中不存在的替换标记。
    ;
    ; **参数**
    ;   t_subj  (str) - 主题串
    ;
    ; **返回**
    ;   (str) - 不与主题串冲突的标记串
    let((t_m)
        t_m = "<YC-POS>"
        while(index(t_subj t_m)
            t_m = strcat(t_m "x")
        )
        t_m
    )
)

procedure(_MatchStart(g_pat t_subj n_exec "gtx")  ; -> int
    ; 用一次首处替换定位匹配起点（不依赖 lookbehind 锚定）。
    ;
    ; **参数**
    ;   g_pat   (compiled) - 已匹配成功的编译对象
    ;   t_subj  (str)      - 主题串
    ;   n_exec  (int)      - 执行选项位值
    ;
    ; **返回**
    ;   (int) - 首个匹配的 0-based 起始字节位
    let((t_m t_hit t_suf)
        t_m = _PosMarker(t_subj)
        t_hit = pcreReplace(g_pat t_subj t_m 1 n_exec)
        t_suf = index(t_hit t_m)
        length(t_hit) - length(t_suf)
    )
)

procedure(_ExportMarkers(t_subj "t")  ; -> list[str]
    ; 返回两个在主题串中不存在的导出标记（匹配标记、组标记）。
    ;
    ; **参数**
    ;   t_subj  (str) - 主题串
    ;
    ; **返回**
    ;   (list[str]) - (匹配标记 组标记)
    let((t_m t_g)
        t_m = "<YC-M>"
        while(index(t_subj t_m)
            t_m = strcat(t_m "x")
        )
        t_g = "<YC-G>"
        while(index(t_subj t_g)
            t_g = strcat(t_g "x")
        )
        list(t_m t_g)
    )
)

procedure(_ExportTemplate(n_g t_m t_g "xtt")  ; -> str
    ; 构造批量导出模板：匹配标记 + 整体 + 组标记 + 各组 + 尾组标记。
    ;
    ; **参数**
    ;   n_g  (int) - 捕获组数
    ;   t_m  (str) - 匹配标记
    ;   t_g  (str) - 组标记
    ;
    ; **返回**
    ;   (str) - pcreReplace 全量替换模板
    let((t_t n_k)
        t_t = strcat(t_m "&" t_g)
        n_k = 1
        while(n_k <= n_g
            t_t = strcat(t_t _Backref(n_k) t_g)
            n_k = n_k + 1
        )
        t_t
    )
)

procedure(_ExportRecords(g_pat t_subj n_exec "gtx")  ; -> list | sym
    ; 用一次全量替换导出全部非空匹配的记录；零宽/格式异常回 'fallback。
    ;
    ; **参数**
    ;   g_pat   (Pattern) - Pattern 实例
    ;   t_subj  (str)     - 主题串
    ;   n_exec  (int)     - 执行选项位值
    ;
    ; **返回**
    ;   (list|sym) - (start end . groups) 记录列表；无命中 nil；需回退 'fallback
    let((l_marks t_m t_g t_tpl t_out t_rest t_seg t_tail t_whole l_groups l_res
          n_delta n_out n_start n_consumed n_k t_cur)
        if(pcreMatchp(g_pat->_data->pcre t_subj 0 n_exec)
            progn(
                l_marks = _ExportMarkers(t_subj)
                t_m = car(l_marks)
                t_g = car(cdr(l_marks))
                t_tpl = _ExportTemplate(g_pat->_data->nGroups t_m t_g)
                t_out = pcreReplace(g_pat->_data->pcre t_subj t_tpl 0 n_exec)
                t_rest = t_out
                n_delta = 0
                n_out = 0
                while((t_seg = index(t_rest t_m))
                    n_out = n_out + length(t_rest) - length(t_seg)
                    n_start = n_out - n_delta
                    t_rest = _Suffix(t_seg length(t_m) + 1)
                    t_tail = index(t_rest t_g)
                    when(!t_tail
                        l_res = 'fallback
                        t_rest = ""
                    )
                    when(l_res == nil || l_res != 'fallback
                        n_consumed = length(t_rest) - length(t_tail)
                        t_whole = substring(t_rest 1 n_consumed)
                        t_rest = _Suffix(t_tail length(t_g) + 1)
                        l_groups = nil
                        n_k = 1
                        while(l_res != 'fallback && n_k <= g_pat->_data->nGroups
                            t_tail = index(t_rest t_g)
                            when(!t_tail
                                l_res = 'fallback
                                t_rest = ""
                            )
                            when(l_res != 'fallback
                                t_cur = substring(t_rest 1 length(t_rest) - length(t_tail))
                                l_groups = tconc(l_groups t_cur)
                                t_rest = _Suffix(t_tail length(t_g) + 1)
                                n_k = n_k + 1
                            )
                        )
                        when(l_res != 'fallback
                            if(n_consumed == 0
                                l_res = 'fallback
                                progn(
                                    l_res = tconc(l_res cons(n_start cons(n_start + n_consumed car(l_groups))))
                                    n_delta = n_delta + (length(t_seg) - length(t_rest)) - n_consumed
                                    n_out = n_out + (length(t_seg) - length(t_rest))
                                )
                            )
                        )
                    )
                )
                if(l_res == 'fallback 'fallback car(l_res))
            )
            nil
        )
    )
)

procedure(_HasBit(n_val n_bit "xx")  ; -> t | nil
    ; 判断位值是否包含某一位。
    ;
    ; **参数**
    ;   n_val  (int) - 位值
    ;   n_bit  (int) - 单个位
    ;
    ; **返回**
    ;   (t|nil) - 含该位时为 t
    remainder(n_val n_bit * 2) >= n_bit
)

procedure(_HasNumericGroupRef(t_pat "t")  ; -> t | nil
    ; 判断 pattern 是否含数字组引用/条件/子程序调用。
    ;
    ; **参数**
    ;   t_pat  (str) - 正则 pattern
    ;
    ; **返回**
    ;   (t|nil) - 含数字组引用时为 t
    let((n_i t_ref g_found)
        n_i = 1
        while(n_i <= 9 && !g_found
            t_ref = strcat("\\" sprintf(nil "%d" n_i))
            when(index(t_pat t_ref) g_found = t)
            when(index(t_pat strcat("(?" sprintf(nil "%d" n_i))) g_found = t)
            when(index(t_pat strcat("(?(" sprintf(nil "%d" n_i))) g_found = t)
            when(index(t_pat strcat("\\g{" sprintf(nil "%d" n_i) "}")) g_found = t)
            when(index(t_pat strcat("\\g<" sprintf(nil "%d" n_i) ">")) g_found = t)
            when(index(t_pat strcat("\\k<" sprintf(nil "%d" n_i) ">")) g_found = t)
            n_i = n_i + 1
        )
        g_found
    )
)

procedure(_ShiftNumericRefs(t_pat n_g "tx")  ; -> str | sym
    ; 把数字组引用/条件/子程序号整体 +2，供零宽前瞻包装使用。
    ;
    ; **参数**
    ;   t_pat  (str) - 原 pattern
    ;   n_g    (int) - 原捕获组数
    ;
    ; **返回**
    ;   (str|sym) - 平移后的 pattern；含不支持结构时回 'fallback
    let((t_res n_i n_len t_c t_next n_j n_num n_first t_tail)
        unless(_HasNumericGroupRef(t_pat)
            t_res = t_pat
        )
        when(_HasNumericGroupRef(t_pat)
            cond(
                (index(t_pat "[") 'fallback)
                (index(t_pat "\\Q") 'fallback)
                (index(t_pat "\\g") 'fallback)
                (index(t_pat "\\k") 'fallback)
                (index(t_pat "(?#") 'fallback)
                (index(t_pat "(?R") 'fallback)
                (index(t_pat "(?0") 'fallback)
                (t
                    t_res = ""
                    n_i = 1
                    n_len = length(t_pat)
                    while(n_i <= n_len && t_res != 'fallback
                        t_c = substring(t_pat n_i 1)
                        cond(
                            (t_c == "\\"
                                t_next = substring(t_pat n_i + 1 1)
                                if(index("123456789" t_next)
                                    progn(
                                        n_j = n_i + 1
                                        while(n_j <= n_len && index("0123456789" substring(t_pat n_j 1))
                                            n_j = n_j + 1
                                        )
                                        n_num = atoi(substring(t_pat n_i + 1 n_j - n_i - 1))
                                        if(n_num <= n_g
                                            progn(
                                                t_res = strcat(t_res "\\" sprintf(nil "%d" n_num + 2))
                                                n_i = n_j
                                            )
                                            progn(
                                                n_first = atoi(t_next)
                                                if(n_first <= n_g
                                                    progn(
                                                        t_res = strcat(t_res "\\" sprintf(nil "%d" n_first + 2)
                                                            if(n_j - n_i - 2 > 0 substring(t_pat n_i + 2 n_j - n_i - 2) ""))
                                                        n_i = n_j
                                                    )
                                                    t_res = 'fallback
                                                )
                                            )
                                        )
                                    )
                                    progn(
                                        t_res = strcat(t_res t_c t_next)
                                        n_i = n_i + 2
                                    )
                                )
                            )
                            (t_c == "(" && substring(t_pat n_i 2) == "(?"
                                t_next = substring(t_pat n_i + 2 1)
                                if(index("123456789" t_next)
                                    progn(
                                        n_j = n_i + 2
                                        while(n_j <= n_len && index("0123456789" substring(t_pat n_j 1))
                                            n_j = n_j + 1
                                        )
                                        n_num = atoi(substring(t_pat n_i + 2 n_j - n_i - 2))
                                        t_res = strcat(t_res "(?" sprintf(nil "%d" n_num + 2))
                                        n_i = n_j
                                    )
                                    if(t_next == "(" && index("123456789" substring(t_pat n_i + 3 1))
                                        progn(
                                            n_j = n_i + 3
                                            while(n_j <= n_len && index("0123456789" substring(t_pat n_j 1))
                                                n_j = n_j + 1
                                            )
                                            n_num = atoi(substring(t_pat n_i + 3 n_j - n_i - 3))
                                            t_res = strcat(t_res "(?(" sprintf(nil "%d" n_num + 2))
                                            n_i = n_j
                                        )
                                        progn(
                                            t_res = strcat(t_res t_c)
                                            n_i = n_i + 1
                                        )
                                    )
                                )
                            )
                            (t
                                t_res = strcat(t_res t_c)
                                n_i = n_i + 1
                            )
                        )
                    )
                )
            )
        )
        t_res
    )
)

procedure(_ZeroAtStart(g_pat t_subj n_exec "gtx")  ; -> list | sym
    ; 执行选项 anchored 下的零宽导出：只检查位置 0。
    ;
    ; **参数**
    ;   g_pat   (Pattern) - Pattern 实例
    ;   t_subj  (str)     - 主题串
    ;   n_exec  (int)     - 执行选项位值
    ;
    ; **返回**
    ;   (list|sym) - 位置 0 的零宽记录；非零宽或不匹配时回 'fallback/nil
    let((l_parts)
        if(pcreMatchp(g_pat->_data->span t_subj 0 n_exec)
            progn(
                l_parts = _ExtractParts(g_pat g_pat->_data->span)
                if(length(car(l_parts)) == 0
                    list(cons(0 cons(0 cdr(l_parts))))
                    'fallback
                )
            )
            nil
        )
    )
)

procedure(_ZeroWidthRecords(g_pat t_subj n_exec "gtx")  ; -> list | sym
    ; 用「消费一字符 + 前瞻」批量导出零宽匹配；不适用时回 'fallback。
    ;
    ; **参数**
    ;   g_pat   (Pattern) - Pattern 实例
    ;   t_subj  (str)     - 主题串
    ;   n_exec  (int)     - 执行选项位值
    ;
    ; **返回**
    ;   (list|sym) - (start end . groups) 记录列表；需回退 'fallback
    let((t_qpat t_pat2 g_qobj n_q g_qpat l_q l_0 l_parts l_res l_qgroups
          l_m t_pw n_start n_skip g_bad)
        cond(
            ((_HasBit(g_pat->_data->compileOpts 16) || _HasBit(n_exec 16))
                _ZeroAtStart(g_pat t_subj n_exec))
            (t
                t_pat2 = _ShiftNumericRefs(g_pat->_data->pattern g_pat->_data->nGroups)
                if(t_pat2 == 'fallback
                    'fallback
                    progn(
                        t_qpat = lsprintf("%s([\\s\\S])(?=((?:%s)))"
                            g_pat->_data->flags t_pat2)
                        g_qobj = _CompileChecked(t_qpat
                            "ycRegEx: zero-width probe" g_pat->_data->compileOpts)
                        if(g_qobj
                            progn(
                                n_q = pcreSubpatCount(g_qobj)
                                g_qpat = makeInstance('Pattern ?_data makeInstance('PatternData
                                    ?pcre g_qobj ?nGroups n_q))
                                l_q = _ExportRecords(g_qpat t_subj n_exec)
                                n_skip = 0
                                when(l_q == 'fallback g_bad = t)
                                when(pcreMatchp(g_pat->_data->span t_subj 0 n_exec)
                                    l_parts = _ExtractParts(g_pat g_pat->_data->span)
                                    if(length(car(l_parts)) == 0
                                        unless(_HasBit(n_exec 1024)
                                            l_0 = cons(0 cons(0 cdr(l_parts)))
                                        )
                                        g_bad = t
                                    )
                                )
                                when(!g_bad
                                    l_res = if(l_0 tconc(nil l_0) nil)
                                    foreach(l_m l_q
                                        l_qgroups = cdr(cdr(l_m))
                                        if(length(l_qgroups) < 2
                                            g_bad = t
                                            progn(
                                                t_pw = car(cdr(l_qgroups))
                                                n_start = car(l_m) + 1
                                                cond(
                                                    (n_start < n_skip nil)
                                                    (t_pw == "" && _HasBit(n_exec 1024) nil)
                                                    (t
                                                        progn(
                                                            l_res = tconc(l_res cons(n_start cons(n_start + length(t_pw) cdr(cdr(l_qgroups)))))
                                                            when(length(t_pw) > 0
                                                                n_skip = n_start + length(t_pw)
                                                            )
                                                        )
                                                    )
                                                )
                                            )
                                        )
                                    )
                                )
                                if(g_bad 'fallback car(l_res))
                            )
                            'fallback
                        )
                    )
                )
            )
        )
    )
)

procedure(_WalkRecords(g_pat t_subj n_exec "gtx")  ; -> list
    ; 逐位置锚定扫描全部匹配（零宽回退路径）。
    ;
    ; **参数**
    ;   g_pat   (Pattern) - Pattern 实例
    ;   t_subj  (str)     - 主题串
    ;   n_exec  (int)     - 执行选项位值
    ;
    ; **返回**
    ;   (list) - (start end . groups) 记录列表
    let((l_res l_m n_from)
        n_from = 0
        l_m = t
        while(l_m
            l_m = _NextMatch(g_pat t_subj n_from n_exec)
            when(l_m
                l_res = tconc(l_res l_m)
                n_from = if(car(cdr(l_m)) > car(l_m)
                    car(cdr(l_m))
                    car(l_m) + 1
                )
            )
        )
        car(l_res)
    )
)

procedure(_NextMatch(g_pat t_subj n_from n_exec "gtxx")  ; -> (int, int . list[str]) | nil
    ; 慢路径内核：从 n_from 起逐位置锚定扫描，取最左命中。
    ;
    ; **参数**
    ;   g_pat   (Pattern) - Pattern 实例
    ;   t_subj  (str)     - 主题串
    ;   n_from  (int)     - 起始扫描的 0-based 字节偏移
    ;   n_exec  (int)     - 执行选项位值（0 表示默认）
    ;
    ; **返回**
    ;   (int, int . list[str])|nil - 点对 (start end . 组值列表)：start/end 为 0-based
    ;                                匹配区间起止（end 开区间，end = start + 整体串长），groups 为组值列表（未参与组为 ""）；
    ;                                取 >= n_from 的最左命中（扫描位置 n_from 到 length(t_subj) 含末位），全部无命中返回 nil
    let((n_i n_len l_res)
        n_i = n_from
        n_len = length(t_subj)
        while(l_res == nil && n_i <= n_len
            let((g_obj)
                g_obj = _AnchorAt(g_pat n_i)
                if(pcreMatchp(g_obj t_subj 0 n_exec)
                    let((l_parts)
                        l_parts = _ExtractParts(g_pat g_obj)
                        l_res = cons(n_i cons(n_i + length(car(l_parts)) cdr(l_parts)))
                    )
                    n_i = n_i + 1
                )
            )
        )
        l_res
    )
)

procedure(_FindAllItem(g_pat t_subj l_m "gtl")  ; -> str | list[str]
    ; 把单个命中记录转换为 findall 的结果项（对齐 Python 形态）。
    ;
    ; **参数**
    ;   g_pat   (Pattern) - 提供捕获组数的 Pattern 实例
    ;   t_subj  (str)     - 主题串
    ;   l_m     (list)    - _NextMatch 的命中记录 (start end . 组值列表)
    ;
    ; **返回**
    ;   (str|list[str]) - 0 组返回整体串，1 组返回该组串，≥2 组返回组值列表
    let((l_gr)
        l_gr = cdr(cdr(l_m))
        case(g_pat->_data->nGroups
            (0
                _Prefix(_Suffix(t_subj car(l_m) + 1) car(cdr(l_m)) - car(l_m))
            )
            (1
                car(l_gr)
            )
            (t
                l_gr
            )
        )
    )
)

procedure(_MkMatch(g_pat t_subj g_start g_end l_groups g_anchor n_exec "gtgglgx")  ; -> Match
    ; 构造 Match 实例，收纳整体位置、捕获组值与锚对象。
    ;
    ; **参数**
    ;   g_pat     (Pattern)  - 归属的 Pattern 实例
    ;   t_subj    (str)      - 主题串
    ;   g_start   (int|nil)  - 0-based 起始字节位；search 路径传 nil（惰性定位）
    ;   g_end     (int|nil)  - 结束字节位（开区间）；search 路径传 nil（惰性定位）
    ;   l_groups  (list)     - 捕获组值列表（非参与组为 ""）
    ;   g_anchor  (compiled) - 锚对象（span 或 full），供惰性定位与 expand 重挂状态
    ;   n_exec    (int)      - 执行选项位值（0 表示默认）
    ;
    ; **返回**
    ;   (Match) - 新 Match 实例
    makeInstance('Match ?_data makeInstance('MatchData
        ?pattern g_pat ?subject t_subj ?start g_start ?end g_end
        ?groups l_groups ?anchor g_anchor ?execOpts n_exec))
)


; ---------- class definition ----------

; 数据桶：Match 状态（pattern subject start end groups anchor execOpts）收敛为单一 _data 槽
defclass(MatchData () (
    ; MatchData 数据桶：收纳 Match 的 pattern/subject/start/end/groups/anchor/execOpts 状态，构造后禁写。
    pattern(
        \@initarg pattern
        \@initform nil
    )
    subject(
        \@initarg subject
        \@initform ""
    )
    start(
        \@initarg start
        \@initform nil
    )
    end(
        \@initarg end
        \@initform nil
    )
    groups(
        \@initarg groups
        \@initform nil
    )
    anchor(
        \@initarg anchor
        \@initform nil
    )
    execOpts(
        \@initarg execOpts
        \@initform 0
    )
))

defclass(Match () (
    ; Match 实例：re 系匹配/查找（ReFinditer、Pattern->match/search/fullmatch 等）返回的匹配对象，提供串值、组值、span 位置与模板展开等查询。
    ; 状态桶（MatchData：pattern subject start end groups anchor execOpts），构造后禁写
    _data(
        \@initarg _data
        \@initform nil
    )
    group()
    groups()
    span()
    start()
    end()
    expand()
    groupdict()
))


defmethod(printself (self(Match))  ; -> str
    ; 返回 Match 的打印描述串，形如 <ycRegEx::Match "10-20">。
    ;
    ; **返回**
    ;   (str) - lsprintf 按 <类名 字面量> 模板生成（类名为限定名）
    lsprintf("<%A %A>" className(self) self->_data->subject)
)


; ---------- method installation ----------

inScheme(
procedure(_InstallMatch(self "g")  ; -> any
    ; 把 Match 方法安装到 Match 类（由 initializeInstance 调用）。
    ;
    ; **返回**
    ;   (any) - 返回最后一条安装赋值的结果，调用方忽略

procedure(_Error(t_method t_formatString \@rest g_args "ttg")  ; -> never
    ; 按统一格式 error() 中断：消息形如 <类名>-><方法名>: <说明>。
    ;
    ; **参数**
    ;   t_method        (str) - 出错的方法名
    ;   t_formatString  (str) - 错误说明格式串（lsprintf 格式）
    ;   g_args          (list) - 变参：格式串实参
    ;
    ; **返回**
    ;   (never) - 总是调用 error()，不返回
    error("%A->%s: %s" className(self) t_method apply('lsprintf t_formatString g_args))
)

self->span = lambda((\@rest g_args "g")  ; -> (int, int)
    ; 返回匹配区间 (start end) 的 0-based 字节位（end 开区间）。
    ;
    ; **参数**
    ;   g_args  (list) - 变参：组选择参数（span(g) 预留），传入任意参数即 _Error() 中断
    ;
    ; **返回**
    ;   (int, int) - (start end) 字节位；位置由构造方给出，缺失时走慢路径回填
    ;                无命中走 _Error() 中断
    let((l_rec)
        when(g_args
            _Error("span" "group arguments are not supported yet (reserved)")
        )
        when(self->_data->start == nil
            l_rec = _NextMatch(self->_data->pattern self->_data->subject 0 self->_data->execOpts)
            when(l_rec
                self->_data->start = car(l_rec)
                self->_data->end = car(cdr(l_rec))
            )
        )
        when(self->_data->start == nil
            _Error("span" "position walk failed unexpectedly")
        )
        list(self->_data->start self->_data->end)
    )
)

self->start = lambda((\@rest g_args "g")  ; -> int
    ; 返回匹配起始字节位（0-based）。
    ;
    ; **参数**
    ;   g_args  (list) - 变参：组选择参数（start(g) 预留），传入任意参数即 _Error() 中断
    ;
    ; **返回**
    ;   (int) - span() 的 start；位置惰性时首次调用走慢路径回填
    when(g_args
        _Error("start" "group arguments are not supported yet (reserved)")
    )
    car(self->span())
)

self->end = lambda((\@rest g_args "g")  ; -> int
    ; 返回匹配结束字节位（0-based，开区间）。
    ;
    ; **参数**
    ;   g_args  (list) - 变参：组选择参数（end(g) 预留），传入任意参数即 _Error() 中断
    ;
    ; **返回**
    ;   (int) - span() 的 end（start + 整体串字节长）；位置惰性时首次调用走慢路径回填
    when(g_args
        _Error("end" "group arguments are not supported yet (reserved)")
    )
    car(cdr(self->span()))
)

self->group = lambda((\@rest g_args "g")  ; -> str | list[str]
    ; 按组序号取组值（语义同 Python re.Match.group；按名取组预留，调用即 error() 中断）。
    ;
    ; **参数**
    ;   g_args  (list) - 变参：组选择器——无参取整体；单参 0 = 整体、1..n_g = 对应捕获组；
    ;                    多参逐个取值（0 可混入）；字符串参数（按名取组）预留
    ;
    ; **返回**
    ;   (str|list[str]) - 无参返回整体串，单参返回该组串，多参返回组值列表；
    ;                     非参与组为 ""（CPython None → ""）；序号越界走 error()（_GroupAt 直调）；
    ;                     非数字或按名参数走 _Error() 中断
    let((n_g)
        foreach(g g_args
            unless(fixp(g)
                if(stringp(g)
                    _Error("group" "group by name is not supported yet (reserved)")
                    _Error("group" "expected group number, got %A" g)
                )
            )
        )
        n_g = length(self->_data->groups)
        cond(
            (g_args == nil
                _GroupWhole(self)
            )
            (length(g_args) == 1
                _GroupAt(self car(g_args) n_g)
            )
            (t
                let((l_res)
                    foreach(g g_args
                        l_res = tconc(l_res _GroupAt(self g n_g))
                    )
                    car(l_res)
                )
            )
        )
    )
)

self->groups = lambda((\@key empty("") "g")  ; -> list
    ; 返回全部捕获组值列表，并用 ?empty 替换空结果。
    ;
    ; **参数**
    ;   ?empty  (any) - 空结果替换值（默认 ""）
    ;
    ; **返回**
    ;   (list) - 组值按序号排列；空字符串（含未参与组）替换为 empty；
    ;            无捕获组时为 nil（空列表）
    let((l_res)
        foreach(g self->_data->groups
            l_res = tconc(l_res if(g == "" empty g))
        )
        car(l_res)
    )
)

self->groupdict = lambda(()  ; -> never
    ; 返回组名到组值的字典（按名取组预留），本实现调用即 error() 中断。
    ;
    ; **返回**
    ;   (never) - 总是走 _Error() 中断（按名取组预留），不返回
    _Error("groupdict" "not supported yet (reserved)")
)

self->expand = lambda((t_tpl "t")  ; -> str
    ; 按模板展开整体匹配（语义同 Python re.Match.expand：先重挂状态再按引擎方言展开）。
    ;
    ; **参数**
    ;   t_tpl  (str) - 替换模板：引擎方言展开 \1~\9、&（整体）、\0、\n；& 在 Python 是字面量
    ;
    ; **返回**
    ;   (str) - 在全主题串上按匹配偏移重挂锚状态后由 pcreSubstitute 展开的结果；
    ;           t_tpl 非串、状态重挂失败或模板非法走 _Error() 中断
    let((l_sp g_ok g_obj l_res)
        unless(stringp(t_tpl)
            _Error("expand" "expected string template, got %A" t_tpl)
        )
        l_sp = self->span()
        g_obj = if(car(l_sp) == 0
            self->_data->anchor
            _AnchorAt(self->_data->pattern car(l_sp))
        )
        g_ok = errset(pcreMatchp(g_obj self->_data->subject 0 self->_data->execOpts) nil)
        unless(g_ok && car(g_ok)
            _Error("expand" "cannot re-establish match state")
        )
        l_res = errset(pcreSubstitute(g_obj t_tpl) nil)
        unless(l_res && stringp(car(l_res))
            _Error("expand" "bad template: %s" t_tpl)
        )
        car(l_res)
    )
)

))

inScheme(
defmethod(initializeInstance (self(Match) \@rest _args)
    ; 构造 Match 实例时调用 _InstallMatch 安装全部方法集。
    ;
    ; **参数**
    ;   _args  (list) - 变参：附加初始化参数，本实现忽略
    ;
    ; **返回**
    ;   (t) - 安装完成后返回 t
    _InstallMatch(self)
    t
)
)

unuseNamespace("ycRegEx")

; END
