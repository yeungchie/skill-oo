unless(findNamespace("ycDateTime")
    makeNamespace("ycDateTime")
)
addToNamespace("ycDateTime"
    mapcar('symbolToString '(
        ; datetime.il
        DateTime  ; proc, class
        _DateTimeData  ; class
        _DateTimeCache  ; var
        _DateTimeCacheCap  ; var
        _DateTimeCacheN  ; var
        Now  ; proc
        _DateTimeTime  ; proc
        _MkDateTime  ; proc
        _InstallDateTime  ; proc

        ; format.il
        _FormatToken  ; proc
        _FormatTime  ; proc
        _MonthShort  ; var
        _MonthLong  ; var
        _DayShort  ; var
        _DayLong  ; var
    ))
)
unuseNamespace("ycDateTime")

; END
