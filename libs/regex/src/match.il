useNamespace("ycRegEx")


; ---------- Match helpers ----------

procedure(_groupWhole(self "g")  ; -> str
    ; 取整体匹配串（group() / group(0) 路径）：按 span 位置从主题串切片。
    ;
    ; **返回**
    ;   (str) - 主题串上 [start, end) 字节区间的切片；span 未定位时先经 span() 慢路径回填
    let((l_sp)
        l_sp = self->span()
        _prefix(_suffix(self->_data->subject car(l_sp) + 1) car(cdr(l_sp)) - car(l_sp))
    )
)

procedure(_groupAt(self n_i n_g "gnn")  ; -> str
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
            _groupWhole(self)
        )
        (n_i < 1 || n_i > n_g
            error("ycRegEx::Match->group: no such group: %d" n_i)
        )
        (t
            _nth1(self->_data->groups n_i)
        )
    )
)


; ---------- extraction templates: "&" whole + delimited groups, one substitute ----------

procedure(_wholeTemplate(n_g "n")  ; -> str
    ; 构造「整体 + 组值」提取模板：& 后按 <YC-B> 定界各组反向引用。
    ;
    ; **参数**
    ;   n_g  (int) - 捕获组数（0..9）
    ;
    ; **返回**
    ;   (str) - 形如 "&<YC-B>\1<YC-B>\2" 的模板，供一次 pcreSubstitute 展开
    let((t_t n_k)
        t_t = "&"
        n_k = 1
        while(n_k <= n_g
            t_t = lsprintf("%s<YC-B>\\%s" t_t _digitAt(n_k))
            n_k = n_k + 1
        )
        t_t
    )
)

procedure(_splitTemplate(n_g "n")  ; -> str
    ; 构造 split 替换模板：匹配处整体换成 <YC-S> 定界与组值交替的串。
    ;
    ; **参数**
    ;   n_g  (int) - 捕获组数（0..9）
    ;
    ; **返回**
    ;   (str) - 形如 "<YC-S>\1<YC-S>" 的模板，替换后按 <YC-S> 拆分
    let((t_t n_k)
        t_t = "<YC-S>"
        n_k = 1
        while(n_k <= n_g
            t_t = lsprintf("%s\\%s<YC-S>" t_t _digitAt(n_k))
            n_k = n_k + 1
        )
        t_t
    )
)

procedure(_extractParts(g_pat g_obj "gg")  ; -> (str . list[str])
    ; 从 g_obj 刚建立的匹配状态提取整体与各捕获组值（须在 pcreReplace 之前）。
    ;
    ; **参数**
    ;   g_pat  (Pattern)  - 提供捕获组数的 Pattern 实例
    ;   g_obj  (compiled) - 已 pcreMatchp 成功的编译对象
    ;
    ; **返回**
    ;   (str . list[str]) - 点对 (整体串 . 组值列表)；0 个捕获组时组值列表为空
    let((t_buf)
        t_buf = pcreSubstitute(g_obj _wholeTemplate(g_pat->_data->nGroups))
        if(g_pat->_data->nGroups == 0
            list(t_buf)
            _splitBy(t_buf "<YC-B>")
        )
    )
)

procedure(_anchorAt(g_pat n_off "gn")  ; -> compiled
    ; 生成在字节偏移 n_off 处精确锚定的编译对象，不截断左侧上下文。
    ;
    ; **参数**
    ;   g_pat  (Pattern) - Pattern 实例
    ;   n_off  (int)     - 0-based 起始字节偏移
    ;
    ; **返回**
    ;   (compiled) - n_off 为 0 时复用 span 对象；否则以 (?<=\A[\s\S]{n_off})(?:…) 编译，
    ;                编译失败 error() 中断
    if(n_off == 0
        g_pat->_data->span
        let((g_obj)
            g_obj = _compileChecked(lsprintf("%s(?<=\\A[\\s\\S]{%d})(?:%s)"
                g_pat->_data->flags n_off g_pat->_data->pattern))
            unless(g_obj
                error("ycRegEx: cannot compile anchor at offset %d" n_off)
            )
            g_obj
        )
    )
)

