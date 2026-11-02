procedure(_Table()  ; -> table
    makeTable("ycIniTest" ycCodec::Missing)
)

_TestRun("ycIni" 129
    "test_decode.il"
    "test_encode.il"
)

; END
