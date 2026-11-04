let((t_tmp)

t_tmp = "ycIOTmpTest"
system(strcat("rm -rf " t_tmp))
system(strcat("mkdir -p " t_tmp))

; --- open / write / close ---
let((g_p)
    g_p = ycIO::Open(_IOTmp("round.txt") ?mode "w")
    _Assert(className(g_p) == 'ycIO::Port  "open: returns ycIO::Port")
    _Assert(g_p->isClosed() == nil  "open: starts open")
    g_p->write("hello\n")->write("world\n")
    _Assert(g_p->isClosed() == nil  "write: keeps port open")
    g_p->close()
    _Assert(g_p->isClosed()  "close: marks closed")
    _Assert(g_p->close() == t  "close: idempotent")
    _Assert(ycPathLib::Path(_IOTmp("round.txt"))->readText() == "hello\nworld\n"
        "write: roundtrip keeps content")

    g_p = ycIO::Open(_IOTmp("round.txt") ?mode "a")
    g_p->write("tail")
    g_p->close()
    _Assert(ycPathLib::Path(_IOTmp("round.txt"))->readText() == "hello\nworld\ntail"
        "open: append mode adds content")
)

; --- readLine / readAll ---
let((g_p)
    g_p = ycIO::Open(_IOTmp("round.txt"))
    _Assert(g_p->readLine() == "hello\n"  "readLine: first line keeps newline")
    _Assert(g_p->readLine() == "world\n"  "readLine: second line")
    g_p->close()

    g_p = ycIO::Open(_IOTmp("round.txt"))
    _Assert(g_p->readAll() == "hello\nworld\ntail"  "readAll: reads to EOF")
    _Assert(g_p->readLine() == nil  "readLine: EOF returns nil")
    g_p->close()

    g_p = ycIO::Open(_IOTmp("empty.txt") ?mode "w")
    g_p->close()
    g_p = ycIO::Open(_IOTmp("empty.txt"))
    _Assert(g_p->readAll() == ""  "readAll: empty file returns empty string")
    g_p->close()
)

; --- native port escape hatch ---
let((g_p)
    g_p = ycIO::Open(_IOTmp("round.txt"))
    _Assert(g_p->port() != nil  "port: returns the native port")
    g_p->close()
)

; --- operations after close ---
let((g_p)
    g_p = ycIO::Open(_IOTmp("round.txt"))
    g_p->close()
    _AssertErrorMsg(lambda(() g_p->readLine())  "port is closed"
        "readLine: closed port errors")
    _AssertErrorMsg(lambda(() g_p->readAll())  "port is closed"
        "readAll: closed port errors")
    _AssertErrorMsg(lambda(() g_p->write("x"))  "port is closed"
        "write: closed port errors")
)

; --- with protocol ---
let((g_p)
    g_p = ycIO::Open(_IOTmp("with.txt") ?mode "w")
    ycWith(p g_p
        p->write("with")
    )
    _Assert(g_p->isClosed()  "with: closes on normal return")
    _Assert(ycPathLib::Path(_IOTmp("with.txt"))->readText() == "with"
        "with: written content is flushed")
)

let((g_p res)
    g_p = ycIO::Open(_IOTmp("with2.txt") ?mode "w")
    res = errset(ycWith(p g_p
            p->write("before")
            error("io probe: body failure")
        ) nil)
    _Assert(res == nil  "with: body error propagates")
    _Assert(g_p->isClosed()  "with: closes on body error")
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

system(strcat("rm -rf " t_tmp))

)  ; end let

_TestChildDone = t

; END
