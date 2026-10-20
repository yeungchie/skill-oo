; --- 标量输出 ---
_assert(ycYaml::encode(ycYaml::YamlNull) == "null\n"  "encode: null")
_assert(ycYaml::encode(t) == "true\n"  "encode: t")
_assert(ycYaml::encode(ycYaml::YamlTrue) == "true\n"  "encode: YamlTrue")
_assert(ycYaml::encode(ycYaml::YamlFalse) == "false\n"  "encode: YamlFalse")
_assertError(lambda(() ycYaml::encode(ycYaml::YamlMissing))  "encode: Missing errors")
_assert(ycYaml::encode(42) == "42\n"  "encode: fixnum")
_assert(ycYaml::encode(-7) == "-7\n"  "encode: negative fixnum")
_assert(ycYaml::encode(3.14) == "3.14\n"  "encode: float")
_assert(ycYaml::encode(1.0) == "1.0\n"  "encode: float keeps decimal point")
_assert(ycYaml::encode(atof("1e999")) == ".inf\n"  "encode: infinity")
_assert(ycYaml::encode(-atof("1e999")) == "-.inf\n"  "encode: negative infinity")
_assert(ycYaml::encode(atof("nan")) == ".nan\n"  "encode: nan")
_assert(ycYaml::encode("abc") == "abc\n"  "encode: plain string")
_assert(ycYaml::encode("hello world") == "hello world\n"  "encode: plain string with space")
_assert(ycYaml::encode("") == "\"\"\n"  "encode: empty string")
_assert(ycYaml::encode("true") == "\"true\"\n"  "encode: boolean-like string quoted")
_assert(ycYaml::encode("123") == "\"123\"\n"  "encode: number-like string quoted")
_assert(ycYaml::encode("null") == "\"null\"\n"  "encode: null-like string quoted")
_assert(ycYaml::encode("a: b") == "\"a: b\"\n"  "encode: colon-space string quoted")
_assert(ycYaml::encode("a # b") == "\"a # b\"\n"  "encode: comment-like string quoted")
_assert(ycYaml::encode("a#b") == "a#b\n"  "encode: hash without space stays plain")
_assert(ycYaml::encode("- x") == "\"- x\"\n"  "encode: sequence-like string quoted")
_assert(ycYaml::encode("a\nb") == "\"a\\nb\"\n"  "encode: newline escaped")
_assert(ycYaml::encode("中") == "中\n"  "encode: unicode passes through")
_assertError(lambda(() ycYaml::encode('foo))  "encode: symbol errors")

; --- 序列输出 ---
_assert(ycYaml::encode(nil) == "[]\n"  "encode: empty sequence")
_assert(ycYaml::encode(list(1 2)) == "- 1\n- 2\n"  "encode: sequence")
_assert(ycYaml::encode(list(1 list(2 3))) == "- 1\n-\n  - 2\n  - 3\n"  "encode: nested sequence")
_assert(ycYaml::encode(list()) == "[]\n"  "encode: empty list")
_assert(ycYaml::encode(list(t ycYaml::YamlFalse ycYaml::YamlNull)) == "- true\n- false\n- null\n"  "encode: literal sequence")
_assert(ycYaml::encode(list(nil)) == "- []\n"  "encode: nil sequence item is empty sequence")
_assert(ycYaml::encode(list(makeTable("ycTest"))) == "- {}\n"  "encode: empty map sequence item")

; --- 映射输出 ---
_assert(ycYaml::encode(makeTable("ycTest")) == "{}\n"  "encode: empty map")
let((t_v)
    t_v = makeTable("ycTest")
    t_v["a"] = 1
    t_v["b"] = 2
    _assert(ycYaml::encode(t_v ?sortKeys t) == "a: 1\nb: 2\n"  "encode: map")
    _assert(ycYaml::encode(t_v ?sortKeys t) == "a: 1\nb: 2\n"  "encode: sorted map")
)
let((t_v t_in)
    t_in = makeTable("ycTest")
    t_in["b"] = 1
    t_v = makeTable("ycTest")
    t_v["a"] = t_in
    _assert(ycYaml::encode(t_v) == "a:\n  b: 1\n"  "encode: nested map")
)
let((t_v)
    t_v = makeTable("ycTest")
    t_v["a"] = list(1 2)
    _assert(ycYaml::encode(t_v) == "a:\n  - 1\n  - 2\n"  "encode: map with sequence")
)
let((t_v)
    t_v = makeTable("ycTest")
    t_v["a"] = 1
    t_v["b"] = 2
    _assert(ycYaml::encode(list(t_v) ?sortKeys t) == "- a: 1\n  b: 2\n"  "encode: sequence of maps")
)
let((t_v)
    t_v = makeTable("ycTest")
    t_v["a b"] = 1
    _assert(ycYaml::encode(t_v) == "\"a b\": 1\n"  "encode: quoted key")
)
let((t_v)
    t_v = makeTable("ycTest")
    t_v['k] = 1
    t_v[3] = 2
    _assert(ycYaml::encode(t_v ?sortKeys t) == "3: 2\nk: 1\n"  "encode: symbol and integer keys")
    _assertError(lambda(() ycYaml::encode(t_v ?strict t))  "encode: strict rejects non-string keys")
)
let((t_v)
    t_v = makeTable("ycTest")
    t_v["a"] = nil
    _assert(ycYaml::encode(t_v) == "a: []\n"  "encode: nil map value is empty sequence")
)
let((t_v)
    t_v = makeTable("ycTest")
    t_v["a"] = ycYaml::YamlMissing
    _assertError(lambda(() ycYaml::encode(t_v))  "encode: Missing value errors")
)

; --- 流式输出 ---
_assert(ycYaml::encode(list(1 2) ?flow t) == "[1, 2]\n"  "flow encode: sequence")
_assert(ycYaml::encode(nil ?flow t) == "[]\n"  "flow encode: empty sequence")
let((t_v)
    t_v = makeTable("ycTest")
    t_v["a"] = nil
    _assert(ycYaml::encode(t_v) == "a: []\n"  "encode: nil map value is empty sequence")
)
let((t_v)
    t_v = makeTable("ycTest")
    t_v["a"] = 1
    t_v["b"] = list(2 3)
    _assert(ycYaml::encode(t_v ?flow t ?sortKeys t) == "{a: 1, b: [2, 3]}\n"  "flow encode: map")
)

; --- 文档与选项 ---
_assert(ycYaml::encode(1 ?explicitStart t) == "---\n1\n"  "doc encode: explicit start")
_assert(ycYaml::encode(1 ?finalNewline nil) == "1"  "doc encode: finalNewline nil")
let((t_v)
    t_v = makeTable("ycTest")
    t_v["a"] = list(1 2)
    _assert(ycYaml::encode(t_v ?indent 4) == "a:\n    - 1\n    - 2\n"  "doc encode: indent 4")
)
_assert(ycYaml::encode(list(1 2) ?format "yaml-stream") == "---\n1\n---\n2\n"  "stream encode: documents")
_assert(ycYaml::encode(nil ?format "yaml-stream") == ""  "stream encode: empty")
_assertError(lambda(() ycYaml::encode(1 ?format "yaml-stream"))  "stream encode: expects list")
_assertError(lambda(() ycYaml::encode(1 ?format "xml"))  "encode: unknown format")
_assertError(lambda(() ycYaml::encode(1 ?indent 0))  "encode: indent zero errors")
_assertError(lambda(() ycYaml::encode(1 ?indent "x"))  "encode: indent type error")
_assertError(lambda(() ycYaml::encode(1 ?maxDepth 0))  "encode: maxDepth zero errors")
_assertError(lambda(() ycYaml::encode(1 ?format 1))  "encode: format type error")
_assertError(lambda(() ycYaml::encode(1 ?indent 2.5))  "encode: indent float error")
_assertError(lambda(() ycYaml::encode(1 ?maxDepth 1.5))  "encode: maxDepth float error")
_assertError(lambda(() ycYaml::encode(list(list(list(1))) ?maxDepth 1))  "encode: maxDepth nesting error")

; --- 往返 ---
let((g_v t_s)
    g_v = ycYaml::decode("a:\n  - 1\n  - 2.5\n  - true\n  - null\n  - \"x\"\nb:\n  c: d\n")
    t_s = ycYaml::encode(g_v ?sortKeys t)
    _assertDumpEq(ycYaml::decode(t_s) g_v  "encode: roundtrip composite")
)
let((g_v t_s)
    g_v = ycYaml::decode("- a\n- b: 1\n  c: [2, 3]\n", ?maxDepth 100)
    t_s = ycYaml::encode(g_v ?sortKeys t)
    _assertDumpEq(ycYaml::decode(t_s) g_v  "encode: roundtrip nested")
)
_TestEncodeDone = t

; END
