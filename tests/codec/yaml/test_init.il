procedure(_Dump(g_v "g")  ; -> str
    ycYaml::Encode(g_v ?flow t ?sortKeys t ?finalNewline nil)
)

procedure(_AssertDumpEq(g_a g_b t_msg "ggt")  ; -> t | nil
    let(((a nil) (b nil) (ok nil) (perf nil))
        perf = measureTime(
            a = _Dump(g_a)
            b = _Dump(g_b)
            ok = a == b
        )
        unless(ok
            printf("  expected: %s\n" b)
            printf("  actual: %s\n" a)
        )
        _TestReport(ok t_msg caddr(perf))
    )
)

_TestRun("ycYaml" 224
    "test_decode.il"
    "test_encode.il"
)

; END
