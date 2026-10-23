_TestCount = 0
_TestFail = 0

procedure(_Assert(g_cond t_msg "gt")  ; -> t | nil
    ; 断言真值并计数。
    ;
    ; **参数**
    ;   g_cond  (any) - 待断言值
    ;   t_msg   (str) - 用例名
    ;
    ; **返回**
    ;   (t|nil) - 原样返回断言值
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

procedure(_AssertError(g_funobj t_msg "gt")  ; -> t | nil
    ; 断言调用报错（静默捕获）。
    ;
    ; **参数**
    ;   g_funobj  (any) - 零参 lambda
    ;   t_msg     (str) - 用例名
    ;
    ; **返回**
    ;   (t|nil) - 捕获到错误时为 t
    let((l_res)
        _TestCount = _TestCount + 1
        l_res = errset(funcall(g_funobj) nil)
        when(l_res
            _TestFail = _TestFail + 1
        )
        if(l_res
            printf("TEST FAILED - %s\n" t_msg)
            printf("TEST PASSED - %s\n" t_msg)
        )
        !l_res
    )
)

procedure(_AssertErrorMsg(g_funobj t_sub t_msg "gtt")  ; -> t | nil
    ; 断言调用报错且消息包含指定片段。
    ;
    ; **参数**
    ;   g_funobj  (any) - 零参 lambda
    ;   t_sub     (str) - 期望的消息片段
    ;   t_msg     (str) - 用例名
    ;
    ; **返回**
    ;   (t|nil) - 条件满足时为 t
    let((t_text t_tail g_pass)
        _TestCount = _TestCount + 1
        g_pass = errset(funcall(g_funobj) nil)
        when(!g_pass
            ; errset.errset 为 ("error" 序号 t nil ("*Error* 消息"))，取末元素首字符串
            t_tail = errset.errset
            when(t_tail && 4 <= length(t_tail)
                t_text = car(car(cdr(cdr(cdr(cdr(t_tail))))))
            )
        )
        g_pass = !g_pass && t_text && index(t_text t_sub)
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

let((l_res t_self t_dir)
    l_res = errset(get_filename(piport) nil)
    t_self = when(l_res && car(l_res) && stringp(car(l_res)) && car(l_res) != ""
        car(l_res)
    )
    unless(t_self
        error("ycTextwrap: can't determine the current file - load this file with an explicit path")
    )
    unless(pcreMatchp("^[~/]|^\\.{1,2}/" t_self)
        t_self = strcat("./" t_self)
    )
    t_dir = simplifyFilename(pcreReplace(pcreCompile("(?<=/)[^/]+/*$") t_self "" 0) t)
    unless(pcreMatchp("/$" t_dir)
        t_dir = strcat(t_dir "/")
    )

    _TestWrapDone = nil
    l_res = errset(load(strcat(t_dir "test_wrap.il")) t)
    unless(_TestWrapDone
        _TestCount = _TestCount + 1
        _TestFail = _TestFail + 1
        printf("TEST FAILED - test_wrap.il did not run to completion%s\n"
            if(l_res "" " (load raised an error)")
        )
    )

    _TestBlockDone = nil
    l_res = errset(load(strcat(t_dir "test_block.il")) t)
    unless(_TestBlockDone
        _TestCount = _TestCount + 1
        _TestFail = _TestFail + 1
        printf("TEST FAILED - test_block.il did not run to completion%s\n"
            if(l_res "" " (load raised an error)")
        )
    )

    printf("\nPASS: %d / FAIL: %d\n"
        _TestCount - _TestFail
        _TestFail
    )

    when(_TestFail > 0
        error("ycTextwrap: %d test(s) failed" _TestFail)
    )
)

; END
