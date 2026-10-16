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

let((l_res t_self t_dir)
    l_res = errset(get_filename(piport) nil)
    t_self = when(l_res && car(l_res) && stringp(car(l_res)) && car(l_res) != ""
        car(l_res)
    )
    unless(t_self
        error("ycSubProcess: can't determine the current file - load this file with an explicit path")
    )
    unless(pcreMatchp("^[~/]|^\\.{1,2}/" t_self)
        t_self = strcat("./" t_self)
    )
    t_dir = simplifyFilename(pcreReplace(pcreCompile("(?<=/)[^/]+/*$") t_self "" 0) t)
    unless(pcreMatchp("/$" t_dir)
        t_dir = strcat(t_dir "/")
    )

    _TestRunJobDone = nil
    l_res = errset(load(strcat(t_dir "test_run_job.il")) t)
    unless(_TestRunJobDone
        _TestCount = _TestCount + 1
        _TestFail = _TestFail + 1
        printf("TEST FAILED - test_run_job.il did not run to completion%s\n"
            if(l_res "" " (load raised an error)")
        )
    )

    _TestCreateJobDone = nil
    l_res = errset(load(strcat(t_dir "test_create_job.il")) t)
    unless(_TestCreateJobDone
        _TestCount = _TestCount + 1
        _TestFail = _TestFail + 1
        printf("TEST FAILED - test_create_job.il did not run to completion%s\n"
            if(l_res "" " (load raised an error)")
        )
    )

    _TestTimeDone = nil
    l_res = errset(load(strcat(t_dir "test_time.il")) t)
    unless(_TestTimeDone
        _TestCount = _TestCount + 1
        _TestFail = _TestFail + 1
        printf("TEST FAILED - test_time.il did not run to completion%s\n"
            if(l_res "" " (load raised an error)")
        )
    )

    _TestRstringDone = nil
    l_res = errset(load(strcat(t_dir "test_rstring.il")) t)
    unless(_TestRstringDone
        _TestCount = _TestCount + 1
        _TestFail = _TestFail + 1
        printf("TEST FAILED - test_rstring.il did not run to completion%s\n"
            if(l_res "" " (load raised an error)")
        )
    )

    _TestCallbackDone = nil
    l_res = errset(load(strcat(t_dir "test_callback.il")) t)
    unless(_TestCallbackDone
        _TestCount = _TestCount + 1
        _TestFail = _TestFail + 1
        printf("TEST FAILED - test_callback.il did not run to completion%s\n"
            if(l_res "" " (load raised an error)")
        )
    )

    _TestControlDone = nil
    l_res = errset(load(strcat(t_dir "test_control.il")) t)
    unless(_TestControlDone
        _TestCount = _TestCount + 1
        _TestFail = _TestFail + 1
        printf("TEST FAILED - test_control.il did not run to completion%s\n"
            if(l_res "" " (load raised an error)")
        )
    )

    _TestErrorsDone = nil
    l_res = errset(load(strcat(t_dir "test_errors.il")) t)
    unless(_TestErrorsDone
        _TestCount = _TestCount + 1
        _TestFail = _TestFail + 1
        printf("TEST FAILED - test_errors.il did not run to completion%s\n"
            if(l_res "" " (load raised an error)")
        )
    )

    printf("\nPASS: %d / FAIL: %d\n"
        _TestCount - _TestFail
        _TestFail
    )

    when(_TestFail > 0
        error("ycSubProcess: %d test(s) failed" _TestFail)
    )
)

; END
