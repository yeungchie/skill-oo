; --- 字面量与哨兵 ---
_assert(ycCodec::jsonDump(nil) == "[]"  "dump: nil -> []")
_assert(ycCodec::jsonDump(t) == "true"  "dump: t -> true")
_assert(ycCodec::jsonDump(ycCodec::jsonFalse) == "false"  "dump: jsonFalse -> false")
_assert(ycCodec::jsonDump(ycCodec::jsonNull) == "null"  "dump: jsonNull -> null")
_assertError(lambda(() ycCodec::jsonDump(ycCodec::jsonMissing))  "dump: jsonMissing errors")
_assertError(lambda(() ycCodec::jsonDump('foo))  "dump: plain symbol errors")

; --- 数字 ---
_assert(ycCodec::jsonDump(42) == "42"  "dump: fixnum 42")
_assert(ycCodec::jsonDump(-7) == "-7"  "dump: fixnum -7")
_assert(ycCodec::jsonDump(2147483647) == "2147483647"  "dump: fixnum max")
_assert(ycCodec::jsonDump(0.1) == "0.1"  "dump: 0.1")
_assert(ycCodec::jsonDump(1.5) == "1.5"  "dump: 1.5")
_assert(ycCodec::jsonDump(1.0) == "1.0"  "dump: 1.0 keeps decimal point")
_assert(ycCodec::jsonDump(atof("-0")) == "-0.0"  "dump: negative zero")
_assert(ycCodec::jsonDump(1e20) == "1e+20"  "dump: 1e20 exponent form")
_assert(ycCodec::jsonDump(1e-7) == "1e-07"  "dump: 1e-7 exponent form")
_assert(atof(ycCodec::jsonDump(1.0 / 3.0)) == 1.0 / 3.0  "dump: 1/3 roundtrips")
_assert(atof(ycCodec::jsonDump(0.1 + 0.2)) == 0.1 + 0.2  "dump: 0.1+0.2 roundtrips")
_assert(atof(ycCodec::jsonDump(123456.789e10)) == 123456.789e10  "dump: large flonum roundtrips")
_assertError(lambda(() ycCodec::jsonDump(atof("1e999")))  "dump: infinity errors")

; --- 字符串 ---
_assert(ycCodec::jsonDump("") == "\"\""  "dump: empty string")
_assert(ycCodec::jsonDump("abc") == "\"abc\""  "dump: plain string")
_assert(ycCodec::jsonDump("中") == "\"中\""  "dump: utf-8 passes through")
_assert(ycCodec::jsonDump("/") == "\"/\""  "dump: slash not escaped")
_assert(ycCodec::jsonDump(strcat("a" intToChar(34) "b")) == strcat("\"" "a" "\\\"" "b" "\"")  "dump: escaped quote")
_assert(ycCodec::jsonDump(strcat("a" intToChar(92) "b")) == strcat("\"" "a" "\\\\" "b" "\"")  "dump: escaped backslash")
_assert(
    ycCodec::jsonDump(strcat(intToChar(8) intToChar(12) intToChar(10) intToChar(13) intToChar(9) intToChar(1)))
        == strcat("\"" "\\b" "\\f" "\\n" "\\r" "\\t" "\\u0001" "\"")
    "dump: control characters"
)

; --- 数组 ---
_assert(ycCodec::jsonDump(list(1 2 3)) == "[1,2,3]"  "dump: list of fixnums")
_assert(ycCodec::jsonDump(list("a" "b")) == "[\"a\",\"b\"]"  "dump: list of strings")
_assert(ycCodec::jsonDump(list(t ycCodec::jsonFalse ycCodec::jsonNull)) == "[true,false,null]"  "dump: list of literals")
_assert(ycCodec::jsonDump(list(nil)) == "[[]]"  "dump: list containing empty array")
_assert(ycCodec::jsonDump(list(nil nil)) == "[[],[]]"  "dump: list of empty arrays")
_assert(ycCodec::jsonDump(list(1 list(2 list(3)))) == "[1,[2,[3]]]"  "dump: nested lists")
_assertError(lambda(() ycCodec::jsonDump(list('foo)))  "dump: list with symbol errors")

; --- 对象 ---
_assert(ycCodec::jsonDump(makeTable("ycTest")) == "{}"  "dump: empty table")
let((t_v)
    t_v = makeTable("ycTest")
    t_v["b"] = 1
    t_v["a"] = 2
    _assert(ycCodec::jsonDump(t_v) == "{\"a\":2,\"b\":1}"  "dump: sorts keys by default")
    _assert(
        index(ycCodec::jsonDump(t_v ?sortKeys nil) "\"a\":2")
            && index(ycCodec::jsonDump(t_v ?sortKeys nil) "\"b\":1")
        "dump: unsorted output contains all entries"
    )
)
let((t_v)
    t_v = makeTable("ycTest")
    t_v['k] = 1
    t_v[3] = 2
    _assert(ycCodec::jsonDump(t_v) == "{\"3\":2,\"k\":1}"  "dump: symbol and fixnum keys")
)
let((t_v)
    t_v = makeTable("ycTest")
    t_v["a"] = nil
    _assert(ycCodec::jsonDump(t_v) == "{\"a\":[]}"  "dump: nil table value as empty array")
)
let((t_v)
    t_v = makeTable("ycTest")
    t_v["a"] = ycCodec::jsonMissing
    _assertError(lambda(() ycCodec::jsonDump(t_v))  "dump: jsonMissing value errors")
)
let((t_v)
    t_v = makeTable("ycTest")
    t_v[strcat("a" intToChar(10) "b")] = 1
    _assert(ycCodec::jsonDump(t_v) == "{\"a\\nb\":1}"  "dump: key with control char escaped")
)
_assertError(
    lambda(() ycCodec::jsonDump(let((t_v) t_v = makeTable("ycTest") t_v[1.5] = 2 t_v)))
    "dump: flonum key errors"
)

; --- 缩进输出 ---
let((t_v)
    t_v = makeTable("ycTest")
    t_v["a"] = list(1 2)
    _assert(ycCodec::jsonDump(t_v ?indent 2) == "{\n  \"a\": [\n    1,\n    2\n  ]\n}"  "dump: indent nested object")
)
_assert(ycCodec::jsonDump(list(1 2) ?indent 2) == "[\n  1,\n  2\n]"  "dump: indent array")
_assert(ycCodec::jsonDump("x" ?indent 2) == "\"x\""  "dump: indent irrelevant for scalar")
_assert(ycCodec::jsonDump(5 ?indent 0) == "5"  "dump: indent zero is compact")
_assert(ycCodec::jsonDump(makeTable("ycTest") ?indent 2) == "{}"  "dump: indent empty object")
_assertError(lambda(() ycCodec::jsonDump(5 ?indent "x"))  "dump: indent type error")

; --- 嵌套深度 ---
_assert(errset(ycCodec::jsonDump(_nestArrayValue(1000)) nil) != nil  "dump: 1000-deep nesting ok")
_assertError(lambda(() ycCodec::jsonDump(_nestArrayValue(1001)))  "dump: 1001-deep nesting errors")

; --- 往返一致性 ---
let((g_v t_s)
    g_v = ycCodec::jsonParse("{\"a\":[1,2.5,true,false,null,\"x\\u4e2d\"],\"b\":{}}")
    t_s = ycCodec::jsonDump(g_v)
    _assertDumpEq(ycCodec::jsonParse(t_s) g_v  "dump: dump/parse roundtrip composite")
)

_TestDumpDone = t

; END
