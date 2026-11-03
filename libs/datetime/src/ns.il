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
        _MonthShort  ; var
        _MonthLong  ; var
        _DayShort  ; var
        _DayLong  ; var
        _IsLeapYear  ; proc
        _Jan1Weekday  ; proc
        _WeeksInYear  ; proc
        _IsoWeek  ; proc
        _FormatToken  ; proc
        _FormatTime  ; proc
    ))
)
unuseNamespace("ycDateTime")

; END
