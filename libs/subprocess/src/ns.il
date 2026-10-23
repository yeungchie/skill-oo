unless(findNamespace("ycSubProcess")
    makeNamespace("ycSubProcess")
)
addToNamespace("ycSubProcess"
    mapcar('symbolToString '(
        Stream
        AsyncJob
        RunJob
        CreateJob
        Elapsed
        _Rstring
        _FormatSeconds
    ))
)
unuseNamespace("ycSubProcess")

; END
