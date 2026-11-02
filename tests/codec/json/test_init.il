procedure(_AssertDumpEq(g_actual g_expected t_msg "ggt")  ; -> t | nil（经 encode 规范化串比较结构）
    let(((t_a nil) (t_b nil) (g_ok nil) (l_perf nil))
        l_perf = measureTime(
            t_a = ycJson::Encode(g_actual ?sortKeys t)
            t_b = ycJson::Encode(g_expected ?sortKeys t)
            g_ok = t_a == t_b
        )
        unless(g_ok
            printf("  expected: %s\n" t_b)
            printf("  actual: %s\n" t_a)
        )
        _TestReport(g_ok t_msg caddr(l_perf))
    )
)

procedure(_NestArrays(n_n "n")  ; -> str（n 层嵌套数组包裹 1）
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

procedure(_NestArrayValue(n_n "n")  ; -> any（n 层嵌套 list 包裹 1）
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

_TestRun("ycJson" 230
    "test_decode.il"
    "test_encode.il"
    "test_variants.il"
)

; END
