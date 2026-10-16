useNamespace("ycPathLib")


; ---------- 模块级 helper（不导出） ----------

; 实例驻留表：规范串 → Path（同串共享同一实例，== 为真）。构造后禁止再写
; self->_data 及其字段（别名污染——纪律非语言强制）；绕过本函数直接
; makeInstance 的实例不共享，请走 Path()/_asPath()/_mkPath()。
; 驻留表有界：超过 _PathCacheCap 条整体清空重计（丢共享只弱化 == 快路径，不改正确性）。
_PathCache = makeTable("pathCache" nil)
_PathCacheCap = 8192
_PathCacheN = 0

procedure(_asPath(g_x "g")  ; -> Path | nil
    ; 把任意可字符串化值转换为驻留的 Path 实例。
    ;
    ; **参数**
    ;   g_x  (any) - string 直接解析；其他对象取其 ->str() 结果
    ;
    ; **返回**
    ;   (Path|nil) - 解析结果按规范串驻留返回 Path；g_x 非 string 且 ->str()
    ;                失败或结果非 string 时返回 nil
    let((t_s l_parse)
        if(stringp(g_x)
            t_s = g_x
            t_s = car(errset(g_x->str() nil))
        )
        when(stringp(t_s)
            l_parse = _parsePath(t_s)
            _mkPath(car(l_parse) cdr(l_parse))
        )
    )
)

procedure(_parsePath(t_path "t")  ; -> (str . list[str])
    ; 词法解析路径串为 (锚 . 部件列表)，不访问磁盘。
    ;
    ; **参数**
    ;   t_path  (str) - 路径串
    ;
    ; **返回**
    ;   (str . list[str]) - 点对 (锚 . 部件)：锚为 "/"（以 / 开头）或 ""；
    ;                       部件按 / 拆分并丢弃空部件与 "." 部件，".." 保留
    cons(
        pcreMatchp("^/" t_path) && "/" || ""
        setof(t_s parseString(t_path "/") t_s != "" && t_s != ".")
    )
)

procedure(_pathKey(t_anchor l_parts "tl")  ; -> str
    ; 由锚与部件列表生成路径规范串，用作驻留表键。
    ;
    ; **参数**
    ;   t_anchor  (str)  - 锚，"/" 或 ""
    ;   l_parts   (list) - 部件列表（元素为 str）
    ;
    ; **返回**
    ;   (str) - 与 ->str() 同式：根且无部件为 "/"，空锚且无部件为 "."，
    ;           否则锚与部件按 / 拼接
    cond(
        (l_parts == nil && t_anchor == "/" "/")
        (l_parts == nil ".")
        (t strcat(t_anchor buildString(l_parts "/")))
    )
)

