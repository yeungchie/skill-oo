;--------------------------
; Program  : ycToml tests(test_encode.il)
; Language : Cadence Skill
;--------------------------

let((v a2 b out inner)
    v = _Table()
    _Assert(ycToml::Encode(v) == ""  "encode: empty root")

    v["b"] = 2
    v["a"] = 1
    _Assert(ycToml::Encode(v ?sortKeys t) == "a = 1\nb = 2\n"  "encode: sorted root scalars")

    v = _Table()
    v["title"] = "x"
    v["server"] = _Table()
    v["server"]["host"] = "h"
    v["server"]["tls"] = _Table()
    v["server"]["tls"]["enabled"] = t
    _Assert(ycToml::Encode(v ?sortKeys t) == "title = \"x\"\n\n[server]\nhost = \"h\"\n\n[server.tls]\nenabled = true\n"  "encode: nested tables")

    v = _Table()
    v["a"] = _Table()
    _Assert(ycToml::Encode(v) == "[a]\n"  "encode: empty table")

    v["a"]["b"] = 1
    _Assert(ycToml::Encode(v) == "[a]\nb = 1\n"  "encode: table scalar")

    v = _Table()
    a2 = _Table()
    a2["name"] = "Hammer"
    b = _Table()
    b["name"] = "Nail"
    v["products"] = list(a2 b)
    _Assert(ycToml::Encode(v) == "[[products]]\nname = \"Hammer\"\n\n[[products]]\nname = \"Nail\"\n"  "encode: array of tables")

    v = _Table()
    a2 = _Table()
    b = _Table()
    v["a"] = list(a2 b)
    a2["b"] = _Table()
    a2["b"]["y"] = 2
    b["b"] = _Table()
    b["b"]["y"] = 4
    _Assert(ycToml::Encode(v) == "[[a]]\n\n[a.b]\ny = 2\n\n[[a]]\n\n[a.b]\ny = 4\n"  "encode: subtable of array element")

    v = ycToml::Decode("[[fruits]]\nname = \"apple\"\n[fruits.physical]\ncolor = \"red\"\n[[fruits.varieties]]\nname = \"red\"\n[[fruits]]\nname = \"banana\"\n")
    out = ycToml::Encode(v ?sortKeys t)
    v = ycToml::Decode(out)
    _Assert(length(v["fruits"]) == 2  "encode/decode: nested array table count")
    _Assert(car(v["fruits"])["physical"]["color"] == "red"  "encode/decode: nested array table subtable")
    _Assert(car(car(v["fruits"])["varieties"])["name"] == "red"  "encode/decode: nested array table element")

    v = _Table()
    v["a"] = list(1 2)
    v["b"] = list(list(1) list(2 3))
    _Assert(ycToml::Encode(v ?sortKeys t) == "a = [1, 2]\nb = [[1], [2, 3]]\n"  "encode: arrays")

    v = _Table()
    v["a"] = list(1 _Table())
    _Assert(ycToml::Encode(v) == "a = [1, {}]\n"  "encode: inline table in mixed array")

    inner = _Table()
    inner['sym] = 1
    v = _Table()
    v["arr"] = list(1 inner)
    _Assert(ycToml::Encode(v) == "arr = [1, { sym = 1 }]\n"  "encode: inline table stringifies symbol keys")

    v = _Table()
    v["s"] = "a\"b\\c\n\t"
    _Assert(ycToml::Encode(v) == "s = \"a\\\"b\\\\c\\n\\t\"\n"  "encode: string escapes")

    v = ycToml::Decode("s = \"\\u0001\"\n")
    _Assert(ycToml::Encode(v) == "s = \"\\u0001\"\n"  "encode: control byte escape")

    v = ycToml::Decode("s = \"\\u007F\"\n")
    _Assert(ycToml::Encode(v) == "s = \"\\u007f\"\n"  "encode: DEL escape")

    v = _Table()
    v["s"] = strcat(intToChar(255))
    _AssertError(lambda(() ycToml::Encode(v))  "encode: invalid UTF-8 string errors")

    v = _Table()
    v["a"] = 1.0
    v["b"] = -0.0
    v["c"] = 5e+22
    v["d"] = 1
    _Assert(ycToml::Encode(v ?sortKeys t) == "a = 1.0\nb = -0.0\nc = 5e+22\nd = 1\n"  "encode: numbers")

    v = _Table()
    v["inf"] = atof("inf")
    v["ninf"] = -atof("inf")
    v["nan"] = atof("nan")
    out = ycToml::Encode(v)
    _Assert(index(out "inf = inf\n")  "encode: inf")
    _Assert(index(out "ninf = -inf\n")  "encode: negative inf")
    _Assert(index(out "nan = nan\n")  "encode: nan")

    v = _Table()
    v["a"] = nil
    v["b"] = t
    v["c"] = ycCodec::True
    v["d"] = ycCodec::False
    _Assert(ycToml::Encode(v ?sortKeys t) == "a = []\nb = true\nc = true\nd = false\n"  "encode: nil and booleans")

    v = _Table()
    v["a.b"] = 1
    v["with space"] = 2
    v["-"] = 3
    v["123"] = 4
    v[""] = 5
    _Assert(ycToml::Encode(v ?sortKeys t) == "\"\" = 5\n- = 3\n123 = 4\n\"a.b\" = 1\n\"with space\" = 2\n"  "encode: quoted keys")

    v = _Table()
    v["a\nb"] = 1
    v["q\"x"] = 2
    out = ycToml::Encode(v ?sortKeys t)
    _Assert(ycToml::Decode(out)["a\nb"] == 1  "encode/decode: newline key")
    _Assert(ycToml::Decode(out)["q\"x"] == 2  "encode/decode: quote key")

    v = _Table()
    v['sym] = 1
    _Assert(ycToml::Encode(v) == "sym = 1\n"  "encode: symbol key default")
    _AssertError(lambda(() ycToml::Encode(v ?strict t))  "encode: symbol key strict errors")

    v = _Table()
    v['a] = 1
    v["a"] = 2
    _AssertError(lambda(() ycToml::Encode(v))  "encode: key collision errors")

    v = _Table()
    v["d"] = "1979-05-27"
    _Assert(ycToml::Encode(v) == "d = \"1979-05-27\"\n"  "encode: date string stays quoted")

    v = _Table()
    v["a"] = 1
    _Assert(ycToml::Encode(v ?finalNewline nil) == "a = 1"  "encode: finalNewline nil")

    v = _Table()
    v["a"] = _Table()
    v["a"]["b"] = _Table()
    v["a"]["b"]["c"] = 1
    _AssertError(lambda(() ycToml::Encode(v ?maxDepth 1))  "encode: table depth limit")
    _AssertError(lambda(() ycToml::Encode(v ?maxDepth 0))  "encode: zero maxDepth errors")
    _AssertError(lambda(() ycToml::Encode(v ?maxDepth 1.5))  "encode: float maxDepth errors")

    v = _Table()
    v["a"] = list(list(1))
    _AssertError(lambda(() ycToml::Encode(v ?maxDepth 1))  "encode: array depth limit")
    v = _Table()
    a2 = _Table()
    v["a"] = list(a2)
    a2["b"] = list(_Table())
    _AssertError(lambda(() ycToml::Encode(v ?maxDepth 1))  "encode: empty array table depth limit")

    _AssertError(lambda(() ycToml::Encode("x"))  "encode: non-table root errors")
    _AssertError(lambda(() ycToml::Encode(nil))  "encode: nil root errors")
    _AssertError(lambda(() ycToml::Encode(list(1)))  "encode: list root errors")

    v = _Table()
    v["n"] = ycCodec::Null
    _AssertError(lambda(() ycToml::Encode(v))  "encode: Null errors")
    v["n"] = ycCodec::Missing
    _AssertError(lambda(() ycToml::Encode(v))  "encode: Missing errors")
    v["n"] = 'foo
    _AssertError(lambda(() ycToml::Encode(v))  "encode: symbol value errors")

    v = _Table()
    v["s"] = "值"
    v["n"] = 1
    v["arr"] = list(1 2)
    v["tbl"] = _Table()
    v["tbl"]["x"] = t
    out = ycToml::Encode(v)
    _Assert(ycToml::Decode(out)["s"] == "值"  "encode/decode: unicode roundtrip")
    _Assert(ycToml::Decode(out)["n"] == 1  "encode/decode: number roundtrip")
    _Assert(ycToml::Decode(out)["arr"] == list(1 2)  "encode/decode: array roundtrip")
    _Assert(ycToml::Decode(out)["tbl"]["x"] == ycCodec::True  "encode/decode: table roundtrip")

    _AssertErrorMsg(lambda(() ycToml::Encode("x")) "root value must be a table"  "encode: root error message")
    _AssertErrorMsg(lambda(() ycToml::Encode(v ?maxDepth 0)) "maxDepth"  "encode: maxDepth error message")
)
_TestChildDone = t

; END
