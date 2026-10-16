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
