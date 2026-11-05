; ycRegEx named-group suite: Pattern->groupindex, Matched->group(name), groupdict.

; --- 1. Pattern->groupindex ---
let((p idx)
    p = ycRegEx::Compile("(?P<y>\\d{4})")
    idx = p->groupindex()
    _Assert(tablep(idx)  "groupindex: named pattern returns a table")
    _Assert(idx["y"] == 1  "groupindex: single name maps to 1")
    _Assert(ycRegEx::Compile("(\\d+)-(\\d+)")->groupindex() == nil
        "groupindex: no named group returns nil")
    idx = ycRegEx::Compile("(?P<a>x)(?P<b>y)")->groupindex()
    _AssertSameInts(list(idx["a"] idx["b"]) '(1 2)
        "groupindex: names numbered in order")
    _Assert(ycRegEx::Compile("(x)(?P<a>y)")->groupindex()["a"] == 2
        "groupindex: default numbering counts plain groups")
    _Assert(ycRegEx::Compile("(?P<a>x)")->groupindex()["a"]
        == ycRegEx::Compile("(?P<a>x)")->groupindex()["a"]
        "groupindex: same pattern text shares one cached table")
)

; --- 2. Matched->group by name ---
let((m)
    m = ycRegEx::Search("(?P<a>\\d+)-(?P<b>\\d+)" "10-20")
    _Assert(m->group("a") == "10"  "group: named selector")
    _Assert(m->group("b") == "20"  "group: second named selector")
    _AssertSameStrs(m->group(1 "b") '("10" "20")  "group: number and name mixed")
    _AssertSameStrs(m->group("b" 1) '("20" "10")  "group: name first keeps order")
    _AssertSameStrs(m->group(0 "a") '("10-20" "10")  "group: 0 mixes with a name")
    _AssertSameStrs(m->group("a" "b") '("10" "20")  "group: several names")
    _Assert(m->group("a") == m->group(1)  "group: name and number agree")
)

; --- 3. Matched->groupdict ---
let((m d)
    m = ycRegEx::Search("(?P<a>\\d+)-(?P<b>\\d+)" "10-20")
    d = m->groupdict()
    _Assert(tablep(d)  "groupdict: returns a table")
    _Assert(d["a"] == "10" && d["b"] == "20"  "groupdict: name to value")
    m = ycRegEx::Search("(?P<a>a)?(?P<b>b)" "b")
    _Assert(m->groupdict()["a"] == ""  "groupdict: non-participating group is empty")
    _Assert(m->groupdict()["b"] == "b"  "groupdict: participated group kept")
    _Assert(m->groupdict(?empty "NA")["a"] == "NA"  "groupdict: ?empty replaces empty")
    _Assert(ycRegEx::Search("(a)" "a")->groupdict() == nil
        "groupdict: no named group returns nil")
)

; --- 4. error paths ---
_AssertError(lambda(() ycRegEx::Search("(?P<a>x)" "x")->group("zz") t)
    "group: unknown name raises")
_AssertErrorMsg(lambda(() ycRegEx::Search("(?P<a>x)" "x")->group("zz") t)
    "no such group name"  "group: unknown name message")
_AssertError(lambda(() ycRegEx::Search("(?P<a>x)" "x")->group(1.5) t)
    "group: float selector raises")
_AssertError(lambda(() ycRegEx::Search("(?P<a>x)" "x")->group('a) t)
    "group: symbol selector raises")
_AssertError(lambda(() ycRegEx::Search("(a)" "a")->group("a") t)
    "group: name without named group raises")

; --- 5. no_auto_capture numbering ---
let((p m idx)
    p = ycRegEx::Compile("(a)(?P<x>b)(c)(?P<y>d)" ?compileOpts 'no_auto_capture)
    idx = p->groupindex()
    _AssertSameInts(list(idx["x"] idx["y"]) '(1 2)
        "groupindex: no_auto_capture numbers only named groups")
    m = p->match("abcd")
    _Assert(m->group("x") == "b"  "group: no_auto_capture name x")
    _Assert(m->group("y") == "d"  "group: no_auto_capture name y")
    _Assert(ycRegEx::Compile("(a)(?P<x>b)(c)(?P<y>d)")->groupindex()["x"] == 2
        "groupindex: default numbering kept apart from no_auto_capture")
)

; --- 6. unresolvable pattern fails loudly ---
_AssertError(lambda(() ycRegEx::Compile("\\Q(?P<a>x)\\E")->groupindex() t)
    "groupindex: pattern the helper cannot parse raises")

; --- 7. heredoc terminator cannot be forged from the pattern ---
; 模式串里出现与终止符同名的整行时，传输不能被截断（否则其后内容会被 shell 执行）。
let((eof pat idx)
    eof = lsprintf("EOF%d" ipcGetPid())
    pat = lsprintf("(?P<a>x)\n%s\n(?P<b>y)" eof)
    idx = ycRegEx::Compile(pat)->groupindex()
    _Assert(tablep(idx)  "groupindex: terminator-like line inside pattern is accepted")
    _Assert(idx["a"] == 1 && idx["b"] == 2
        "groupindex: pattern is delivered whole across a terminator-like line")
    pat = lsprintf("(?P<a>x)\n%s" eof)
    idx = ycRegEx::Compile(pat)->groupindex()
    _Assert(idx["a"] == 1
        "groupindex: terminator-like last line does not truncate the pattern")
)

; --- 8. the pattern is never expanded by the shell ---
; 引号形式的 heredoc 不展开正文；若退化成 <<EOF，命令替换会先执行：
; $(printf '()') 变成 ()，后面的命名组序号随之从 3 掉到 2。
let((pat idx)
    pat = "$(printf '()')(?P<b>y)"
    idx = ycRegEx::Compile(pat)->groupindex()
    _Assert(idx["b"] == 3  "groupindex: command substitution stays literal")
)

_TestChildDone = t
