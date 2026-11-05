;--------------------------
; Program  : ycIni tests(test_encode.il)
; Language : Cadence Skill
;--------------------------

let((v tbl out)
    v = _Table()
    _Assert(ycIni::Encode(v) == ""  "encode: empty root")

    v["a"] = "1"
    _Assert(ycIni::Encode(v) == "a = 1\n"  "encode: root scalar")
    v["a"] = ""
    _Assert(ycIni::Encode(v) == "a = \n"  "encode: empty value")

    v = _Table()
    v["a"] = _Table()
    _Assert(ycIni::Encode(v) == "[a]\n"  "encode: empty section")

    v["a"]["b"] = "1"
    _Assert(ycIni::Encode(v) == "[a]\nb = 1\n"  "encode: section scalar")

    v = _Table()
    v["title"] = "x"
    v["server"] = _Table()
    v["server"]["host"] = "h"
    _Assert(ycIni::Encode(v) == "title = x\n\n[server]\nhost = h\n"  "encode: root before section")

    v = _Table()
    v["z"] = _Table()
    v["z"]["b"] = "2"
    v["z"]["a"] = "1"
    v["a"] = _Table()
    v["a"]["k"] = "v"
    out = ycIni::Encode(v ?sortKeys t)
    _Assert(out == "[a]\nk = v\n\n[z]\na = 1\nb = 2\n"  "encode: sorted sections and section keys")

    v = _Table()
    v["z"] = "1"
    v["a"] = "2"
    v["b"] = _Table()
    v["b"]["k"] = "v"
    v["m"] = _Table()
    v["m"]["z"] = "1"
    v["m"]["a"] = "2"
    _Assert(ycIni::Encode(v ?sortKeys t) == "a = 2\nz = 1\n\n[b]\nk = v\n\n[m]\na = 2\nz = 1\n"  "encode: root scalars sorted before sections")

    v = _Table()
    v["s"] = "text"
    v["n"] = 42
    v["f"] = 1.5
    v["t"] = t
    v["tt"] = ycCodec::True
    v["ff"] = ycCodec::False
    v["sym"] = 'sym
    v["z"] = nil
    _Assert(ycIni::Encode(v ?sortKeys t) == "f = 1.5\nff = false\nn = 42\ns = text\nsym = sym\nt = true\ntt = true\nz = \n"  "encode: scalar types")

    v = _Table()
    v["neg"] = -3
    v["real"] = -0.5
    v["one"] = 1.0
    _Assert(ycIni::Encode(v ?sortKeys t) == "neg = -3\none = 1\nreal = -0.5\n"  "encode: numbers")

    v = _Table()
    v['sym] = "v"
    v[7] = "x"
    _Assert(ycIni::Encode(v ?sortKeys t) == "7 = x\nsym = v\n"  "encode: symbol and fixnum keys")

    v = _Table()
    v["s"] = "v"
    _Assert(ycIni::Encode(v ?strict t) == "s = v\n"  "encode: strict accepts string keys")
    v['sym] = "v"
    _AssertError(lambda(() ycIni::Encode(v ?strict t))  "encode: strict rejects symbol keys")

    v = _Table()
    v["a=b"] = "v"
    _AssertError(lambda(() ycIni::Encode(v))  "encode: delimiter in key errors")
    _Assert(ycIni::Encode(v ?delimiter ":") == "a=b : v\n"  "encode: custom delimiter")
    v = _Table()
    v["a"] = "x:y"
    _Assert(ycIni::Encode(v ?delimiter ":") == "a : x:y\n"  "encode: custom delimiter in value")
    v = _Table()
    v["a"] = "x=y"
    _Assert(ycIni::Encode(v) == "a = x=y\n"  "encode: delimiter in value")

    v = _Table()
    v["a"] = list(1 2)
    _AssertError(lambda(() ycIni::Encode(v))  "encode: list value errors")
    v = _Table()
    v["a"] = _Table()
    v["a"]["b"] = _Table()
    _AssertError(lambda(() ycIni::Encode(v))  "encode: nested table errors")
    v["a"] = ycCodec::Null
    _AssertError(lambda(() ycIni::Encode(v))  "encode: Null errors")
    v["a"] = ycCodec::Missing
    _AssertError(lambda(() ycIni::Encode(v))  "encode: Missing errors")

    _AssertError(lambda(() ycIni::Encode("x"))  "encode: non-table root errors")
    _AssertError(lambda(() ycIni::Encode(nil))  "encode: nil root errors")
    _AssertError(lambda(() ycIni::Encode(list(1)))  "encode: list root errors")

    v = _Table()
    v[""] = "v"
    _AssertError(lambda(() ycIni::Encode(v))  "encode: empty key errors")
    v = _Table()
    v[" a"] = "v"
    _AssertError(lambda(() ycIni::Encode(v))  "encode: leading whitespace key errors")
    v = _Table()
    v["a\t"] = "v"
    _AssertError(lambda(() ycIni::Encode(v))  "encode: trailing tab key errors")
    v = _Table()
    v["a\nb"] = "v"
    _AssertError(lambda(() ycIni::Encode(v))  "encode: newline key errors")
    v = _Table()
    v["#a"] = "v"
    _AssertError(lambda(() ycIni::Encode(v))  "encode: hash-leading key errors")
    v = _Table()
    v[";a"] = "v"
    _AssertError(lambda(() ycIni::Encode(v))  "encode: semicolon-leading key errors")
    v = _Table()
    v["[a"] = "v"
    _AssertError(lambda(() ycIni::Encode(v))  "encode: bracket-leading key errors")

    v = _Table()
    v["a"] = _Table()
    v["a"][""] = "v"
    _AssertError(lambda(() ycIni::Encode(v))  "encode: empty section key errors")
    v = _Table()
    v[" a"] = _Table()
    _AssertError(lambda(() ycIni::Encode(v))  "encode: leading whitespace section name errors")
    v = _Table()
    v["a[b"] = _Table()
    _AssertError(lambda(() ycIni::Encode(v))  "encode: bracket section name errors")
    v = _Table()
    v["a]b"] = _Table()
    _AssertError(lambda(() ycIni::Encode(v))  "encode: closing bracket section name errors")
    v = _Table()
    v["a\nb"] = _Table()
    _AssertError(lambda(() ycIni::Encode(v))  "encode: control section name errors")

    v = _Table()
    v["a"] = "x"
    v['a] = "y"
    _AssertError(lambda(() ycIni::Encode(v))  "encode: root scalar key collision errors")
    v = _Table()
    v["a"] = "x"
    v['a] = _Table()
    _AssertError(lambda(() ycIni::Encode(v))  "encode: scalar and section key collision errors")
    v = _Table()
    v["a"] = _Table()
    v["a"]["k"] = "1"
    v["a"]['k] = "2"
    _AssertError(lambda(() ycIni::Encode(v))  "encode: section key collision errors")

    v = _Table()
    v["a"] = "1"
    _Assert(ycIni::Encode(v ?finalNewline nil) == "a = 1"  "encode: finalNewline nil scalar")
    v["a"] = _Table()
    _Assert(ycIni::Encode(v ?finalNewline nil) == "[a]"  "encode: finalNewline nil section")
    v = _Table()
    _Assert(ycIni::Encode(v ?finalNewline nil) == ""  "encode: finalNewline nil empty root")

    v = ycIni::Decode("s = x\n[one]\na = 1\n[two]\nb = 2\n")
    out = ycIni::Encode(v ?sortKeys t)
    v = ycIni::Decode(out)
    _Assert(v["s"] == "x"  "encode/decode: root roundtrip")
    _Assert(v["one"]["a"] == "1"  "encode/decode: first section roundtrip")
    _Assert(v["two"]["b"] == "2"  "encode/decode: second section roundtrip")

    v = _Table()
    v["名字"] = "值"
    v["quote"] = "\"x\""
    v["slash"] = "C:\\Users\\name"
    v["mark"] = "# ; ="
    out = ycIni::Encode(v ?sortKeys t)
    v = ycIni::Decode(out)
    _Assert(v["名字"] == "值"  "encode/decode: unicode roundtrip")
    _Assert(v["quote"] == "\"x\""  "encode/decode: quote roundtrip")
    _Assert(v["slash"] == "C:\\Users\\name"  "encode/decode: backslash roundtrip")
    _Assert(v["mark"] == "# ; ="  "encode/decode: marker characters roundtrip")

    _AssertErrorMsg(lambda(() ycIni::Encode("x")) "root value must be a table"  "encode: root error message")
    _AssertErrorMsg(lambda(() ycIni::Encode(_Table() ?delimiter " ")) "delimiter"  "encode: delimiter error message")
)
_TestChildDone = t

; END
