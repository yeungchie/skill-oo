; --- 字面量与哨兵 ---
_assert(ycJson::Encode(nil) == "[]"  "encode: nil -> []")
_assert(ycJson::Encode(t) == "true"  "encode: t -> true")
_assert(ycJson::Encode(ycCodec::False) == "false"  "encode: False -> false")
_assert(ycJson::Encode(ycCodec::Null) == "null"  "encode: Null -> null")
_assertError(lambda(() ycJson::Encode(ycCodec::Missing))  "encode: Missing errors")
_assertError(lambda(() ycJson::Encode('foo))  "encode: plain symbol errors")
_assert(ycJson::Encode(nil ?nilAs "false") == "false"  "encode: nilAs false")
_assert(ycJson::Encode(nil ?nilAs "array") == "[]"  "encode: nilAs array")
_assertError(lambda(() ycJson::Encode(nil ?nilAs "null"))  "encode: nilAs null invalid")

; --- 数字 ---
_assert(ycJson::Encode(42) == "42"  "encode: fixnum 42")
_assert(ycJson::Encode(-7) == "-7"  "encode: fixnum -7")
_assert(ycJson::Encode(2147483647) == "2147483647"  "encode: fixnum max")
_assert(ycJson::Encode(0.1) == "0.1"  "encode: 0.1")
_assert(ycJson::Encode(1.5) == "1.5"  "encode: 1.5")
_assert(ycJson::Encode(1.0) == "1.0"  "encode: 1.0 keeps decimal point")
_assert(ycJson::Encode(atof("-0")) == "-0.0"  "encode: negative zero")
_assert(ycJson::Encode(1e20) == "1e+20"  "encode: 1e20 exponent form")
_assert(ycJson::Encode(1e-7) == "1e-07"  "encode: 1e-7 exponent form")
_assert(atof(ycJson::Encode(1.0 / 3.0)) == 1.0 / 3.0  "encode: 1/3 roundtrips")
_assert(atof(ycJson::Encode(0.1 + 0.2)) == 0.1 + 0.2  "encode: 0.1+0.2 roundtrips")
_assert(atof(ycJson::Encode(123456.789e10)) == 123456.789e10  "encode: large flonum roundtrips")
_assertError(lambda(() ycJson::Encode(atof("1e999")))  "encode: infinity errors")

; --- 字符串 ---
_assert(ycJson::Encode("") == "\"\""  "encode: empty string")
_assert(ycJson::Encode("abc") == "\"abc\""  "encode: plain string")
_assert(ycJson::Encode("中") == "\"中\""  "encode: utf-8 passes through")
_assert(ycJson::Encode("/") == "\"/\""  "encode: slash not escaped")
_assert(ycJson::Encode(strcat("a" intToChar(34) "b")) == strcat("\"" "a" "\\\"" "b" "\"")  "encode: escaped quote")
_assert(ycJson::Encode(strcat("a" intToChar(92) "b")) == strcat("\"" "a" "\\\\" "b" "\"")  "encode: escaped backslash")
_assert(
    ycJson::Encode(strcat(intToChar(8) intToChar(12) intToChar(10) intToChar(13) intToChar(9) intToChar(1)))
        == strcat("\"" "\\b" "\\f" "\\n" "\\r" "\\t" "\\u0001" "\"")
    "encode: control characters"
)

; --- 数组 ---
_assert(ycJson::Encode(list(1 2 3)) == "[1,2,3]"  "encode: list of fixnums")
_assert(ycJson::Encode(list("a" "b")) == "[\"a\",\"b\"]"  "encode: list of strings")
_assert(ycJson::Encode(list(t ycCodec::False ycCodec::Null)) == "[true,false,null]"  "encode: list of literals")
_assert(ycJson::Encode(list(nil)) == "[[]]"  "encode: list containing empty array")
_assert(ycJson::Encode(list(nil nil)) == "[[],[]]"  "encode: list of empty arrays")
_assert(ycJson::Encode(list(1 list(2 list(3)))) == "[1,[2,[3]]]"  "encode: nested lists")
_assertError(lambda(() ycJson::Encode(list('foo)))  "encode: list with symbol errors")

; --- 对象 ---
_assert(ycJson::Encode(makeTable("ycTest")) == "{}"  "encode: empty table")
let((t_v)
    t_v = makeTable("ycTest")
    t_v["b"] = 1
    t_v["a"] = 2
    _assert(ycJson::Encode(t_v ?sortKeys t) == "{\"a\":2,\"b\":1}"  "encode: sorts keys when requested")
    _assert(
        index(ycJson::Encode(t_v) "\"a\":2")
            && index(ycJson::Encode(t_v) "\"b\":1")
        "encode: default keeps table order entries"
    )
)
let((t_v)
    t_v = makeTable("ycTest")
    t_v['k] = 1
    t_v[3] = 2
    _assert(ycJson::Encode(t_v ?sortKeys t) == "{\"3\":2,\"k\":1}"  "encode: symbol and fixnum keys")
)
let((t_v)
    t_v = makeTable("ycTest")
    t_v['k] = 1
    t_v[3] = 2
    _assertError(lambda(() ycJson::Encode(t_v ?strict t))  "encode: strict rejects non-string keys")
)
let((t_v)
    t_v = makeTable("ycTest")
    t_v["a"] = 1
    t_v['a] = 2
    _assertError(lambda(() ycJson::Encode(t_v))  "encode: stringified key collision errors")
)
let((t_v)
    t_v = makeTable("ycTest")
    t_v["1"] = 1
    t_v[1] = 2
    _assertError(lambda(() ycJson::Encode(t_v))  "encode: fixnum and string key collision errors")
)
let((t_v)
    t_v = makeTable("ycTest")
    t_v["a"] = nil
    _assert(ycJson::Encode(t_v) == "{\"a\":[]}"  "encode: nil table value as empty array")
)
let((t_v)
    t_v = makeTable("ycTest")
    t_v["a"] = ycCodec::Missing
    _assertError(lambda(() ycJson::Encode(t_v))  "encode: Missing value errors")
)
let((t_v)
    t_v = makeTable("ycTest")
    t_v[strcat("a" intToChar(10) "b")] = 1
    _assert(ycJson::Encode(t_v) == "{\"a\\nb\":1}"  "encode: key with control char escaped")
)
_assertError(
    lambda(() ycJson::Encode(let((t_v) t_v = makeTable("ycTest") t_v[1.5] = 2 t_v)))
    "encode: flonum key errors"
)

; --- 缩进输出 ---
let((t_v)
    t_v = makeTable("ycTest")
    t_v["a"] = list(1 2)
    _assert(ycJson::Encode(t_v ?indent 2) == "{\n  \"a\": [\n    1,\n    2\n  ]\n}"  "encode: indent nested object")
)
_assert(ycJson::Encode(list(1 2) ?indent 2) == "[\n  1,\n  2\n]"  "encode: indent array")
_assert(ycJson::Encode("x" ?indent 2) == "\"x\""  "encode: indent irrelevant for scalar")
_assert(ycJson::Encode(5 ?indent 0) == "5"  "encode: indent zero is compact")
_assert(ycJson::Encode(makeTable("ycTest") ?indent 2) == "{}"  "encode: indent empty object")
_assertError(lambda(() ycJson::Encode(5 ?indent "x"))  "encode: indent type error")

; --- 嵌套深度 ---
_assert(errset(ycJson::Encode(_nestArrayValue(800)) nil) != nil  "encode: 800-deep nesting ok")
_assertError(lambda(() ycJson::Encode(_nestArrayValue(801)))  "encode: 801-deep nesting errors")
_assert(errset(ycJson::Encode(_nestArrayValue(900) ?maxDepth 1000) nil) != nil  "encode: custom maxDepth allows deeper nesting")
_assertError(lambda(() ycJson::Encode(list(list(1)) ?maxDepth 1))  "encode: maxDepth rejects deeper than limit")
_assertError(lambda(() ycJson::Encode(1 ?maxDepth 0))  "encode: maxDepth zero errors")
_assertError(lambda(() ycJson::Encode(1 ?maxDepth "x"))  "encode: maxDepth type error")

; --- 往返一致性 ---
let((g_v t_s)
    g_v = ycJson::Decode("{\"a\":[1,2.5,true,false,null,\"x\\u4e2d\"],\"b\":{}}")
    t_s = ycJson::Encode(g_v)
    _assertDumpEq(ycJson::Decode(t_s) g_v  "encode: dump/parse roundtrip composite")
)

_assert(ycJson::Encode(ycCodec::True) == "true"  "encode: True -> true")
_assert(ycJson::Encode("x" ?format "jsonc") == "\"x\""  "encode: jsonc format behaves as json")
_assert(ycJson::Encode(list(1) ?format "jsonl") == "1\n"  "encode: jsonl format dispatch")
_assertErrorMsg(lambda(() ycJson::Encode(1 ?format "xml")) "unknown format"  "encode: unknown format errors")
_TestEncodeDone = t

; END
