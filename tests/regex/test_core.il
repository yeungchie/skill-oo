; ycRegEx core suite.
; Expectations are engine-proven behavior unless a comment marks the CPython
; value for a pinned divergence.

; --- 1. first-run smoke (errset-wrapped: capability failure fails the test, not the file) ---
_assertOk(errset(ycRegEx::reMatch("\\Aabc" "abc") != nil nil)  "smoke: \\A anchor compiles and gates")
_assertOk(errset(length(ycRegEx::reFindall("\\d+" "a1b22")) == 2 nil)  "smoke: source backslashes 2-write")
_assertOk(errset(length(ycRegEx::reFindall("a*" "")) == 1 nil)  "smoke: empty subject engine call")
_assertOk(errset(ycRegEx::reSearch("(?P<y>\\d{4})" "y2026") != nil nil)  "smoke: named group syntax")
_assertOk(errset(ycRegEx::reSearch("(a)\\1" "aa") != nil nil)  "smoke: user backref across non-capturing wrap")
_assertOk(errset(ycRegEx::reSearch("a++b" "aaab") != nil nil)  "smoke: possessive quantifier")
_assertOk(errset(ycRegEx::reSearch("foo(?=bar)" "foobar") != nil nil)  "smoke: lookahead")
_assertOk(errset(ycRegEx::reSearch("(?i)abc" "xABC") != nil nil)  "smoke: inline flag")
_assertOk(errset(ycRegEx::reSearch("(\\d+)-(\\d+)" "a10-20b") != nil nil)  "smoke: & whole-text extraction")
_assertOk(errset(length(ycRegEx::reFindall("" "ab")) == 3 nil)  "smoke: empty pattern")
_assertOk(errset(ycRegEx::reSearch("(?:ab)+" "xxabab") != nil nil)  "smoke: non-capturing span wrap")
_assertOk(errset(ycRegEx::reFullmatch("a|ab" "ab") != nil nil)  "smoke: third object \\A(?:)\\z")

; --- 2. anchors / match spans ---
let((m)
    m = ycRegEx::reMatch("\\Aabc" "abc")
    _assert(m && m->start() == 0 && m->end() == 3  "match: \\A span (0,3)")
    _assert(ycRegEx::reMatch("\\Aabc" "xabc") == nil  "match: \\A rejects offset subject")
    m = ycRegEx::reMatch("\\d+" "123abc")
    _assert(m && m->start() == 0 && m->end() == 3  "match: digits span (0,3)")
    _assert(ycRegEx::reMatch("\\d+" "a123") == nil  "match: no match at 0 -> nil")
    m = ycRegEx::reMatch("(?m)^a" "ab")
    _assert(m && m->start() == 0 && m->end() == 1  "match: (?m)^a span (0,1)")
    _assert(ycRegEx::reMatch("^b" "a\nb") == nil  "match: ^ without M is string start")
    m = ycRegEx::reMatch("foo(?=bar)" "foobar")
    _assert(m && m->start() == 0 && m->end() == 3  "match: lookahead span (0,3)")
)

; --- 3. fullmatch third object ---
let((m)
    m = ycRegEx::reFullmatch("a|ab" "ab")
    _assert(m && m->start() == 0 && m->end() == 2  "fullmatch: a|ab consumes whole subject")
    m = ycRegEx::reFullmatch("a+" "aaa")
    _assert(m && m->start() == 0 && m->end() == 3  "fullmatch: greedy span (0,3)")
    m = ycRegEx::reFullmatch("a+?" "aaa")
    _assert(m && m->start() == 0 && m->end() == 3  "fullmatch: lazy still whole (0,3)")
    _assert(ycRegEx::reFullmatch("foo(?=bar)" "foobar") == nil  "fullmatch: lookahead fails without trailing context")
    _assert(ycRegEx::reFullmatch("\\d+" "123a") == nil  "fullmatch: trailing junk -> nil")
)

