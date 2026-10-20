useNamespace("ycRegEx")


; ---------- string/list helper ----------

procedure(_suffix(t_str n_pos "tx")  ; -> str
    ; 返回从 n_pos 到串尾的子串（1-based）。
    ;
    ; **参数**
    ;   t_str  (str) - 源串
    ;   n_pos  (int) - 1-based 起始位置
    ;
    ; **返回**
    ;   (str) - n_pos 超出串长返回 ""；n_pos < 2 返回全串
    cond(
        (n_pos > length(t_str) "")
        (n_pos < 2 t_str)
        (t substring(t_str n_pos length(t_str) - n_pos + 1))
    )
)

procedure(_prefix(t_str n_len "tx")  ; -> str
    ; 返回串的前 n_len 个字符（1-based，越界收敛到串边界）。
    ;
    ; **参数**
    ;   t_str  (str) - 源串
    ;   n_len  (int) - 期望的前缀长度
    ;
    ; **返回**
    ;   (str) - n_len < 1 返回 ""；n_len 超过串长返回全串
    cond(
        (n_len < 1 "")
        (n_len > length(t_str) t_str)
        (t substring(t_str 1 n_len))
    )
)

procedure(_splitBy(t_str t_delim "tt")  ; -> list[str]
    ; 按字面分隔串拆分源串，保留空段与原有顺序。
    ;
    ; **参数**
    ;   t_str    (str) - 源串
    ;   t_delim  (str) - 字面分隔串（非正则）
    ;
    ; **返回**
    ;   (list[str]) - 逐段结果，恒含末段；t_delim 为空串时不拆、返回单元素列表 (t_str)
    let((l_res t_cur n_i n_len n_d g_hit)
        t_cur = ""
        n_len = length(t_str)
        n_d = length(t_delim)
        n_i = 1
        while(n_i <= n_len
            g_hit = n_d > 0 && n_d <= n_len - n_i + 1 && substring(t_str n_i n_d) == t_delim
            when(g_hit
                l_res = tconc(l_res t_cur)
                t_cur = ""
            )
            unless(g_hit
                t_cur = strcat(t_cur substring(t_str n_i 1))
            )
            if(g_hit
                n_i = n_i + n_d
                n_i = n_i + 1
            )
        )
        car(tconc(l_res t_cur))
    )
)

procedure(_countSub(t_str t_sub "tt")  ; -> int
    ; 统计子串在源串中的非重叠出现次数。
    ;
    ; **参数**
    ;   t_str  (str) - 源串
    ;   t_sub  (str) - 字面子串（非正则）
    ;
    ; **返回**
    ;   (int) - 非重叠命中次数；t_sub 为空串返回 0
    let((n_c n_i n_len n_d g_hit)
        n_c = 0
        n_len = length(t_str)
        n_d = length(t_sub)
        n_i = 1
        while(n_i <= n_len
            g_hit = n_d > 0 && n_d <= n_len - n_i + 1 && substring(t_str n_i n_d) == t_sub
            when(g_hit
                n_c = n_c + 1
            )
            if(g_hit
                n_i = n_i + n_d
                n_i = n_i + 1
            )
        )
        n_c
    )
)

procedure(_nth1(l_list n_i "lx")  ; -> any | nil
    ; 取列表的第 n_i 个元素（1-based）。
    ;
    ; **参数**
    ;   l_list  (list) - 源列表
    ;   n_i     (int)  - 1-based 序号
    ;
    ; **返回**
    ;   (any|nil) - 序号越界、n_i < 1 或列表为空时返回 nil
    unless(l_list == nil || n_i < 1
        if(n_i == 1
            car(l_list)
            _nth1(cdr(l_list) n_i - 1)
        )
    )
)

procedure(_backref(n_k "x")  ; -> str
    ; 返回引擎两参模板的组反向引用 `\{n}`。
    ;
    ; **参数**
    ;   n_k  (int) - 捕获组序号（≥ 1）
    ;
    ; **返回**
    ;   (str) - 形如 `\{1}`、`\{10}` 的模板片段
    lsprintf("\\{%d}" n_k)
)

procedure(_foldCat(l_list "l")  ; -> str
    ; 依次拼接字符串列表为单个串。
    ;
    ; **参数**
    ;   l_list  (list) - 元素为 str 的列表
    ;
    ; **返回**
    ;   (str) - 按序 strcat 的结果；空列表返回 ""
    let((t_res)
        t_res = ""
        foreach(t_s l_list
            t_res = strcat(t_res t_s)
        )
        t_res
    )
)


