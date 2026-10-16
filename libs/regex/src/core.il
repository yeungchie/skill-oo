useNamespace("ycRegEx")


; ---------- string/list helper ----------

procedure(_suffix(t_str n_pos "tn")  ; -> str
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

procedure(_prefix(t_str n_len "tn")  ; -> str
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

procedure(_nth1(l_list n_i "ln")  ; -> any | nil
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

procedure(_digitAt(n_k "n")  ; -> str
    ; 返回 "123456789" 中第 n_k 个字符（拼接捕获组反向引用用）。
    ;
    ; **参数**
    ;   n_k  (int) - 序号，调用方保证 1..9（编译期已限捕获组 ≤ 9）
    ;
    ; **返回**
    ;   (str) - 对应的数字字符
    substring("123456789" n_k 1)
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

procedure(_compileChecked(t_str "t")  ; -> compiled | nil
    ; 编译 PCRE 串，用 errset 捕获错误并抑制输出。
    ;
    ; **参数**
    ;   t_str  (str) - 待编译的正则串
    ;
    ; **返回**
    ;   (compiled|nil) - 编译成功返回对象；失败返回 nil（错误不外抛、不打印）
    let((l_res)
        l_res = errset(pcreCompile(t_str) nil)
        when(l_res
            car(l_res)
        )
    )
)

procedure(_mkPattern(g_pat t_flags t_ctx "gtt")  ; -> Pattern
    ; 按模式串构造 Pattern：一次生成忠实（不加锚）、span（\A(?:…)）、full（\A(?:…)\z）三个编译对象。
    ;
    ; **参数**
    ;   g_pat    (any) - 模式串（期望 string）
    ;   t_flags  (str) - 内联 flags 串（如 "(?i)"，无 flags 为 ""）
    ;   t_ctx    (str) - 出错上下文名（拼入错误消息）
    ;
    ; **返回**
    ;   (Pattern) - 非串模式、编译失败或捕获组数 > 9 时 error() 中断，否则返回新实例
    let((g_faithful g_span g_full n_g)
        unless(stringp(g_pat)
            error("%A: pattern must be a string, got %A" t_ctx g_pat)
        )
        g_faithful = _compileChecked(strcat(t_flags g_pat))
        g_span = _compileChecked(lsprintf("%s\\A(?:%s)" t_flags g_pat))
        g_full = _compileChecked(lsprintf("%s\\A(?:%s)\\z" t_flags g_pat))
        unless(g_faithful && g_span && g_full
            error("%A: invalid pattern: %s" t_ctx g_pat)
        )
        n_g = pcreSubpatCount(g_faithful)
        when(n_g > 9
            error("%A: too many capture groups (%d), max 9" t_ctx n_g)
        )
        makeInstance('Pattern ?_data makeInstance('PatternData
            ?pattern g_pat ?flags t_flags ?pcre g_faithful
            ?span g_span ?full g_full ?nGroups n_g))
    )
)

procedure(_asPat(g_pat t_flags t_ctx "gtt")  ; -> Pattern
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
        _mkPattern(g_pat t_flags t_ctx)
        let((l_pat)
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
    ; 返回 Pattern 的打印描述串，形如 <ycRegEx::Pattern "\d+">。
    ;
    ; **返回**
    ;   (str) - lsprintf 按 <类名 "pattern"> 模板生成
    lsprintf("<%A \"%s\">" className(self) self->_data->pattern)
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


; ---------- module-level free functions (Python re skin) ----------

procedure(reCompile(g_pat \@key flags "gg")  ; -> Pattern
    ; 编译模式串并返回可复用的 Pattern（双表皮 API 的编译入口）。
    ;
    ; **参数**
    ;   g_pat   (str|Pattern) - 模式串（源串反斜杠按 2 写，如 "\\d+"）或已编译 Pattern；
    ;                           传 Pattern 时直接复用、原样返回该实例（不再重编译），此时不能带 flags
    ;   ?flags  (sym|str|nil) - 修饰标志 'I 'M 'S 'X（大小写皆可，默认 nil 不修饰）
    ;
    ; **返回**
    ;   (Pattern) - 编译失败、非法 pattern、捕获组数 > 9、类型非法，或 Pattern 与 flags 同用时 error() 中断
    _asPat(g_pat _flagsFromValue(flags "ycRegEx::reCompile") "ycRegEx::reCompile")
)

procedure(reMatch(g_pat t_subj \@key flags "gtg")  ; -> Match | nil
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
        p = _asPat(g_pat _flagsFromValue(flags "ycRegEx::reMatch") "ycRegEx::reMatch")
        p->match(t_subj)
    )
)

procedure(reSearch(g_pat t_subj \@key flags "gtg")  ; -> Match | nil
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
        p = _asPat(g_pat _flagsFromValue(flags "ycRegEx::reSearch") "ycRegEx::reSearch")
        p->search(t_subj)
    )
)

procedure(reFullmatch(g_pat t_subj \@key flags "gtg")  ; -> Match | nil
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
        p = _asPat(g_pat _flagsFromValue(flags "ycRegEx::reFullmatch") "ycRegEx::reFullmatch")
        p->fullmatch(t_subj)
    )
)

procedure(reFindall(g_pat t_subj \@key flags "gtg")  ; -> list
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
        p = _asPat(g_pat _flagsFromValue(flags "ycRegEx::reFindall") "ycRegEx::reFindall")
        p->findall(t_subj)
    )
)

procedure(reFinditer(g_pat t_subj \@key flags "gtg")  ; -> list[Match]
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
        p = _asPat(g_pat _flagsFromValue(flags "ycRegEx::reFinditer") "ycRegEx::reFinditer")
        p->finditer(t_subj)
    )
)

procedure(reSplit(g_pat t_subj \@key flags all "gtgg")  ; -> list[str]
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
        p = _asPat(g_pat _flagsFromValue(flags "ycRegEx::reSplit") "ycRegEx::reSplit")
        p->split(t_subj ?all all)
    )
)

procedure(reSub(g_pat t_repl t_subj \@key flags all "gttgg")  ; -> str
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
        p = _asPat(g_pat _flagsFromValue(flags "ycRegEx::reSub") "ycRegEx::reSub")
        p->sub(t_repl t_subj ?all all)
    )
)

procedure(reSubn(g_pat t_repl t_subj \@key flags all "gttgg")  ; -> (str, int)
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
        p = _asPat(g_pat _flagsFromValue(flags "ycRegEx::reSubn") "ycRegEx::reSubn")
        p->subn(t_repl t_subj ?all all)
    )
)

unuseNamespace("ycRegEx")

; END
