unless(findNamespace("ycIO")
    makeNamespace("ycIO")
)
addToNamespace("ycIO"
    mapcar('symbolToString '(
        ; port.il
        _PortData  ; class
        Port  ; class
        _PortName  ; proc
        _InstallPort  ; proc
        Open  ; proc
    ))
)
unuseNamespace("ycIO")

; END
