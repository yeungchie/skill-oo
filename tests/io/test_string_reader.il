let((r line a b c p)
    ; --- construction / readLine / close ---
    r = ycIO::FromString("a\nb\n")
    _Assert(className(r) == 'ycIO::StringPort
        "string reader: FromString returns StringPort")
    _Assert(r->isClosed() == nil
        "string reader: starts open")
    _Assert(r->readLine() == "a\n"
        "string reader: readLine keeps newline")
    _Assert(r->readLine() == "b\n"
        "string reader: readLine second line")
    _Assert(r->readLine() == nil
        "string reader: readLine EOF returns nil")
    r->close()
    _Assert(r->isClosed()
        "string reader: close marks closed")
    _Assert(r->close() == t
        "string reader: close is idempotent")
    _AssertError(lambda(() r->readLine())
        "string reader: closed readLine errors")
    _AssertError(lambda(() r->readAll())
        "string reader: closed readAll errors")
    _AssertError(lambda(() r->fscanf("%d" list('a)))
        "string reader: closed fscanf errors")
    _AssertError(lambda(() r->seek(0))
        "string reader: closed seek errors")
    _AssertError(lambda(() r->tell())
        "string reader: closed tell errors")

    ; --- readAll / empty ---
    r = ycIO::FromString("a\nb\n")
    _Assert(r->readAll() == "a\nb\n"
        "string reader: readAll returns full text")
    _Assert(r->readAll() == ""
        "string reader: readAll at EOF returns empty string")
    _Assert(r->tell() == 4
        "string reader: tell at EOF is content length")
    r->close()

    r = ycIO::FromString("")
    _Assert(r->readAll() == ""
        "string reader: empty input returns empty string")
    _Assert(r->readLine() == nil
        "string reader: empty input has EOF")
    r->close()

    ; --- fscanf ---
    r = ycIO::FromString("10 20 hello\nsecond\n")
    _Assert(r->fscanf("%d %d %s" list('a 'b 'c)) == 3
        "string reader: fscanf reports item count")
    _Assert(a == 10 && b == 20 && c == "hello"
        "string reader: fscanf fills variables")
    _Assert(r->fscanf("%d" list('a)) == 0
        "string reader: fscanf mismatch returns zero")
    _AssertError(lambda(() r->fscanf("%d" "a"))
        "string reader: fscanf variables must be a list")
    _AssertError(lambda(() r->fscanf("%d" list("a")))
        "string reader: fscanf variables must be symbols")
    _AssertError(lambda(() r->fscanf("%q" list('a)))
        "string reader: invalid fscanf format errors")
    r->close()

    ; --- seek / tell before EOF ---
    r = ycIO::FromString("abcdef\nghij")
    _Assert(r->tell() == 0
        "string reader: tell starts at zero")
    _Assert(r->readLine() == "abcdef\n"
        "string reader: readLine before seek")
    _Assert(r->tell() == 7
        "string reader: tell advances after readLine")
    _Assert(r->seek(2 ?whence 1) == t
        "string reader: current-relative seek")
    _Assert(r->tell() == 9
        "string reader: tell after current-relative seek")
    _Assert(r->readLine() == "ij"
        "string reader: readLine after current-relative seek")
    _Assert(r->seek(2) == t
        "string reader: absolute seek succeeds")
    _Assert(r->tell() == 2
        "string reader: tell after absolute seek")
    _Assert(r->readLine() == "cdef\n"
        "string reader: readLine after seek")
    _Assert(r->seek(-1 ?whence 2) == t
        "string reader: end-relative seek succeeds")
    _Assert(r->readLine() == "j"
        "string reader: readLine after end seek")
    _Assert(r->seek(999) == nil
        "string reader: out-of-range seek returns nil")
    _AssertError(lambda(() r->seek(0 ?whence 3))
        "string reader: invalid whence errors")
    r->close()

    ; --- seek after EOF ---
    r = ycIO::FromString("abc")
    _Assert(r->readAll() == "abc"
        "string reader: EOF block readAll")
    _Assert(r->tell() == 3
        "string reader: tell at EOF is length")
    _Assert(r->seek(0) == t
        "string reader: seek after EOF succeeds")
    _Assert(r->readLine() == "abc"
        "string reader: readLine after EOF seek")
    _Assert(r->seek(-1 ?whence 2) == t
        "string reader: end seek after EOF")
    _Assert(r->readLine() == "c"
        "string reader: readLine after end seek")
    _Assert(r->readAll() == ""
        "string reader: readAll at EOF after seek")
    _Assert(r->seek(-2 ?whence 1) == t
        "string reader: current-relative seek after EOF")
    _Assert(r->readLine() == "bc"
        "string reader: readLine after current-relative seek")
    _Assert(r->readAll() == ""
        "string reader: readAll reaches EOF again")
    _Assert(r->seek(99) == nil
        "string reader: invalid seek after EOF returns nil")
    _Assert(r->tell() == 3
        "string reader: failed seek keeps EOF position")
    r->close()

    ; --- fscanf EOF then seek ---
    r = ycIO::FromString("10")
    _Assert(r->fscanf("%d" list('a)) == 1
        "string reader: fscanf before EOF")
    _Assert(r->fscanf("%d" list('a)) == nil
        "string reader: fscanf at EOF returns nil")
    _Assert(r->tell() == 2
        "string reader: tell at EOF after fscanf")
    _Assert(r->seek(0) == t
        "string reader: seek after fscanf EOF")
    _Assert(r->fscanf("%d" list('a)) == 1
        "string reader: fscanf after EOF seek")
    r->close()

    ; --- direction / escape hatch ---
    r = ycIO::FromString("x")
    _AssertError(lambda(() r->write("x"))
        "string reader: write on reader errors")
    _AssertErrorMsg(lambda(() r->text()) "only available on a string writer"
        "string reader: text on reader reports writer-only method")
    _Assert(r->flush() == r
        "string reader: flush returns self")
    p = r->port()
    _Assert(inportp(p)
        "string reader: port is an input port")
    r->close()

    ; --- ycWith ---
    let((holder)
        ycWith(r2 ycIO::FromString("with\n")
            holder = r2
            _Assert(r2->readLine() == "with\n"
                "string reader: ycWith reads inside scope")
        )
        _Assert(holder->isClosed()
            "string reader: ycWith closes on normal exit")
    )

    let((holder2)
        errset(ycWith(r3 ycIO::FromString("x")
            holder2 = r3
            error("forced reader error")
        ) nil)
        _Assert(holder2->isClosed()
            "string reader: ycWith closes on error exit")
    )

    ; --- constructor type errors ---
    _AssertError(lambda(() ycIO::FromString(nil))
        "string reader: nil input errors")
    _AssertError(lambda(() ycIO::FromString(42))
        "string reader: non-string input errors")
)

_TestChildDone = t

; END
