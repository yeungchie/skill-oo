useNamespace("ycRegEx")


; ---------- class definition ----------

; 数据桶：Pattern 状态（pattern flags compileOpts pcre span full nGroups）收敛为单一 _data 槽
defclass(PatternData () (
    ; PatternData 数据桶：收纳 Pattern 的 pattern/flags/compileOpts/pcre/span/full/nGroups 状态，构造后禁写。
    pattern(
        \@initarg pattern
        \@initform ""
    )
    flags(
        \@initarg flags
        \@initform ""
    )
    pcre(
        \@initarg pcre
        \@initform nil
    )
    span(
        \@initarg span
        \@initform nil
    )
    full(
        \@initarg full
        \@initform nil
    )
    compileOpts(
        \@initarg compileOpts
        \@initform 0
    )
    nGroups(
        \@initarg nGroups
        \@initform 0
    )
))

defclass(Pattern () (
    ; Pattern 实例：Compile() 返回的已编译模式对象，方法语义同对应自由函数。
    ; 状态桶（PatternData：pattern flags compileOpts pcre span full nGroups），构造后禁写
    _data(
        \@initarg _data
        \@initform nil
    )
    match()
    search()
    fullmatch()
    findall()
    finditer()
    partialp()
    split()
    sub()
    subn()
    groups()
    pattern()
))


defmethod(printself (self(Pattern))  ; -> str
    ; 返回 Pattern 的打印描述串，形如 <ycRegEx::Pattern "\\d+">。
    ;
    ; **返回**
    ;   (str) - lsprintf 按 <类名 字面量> 模板生成
    lsprintf("<%A %A>" className(self) self->_data->pattern)
)


; ---------- method installation ----------