; ---------- flags / compile ----------

procedure(_flagsFromValue(g_flags t_ctx "gt")  ; -> str
    ; 把 ?flags 入参归一为 "(?imsx)" 式内联修饰串（仅含出现的标志）。
    ;
    ; **参数**
    ;   g_flags  (sym|str|nil) - 修饰标志：nil 或 "" 不修饰；符号/字符串逐字符拆（大小写不敏感）
    ;   t_ctx    (str)         - 出错上下文名（拼入错误消息）
    ;
    ; **返回**
    ;   (str) - 无修饰返回 ""；否则按 i m s x 固定序去重拼成 "(?imsx)" 式串；
    ;           遇 'g' 走 error() 提示改用 ?all；非符号/字符串或未知字母走 error() 中断
    let((t_s t_letters t_c t_in n_i n_len)
        cond(
            (g_flags == nil
                t_s = ""
            )
            (symbolp(g_flags)
                t_s = symbolToString(g_flags)
            )
            (stringp(g_flags)
                t_s = g_flags
            )
            (t
                error("%A: flags must be a symbol or string, got %A" t_ctx g_flags)
            )
        )
        t_letters = ""
        n_len = length(t_s)
        n_i = 1
        while(n_i <= n_len
            t_c = substring(t_s n_i 1)
            case(t_c
                (("i" "I")
                    t_letters = strcat(t_letters "i")
                )
                (("m" "M")
                    t_letters = strcat(t_letters "m")
                )
                (("s" "S")
                    t_letters = strcat(t_letters "s")
                )
                (("x" "X")
                    t_letters = strcat(t_letters "x")
                )
                (("g" "G")
                    error("%A: flag 'g' is not supported; use ?all t for global matching" t_ctx)
                )
                (t
                    error("%A: unknown flag '%s (use 'I 'M 'S 'X)" t_ctx t_c)
                )
            )
            n_i = n_i + 1
        )
        t_in = ""
        when(index(t_letters "i")
            t_in = strcat(t_in "i")
        )
        when(index(t_letters "m")
            t_in = strcat(t_in "m")
        )
        when(index(t_letters "s")
            t_in = strcat(t_in "s")
        )
        when(index(t_letters "x")
            t_in = strcat(t_in "x")
        )
        if(t_in == ""
            ""
            lsprintf("(?%s)" t_in)
        )
    )
)

procedure(_optsList(g_opts t_ctx "gt")  ; -> list
    ; 把选项参数归一为符号列表。
    ;
    ; **参数**
    ;   g_opts  (sym|list|nil) - 选项符号或符号列表
    ;   t_ctx   (str)          - 出错上下文名（拼入错误消息）
    ;
    ; **返回**
    ;   (list) - 选项符号列表；nil 返回 nil
    cond(
        (g_opts == nil nil)
        (symbolp(g_opts) list(g_opts))
        (listp(g_opts) g_opts)
        (t error("%A: options must be a symbol or list of symbols, got %A" t_ctx g_opts))
    )
)

