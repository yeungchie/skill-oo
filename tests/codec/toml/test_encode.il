;--------------------------
; Program  : ycToml tests(test_encode.il)
; Language : Cadence Skill
;--------------------------

let((t_v t_a t_b t_out)
    t_v = _table()
    _assert(ycToml::encode(t_v) == ""  "encode: empty root")

    t_v["b"] = 2
    t_v["a"] = 1
    _assert(ycToml::encode(t_v ?sortKeys t) == "a = 1\nb = 2\n"  "encode: sorted root scalars")

    t_v = _table()
    t_v["title"] = "x"
    t_v["server"] = _table()
    t_v["server"]["host"] = "h"
    t_v["server"]["tls"] = _table()
    t_v["server"]["tls"]["enabled"] = t
    _assert(ycToml::encode(t_v ?sortKeys t) == "title = \"x\"\n\n[server]\nhost = \"h\"\n\n[server.tls]\nenabled = true\n"  "encode: nested tables")

    t_v = _table()
    t_v["a"] = _table()
    _assert(ycToml::encode(t_v) == "[a]\n"  "encode: empty table")

    t_v["a"]["b"] = 1
    _assert(ycToml::encode(t_v) == "[a]\nb = 1\n"  "encode: table scalar")

    t_v = _table()
    t_a = _table()
    t_a["name"] = "Hammer"
    t_b = _table()
    t_b["name"] = "Nail"
    t_v["products"] = list(t_a t_b)
    _assert(ycToml::encode(t_v) == "[[products]]\nname = \"Hammer\"\n\n[[products]]\nname = \"Nail\"\n"  "encode: array of tables")

    t_v = _table()
    t_a = _table()
    t_b = _table()
    t_v["a"] = list(t_a t_b)
    t_a["b"] = _table()
    t_a["b"]["y"] = 2
    t_b["b"] = _table()
    t_b["b"]["y"] = 4
    _assert(ycToml::encode(t_v) == "[[a]]\n\n[a.b]\ny = 2\n\n[[a]]\n\n[a.b]\ny = 4\n"  "encode: subtable of array element")

    t_v = ycToml::decode("[[fruits]]\nname = \"apple\"\n[fruits.physical]\ncolor = \"red\"\n[[fruits.varieties]]\nname = \"red\"\n[[fruits]]\nname = \"banana\"\n")
    t_out = ycToml::encode(t_v ?sortKeys t)
    t_v = ycToml::decode(t_out)
    _assert(length(t_v["fruits"]) == 2  "encode/decode: nested array table count")
    _assert(car(t_v["fruits"])["physical"]["color"] == "red"  "encode/decode: nested array table subtable")
    _assert(car(car(t_v["fruits"])["varieties"])["name"] == "red"  "encode/decode: nested array table element")

    t_v = _table()
    t_v["a"] = list(1 2)
    t_v["b"] = list(list(1) list(2 3))
    _assert(ycToml::encode(t_v ?sortKeys t) == "a = [1, 2]\nb = [[1], [2, 3]]\n"  "encode: arrays")

    t_v = _table()
    t_v["a"] = list(1 _table())
    _assert(ycToml::encode(t_v) == "a = [1, {}]\n"  "encode: inline table in mixed array")

    t_v = _table()
    t_v["s"] = "a\"b\\c\n\t"
    _assert(ycToml::encode(t_v) == "s = \"a\\\"b\\\\c\\n\\t\"\n"  "encode: string escapes")

    t_v = ycToml::decode("s = \"\\u0001\"\n")
    _assert(ycToml::encode(t_v) == "s = \"\\u0001\"\n"  "encode: control byte escape")

    t_v = ycToml::decode("s = \"\\u007F\"\n")
    _assert(ycToml::encode(t_v) == "s = \"\\u007f\"\n"  "encode: DEL escape")

    t_v = _table()
    t_v["a"] = 1.0
    t_v["b"] = -0.0
    t_v["c"] = 5e+22
    t_v["d"] = 1
    _assert(ycToml::encode(t_v ?sortKeys t) == "a = 1.0\nb = -0.0\nc = 5e+22\nd = 1\n"  "encode: numbers")

    t_v = _table()
    t_v["inf"] = atof("inf")
    t_v["ninf"] = -atof("inf")
    t_v["nan"] = atof("nan")
    t_out = ycToml::encode(t_v)
    _assert(index(t_out "inf = inf\n")  "encode: inf")
    _assert(index(t_out "ninf = -inf\n")  "encode: negative inf")
    _assert(index(t_out "nan = nan\n")  "encode: nan")

    t_v = _table()
    t_v["a"] = nil
    t_v["b"] = t
    t_v["c"] = ycCodec:::True
    t_v["d"] = ycCodec:::False
    _assert(ycToml::encode(t_v ?sortKeys t) == "a = []\nb = true\nc = true\nd = false\n"  "encode: nil and booleans")

    t_v = _table()
    t_v["a.b"] = 1
    t_v["with space"] = 2
    t_v["-"] = 3
    t_v["123"] = 4
    t_v[""] = 5
    _assert(ycToml::encode(t_v ?sortKeys t) == "\"\" = 5\n- = 3\n123 = 4\n\"a.b\" = 1\n\"with space\" = 2\n"  "encode: quoted keys")

    t_v = _table()
    t_v["a\nb"] = 1
    t_v["q\"x"] = 2
    t_out = ycToml::encode(t_v ?sortKeys t)
    _assert(ycToml::decode(t_out)["a\nb"] == 1  "encode/decode: newline key")
    _assert(ycToml::decode(t_out)["q\"x"] == 2  "encode/decode: quote key")

    t_v = _table()
    t_v['sym] = 1
    _assert(ycToml::encode(t_v) == "sym = 1\n"  "encode: symbol key default")
    _assertError(lambda(() ycToml::encode(t_v ?strict t))  "encode: symbol key strict errors")

    t_v = _table()
    t_v['a] = 1
    t_v["a"] = 2
    _assertError(lambda(() ycToml::encode(t_v))  "encode: key collision errors")

    t_v = _table()
    t_v["d"] = "1979-05-27"
    _assert(ycToml::encode(t_v) == "d = \"1979-05-27\"\n"  "encode: date string stays quoted")

    t_v = _table()
    t_v["a"] = 1
    _assert(ycToml::encode(t_v ?finalNewline nil) == "a = 1"  "encode: finalNewline nil")

    t_v = _table()
    t_v["a"] = _table()
    t_v["a"]["b"] = _table()
    t_v["a"]["b"]["c"] = 1
    _assertError(lambda(() ycToml::encode(t_v ?maxDepth 1))  "encode: table depth limit")
    _assertError(lambda(() ycToml::encode(t_v ?maxDepth 0))  "encode: zero maxDepth errors")
    _assertError(lambda(() ycToml::encode(t_v ?maxDepth 1.5))  "encode: float maxDepth errors")

    t_v = _table()
    t_v["a"] = list(list(1))
    _assertError(lambda(() ycToml::encode(t_v ?maxDepth 1))  "encode: array depth limit")

    _assertError(lambda(() ycToml::encode("x"))  "encode: non-table root errors")
    _assertError(lambda(() ycToml::encode(nil))  "encode: nil root errors")
    _assertError(lambda(() ycToml::encode(list(1)))  "encode: list root errors")

    t_v = _table()
    t_v["n"] = ycCodec:::Null
    _assertError(lambda(() ycToml::encode(t_v))  "encode: Null errors")
    t_v["n"] = ycCodec:::Missing
    _assertError(lambda(() ycToml::encode(t_v))  "encode: Missing errors")
    t_v["n"] = 'foo
    _assertError(lambda(() ycToml::encode(t_v))  "encode: symbol value errors")

    t_v = _table()
    t_v["s"] = "值"
    t_v["n"] = 1
    t_v["arr"] = list(1 2)
    t_v["tbl"] = _table()
    t_v["tbl"]["x"] = t
    t_out = ycToml::encode(t_v)
    _assert(ycToml::decode(t_out)["s"] == "值"  "encode/decode: unicode roundtrip")
    _assert(ycToml::decode(t_out)["n"] == 1  "encode/decode: number roundtrip")
    _assert(ycToml::decode(t_out)["arr"] == list(1 2)  "encode/decode: array roundtrip")
    _assert(ycToml::decode(t_out)["tbl"]["x"] == ycCodec:::True  "encode/decode: table roundtrip")

    _assertErrorMsg(lambda(() ycToml::encode("x")) "root value must be a table"  "encode: root error message")
    _assertErrorMsg(lambda(() ycToml::encode(t_v ?maxDepth 0)) "maxDepth"  "encode: maxDepth error message")
)
_TestEncodeDone = t

; END
