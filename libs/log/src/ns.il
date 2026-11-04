unless(findNamespace("ycLog")
    makeNamespace("ycLog")
)
addToNamespace("ycLog"
    mapcar('symbolToString '(
        ; logger.il
        Logger  ; proc, class
        _LoggerData  ; class
        _LevelParts  ; proc
        _CheckFlag  ; proc
        _LogLine  ; proc
        _InstallLogger  ; proc
    ))
)
unuseNamespace("ycLog")

; END
