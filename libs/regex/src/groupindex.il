ycNamespace:::Require("ycPathLib" "ycSubProcess" "ycJson")

useNamespace("ycRegEx")

; 本包先于 subprocess / codec 加载，那两个命名空间里的符号在读取本文件时还不存在；
; 跨库引用一律用 ::: 形式（读取期不做导出表解析），调用发生在运行期。


; 组名表缓存：键为「编号口径 + 制表符 + 模式串」，值为 table 或 'none（该模式无命名组）。
; 有界：超过 _GroupIndexCacheCap 条整表清空重计（丢缓存只增加下次解析开销，不改结果）。
_GroupIndexCache = makeTable("regexGroupIndex" nil)
_GroupIndexCacheCap = 1024
_GroupIndexCacheN = 0

; 辅助解释器探测结果：键 "python" -> 命令名，探测一次后复用。
_GroupIndexProbe = makeTable("regexGroupIndexTool" nil)


procedure(_GroupIndexPython(t_ctx "t")  ; -> str
    ; 返回辅助解释器命令名（python3），探测结果缓存。
    ;
    ; **参数**
    ;   t_ctx  (str) - 出错上下文名（拼入错误消息）
    ;
    ; **返回**
    ;   (str) - 命令名；不可用时 error() 中断
    let((hit res)
        hit = _GroupIndexProbe["python"]
        unless(hit
            res = ycSubProcess:::RunWithRead("command -v python3")
            unless(car(res) == 0 && cadr(res) != ""
                error("%A: group name resolution needs python3 on PATH" t_ctx)
            )
            hit = "python3"
            _GroupIndexProbe["python"] = hit
        )
        hit
    )
)


procedure(_GroupIndexFetch(t_pat g_nac n_g t_ctx "tgxt")  ; -> table | nil
    ; 调用辅助解析取得「组名 -> 组号」映射并校验范围。
    ;
    ; **参数**
    ;   t_pat  (str)   - 原始模式串
    ;   g_nac  (t|nil) - t 时按 no_auto_capture 口径编号（只有命名组参与）
    ;   n_g    (int)   - 该模式的捕获组数
    ;   t_ctx  (str)   - 出错上下文名（拼入错误消息）
    ;
    ; **返回**
    ;   (table|nil) - 组名 -> 组号；无命名组时 nil；
    ;                 解析失败、返回数据异常或组号超出 n_g 时 error() 中断
    let((tool eof cmd res dec names msg n_max name)
        ; 读期求值：把本文件所在目录烧成字面量，运行时调用不会取到调用者的文件。
        tool = #.ycPathLib::CurrentFile()->parent()->join("groupindex.py")->absolute()->str()
        eof = lsprintf("EOF%d" ipcGetPid())
        ; 终止符不能出现在模式串里：heredoc 遇到「独占一行的终止符」就提前结束，
        ; 其后的模式串内容会被 shell 当命令执行。命中即加长，直到模式串里不可能出现。
        while(index(t_pat eof)
            eof = strcat(eof "X")
        )
        cmd = buildString(
            list(
                lsprintf("\"%s\" \"%s\"%s<<'%s'"
                    _GroupIndexPython(t_ctx)
                    tool
                    if(g_nac " --no-auto-capture" "")
                    eof
                )
                t_pat
                eof
            )
            "\n"
        )
        res = ycSubProcess:::RunWithRead(cmd)
        unless(car(res) == 0
            msg = caddr(res)
            when(msg == ""
                msg = "helper failed"
            )
            error("%A: cannot resolve group names for this pattern (%s)" t_ctx msg)
        )
        dec = errset(ycJson:::Decode(cadr(res)) nil)
        unless(dec && car(dec) && tablep(car(dec))
            error("%A: group name resolution returned unexpected data" t_ctx)
        )
        names = car(dec)
        n_max = 0
        foreach(name names
            when(n_max < names[name]
                n_max = names[name]
            )
        )
        when(n_g < n_max
            error("%A: cannot resolve group names for this pattern (group index %d exceeds the pattern's %d group(s))" t_ctx n_max n_g)
        )
        if(length(names) == 0
            nil
            names
        )
    )
)


procedure(_GroupIndex(t_pat n_opts n_g t_ctx "txxt")  ; -> table | nil
    ; 取「组名 -> 组号」映射：懒加载、按模式串缓存；无命名组的模式直接返回 nil。
    ;
    ; **参数**
    ;   t_pat   (str) - 原始模式串
    ;   n_opts  (int) - 编译选项位值（no_auto_capture 改变编号口径）
    ;   n_g     (int) - 该模式的捕获组数
    ;   t_ctx   (str) - 出错上下文名（拼入错误消息）
    ;
    ; **返回**
    ;   (table|nil) - 组名 -> 组号；模式无命名组时 nil（不启动解析）；
    ;                 解析失败或组号越界以 error() 中断
    when(index(t_pat "(?P<")
        let((nac key hit)
            nac = _HasBit(n_opts pcreGenCompileOptBits('?no_auto_capture t))
            key = lsprintf("%d\t%s" if(nac 1 0) t_pat)
            hit = _GroupIndexCache[key]
            unless(hit
                hit = _GroupIndexFetch(t_pat nac n_g t_ctx)
                unless(hit
                    hit = 'none
                )
                _GroupIndexCache[key] = hit
                _GroupIndexCacheN++
                when(_GroupIndexCacheCap < _GroupIndexCacheN
                    _GroupIndexCache = makeTable("regexGroupIndex" nil)
                    _GroupIndexCacheN = 0
                )
            )
            when(hit == 'none
                hit = nil
            )
            hit
        )
    )
)


unuseNamespace("ycRegEx")

; END
