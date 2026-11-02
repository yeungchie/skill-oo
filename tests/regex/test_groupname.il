; ycRegEx named-group suite: Pattern->groupindex, Matched->group(name), groupdict.

; --- 1. Pattern->groupindex ---
let((p t_idx)
    p = ycRegEx::Compile("(?P<y>\\d{4})")
    t_idx = p->groupindex()
    _Assert(tablep(t_idx)  "groupindex: named pattern returns a table")
    _Assert(t_idx["y"] == 1  "groupindex: single name maps to 1")
    _Assert(ycRegEx::Compile("(\\d+)-(\\d+)")->groupindex() == nil
        "groupindex: no named group returns nil")
    t_idx = ycRegEx::Compile("(?P<a>x)(?P<b>y)")->groupindex()
    _AssertSameInts(list(t_idx["a"] t_idx["b"]) '(1 2)
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
let((m t_d)
    m = ycRegEx::Search("(?P<a>\\d+)-(?P<b>\\d+)" "10-20")
    t_d = m->groupdict()
    _Assert(tablep(t_d)  "groupdict: returns a table")
    _Assert(t_d["a"] == "10" && t_d["b"] == "20"  "groupdict: name to value")
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
let((p m t_idx)
    p = ycRegEx::Compile("(a)(?P<x>b)(c)(?P<y>d)" ?compileOpts 'no_auto_capture)
    t_idx = p->groupindex()
    _AssertSameInts(list(t_idx["x"] t_idx["y"]) '(1 2)
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

_TestChildDone = t
