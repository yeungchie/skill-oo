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
        Current  ; proc
        _DateTimeParts  ; proc
        _MkDateTime  ; proc
        _AddSec  ; proc
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

        ; parse.il
        _Pow10  ; var
        _ParseDigits  ; proc
        _ParseSigned  ; proc
        _ParseName  ; proc
        _MonthLength  ; proc
        _MonthDayFromYday  ; proc
        _ExpandPattern  ; proc
        _ParseTime  ; proc
        Parse  ; proc
    ))
)
unuseNamespace("ycDateTime")

; END