; --- 4. search path: lazy span + lookahead position + expand ---
let((m)
    m = ycRegEx::reSearch("(\\d+)-(\\d+)" "a10-20b")
    _assert(m && m->start() == 1 && m->end() == 6  "search: lazy span (1,6)")
    _assert(m->group() == "10-20"  "search: group() whole")
    _assertSameSeq(m->groups() '("10" "20")  "search: groups()")
    _assertSameInts(m->span() '(1 6)  "search: span list (1 6)")
    _assert(m->expand("\\2-\\1") == "20-10"  "search: expand reverse refs")
    _assert(m->expand("\\1") == "10"  "search: expand single ref")
    _assert(m->expand("literal-abc") == "literal-abc"  "search: expand literal passthrough")
    m = ycRegEx::reSearch("foo(?=bar)" "foobar")
    _assert(m && m->start() == 0 && m->end() == 3  "search: lookahead span (0,3)")
    _assert(m->group() == "foo"  "search: lookahead group() 'foo'")
    _assert(ycRegEx::reSearch("foo(?=bar)" "foobaz") == nil  "search: failed lookahead -> nil")
    m = ycRegEx::reFullmatch("a+" "aaa")
    _assert(m && m->expand("x") == "x"  "fullmatch: expand re-establishes on _full anchor")
)

; --- 4b. search beyond the old 64KB anchor limit ---
let((t_subj m)
    t_subj = strcat(sprintf(nil "%70000s" "") "x")
    m = ycRegEx::reSearch("x" t_subj)
    _assert(m && m->start() == 70000  "search: >64KB start")
    _assert(m && m->end() == 70001    "search: >64KB end")
)

; --- 5. group family ---
let((m)
    m = ycRegEx::reSearch("(\\d+)-(\\d+)" "a10-20b")
    _assert(m->group(0) == "10-20"  "group: 0 = whole")
    _assert(m->group(1) == "10"  "group: 1")
    _assert(m->group() == "10-20"  "group: no args = whole")
    _assertSameSeq(m->group(1 2) '("10" "20")  "group: multi-arg -> list")
    _assertSameSeq(m->group(0 1) '("10-20" "10")  "group: mixed 0 -> list")
    _assertError(lambda(() m->group("zz") t)  "group: by-name raises (reserved)")
    _assertError(lambda(() m->group(9) t)  "group: out of range raises")
    _assertError(lambda(() m->groupdict() t)  "groupdict: raises (reserved)")
    _assertError(lambda(() m->span(1) t)  "span: group arg raises (reserved)")
    _assertError(lambda(() m->start(1) t)  "start: group arg raises (reserved)")
    _assertError(lambda(() m->end(1) t)  "end: group arg raises (reserved)")
    _assert(printself(m) == "<ycRegEx::Match \"a10-20b\">"  "Match: printself literal format")
)

; --- 5b. >9 capture groups ---
let((l_pat m p)
    l_pat = "(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)"
    m = ycRegEx::reSearch(l_pat "abcdefghijkl")
    _assert(m != nil  "groups>9: search")
    _assert(m->group(10) == "j"  "groups>9: group(10)")
    _assert(m->group(12) == "l"  "groups>9: group(12)")
    _assertSameSeq(m->groups()
        '("a" "b" "c" "d" "e" "f" "g" "h" "i" "j" "k" "l")
        "groups>9: groups()"
    )
    _assert(m->expand("\\{10}\\{12}") == "jl"  "groups>9: expand")
    p = ycRegEx::reCompile(l_pat)
    _assert(p->groups() == 12  "groups>9: Pattern->groups")
    _assertSameSeq(car(p->findall("abcdefghijkl"))
        '("a" "b" "c" "d" "e" "f" "g" "h" "i" "j" "k" "l")
        "groups>9: findall"
    )
    _assert(p->sub("\\{12}\\{1}" "abcdefghijkl") == "la"  "groups>9: sub")
)

; --- 5c. group type contract / groups isolation ---
let((m l_g)
    m = ycRegEx::reSearch("(\\d+)-(\\d+)" "a10-20b")
    _assertError(lambda(() m->group(1.0) t)  "group: float 1.0 raises")
    _assertError(lambda(() m->group(1.5) t)  "group: float 1.5 raises")
    _assertError(lambda(() m->group(0.0) t)  "group: float 0.0 raises")
    let((l_r t_msg)
        l_r = errset(m->group(1.0) nil)
        t_msg = car(car(cdr(cdr(cdr(cdr(errset.errset))))))
        _assert(!l_r && pcreMatchp("expected group number" t_msg)
            "group: float error has Match->group context"
        )
    )
    l_g = m->groups()
    setcar(l_g "X")
    _assert(m->group(1) == "10"  "groups: returned list is a copy")
    _assertSameSeq(m->groups() '("10" "20")  "groups: internal state unchanged")
)

; --- 5d. anchor offset hard limit ---
let((p l_r t_msg)
    p = ycRegEx::reCompile("x")
    _assert(pcreObjectp(ycRegEx:::_anchorAt(p 65535))  "anchor: 65535 allowed")
    l_r = errset(ycRegEx:::_anchorAt(p 65536) nil)
    t_msg = car(car(cdr(cdr(cdr(cdr(errset.errset))))))
    _assert(!l_r && pcreMatchp("65535-byte limit" t_msg)
        "anchor: 65536 has explicit limit message"
    )
    l_r = errset(ycRegEx:::_anchorAt(p 70000) nil)
    t_msg = car(car(cdr(cdr(cdr(cdr(errset.errset))))))
    _assert(!l_r && pcreMatchp("65535-byte limit" t_msg)
        "anchor: 70000 has explicit limit message"
    )
)

; --- 5e. groups empty replacement ---
let((m)
    m = ycRegEx::reSearch("(a)|(b)" "a")
    _assertSameSeq(m->groups() '("a" "")  "groups: default keeps empty")
    _assertSameSeq(m->groups(?empty "NA") '("a" "NA")  "groups: replaces empty")
    _assert(car(cdr(m->groups(?empty 0))) == 0  "groups: replacement accepts any type")
    _assert(car(cdr(m->groups(?empty nil))) == nil  "groups: nil replacement")
    m = ycRegEx::reSearch("(a)()" "a")
    _assertSameSeq(m->groups(?empty "NA") '("a" "NA")  "groups: matched empty also replaced")
)
_assert(ycRegEx::reSearch("a" "a")->groups(?empty "NA") == nil  "groups: no groups stays nil")

; --- 6. non-participating groups (pinned: CPython None -> "") ---
let((m)
    m = ycRegEx::reFullmatch("(a)|(ab)" "ab")
    _assert(m && m->group() == "ab"  "fullmatch: whole 'ab'")
    _assert(m->group(1) == ""  "fullmatch: group(1) '' (CPython None)")
    _assert(m->group(2) == "ab"  "fullmatch: group(2) 'ab'")
    _assertSameSeq(m->groups() '("" "ab")  "groups: CPython (None,'ab') -> ('','ab')")
    m = ycRegEx::reSearch("(a)|(b)" "ab")
    _assertSameSeq(m->groups() '("a" "")  "groups: CPython ('a',None) -> ('a','')")
    _assert(m->group(2) == ""  "group(2): CPython None -> ''")
)

; --- 7. error contracts (free functions) ---
_assertError(lambda(() ycRegEx::reCompile("(") t)  "compile: unbalanced paren raises")
_assertError(lambda(() ycRegEx::reCompile("*") t)  "compile: nothing to repeat raises")
_assertError(lambda(() ycRegEx::reCompile(42) t)  "compile: non-string pattern raises")
_assertError(lambda(() ycRegEx::reSearch(42 "a") t)  "search: non-string pattern raises")
_assertError(lambda(() ycRegEx::reSearch("a" 42) t)  "search: non-string subject raises")
_assertError(lambda(() ycRegEx::reSearch("a" nil) t)  "search: nil subject raises")
_assertError(lambda(() ycRegEx::reMatch("a" "b" ?flags 'Z) t)  "match: unknown flag raises")
_assertError(lambda(() ycRegEx::reMatch("a" "b" ?flags 2) t)  "match: numeric flag raises")
_assert(ycRegEx::reMatch("a" "A" ?flags "I") != nil  "match: string flags accepted")
_assertError(lambda(() ycRegEx::reSearch(ycRegEx::reCompile("\\d+") "1" ?flags 'I) t)  "search: flags + compiled pattern raise")
_assertError(lambda(() ycRegEx::reSub("\\d" "#" "a1b2" ?flags 'g) t)  "flags: 'g rejected -> use ?all")
_assert(ycRegEx::reMatch("a" "A" ?flags 'i) != nil  "flags: symbol 'i caseless")
_assert(ycRegEx::reMatch("ab" "AB" ?flags "iI") != nil  "flags: mixed-case duplicate ok")
_assert(ycRegEx::reMatch("a" "a" ?flags "") != nil  "flags: empty string = no flags")
_assertError(lambda(() ycRegEx::reFindall("\\d" "a1b2" ?all t) t)  "findall: ?all is not a key -> raises")

; --- 8. marker conflict pins (readme limitation fixtures) ---
let((l_r)
    l_r = ycRegEx::reSubn("x" "y" "<YC-N>x")
    _assert(car(l_r) == "y"  "subn: marker-in-subject stripped (CPython '<YC-N>y')")
    _assert(car(cdr(l_r)) == 2  "subn: marker double counted (CPython 1)")
)
_assertSameSeq(ycRegEx::reFindall("(<YC-B>)" "<YC-B>") '("")  "findall: marker inside group collapses (CPython ['<YC-B>'])")

; --- 9. byte engine facts ---
_assert(length("中文") == 6  "byte engine: length counts bytes")
let((l_l)
    l_l = ycRegEx::reFinditer("中文" "前中文后")
    _assert(length(l_l) == 1  "byte engine: one CJK match")
    _assertSameInts(_startsOf(l_l) '(3)  "byte engine: CJK start byte 3 (CPython char 1)")
    _assertSameInts(_endsOf(l_l) '(9)  "byte engine: CJK end byte 9 (CPython char 3)")
)

; --- 10. Pattern object ---
let((m p p2 l_r)
    p = ycRegEx::reCompile("\\d+")
    _assert(p->groups() == 0  "Pattern: groups count 0")
    _assert(p->pattern() == "\\d+"  "Pattern: pattern roundtrip")
    _assert(ycRegEx::reCompile(p) == p  "Pattern: reCompile reuses instance")
    _assert(ycRegEx::reSearch(p "a123") != nil  "Pattern: free fn accepts compiled instance")
    _assertError(lambda(() ycRegEx::reCompile(p ?flags 'I) t)  "Pattern: reCompile + flags raise")
    _assert(printself(p) == "<ycRegEx::Pattern \"\\\\d+\">"  "Pattern: printself literal format")
    _assert(p->match("123") != nil  "Pattern: match method")
    m = p->search("a123")
    _assert(m && m->start() == 1  "Pattern: search method start 1")
    _assert(p->fullmatch("123") != nil  "Pattern: fullmatch method")
    _assertSameSeq(p->findall("a1b22") '("1" "22")  "Pattern: findall method")
    _assert(length(p->finditer("a1b22")) == 2  "Pattern: finditer length 2")
    _assert(p->sub("#" "a1b2") == "a#b2"  "Pattern: sub method default single")
    _assert(p->sub("#" "a1b2" ?all t) == "a#b#"  "Pattern: sub method ?all")
    l_r = p->subn("#" "a1b2")
    _assert(car(l_r) == "a#b2" && car(cdr(l_r)) == 1  "Pattern: subn default single")
    l_r = p->subn("#" "a1b2" ?all t)
    _assert(car(l_r) == "a#b#" && car(cdr(l_r)) == 2  "Pattern: subn ?all")
    p2 = ycRegEx::reCompile(",")
    _assertSameSeq(p2->split("a,b,c") '("a" "b,c")  "Pattern: split default single")
    _assertSameSeq(p2->split("a,b,c" ?all t) '("a" "b" "c")  "Pattern: split ?all")
    _assert(p2->groups() == 0  "Pattern: groups count 0 (comma)")
    _assertError(lambda(() p->search("1" 'I) t)  "Pattern: extra positional arg raises")
    _assertError(lambda(() p->search() t)  "Pattern: missing subject raises")
    _assertError(lambda(() p->sub("1") t)  "Pattern: missing subject raises")
    _assertError(lambda(() p->sub(42 "1") t)  "Pattern: non-string repl raises")
)
let((p2)
    p2 = ycRegEx::reCompile("(\\d)(\\w)")
    _assert(p2->groups() == 2  "Pattern: groups count 2")
)

; --- 9b. compile options ---
let((p)
    _assert(ycRegEx::reCompile("ABC" ?compileOpts 'caseLess)->match("abc") != nil
        "compileOpts: caseLess")
    _assert(ycRegEx::reCompile("b" ?compileOpts 'anchored)->search("ab") == nil
        "compileOpts: anchored")
    _assert(ycRegEx::reCompile("(a)" ?compileOpts 'no_auto_capture)->groups() == 0
        "compileOpts: no_auto_capture")
    _assert(ycRegEx::reCompile("a$" ?compileOpts 'dollar_endonly)->search(strcat("a" "\n")) == nil
        "compileOpts: dollar_endonly")
    _assert(ycRegEx::reCompile("a+" ?compileOpts 'ungreedy)->match("aaa")->group() == "a"
        "compileOpts: ungreedy")
    _assert(ycRegEx::reCompile("b" ?compileOpts 'firstline)->search(strcat("a" "\n" "b")) == nil
        "compileOpts: firstline")
    _assert(ycRegEx::reCompile("a b" ?compileOpts 'extended)->match("ab") != nil
        "compileOpts: extended")
    _assert(ycRegEx::reCompile("ABC" ?compileOpts list('caseLess 'anchored))->match("abc") != nil
        "compileOpts: list form")
    p = ycRegEx::reCompile("a")
    _assertError(lambda(() ycRegEx::reCompile(p ?compileOpts 'caseLess) t)
        "compileOpts: compiled Pattern rejects options")
    _assertError(lambda(() ycRegEx::reCompile("a" ?compileOpts 'bogus) t)
        "compileOpts: unknown option raises")
    _assertError(lambda(() ycRegEx::reCompile("a" ?compileOpts 42) t)
        "compileOpts: non-symbol option raises")
)

; --- 9c. execution options ---
let((p)
    _assert(ycRegEx::reSearch("^a" "a" ?execOpts 'notbol) == nil
        "execOpts: notbol"
    )
    _assert(ycRegEx::reSearch("a$" "a" ?execOpts 'noteol) == nil
        "execOpts: noteol"
    )
    _assert(ycRegEx::reSearch("a?" "b" ?execOpts 'notempty) == nil
        "execOpts: notempty"
    )
    _assert(ycRegEx::reSearch("b" "ab" ?execOpts 'anchored) == nil
        "execOpts: anchored"
    )
    _assert(ycRegEx::reSearch("^a" "a" ?execOpts list('notbol 'notempty)) == nil
        "execOpts: list form"
    )
    p = ycRegEx::reCompile("^a")
    _assert(p->search("a" ?execOpts 'notbol) == nil
        "execOpts: Pattern method"
    )
    _assertError(lambda(() ycRegEx::reSearch("a" "a" ?execOpts 'bogus) t)
        "execOpts: unknown option raises"
    )
    _assertError(lambda(() ycRegEx::reSearch("a" "a" ?execOpts 42) t)
        "execOpts: non-symbol option raises"
    )
    let((m)
        m = ycRegEx::reSearch("a?" "b a" ?execOpts 'notempty)
        _assertSameSpan(m 2 3  "execOpts: lazy span keeps option")
        _assert(m->expand("&") == "a"  "execOpts: expand keeps option")
    )
)

; --- 9d. partial probe ---
_assert(ycRegEx::rePartialp("ab" "a")  "partialp: incomplete prefix")
_assert(ycRegEx::rePartialp("ab" "ab")  "partialp: complete match")
_assert(ycRegEx::rePartialp("ab" "ac") == nil  "partialp: impossible prefix")
_assert(ycRegEx::reCompile("ab")->partialp("a")  "partialp: Pattern method")
_assertError(lambda(() ycRegEx::rePartialp("ab" "a" ?execOpts 'bogus) t)
    "partialp: unknown exec option raises"
)

; --- 10. recursion limit wrappers ---
let((n_orig)
    n_orig = ycRegEx::reGetRecursionLimit()
    _assert(n_orig == 10000000  "recursion: default 10000000")
    _assert(ycRegEx::reSetRecursionLimit(1000)  "recursion: set 1000")
    _assert(ycRegEx::reGetRecursionLimit() == 1000  "recursion: get 1000")
    _assert(ycRegEx::reSetRecursionLimit(n_orig)  "recursion: restore")
    _assertError(lambda(() ycRegEx::reSetRecursionLimit(1.5) t)  "recursion: float rejected")
)

_TestCoreDone = t
; END
