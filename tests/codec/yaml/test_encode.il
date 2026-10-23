; --- 标量输出 ---
_Assert(ycYaml::Encode(ycCodec::Null) == "null\n"  "encode: null")
_Assert(ycYaml::Encode(t) == "true\n"  "encode: t")
_Assert(ycYaml::Encode(ycCodec::True) == "true\n"  "encode: True")
_Assert(ycYaml::Encode(ycCodec::False) == "false\n"  "encode: False")
_AssertError(lambda(() ycYaml::Encode(ycCodec::Missing))  "encode: Missing errors")
_Assert(ycYaml::Encode(42) == "42\n"  "encode: fixnum")
_Assert(ycYaml::Encode(-7) == "-7\n"  "encode: negative fixnum")
_Assert(ycYaml::Encode(3.14) == "3.14\n"  "encode: float")
_Assert(ycYaml::Encode(1.0) == "1.0\n"  "encode: float keeps decimal point")
_Assert(ycYaml::Encode(atof("1e999")) == ".inf\n"  "encode: infinity")
_Assert(ycYaml::Encode(-atof("1e999")) == "-.inf\n"  "encode: negative infinity")
_Assert(ycYaml::Encode(atof("nan")) == ".nan\n"  "encode: nan")
_Assert(ycYaml::Encode("abc") == "abc\n"  "encode: plain string")
_Assert(ycYaml::Encode("hello world") == "hello world\n"  "encode: plain string with space")
_Assert(ycYaml::Encode("") == "\"\"\n"  "encode: empty string")
_Assert(ycYaml::Encode("true") == "\"true\"\n"  "encode: boolean-like string quoted")
_Assert(ycYaml::Encode("123") == "\"123\"\n"  "encode: number-like string quoted")
_Assert(ycYaml::Encode("null") == "\"null\"\n"  "encode: null-like string quoted")
_Assert(ycYaml::Encode("a: b") == "\"a: b\"\n"  "encode: colon-space string quoted")
_Assert(ycYaml::Encode("a # b") == "\"a # b\"\n"  "encode: comment-like string quoted")
_Assert(ycYaml::Encode("a#b") == "a#b\n"  "encode: hash without space stays plain")
_Assert(ycYaml::Encode("- x") == "\"- x\"\n"  "encode: sequence-like string quoted")
_Assert(ycYaml::Encode("...") == "\"...\"\n"  "encode: document-end marker string quoted")
_Assert(ycYaml::Decode(ycYaml::Encode("...")) == "..."  "encode: document-end marker roundtrip")
_Assert(ycYaml::Encode("a\nb") == "\"a\\nb\"\n"  "encode: newline escaped")
_Assert(ycYaml::Encode("中") == "中\n"  "encode: unicode passes through")
_AssertError(lambda(() ycYaml::Encode('foo))  "encode: symbol errors")

; --- 序列输出 ---
_Assert(ycYaml::Encode(nil) == "[]\n"  "encode: empty sequence")
_Assert(ycYaml::Encode(list(1 2)) == "- 1\n- 2\n"  "encode: sequence")
_Assert(ycYaml::Encode(list(1 list(2 3))) == "- 1\n-\n  - 2\n  - 3\n"  "encode: nested sequence")
_Assert(ycYaml::Encode(list()) == "[]\n"  "encode: empty list")
_Assert(ycYaml::Encode(list(t ycCodec::False ycCodec::Null)) == "- true\n- false\n- null\n"  "encode: literal sequence")
_Assert(ycYaml::Encode(list(nil)) == "- []\n"  "encode: nil sequence item is empty sequence")
_Assert(ycYaml::Encode(list(makeTable("ycTest"))) == "- {}\n"  "encode: empty map sequence item")

; --- 映射输出 ---
_Assert(ycYaml::Encode(makeTable("ycTest")) == "{}\n"  "encode: empty map")
let((t_v)
    t_v = makeTable("ycTest")
    t_v["a"] = 1
    t_v["b"] = 2
    _Assert(ycYaml::Encode(t_v ?sortKeys t) == "a: 1\nb: 2\n"  "encode: map")
    _Assert(ycYaml::Encode(t_v ?sortKeys t) == "a: 1\nb: 2\n"  "encode: sorted map")
)
let((t_v t_in)
    t_in = makeTable("ycTest")
    t_in["b"] = 1
    t_v = makeTable("ycTest")
    t_v["a"] = t_in
    _Assert(ycYaml::Encode(t_v) == "a:\n  b: 1\n"  "encode: nested map")
)
let((t_v)
    t_v = makeTable("ycTest")
    t_v["a"] = list(1 2)
    _Assert(ycYaml::Encode(t_v) == "a:\n  - 1\n  - 2\n"  "encode: map with sequence")
)
let((t_v)
    t_v = makeTable("ycTest")
    t_v["a"] = 1
    t_v["b"] = 2
    _Assert(ycYaml::Encode(list(t_v) ?sortKeys t) == "- a: 1\n  b: 2\n"  "encode: sequence of maps")
)
let((t_v)
    t_v = makeTable("ycTest")
    t_v["a b"] = 1
    _Assert(ycYaml::Encode(t_v) == "\"a b\": 1\n"  "encode: quoted key")
)
let((t_v)
    t_v = makeTable("ycTest")
    t_v['k] = 1
    t_v[3] = 2
    _Assert(ycYaml::Encode(t_v ?sortKeys t) == "3: 2\nk: 1\n"  "encode: symbol and integer keys")
    _AssertError(lambda(() ycYaml::Encode(t_v ?strict t))  "encode: strict rejects non-string keys")
)
let((t_v)
    t_v = makeTable("ycTest")
    t_v["a"] = 1
    t_v['a] = 2
    _AssertError(lambda(() ycYaml::Encode(t_v))  "encode: stringified key collision errors")
)

let((t_v)
    t_v = makeTable("ycTest")
    t_v["a"] = nil
    _Assert(ycYaml::Encode(t_v) == "a: []\n"  "encode: nil map value is empty sequence")
)
let((t_v)
    t_v = makeTable("ycTest")
    t_v["a"] = ycCodec::Missing
    _AssertError(lambda(() ycYaml::Encode(t_v))  "encode: Missing value errors")
)

; --- 流式输出 ---
_Assert(ycYaml::Encode(list(1 2) ?flow t) == "[1, 2]\n"  "flow encode: sequence")
_Assert(ycYaml::Encode(nil ?flow t) == "[]\n"  "flow encode: empty sequence")
let((t_v)
    t_v = makeTable("ycTest")
    t_v["a"] = nil
    _Assert(ycYaml::Encode(t_v) == "a: []\n"  "encode: nil map value is empty sequence")
)
let((t_v)
    t_v = makeTable("ycTest")
    t_v["a"] = 1
    t_v["b"] = list(2 3)
    _Assert(ycYaml::Encode(t_v ?flow t ?sortKeys t) == "{a: 1, b: [2, 3]}\n"  "flow encode: map")
)
let((t_v)
    t_v = makeTable("ycTest")
    t_v["a"] = 1
    t_v['a] = 2
    _AssertError(lambda(() ycYaml::Encode(t_v ?flow t))  "flow encode: key collision errors")
)

; --- 文档与选项 ---
_Assert(ycYaml::Encode(1 ?explicitStart t) == "---\n1\n"  "doc encode: explicit start")
_Assert(ycYaml::Encode(1 ?finalNewline nil) == "1"  "doc encode: finalNewline nil")
let((t_v)
    t_v = makeTable("ycTest")
    t_v["a"] = list(1 2)
    _Assert(ycYaml::Encode(t_v ?indent 4) == "a:\n    - 1\n    - 2\n"  "doc encode: indent 4")
)
_Assert(ycYaml::Encode(list(1 2) ?format "yaml-stream") == "---\n1\n---\n2\n"  "stream encode: documents")
_Assert(ycYaml::Encode(nil ?format "yaml-stream") == ""  "stream encode: empty")
_AssertError(lambda(() ycYaml::Encode(1 ?format "yaml-stream"))  "stream encode: expects list")
_AssertError(lambda(() ycYaml::Encode(1 ?format "xml"))  "encode: unknown format")
_AssertError(lambda(() ycYaml::Encode(1 ?indent 0))  "encode: indent zero errors")
_AssertError(lambda(() ycYaml::Encode(1 ?indent "x"))  "encode: indent type error")
_AssertError(lambda(() ycYaml::Encode(1 ?maxDepth 0))  "encode: maxDepth zero errors")
_AssertError(lambda(() ycYaml::Encode(1 ?format 1))  "encode: format type error")
_AssertError(lambda(() ycYaml::Encode(1 ?indent 2.5))  "encode: indent float error")
_AssertError(lambda(() ycYaml::Encode(1 ?maxDepth 1.5))  "encode: maxDepth float error")
_AssertError(lambda(() ycYaml::Encode(list(list(list(1))) ?maxDepth 1))  "encode: maxDepth nesting error")

; --- 往返 ---
let((g_v t_s)
    g_v = ycYaml::Decode("a:\n  - 1\n  - 2.5\n  - true\n  - null\n  - \"x\"\nb:\n  c: d\n")
    t_s = ycYaml::Encode(g_v ?sortKeys t)
    _AssertDumpEq(ycYaml::Decode(t_s) g_v  "encode: roundtrip composite")
)
let((g_v t_s)
    g_v = ycYaml::Decode("- a\n- b: 1\n  c: [2, 3]\n", ?maxDepth 100)
    t_s = ycYaml::Encode(g_v ?sortKeys t)
    _AssertDumpEq(ycYaml::Decode(t_s) g_v  "encode: roundtrip nested")
)
_TestEncodeDone = t

; END
