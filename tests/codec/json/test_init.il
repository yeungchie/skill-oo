procedure(_AssertDumpEq(g_actual g_expected t_msg "ggt")  ; -> t | nil（经 encode 规范化串比较结构）
    let(((a nil) (b nil) (ok nil) (perf nil))
        perf = measureTime(
            a = ycJson::Encode(g_actual ?sortKeys t)
            b = ycJson::Encode(g_expected ?sortKeys t)
            ok = a == b
        )
        unless(ok
            printf("  expected: %s\n" b)
            printf("  actual: %s\n" a)
        )
        _TestReport(ok t_msg caddr(perf))
    )
)

procedure(_NestArrays(n_n "n")  ; -> str（n 层嵌套数组包裹 1）
    let((item i)
        item = "1"
        when(0 < n_n
            for(i2 1 n_n
                item = strcat("[" item "]")
            )
        )
        item
    )
)

procedure(_NestArrayValue(n_n "n")  ; -> any（n 层嵌套 list 包裹 1）
    let((v i)
        v = 1
        when(0 < n_n
            for(i2 1 n_n
                v = list(v)
            )
        )
        v
    )
)

_TestRun("ycJson" 235
    "test_decode.il"
    "test_encode.il"
    "test_variants.il"
)

; END
