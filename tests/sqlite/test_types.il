let((db row blob)
    db = ycSQLite::Open(":memory:")
    db->execute("create table ty(n text, i integer, big integer, huge integer, r real, b blob, z text, e text);")
    db->execute(
        "insert into ty values (NULL, 1, 2147483648, 9223372036854775807, 1.2345678901234567, x'00ff', char(97,44,34,10,98), '');"
    )

    row = car(db->query("select * from ty;")->rows())
    _Assert(row->get("n") == nil
        "types: NULL maps to nil")
    _Assert(row->get("i") == 1
        "types: 32-bit integer maps to fixnum")
    _Assert(row->get("big") == "2147483648"
        "types: 64-bit integer maps to string")
    _Assert(row->get("huge") == "9223372036854775807"
        "types: 64-bit maximum maps to string")
    _Assert(row->get("r") > 1.2345 && row->get("r") < 1.2346
        "types: REAL maps to flonum")
    _Assert(row->get("z") == strcat("a,\"" intToChar(10) "b")
        "types: text preserves comma, quote and newline")
    _Assert(row->get("e") == ""
        "types: empty text stays empty")
    blob = row->get("b")
    _Assert(className(blob) == 'ycSQLite::Blob
        "types: BLOB maps to ycSQLite::Blob")
    _Assert(blob->hex() == "00FF"
        "types: BLOB preserves hexadecimal bytes")
    _AssertSameInts(blob->toList() list(0 255)
        "types: BLOB exposes byte values")
    _Assert(blob->size() == 2
        "types: BLOB size is byte length")

    _AssertError(lambda(() ycSQLite::Blob("0"))
        "types: odd-length BLOB hex errors")
    _AssertError(lambda(() ycSQLite::Blob("zz"))
        "types: invalid BLOB hex errors")
    db->close()
)

_TestChildDone = t

; END