procedure(_compileOptsBits(g_opts t_ctx "gt")  ; -> int
    ; 把编译选项符号列表转成引擎位值。
    ;
    ; **参数**
    ;   g_opts  (sym|list|nil) - caseLess / multiLine / dotAll / extended / anchored /
    ;                            dollar_endonly / ungreedy / no_auto_capture / firstline
    ;   t_ctx   (str)          - 出错上下文名（拼入错误消息）
    ;
    ; **返回**
    ;   (int) - pcreGenCompileOptBits 的位值；无选项返回 0
    let((l_args)
        foreach(g_opt _optsList(g_opts t_ctx)
            case(g_opt
                (caseLess l_args = append(l_args list('?caseLess t)))
                (multiLine l_args = append(l_args list('?multiLine t)))
                (dotAll l_args = append(l_args list('?dotAll t)))
                (extended l_args = append(l_args list('?extended t)))
                (anchored l_args = append(l_args list('?anchored t)))
                (dollar_endonly l_args = append(l_args list('?dollar_endonly t)))
                (ungreedy l_args = append(l_args list('?ungreedy t)))
                (no_auto_capture l_args = append(l_args list('?no_auto_capture t)))
                (firstline l_args = append(l_args list('?firstline t)))
                (t error("%A: unknown compile option %A" t_ctx g_opt))
            )
        )
        apply('pcreGenCompileOptBits l_args)
    )
)

procedure(_execOptsBits(g_opts t_ctx "gt")  ; -> int
    ; 把执行选项符号列表转成引擎位值。
    ;
    ; **参数**
    ;   g_opts  (sym|list|nil) - anchored / notbol / noteol / notempty
    ;   t_ctx   (str)          - 出错上下文名（拼入错误消息）
    ;
    ; **返回**
    ;   (int) - pcreGenExecOptBits 的位值；无选项返回 0
    let((l_args)
        foreach(g_opt _optsList(g_opts t_ctx)
            case(g_opt
                (anchored l_args = append(l_args list('?anchored t)))
                (notbol l_args = append(l_args list('?notbol t)))
                (noteol l_args = append(l_args list('?noteol t)))
                (notempty l_args = append(l_args list('?notempty t)))
                (t error("%A: unknown execution option %A" t_ctx g_opt))
            )
        )
        apply('pcreGenExecOptBits l_args)
    )
)

procedure(_compileChecked(t_str t_ctx n_opts "ttx")  ; -> compiled
    ; 编译 PCRE 串；原生诊断照常打印，失败统一转成带上下文的 error()。
    ;
    ; **参数**
    ;   t_str  (str) - 待编译的正则串
    ;   t_ctx  (str) - 出错上下文名（拼入错误消息）
    ;
    ; **返回**
    ;   (compiled) - 编译成功返回对象；失败不返回
    let((l_res)
        l_res = errset(pcreCompile(t_str n_opts) t)
        if(l_res && pcreObjectp(car(l_res))
            car(l_res)
            error("%A: pattern compilation failed" t_ctx)
        )
    )
)

procedure(_mkPattern(g_pat t_flags t_ctx n_opts "gttx")  ; -> Pattern
    ; 按模式串构造 Pattern：一次生成忠实（不加锚）、span（\A(?:…)）、full（\A(?:…)\z）三个编译对象。
    ;
    ; **参数**
    ;   g_pat    (any) - 模式串（期望 string）
    ;   t_flags  (str) - 内联 flags 串（如 "(?i)"，无 flags 为 ""）
    ;   t_ctx    (str) - 出错上下文名（拼入错误消息）
    ;   n_opts   (int) - 编译选项位值（0 表示无额外选项）
    ;
    ; **返回**
    ;   (Pattern) - 非串模式或编译失败时 error() 中断，否则返回新实例
    let((g_faithful g_span g_full n_g)
        unless(stringp(g_pat)
            error("%A: pattern must be a string, got %A" t_ctx g_pat)
        )
        g_faithful = _compileChecked(strcat(t_flags g_pat) t_ctx n_opts)
        g_span = _compileChecked(lsprintf("%s\\A(?:%s)" t_flags g_pat) t_ctx n_opts)
        g_full = _compileChecked(lsprintf("%s\\A(?:%s)\\z" t_flags g_pat) t_ctx n_opts)
        n_g = pcreSubpatCount(g_faithful)
        makeInstance('Pattern ?_data makeInstance('PatternData
            ?pattern g_pat ?flags t_flags ?compileOpts n_opts ?pcre g_faithful
            ?span g_span ?full g_full ?nGroups n_g))
    )
)

procedure(_asPat(g_pat t_flags t_ctx n_opts "gttx")  ; -> Pattern
    ; 双表皮入口：模式串现编译，已编译 Pattern 直接复用。
    ;
    ; **参数**
    ;   g_pat    (any) - 模式串或 Pattern，其他类型 error() 中断
    ;   t_flags  (str) - 内联 flags 串；g_pat 为 Pattern 时必须为 ""（带 flags 时 error() 中断）
    ;   t_ctx    (str) - 出错上下文名（拼入错误消息）
    ;
    ; **返回**
    ;   (Pattern) - 字符串走 _mkPattern；Pattern 经 ->pattern() 校验为串后原样返回
    if(stringp(g_pat)
        _mkPattern(g_pat t_flags t_ctx n_opts)
        let((l_pat)
            when(n_opts != 0
                error("%A: cannot pass compile options with a compiled pattern" t_ctx)
            )
            unless(t_flags == ""
                error("%A: cannot pass flags with a compiled pattern" t_ctx)
            )
            l_pat = errset(g_pat->pattern() nil)
            unless(l_pat && stringp(car(l_pat))
                error("%A: expected string pattern or Pattern, got %A" t_ctx g_pat)
            )
            g_pat
        )
    )
)


; ---------- module-level free functions (Python re skin) ----------

procedure(reCompile(g_pat \@key flags compileOpts "gg")  ; -> Pattern
    ; 编译模式串并返回可复用的 Pattern（双表皮 API 的编译入口）。
    ;
    ; **参数**
    ;   g_pat   (str|Pattern) - 模式串（源串反斜杠按 2 写，如 "\\d+"）或已编译 Pattern；
    ;                           传 Pattern 时直接复用、原样返回该实例（不再重编译），此时不能带 flags
    ;   ?flags  (sym|str|nil) - 修饰标志 'I 'M 'S 'X（大小写皆可，默认 nil 不修饰）
    ;   ?compileOpts (sym|list|nil) - 编译选项符号或列表，见 README
    ;
    ; **返回**
    ;   (Pattern) - 编译失败、非法 pattern、类型非法，或 Pattern 与 flags/compileOpts 同用时 error() 中断
    _asPat(g_pat _flagsFromValue(flags "ycRegEx::reCompile") "ycRegEx::reCompile"
        _compileOptsBits(compileOpts "ycRegEx::reCompile"))
)

procedure(reMatch(g_pat t_subj \@key flags execOpts "gtgg")  ; -> Match | nil
    ; 在主题串开头做锚定匹配（语义同 Python re.match，前锚 \A）。
    ;
    ; **参数**
    ;   g_pat   (any)         - 模式串或已编译 Pattern（双表皮）
    ;   t_subj  (str)         - 主题串
    ;   ?flags  (sym|str|nil) - 修饰标志 'I 'M 'S 'X（默认 nil）
    ;
    ; **返回**
    ;   (Match|nil) - 主题串起始处命中返回 Match，未命中返回 nil
    let((p)
        p = _asPat(g_pat _flagsFromValue(flags "ycRegEx::reMatch") "ycRegEx::reMatch" 0)
        p->match(t_subj ?execOpts execOpts)
    )
)

procedure(reSearch(g_pat t_subj \@key flags execOpts "gtgg")  ; -> Match | nil
    ; 在主题串中搜索首个匹配（语义同 Python re.search）。
    ;
    ; **参数**
    ;   g_pat   (any)         - 模式串或已编译 Pattern（双表皮）
    ;   t_subj  (str)         - 主题串
    ;   ?flags  (sym|str|nil) - 修饰标志 'I 'M 'S 'X（默认 nil）
    ;
    ; **返回**
    ;   (Match|nil) - 命中返回 Match（span 惰性），未命中返回 nil
    let((p)
        p = _asPat(g_pat _flagsFromValue(flags "ycRegEx::reSearch") "ycRegEx::reSearch" 0)
        p->search(t_subj ?execOpts execOpts)
    )
)

procedure(reFullmatch(g_pat t_subj \@key flags execOpts "gtgg")  ; -> Match | nil
    ; 整串匹配（语义同 Python re.fullmatch，经 \A(?:…)\z 第三编译对象）。
    ;
    ; **参数**
    ;   g_pat   (any)         - 模式串或已编译 Pattern（双表皮）
    ;   t_subj  (str)         - 主题串
    ;   ?flags  (sym|str|nil) - 修饰标志 'I 'M 'S 'X（默认 nil）
    ;
    ; **返回**
    ;   (Match|nil) - 匹配覆盖整个主题串返回 Match，否则返回 nil
    let((p)
        p = _asPat(g_pat _flagsFromValue(flags "ycRegEx::reFullmatch") "ycRegEx::reFullmatch" 0)
        p->fullmatch(t_subj ?execOpts execOpts)
    )
)

procedure(reFindall(g_pat t_subj \@key flags execOpts "gtgg")  ; -> list
    ; 返回主题串中全部匹配的结果列表（语义同 Python re.findall）。
    ;
    ; **参数**
    ;   g_pat   (any)         - 模式串或已编译 Pattern（双表皮）
    ;   t_subj  (str)         - 主题串
    ;   ?flags  (sym|str|nil) - 修饰标志 'I 'M 'S 'X（默认 nil）
    ;
    ; **返回**
    ;   (list) - 0 组整体串列表 / 1 组扁平组值列表 / ≥2 组每匹配一个子列表
    let((p)
        p = _asPat(g_pat _flagsFromValue(flags "ycRegEx::reFindall") "ycRegEx::reFindall" 0)
        p->findall(t_subj ?execOpts execOpts)
    )
)

procedure(reFinditer(g_pat t_subj \@key flags execOpts "gtgg")  ; -> list[Match]
    ; 返回全部匹配的 Match 列表（语义同 Python re.finditer，全量返回）。
    ;
    ; **参数**
    ;   g_pat   (any)         - 模式串或已编译 Pattern（双表皮）
    ;   t_subj  (str)         - 主题串
    ;   ?flags  (sym|str|nil) - 修饰标志 'I 'M 'S 'X（默认 nil）
    ;
    ; **返回**
    ;   (list[Match]) - 全量 Match 列表；慢路径逐位置扫描
    let((p)
        p = _asPat(g_pat _flagsFromValue(flags "ycRegEx::reFinditer") "ycRegEx::reFinditer" 0)
        p->finditer(t_subj ?execOpts execOpts)
    )
)

procedure(reSplit(g_pat t_subj \@key flags all execOpts "gtggg")  ; -> list[str]
    ; 按模式切分主题串（语义同 Python re.split）。
    ;
    ; **参数**
    ;   g_pat   (any)         - 模式串或已编译 Pattern（双表皮）
    ;   t_subj  (str)         - 主题串
    ;   ?flags  (sym|str|nil) - 修饰标志 'I 'M 'S 'X（默认 nil）
    ;   ?all    (t|nil)       - t 时切分全部匹配，nil（默认）只切首处
    ;
    ; **返回**
    ;   (list[str]) - 切分段列表（保留捕获组段）
    let((p)
        p = _asPat(g_pat _flagsFromValue(flags "ycRegEx::reSplit") "ycRegEx::reSplit" 0)
        p->split(t_subj ?all all ?execOpts execOpts)
    )
)

procedure(reSub(g_pat t_repl t_subj \@key flags all execOpts "gttggg")  ; -> str
    ; 替换主题串中的匹配（语义同 Python re.sub，参数序为 pattern repl subj）。
    ;
    ; **参数**
    ;   g_pat   (any)         - 模式串或已编译 Pattern（双表皮）
    ;   t_repl  (str)         - 替换模板（引擎方言，展开 \1、&、\0）
    ;   t_subj  (str)         - 主题串
    ;   ?flags  (sym|str|nil) - 修饰标志 'I 'M 'S 'X（默认 nil）
    ;   ?all    (t|nil)       - t 时替换全部匹配，nil（默认）只替首处
    ;
    ; **返回**
    ;   (str) - 替换后的串
    let((p)
        p = _asPat(g_pat _flagsFromValue(flags "ycRegEx::reSub") "ycRegEx::reSub" 0)
        p->sub(t_repl t_subj ?all all ?execOpts execOpts)
    )
)

procedure(reSubn(g_pat t_repl t_subj \@key flags all execOpts "gttggg")  ; -> (str, int)
    ; 同 reSub，另返回实际替换次数（语义同 Python re.subn）。
    ;
    ; **参数**
    ;   g_pat   (any)         - 模式串或已编译 Pattern（双表皮）
    ;   t_repl  (str)         - 替换模板（引擎方言，见 README）
    ;   t_subj  (str)         - 主题串
    ;   ?flags  (sym|str|nil) - 修饰标志 'I 'M 'S 'X（默认 nil）
    ;   ?all    (t|nil)       - t 时替换全部匹配，nil（默认）只替首处
    ;
    ; **返回**
    ;   (str, int) - (替换后的串, 实际替换次数)
    let((p)
        p = _asPat(g_pat _flagsFromValue(flags "ycRegEx::reSubn") "ycRegEx::reSubn" 0)
        p->subn(t_repl t_subj ?all all ?execOpts execOpts)
    )
)

procedure(reGetRecursionLimit()  ; -> int
    ; 返回 PCRE 匹配算法的当前最大递归深度（进程级设置）。
    ;
    ; **参数**
    ;   无
    ;
    ; **返回**
    ;   (int) - 当前最大递归深度（默认 10000000）
    pcreGetRecursionLimit()
)

procedure(reSetRecursionLimit(n_limit "x")  ; -> t
    ; 设置 PCRE 匹配算法的最大递归深度（进程级设置）。
    ;
    ; **参数**
    ;   n_limit  (int) - 最大递归深度
    ;
    ; **返回**
    ;   (t) - 设置成功
    pcreSetRecursionLimit(n_limit)
)

unuseNamespace("ycRegEx")

; END