inScheme(
procedure(_InstallPattern(self "g")  ; -> any
    ; 把 Pattern 方法安装到 Pattern 类（由 initializeInstance 调用）。
    ;
    ; **返回**
    ;   (any) - 返回最后一条安装赋值的结果，调用方忽略

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

self->match = lambda((t_subj \@key execOpts "tg")  ; -> Matched | nil
    ; 在主题串开头锚定匹配（同函数 ycRegEx::Match，前锚 \A）。
    ;
    ; **参数**
    ;   t_subj     (str)         - 主题串
    ;   ?execOpts  (sym|list|nil) - 执行选项符号或列表（默认 nil）
    ;
    ; **返回**
    ;   (Matched|nil) - 起始处命中返回 Matched（位置构造即知），未命中返回 nil
    let((l_parts n_exec)
        n_exec = _ExecOptsBits(execOpts "ycRegEx::Pattern->match")
        when(pcreMatchp(self->_data->span t_subj 0 n_exec)
            l_parts = _ExtractParts(self self->_data->span)
            _MkMatch(self t_subj 0 length(car(l_parts)) cdr(l_parts) self->_data->span n_exec)
        )
    )
)

self->search = lambda((t_subj \@key execOpts "tg")  ; -> Matched | nil
    ; 搜索主题串中的首个匹配（同函数 ycRegEx::Search，span 惰性）。
    ;
    ; **参数**
    ;   t_subj     (str)         - 主题串
    ;   ?execOpts  (sym|list|nil) - 执行选项符号或列表（默认 nil）
    ;
    ; **返回**
    ;   (Matched|nil) - 命中返回 Matched（位置已定位），未命中返回 nil
    let((l_parts n_exec n_start)
        n_exec = _ExecOptsBits(execOpts "ycRegEx::Pattern->search")
        when(pcreMatchp(self->_data->pcre t_subj 0 n_exec)
            l_parts = _ExtractParts(self self->_data->pcre)
            n_start = _MatchStart(self->_data->pcre t_subj n_exec)
            _MkMatch(self t_subj n_start n_start + length(car(l_parts))
                cdr(l_parts) self->_data->span n_exec)
        )
    )
)

self->fullmatch = lambda((t_subj \@key execOpts "tg")  ; -> Matched | nil
    ; 整串匹配（同函数 ycRegEx::Fullmatch，经 full 锚 \A(?:…)\z）。
    ;
    ; **参数**
    ;   t_subj     (str)         - 主题串
    ;   ?execOpts  (sym|list|nil) - 执行选项符号或列表（默认 nil）
    ;
    ; **返回**
    ;   (Matched|nil) - 匹配覆盖整个主题串返回 Matched（位置构造即知），否则返回 nil
    let((l_parts n_exec)
        n_exec = _ExecOptsBits(execOpts "ycRegEx::Pattern->fullmatch")
        when(pcreMatchp(self->_data->full t_subj 0 n_exec)
            l_parts = _ExtractParts(self self->_data->full)
            _MkMatch(self t_subj 0 length(car(l_parts)) cdr(l_parts) self->_data->full n_exec)
        )
    )
)

self->finditer = lambda((t_subj \@key execOpts "tg")  ; -> list[Matched]
    ; 返回全部匹配的 Matched 列表（同函数 ycRegEx::Finditer，慢路径内核）。
    ;
    ; **参数**
    ;   t_subj     (str)         - 主题串
    ;   ?execOpts  (sym|list|nil) - 执行选项符号或列表（默认 nil）
    ;
    ; **返回**
    ;   (list[Matched]) - 全量 Matched 列表；非空匹配批量导出，零宽匹配回退逐位置扫描并按 start + 1 推进
    let((l_res l_recs n_exec l_m)
        n_exec = _ExecOptsBits(execOpts "ycRegEx::Pattern->finditer")
        l_recs = _ExportRecords(self t_subj n_exec)
        when(l_recs == 'fallback
            l_recs = _ZeroWidthRecords(self t_subj n_exec)
        )
        when(l_recs == 'fallback
            l_recs = _WalkRecords(self t_subj n_exec)
        )
        foreach(l_m l_recs
            l_res = tconc(l_res _MkMatch(self t_subj car(l_m) car(cdr(l_m))
                cdr(cdr(l_m)) self->_data->span n_exec))
        )
        car(l_res)
    )
)

self->findall = lambda((t_subj \@key execOpts "tg")  ; -> list
    ; 返回全部匹配的结果列表（同函数 ycRegEx::Findall，与 finditer 同源内核派生）。
    ;
    ; **参数**
    ;   t_subj     (str)         - 主题串
    ;   ?execOpts  (sym|list|nil) - 执行选项符号或列表（默认 nil）
    ;
    ; **返回**
    ;   (list) - 0 组整体串列表 / 1 组扁平组值列表 / ≥2 组每匹配一个子列表
    let((l_res l_recs n_exec l_m)
        n_exec = _ExecOptsBits(execOpts "ycRegEx::Pattern->findall")
        l_recs = _ExportRecords(self t_subj n_exec)
        when(l_recs == 'fallback
            l_recs = _ZeroWidthRecords(self t_subj n_exec)
        )
        when(l_recs == 'fallback
            l_recs = _WalkRecords(self t_subj n_exec)
        )
        foreach(l_m l_recs
            l_res = tconc(l_res _FindAllItem(self t_subj l_m))
        )
        car(l_res)
    )
)

self->partialp = lambda((t_subj \@key execOpts "tg")  ; -> t | nil
    ; 判断主题串是否为部分匹配或完整匹配（同函数 ycRegEx::Partialp）。
    ;
    ; **参数**
    ;   t_subj     (str)         - 主题串
    ;   ?execOpts  (sym|list|nil) - 执行选项符号或列表（默认 nil）
    ;
    ; **返回**
    ;   (t|nil) - 主题串可完成该模式（含完整匹配）时为 t，否则为 nil
    let((n_exec)
        n_exec = _ExecOptsBits(execOpts "ycRegEx::Pattern->partialp")
            + pcreGenExecOptBits(?partial t)
        pcreMatchp(self->_data->pcre t_subj 0 n_exec)
    )
)

self->split = lambda((t_subj \@key first execOpts "tgg")  ; -> list[str]
    ; 按模式切分主题串（同函数 ycRegEx::Split）。
    ;
    ; **参数**
    ;   t_subj     (str)         - 主题串
    ;   ?first     (t|nil)       - t 时只切首处，nil（默认）切分全部
    ;   ?execOpts  (sym|list|nil) - 执行选项符号或列表（默认 nil）
    ;
    ; **返回**
    ;   (list[str]) - 切分段列表（保留捕获组段）
    let((t_buf n_count n_exec)
        n_exec = _ExecOptsBits(execOpts "ycRegEx::Pattern->split")
        n_count = if(first 1 0)
        t_buf = pcreReplace(self->_data->pcre t_subj _SplitTemplate(self->_data->nGroups) n_count n_exec)
        _SplitBy(t_buf "<YC-S>")
    )
)

self->sub = lambda((t_repl t_subj \@key first execOpts "ttgg")  ; -> str
    ; 替换主题串中的匹配（同函数 ycRegEx::Sub）。
    ;
    ; **参数**
    ;   t_repl     (str)         - 替换模板（引擎方言，展开 \1、&、\0）
    ;   t_subj     (str)         - 主题串
    ;   ?first     (t|nil)       - t 时只替换首处，nil（默认）替换全部
    ;   ?execOpts  (sym|list|nil) - 执行选项符号或列表（默认 nil）
    ;
    ; **返回**
    ;   (str) - 替换后的串
    let((n_count n_exec)
        n_exec = _ExecOptsBits(execOpts "ycRegEx::Pattern->sub")
        n_count = if(first 1 0)
        pcreReplace(self->_data->pcre t_subj t_repl n_count n_exec)
    )
)
self->subn = lambda((t_repl t_subj \@key first execOpts "ttgg")  ; -> (str, int)
    ; 同 sub，另返回实际替换次数（同函数 ycRegEx::Subn）。
    ;
    ; **参数**
    ;   t_repl     (str)         - 替换模板（引擎方言）
    ;   t_subj     (str)         - 主题串
    ;   ?first     (t|nil)       - t 时只替换首处，nil（默认）替换全部
    ;   ?execOpts  (sym|list|nil) - 执行选项符号或列表（默认 nil）
    ;
    ; **返回**
    ;   (str, int) - (替换后的串, 实际替换次数)
    let((t_buf n_c n_count n_exec)
        n_exec = _ExecOptsBits(execOpts "ycRegEx::Pattern->subn")
        n_count = if(first 1 0)
        t_buf = pcreReplace(self->_data->pcre t_subj strcat("<YC-N>" t_repl) n_count n_exec)
        n_c = _CountSub(t_buf "<YC-N>")
        list(_FoldCat(_SplitBy(t_buf "<YC-N>")) n_c)
    )
)

self->groups = lambda(()  ; -> int
    ; 返回编译模式的捕获组数（注意与 Matched.groups() 返回组值列表不同）。
    ;
    ; **返回**
    ;   (int) - 捕获组数（不设自设上限）
    self->_data->nGroups
)

self->pattern = lambda(()  ; -> str
    ; 返回编译时的原始模式字符串（不含 flags 修饰）。
    ;
    ; **返回**
    ;   (str) - 原 pattern 串；flags 单独存于 _data->flags
    self->_data->pattern
)

))


inScheme(
defmethod(initializeInstance (self(Pattern) \@rest _args)
    ; 构造 Pattern 实例时调用 _InstallPattern 安装全部方法集。
    ;
    ; **参数**
    ;   _args  (list) - 变参：附加初始化参数，本实现忽略
    ;
    ; **返回**
    ;   (t) - 安装完成后返回 t
    _InstallPattern(self)
    t
)
)

unuseNamespace("ycRegEx")

; END
