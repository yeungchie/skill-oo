procedure(_StartsOf(l_l "l")  ; -> list of int
    mapcar(lambda((m "g") m->start()) l_l)
)

procedure(_EndsOf(l_l "l")  ; -> list of int
    mapcar(lambda((m "g") m->end()) l_l)
)

_TestRun("ycRegEx" 292
    "test_core.il"
    "test_parity.il"
)

; END
