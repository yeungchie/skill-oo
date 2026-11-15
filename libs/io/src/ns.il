unless(findNamespace("ycIO")
    makeNamespace("ycIO")
)
addToNamespace("ycIO"
    mapcar('symbolToString '(
        ; port.il
        _PortData  ; class
        Port  ; class
        _PortName  ; proc
        _ErrText  ; proc
        _PortError  ; proc
        _Fscanf  ; proc
        _Seek  ; proc
        _Tell  ; proc
        _InstallPort  ; proc
        Open  ; proc

        ; string.il
        _StringPortData  ; class
        StringPort  ; class
        _CheckStringPort  ; proc
        _MakeStringInputPort  ; proc
        _MakeStringOutputPort  ; proc
        _InstallStringPort  ; proc
        FromString  ; proc
        ToString  ; proc
    ))
)
unuseNamespace("ycIO")

; END