procedure(_nextMatch(g_pat t_subj n_from "gtn")  ; -> (int, int . list[str]) | nil
    ; 慢路径内核：从 n_from 起逐位置锚定扫描，取最左命中。
    ;
    ; **参数**
    ;   g_pat   (Pattern) - Pattern 实例
    ;   t_subj  (str)     - 主题串
    ;   n_from  (int)     - 起始扫描的 0-based 字节偏移
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
                g_obj = _anchorAt(g_pat n_i)
                if(pcreMatchp(g_obj t_subj)
                    let((l_parts)
                        l_parts = _extractParts(g_pat g_obj)
                        l_res = cons(n_i cons(n_i + length(car(l_parts)) cdr(l_parts)))
                    )
                    n_i = n_i + 1
                )
            )
        )
        l_res
    )
)

procedure(_findAllItem(g_pat t_subj l_m "gtl")  ; -> str | list[str]
    ; 把单个命中记录转换为 findall 的结果项（对齐 Python 形态）。
    ;
    ; **参数**
    ;   g_pat   (Pattern) - 提供捕获组数的 Pattern 实例
    ;   t_subj  (str)     - 主题串
    ;   l_m     (list)    - _nextMatch 的命中记录 (start end . 组值列表)
    ;
    ; **返回**
    ;   (str|list[str]) - 0 组返回整体串，1 组返回该组串，≥2 组返回组值列表
    let((l_gr)
        l_gr = cdr(cdr(l_m))
        case(g_pat->_data->nGroups
            (0
                _prefix(_suffix(t_subj car(l_m) + 1) car(cdr(l_m)) - car(l_m))
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

procedure(_mkMatch(g_pat t_subj g_start g_end l_groups g_anchor "gtgggg")  ; -> Match
    ; 构造 Match 实例，收纳整体位置、捕获组值与锚对象。
    ;
    ; **参数**
    ;   g_pat     (Pattern)  - 归属的 Pattern 实例
    ;   t_subj    (str)      - 主题串
    ;   g_start   (int|nil)  - 0-based 起始字节位；search 路径传 nil（惰性定位）
    ;   g_end     (int|nil)  - 结束字节位（开区间）；search 路径传 nil（惰性定位）
    ;   l_groups  (list)     - 捕获组值列表（非参与组为 ""）
    ;   g_anchor  (compiled) - 锚对象（span 或 full），供惰性定位与 expand 重挂状态
    ;
    ; **返回**
    ;   (Match) - 新 Match 实例
    makeInstance('Match ?_data makeInstance('MatchData
        ?pattern g_pat ?subject t_subj ?start g_start ?end g_end
        ?groups l_groups ?anchor g_anchor))
)


; ---------- class definition ----------

; 数据桶：Match 状态（pattern subject start end groups anchor）收敛为单一 _data 槽
defclass(MatchData () (
    ; MatchData 数据桶：收纳 Match 的 pattern/subject/start/end/groups/anchor 状态，构造后禁写。
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
))

defclass(Match () (
    ; Match 实例：re 系匹配/查找（reFinditer、Pattern->match/search/fullmatch 等）返回的匹配对象，提供串值、组值、span 位置与模板展开等查询。
    ; 状态桶（MatchData：pattern subject start end groups anchor），构造后禁写
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
procedure(_installMatch(self "g")  ; -> any
    ; 把 Match 方法安装到 Match 类（由 initializeInstance 调用）。
    ;
    ; **返回**
    ;   (any) - 返回最后一条安装赋值的结果，调用方忽略

procedure(_error(t_method t_formatString \@rest g_args "ttg")  ; -> never
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
    ;   g_args  (list) - 变参：组选择参数（span(g) 预留），传入任意参数即 _error() 中断
    ;
    ; **返回**
    ;   (int, int) - (start end) 字节位；search 路径构造的 Match 位置惰性，首次调用才走
    ;                慢路径逐位置锚定回填，回填无命中走 _error() 中断
    let((l_rec)
        when(g_args
            _error("span" "group arguments are not supported yet (reserved)")
        )
        when(self->_data->start == nil
            l_rec = _nextMatch(self->_data->pattern self->_data->subject 0)
            when(l_rec
                self->_data->start = car(l_rec)
                self->_data->end = car(cdr(l_rec))
            )
        )
        when(self->_data->start == nil
            _error("span" "position walk failed unexpectedly")
        )
        list(self->_data->start self->_data->end)
    )
)

self->start = lambda((\@rest g_args "g")  ; -> int
    ; 返回匹配起始字节位（0-based）。
    ;
    ; **参数**
    ;   g_args  (list) - 变参：组选择参数（start(g) 预留），传入任意参数即 _error() 中断
    ;
    ; **返回**
    ;   (int) - span() 的 start；位置惰性时首次调用走慢路径回填
    when(g_args
        _error("start" "group arguments are not supported yet (reserved)")
    )
    car(self->span())
)

self->end = lambda((\@rest g_args "g")  ; -> int
    ; 返回匹配结束字节位（0-based，开区间）。
    ;
    ; **参数**
    ;   g_args  (list) - 变参：组选择参数（end(g) 预留），传入任意参数即 _error() 中断
    ;
    ; **返回**
    ;   (int) - span() 的 end（start + 整体串字节长）；位置惰性时首次调用走慢路径回填
    when(g_args
        _error("end" "group arguments are not supported yet (reserved)")
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
    ;                     非参与组为 ""（CPython None → ""）；序号越界走 error()（_groupAt 直调）；
    ;                     非数字或按名参数走 _error() 中断
    let((n_g)
        foreach(g g_args
            unless(numberp(g)
                if(stringp(g)
                    _error("group" "group by name is not supported yet (reserved)")
                    _error("group" "expected group number, got %A" g)
                )
            )
        )
        n_g = length(self->_data->groups)
        cond(
            (g_args == nil
                _groupWhole(self)
            )
            (length(g_args) == 1
                _groupAt(self car(g_args) n_g)
            )
            (t
                let((l_res)
                    foreach(g g_args
                        l_res = tconc(l_res _groupAt(self g n_g))
                    )
                    car(l_res)
                )
            )
        )
    )
)

self->groups = lambda(()  ; -> list[str]
    ; 返回全部捕获组值列表（语义同 Python re.Match.groups）。
    ;
    ; **返回**
    ;   (list[str]) - 组值按序号排列，非参与组为 ""（CPython None → ""）；
    ;                 无捕获组时为 nil（空列表）
    self->_data->groups
)

self->groupdict = lambda(()  ; -> never
    ; 返回组名到组值的字典（按名取组预留），本实现调用即 error() 中断。
    ;
    ; **返回**
    ;   (never) - 总是走 _error() 中断（按名取组预留），不返回
    _error("groupdict" "not supported yet (reserved)")
)

self->expand = lambda((t_tpl "t")  ; -> str
    ; 按模板展开整体匹配（语义同 Python re.Match.expand：先重挂状态再按引擎方言展开）。
    ;
    ; **参数**
    ;   t_tpl  (str) - 替换模板：引擎方言展开 \1~\9、&（整体）、\0、\n；& 在 Python 是字面量
    ;
    ; **返回**
    ;   (str) - 在全主题串上按匹配偏移重挂锚状态后由 pcreSubstitute 展开的结果；
    ;           t_tpl 非串、状态重挂失败或模板非法走 _error() 中断
    let((l_sp g_ok g_obj l_res)
        unless(stringp(t_tpl)
            _error("expand" "expected string template, got %A" t_tpl)
        )
        l_sp = self->span()
        g_obj = if(car(l_sp) == 0
            self->_data->anchor
            _anchorAt(self->_data->pattern car(l_sp))
        )
        g_ok = errset(pcreMatchp(g_obj self->_data->subject) nil)
        unless(g_ok && car(g_ok)
            _error("expand" "cannot re-establish match state")
        )
        l_res = errset(pcreSubstitute(g_obj t_tpl) nil)
        unless(l_res && stringp(car(l_res))
            _error("expand" "bad template: %s" t_tpl)
        )
        car(l_res)
    )
)

))

inScheme(
defmethod(initializeInstance (self(Match) \@rest _args)
    ; 构造 Match 实例时调用 _installMatch 安装全部方法集。
    ;
    ; **参数**
    ;   _args  (list) - 变参：附加初始化参数，本实现忽略
    ;
    ; **返回**
    ;   (t) - 安装完成后返回 t
    _installMatch(self)
    t
)
)

unuseNamespace("ycRegEx")

; END
