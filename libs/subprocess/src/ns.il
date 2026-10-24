unless(findNamespace("ycSubProcess")
    makeNamespace("ycSubProcess")
)
addToNamespace("ycSubProcess"
    mapcar('symbolToString '(
        Stream
        AsyncJob
        Run
        CreateJob
        Elapsed
        _Rstring
        _FormatSeconds
    ))
)
unuseNamespace("ycSubProcess")

; END
