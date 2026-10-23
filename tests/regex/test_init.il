_TestCount = 0
_TestFail = 0

procedure(_Assert(g_cond t_msg "gt")  ; -> t | nil
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

procedure(_AssertOk(g_r t_msg "gt")  ; -> t | nil (errset list, value t means pass)
    let((g_ok)
        when(g_r
            g_ok = car(g_r)
        )
        _Assert(g_ok t_msg)
    )
)

procedure(_TupKey(l_list "l")  ; -> str ("a,b,c"; nil -> "")
    cond(
        (l_list == nil "")
        (cdr(l_list) == nil car(l_list))
        (t lsprintf("%s,%s" car(l_list) _TupKey(cdr(l_list))))
    )
)

procedure(_AssertSameSeq(l_actual l_expected t_msg "llt")  ; -> t | nil (ordered strings)
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
            printf("  expected (%d): [%s]\n" length(l_expected) _TupKey(l_expected))
            printf("  actual (%d): [%s]\n" length(l_actual) _TupKey(l_actual))
        )
        _Assert(g_ok t_msg)
    )
)

procedure(_AssertSameTuples(l_actual l_expected t_msg "llt")  ; -> t | nil (list of lists)
    _AssertSameSeq(mapcar('_TupKey l_actual) mapcar('_TupKey l_expected) t_msg)
)

procedure(_IntKey(l_list "l")  ; -> str ("1 2 3"; nil -> "")
    cond(
        (l_list == nil "")
        (cdr(l_list) == nil lsprintf("%d" car(l_list)))
        (t lsprintf("%d %s" car(l_list) _IntKey(cdr(l_list))))
    )
)

procedure(_AssertSameInts(l_actual l_expected t_msg "llt")  ; -> t | nil (ordered ints)
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
            printf("  expected ints (%d): %s\n" length(l_expected) _IntKey(l_expected))
            printf("  actual ints (%d): %s\n" length(l_actual) _IntKey(l_actual))
        )
        _Assert(g_ok t_msg)
    )
)

procedure(_StartsOf(l_l "l")  ; -> list of int
    mapcar(lambda((m "g") m->start()) l_l)
)

procedure(_EndsOf(l_l "l")  ; -> list of int
    mapcar(lambda((m "g") m->end()) l_l)
)

procedure(_AssertSameSpan(g_m n_start n_end t_msg "gnnt")  ; -> t | nil (nil match fails safely)
    let((g_ok l_sp)
        when(g_m
            l_sp = g_m->span()
        )
        g_ok = g_m && length(l_sp) == 2 && car(l_sp) == n_start && car(cdr(l_sp)) == n_end
        unless(g_ok
            printf("  expected span (%d, %d)\n" n_start n_end)
            when(l_sp
                printf("  actual span (%d, %d)\n" car(l_sp) car(cdr(l_sp)))
            )
        )
        _Assert(g_ok t_msg)
    )
)

let((l_res t_dir)
    ; tests/regex/load.il bootstraps the libs first, so ycPathLib is here.
    t_dir = ycPathLib::CurrentFile()->parent()

    _TestCoreDone = nil
    l_res = errset(t_dir->join("test_core.il")->load() t)
    unless(_TestCoreDone
        _TestCount = _TestCount + 1
        _TestFail = _TestFail + 1
        printf("TEST FAILED - test_core.il did not run to completion%s\n"
            if(l_res "" " (load raised an error)")
        )
    )

    _TestParityDone = nil
    l_res = errset(t_dir->join("test_parity.il")->load() t)
    unless(_TestParityDone
        _TestCount = _TestCount + 1
        _TestFail = _TestFail + 1
        printf("TEST FAILED - test_parity.il did not run to completion%s\n"
            if(l_res "" " (load raised an error)")
        )
    )

    printf("\nPASS: %d / FAIL: %d\n"
        _TestCount - _TestFail
        _TestFail
    )

    when(_TestFail > 0
        error("ycRegEx: %d test(s) failed" _TestFail)
    )
)

; END