procedure(_mkPath(t_anchor l_parts "tl")  ; -> Path
    ; 按锚与部件从驻留表取（或新建）Path 实例，同规范串共享同一实例。
    ;
    ; **参数**
    ;   t_anchor  (str)  - 锚，"/" 或 ""
    ;   l_parts   (list) - 部件列表（元素为 str）
    ;
    ; **返回**
    ;   (Path) - 按规范串查 _PathCache：命中即复用，未命中新建登记；
    ;            超过 _PathCacheCap 条整表清空重计（丢共享只弱化 == 快路径，不改正确性）
    let((t_key hit)
        t_key = _pathKey(t_anchor l_parts)
        hit = _PathCache[t_key]
        when(hit == nil
            hit = makeInstance('Path ?_data
                makeInstance('PathData ?anchor t_anchor ?parts l_parts))
            _PathCache[t_key] = hit
            _PathCacheN = _PathCacheN + 1
            when(_PathCacheN > _PathCacheCap
                _PathCache = makeTable("pathCache" nil)
                _PathCacheN = 0
            )
        )
        hit
    )
)

procedure(_lastItem(l_parts "l")  ; -> str
    ; 返回列表的最后一个元素。
    ;
    ; **参数**
    ;   l_parts  (list) - 元素列表（str）
    ;
    ; **返回**
    ;   (str) - 非空列表返回最后一个元素；空列表返回 ""
    cond(
        (l_parts == nil "")
        (cdr(l_parts) == nil car(l_parts))
        (t _lastItem(cdr(l_parts)))
    )
)

procedure(_dropLast(l_parts "l")  ; -> list
    ; 返回去掉最后一个元素的列表。
    ;
    ; **参数**
    ;   l_parts  (list) - 元素列表
    ;
    ; **返回**
    ;   (list|nil) - 元素数 >= 2 时返回去掉末元素的新列表；空或单元素列表返回 nil
    unless(l_parts == nil
        unless(cdr(l_parts) == nil
            cons(car(l_parts) _dropLast(cdr(l_parts)))
        )
    )
)

procedure(_dropFirstN(l_parts n_count "ln")  ; -> list
    ; 返回去掉前 n_count 个元素后的列表。
    ;
    ; **参数**
    ;   l_parts  (list) - 源列表
    ;   n_count  (int)  - 要去掉的元素个数
    ;
    ; **返回**
    ;   (list|nil) - n_count <= 0 返回原列表；去掉数 >= 列表长度时返回 nil
    if(n_count <= 0
        l_parts
        _dropFirstN(cdr(l_parts) n_count - 1)
    )
)

procedure(_dotIndex(t_name "t")  ; -> int | nil
    ; 找出串中最后一个 "." 的位置（1-based）。
    ;
    ; **参数**
    ;   t_name  (str) - 源串
    ;
    ; **返回**
    ;   (int|nil) - 最后一个 "." 的 1-based 位置；没有 "." 返回 nil
    let((n_found n_i)
        n_i = 1
        while(n_i <= length(t_name)
            when(substring(t_name n_i 1) == "."
                n_found = n_i
            )
            n_i = n_i + 1
        )
        n_found
    )
)

procedure(_lstripDots(t_str "t")  ; -> str
    ; 去掉串首连续的 "."。
    ;
    ; **参数**
    ;   t_str  (str) - 源串
    ;
    ; **返回**
    ;   (str) - 自首个非 "." 字符起的后缀；空串或全为 "." 返回 ""
    let((n_i)
        n_i = 1
        while(n_i <= length(t_str) && substring(t_str n_i 1) == "."
            n_i = n_i + 1
        )
        if(n_i > length(t_str)
            ""
            substring(t_str n_i)
        )
    )
)

procedure(_splitKeep(t_str t_sep "tt")  ; -> list[str]
    ; 按单字符分隔符拆分串，保留空字段（顺序不变）。
    ;
    ; **参数**
    ;   t_str  (str) - 源串
    ;   t_sep  (str) - 单字符分隔符
    ;
    ; **返回**
    ;   (list[str]) - 含首尾空字段的字段列表；空串返回单元素 ("")
    let((l_res t_cur n_i n_len)
        t_cur = ""
        n_len = length(t_str)
        n_i = 1
        while(n_i <= n_len
            when(substring(t_str n_i 1) == t_sep
                l_res = tconc(l_res t_cur)
                t_cur = ""
            )
            unless(substring(t_str n_i 1) == t_sep
                t_cur = strcat(t_cur substring(t_str n_i 1))
            )
            n_i = n_i + 1
        )
        car(tconc(l_res t_cur))
    )
)

procedure(_endsWith(t_str t_suf "tt")  ; -> t | nil
    ; 判断 t_str 是否以 t_suf 结尾。
    ;
    ; **参数**
    ;   t_str  (str) - 源串
    ;   t_suf  (str) - 后缀
    ;
    ; **返回**
    ;   (t|nil) - 后缀匹配返回 t；t_suf 为空串返回 t；不匹配返回 nil
    let((n_ls n_rs)
        n_ls = length(t_str)
        n_rs = length(t_suf)
        if(n_rs == 0
            t
            n_rs <= n_ls && substring(t_str n_ls - n_rs + 1 n_rs) == t_suf
        )
    )
)

procedure(_fnmatchBracket(t_pattern n_open n_len)  ; -> (str, int)
    ; 把 pattern 中单个 "[" 字符类段编译为 pcre 字符类（fnmatch._translate 的 "[" 分支）。
    ;
    ; **参数**
    ;   t_pattern  (str) - 完整 fnmatch pattern
    ;   n_open     (int) - "[" 的 1-based 位置
    ;   n_len      (int) - t_pattern 的串长
    ;
    ; **返回**
    ;   (str, int) - 二元组 (正则串, 段后 1-based 位置)：支持 "!" 取反与段内元字符转义；
    ;                无闭合 "]" 时正则按字面 "[" 转义为 \[，位置回到 n_open + 1
    let((n_j g_stop t_stuff g_neg t_out n_k t_ch)
        n_j = n_open + 1
        when(n_j <= n_len
            when(substring(t_pattern n_j 1) == "!"
                n_j = n_j + 1
            )
        )
        when(n_j <= n_len
            when(substring(t_pattern n_j 1) == "]"
                n_j = n_j + 1
            )
        )
        while(!g_stop
            cond(
                (n_j > n_len
                    g_stop = t
                )
                (substring(t_pattern n_j 1) == "]"
                    g_stop = t
                )
                (t n_j = n_j + 1)
            )
        )
        if(n_j > n_len
            list("\\[" n_open + 1)
            let((l_res)
                t_stuff = substring(t_pattern n_open + 1 n_j - n_open - 1)
                when(substring(t_stuff 1 1) == "!"
                    g_neg = t
                    t_stuff = substring(t_stuff 2 length(t_stuff) - 1)
                )
                t_out = ""
                n_k = 1
                while(n_k <= length(t_stuff)
                    t_ch = substring(t_stuff n_k 1)
                    t_out = strcat(t_out
                        if(index("\\&~|" t_ch)
                            strcat("\\" t_ch)
                            t_ch
                        )
                    )
                    n_k = n_k + 1
                )
                unless(t_out == ""
                    when(index("^[]" substring(t_out 1 1))
                        t_out = strcat("\\" t_out)
                    )
                )
                l_res = list(
                    lsprintf("%s%s]" if(g_neg "[^" "[") t_out)
                    n_j + 1
                )
                l_res
            )
        )
    )
)

procedure(_fnmatchToPcre(t_pattern "t")  ; -> str
    ; 把 fnmatch 风格 pattern 编译为 pcre 正则串（"*" "?" 不跨 /）。
    ;
    ; **参数**
    ;   t_pattern  (str) - 含 "*"、"?"、"[seq]" 的 fnmatch pattern
    ;
    ; **返回**
    ;   (str) - 供 ^...\z 全串匹配使用的正则；其余正则元字符逐个加反斜杠转义
    let((t_res n_i n_len t_c)
        t_res = ""
        n_i = 1
        n_len = length(t_pattern)
        while(n_i <= n_len
            t_c = substring(t_pattern n_i 1)
            n_i = n_i + 1
            cond(
                (t_c == "*"
                    t_res = strcat(t_res "[^/]*")
                )
                (t_c == "?"
                    t_res = strcat(t_res "[^/]")
                )
                (t_c == "["
                    let((t_br)
                        t_br = _fnmatchBracket(t_pattern n_i - 1 n_len)
                        t_res = strcat(t_res car(t_br))
                        n_i = car(cdr(t_br))
                    )
                )
                (t
                    t_res = strcat(t_res
                        if(index("\\^$.+()[]{}|" t_c)
                            strcat("\\" t_c)
                            t_c
                        )
                    )
                )
            )
        )
        t_res
    )
)

procedure(_fnmatch1(t_name t_comp "tt")  ; -> t | nil
    ; 按 fnmatch 语义判断单个名字是否匹配单段 pattern。
    ;
    ; **参数**
    ;   t_name  (str) - 被匹配的名字（路径部件）
    ;   t_comp  (str) - 单段 pattern（"*"、"?"、"[seq]" 与字面量）
    ;
    ; **返回**
    ;   (t|nil) - 匹配返回 t，否则返回 nil；pattern 为 "*" 时要求 t_name 非空
    if(t_comp == "*"
        t_name != ""
        pcreMatchp(lsprintf("^%s\\z" _fnmatchToPcre(t_comp)) t_name)
    )
)

procedure(_canMatchEmpty(t_comp "t")  ; -> t | nil
    ; 判断 pattern 段能否匹配空名（""）。
    ;
    ; **参数**
    ;   t_comp  (str) - 单段 pattern
    ;
    ; **返回**
    ;   (t|nil) - 能匹配 "" 返回 t；"*"（以及匹配不了 "" 的段）返回 nil
    t_comp != "*" && _fnmatch1("" t_comp)
)

procedure(_allMatchp(l_names l_comps "ll")  ; -> t | nil
    ; 按顺序逐段判断两个串列表是否等长且每段都匹配。
    ;
    ; **参数**
    ;   l_names  (list) - 名字列表（str）
    ;   l_comps  (list) - pattern 段列表（str）
    ;
    ; **返回**
    ;   (t|nil) - 等长且逐段 _fnmatch1 全通过返回 t；长度不同或任一段不匹配返回 nil
    let((g_ok l_rest)
        g_ok = length(l_names) == length(l_comps)
        l_rest = l_names
        when(g_ok
            foreach(t_c l_comps
                when(g_ok
                    g_ok = l_rest != nil && _fnmatch1(car(l_rest) t_c)
                    l_rest = cdr(l_rest)
                )
            )
        )
        g_ok
    )
)

procedure(_suffixMatchp(l_names l_comps "ll")  ; -> t | nil
    ; 判断名字列表的末段是否与 pattern 段右对齐全部匹配。
    ;
    ; **参数**
    ;   l_names  (list) - 名字列表（str）
    ;   l_comps  (list) - pattern 段列表（str）
    ;
    ; **返回**
    ;   (t|nil) - l_comps 不长于 l_names 且右对齐逐段匹配返回 t；否则返回 nil
    let((n_len n_comp)
        n_len = length(l_names)
        n_comp = length(l_comps)
        unless(n_comp > n_len
            _allMatchp(_dropFirstN(l_names n_len - n_comp) l_comps)
        )
    )
)

procedure(_strMember(t_str l_list "tl")  ; -> t | nil
    ; 判断字符串是否出现在列表中（按 == 比较）。
    ;
    ; **参数**
    ;   t_str   (str)  - 待查找字符串
    ;   l_list  (list) - 候选字符串列表
    ;
    ; **返回**
    ;   (t|nil) - 找到相等元素返回 t，否则返回 nil
    let((g_found)
        foreach(t_s l_list
            when(t_s == t_str
                g_found = t
            )
        )
        g_found
    )
)

procedure(_shellQuote(t_str "t")  ; -> str
    ; 用单引号包裹串，转义为 shell 安全形式。
    ;
    ; **参数**
    ;   t_str  (str) - 原始串
    ;
    ; **返回**
    ;   (str) - 形如 '...'；内部单引号替换为 '\''
    let((t_res n_i n_len t_c)
        t_res = "'"
        n_i = 1
        n_len = length(t_str)
        while(n_i <= n_len
            t_c = substring(t_str n_i 1)
            when(t_c == "'"
                t_res = strcat(t_res "'\\''")
            )
            unless(t_c == "'"
                t_res = strcat(t_res t_c)
            )
            n_i = n_i + 1
        )
        strcat(t_res "'")
    )
)


; ---------- 模块级入口 ----------

procedure(Path(\@rest g_args "g")  ; -> Path
    ; 构造路径对象：零参得 "."，多段按 / 连接，绝对段丢弃此前拼接。
    ;
    ; **参数**
    ;   g_args  (list) - 变参：每段为 string 或 Path（取 str() 再解析），其他类型 error() 中断；
    ;                    零段等价 Path("")
    ;
    ; **返回**
    ;   (Path) - 驻留后的路径实例；解析为词法规则（丢弃空/ "." 部件、".." 保留），不访问磁盘
    let((p_res)
        p_res = _asPath("")
        when(g_args
            foreach(g g_args
                unless(_asPath(g)
                    error("%A: expected string or Path, got %A" 'ycPathLib::Path g)
                )
            )
            p_res = _asPath(car(g_args))
            foreach(g cdr(g_args)
                p_res = p_res->join(g)
            )
        )
        p_res
    )
)

procedure(cwd()  ; -> Path
    ; 返回当前工作目录的 Path。
    ;
    ; **返回**
    ;   (Path) - 基于 getWorkingDir() 构造
    Path(getWorkingDir())
)

procedure(home()  ; -> Path
    ; 返回 HOME 环境变量对应的 Path。
    ;
    ; **返回**
    ;   (Path) - $HOME 路径；HOME 未设置或为空串时 error() 中断
    let((t_home)
        t_home = getShellEnvVar("HOME")
        when(t_home == nil || t_home == ""
            error("%A: home directory is not known" 'ycPathLib::home)
        )
        Path(t_home)
    )
)

procedure(currentFile()  ; -> Path
    ; 返回当前正在加载的文件路径（表达式所在文件在加载时求值）。
    ;
    ; **返回**
    ;   (Path) - 文件加载期间顶层调用返回该文件的 Path；CIW 直接调用、
    ;            加载完成后调用或取不到有效文件时 error() 中断
    let((l_res t_file)
        l_res = errset(get_filename(piport) nil)
        t_file = when(l_res && car(l_res) && stringp(car(l_res)) && car(l_res) != ""
            car(l_res)
        )
        unless(t_file && isFile(t_file)
            error("%A: no current file - call it at the top level of a file while it is being loaded (not from the CIW)"
                'ycPathLib::currentFile)
        )
        Path(t_file)
    )
)

; ---------- 类定义 ----------

; 数据桶：Path 状态（anchor + parts）收敛为单一 _data 槽，obj->? 不罗列 _ 字段
defclass(PathData () (
    ; PathData 数据桶：收纳 Path 的 anchor（锚）与 parts（部件列表），构造后禁写。
    anchor(
        \@initarg anchor
        \@initform ""
    )
    parts(
        \@initarg parts
        \@initform nil
    )
))

defclass(Path () (
    ; Path 实例：不可变路径对象，同规范串驻留共享同一实例。
    ; 状态桶（PathData：anchor + parts），构造后禁写
    _data(
        \@initarg _data
        \@initform nil
    )

    ; pure path
    str()
    name()
    stem()
    suffix()
    suffixes()
    parent()
    parents()
    parts()
    isAbsolute()
    join()
    relativeTo()
    isRelativeTo()
    withName()
    withSuffix()
    match()
    expandUser()
    absolute()
    resolve()

    ; file system
    exists()
    isDir()
    isFile()
    isSymlink()
    readable()
    writable()
    executable()
    size()
    mtime()
    mkdir()
    rmdir()
    unlink()
    rename()
    touch()
    open()
    readText()
    writeText()
    load()
    loadi()
    iterdir()

    ; glob
    glob()
    rglob()
))

defmethod(printself (self(Path))  ; -> str
    ; 返回 Path 的打印描述串，形如 <ycPathLib::Path "/a/b">。
    ;
    ; **返回**
    ;   (str) - lsprintf 按 <类名 "值"> 模板生成
    lsprintf("<%A \"%s\">" className(self) self->str())
)


; ---------- 纯路径方法安装 ----------

inScheme(
procedure(_installPure(self "g")  ; -> any
    ; 把纯路径方法安装到 Path 类（由 initializeInstance 调用）。
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

self->str = lambda(()  ; -> str
    ; 返回路径的规范化字符串形式。
    ;
    ; **返回**
    ;   (str) - 与驻留表键同式：锚与部件按 / 拼接；空路径为 "."，根为 "/"
    _pathKey(self->_data->anchor self->_data->parts)
)

self->name = lambda(()  ; -> str
    ; 返回最后一个路径部件。
    ;
    ; **返回**
    ;   (str) - 最后一个部件；"."、"/" 等无名路径返回 ""
    _lastItem(self->_data->parts)
)

self->suffix = lambda(()  ; -> str
    ; 返回名称的最后一个后缀（自名称中最后一个 "." 起）。
    ;
    ; **返回**
    ;   (str) - 最后一个 "." 既非首字符也非末字符时返回自该点起的后缀，否则返回 ""；
    ;           如 ".bashrc"（最后一个 "." 即首字符）返回 ""，"..foo"（最后一个 "." 在位置 2）返回 ".foo"
    let((t_name n_idx)
        t_name = self->name()
        n_idx = _dotIndex(t_name)
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
        n_idx = _dotIndex(t_name)
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
        unless(t_name == "" || _endsWith(t_name ".")
            mapcar(lambda((t_s "t") strcat("." t_s))
                cdr(_splitKeep(_lstripDots(t_name) "."))
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
        _mkPath(self->_data->anchor _dropLast(self->_data->parts))
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
            l_parts = _dropLast(l_parts)
            l_res = tconc(l_res _mkPath(self->_data->anchor l_parts))
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
    ;   g_args  (list) - 变参：每段 string 或 Path（取 str() 再解析），其他类型走 _error() 中断
    ;
    ; **返回**
    ;   (Path) - 拼接结果（按规范串驻留）；零段返回按驻留规则复用的等价实例
    let((t_anchor l_parts l_parse p_seg)
        t_anchor = self->_data->anchor
        l_parts = self->_data->parts
        foreach(g_seg g_args
            p_seg = _asPath(g_seg)
            unless(p_seg
                _error("join" "expected string or Path, got %A" g_seg)
            )
            l_parse = _parsePath(p_seg->str())
            when(car(l_parse) == "/"
                t_anchor = "/"
                l_parts = cdr(l_parse)
            )
            unless(car(l_parse) == "/"
                l_parts = append(l_parts cdr(l_parse))
            )
        )
        _mkPath(t_anchor l_parts)
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
        p_o = _asPath(g_other)
        unless(p_o
            _error("isRelativeTo" "expected string or Path, got %A" g_other)
        )
        if(self->str() == p_o->str()
            t
            _strMember(p_o->str()
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
        p_o = _asPath(g_other)
        unless(p_o
            _error("relativeTo" "expected string or Path, got %A" g_other)
        )
        unless(self->isRelativeTo(p_o)
            _error("relativeTo" "'%s' is not in the subpath of '%s'"
                self->str()
                p_o->str()
            )
        )
        _mkPath("" _dropFirstN(self->_data->parts length(p_o->_data->parts)))
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
    let((t_old)
        t_old = self->name()
        when(t_old == ""
            _error("withName" "%s has an empty name" self->str())
        )
        unless(t_name != "" && index(t_name "/") == nil && t_name != "."
            _error("withName" "Invalid name '%s'" t_name)
        )
        _mkPath(self->_data->anchor
            append(_dropLast(self->_data->parts) list(t_name))
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
    let((t_name)
        t_name = self->name()
        when(t_name == ""
            _error("withSuffix" "%s has an empty name" self->str())
        )
        unless(t_suffix == ""
            unless(substring(t_suffix 1 1) == "." && t_suffix != "." && index(t_suffix "/") == nil
                _error("withSuffix" "Invalid suffix '%s'" t_suffix)
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
    ;             pattern 相对（锚为空）且解析后无部件（"."、""）时走 _error() 中断（"/" 有锚不触发）
    let((l_parse t_anchor l_parts g_ok)
        l_parse = _parsePath(t_pattern)
        t_anchor = car(l_parse)
        l_parts = cdr(l_parse)
        when(t_anchor == "" && l_parts == nil
            _error("match" "empty pattern")
        )
        if(t_anchor == "/"
            when(self->_data->anchor == t_anchor
                g_ok = if(length(self->_data->parts) == length(l_parts)
                    _allMatchp(self->_data->parts l_parts)
                    when(self->_data->parts == nil && length(l_parts) == 1
                        _canMatchEmpty(car(l_parts))
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
                g_ok = _suffixMatchp(t_path l_parts)
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
    ;            "~other" 形式、HOME 未设置或为空串，走 _error() 中断
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
                        _error("expandUser" "home directory is not known")
                    )
                    l_rest = cdr(self->_data->parts)
                    if(l_rest == nil
                        Path(t_home)
                        Path(lsprintf("%s/%s" t_home buildString(l_rest "/")))
                    )
                )
            )
            (t_first && substring(t_first 1 1) == "~"
                _error("expandUser" "user home directories are not supported: '%s'" t_first)
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


; ---------- 构造时安装全部方法 ----------

inScheme(
defmethod(initializeInstance (self(Path) \@rest _args)
    ; 构造 Path 实例时安装全部方法集：纯路径、文件系统与 glob。
    ;
    ; **参数**
    ;   _args  (list) - 变参：附加初始化参数，本实现忽略
    ;
    ; **返回**
    ;   (t) - 依次调用 _installPure、_installFs、_installGlob 后返回 t
    _installPure(self)
    _installFs(self)
    _installGlob(self)
    t
)
)


unuseNamespace("ycPathLib")

; END
