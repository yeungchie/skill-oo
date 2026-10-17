useNamespace("ycRegEx")


; ---------- class definition ----------

; 数据桶：Pattern 状态（pattern flags pcre span full nGroups）收敛为单一 _data 槽
defclass(PatternData () (
    ; PatternData 数据桶：收纳 Pattern 的 pattern/flags/pcre/span/full/nGroups 状态，构造后禁写。
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
    nGroups(
        \@initarg nGroups
        \@initform 0
    )
))

defclass(Pattern () (
    ; Pattern 实例：reCompile() 返回的已编译模式对象，方法语义同对应函数 ycRegEx::reXxx。
    ; 状态桶（PatternData：pattern flags pcre span full nGroups），构造后禁写
    _data(
        \@initarg _data
        \@initform nil
    )
    match()
    search()
    fullmatch()
    findall()
    finditer()
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
procedure(_installPattern(self "g")  ; -> any
    ; 把 Pattern 方法安装到 Pattern 类（由 initializeInstance 调用）。
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

self->match = lambda((t_subj "t")  ; -> Match | nil
    ; 在主题串开头锚定匹配（同函数 ycRegEx::reMatch，前锚 \A）。
    ;
    ; **参数**
    ;   t_subj  (str) - 主题串
    ;
    ; **返回**
    ;   (Match|nil) - 起始处命中返回 Match（位置构造即知），未命中返回 nil
    when(pcreMatchp(self->_data->span t_subj)
        let((l_parts)
            l_parts = _extractParts(self self->_data->span)
            _mkMatch(self t_subj 0 length(car(l_parts)) cdr(l_parts) self->_data->span)
        )
    )
)

self->search = lambda((t_subj "t")  ; -> Match | nil
    ; 搜索主题串中的首个匹配（同函数 ycRegEx::reSearch，span 惰性）。
    ;
    ; **参数**
    ;   t_subj  (str) - 主题串
    ;
    ; **返回**
    ;   (Match|nil) - 命中返回 Match（位置惰性，首次 span()/start()/end() 走慢路径回填），未命中返回 nil
    when(pcreMatchp(self->_data->pcre t_subj)
        let((l_parts)
            l_parts = _extractParts(self self->_data->pcre)
            _mkMatch(self t_subj nil nil cdr(l_parts) self->_data->span)
        )
    )
)

self->fullmatch = lambda((t_subj "t")  ; -> Match | nil
    ; 整串匹配（同函数 ycRegEx::reFullmatch，经 full 锚 \A(?:…)\z）。
    ;
    ; **参数**
    ;   t_subj  (str) - 主题串
    ;
    ; **返回**
    ;   (Match|nil) - 匹配覆盖整个主题串返回 Match（位置构造即知），否则返回 nil
    when(pcreMatchp(self->_data->full t_subj)
        let((l_parts)
            l_parts = _extractParts(self self->_data->full)
            _mkMatch(self t_subj 0 length(car(l_parts)) cdr(l_parts) self->_data->full)
        )
    )
)

self->finditer = lambda((t_subj "t")  ; -> list[Match]
    ; 返回全部匹配的 Match 列表（同函数 ycRegEx::reFinditer，慢路径内核）。
    ;
    ; **参数**
    ;   t_subj  (str) - 主题串
    ;
    ; **返回**
    ;   (list[Match]) - 全量 Match 列表；逐位置锚定扫描，零宽命中按 start + 1 推进
    let((l_res l_m n_from)
        n_from = 0
        l_m = t
        while(l_m
            l_m = _nextMatch(self t_subj n_from)
            when(l_m
                l_res = tconc(l_res _mkMatch(self t_subj car(l_m) car(cdr(l_m)) cdr(cdr(l_m)) self->_data->span))
                n_from = if(car(cdr(l_m)) > car(l_m)
                    car(cdr(l_m))
                    car(l_m) + 1
                )
            )
        )
        car(l_res)
    )
)

self->findall = lambda((t_subj "t")  ; -> list
    ; 返回全部匹配的结果列表（同函数 ycRegEx::reFindall，与 finditer 同源内核派生）。
    ;
    ; **参数**
    ;   t_subj  (str) - 主题串
    ;
    ; **返回**
    ;   (list) - 0 组整体串列表 / 1 组扁平组值列表 / ≥2 组每匹配一个子列表
    let((l_res l_m n_from)
        n_from = 0
        l_m = t
        while(l_m
            l_m = _nextMatch(self t_subj n_from)
            when(l_m
                l_res = tconc(l_res _findAllItem(self t_subj l_m))
                n_from = if(car(cdr(l_m)) > car(l_m)
                    car(cdr(l_m))
                    car(l_m) + 1
                )
            )
        )
        car(l_res)
    )
)

self->split = lambda((t_subj \@key all "tg")  ; -> list[str]
    ; 按模式切分主题串（同函数 ycRegEx::reSplit）。
    ;
    ; **参数**
    ;   t_subj  (str)   - 主题串
    ;   ?all    (t|nil) - t 时切分全部匹配，nil（默认）只切首处（默认 nil）
    ;
    ; **返回**
    ;   (list[str]) - 切分段列表（保留捕获组段）
    let((t_buf n_count)
        n_count = if(all 0 1)
        t_buf = pcreReplace(self->_data->pcre t_subj _splitTemplate(self->_data->nGroups) n_count)
        _splitBy(t_buf "<YC-S>")
    )
)

self->sub = lambda((t_repl t_subj \@key all "ttg")  ; -> str
    ; 替换主题串中的匹配（同函数 ycRegEx::reSub）。
    ;
    ; **参数**
    ;   t_repl  (str)   - 替换模板（引擎方言，展开 \1、&、\0）
    ;   t_subj  (str)   - 主题串
    ;   ?all    (t|nil) - t 时替换全部匹配，nil 时只替首处，默认值为 nil
    ;
    ; **返回**
    ;   (str) - 替换后的串
    let((n_count)
        n_count = if(all 0 1)
        pcreReplace(self->_data->pcre t_subj t_repl n_count)
    )
)

self->subn = lambda((t_repl t_subj \@key all "ttg")  ; -> (str, int)
    ; 同 sub，另返回实际替换次数（同函数 ycRegEx::reSubn）。
    ;
    ; **参数**
    ;   t_repl  (str)   - 替换模板（引擎方言）
    ;   t_subj  (str)   - 主题串
    ;   ?all    (t|nil) - t 时替换全部匹配，nil（默认）只替首处
    ;
    ; **返回**
    ;   (str, int) - (替换后的串, 实际替换次数)
    let((t_buf n_c n_count)
        n_count = if(all 0 1)
        t_buf = pcreReplace(self->_data->pcre t_subj strcat("<YC-N>" t_repl) n_count)
        n_c = _countSub(t_buf "<YC-N>")
        list(_foldCat(_splitBy(t_buf "<YC-N>")) n_c)
    )
)

self->groups = lambda(()  ; -> int
    ; 返回编译模式的捕获组数（注意与 Match.groups() 返回组值列表不同）。
    ;
    ; **返回**
    ;   (int) - 捕获组数；> 9 在编译阶段（_mkPattern）即 error() 中断
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
    ; 构造 Pattern 实例时调用 _installPattern 安装全部方法集。
    ;
    ; **参数**
    ;   _args  (list) - 变参：附加初始化参数，本实现忽略
    ;
    ; **返回**
    ;   (t) - 安装完成后返回 t
    _installPattern(self)
    t
)
)

unuseNamespace("ycRegEx")

; END
