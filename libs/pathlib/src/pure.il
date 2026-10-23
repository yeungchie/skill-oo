useNamespace("ycPathLib")


; ---------- 纯路径方法安装 ----------

inScheme(
procedure(_InstallPure(self "g")  ; -> any
    ; 把纯路径方法安装到 Path 类（由 initializeInstance 调用）。
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

self->str = lambda(()  ; -> str
    ; 返回路径的规范化字符串形式。
    ;
    ; **返回**
    ;   (str) - 与驻留表键同式：锚与部件按 / 拼接；空路径为 "."，根为 "/"
    _PathKey(self->_data->anchor self->_data->parts)
)

self->name = lambda(()  ; -> str
    ; 返回最后一个路径部件。
    ;
    ; **返回**
    ;   (str) - 最后一个部件；"."、"/" 等无名路径返回 ""
    _LastItem(self->_data->parts)
)

self->suffix = lambda(()  ; -> str
    ; 返回名称的最后一个后缀（自名称中最后一个 "." 起）。
    ;
    ; **返回**
    ;   (str) - 最后一个 "." 既非首字符也非末字符时返回自该点起的后缀，否则返回 ""；
    ;           如 ".bashrc"（最后一个 "." 即首字符）返回 ""，"..foo"（最后一个 "." 在位置 2）返回 ".foo"
    let((t_name n_idx)
        t_name = self->name()
        n_idx = _DotIndex(t_name)
        if(n_idx && n_idx > 1 && n_idx < length(t_name)
            substring(t_name n_idx)
            ""
        )
    )
)

self->stem = lambda(()  ; -> str
    ; 返回去掉最后一个后缀的名称。
    ;
    ; **返回**
    ;   (str) - 有后缀时返回后缀之前的部分；无有效后缀时返回整个名称
    let((t_name n_idx)
        t_name = self->name()
        n_idx = _DotIndex(t_name)
        if(n_idx && n_idx > 1 && n_idx < length(t_name)
            substring(t_name 1 n_idx - 1)
            t_name
        )
    )
)

self->suffixes = lambda(()  ; -> list[str]
    ; 返回名称中首个 "." 之后的全部后缀。
    ;
    ; **返回**
    ;   (list[str]|nil) - 如 (".tar" ".gz")；无后缀返回 nil（"foo."、".bashrc"、
    ;                     "x.y." 均是）；"a..b" 返回 ("." ".b")
    let((t_name)
        t_name = self->name()
        unless(t_name == "" || _EndsWith(t_name ".")
            mapcar(lambda((t_s "t") strcat("." t_s))
                cdr(_SplitKeep(_LstripDots(t_name) "."))
            )
        )
    )
)

self->parent = lambda(()  ; -> Path
    ; 返回上级目录。
    ;
    ; **返回**
    ;   (Path) - 去掉最后一个部件；单部件相对路径与 "." 返回 "."，根返回自身
    if(self->_data->parts == nil
        self
        _MkPath(self->_data->anchor _DropLast(self->_data->parts))
    )
)

self->parents = lambda(()  ; -> list[Path]
    ; 返回自上级起直至根的全部祖先（不含自身），由近及远。
    ;
    ; **返回**
    ;   (list[Path]|nil) - 如 ("a/b" "a" ".")；"." 与根返回 nil
    let((l_res l_parts)
        l_parts = self->_data->parts
        while(l_parts
            l_parts = _DropLast(l_parts)
            l_res = tconc(l_res _MkPath(self->_data->anchor l_parts))
        )
        car(l_res)
    )
)

self->parts = lambda(()  ; -> list[str]
    ; 返回按 / 拆分的部件列表。
    ;
    ; **返回**
    ;   (list[str]|nil) - 绝对路径首元素为 "/"；"." 与空路径返回 nil；".." 保留；
    ;                     新建列表，不与内部 _data->parts 共享
    copy(if(self->_data->anchor == "/"
        cons("/" self->_data->parts)
        self->_data->parts
    ))
)

self->isAbsolute = lambda(()  ; -> t | nil
    ; 判断路径是否为绝对路径（锚非空）。
    ;
    ; **返回**
    ;   (t|nil) - 锚非空（以 / 开头）返回 t，否则返回 nil
    self->_data->anchor != ""
)

self->join = lambda((\@rest g_args "g")  ; -> Path
    ; 逐段拼接路径：绝对段丢弃此前拼接，"." 丢弃，".." 保留不折叠。
    ;
    ; **参数**
    ;   g_args  (list) - 变参：每段 string 或 Path（取 str() 再解析），其他类型走 _Error() 中断
    ;
    ; **返回**
    ;   (Path) - 拼接结果（按规范串驻留）；零段返回按驻留规则复用的等价实例
    let((t_anchor l_parts l_parse p_seg)
        t_anchor = self->_data->anchor
        l_parts = self->_data->parts
        foreach(g_seg g_args
            p_seg = _AsPath(g_seg)
            unless(p_seg
                _Error("join" "expected string or Path, got %A" g_seg)
            )
            l_parse = _ParsePath(p_seg->str())
            when(car(l_parse) == "/"
                t_anchor = "/"
                l_parts = cdr(l_parse)
            )
            unless(car(l_parse) == "/"
                l_parts = append(l_parts cdr(l_parse))
            )
        )
        _MkPath(t_anchor l_parts)
    )
)

self->isRelativeTo = lambda((g_other "g")  ; -> t | nil
    ; 判断本路径是否等于 g_other 或位于其之下（relativeTo 的布尔版）。
    ;
    ; **参数**
    ;   g_other  (any) - 前缀路径，string 或 Path；其他类型走 _Error() 中断
    ;
    ; **返回**
    ;   (t|nil) - 相等或前缀匹配返回 t，不匹配返回 nil（不匹配不报错）
    let((p_o)
        p_o = _AsPath(g_other)
        unless(p_o
            _Error("isRelativeTo" "expected string or Path, got %A" g_other)
        )
        if(self->str() == p_o->str()
            t
            _StrMember(p_o->str()
                mapcar(lambda((p "g") p->str()) self->parents())
            )
        )
    )
)

self->relativeTo = lambda((g_other "g")  ; -> Path
    ; 返回去掉前缀 g_other 后的相对路径。
    ;
    ; **参数**
    ;   g_other  (any) - 前缀路径，string 或 Path；其他类型走 _Error() 中断
    ;
    ; **返回**
    ;   (Path) - 相等时为 "."；前缀不匹配（含绝对/相对混用）走 _Error() 中断
    let((p_o)
        p_o = _AsPath(g_other)
        unless(p_o
            _Error("relativeTo" "expected string or Path, got %A" g_other)
        )
        unless(self->isRelativeTo(p_o)
            _Error("relativeTo" "'%s' is not in the subpath of '%s'"
                self->str()
                p_o->str()
            )
        )
        _MkPath("" _DropFirstN(self->_data->parts length(p_o->_data->parts)))
    )
)

self->withName = lambda((t_name "t")  ; -> Path
    ; 替换最后一个部件，返回新路径。
    ;
    ; **参数**
    ;   t_name  (str) - 新的最后部件
    ;
    ; **返回**
    ;   (Path) - 替换后的路径；新名为空、含 "/"、等于 "."，或 self 无名
    ;            （"."、"/"），均走 _Error() 中断
    let((t_old)
        t_old = self->name()
        when(t_old == ""
            _Error("withName" "%s has an empty name" self->str())
        )
        unless(t_name != "" && index(t_name "/") == nil && t_name != "."
            _Error("withName" "Invalid name '%s'" t_name)
        )
        _MkPath(self->_data->anchor
            append(_DropLast(self->_data->parts) list(t_name))
        )
    )
)

self->withSuffix = lambda((t_suffix "t")  ; -> Path
    ; 替换最后一个后缀：非空则替换/追加，"" 清除后缀。
    ;
    ; **参数**
    ;   t_suffix  (str) - 新后缀（以 "." 开头）或 ""
    ;
    ; **返回**
    ;   (Path) - 替换后的路径；self 无名，或非空且不以 "." 开头、等于 "."、
    ;            含 "/"，均走 _Error() 中断
    let((t_name)
        t_name = self->name()
        when(t_name == ""
            _Error("withSuffix" "%s has an empty name" self->str())
        )
        unless(t_suffix == ""
            unless(substring(t_suffix 1 1) == "." && t_suffix != "." && index(t_suffix "/") == nil
                _Error("withSuffix" "Invalid suffix '%s'" t_suffix)
            )
        )
        self->withName(strcat(self->stem() t_suffix))
    )
)

self->match = lambda((t_pattern "t")  ; -> t | nil
    ; 按 pathlib PurePath.match 语义做 fnmatch 式整路径匹配。
    ;
    ; **参数**
    ;   t_pattern  (str) - 匹配模式："*" "?" 与 "[seq]"/"[!seq]"，段不跨部件，大小写敏感
    ;
    ; **返回**
    ;   (t|nil) - 以 "/" 开头要求锚相等并整路径部件比较（root-only 路径例外，
    ;             "/" 可与 "**" 对齐），否则右对齐到部件边界比较；匹配返回 t、不匹配返回 nil；
    ;             pattern 相对（锚为空）且解析后无部件（"."、""）时走 _Error() 中断（"/" 有锚不触发）
    let((l_parse t_anchor l_parts g_ok)
        l_parse = _ParsePath(t_pattern)
        t_anchor = car(l_parse)
        l_parts = cdr(l_parse)
        when(t_anchor == "" && l_parts == nil
            _Error("match" "empty pattern")
        )
        if(t_anchor == "/"
            when(self->_data->anchor == t_anchor
                g_ok = if(length(self->_data->parts) == length(l_parts)
                    _AllMatchp(self->_data->parts l_parts)
                    when(self->_data->parts == nil && length(l_parts) == 1
                        _CanMatchEmpty(car(l_parts))
                    )
                )
            )
            let((t_path)
                t_path = self->_data->parts
                when(self->_data->anchor == "/"
                    t_path = cons("" t_path)
                )
                when(t_path == nil
                    t_path = list("")
                )
                g_ok = _SuffixMatchp(t_path l_parts)
            )
        )
        g_ok
    )
)

self->expandUser = lambda(()  ; -> Path
    ; 展开首部件的 "~"（用户主目录），其余形式原样返回。
    ;
    ; **返回**
    ;   (Path) - "~" 与 "~/..." 展开为 HOME；绝对路径、"." 及普通路径返回自身；
    ;            "~other" 形式、HOME 未设置或为空串，走 _Error() 中断
    let((t_first)
        t_first = self->_data->parts && car(self->_data->parts)
        cond(
            (self->isAbsolute() || self->_data->parts == nil
                self
            )
            (t_first == "~"
                let((t_home l_rest)
                    t_home = getShellEnvVar("HOME")
                    when(t_home == nil || t_home == ""
                        _Error("expandUser" "home directory is not known")
                    )
                    l_rest = cdr(self->_data->parts)
                    if(l_rest == nil
                        Path(t_home)
                        Path(lsprintf("%s/%s" t_home buildString(l_rest "/")))
                    )
                )
            )
            (t_first && substring(t_first 1 1) == "~"
                _Error("expandUser" "user home directories are not supported: '%s'" t_first)
            )
            (t
                self
            )
        )
    )
)

self->absolute = lambda(()  ; -> Path
    ; 返回绝对化路径（不做规范化）。
    ;
    ; **返回**
    ;   (Path) - 已绝对返回自身；否则基于 getWorkingDir() 拼接
    if(self->isAbsolute()
        self
        Path(getWorkingDir())->join(self)
    )
)

self->resolve = lambda(()  ; -> Path
    ; 返回词法规范化后的绝对路径（不解析符号链接）。
    ;
    ; **返回**
    ;   (Path) - absolute() 后经 simplifyFilename 折叠 "."/".."
    Path(simplifyFilename(self->absolute()->str()))
)

))

unuseNamespace("ycPathLib")

; END
