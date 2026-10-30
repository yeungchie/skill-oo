useNamespace("ycPathLib")


procedure(_CollapseStars(l_segs "l")  ; -> list[str] | nil
    ; 折叠路径 pattern 段列表中连续重复的 "**"，每段连续游程只保留第一个。
    ;
    ; **参数**
    ;   l_segs  (list) - 路径 pattern 段列表（元素为 str）
    ;
    ; **返回**
    ;   (list[str]|nil) - 折叠后的段列表；空入参返回 nil
    let((l_res t_prev)
        foreach(t_s l_segs
            unless(t_s == "**" && t_prev == "**"
                l_res = tconc(l_res t_s)
                t_prev = t_s
            )
        )
        car(l_res)
    )
)

procedure(_GlobDirs(g_dir "g")  ; -> list[Path]
    ; 递归收集目录树的真实目录：起点自身加全部真实子目录。
    ;
    ; **参数**
    ;   g_dir  (Path) - 起点目录
    ;
    ; **返回**
    ;   (list[Path]) - g_dir 自身及全部真实子目录（深度递归）；符号链接目录不进入也不列出
    let((l_res)
        l_res = list(g_dir)
        foreach(t_s _DirNames(g_dir->str())
            let((p_sub)
                p_sub = g_dir->join(t_s)
                when(p_sub->isDir() && !p_sub->isSymlink()
                    l_res = append(l_res _GlobDirs(p_sub))
                )
            )
        )
        l_res
    )
)

procedure(_GlobTree(g_dir "g")  ; -> list[Path]
    ; 递归收集目录树的全部条目：起点自身加每个子项。
    ;
    ; **参数**
    ;   g_dir  (Path) - 起点目录
    ;
    ; **返回**
    ;   (list[Path]) - g_dir 自身与全部条目；真实目录递归进入，符号链接目录只产出条目不进入
    let((l_res)
        l_res = list(g_dir)
        foreach(t_s _DirNames(g_dir->str())
            let((p_sub)
                p_sub = g_dir->join(t_s)
                if(p_sub->isDir() && !p_sub->isSymlink()
                    l_res = append(l_res _GlobTree(p_sub))
                    l_res = append(l_res list(p_sub))
                )
            )
        )
        l_res
    )
)

procedure(_GlobChain(g_dir l_segs "gl")  ; -> list[Path] | nil
    ; 按 pattern 段逐级递归匹配，返回符合剩余 pattern 段的路径列表。
    ;
    ; **参数**
    ;   g_dir   (Path) - 当前所在目录
    ;   l_segs  (list) - 剩余 pattern 段："" 锚定当前目录，".." 字面拼接，"**" 递归展开，其余段按通配符匹配条目名
    ;
    ; **返回**
    ;   (list[Path]|nil) - 匹配路径列表（终端段产出匹配条目；终端 "**" 与 "" 锚点另含 g_dir 自身；
    ;                      非终端段仅沿目录递归）；无匹配返回 nil
    let((t_first l_rest l_res)
        t_first = car(l_segs)
        l_rest = cdr(l_segs)
        case(t_first
            ((nil "")
                l_res = list(g_dir)
            )
            (".."
                l_res = _GlobChain(g_dir->join("..") l_rest)
            )
            ("**"
                if(l_rest == nil
                    l_res = _GlobTree(g_dir)
                    foreach(p_sp _GlobDirs(g_dir)
                        l_res = append(l_res _GlobChain(p_sp l_rest))
                    )
                )
            )
            (t
                foreach(t_s _DirNames(g_dir->str())
                    when(_Fnmatch1(t_s t_first)
                        let((p_child)
                            p_child = g_dir->join(t_s)
                            if(l_rest == nil
                                l_res = cons(p_child l_res)
                                when(p_child->isDir()
                                    l_res = append(l_res _GlobChain(p_child l_rest))
                                )
                            )
                        )
                    )
                )
            )
        )
        l_res
    )
)

procedure(_GlobPattern(g_base t_pattern "gt")  ; -> list[Path] | nil
    ; 以 g_base 为起点执行 glob pattern：校验、解析、遍历并去重。
    ;
    ; **参数**
    ;   g_base     (Path) - 匹配起点目录
    ;   t_pattern  (str)  - 相对 pattern；尾部 "/" 要求匹配项为目录
    ;
    ; **返回**
    ;   (list[Path]|nil) - 按字符串去重的匹配列表（顺序未定义）；g_base 非目录或无匹配返回 nil；绝对 pattern 抛
    ;                      "ycPathLib::_GlobPattern: non-relative patterns are unsupported"；解析后无有效段（如 ""、"."）抛 "ycPathLib::_GlobPattern: unacceptable pattern"
    let((l_parse l_segs)
        when(pcreMatchp("^/" t_pattern)
            error("ycPathLib::_GlobPattern: non-relative patterns are unsupported")
        )
        l_parse = _ParsePath(t_pattern)
        l_segs = cdr(l_parse)
        when(l_segs == nil
            error("ycPathLib::_GlobPattern: unacceptable pattern: '%s'" t_pattern)
        )
        when(_EndsWith(t_pattern "/")
            l_segs = append(l_segs list(""))
        )
        l_segs = _CollapseStars(l_segs)
        when(g_base->isDir()
            let((l_res g_seen)
                g_seen = makeTable("globSeen" nil)
                foreach(p _GlobChain(g_base l_segs)
                    unless(g_seen[p->str()]
                        g_seen[p->str()] = t
                        l_res = tconc(l_res p)
                    )
                )
                car(l_res)
            )
        )
    )
)

inScheme(
procedure(_InstallGlob(self "g")  ; -> any
    ; 把 glob 方法安装到 Path 类（由 initializeInstance 调用）。
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

self->iterdir = lambda(()  ; -> list[Path] | nil
    ; 列出直接子项的 Path 列表（不含 "."/".."）。
    ;
    ; **返回**
    ;   (list[Path]|nil) - 空目录返回 nil；非目录走 _error() 中断；含点开头名与子目录，顺序未定义
    let((t_str)
        t_str = self->str()
        unless(self->isDir()
            _error("iterdir" "not a directory: '%s'" t_str)
        )
        mapcar(lambda((t_s "t") self->join(t_s))
            _DirNames(t_str)
        )
    )
)

self->glob = lambda((t_pattern "t")  ; -> list[Path] | nil
    ; 按 pattern 匹配后代条目，返回 Path 列表（分段 fnmatch，整段 "**" 递归，终端 "**" 产出起点自身）。
    ;
    ; **参数**
    ;   t_pattern  (str) - 相对 pattern（"*" "?" 与字符类，段不跨部件；点开头名不特殊）
    ;
    ; **返回**
    ;   (list[Path]|nil) - 去重后的匹配列表（顺序未定义）；起点非目录或无匹配返回 nil；绝对 pattern 或无有效段 pattern error() 中断
    _GlobPattern(self t_pattern)
)

self->rglob = lambda((t_pattern "t")  ; -> list[Path] | nil
    ; 递归匹配，等价于 glob("**/" + t_pattern)。
    ;
    ; **参数**
    ;   t_pattern  (str) - 相对 pattern，可为空（空时等价 glob("**/")）
    ;
    ; **返回**
    ;   (list[Path]|nil) - 同 glob；绝对 pattern 在拼接 "**/" 之前检查并 error() 中断
    when(pcreMatchp("^/" t_pattern)
        _error("rglob" "non-relative patterns are unsupported")
    )
    _GlobPattern(self strcat("**/" t_pattern))
)

))


unuseNamespace("ycPathLib")

; END
