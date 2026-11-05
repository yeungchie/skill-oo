useNamespace("ycRegEx")


; ---------- Matched helpers ----------

procedure(_GroupWhole(self "g")  ; -> str
    ; 取整体匹配串（group() / group(0) 路径）：按 span 位置从主题串切片。
    ;
    ; **返回**
    ;   (str) - 主题串上 [start, end) 字节区间的切片；span 未定位时先经 span() 慢路径回填
    let((sp)
        sp = self->span()
        _Prefix(_Suffix(self->_data->subject car(sp) + 1) car(cdr(sp)) - car(sp))
    )
)

procedure(_GroupAt(self n_i n_g "gxx")  ; -> str
    ; 按组序号取组值（group 单参与多参路径共用；0 表示整体）。
    ;
    ; **参数**
    ;   n_i  (int) - 组序号：0 = 整体，1..n_g = 对应捕获组
    ;   n_g  (int) - 捕获组总数（Matched 组值列表的长度）
    ;
    ; **返回**
    ;   (str) - 0 返回整体串，其余返回对应组值（非参与组为 ""）；n_i < 1 或 > n_g 时 error() 中断
    cond(
        (n_i == 0
            _GroupWhole(self)
        )
        (n_i < 1 || n_i > n_g
            error("ycRegEx::Matched->group: no such group: %d" n_i)
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
    let((value k)
        value = "&"
        k = 1
        while(k <= n_g
            value = lsprintf("%s<YC-B>%s" value _Backref(k))
            k++
        )
        value
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
    let((value k)
        value = "<YC-S>"
        k = 1
        while(k <= n_g
            value = lsprintf("%s%s<YC-S>" value _Backref(k))
            k++
        )
        value
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
    let((buf)
        buf = pcreSubstitute(g_obj _WholeTemplate(g_pat->_data->nGroups))
        if(g_pat->_data->nGroups == 0
            list(buf)
            _SplitBy(buf "<YC-B>")
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
        let((obj)
            obj = _CompileChecked(
                lsprintf("%s(?<=\\A[\\s\\S]{%d})(?:%s)" g_pat->_data->flags n_off g_pat->_data->pattern)
                lsprintf("ycRegEx: anchor at offset %d" n_off)
                g_pat->_data->compileOpts
            )
            obj
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
    let((m)
        m = "<YC-POS>"
        while(index(t_subj m)
            m = strcat(m "x")
        )
        m
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
    let((m hit suf)
        m = _PosMarker(t_subj)
        hit = pcreReplace(g_pat t_subj m 1 n_exec)
        suf = index(hit m)
        length(hit) - length(suf)
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
    let((m g2)
        m = "<YC-M>"
        while(index(t_subj m)
            m = strcat(m "x")
        )
        g2 = "<YC-G>"
        while(index(t_subj g2)
            g2 = strcat(g2 "x")
        )
        list(m g2)
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
    let((value k)
        value = strcat(t_m "&" t_g)
        k = 1
        while(k <= n_g
            value = strcat(value _Backref(k) t_g)
            k++
        )
        value
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
    let((marks m g2 tpl out rest seg tail whole groups2 res2
          delta out2 start2 consumed k cur)
        when(pcreMatchp(g_pat->_data->pcre t_subj 0 n_exec)
            progn(
                marks = _ExportMarkers(t_subj)
                m = car(marks)
                g2 = car(cdr(marks))
                tpl = _ExportTemplate(g_pat->_data->nGroups m g2)
                out = pcreReplace(g_pat->_data->pcre t_subj tpl 0 n_exec)
                rest = out
                delta = 0
                out2 = 0
                while((seg = index(rest m))
                    out2 = out2 + length(rest) - length(seg)
                    start2 = out2 - delta
                    rest = _Suffix(seg length(m) + 1)
                    tail = index(rest g2)
                    when(!tail
                        res2 = 'fallback
                        rest = ""
                    )
                    when(res2 == nil || res2 != 'fallback
                        consumed = length(rest) - length(tail)
                        whole = substring(rest 1 consumed)
                        rest = _Suffix(tail length(g2) + 1)
                        groups2 = nil
                        k = 1
                        while(res2 != 'fallback && k <= g_pat->_data->nGroups
                            tail = index(rest g2)
                            when(!tail
                                res2 = 'fallback
                                rest = ""
                            )
                            when(res2 != 'fallback
                                cur = substring(rest 1 length(rest) - length(tail))
                                groups2 = tconc(groups2 cur)
                                rest = _Suffix(tail length(g2) + 1)
                                k++
                            )
                        )
                        when(res2 != 'fallback
                            if(consumed == 0
                            then
                                res2 = 'fallback
                            else
                                res2 = tconc(res2 cons(start2 cons(start2 + consumed car(groups2))))
                                delta = delta + (length(seg) - length(rest)) - consumed
                                out2 = out2 + (length(seg) - length(rest))
                            )
                        )
                    )
                )
                if(res2 == 'fallback 'fallback car(res2))
            )
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
    let((i ref found)
        i = 1
        while(i <= 9 && !found
            ref = strcat("\\" sprintf(nil "%d" i))
            when(index(t_pat ref) found = t)
            when(index(t_pat strcat("(?" sprintf(nil "%d" i))) found = t)
            when(index(t_pat strcat("(?(" sprintf(nil "%d" i))) found = t)
            when(index(t_pat strcat("\\g{" sprintf(nil "%d" i) "}")) found = t)
            when(index(t_pat strcat("\\g<" sprintf(nil "%d" i) ">")) found = t)
            when(index(t_pat strcat("\\k<" sprintf(nil "%d" i) ">")) found = t)
            i++
        )
        found
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
    let((res2 i len c next j num first tail)
        unless(_HasNumericGroupRef(t_pat)
            res2 = t_pat
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
                    res2 = ""
                    i = 1
                    len = length(t_pat)
                    while(i <= len && res2 != 'fallback
                        c = substring(t_pat i 1)
                        cond(
                            (c == "\\"
                                next = substring(t_pat i + 1 1)
                                if(index("123456789" next)
                                then
                                    j = i + 1
                                    while(j <= len && index("0123456789" substring(t_pat j 1))
                                        j++
                                    )
                                    num = atoi(substring(t_pat i + 1 j - i - 1))
                                    if(num <= n_g
                                    then
                                        res2 = strcat(res2 "\\" sprintf(nil "%d" num + 2))
                                        i = j
                                    else
                                        first = atoi(next)
                                        if(first <= n_g
                                        then
                                            res2 = strcat(res2 "\\" sprintf(nil "%d" first + 2)
                                                if(j - i - 2 > 0 substring(t_pat i + 2 j - i - 2) ""))
                                            i = j
                                        else
                                            res2 = 'fallback
                                        )
                                    )
                                else
                                    res2 = strcat(res2 c next)
                                    i = i + 2
                                )
                            )
                            (c == "(" && substring(t_pat i 2) == "(?"
                                next = substring(t_pat i + 2 1)
                                if(index("123456789" next)
                                then
                                    j = i + 2
                                    while(j <= len && index("0123456789" substring(t_pat j 1))
                                        j++
                                    )
                                    num = atoi(substring(t_pat i + 2 j - i - 2))
                                    res2 = strcat(res2 "(?" sprintf(nil "%d" num + 2))
                                    i = j
                                else
                                    if(next == "(" && index("123456789" substring(t_pat i + 3 1))
                                    then
                                        j = i + 3
                                        while(j <= len && index("0123456789" substring(t_pat j 1))
                                            j++
                                        )
                                        num = atoi(substring(t_pat i + 3 j - i - 3))
                                        res2 = strcat(res2 "(?(" sprintf(nil "%d" num + 2))
                                        i = j
                                    else
                                        res2 = strcat(res2 c)
                                        i++
                                    )
                                )
                            )
                            (t
                                res2 = strcat(res2 c)
                                i++
                            )
                        )
                    )
                )
            )
        )
        res2
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
    let((parts)
        when(pcreMatchp(g_pat->_data->span t_subj 0 n_exec)
            parts = _ExtractParts(g_pat g_pat->_data->span)
            if(length(car(parts)) == 0
                list(cons(0 cons(0 cdr(parts))))
                'fallback
            )
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
    let((qpat pat2 qobj q qpat2 q2 l_0 parts res2 qgroups
          m pw start2 skip bad)
        cond(
            ((_HasBit(g_pat->_data->compileOpts 16) || _HasBit(n_exec 16))
                _ZeroAtStart(g_pat t_subj n_exec))
            (t
                pat2 = _ShiftNumericRefs(g_pat->_data->pattern g_pat->_data->nGroups)
                if(pat2 == 'fallback
                then
                    'fallback
                else
                    qpat = lsprintf("%s([\\s\\S])(?=((?:%s)))"
                        g_pat->_data->flags pat2)
                    qobj = _CompileChecked(qpat
                        "ycRegEx: zero-width probe" g_pat->_data->compileOpts)
                    if(qobj
                    then
                        q = pcreSubpatCount(qobj)
                        qpat2 = makeInstance('Pattern ?_data makeInstance('_PatternData
                            ?pcre qobj ?nGroups q))
                        q2 = _ExportRecords(qpat2 t_subj n_exec)
                        skip = 0
                        when(q2 == 'fallback bad = t)
                        when(pcreMatchp(g_pat->_data->span t_subj 0 n_exec)
                            parts = _ExtractParts(g_pat g_pat->_data->span)
                            if(length(car(parts)) == 0
                                unless(_HasBit(n_exec 1024)
                                    l_0 = cons(0 cons(0 cdr(parts)))
                                )
                                bad = t
                            )
                        )
                        when(!bad
                            res2 = when(l_0 tconc(nil l_0))
                            foreach(m2 q2
                                qgroups = cdr(cdr(m2))
                                if(length(qgroups) < 2
                                then
                                    bad = t
                                else
                                    pw = car(cdr(qgroups))
                                    start2 = car(m2) + 1
                                    cond(
                                        (start2 < skip nil)
                                        (pw == "" && _HasBit(n_exec 1024) nil)
                                        (t
                                            progn(
                                                res2 = tconc(res2 cons(start2 cons(start2 + length(pw) cdr(cdr(qgroups)))))
                                                when(length(pw) > 0
                                                    skip = start2 + length(pw)
                                                )
                                            )
                                        )
                                    )
                                )
                            )
                        )
                        if(bad 'fallback car(res2))
                    else
                        'fallback
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
    let((res2 m from)
        from = 0
        m = t
        while(m
            m = _NextMatch(g_pat t_subj from n_exec)
            when(m
                res2 = tconc(res2 m)
                from = if(car(cdr(m)) > car(m)
                    car(cdr(m))
                    car(m) + 1
                )
            )
        )
        car(res2)
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
    let((i len res2)
        i = n_from
        len = length(t_subj)
        while(res2 == nil && i <= len
            let((obj)
                obj = _AnchorAt(g_pat i)
                if(pcreMatchp(obj t_subj 0 n_exec)
                    let((parts)
                        parts = _ExtractParts(g_pat obj)
                        res2 = cons(i cons(i + length(car(parts)) cdr(parts)))
                    )
                    i++
                )
            )
        )
        res2
    )
)

procedure(_FindAllItem(g_pat t_subj l_m "gtl")  ; -> str | list[str]
    ; 把单个命中记录转换为 findall 的结果项。
    ;
    ; **参数**
    ;   g_pat   (Pattern) - 提供捕获组数的 Pattern 实例
    ;   t_subj  (str)     - 主题串
    ;   l_m     (list)    - _NextMatch 的命中记录 (start end . 组值列表)
    ;
    ; **返回**
    ;   (str|list[str]) - 0 组返回整体串，1 组返回该组串，≥2 组返回组值列表
    let((gr)
        gr = cdr(cdr(l_m))
        case(g_pat->_data->nGroups
            (0
                _Prefix(_Suffix(t_subj car(l_m) + 1) car(cdr(l_m)) - car(l_m))
            )
            (1
                car(gr)
            )
            (t
                gr
            )
        )
    )
)

procedure(_MkMatch(g_pat t_subj g_start g_end l_groups g_anchor n_exec "gtgglgx")  ; -> Matched
    ; 构造 Matched 实例，收纳整体位置、捕获组值与锚对象。
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
    ;   (Matched) - 新 Matched 实例
    makeInstance('Matched ?_data makeInstance('_MatchedData
        ?pattern g_pat ?subject t_subj ?start g_start ?end g_end
        ?groups l_groups ?anchor g_anchor ?execOpts n_exec))
)


; ---------- class definition ----------

; 数据桶：Matched 状态（pattern subject start end groups anchor execOpts）收敛为单一 _data 槽
defclass(_MatchedData () (
    ; _MatchedData 数据桶：收纳 Matched 的 pattern/subject/start/end/groups/anchor/execOpts 状态，构造后禁写。
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

defclass(Matched () (
    ; Matched 实例：re 系匹配/查找（Finditer、Pattern->match/search/fullmatch 等）返回的匹配对象，提供串值、组值、span 位置与模板展开等查询。
    ; 状态桶（_MatchedData：pattern subject start end groups anchor execOpts），构造后禁写
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


defmethod(printself (self(Matched))  ; -> str
    ; 返回 Matched 的打印描述串，形如 <ycRegEx::Matched "10-20">。
    ;
    ; **返回**
    ;   (str) - lsprintf 按 <类名 字面量> 模板生成（类名为限定名）
    lsprintf("<%A %A>" className(self) self->_data->subject)
)


; ---------- method installation ----------

inScheme(
procedure(_InstallMatch(self "g")  ; -> t
    ; 把 Matched 方法安装到 Matched 类（由 initializeInstance 调用）。
    ;
    ; **返回**
    ;   (t) - 安装完成；调用方忽略

procedure(_error(t_method t_formatString \@rest l_args "ttg")  ; -> never
    ; 按统一格式 error() 中断：消息形如 <类名>-><方法名>: <说明>。
    ;
    ; **参数**
    ;   t_method        (str) - 出错的方法名
    ;   t_formatString  (str) - 错误说明格式串（lsprintf 格式）
    ;   l_args          (list) - 变参：格式串实参
    ;
    ; **返回**
    ;   (never) - 总是调用 error()，不返回
    error("%A->%s: %s" className(self) t_method apply('lsprintf t_formatString l_args))
)

self->span = lambda((\@rest l_args "g")  ; -> (int, int)
    ; 返回匹配区间 (start end) 的 0-based 字节位（end 开区间）。
    ;
    ; **参数**
    ;   l_args  (list) - 变参：组选择参数（span(g) 预留），传入任意参数即 _error() 中断
    ;
    ; **返回**
    ;   (int, int) - (start end) 字节位；位置由构造方给出，缺失时走慢路径回填
    ;                无命中走 _error() 中断
    let((rec)
        when(l_args
            _error("span" "group arguments are not supported yet (reserved)")
        )
        when(self->_data->start == nil
            rec = _NextMatch(self->_data->pattern self->_data->subject 0 self->_data->execOpts)
            when(rec
                self->_data->start = car(rec)
                self->_data->end = car(cdr(rec))
            )
        )
        when(self->_data->start == nil
            _error("span" "position walk failed unexpectedly")
        )
        list(self->_data->start self->_data->end)
    )
)

self->start = lambda((\@rest l_args "g")  ; -> int
    ; 返回匹配起始字节位（0-based）。
    ;
    ; **参数**
    ;   l_args  (list) - 变参：组选择参数（start(g) 预留），传入任意参数即 _error() 中断
    ;
    ; **返回**
    ;   (int) - span() 的 start；位置惰性时首次调用走慢路径回填
    when(l_args
        _error("start" "group arguments are not supported yet (reserved)")
    )
    car(self->span())
)

self->end = lambda((\@rest l_args "g")  ; -> int
    ; 返回匹配结束字节位（0-based，开区间）。
    ;
    ; **参数**
    ;   l_args  (list) - 变参：组选择参数（end(g) 预留），传入任意参数即 _error() 中断
    ;
    ; **返回**
    ;   (int) - span() 的 end（start + 整体串字节长）；位置惰性时首次调用走慢路径回填
    when(l_args
        _error("end" "group arguments are not supported yet (reserved)")
    )
    car(cdr(self->span()))
)

self->group = lambda((\@rest l_args "g")  ; -> str | list[str]
    ; 按组序号或组名取组值。
    ;
    ; **参数**
    ;   l_args  (list) - 变参：组选择器——无参取整体；单参 0 = 整体、1..n_g = 对应捕获组、
    ;                    字符串 = 组名；多参逐个取值（序号与组名可混用）
    ;
    ; **返回**
    ;   (str|list[str]) - 无参返回整体串，单参返回该组串，多参返回组值列表；
    ;                     非参与组为 ""；序号越界或组名不存在走 error() 中断；
    ;                     既非整数也非字符串的参数走 _error() 中断
    let((g2 sel loaded names)
        g2 = length(self->_data->groups)
        sel = nil
        foreach(g l_args
            if(fixp(g)
            then
                sel = tconc(sel g)
            else
                unless(stringp(g)
                    _error("group" "expected group number or name, got %A" g)
                )
                unless(loaded
                    names = self->_data->pattern->groupindex()
                    loaded = t
                )
                let((i)
                    i = when(names names[g])
                    unless(fixp(i)
                        _error("group" "no such group name: %A" g)
                    )
                    sel = tconc(sel i)
                )
            )
        )
        sel = car(sel)
        cond(
            (sel == nil
                _GroupWhole(self)
            )
            (length(sel) == 1
                _GroupAt(self car(sel) g2)
            )
            (t
                let((res2)
                    foreach(n sel
                        res2 = tconc(res2 _GroupAt(self n g2))
                    )
                    car(res2)
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
    let((res2)
        foreach(g self->_data->groups
            res2 = tconc(res2 if(g == "" empty g))
        )
        car(res2)
    )
)

self->groupdict = lambda((\@key empty("") "g")  ; -> table | nil
    ; 返回组名到组值的字典，并用 ?empty 替换空结果。
    ;
    ; **参数**
    ;   ?empty  (any) - 空结果替换值（默认 ""）
    ;
    ; **返回**
    ;   (table|nil) - 组名 -> 组值；模式无命名组时 nil；
    ;                 组名映射不可用时以 error() 中断
    let((names res g2 val name)
        names = self->_data->pattern->groupindex()
        when(names
            g2 = length(self->_data->groups)
            res = makeTable("ycRegExGroupDict" nil)
            foreach(name names
                val = _GroupAt(self names[name] g2)
                res[name] = if(val == "" empty val)
            )
        )
        res
    )
)

self->expand = lambda((t_tpl "t")  ; -> str
    ; 按模板展开整体匹配：先重挂状态再按引擎方言展开。
    ;
    ; **参数**
    ;   t_tpl  (str) - 替换模板：引擎方言展开 \1~\9、&（整体）、\0、\n
    ;
    ; **返回**
    ;   (str) - 在全主题串上按匹配偏移重挂锚状态后由 pcreSubstitute 展开的结果；
    ;           t_tpl 非串、状态重挂失败或模板非法走 _error() 中断
    let((sp ok obj res2)
        unless(stringp(t_tpl)
            _error("expand" "expected string template, got %A" t_tpl)
        )
        sp = self->span()
        obj = if(car(sp) == 0
            self->_data->anchor
            _AnchorAt(self->_data->pattern car(sp))
        )
        ok = errset(pcreMatchp(obj self->_data->subject 0 self->_data->execOpts) nil)
        unless(ok && car(ok)
            _error("expand" "cannot re-establish match state")
        )
        res2 = errset(pcreSubstitute(obj t_tpl) nil)
        unless(res2 && stringp(car(res2))
            _error("expand" "bad template: %s" t_tpl)
        )
        car(res2)
    )
)

))

inScheme(
defmethod(initializeInstance (self(Matched) \@rest _args)
    ; 构造 Matched 实例时调用 _InstallMatch 安装全部方法集。
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
