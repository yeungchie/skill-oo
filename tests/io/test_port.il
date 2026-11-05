let((tmp)

tmp = "ycIOTmpTest"
system(strcat("rm -rf " tmp))
system(strcat("mkdir -p " tmp))

; --- open / write / close ---
let((p2)
    p2 = ycIO::Open(_IOTmp("round.txt") ?mode "w")
    _Assert(className(p2) == 'ycIO::Port  "open: returns ycIO::Port")
    _Assert(p2->isClosed() == nil  "open: starts open")
    p2->write("hello\n")->write("world\n")
    _Assert(p2->isClosed() == nil  "write: keeps port open")
    p2->close()
    _Assert(p2->isClosed()  "close: marks closed")
    _Assert(p2->close() == t  "close: idempotent")
    _Assert(ycPathLib::Path(_IOTmp("round.txt"))->readText() == "hello\nworld\n"
        "write: roundtrip keeps content")

    p2 = ycIO::Open(_IOTmp("round.txt") ?mode "a")
    p2->write("tail")
    p2->close()
    _Assert(ycPathLib::Path(_IOTmp("round.txt"))->readText() == "hello\nworld\ntail"
        "open: append mode adds content")
)

; --- readLine / readAll ---
let((p2)
    p2 = ycIO::Open(_IOTmp("round.txt"))
    _Assert(p2->readLine() == "hello\n"  "readLine: first line keeps newline")
    _Assert(p2->readLine() == "world\n"  "readLine: second line")
    p2->close()

    p2 = ycIO::Open(_IOTmp("round.txt"))
    _Assert(p2->readAll() == "hello\nworld\ntail"  "readAll: reads to EOF")
    _Assert(p2->readLine() == nil  "readLine: EOF returns nil")
    p2->close()

    p2 = ycIO::Open(_IOTmp("empty.txt") ?mode "w")
    p2->close()
    p2 = ycIO::Open(_IOTmp("empty.txt"))
    _Assert(p2->readAll() == ""  "readAll: empty file returns empty string")
    p2->close()
)

; --- native port escape hatch ---
let((p2)
    p2 = ycIO::Open(_IOTmp("round.txt"))
    _Assert(p2->port() != nil  "port: returns the native port")
    p2->close()
)

; --- operations after close ---
let((p2)
    p2 = ycIO::Open(_IOTmp("round.txt"))
    p2->close()
    _AssertErrorMsg(lambda(() p2->readLine())  "port is closed"
        "readLine: closed port errors")
    _AssertErrorMsg(lambda(() p2->readAll())  "port is closed"
        "readAll: closed port errors")
    _AssertErrorMsg(lambda(() p2->write("x"))  "port is closed"
        "write: closed port errors")
)

; --- with protocol ---
let((p2)
    p2 = ycIO::Open(_IOTmp("with.txt") ?mode "w")
    ycWith(p p2
        p->write("with")
    )
    _Assert(p2->isClosed()  "with: closes on normal return")
    _Assert(ycPathLib::Path(_IOTmp("with.txt"))->readText() == "with"
        "with: written content is flushed")
)

let((p2 res)
    p2 = ycIO::Open(_IOTmp("with2.txt") ?mode "w")
    res = errset(ycWith(p p2
            p->write("before")
            error("io probe: body failure")
        ) nil)
    _Assert(res == nil  "with: body error propagates")
    _Assert(p2->isClosed()  "with: closes on body error")
    _Assert(ycPathLib::Path(_IOTmp("with2.txt"))->readText() == "before"
        "with: content before the error is flushed")
)

; --- errors ---
_AssertErrorMsg(lambda(() ycIO::Open(_IOTmp("x.txt") ?mode "b"))  "invalid mode"
    "open: invalid mode errors")
_AssertErrorMsg(lambda(() ycIO::Open(_IOTmp("missing.txt")))  "cannot open"
    "open: missing file errors")
_AssertErrorMsg(lambda(() ycIO::Open(42))  "should be a string"
    "open: non-string path rejected")
_AssertErrorMsg(lambda(() ycIO::Open(_IOTmp("x.txt") ?mode 42))  "should be a string"
    "open: non-string mode rejected")

system(strcat("rm -rf " tmp))

)  ; end let

_TestChildDone = t

; END
