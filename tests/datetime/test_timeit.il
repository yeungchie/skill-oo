; ycTimeIt macro suite: wrapped-code timing as a DateTime duration.

; --- 1. returns a DateTime carrying the elapsed time ---
let((d)
    d = ycTimeIt(1 + 2)
    _Assert(0 <= d->epoch()  "timeit: epoch is non-negative")
    _Assert(0 <= d->nanos() && d->nanos() <= 999999999  "timeit: nanos are in range")
    _Assert(pcreMatchp("^[0-9]{9}$" d->format("%N"))  "timeit: %N shows nine digits")
)
_Assert(ycTimeIt(1 + 1)->epoch() == 0  "timeit: short body stays below one second")

; --- 2. body runs exactly once, in order ---
let((n)
    n = 0
    ycTimeIt(n = n + 1)
    _Assert(n == 1  "timeit: body runs once")
)
let((n)
    n = 0
    ycTimeIt(n = n + 1 n = n + 1 n = n + 1)
    _Assert(n == 3  "timeit: every body form runs once, in order")
)

; --- 3. body value is available through an assignment inside the body ---
let((n d)
    n = 0
    d = ycTimeIt(n = 42)
    _Assert(n == 42  "timeit: assignment inside the body is kept")
    _Assert(0 <= d->epoch()  "timeit: the measurement itself is still returned")
)

; --- 4. measurable durations ---
let((d)
    d = ycTimeIt(let((x)
        x = 0
        while(x < 50000
            x = x + 1
        )
    ))
    _Assert(0 < d->epoch() || 0 < d->nanos()  "timeit: a busy loop takes measurable time")
)

; --- 5. errors ---
_AssertError(lambda(() ycTimeIt(error("boom")) t)  "timeit: body errors propagate")
_AssertError(lambda(() ycTimeIt() t)  "timeit: empty body rejected")

_TestChildDone = t

; END
