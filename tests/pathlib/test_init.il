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

procedure(_p(g_path "g")  ; -> Path
    ycPathLib::Path(g_path)
)

procedure(_s(g_path "g")  ; -> str
    ycPathLib::Path(g_path)->str()
)

procedure(_sl(g_list "g")  ; -> list of str
    mapcar(lambda((g "g") g->str()) g_list)
)

procedure(_hasStr(l_list t_str "lt")  ; -> t | nil
    let((g_found)
        foreach(t_s l_list
            when(t_s == t_str
                g_found = t
            )
        )
        g_found
    )
)

procedure(_countStr(l_list t_str "lt")  ; -> n
    let((n_c)
        n_c = 0
        foreach(t_s l_list
            when(t_s == t_str
                n_c = n_c + 1
            )
        )
        n_c
    )
)

procedure(_assertSameStrs(l_actual l_expected t_msg "llt")  ; -> t | nil
    let((g_ok)
        g_ok = length(l_actual) == length(l_expected)
        when(g_ok
            foreach(t_s l_actual
                when(_countStr(l_actual t_s) != _countStr(l_expected t_s)
                    g_ok = nil
                )
            )
        )
        when(g_ok
            foreach(t_s l_expected
                when(_countStr(l_expected t_s) != _countStr(l_actual t_s)
                    g_ok = nil
                )
            )
        )
        unless(g_ok
            printf("  expected (%d):\n" length(l_expected))
            foreach(t_s l_expected
                printf("    %s\n" t_s)
            )
            printf("  actual (%d):\n" length(l_actual))
            foreach(t_s l_actual
                printf("    %s\n" t_s)
            )
        )
        _assert(g_ok t_msg)
    )
)

procedure(_assertSameSeq(l_actual l_expected t_msg "llt")  ; -> t | nil
    let((g_ok l_a l_b)
        g_ok = length(l_actual) == length(l_expected)
        when(g_ok
            l_a = l_actual
            l_b = l_expected
            while(g_ok && l_a
                g_ok = car(l_a) == car(l_b)
                l_a = cdr(l_a)
                l_b = cdr(l_b)
            )
        )
        unless(g_ok
            printf("  expected (%d): %s\n" length(l_expected) buildString(l_expected " "))
            printf("  actual (%d): %s\n" length(l_actual) buildString(l_actual " "))
        )
        _assert(g_ok t_msg)
    )
)

procedure(_assertOk(g_r t_msg "gt")  ; -> t | nil（errset 结果：捕获成功且值为 t 才过）
    let((g_ok)
        when(g_r
            g_ok = car(g_r)
        )
        _assert(g_ok t_msg)
    )
)

procedure(_sameJson(g_a g_b t_format "ggt")  ; -> t | nil
    ycJson::Encode(g_a ?format t_format ?sortKeys t)
        == ycJson::Encode(g_b ?format t_format ?sortKeys t)
)

procedure(_sameYaml(g_a g_b "gg")  ; -> t | nil
    ycYaml::Encode(g_a ?sortKeys t)
        == ycYaml::Encode(g_b ?sortKeys t)
)

let((l_res t_self t_dir)
    l_res = errset(get_filename(piport) nil)
    t_self = when(l_res && car(l_res) && stringp(car(l_res)) && car(l_res) != ""
        car(l_res)
    )
    unless(t_self
        error("ycPathLib: can't determine the current file - load this file with an explicit path")
    )
    unless(pcreMatchp("^[~/]|^\\.{1,2}/" t_self)
        t_self = strcat("./" t_self)
    )
    t_dir = simplifyFilename(pcreReplace(pcreCompile("(?<=/)[^/]+/*$") t_self "" 0) t)
    unless(pcreMatchp("/$" t_dir)
        t_dir = strcat(t_dir "/")
    )

    _TestPureDone = nil
    l_res = errset(load(strcat(t_dir "test_pure.il")) t)
    unless(_TestPureDone
        _TestCount = _TestCount + 1
        _TestFail = _TestFail + 1
        printf("TEST FAILED - test_pure.il did not run to completion%s\n"
            if(l_res "" " (load raised an error)")
        )
    )

    _TestFsDone = nil
    l_res = errset(load(strcat(t_dir "test_fs.il")) t)
    unless(_TestFsDone
        _TestCount = _TestCount + 1
        _TestFail = _TestFail + 1
        printf("TEST FAILED - test_fs.il did not run to completion%s\n"
            if(l_res "" " (load raised an error)")
        )
    )

    _TestCodecDone = nil
    l_res = errset(load(strcat(t_dir "test_codec.il")) t)
    unless(_TestCodecDone
        _TestCount = _TestCount + 1
        _TestFail = _TestFail + 1
        printf("TEST FAILED - test_codec.il did not run to completion%s\n"
            if(l_res "" " (load raised an error)")
        )
    )

    printf("\nPASS: %d / FAIL: %d\n"
        _TestCount - _TestFail
        _TestFail
    )

    when(_TestFail > 0
        error("ycPathLib: %d test(s) failed" _TestFail)
    )
)

; END
