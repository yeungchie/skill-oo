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
    _TestSentinelDone = nil
    l_res = errset(load(strcat(t_dir "test_sentinel.il")) t)
    unless(_TestSentinelDone
        _TestCount = _TestCount + 1
        _TestFail = _TestFail + 1
        printf("TEST FAILED - test_sentinel.il did not run to completion%s\n"
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
