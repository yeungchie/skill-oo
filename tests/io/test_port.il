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

; --- flush ---
let((p2 r)
    p2 = ycIO::Open(_IOTmp("flush.txt") ?mode "w")
    p2->write("hello")
    _Assert(car(errset(p2->flush() nil)) == p2  "flush: returns the port itself")
    r = ycIO::Open(_IOTmp("flush.txt"))
    _Assert(r->readAll() == "hello"  "flush: makes buffered content visible")
    _Assert(car(errset(r->flush() nil)) == r  "flush: read port is a no-op")
    r->close()
    p2->close()
)
let((p2)
    p2 = ycIO::Open(_IOTmp("flush.txt"))
    p2->close()
    _AssertErrorMsg(lambda(() p2->flush())  "port is closed"  "flush: closed port errors")
)

; --- close error path ---
let((p2 res)
    p2 = ycIO::Open("/dev/full" ?mode "w")
    p2->write("x")
    res = errset(p2->close() nil)
    _Assert(res == nil && errset.errset  "close: /dev/full reports an error")
    _Assert(p2->isClosed()  "close: state reset even when native close fails")
    _Assert(p2->close() == t  "close: idempotent after a failed close")
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

; --- fscanf / seek / tell ---
let((p2 a b c)
    p2 = ycIO::Open(_IOTmp("seek.txt") ?mode "w")
    p2->write("10 20 hello\nsecond\n")->close()

    p2 = ycIO::Open(_IOTmp("seek.txt"))
    _Assert(p2->tell() == 0  "seek: tell starts at zero")
    _Assert(p2->fscanf("%d %d %s" list('a 'b 'c)) == 3
        "fscanf: reports item count")
    _Assert(a == 10 && b == 20 && c == "hello"
        "fscanf: fills variables")
    _Assert(p2->tell() == 11  "seek: tell after fscanf")
    _Assert(p2->seek(3 ?whence 1) == t  "seek: current-relative seek")
    _Assert(p2->tell() == 14  "seek: tell after current-relative seek")
    _Assert(p2->readLine() == "cond\n"
        "seek: readLine after current-relative seek")
    _Assert(p2->seek(0) == t  "seek: absolute seek")
    _Assert(p2->readLine() == "10 20 hello\n"
        "seek: readLine after seek")
    _Assert(p2->seek(-1 ?whence 2) == t  "seek: end-relative seek")
    _Assert(p2->readLine() == "\n"  "seek: readLine after end seek")
    _Assert(p2->seek(999) == t  "seek: native file seek beyond end succeeds")
    _Assert(p2->tell() == 999  "seek: tell beyond end")
    _Assert(p2->readLine() == nil  "seek: read after beyond-end seek is EOF")
    _AssertError(lambda(() p2->seek(0 ?whence 3))
        "seek: invalid whence errors")
    _AssertError(lambda(() p2->seek("0"))
        "seek: non-integer offset rejected")
    _AssertError(lambda(() p2->fscanf("%d" "a"))
        "fscanf: variables must be a list")
    _AssertError(lambda(() p2->fscanf("%d" list("a")))
        "fscanf: variables must be symbols")
    _AssertError(lambda(() p2->fscanf("%q" list('a)))
        "fscanf: invalid format errors")
    p2->close()

    p2 = ycIO::Open(_IOTmp("seek.txt") ?mode "w")
    _AssertError(lambda(() p2->fscanf("%d" list('a)))
        "fscanf: writer errors")
    _AssertError(lambda(() p2->readLine())  "readLine: writer errors")
    _AssertError(lambda(() p2->readAll())  "readAll: writer errors")
    _Assert(p2->seek(0) == t  "seek: writer absolute seek")
    _Assert(p2->tell() == 0  "tell: writer position")
    p2->close()

    p2 = ycIO::Open(_IOTmp("seek.txt"))
    _AssertError(lambda(() p2->write("x"))  "write: reader errors")
    p2->close()

    p2 = ycIO::Open(_IOTmp("seek.txt"))
    p2->close()
    _AssertError(lambda(() p2->seek(0))  "seek: closed port errors")
    _AssertError(lambda(() p2->tell())  "tell: closed port errors")
    _AssertError(lambda(() p2->fscanf("%d" list('a)))
        "fscanf: closed port errors")
)

; --- errors ---
_AssertErrorMsg(lambda(() ycIO::Open(_IOTmp("x.txt") ?mode "b"))  "invalid mode"
    "open: invalid mode errors")
_AssertErrorMsg(lambda(() ycIO::Open(_IOTmp("missing.txt")))  "cannot open"
    "open: missing file errors")
_AssertErrorMsg(lambda(() ycIO::Open(_IOTmp("")))  "is a directory"
    "open: directory rejected")
_AssertErrorMsg(lambda(() ycIO::Open(""))  "empty path"
    "open: empty path rejected")
_AssertErrorMsg(lambda(() ycIO::Open(42))  "should be a string"
    "open: non-string path rejected")
_AssertErrorMsg(lambda(() ycIO::Open(_IOTmp("x.txt") ?mode 42))  "should be a string"
    "open: non-string mode rejected")

system(strcat("rm -rf " tmp))

)  ; end let

_TestChildDone = t

; END
