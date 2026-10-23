;--------------------------
; Program  : ycIni tests(test_encode.il)
; Language : Cadence Skill
;--------------------------

let((t_v t_tbl t_out)
    t_v = _Table()
    _Assert(ycIni::Encode(t_v) == ""  "encode: empty root")

    t_v["a"] = "1"
    _Assert(ycIni::Encode(t_v) == "a = 1\n"  "encode: root scalar")
    t_v["a"] = ""
    _Assert(ycIni::Encode(t_v) == "a = \n"  "encode: empty value")

    t_v = _Table()
    t_v["a"] = _Table()
    _Assert(ycIni::Encode(t_v) == "[a]\n"  "encode: empty section")

    t_v["a"]["b"] = "1"
    _Assert(ycIni::Encode(t_v) == "[a]\nb = 1\n"  "encode: section scalar")

    t_v = _Table()
    t_v["title"] = "x"
    t_v["server"] = _Table()
    t_v["server"]["host"] = "h"
    _Assert(ycIni::Encode(t_v) == "title = x\n\n[server]\nhost = h\n"  "encode: root before section")

    t_v = _Table()
    t_v["z"] = _Table()
    t_v["z"]["b"] = "2"
    t_v["z"]["a"] = "1"
    t_v["a"] = _Table()
    t_v["a"]["k"] = "v"
    t_out = ycIni::Encode(t_v ?sortKeys t)
    _Assert(t_out == "[a]\nk = v\n\n[z]\na = 1\nb = 2\n"  "encode: sorted sections and section keys")

    t_v = _Table()
    t_v["z"] = "1"
    t_v["a"] = "2"
    t_v["b"] = _Table()
    t_v["b"]["k"] = "v"
    t_v["m"] = _Table()
    t_v["m"]["z"] = "1"
    t_v["m"]["a"] = "2"
    _Assert(ycIni::Encode(t_v ?sortKeys t) == "a = 2\nz = 1\n\n[b]\nk = v\n\n[m]\na = 2\nz = 1\n"  "encode: root scalars sorted before sections")

    t_v = _Table()
    t_v["s"] = "text"
    t_v["n"] = 42
    t_v["f"] = 1.5
    t_v["t"] = t
    t_v["tt"] = ycCodec::True
    t_v["ff"] = ycCodec::False
    t_v["sym"] = 'sym
    t_v["z"] = nil
    _Assert(ycIni::Encode(t_v ?sortKeys t) == "f = 1.5\nff = false\nn = 42\ns = text\nsym = sym\nt = true\ntt = true\nz = \n"  "encode: scalar types")

    t_v = _Table()
    t_v["neg"] = -3
    t_v["real"] = -0.5
    t_v["one"] = 1.0
    _Assert(ycIni::Encode(t_v ?sortKeys t) == "neg = -3\none = 1\nreal = -0.5\n"  "encode: numbers")

    t_v = _Table()
    t_v['sym] = "v"
    t_v[7] = "x"
    _Assert(ycIni::Encode(t_v ?sortKeys t) == "7 = x\nsym = v\n"  "encode: symbol and fixnum keys")

    t_v = _Table()
    t_v["s"] = "v"
    _Assert(ycIni::Encode(t_v ?strict t) == "s = v\n"  "encode: strict accepts string keys")
    t_v['sym] = "v"
    _AssertError(lambda(() ycIni::Encode(t_v ?strict t))  "encode: strict rejects symbol keys")

    t_v = _Table()
    t_v["a=b"] = "v"
    _AssertError(lambda(() ycIni::Encode(t_v))  "encode: delimiter in key errors")
    _Assert(ycIni::Encode(t_v ?delimiter ":") == "a=b : v\n"  "encode: custom delimiter")
    t_v = _Table()
    t_v["a"] = "x:y"
    _Assert(ycIni::Encode(t_v ?delimiter ":") == "a : x:y\n"  "encode: custom delimiter in value")
    t_v = _Table()
    t_v["a"] = "x=y"
    _Assert(ycIni::Encode(t_v) == "a = x=y\n"  "encode: delimiter in value")

    t_v = _Table()
    t_v["a"] = list(1 2)
    _AssertError(lambda(() ycIni::Encode(t_v))  "encode: list value errors")
    t_v = _Table()
    t_v["a"] = _Table()
    t_v["a"]["b"] = _Table()
    _AssertError(lambda(() ycIni::Encode(t_v))  "encode: nested table errors")
    t_v["a"] = ycCodec::Null
    _AssertError(lambda(() ycIni::Encode(t_v))  "encode: Null errors")
    t_v["a"] = ycCodec::Missing
    _AssertError(lambda(() ycIni::Encode(t_v))  "encode: Missing errors")

    _AssertError(lambda(() ycIni::Encode("x"))  "encode: non-table root errors")
    _AssertError(lambda(() ycIni::Encode(nil))  "encode: nil root errors")
    _AssertError(lambda(() ycIni::Encode(list(1)))  "encode: list root errors")

    t_v = _Table()
    t_v[""] = "v"
    _AssertError(lambda(() ycIni::Encode(t_v))  "encode: empty key errors")
    t_v = _Table()
    t_v[" a"] = "v"
    _AssertError(lambda(() ycIni::Encode(t_v))  "encode: leading whitespace key errors")
    t_v = _Table()
    t_v["a\t"] = "v"
    _AssertError(lambda(() ycIni::Encode(t_v))  "encode: trailing tab key errors")
    t_v = _Table()
    t_v["a\nb"] = "v"
    _AssertError(lambda(() ycIni::Encode(t_v))  "encode: newline key errors")
    t_v = _Table()
    t_v["#a"] = "v"
    _AssertError(lambda(() ycIni::Encode(t_v))  "encode: hash-leading key errors")
    t_v = _Table()
    t_v[";a"] = "v"
    _AssertError(lambda(() ycIni::Encode(t_v))  "encode: semicolon-leading key errors")
    t_v = _Table()
    t_v["[a"] = "v"
    _AssertError(lambda(() ycIni::Encode(t_v))  "encode: bracket-leading key errors")

    t_v = _Table()
    t_v["a"] = _Table()
    t_v["a"][""] = "v"
    _AssertError(lambda(() ycIni::Encode(t_v))  "encode: empty section key errors")
    t_v = _Table()
    t_v[" a"] = _Table()
    _AssertError(lambda(() ycIni::Encode(t_v))  "encode: leading whitespace section name errors")
    t_v = _Table()
    t_v["a[b"] = _Table()
    _AssertError(lambda(() ycIni::Encode(t_v))  "encode: bracket section name errors")
    t_v = _Table()
    t_v["a]b"] = _Table()
    _AssertError(lambda(() ycIni::Encode(t_v))  "encode: closing bracket section name errors")
    t_v = _Table()
    t_v["a\nb"] = _Table()
    _AssertError(lambda(() ycIni::Encode(t_v))  "encode: control section name errors")

    t_v = _Table()
    t_v["a"] = "x"
    t_v['a] = "y"
    _AssertError(lambda(() ycIni::Encode(t_v))  "encode: root scalar key collision errors")
    t_v = _Table()
    t_v["a"] = "x"
    t_v['a] = _Table()
    _AssertError(lambda(() ycIni::Encode(t_v))  "encode: scalar and section key collision errors")
    t_v = _Table()
    t_v["a"] = _Table()
    t_v["a"]["k"] = "1"
    t_v["a"]['k] = "2"
    _AssertError(lambda(() ycIni::Encode(t_v))  "encode: section key collision errors")

    t_v = _Table()
    t_v["a"] = "1"
    _Assert(ycIni::Encode(t_v ?finalNewline nil) == "a = 1"  "encode: finalNewline nil scalar")
    t_v["a"] = _Table()
    _Assert(ycIni::Encode(t_v ?finalNewline nil) == "[a]"  "encode: finalNewline nil section")
    t_v = _Table()
    _Assert(ycIni::Encode(t_v ?finalNewline nil) == ""  "encode: finalNewline nil empty root")

    t_v = ycIni::Decode("s = x\n[one]\na = 1\n[two]\nb = 2\n")
    t_out = ycIni::Encode(t_v ?sortKeys t)
    t_v = ycIni::Decode(t_out)
    _Assert(t_v["s"] == "x"  "encode/decode: root roundtrip")
    _Assert(t_v["one"]["a"] == "1"  "encode/decode: first section roundtrip")
    _Assert(t_v["two"]["b"] == "2"  "encode/decode: second section roundtrip")

    t_v = _Table()
    t_v["名字"] = "值"
    t_v["quote"] = "\"x\""
    t_v["slash"] = "C:\\Users\\name"
    t_v["mark"] = "# ; ="
    t_out = ycIni::Encode(t_v ?sortKeys t)
    t_v = ycIni::Decode(t_out)
    _Assert(t_v["名字"] == "值"  "encode/decode: unicode roundtrip")
    _Assert(t_v["quote"] == "\"x\""  "encode/decode: quote roundtrip")
    _Assert(t_v["slash"] == "C:\\Users\\name"  "encode/decode: backslash roundtrip")
    _Assert(t_v["mark"] == "# ; ="  "encode/decode: marker characters roundtrip")

    _AssertErrorMsg(lambda(() ycIni::Encode("x")) "root value must be a table"  "encode: root error message")
    _AssertErrorMsg(lambda(() ycIni::Encode(_Table() ?delimiter " ")) "delimiter"  "encode: delimiter error message")
)
_TestEncodeDone = t

; END
