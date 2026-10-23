useNamespace("ycPathLib")


; ---------- 模块级 helper（不导出） ----------

; 实例驻留表：规范串 → Path（同串共享同一实例，== 为真）。构造后禁止再写
; self->_data 及其字段（别名污染——纪律非语言强制）；绕过本函数直接
; makeInstance 的实例不共享，请走 Path()/_AsPath()/_MkPath()。
; 驻留表有界：超过 _PathCacheCap 条整体清空重计（丢共享只弱化 == 快路径，不改正确性）。
_PathCache = makeTable("pathCache" nil)
_PathCacheCap = 8192
_PathCacheN = 0

procedure(_AsPath(g_x "g")  ; -> Path | nil
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
            l_parse = _ParsePath(t_s)
            _MkPath(car(l_parse) cdr(l_parse))
        )
    )
)

procedure(_ParsePath(t_path "t")  ; -> (str . list[str])
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

procedure(_PathKey(t_anchor l_parts "tl")  ; -> str
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

procedure(_MkPath(t_anchor l_parts "tl")  ; -> Path
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
        t_key = _PathKey(t_anchor l_parts)
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

procedure(_LastItem(l_parts "l")  ; -> str
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
        (t _LastItem(cdr(l_parts)))
    )
)

procedure(_DropLast(l_parts "l")  ; -> list
    ; 返回去掉最后一个元素的列表。
    ;
    ; **参数**
    ;   l_parts  (list) - 元素列表
    ;
    ; **返回**
    ;   (list|nil) - 元素数 >= 2 时返回去掉末元素的新列表；空或单元素列表返回 nil
    unless(l_parts == nil
        unless(cdr(l_parts) == nil
            cons(car(l_parts) _DropLast(cdr(l_parts)))
        )
    )
)

procedure(_DropFirstN(l_parts n_count "lx")  ; -> list
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
        _DropFirstN(cdr(l_parts) n_count - 1)
    )
)

procedure(_DotIndex(t_name "t")  ; -> int | nil
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

procedure(_LstripDots(t_str "t")  ; -> str
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

procedure(_SplitKeep(t_str t_sep "tt")  ; -> list[str]
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

procedure(_EndsWith(t_str t_suf "tt")  ; -> t | nil
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

procedure(_StrMember(t_str l_list "tl")  ; -> t | nil
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

procedure(_ShellQuote(t_str "t")  ; -> str
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
        p_res = _AsPath("")
        when(g_args
            foreach(g g_args
                unless(_AsPath(g)
                    error("%A: expected string or Path, got %A" 'ycPathLib::Path g)
                )
            )
            p_res = _AsPath(car(g_args))
            foreach(g cdr(g_args)
                p_res = p_res->join(g)
            )
        )
        p_res
    )
)

procedure(Cwd()  ; -> Path
    ; 返回当前工作目录的 Path。
    ;
    ; **返回**
    ;   (Path) - 基于 getWorkingDir() 构造
    Path(getWorkingDir())
)

procedure(Home()  ; -> Path
    ; 返回 HOME 环境变量对应的 Path。
    ;
    ; **返回**
    ;   (Path) - $HOME 路径；HOME 未设置或为空串时 error() 中断
    let((t_home)
        t_home = getShellEnvVar("HOME")
        when(t_home == nil || t_home == ""
            error("%A: home directory is not known" 'ycPathLib::Home)
        )
        Path(t_home)
    )
)

procedure(CurrentFile()  ; -> Path
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
                'ycPathLib::CurrentFile)
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

    ; codec
    readJson()
    readYaml()
    readCsv()
    readToml()
))

defmethod(printself (self(Path))  ; -> str
    ; 返回 Path 的打印描述串，形如 ycPathLib::Path("/a/b")（命名空间限定构造调用形式，顶层 evalstring 可复得同一驻留实例）。
    ;
    ; **返回**
    ;   (str) - lsprintf 按 %A(%A) 模板生成（类名取 className，参数为路径串）
    lsprintf("%A(%A)" className(self) self->str())
)


; ---------- 构造时安装全部方法 ----------

inScheme(
defmethod(initializeInstance (self(Path) \@rest _args)
    ; 构造 Path 实例时安装全部方法集：纯路径、文件系统、glob 与 codec。
    ;
    ; **参数**
    ;   _args  (list) - 变参：附加初始化参数，本实现忽略
    ;
    ; **返回**
    ;   (t) - 依次调用 _InstallPure、_InstallFs、_InstallGlob、_InstallCodec 后返回 t
    _InstallPure(self)
    _InstallFs(self)
    _InstallGlob(self)
    _InstallCodec(self)
    t
)
)

unuseNamespace("ycPathLib")

; END
