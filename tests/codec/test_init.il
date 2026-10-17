_TestCount = 0
_TestFail = 0

procedure(_assert(g_cond t_msg "gt")  ; -> t | nil
    _TestCount = _TestCount + 1
    unless(g_cond
        _TestFail = _TestFail + 1
    )
    if(g_cond
        printf("TEST PASSED - %s\n" t_msg)
        printf("TEST FAILED - %s\n" t_msg)
    )
    g_cond
)

procedure(_assertError(g_funobj t_msg "gt")  ; -> t | nil
    let((g_ok)
        _TestCount = _TestCount + 1
        g_ok = errset(funcall(g_funobj) nil)
        when(g_ok
            _TestFail = _TestFail + 1
        )
        if(g_ok
            printf("TEST FAILED - %s\n" t_msg)
            printf("TEST PASSED - %s\n" t_msg)
        )
        !g_ok
    )
)

procedure(_assertErrorMsg(g_funobj t_sub t_msg "gtt")  ; -> t | nil（错误消息须包含 t_sub）
    let((g_ok t_text t_tail g_pass)
        _TestCount = _TestCount + 1
        g_ok = errset(funcall(g_funobj) nil)
        when(!g_ok
            ; errset.errset 为 ("error" 序号 t nil ("*Error* 消息"))，取末元素首字符串
            t_tail = errset.errset
            when(t_tail && 4 <= length(t_tail)
                t_text = car(car(cdr(cdr(cdr(cdr(t_tail))))))
            )
        )
        g_pass = !g_ok && t_text && index(t_text t_sub)
        unless(g_pass
            _TestFail = _TestFail + 1
        )
        if(g_pass
            printf("TEST PASSED - %s\n" t_msg)
            printf("TEST FAILED - %s\n" t_msg)
        )
        unless(g_pass
            printf("  expected message containing: %A\n" t_sub)
            printf("  actual: %A\n" if(t_text t_text "no error detail"))
        )
        g_pass
    )
)

procedure(_assertDumpEq(g_actual g_expected t_msg "ggt")  ; -> t | nil（经 jsonDump 规范化串比较结构）
    let((t_a t_b g_ok)
        t_a = ycCodec::jsonDump(g_actual)
        t_b = ycCodec::jsonDump(g_expected)
        g_ok = t_a == t_b
        unless(g_ok
            printf("  expected: %s\n" t_b)
            printf("  actual: %s\n" t_a)
        )
        _assert(g_ok t_msg)
    )
)

procedure(_nestArrays(n_n "n")  ; -> str（n 层嵌套数组包裹 1）
    let((t_s n_i)
        t_s = "1"
        when(0 < n_n
            for(n_i 1 n_n
                t_s = strcat("[" t_s "]")
            )
        )
        t_s
    )
)

procedure(_nestArrayValue(n_n "n")  ; -> any（n 层嵌套 list 包裹 1）
    let((g_v n_i)
        g_v = 1
        when(0 < n_n
            for(n_i 1 n_n
                g_v = list(g_v)
            )
        )
        g_v
    )
)

let((l_res t_self t_dir)
    l_res = errset(get_filename(piport) nil)
    t_self = when(l_res && car(l_res) && stringp(car(l_res)) && car(l_res) != ""
        car(l_res)
    )
    unless(t_self
        error("ycCodec: can't determine the current file - load this file with an explicit path")
    )
    unless(pcreMatchp("^[~/]|^\\.{1,2}/" t_self)
        t_self = strcat("./" t_self)
    )
    t_dir = simplifyFilename(pcreReplace(pcreCompile("(?<=/)[^/]+/*$") t_self "" 0) t)
    unless(pcreMatchp("/$" t_dir)
        t_dir = strcat(t_dir "/")
    )

    _TestParseDone = nil
    l_res = errset(load(strcat(t_dir "test_parse.il")) t)
    unless(_TestParseDone
        _TestCount = _TestCount + 1
        _TestFail = _TestFail + 1
        printf("TEST FAILED - test_parse.il did not run to completion%s\n"
            if(l_res "" " (load raised an error)")
        )
    )

    _TestDumpDone = nil
    l_res = errset(load(strcat(t_dir "test_dump.il")) t)
    unless(_TestDumpDone
        _TestCount = _TestCount + 1
        _TestFail = _TestFail + 1
        printf("TEST FAILED - test_dump.il did not run to completion%s\n"
            if(l_res "" " (load raised an error)")
        )
    )

    _TestVariantsDone = nil
    l_res = errset(load(strcat(t_dir "test_variants.il")) t)
    unless(_TestVariantsDone
        _TestCount = _TestCount + 1
        _TestFail = _TestFail + 1
        printf("TEST FAILED - test_variants.il did not run to completion%s\n"
            if(l_res "" " (load raised an error)")
        )
    )

    printf("\nPASS: %d / FAIL: %d\n"
        _TestCount - _TestFail
        _TestFail
    )

    when(_TestFail > 0
        error("ycCodec: %d test(s) failed" _TestFail)
    )
)

; END
