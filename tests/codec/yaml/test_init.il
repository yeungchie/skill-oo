procedure(_Dump(g_v "g")  ; -> str
    ycYaml::Encode(g_v ?flow t ?sortKeys t ?finalNewline nil)
)

procedure(_AssertDumpEq(g_a g_b t_msg "ggt")  ; -> t | nil
    let(((t_a nil) (t_b nil) (g_ok nil) (l_perf nil))
        l_perf = measureTime(
            t_a = _Dump(g_a)
            t_b = _Dump(g_b)
            g_ok = t_a == t_b
        )
        unless(g_ok
            printf("  expected: %s\n" t_b)
            printf("  actual: %s\n" t_a)
        )
        _TestReport(g_ok t_msg caddr(l_perf))
    )
)

_TestRun("ycYaml" 187
    "test_decode.il"
    "test_encode.il"
)

; END
