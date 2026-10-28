; ycRegEx parity suite: value tables captured from CPython 3.12.13 re module.
; Comments carry the CPython value whenever the engine intentionally diverges.

; ---------- findall ----------
_AssertSameSeq(ycRegEx::Findall("\\d+" "a1b22c333") '("1" "22" "333")  "findall: digits")
_AssertSameTuples(ycRegEx::Findall("(a)|(b)" "ab") '(("a" "") ("" "b"))  "findall: alt groups tuple")
_AssertSameTuples(ycRegEx::Findall("(\\d)(\\w)" "1a 2b") '(("1" "a") ("2" "b"))  "findall: two groups")
_AssertSameSeq(ycRegEx::Findall("x*" "axbxc") '("" "x" "" "x" "" "")  "findall: zero-width walk")
_AssertSameSeq(ycRegEx::Findall("a*" "") '("")  "findall: empty subject zero-width")
_AssertSameSeq(ycRegEx::Findall("abc" "xABC" ?flags 'I) '("ABC")  "findall: flag 'I")
_AssertSameSeq(ycRegEx::Findall("(?i)abc" "xABC") '("ABC")  "findall: inline (?i)")
_AssertSameSeq(ycRegEx::Findall("a.+b" "ab<b>ab") '("ab<b>ab")  "findall: greedy")
_AssertSameSeq(ycRegEx::Findall("a.+?b" "ab<b>ab") '("ab<b")  "findall: lazy quantifier")
_AssertSameSeq(ycRegEx::Findall("(a)\\1" "aaab") '("a")  "findall: backref")
_AssertSameSeq(ycRegEx::Findall("中文" "中文和中文") '("中文" "中文")  "findall: CJK bytes")
_AssertSameTuples(ycRegEx::Findall("(x)|(y)|(z)" "x z") '(("x" "" "") ("" "" "z"))  "findall: three groups")
_AssertSameSeq(ycRegEx::Findall("(?=a)" "aaa") '("" "" "")  "findall: lookahead empty items")
_AssertSameSeq(ycRegEx::Findall("" "ab") '("" "" "")  "findall: empty pattern")
_AssertSameSeq(ycRegEx::Findall("abc" "xABC") nil  "findall: no match -> empty list")

; ---------- finditer (position tables) ----------
_AssertSameInts(_StartsOf(ycRegEx::Finditer("x*" "axbxc")) '(0 1 2 3 4 5)  "finditer: zero-width starts")
_AssertSameInts(_EndsOf(ycRegEx::Finditer("x*" "axbxc")) '(0 2 2 4 4 5)  "finditer: zero-width ends")
_AssertSameInts(_StartsOf(ycRegEx::Finditer("\\d+" "a1b22")) '(1 3)  "finditer: digits starts")
_AssertSameInts(_EndsOf(ycRegEx::Finditer("\\d+" "a1b22")) '(2 5)  "finditer: digits ends")
_AssertSameInts(_StartsOf(ycRegEx::Finditer("a*" "")) '(0)  "finditer: empty subject start")
_AssertSameInts(_EndsOf(ycRegEx::Finditer("a*" "")) '(0)  "finditer: empty subject end")
_AssertSameInts(_StartsOf(ycRegEx::Finditer("(?m)^b" "a\nb")) '(2)  "finditer: multiline caret start")
_AssertSameInts(_EndsOf(ycRegEx::Finditer("(?m)^b" "a\nb")) '(3)  "finditer: multiline caret end")
_AssertSameInts(_StartsOf(ycRegEx::Finditer("c*" "abc")) '(0 1 2 3)  "finditer: zero-width at end starts")
_AssertSameInts(_EndsOf(ycRegEx::Finditer("c*" "abc")) '(0 1 3 3)  "finditer: zero-width at end ends")
_AssertSameInts(_StartsOf(ycRegEx::Finditer("(?=a)" "aaa")) '(0 1 2)  "finditer: lookahead starts")
_AssertSameInts(_EndsOf(ycRegEx::Finditer("(?=a)" "aaa")) '(0 1 2)  "finditer: lookahead ends")
_AssertSameInts(_StartsOf(ycRegEx::Finditer("a" "aaa")) '(0 1 2)  "finditer: literal starts")
_AssertSameInts(_EndsOf(ycRegEx::Finditer("a" "aaa")) '(1 2 3)  "finditer: literal ends")
_Assert(length(ycRegEx::Finditer("\\d+" "")) == 0  "finditer: no match -> empty list")

; ---------- split ----------
_AssertSameSeq(ycRegEx::Split("\\s+" "a b  c") '("a" "b" "c")  "split default all: whitespace runs")
_AssertSameSeq(ycRegEx::Split("\\s+" "a b  c" ?first t) '("a" "b  c")  "split ?first: whitespace")
_AssertSameSeq(ycRegEx::Split("(\\d)" "a1b2c") '("a" "1" "b" "2" "c")  "split default all: group value in result")
_AssertSameSeq(ycRegEx::Split("(\\d)" "a1b2c" ?first t) '("a" "1" "b2c")  "split ?first: group value")
_AssertSameSeq(ycRegEx::Split("(a)|(b)" "ab") '("" "a" "" "" "" "b" "")  "split default all: alt groups (CPython None -> '')")
_AssertSameSeq(ycRegEx::Split("," "a,b,c") '("a" "b" "c")  "split default all: plain")
_AssertSameSeq(ycRegEx::Split("," "a,b,c" ?first t) '("a" "b,c")  "split ?first: plain")
_AssertSameSeq(ycRegEx::Split("," "") '("")  "split: empty subject")
_AssertSameSeq(ycRegEx::Split("x*" "axbxc") '("" "axbxc")  "split default all: zero-width engine first-only (CPython 7 items)")
_AssertSameSeq(ycRegEx::Split("(?m)^" "a\nb") '("" "a\nb")  "split default all: zero-width caret engine first-only (CPython ['', 'a\\n', 'b'])")
_AssertSameSeq(ycRegEx::Split("" "ab") '("" "ab")  "split default all: empty pattern engine first-only (CPython ['' 'a' 'b' ''])")
_AssertSameSeq(ycRegEx::Split("x*" "") '("" "")  "split default all: zero-width empty subject")
_AssertSameSeq(ycRegEx::Split("," "a<YC-S>b") '("a" "b")  "split default all: marker-in-subject swallowed (CPython ['a<YC-S>b'])")
; ---------- sub / subn ----------
_Assert(ycRegEx::Sub("(x)" "<\\1>" "xa x") == "<x>a <x>"  "sub default all: backref expansion")
_Assert(ycRegEx::Sub("(x)" "<\\1>" "xa x" ?first t) == "<x>a x"  "sub ?first: backref")
_Assert(ycRegEx::Sub("x*" "-" "abc") == "-abc"  "sub: zero-width default-all engine first-only pin (CPython '-a-b-c-')")
_Assert(ycRegEx::Sub("b" "[&]" "abc") == "a[b]c"  "sub: & expands in engine (CPython 'a[&]c')")
_Assert(ycRegEx::Sub("(?i)hello" "X" "Say Hello") == "Say X"  "sub: inline flag")
_Assert(ycRegEx::Sub("a" "X" "") == ""  "sub: empty subject")
_Assert(ycRegEx::Sub("z" "X" "abc") == "abc"  "sub: no match returns subject")
_Assert(ycRegEx::Sub("\\d" "#" "a1b2c") == "a#b#c"  "sub default all: all digits")
_Assert(ycRegEx::Sub("\\d" "#" "a1b2c" ?first t) == "a#b2c"  "sub ?first: first digit")
_Assert(ycRegEx::Sub("x*" "-" "abc") == "-abc"  "sub default all: zero-width still first-only (engine)")
let((l_r)
    l_r = ycRegEx::Subn("\\d" "#" "a1b2c")
    _Assert(car(l_r) == "a#b#c" && car(cdr(l_r)) == 2  "subn default all -> ('a#b#c', 2)")
    l_r = ycRegEx::Subn("\\d" "#" "a1b2c" ?first t)
    _Assert(car(l_r) == "a#b2c" && car(cdr(l_r)) == 1  "subn ?first -> ('a#b2c', 1)")
)

; ---------- match / search / fullmatch spans ----------
_AssertSameSpan(ycRegEx::Match("\\d+" "123abc") 0 3  "match: digits span")
_Assert(ycRegEx::Match("\\d+" "a123") == nil  "match: no match at 0")
_AssertSameSpan(ycRegEx::Search("\\d+" "a123") 1 4  "search: digits span")
_AssertSameSpan(ycRegEx::Fullmatch("\\d+" "123") 0 3  "fullmatch: digits span")
_Assert(ycRegEx::Fullmatch("\\d+" "123a") == nil  "fullmatch: trailing junk -> nil")
_AssertSameSpan(ycRegEx::Fullmatch("a|ab" "ab") 0 2  "fullmatch: alternation span")
_Assert(ycRegEx::Match("^b" "a\nb") == nil  "match: caret without M")
_AssertSameSpan(ycRegEx::Search("(?m)^b" "a\nb") 2 3  "search: multiline caret span")
_Assert(ycRegEx::Search("a" "") == nil  "search: empty subject no match")
_AssertSameSpan(ycRegEx::Search("a*" "") 0 0  "search: zero-width empty subject")
_AssertSameSeq(ycRegEx::Search("(a)(b)" "xxab")->groups() '("a" "b")  "search: group values")
_AssertSameSpan(ycRegEx::Search("(?:ab)+" "xxabab") 2 6  "search: non-capturing span")
_AssertSameSpan(ycRegEx::Search("(?P<y>\\d{4})" "y2026") 1 5  "search: named group span")
_Assert(ycRegEx::Search("(?P<y>\\d{4})" "y2026")->group(1) == "2026"  "search: named group value")
_AssertSameSpan(ycRegEx::Search("(a)\\1" "aa") 0 2  "search: backref span")
_Assert(ycRegEx::Search("(a)\\1" "ab") == nil  "search: failed backref")
_AssertSameSpan(ycRegEx::Search("foo(?=bar)" "foobar") 0 3  "search: lookahead span")
_Assert(ycRegEx::Search("foo(?=bar)" "foobaz") == nil  "search: failed lookahead")
_AssertSameSpan(ycRegEx::Search("" "abc") 0 0  "search: empty pattern at 0")
_AssertSameSpan(ycRegEx::Search("(?m)$" "a\nb") 1 1  "search: multiline end anchor (1,1)")
_AssertSameSpan(ycRegEx::Search("\\Z" "ab") 2 2  "search: \\Z anchor (2,2)")
_AssertSameSpan(ycRegEx::Search("中文" "前中文后") 3 9  "search: CJK byte span (CPython (1,3))")
_AssertSameSpan(ycRegEx::Match("foo(?=bar)" "foobar") 0 3  "match: lookahead span")
_Assert(ycRegEx::Fullmatch("foo(?=bar)" "foobar") == nil  "fullmatch: lookahead w/o trailing ctx (CPython None)")
_AssertSameSpan(ycRegEx::Fullmatch("a+" "aaa") 0 3  "fullmatch: greedy span")
_AssertSameSpan(ycRegEx::Fullmatch("a+?" "aaa") 0 3  "fullmatch: lazy span")

; ---------- A1: left-context patterns on the scan path ----------
; Regression pins for the old suffix re-anchor bug: _NextMatch used to match
; "\A(?:pat)" against a suffix, so anything left of the candidate offset was
; invisible - lookbehind never matched, and a user-written ^ or \A fired at
; every suffix head. _AnchorAt now anchors exactly at the offset on the full
; subject; these cases go red again if left context ever becomes invisible.
; CPython 3.12.13 reference value is on every line.
_AssertSameSeq(ycRegEx::Findall("(?<=\\d)\\w" "a1b") '("b")  "A1 findall: lookbehind digit (CPython ['b'])")
_AssertSameSeq(ycRegEx::Findall("(?<=a)b" "ab") '("b")  "A1 findall: literal lookbehind (CPython ['b'])")
_AssertSameSeq(ycRegEx::Findall("^a" "ba") nil  "A1 findall: ^ no mid-subject match (CPython [])")
_AssertSameSeq(ycRegEx::Findall("^a" "a_ba") '("a")  "A1 findall: ^ matches at 0 (CPython ['a'])")
_AssertSameSeq(ycRegEx::Findall("\\A" "ba") '("")  "A1 findall: \\A only at offset 0 (CPython [''])")
_AssertSameSeq(ycRegEx::Findall("\\A" "") '("")  "A1 findall: \\A on empty subject (CPython [''])")
_AssertSameSeq(ycRegEx::Findall("^a" "a\nb") '("a")  "A1 findall: ^ without M, 2 lines (CPython ['a'])")
_AssertSameInts(_StartsOf(ycRegEx::Finditer("\\b" "ab")) '(0 2)  "A1 finditer: \\b starts (CPython [0, 2])")
_AssertSameInts(_EndsOf(ycRegEx::Finditer("\\b" "ab")) '(0 2)  "A1 finditer: \\b ends (CPython [0, 2])")
_AssertSameInts(_StartsOf(ycRegEx::Finditer("^a" "a\nb")) '(0)  "A1 finditer: ^ without M starts (CPython [0])")
_Assert(ycRegEx::Search("^a" "ba") == nil  "A1 search: ^ no mid-subject match (CPython None)")
_AssertSameSpan(ycRegEx::Search("(?<=a)b" "ab") 1 2  "A1 search: lookbehind span (CPython (1, 2))")
_AssertSameSpan(ycRegEx::Search("(?<=\\d)\\w" "a1b") 2 3  "A1 search: lookbehind span digit (CPython (2, 3))")
_Assert(ycRegEx::Search("(?<=a)b" "ab")->group(0) == "b"  "A1 search: lookbehind group(0) (CPython 'b')")
_Assert(ycRegEx::Search("(?<=a)b" "ab")->expand("x") == "x"  "A1 search: lookbehind expand (CPython 'x')")
_Assert(ycRegEx::Sub("^a" "X" "ba") == "ba"  "A1 sub: ^ default, no substitution (CPython 'ba')")
_AssertSameSeq(ycRegEx::Split("^a" "ba") '("ba")  "A1 split: ^ default, no split (CPython ['ba'])")

; (A2 block removed: count>=2 kernel _replaceN retired in favor of all-matches default)

; ---------- A3: fullmatch anchor gate (PCRE \z vs Python \Z) ----------
_Assert(ycRegEx::Fullmatch("a$" "a\n") == nil  "A3 fullmatch: $ + trailing newline -> nil (CPython None)")
_AssertSameSpan(ycRegEx::Fullmatch("a$\n" "a\n") 0 2  "A3 fullmatch: pattern newline anchors end (CPython (0, 2))")

; ---------- A4: left-context on default-all path, & parity, finditer ----------
_Assert(ycRegEx::Sub("(?<=a)b" "X" "ab") == "aX"  "A4 sub default all: lookbehind (CPython 'aX')")
_Assert(ycRegEx::Sub("(?<=a)(b)" "<\\1>" "ab") == "a<b>"  "A4 sub default all: lookbehind group ref (CPython 'a<b>')")
_Assert(ycRegEx::Sub("b" "[&]" "abc") == "a[b]c"  "A4 sub default all: & (engine)")
_AssertSameSeq(ycRegEx::Split("(?<=,)" "a,b") '("a," "b")  "A4 split default all: lookbehind (CPython ['a,', 'b'])")
_AssertSameInts(_StartsOf(ycRegEx::Finditer("(?<=a)b" "ab ab")) '(1 4)  "A4 finditer: lookbehind starts (CPython [1, 4])")
_AssertSameInts(_EndsOf(ycRegEx::Finditer("(?<=a)b" "ab ab")) '(2 5)  "A4 finditer: lookbehind ends (CPython [2, 5])")

; ---------- non-participating / zero-group Matched values ----------
let((m)
    m = ycRegEx::Search("(a)|(b)" "ab")
    _AssertSameSeq(m->groups() '("a" "")  "groups: CPython ('a', None) -> ('a', '')")
    _Assert(m->group(2) == ""  "group(2): CPython None -> ''")
    m = ycRegEx::Search("(x)*" "a")
    _AssertSameSeq(m->groups() '("")  "groups: zero-rep group (CPython (None,))")
    m = ycRegEx::Search("abc" "abc")
    _AssertSameSeq(m->groups() nil  "groups: zero-group -> ()")
    _Assert(m->group(0) == "abc"  "group(0): whole string")
)

; ---------- expand '&' engine pin ----------
let((m)
    m = ycRegEx::Search("(\\d+)-(\\d+)" "x10-20y")
    _Assert(m->expand("&") == "10-20"  "expand: & = whole match in engine (CPython literal '&')")
)

; ---------- flags ----------
_AssertSameSpan(ycRegEx::Search("^hello" "Say\nHELLO" ?flags "IM") 4 9  "flags: IM -> (4,9)")
_AssertSameSpan(ycRegEx::Search("a b" "xab" ?flags 'X) 1 3  "flags: X ignores space in pattern")
_AssertSameSpan(ycRegEx::Search("a b" "a b") 0 3  "flags: no X, space literal")
_AssertSameSpan(ycRegEx::Search("a.b" "a\nb" ?flags 'S) 0 3  "flags: S dot matches newline")
_Assert(ycRegEx::Search("a.b" "a\nb") == nil  "flags: dot without S skips newline")
_AssertSameSpan(ycRegEx::Search("^b" "a\nb" ?flags 'M) 2 3  "flags: M ^ matches line start")
_Assert(ycRegEx::Search("^b" "a\nb") == nil  "flags: ^ without M only string start")

_TestParityDone = t
; END
