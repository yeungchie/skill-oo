unless(findNamespace("ycQueue")
    makeNamespace("ycQueue")
)
addToNamespace("ycQueue"
    mapcar('symbolToString '(
        ; queue.il
        _EmptyResult  ; proc
        _Position  ; proc
        _NoneArg  ; var

        ; fifo.il
        _FIFOData  ; class
        FIFO  ; proc, class

        ; lifo.il
        _LIFOData  ; class
        LIFO  ; proc, class
    ))
)
unuseNamespace("ycQueue")

; END
