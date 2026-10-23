; ycRegEx parity suite: value tables captured from CPython 3.12.13 re module.
; Comments carry the CPython value whenever the engine intentionally diverges.

; ---------- findall ----------
_assertSameSeq(ycRegEx::ReFindall("\\d+" "a1b22c333") '("1" "22" "333")  "findall: digits")
_assertSameTuples(ycRegEx::ReFindall("(a)|(b)" "ab") '(("a" "") ("" "b"))  "findall: alt groups tuple")
_assertSameTuples(ycRegEx::ReFindall("(\\d)(\\w)" "1a 2b") '(("1" "a") ("2" "b"))  "findall: two groups")
_assertSameSeq(ycRegEx::ReFindall("x*" "axbxc") '("" "x" "" "x" "" "")  "findall: zero-width walk")
_assertSameSeq(ycRegEx::ReFindall("a*" "") '("")  "findall: empty subject zero-width")
_assertSameSeq(ycRegEx::ReFindall("abc" "xABC" ?flags 'I) '("ABC")  "findall: flag 'I")
_assertSameSeq(ycRegEx::ReFindall("(?i)abc" "xABC") '("ABC")  "findall: inline (?i)")
_assertSameSeq(ycRegEx::ReFindall("a.+b" "ab<b>ab") '("ab<b>ab")  "findall: greedy")
_assertSameSeq(ycRegEx::ReFindall("a.+?b" "ab<b>ab") '("ab<b")  "findall: lazy quantifier")
_assertSameSeq(ycRegEx::ReFindall("(a)\\1" "aaab") '("a")  "findall: backref")
_assertSameSeq(ycRegEx::ReFindall("中文" "中文和中文") '("中文" "中文")  "findall: CJK bytes")
_assertSameTuples(ycRegEx::ReFindall("(x)|(y)|(z)" "x z") '(("x" "" "") ("" "" "z"))  "findall: three groups")
_assertSameSeq(ycRegEx::ReFindall("(?=a)" "aaa") '("" "" "")  "findall: lookahead empty items")
_assertSameSeq(ycRegEx::ReFindall("" "ab") '("" "" "")  "findall: empty pattern")
_assertSameSeq(ycRegEx::ReFindall("abc" "xABC") nil  "findall: no match -> empty list")

; ---------- finditer (position tables) ----------
_assertSameInts(_startsOf(ycRegEx::ReFinditer("x*" "axbxc")) '(0 1 2 3 4 5)  "finditer: zero-width starts")
_assertSameInts(_endsOf(ycRegEx::ReFinditer("x*" "axbxc")) '(0 2 2 4 4 5)  "finditer: zero-width ends")
_assertSameInts(_startsOf(ycRegEx::ReFinditer("\\d+" "a1b22")) '(1 3)  "finditer: digits starts")
_assertSameInts(_endsOf(ycRegEx::ReFinditer("\\d+" "a1b22")) '(2 5)  "finditer: digits ends")
_assertSameInts(_startsOf(ycRegEx::ReFinditer("a*" "")) '(0)  "finditer: empty subject start")
_assertSameInts(_endsOf(ycRegEx::ReFinditer("a*" "")) '(0)  "finditer: empty subject end")
_assertSameInts(_startsOf(ycRegEx::ReFinditer("(?m)^b" "a\nb")) '(2)  "finditer: multiline caret start")
_assertSameInts(_endsOf(ycRegEx::ReFinditer("(?m)^b" "a\nb")) '(3)  "finditer: multiline caret end")
_assertSameInts(_startsOf(ycRegEx::ReFinditer("c*" "abc")) '(0 1 2 3)  "finditer: zero-width at end starts")
_assertSameInts(_endsOf(ycRegEx::ReFinditer("c*" "abc")) '(0 1 3 3)  "finditer: zero-width at end ends")
_assertSameInts(_startsOf(ycRegEx::ReFinditer("(?=a)" "aaa")) '(0 1 2)  "finditer: lookahead starts")
_assertSameInts(_endsOf(ycRegEx::ReFinditer("(?=a)" "aaa")) '(0 1 2)  "finditer: lookahead ends")
_assertSameInts(_startsOf(ycRegEx::ReFinditer("a" "aaa")) '(0 1 2)  "finditer: literal starts")
_assertSameInts(_endsOf(ycRegEx::ReFinditer("a" "aaa")) '(1 2 3)  "finditer: literal ends")
_assert(length(ycRegEx::ReFinditer("\\d+" "")) == 0  "finditer: no match -> empty list")

; ---------- split ----------
_assertSameSeq(ycRegEx::ReSplit("\\s+" "a b  c" ?all t) '("a" "b" "c")  "split ?all: whitespace runs")
_assertSameSeq(ycRegEx::ReSplit("\\s+" "a b  c") '("a" "b  c")  "split default single: whitespace")
_assertSameSeq(ycRegEx::ReSplit("(\\d)" "a1b2c" ?all t) '("a" "1" "b" "2" "c")  "split ?all: group value in result")
_assertSameSeq(ycRegEx::ReSplit("(\\d)" "a1b2c") '("a" "1" "b2c")  "split default single: group value")
_assertSameSeq(ycRegEx::ReSplit("(a)|(b)" "ab" ?all t) '("" "a" "" "" "" "b" "")  "split ?all: alt groups (CPython None -> '')")
_assertSameSeq(ycRegEx::ReSplit("," "a,b,c" ?all t) '("a" "b" "c")  "split ?all: plain")
_assertSameSeq(ycRegEx::ReSplit("," "a,b,c") '("a" "b,c")  "split default single: plain")
_assertSameSeq(ycRegEx::ReSplit("," "") '("")  "split: empty subject")
_assertSameSeq(ycRegEx::ReSplit("x*" "axbxc") '("" "axbxc")  "split: zero-width first-only pin (CPython 7 items)")
_assertSameSeq(ycRegEx::ReSplit("(?m)^" "a\nb") '("" "a\nb")  "split: zero-width caret pin (CPython ['', 'a\\n', 'b'])")
_assertSameSeq(ycRegEx::ReSplit("" "ab") '("" "ab")  "split: empty pattern pin (CPython ['' 'a' 'b' ''])")
_assertSameSeq(ycRegEx::ReSplit("x*" "") '("" "")  "split: zero-width empty subject")
_assertSameSeq(ycRegEx::ReSplit("," "a<YC-S>b") '("a" "b")  "split: marker-in-subject swallowed (CPython ['a<YC-S>b'])")

; ---------- sub / subn ----------
_assert(ycRegEx::ReSub("(x)" "<\\1>" "xa x" ?all t) == "<x>a <x>"  "sub ?all: backref expansion")
_assert(ycRegEx::ReSub("(x)" "<\\1>" "xa x") == "<x>a x"  "sub default single: backref")
_assert(ycRegEx::ReSub("x*" "-" "abc") == "-abc"  "sub: zero-width first-only pin (CPython '-a-b-c-')")
_assert(ycRegEx::ReSub("b" "[&]" "abc") == "a[b]c"  "sub: & expands in engine (CPython 'a[&]c')")
_assert(ycRegEx::ReSub("(?i)hello" "X" "Say Hello") == "Say X"  "sub: inline flag")
_assert(ycRegEx::ReSub("a" "X" "") == ""  "sub: empty subject")
_assert(ycRegEx::ReSub("z" "X" "abc") == "abc"  "sub: no match returns subject")
_assert(ycRegEx::ReSub("\\d" "#" "a1b2c" ?all t) == "a#b#c"  "sub ?all: all digits")
_assert(ycRegEx::ReSub("\\d" "#" "a1b2c") == "a#b2c"  "sub default single: first digit")
_assert(ycRegEx::ReSub("x*" "-" "abc" ?all t) == "-abc"  "sub ?all: zero-width still first-only (engine)")
let((l_r)
    l_r = ycRegEx::ReSubn("\\d" "#" "a1b2c" ?all t)
    _assert(car(l_r) == "a#b#c" && car(cdr(l_r)) == 2  "subn ?all -> ('a#b#c', 2)")
    l_r = ycRegEx::ReSubn("\\d" "#" "a1b2c")
    _assert(car(l_r) == "a#b2c" && car(cdr(l_r)) == 1  "subn default single -> ('a#b2c', 1)")
)

; ---------- match / search / fullmatch spans ----------
_assertSameSpan(ycRegEx::ReMatch("\\d+" "123abc") 0 3  "match: digits span")
_assert(ycRegEx::ReMatch("\\d+" "a123") == nil  "match: no match at 0")
_assertSameSpan(ycRegEx::ReSearch("\\d+" "a123") 1 4  "search: digits span")
_assertSameSpan(ycRegEx::ReFullmatch("\\d+" "123") 0 3  "fullmatch: digits span")
_assert(ycRegEx::ReFullmatch("\\d+" "123a") == nil  "fullmatch: trailing junk -> nil")
_assertSameSpan(ycRegEx::ReFullmatch("a|ab" "ab") 0 2  "fullmatch: alternation span")
_assert(ycRegEx::ReMatch("^b" "a\nb") == nil  "match: caret without M")
_assertSameSpan(ycRegEx::ReSearch("(?m)^b" "a\nb") 2 3  "search: multiline caret span")
_assert(ycRegEx::ReSearch("a" "") == nil  "search: empty subject no match")
_assertSameSpan(ycRegEx::ReSearch("a*" "") 0 0  "search: zero-width empty subject")
_assertSameSeq(ycRegEx::ReSearch("(a)(b)" "xxab")->groups() '("a" "b")  "search: group values")
_assertSameSpan(ycRegEx::ReSearch("(?:ab)+" "xxabab") 2 6  "search: non-capturing span")
_assertSameSpan(ycRegEx::ReSearch("(?P<y>\\d{4})" "y2026") 1 5  "search: named group span")
_assert(ycRegEx::ReSearch("(?P<y>\\d{4})" "y2026")->group(1) == "2026"  "search: named group value")
_assertSameSpan(ycRegEx::ReSearch("(a)\\1" "aa") 0 2  "search: backref span")
_assert(ycRegEx::ReSearch("(a)\\1" "ab") == nil  "search: failed backref")
_assertSameSpan(ycRegEx::ReSearch("foo(?=bar)" "foobar") 0 3  "search: lookahead span")
_assert(ycRegEx::ReSearch("foo(?=bar)" "foobaz") == nil  "search: failed lookahead")
_assertSameSpan(ycRegEx::ReSearch("" "abc") 0 0  "search: empty pattern at 0")
_assertSameSpan(ycRegEx::ReSearch("(?m)$" "a\nb") 1 1  "search: multiline end anchor (1,1)")
_assertSameSpan(ycRegEx::ReSearch("\\Z" "ab") 2 2  "search: \\Z anchor (2,2)")
_assertSameSpan(ycRegEx::ReSearch("中文" "前中文后") 3 9  "search: CJK byte span (CPython (1,3))")
_assertSameSpan(ycRegEx::ReMatch("foo(?=bar)" "foobar") 0 3  "match: lookahead span")
_assert(ycRegEx::ReFullmatch("foo(?=bar)" "foobar") == nil  "fullmatch: lookahead w/o trailing ctx (CPython None)")
_assertSameSpan(ycRegEx::ReFullmatch("a+" "aaa") 0 3  "fullmatch: greedy span")
_assertSameSpan(ycRegEx::ReFullmatch("a+?" "aaa") 0 3  "fullmatch: lazy span")

; ---------- A1: left-context patterns on the scan path ----------
; Regression pins for the old suffix re-anchor bug: _nextMatch used to match
; "\A(?:pat)" against a suffix, so anything left of the candidate offset was
; invisible - lookbehind never matched, and a user-written ^ or \A fired at
; every suffix head. _anchorAt now anchors exactly at the offset on the full
; subject; these cases go red again if left context ever becomes invisible.
; CPython 3.12.13 reference value is on every line.
_assertSameSeq(ycRegEx::ReFindall("(?<=\\d)\\w" "a1b") '("b")  "A1 findall: lookbehind digit (CPython ['b'])")
_assertSameSeq(ycRegEx::ReFindall("(?<=a)b" "ab") '("b")  "A1 findall: literal lookbehind (CPython ['b'])")
_assertSameSeq(ycRegEx::ReFindall("^a" "ba") nil  "A1 findall: ^ no mid-subject match (CPython [])")
_assertSameSeq(ycRegEx::ReFindall("^a" "a_ba") '("a")  "A1 findall: ^ matches at 0 (CPython ['a'])")
_assertSameSeq(ycRegEx::ReFindall("\\A" "ba") '("")  "A1 findall: \\A only at offset 0 (CPython [''])")
_assertSameSeq(ycRegEx::ReFindall("\\A" "") '("")  "A1 findall: \\A on empty subject (CPython [''])")
_assertSameSeq(ycRegEx::ReFindall("^a" "a\nb") '("a")  "A1 findall: ^ without M, 2 lines (CPython ['a'])")
_assertSameInts(_startsOf(ycRegEx::ReFinditer("\\b" "ab")) '(0 2)  "A1 finditer: \\b starts (CPython [0, 2])")
_assertSameInts(_endsOf(ycRegEx::ReFinditer("\\b" "ab")) '(0 2)  "A1 finditer: \\b ends (CPython [0, 2])")
_assertSameInts(_startsOf(ycRegEx::ReFinditer("^a" "a\nb")) '(0)  "A1 finditer: ^ without M starts (CPython [0])")
_assert(ycRegEx::ReSearch("^a" "ba") == nil  "A1 search: ^ no mid-subject match (CPython None)")
_assertSameSpan(ycRegEx::ReSearch("(?<=a)b" "ab") 1 2  "A1 search: lookbehind span (CPython (1, 2))")
_assertSameSpan(ycRegEx::ReSearch("(?<=\\d)\\w" "a1b") 2 3  "A1 search: lookbehind span digit (CPython (2, 3))")
_assert(ycRegEx::ReSearch("(?<=a)b" "ab")->group(0) == "b"  "A1 search: lookbehind group(0) (CPython 'b')")
_assert(ycRegEx::ReSearch("(?<=a)b" "ab")->expand("x") == "x"  "A1 search: lookbehind expand (CPython 'x')")
_assert(ycRegEx::ReSub("^a" "X" "ba") == "ba"  "A1 sub: ^ default, no substitution (CPython 'ba')")
_assertSameSeq(ycRegEx::ReSplit("^a" "ba") '("ba")  "A1 split: ^ default, no split (CPython ['ba'])")

; (A2 block removed: count>=2 kernel _replaceN retired in favor of ?all)

; ---------- A3: fullmatch anchor gate (PCRE \z vs Python \Z) ----------
_assert(ycRegEx::ReFullmatch("a$" "a\n") == nil  "A3 fullmatch: $ + trailing newline -> nil (CPython None)")
_assertSameSpan(ycRegEx::ReFullmatch("a$\n" "a\n") 0 2  "A3 fullmatch: pattern newline anchors end (CPython (0, 2))")

; ---------- A4: left-context on ?all path, & parity, finditer ----------
_assert(ycRegEx::ReSub("(?<=a)b" "X" "ab" ?all t) == "aX"  "A4 sub ?all: lookbehind (CPython 'aX')")
_assert(ycRegEx::ReSub("(?<=a)(b)" "<\\1>" "ab" ?all t) == "a<b>"  "A4 sub ?all: lookbehind group ref (CPython 'a<b>')")
_assert(ycRegEx::ReSub("b" "[&]" "abc" ?all t) == "a[b]c"  "A4 sub ?all: & (engine)")
_assertSameSeq(ycRegEx::ReSplit("(?<=,)" "a,b" ?all t) '("a," "b")  "A4 split ?all: lookbehind (CPython ['a,', 'b'])")
_assertSameInts(_startsOf(ycRegEx::ReFinditer("(?<=a)b" "ab ab")) '(1 4)  "A4 finditer: lookbehind starts (CPython [1, 4])")
_assertSameInts(_endsOf(ycRegEx::ReFinditer("(?<=a)b" "ab ab")) '(2 5)  "A4 finditer: lookbehind ends (CPython [2, 5])")

; ---------- non-participating / zero-group Match values ----------
let((m)
    m = ycRegEx::ReSearch("(a)|(b)" "ab")
    _assertSameSeq(m->groups() '("a" "")  "groups: CPython ('a', None) -> ('a', '')")
    _assert(m->group(2) == ""  "group(2): CPython None -> ''")
    m = ycRegEx::ReSearch("(x)*" "a")
    _assertSameSeq(m->groups() '("")  "groups: zero-rep group (CPython (None,))")
    m = ycRegEx::ReSearch("abc" "abc")
    _assertSameSeq(m->groups() nil  "groups: zero-group -> ()")
    _assert(m->group(0) == "abc"  "group(0): whole string")
)

; ---------- expand '&' engine pin ----------
let((m)
    m = ycRegEx::ReSearch("(\\d+)-(\\d+)" "x10-20y")
    _assert(m->expand("&") == "10-20"  "expand: & = whole match in engine (CPython literal '&')")
)

; ---------- flags ----------
_assertSameSpan(ycRegEx::ReSearch("^hello" "Say\nHELLO" ?flags "IM") 4 9  "flags: IM -> (4,9)")
_assertSameSpan(ycRegEx::ReSearch("a b" "xab" ?flags 'X) 1 3  "flags: X ignores space in pattern")
_assertSameSpan(ycRegEx::ReSearch("a b" "a b") 0 3  "flags: no X, space literal")
_assertSameSpan(ycRegEx::ReSearch("a.b" "a\nb" ?flags 'S) 0 3  "flags: S dot matches newline")
_assert(ycRegEx::ReSearch("a.b" "a\nb") == nil  "flags: dot without S skips newline")
_assertSameSpan(ycRegEx::ReSearch("^b" "a\nb" ?flags 'M) 2 3  "flags: M ^ matches line start")
_assert(ycRegEx::ReSearch("^b" "a\nb") == nil  "flags: ^ without M only string start")

_TestParityDone = t
; END
