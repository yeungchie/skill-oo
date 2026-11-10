useNamespace("ycPathLib")


; ---------- 纯路径方法安装 ----------

inScheme(
procedure(_InstallPure(self "g")  ; -> any
    ; 把纯路径方法安装到 Path 类（由 initializeInstance 调用）。
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
    let((name2 idx)
        name2 = self->name()
        idx = _DotIndex(name2)
        if(idx && idx > 1 && idx < length(name2)
            substring(name2 idx)
            ""
        )
    )
)

self->stem = lambda(()  ; -> str
    ; 返回去掉最后一个后缀的名称。
    ;
    ; **返回**
    ;   (str) - 有后缀时返回后缀之前的部分；无有效后缀时返回整个名称
    let((name2 idx)
        name2 = self->name()
        idx = _DotIndex(name2)
        if(idx && idx > 1 && idx < length(name2)
            substring(name2 1 idx - 1)
            name2
        )
    )
)

self->suffixes = lambda(()  ; -> list[str]
    ; 返回名称中首个 "." 之后的全部后缀。
    ;
    ; **返回**
    ;   (list[str]|nil) - 如 (".tar" ".gz")；无后缀返回 nil（"foo."、".bashrc"、
    ;                     "x.y." 均是）；"a..b" 返回 ("." ".b")
    let((name2)
        name2 = self->name()
        unless(name2 == "" || _EndsWith(name2 ".")
            mapcar(lambda((t_s "t") strcat("." t_s))
                cdr(_SplitKeep(_LstripDots(name2) "."))
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
    let((res parts2)
        parts2 = self->_data->parts
        while(parts2
            parts2 = _DropLast(parts2)
            res = tconc(res _MkPath(self->_data->anchor parts2))
        )
        car(res)
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

self->join = lambda((\@rest l_args "g")  ; -> Path
    ; 逐段拼接路径：绝对段丢弃此前拼接，"." 丢弃，".." 保留不折叠。
    ;
    ; **参数**
    ;   l_args  (list) - 变参：每段 string 或 Path（取 str() 再解析），其他类型走 _error() 中断
    ;
    ; **返回**
    ;   (Path) - 拼接结果（按规范串驻留）；零段返回按驻留规则复用的等价实例
    let((anchor2 parts2 parse p_seg)
        anchor2 = self->_data->anchor
        parts2 = self->_data->parts
        foreach(seg l_args
            p_seg = _AsPath(seg)
            unless(p_seg
                _error("join" "expected string or Path, got %A" seg)
            )
            parse = _ParsePath(p_seg->str())
            when(car(parse) == "/"
                anchor2 = "/"
                parts2 = cdr(parse)
            )
            unless(car(parse) == "/"
                parts2 = append(parts2 cdr(parse))
            )
        )
        _MkPath(anchor2 parts2)
    )
)

self->isRelativeTo = lambda((g_other "g")  ; -> t | nil
    ; 判断本路径是否等于 g_other 或位于其之下（relativeTo 的布尔版）。
    ;
    ; **参数**
    ;   g_other  (any) - 前缀路径，string 或 Path；其他类型走 _error() 中断
    ;
    ; **返回**
    ;   (t|nil) - 相等或前缀匹配返回 t，不匹配返回 nil（不匹配不报错）
    let((p_o)
        p_o = _AsPath(g_other)
        unless(p_o
            _error("isRelativeTo" "expected string or Path, got %A" g_other)
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
    ;   g_other  (any) - 前缀路径，string 或 Path；其他类型走 _error() 中断
    ;
    ; **返回**
    ;   (Path) - 相等时为 "."；前缀不匹配（含绝对/相对混用）走 _error() 中断
    let((p_o)
        p_o = _AsPath(g_other)
        unless(p_o
            _error("relativeTo" "expected string or Path, got %A" g_other)
        )
        unless(self->isRelativeTo(p_o)
            _error("relativeTo" "'%s' is not in the subpath of '%s'"
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
    ;            （"."、"/"），均走 _error() 中断
    let((old)
        old = self->name()
        when(old == ""
            _error("withName" "%s has an empty name" self->str())
        )
        unless(t_name != "" && index(t_name "/") == nil && t_name != "."
            _error("withName" "Invalid name '%s'" t_name)
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
    ;            含 "/"，均走 _error() 中断
    let((name2 newName)
        name2 = self->name()
        when(name2 == ""
            _error("withSuffix" "%s has an empty name" self->str())
        )
        unless(t_suffix == ""
            unless(substring(t_suffix 1 1) == "." && t_suffix != "." && index(t_suffix "/") == nil
                _error("withSuffix" "Invalid suffix '%s'" t_suffix)
            )
        )
        newName = strcat(self->stem() t_suffix)
        when(newName == "" || index(newName "/") != nil || newName == "."
            _error("withSuffix" "Invalid name '%s'" newName)
        )
        self->withName(newName)
    )
)

self->match = lambda((t_pattern "t")  ; -> t | nil
    ; 按部件做 fnmatch 式匹配：绝对 pattern 要求锚相等并整路径比较，相对 pattern 右对齐到部件边界；
    ; 整段 "**" 为单部件通配且允许匹配空部件（仅根路径例外，"/" 可与 "**" 对齐），不表示递归。
    ;
    ; **参数**
    ;   t_pattern  (str) - 匹配模式："*" "?"、"[seq]"/"[!seq]" 与整段 "**"（单部件，可匹配空），段不跨部件，大小写敏感
    ;
    ; **返回**
    ;   (t|nil) - 以 "/" 开头要求锚相等并整路径部件比较（root-only 路径例外，
    ;             "/" 可与 "**" 对齐），否则右对齐到部件边界比较；匹配返回 t、不匹配返回 nil；
    ;             pattern 相对（锚为空）且解析后无部件（"."、""）时走 _error() 中断（"/" 有锚不触发）
    let((parse anchor2 parts2 ok)
        parse = _ParsePath(t_pattern)
        anchor2 = car(parse)
        parts2 = cdr(parse)
        when(anchor2 == "" && parts2 == nil
            _error("match" "empty pattern")
        )
        if(anchor2 == "/"
            when(self->_data->anchor == anchor2
                ok = if(length(self->_data->parts) == length(parts2)
                    _AllMatchp(self->_data->parts parts2)
                    when(self->_data->parts == nil && length(parts2) == 1
                        _CanMatchEmpty(car(parts2))
                    )
                )
            )
            let((path)
                path = self->_data->parts
                when(self->_data->anchor == "/"
                    path = cons("" path)
                )
                when(path == nil
                    path = list("")
                )
                ok = _SuffixMatchp(path parts2)
            )
        )
        ok
    )
)

self->expandUser = lambda((\@key checkExists "g")  ; -> Path
    ; 展开首部件的 "~" 或 "~user"（当前用户或指定用户的主目录），其余形式原样返回。
    ; 只做路径处理：默认不检查展开结果是否存在，也不输出用户库查询提示。
    ;
    ; **参数**
    ;   ?checkExists  (t|nil) - 校验展开结果存在，缺失走 _error() 中断（默认 nil）
    ;
    ; **返回**
    ;   (Path) - "~" 与 "~/..." 展开为当前用户 HOME；"~user" 与 "~user/..." 展开为该用户主目录，
    ;            用户不在用户库时按当前 HOME 的父目录推导；绝对路径、"." 及普通路径返回自身；
    ;            HOME 未设置或为空串、且目标是未知用户时，走 _error() 中断
    let((first)
        first = self->_data->parts && car(self->_data->parts)
        cond(
            (self->isAbsolute() || self->_data->parts == nil
                self
            )
            (first == "~"
                let((home rest result)
                    home = getShellEnvVar("HOME")
                    when(home == nil || home == ""
                        _error("expandUser" "home directory is not known")
                    )
                    rest = cdr(self->_data->parts)
                    result = if(rest == nil
                        Path(home)
                        Path(lsprintf("%s/%s" home buildString(rest "/")))
                    )
                    when(checkExists
                        unless(result->exists()
                            _error("expandUser" "expanded path does not exist: %s"
                                result->str())
                        )
                    )
                    result
                )
            )
            (first && substring(first 1 1) == "~"
                let((userName userHome home rest result)
                    userName = substring(first 2)
                    ; 用户库查不到时 simplifyFilename 会报错并带一条提示，这里一并屏蔽，
                    ; 保持「只处理路径、默认不检查」的语义。
                    userHome = car(muffleWarnings(errset(simplifyFilename(first) nil)))
                    when(userHome == nil || userHome == ""
                        home = getShellEnvVar("HOME")
                        when(home == nil || home == ""
                            _error("expandUser" "home directory of user '%s' is not known"
                                userName)
                        )
                        userHome = Path(home)->parent()->join(userName)->str()
                    )
                    rest = cdr(self->_data->parts)
                    result = if(rest == nil
                        Path(userHome)
                        Path(lsprintf("%s/%s" userHome buildString(rest "/")))
                    )
                    when(checkExists
                        unless(result->exists()
                            _error("expandUser" "expanded path does not exist: %s"
                                result->str())
                        )
                    )
                    result
                )
            )
            (t
                self
            )
        )
    )
)

self->expandVars = lambda((\@key (undefined 'error) "s")  ; -> Path
    ; 展开路径串中的环境变量引用：$NAME 与 ${NAME}，其余形式原样保留。
    ; 单次扫描、不递归；默认遇到未定义变量以 _error() 中断。
    ;
    ; **参数**
    ;   ?undefined  (sym) - 未定义变量处理：'error（默认）/ 'keep 保留引用 / 'empty 置空
    ;
    ; **返回**
    ;   (Path) - 展开后的路径；未定义变量按 ?undefined 处理，非法取值走 _error() 中断
    let((str n i ch name value end braced out nameStart nameChars)
        case(undefined
            ((error keep empty)
                nil
            )
            (t
                _error("expandVars" "invalid ?undefined %A (expected 'error, 'keep or 'empty)"
                    undefined)
            )
        )
        nameStart = "_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
        nameChars = "_0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
        str = self->str()
        n = length(str)
        i = 1
        while(i <= n
            ch = substring(str i 1)
            name = nil
            end = nil
            braced = nil
            when(ch == "$"
                let((j nm)
                    j = i + 1
                    when(j <= n && substring(str j 1) == "{"
                        braced = t
                        j++
                    )
                    when(j <= n && index(nameStart substring(str j 1))
                        nm = ""
                        while(j <= n && index(nameChars substring(str j 1))
                            nm = strcat(nm substring(str j 1))
                            j++
                        )
                        if(braced
                            then
                            when(j <= n && substring(str j 1) == "}"
                                name = nm
                                end = j + 1
                            )
                            else
                            name = nm
                            end = j
                        )
                    )
                )
            )
            if(name
                then
                value = getShellEnvVar(name)
                if(value == nil
                    then
                    case(undefined
                        (keep
                            out = tconc(out if(braced
                                strcat("${" name "}")
                                strcat("$" name)))
                        )
                        (empty
                            nil
                        )
                        (t
                            _error("expandVars" "undefined environment variable: %s" name)
                        )
                    )
                    else
                    out = tconc(out value)
                )
                i = end
                else
                out = tconc(out substring(str i 1))
                i++
            )
        )
        Path(if(out apply('strcat car(out)) ""))
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
