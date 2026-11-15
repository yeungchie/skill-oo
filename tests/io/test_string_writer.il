let((w a)
    ; --- construction / write / text ---
    w = ycIO::ToString()
    _Assert(className(w) == 'ycIO::StringPort
        "string writer: ToString returns StringPort")
    _Assert(w->isClosed() == nil
        "string writer: starts open")
    _Assert(w->text() == ""
        "string writer: empty text")
    _Assert(w->write("a") == w
        "string writer: write returns self")
    w->write("b")->write("c")
    _Assert(w->text() == "abc"
        "string writer: text after writes")
    _Assert(w->tell() == 3
        "string writer: tell after writes")
    _Assert(w->flush() == w
        "string writer: flush returns self")
    w->close()
    _Assert(w->isClosed()
        "string writer: close marks closed")
    _Assert(w->close() == t
        "string writer: close is idempotent")
    _Assert(w->text() == "abc"
        "string writer: text survives close")
    _AssertError(lambda(() w->write("x"))
        "string writer: write after close errors")
    _AssertError(lambda(() w->seek(0))
        "string writer: seek after close errors")
    _AssertError(lambda(() w->tell())
        "string writer: tell after close errors")

    ; --- random access writes ---
    w = ycIO::ToString()
    w->write("abc")
    _Assert(w->seek(0) == t
        "string writer: absolute seek")
    w->write("XY")
    _Assert(w->text() == "XYc"
        "string writer: overwrite keeps tail")
    _Assert(w->tell() == 2
        "string writer: tell after overwrite")
    _Assert(w->seek(1) == t
        "string writer: backward seek")
    w->write("Z")
    _Assert(w->text() == "XZc"
        "string writer: backward overwrite")
    _Assert(w->seek(2) == t
        "string writer: seek at current position is a no-op")
    _Assert(w->seek(3) == nil
        "string writer: forward seek returns nil")
    _Assert(w->tell() == 2
        "string writer: failed forward seek keeps position")
    w->write("D")
    _Assert(w->text() == "XZD"
        "string writer: write at current position")
    _Assert(w->seek(9) == nil
        "string writer: seek beyond end returns nil")
    w->write("E")
    _Assert(w->text() == "XZDE"
        "string writer: failed seek keeps write position")
    w->close()

    ; --- direction / whence errors ---
    w = ycIO::ToString()
    _AssertError(lambda(() w->readLine())
        "string writer: readLine on writer errors")
    _AssertError(lambda(() w->readAll())
        "string writer: readAll on writer errors")
    _AssertError(lambda(() w->fscanf("%d" list('a)))
        "string writer: fscanf on writer errors")
    _AssertError(lambda(() w->seek(0 ?whence 1))
        "string writer: relative seek errors")
    _AssertError(lambda(() w->seek(0 ?whence 2))
        "string writer: end-relative seek errors")
    _AssertError(lambda(() w->seek(0 ?whence 3))
        "string writer: invalid whence errors")
    _Assert(outportp(w->port())
        "string writer: port is an output port")
    w->close()

    ; --- empty writer / UTF-8 ---
    w = ycIO::ToString()
    w->close()
    _Assert(w->text() == ""
        "string writer: empty writer text after close")

    w = ycIO::ToString()
    w->write("版图\n")
    _Assert(length(w->text()) == 7
        "string writer: UTF-8 length is byte length")
    _Assert(w->text() == "版图\n"
        "string writer: UTF-8 text round-trips")
    w->close()

    ; --- ycWith retains text ---
    let((holder)
        ycWith(w2 ycIO::ToString()
            holder = w2
            w2->write("with")
        )
        _Assert(holder->text() == "with"
            "string writer: ycWith keeps text after close")
        _Assert(holder->isClosed()
            "string writer: ycWith closes on normal exit")
    )

    let((holder2)
        errset(ycWith(w3 ycIO::ToString()
            holder2 = w3
            w3->write("before")
            error("forced writer error")
        ) nil)
        _Assert(holder2->text() == "before"
            "string writer: ycWith keeps text on error exit")
        _Assert(holder2->isClosed()
            "string writer: ycWith closes on error exit")
    )

    ; --- constructor arguments ---
    _AssertError(lambda(() ycIO::ToString(1))
        "string writer: ToString takes no arguments")
)

_TestChildDone = t

; END
