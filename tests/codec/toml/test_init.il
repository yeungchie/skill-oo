procedure(_Table()  ; -> table
    makeTable("ycTomlTest" ycCodec::Missing)
)

_TestRun("ycToml" 169
    "test_decode.il"
    "test_encode.il"
)

; END
