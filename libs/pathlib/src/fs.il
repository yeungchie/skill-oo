useNamespace("ycPathLib")


procedure(_FsName(t_str "t")  ; -> str
    ; 把路径串规整为文件系统内建函数可接受的形式。
    ;
    ; **参数**
    ;   t_str  (str) - 原始路径串
    ;
    ; **返回**
    ;   (str) - 以 "/" 或 "~" 开头的路径原样返回，相对路径补 "./" 前缀
    if(pcreMatchp("^[~/]" t_str)
        t_str
        strcat("./" t_str)
    )
)

procedure(_DirNames(t_dir "t")  ; -> list[str]
    ; 列出目录下的条目名，剔除 "." 与 ".."。
    ;
    ; **参数**
    ;   t_dir  (str) - 目录路径
    ;
    ; **返回**
    ;   (list[str]|nil) - 目录存在且非空返回条目名列表；空目录或路径不是目录返回 nil
    let((t_fs)
        t_fs = _FsName(t_dir)
        when(isDir(t_fs)
            setof(t_s getDirFiles(t_fs) t_s != "." && t_s != "..")
        )
    )
)

inScheme(
procedure(_InstallFs(self "g")  ; -> any
    ; 把文件系统方法安装到 Path 类（由 initializeInstance 调用）。
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

self->exists = lambda(()  ; -> t | nil
    ; 判断路径指向的条目是否存在。
    ;
    ; **返回**
    ;   (t|nil) - 存在返回 t，不存在返回 nil（跟随符号链接，broken symlink 视为不存在）
    isFileName(_FsName(self->str()))
)

self->isDir = lambda(()  ; -> t | nil
    ; 判断路径是否指向目录（跟随符号链接）。
    ;
    ; **返回**
    ;   (t|nil) - 是目录返回 t，否则返回 nil（路径不存在同样返回 nil）
    isDir(_FsName(self->str()))
)

self->isFile = lambda(()  ; -> t | nil
    ; 判断路径是否指向普通文件（跟随符号链接）。
    ;
    ; **返回**
    ;   (t|nil) - 是普通文件返回 t，否则返回 nil（路径不存在同样返回 nil）
    isFile(_FsName(self->str()))
)

self->isSymlink = lambda(()  ; -> t | nil
    ; 判断路径本身是否为符号链接（lstat 视角，不跟随链接）。
    ;
    ; **返回**
    ;   (t|nil) - 是符号链接返回 t（含 broken symlink），否则返回 nil
    isLink(_FsName(self->str()))
)

self->readable = lambda(()  ; -> t | nil
    ; 判断当前用户是否可读该路径（跟随符号链接）。
    ;
    ; **返回**
    ;   (t|nil) - 可读返回 t；路径不存在、目标缺失或不可读返回 nil（不报错）
    isReadable(_FsName(self->str()))
)

self->writable = lambda(()  ; -> t | nil
    ; 判断当前用户是否可写该路径（跟随符号链接）。
    ;
    ; **返回**
    ;   (t|nil) - 可写返回 t；路径不存在、目标缺失或不可写返回 nil（不报错）
    isWritable(_FsName(self->str()))
)

self->executable = lambda(()  ; -> t | nil
    ; 判断当前用户是否可执行该路径（跟随符号链接）。
    ;
    ; **返回**
    ;   (t|nil) - 可执行返回 t；路径不存在、目标缺失或不可执行返回 nil（不报错）
    isExecutable(_FsName(self->str()))
)

self->size = lambda(()  ; -> int
    ; 返回路径字节数，跟随符号链接取目标值。
    ;
    ; **返回**
    ;   (int) - 文件字节数；目录返回目录自身字节数；目标不存在（含 broken symlink）走 _error() 中断
    let((t_str)
        t_str = self->str()
        unless(self->exists()
            _error("size" "no such file: %s" t_str)
        )
        fileLength(_FsName(t_str))
    )
)

self->mtime = lambda(()  ; -> int
    ; 返回最后修改时间（整数秒时间戳），跟随符号链接取目标值。
    ;
    ; **返回**
    ;   (int) - 整数秒 mtime；目标不存在（含 broken symlink）或取值为 nil 走 _error() 中断
    let((t_str n_time)
        t_str = self->str()
        unless(self->exists()
            _error("mtime" "no such file: %s" t_str)
        )
        n_time = fileTimeModified(_FsName(t_str))
        unless(n_time
            _error("mtime" "no such file: %s" t_str)
        )
        n_time
    )
)

self->mkdir = lambda((\@key parents existOk "gg")  ; -> t
    ; 创建目录（仿 pathlib.Path.mkdir）：自身已是目录、已是非目录条目、
    ; 父目录缺失（parents 为 nil 时）、或底层 createDir 失败时均 error() 中断。
    ;
    ; **参数**
    ;   ?parents  (t|nil) - 逐级创建缺失的父目录（默认 nil）
    ;   ?existOk  (t|nil) - 目录已存在时不报错（默认 nil）
    ;
    ; **返回**
    ;   (t) - 成功返回 t；失败走 _error() 中断（existOk 仅豁免「已存在且是目录」）
    let((t_str)
        t_str = self->str()
        when(self->isDir()
            unless(existOk
                _error("mkdir" "file exists: %s" t_str)
            )
        )
        unless(self->isDir()
            when(self->exists()
                _error("mkdir" "file exists: %s" t_str)
            )
            unless(self->parent()->isDir()
                if(parents
                    self->parent()->mkdir(?parents t ?existOk existOk)
                    _error("mkdir" "no such file or directory: %s" t_str)
                )
            )
            createDir(_FsName(t_str))
            unless(isDir(_FsName(t_str))
                _error("mkdir" "cannot create directory: %s" t_str)
            )
        )
        t
    )
)

self->rmdir = lambda(()  ; -> t
    ; 删除空目录（不递归）。
    ;
    ; **返回**
    ;   (t) - 成功返回 t；目标不存在或不是目录、目录非空、删除后仍存在，均走 _error() 中断
    let((t_str)
        t_str = self->str()
        unless(self->isDir()
            _error("rmdir" "not a directory: %s" t_str)
        )
        when(_DirNames(t_str)
            _error("rmdir" "directory not empty: %s" t_str)
        )
        deleteDir(_FsName(t_str))
        when(self->isDir()
            _error("rmdir" "cannot remove directory: %s" t_str)
        )
        t
    )
)

self->unlink = lambda((\@key missingOk "g")  ; -> t
    ; 删除文件或符号链接（仿 pathlib.Path.unlink：链接删本体、保留目标，不删目录）。
    ;
    ; **参数**
    ;   ?missingOk  (t|nil) - 目标不存在时不报错（默认 nil）
    ;
    ; **返回**
    ;   (t) - 成功返回 t；目标是真实目录或删除后仍存在走 _error() 中断；缺失时仅 missingOk 静默放行
    let((t_str)
        t_str = self->str()
        when(self->isDir() && !self->isSymlink()
            _error("unlink" "is a directory: %s" t_str)
        )
        if(self->exists() || self->isSymlink()
            deleteFile(_FsName(t_str))
            unless(missingOk
                _error("unlink" "no such file: %s" t_str)
            )
        )
        when(self->exists() || self->isSymlink()
            _error("unlink" "cannot remove: %s" t_str)
        )
        t
    )
)

self->rename = lambda((g_target "g")  ; -> Path
    ; 重命名或移动路径（底层 shell 调用 mv(1)，覆盖语义）；源与目标规范化后同路径（如 ./a 与 a）时不做操作。
    ;
    ; **参数**
    ;   g_target  (any) - 目标路径，string 或 Path
    ;
    ; **返回**
    ;   (Path) - 目标路径对应的 Path；g_target 非 string/Path、源不存在、目标是已存在目录、
    ;            或移动后源仍存在或目标缺失，均走 _error() 中断
    let((p_o t_src t_dst)
        p_o = _AsPath(g_target)
        unless(p_o
            _error("rename" "expected string or Path, got %A" g_target)
        )
        t_src = self->str()
        t_dst = p_o->str()
        unless(self->exists() || self->isSymlink()
            _error("rename" "no such file: '%s'" t_src)
        )
        unless(simplifyFilename(t_src) == simplifyFilename(t_dst)
            when(p_o->isDir()
                _error("rename" "cannot rename '%s' to '%s'" t_src t_dst)
            )
            system(lsprintf("mv %s %s" _ShellQuote(t_src) _ShellQuote(t_dst)))
            when(self->exists() || self->isSymlink() || !(p_o->exists() || p_o->isSymlink())
                _error("rename" "cannot rename '%s' to '%s'" t_src t_dst)
            )
        )
        p_o
    )
)

self->touch = lambda(()  ; -> t
    ; 文件不存在则创建；已存在则更新修改时间、不截断内容。
    ;
    ; **返回**
    ;   (t) - 成功返回 t；目标是目录、touch 命令失败或文件未生成，走 _error() 中断
    let((t_str n_rc)
        t_str = self->str()
        when(self->isDir()
            _error("touch" "is a directory: %s" t_str)
        )
        n_rc = system(strcat("touch " _ShellQuote(t_str)))
        unless(n_rc == 0 && self->exists()
            _error("touch" "cannot touch: %s" t_str)
        )
        t
    )
)

self->open = lambda((\@key mode("r") "t")  ; -> port
    ; 按模式打开文件返回 file port：读取用 "r"，覆盖写入用 "w"（截断已有内容），追加写入用 "a"。
    ;
    ; **参数**
    ;   ?mode  (str) - 打开模式："r" 读取、"w" 截断写入、"a" 追加写入（默认 "r"）
    ;
    ; **返回**
    ;   (port) - 打开的 file port；非法模式、"r" 下目标为目录或文件缺失、打开失败，均走 _error() 中断
    let((t_str g_port)
        t_str = self->str()
        unless(mode == "r" || mode == "w" || mode == "a"
            _error("open" "invalid mode: '%s'" mode)
        )
        when(mode == "r"
            when(self->isDir()
                _error("open" "is a directory: %s" t_str)
            )
            unless(self->isFile()
                _error("open" "no such file: %s" t_str)
            )
            g_port = infile(_FsName(t_str))
        )
        when(mode != "r"
            g_port = outfile(_FsName(t_str) mode)
        )
        unless(g_port
            _error("open" "cannot open: %s" t_str)
        )
        g_port
    )
)

self->readText = lambda(()  ; -> str
    ; 读取整个文件为字符串（保留换行）。
    ;
    ; **返回**
    ;   (str) - 文件全文；目标为目录、文件缺失、打开或读取失败，走 _error() 中断
    let((t_str g_port t_line l_res g_ok)
        t_str = self->str()
        when(self->isDir()
            _error("readText" "is a directory: %s" t_str)
        )
        unless(self->isFile()
            _error("readText" "no such file: %s" t_str)
        )
        g_port = infile(_FsName(t_str))
        unless(g_port
            _error("readText" "cannot open: %s" t_str)
        )
        g_ok = errset(
            while(gets(t_line g_port)
                l_res = tconc(l_res t_line)
            )
            t
        )
        close(g_port)
        unless(g_ok
            _error("readText" "cannot read: %s" t_str)
        )
        buildString(car(l_res) "")
    )
)

self->writeText = lambda((t_text "t")  ; -> t
    ; 覆盖写入字符串：文件不存在则创建，已有内容被截断。
    ;
    ; **参数**
    ;   t_text  (str) - 写入内容
    ;
    ; **返回**
    ;   (t) - 成功返回 t；目标为目录、父目录缺失、打开或写入失败，走 _error() 中断
    let((t_str g_port g_ok)
        t_str = self->str()
        when(self->isDir()
            _error("writeText" "is a directory: %s" t_str)
        )
        g_port = outfile(_FsName(t_str) "w")
        unless(g_port
            _error("writeText" "cannot open: %s" t_str)
        )
        g_ok = errset(fprintf(g_port "%s" t_text) t)
        close(g_port)
        unless(g_ok
            _error("writeText" "cannot write: %s" t_str)
        )
        t
    )
)

self->load = lambda((\@optional g_password "g")  ; -> t
    ; 预检后执行该路径的 SKILL 文件（原生 load，文件内运行期错误外传）。
    ;
    ; **参数**
    ;   g_password  (str|nil) - 加密文件密码；省略或 nil 表示无密码（不传给原生 load）；加密加载路径未实证（无夹具，仅透传）
    ;
    ; **返回**
    ;   (t) - 成功返回 t（原生 load 的返回值；失败按原生语义外传）
    let((t_str)
        when(g_password && !stringp(g_password)
            _error("load" "password must be a string")
        )
        t_str = self->str()
        when(self->isDir()
            _error("load" "is a directory: %s" t_str)
        )
        unless(self->isFile()
            _error("load" "no such file: %s" t_str)
        )
        if(g_password
            load(_FsName(t_str) g_password)
            load(_FsName(t_str))
        )
    )
)

self->loadi = lambda((\@optional g_password "g")  ; -> t
    ; 预检后执行该路径的 SKILL 文件（原生 loadi，运行期错误打印后照常返回）。
    ;
    ; **参数**
    ;   g_password  (str|nil) - 加密文件密码；省略或 nil 表示无密码（不传给原生 loadi）；加密加载路径未实证（无夹具，仅透传）
    ;
    ; **返回**
    ;   (t) - 成功返回 t（原生 loadi 的返回值；失败按原生语义外传）
    let((t_str)
        when(g_password && !stringp(g_password)
            _error("loadi" "password must be a string")
        )
        t_str = self->str()
        when(self->isDir()
            _error("loadi" "is a directory: %s" t_str)
        )
        unless(self->isFile()
            _error("loadi" "no such file: %s" t_str)
        )
        if(g_password
            loadi(_FsName(t_str) g_password)
            loadi(_FsName(t_str))
        )
    )
)

)
)


unuseNamespace("ycPathLib")

; END
