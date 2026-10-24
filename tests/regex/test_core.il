; ycRegEx core suite.
; Expectations are engine-proven behavior unless a comment marks the CPython
; value for a pinned divergence.

; --- 1. first-run smoke (errset-wrapped: capability failure fails the test, not the file) ---
_AssertOk(errset(ycRegEx::Match("\\Aabc" "abc") != nil nil)  "smoke: \\A anchor compiles and gates")
_AssertOk(errset(length(ycRegEx::Findall("\\d+" "a1b22")) == 2 nil)  "smoke: source backslashes 2-write")
_AssertOk(errset(length(ycRegEx::Findall("a*" "")) == 1 nil)  "smoke: empty subject engine call")
_AssertOk(errset(ycRegEx::Search("(?P<y>\\d{4})" "y2026") != nil nil)  "smoke: named group syntax")
_AssertOk(errset(ycRegEx::Search("(a)\\1" "aa") != nil nil)  "smoke: user backref across non-capturing wrap")
_AssertOk(errset(ycRegEx::Search("a++b" "aaab") != nil nil)  "smoke: possessive quantifier")
_AssertOk(errset(ycRegEx::Search("foo(?=bar)" "foobar") != nil nil)  "smoke: lookahead")
_AssertOk(errset(ycRegEx::Search("(?i)abc" "xABC") != nil nil)  "smoke: inline flag")
_AssertOk(errset(ycRegEx::Search("(\\d+)-(\\d+)" "a10-20b") != nil nil)  "smoke: & whole-text extraction")
_AssertOk(errset(length(ycRegEx::Findall("" "ab")) == 3 nil)  "smoke: empty pattern")
_AssertOk(errset(ycRegEx::Search("(?:ab)+" "xxabab") != nil nil)  "smoke: non-capturing span wrap")
_AssertOk(errset(ycRegEx::Fullmatch("a|ab" "ab") != nil nil)  "smoke: third object \\A(?:)\\z")

; --- 2. anchors / match spans ---
let((m)
    m = ycRegEx::Match("\\Aabc" "abc")
    _Assert(m && m->start() == 0 && m->end() == 3  "match: \\A span (0,3)")
    _Assert(ycRegEx::Match("\\Aabc" "xabc") == nil  "match: \\A rejects offset subject")
    m = ycRegEx::Match("\\d+" "123abc")
    _Assert(m && m->start() == 0 && m->end() == 3  "match: digits span (0,3)")
    _Assert(ycRegEx::Match("\\d+" "a123") == nil  "match: no match at 0 -> nil")
    m = ycRegEx::Match("(?m)^a" "ab")
    _Assert(m && m->start() == 0 && m->end() == 1  "match: (?m)^a span (0,1)")
    _Assert(ycRegEx::Match("^b" "a\nb") == nil  "match: ^ without M is string start")
    m = ycRegEx::Match("foo(?=bar)" "foobar")
    _Assert(m && m->start() == 0 && m->end() == 3  "match: lookahead span (0,3)")
)

; --- 3. fullmatch third object ---
let((m)
    m = ycRegEx::Fullmatch("a|ab" "ab")
    _Assert(m && m->start() == 0 && m->end() == 2  "fullmatch: a|ab consumes whole subject")
    m = ycRegEx::Fullmatch("a+" "aaa")
    _Assert(m && m->start() == 0 && m->end() == 3  "fullmatch: greedy span (0,3)")
    m = ycRegEx::Fullmatch("a+?" "aaa")
    _Assert(m && m->start() == 0 && m->end() == 3  "fullmatch: lazy still whole (0,3)")
    _Assert(ycRegEx::Fullmatch("foo(?=bar)" "foobar") == nil  "fullmatch: lookahead fails without trailing context")
    _Assert(ycRegEx::Fullmatch("\\d+" "123a") == nil  "fullmatch: trailing junk -> nil")
)

; --- 4. search path: lazy span + lookahead position + expand ---
let((m)
    m = ycRegEx::Search("(\\d+)-(\\d+)" "a10-20b")
    _Assert(m && m->start() == 1 && m->end() == 6  "search: lazy span (1,6)")
    _Assert(m->group() == "10-20"  "search: group() whole")
    _AssertSameSeq(m->groups() '("10" "20")  "search: groups()")
    _AssertSameInts(m->span() '(1 6)  "search: span list (1 6)")
    _Assert(m->expand("\\2-\\1") == "20-10"  "search: expand reverse refs")
    _Assert(m->expand("\\1") == "10"  "search: expand single ref")
    _Assert(m->expand("literal-abc") == "literal-abc"  "search: expand literal passthrough")
    m = ycRegEx::Search("foo(?=bar)" "foobar")
    _Assert(m && m->start() == 0 && m->end() == 3  "search: lookahead span (0,3)")
    _Assert(m->group() == "foo"  "search: lookahead group() 'foo'")
    _Assert(ycRegEx::Search("foo(?=bar)" "foobaz") == nil  "search: failed lookahead -> nil")
    m = ycRegEx::Fullmatch("a+" "aaa")
    _Assert(m && m->expand("x") == "x"  "fullmatch: expand re-establishes on _full anchor")
)

; --- 4b. search beyond the old 64KB anchor limit ---
let((t_subj m)
    t_subj = strcat(sprintf(nil "%70000s" "") "x")
    m = ycRegEx::Search("x" t_subj)
    _Assert(m && m->start() == 70000  "search: >64KB start")
    _Assert(m && m->end() == 70001    "search: >64KB end")
    _AssertSameSeq(ycRegEx::Findall("x" t_subj) '("x")  "findall: >64KB")
    m = car(ycRegEx::Finditer("x" t_subj))
    _Assert(m && m->start() == 70000  "finditer: >64KB start")
    _AssertSameSeq(ycRegEx::Findall("(?=x)" t_subj) '("")  "findall: >64KB zero-width")
    m = car(ycRegEx::Finditer("(?=x)" t_subj))
    _Assert(m && m->start() == 70000  "finditer: >64KB zero-width start")
    m = car(ycRegEx::Finditer("(?<=x)" t_subj))
    _Assert(m && m->start() == 70001  "finditer: >64KB lookbehind zero-width")
    _AssertSameSeq(ycRegEx::Compile("(?=x)" ?compileOpts 'caseLess)->findall(t_subj)
        '("")  "findall: >64KB zero-width with compileOpts"
    )
    _AssertSameSeq(ycRegEx::Findall("(?= )" t_subj ?execOpts 'anchored)
        '("")  "findall: >64KB anchored zero-width"
    ))
_AssertSameSeq(ycRegEx::Findall("(?=(a))" "aa") '("a" "a")  "findall: zero-width capture")

; --- 5. group family ---
let((m)
    m = ycRegEx::Search("(\\d+)-(\\d+)" "a10-20b")
    _Assert(m->group(0) == "10-20"  "group: 0 = whole")
    _Assert(m->group(1) == "10"  "group: 1")
    _Assert(m->group() == "10-20"  "group: no args = whole")
    _AssertSameSeq(m->group(1 2) '("10" "20")  "group: multi-arg -> list")
    _AssertSameSeq(m->group(0 1) '("10-20" "10")  "group: mixed 0 -> list")
    _AssertError(lambda(() m->group("zz") t)  "group: by-name raises (reserved)")
    _AssertError(lambda(() m->group(9) t)  "group: out of range raises")
    _AssertError(lambda(() m->groupdict() t)  "groupdict: raises (reserved)")
    _AssertError(lambda(() m->span(1) t)  "span: group arg raises (reserved)")
    _AssertError(lambda(() m->start(1) t)  "start: group arg raises (reserved)")
    _AssertError(lambda(() m->end(1) t)  "end: group arg raises (reserved)")
    _Assert(printself(m) == "<ycRegEx::Matched \"a10-20b\">"  "Matched: printself literal format")
)

; --- 5b. >9 capture groups ---
let((l_pat m p)
    l_pat = "(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)"
    m = ycRegEx::Search(l_pat "abcdefghijkl")
    _Assert(m != nil  "groups>9: search")
    _Assert(m->group(10) == "j"  "groups>9: group(10)")
    _Assert(m->group(12) == "l"  "groups>9: group(12)")
    _AssertSameSeq(m->groups()
        '("a" "b" "c" "d" "e" "f" "g" "h" "i" "j" "k" "l")
        "groups>9: groups()"
    )
    _Assert(m->expand("\\{10}\\{12}") == "jl"  "groups>9: expand")
    p = ycRegEx::Compile(l_pat)
    _Assert(p->groups() == 12  "groups>9: Pattern->groups")
    _AssertSameSeq(car(p->findall("abcdefghijkl"))
        '("a" "b" "c" "d" "e" "f" "g" "h" "i" "j" "k" "l")
        "groups>9: findall"
    )
    _Assert(p->sub("\\{12}\\{1}" "abcdefghijkl") == "la"  "groups>9: sub")
)

; --- 5b2. zero-width numeric references ---
_AssertSameSeq(ycRegEx::Findall("(a)?\1?" "b") '("" "")  "zero-width: numeric backref")
_AssertSameSeq(ycRegEx::Findall("(a)?(?(1)b|)" "b") '("" "")  "zero-width: numeric conditional")
_AssertSameSeq(ycRegEx::Compile("(?P<n>a)?" ?compileOpts 'no_auto_capture)->findall("b")
    '("" "")  "zero-width: no_auto_capture"
)

; --- 5c. group type contract / groups isolation ---
let((m l_g)
    m = ycRegEx::Search("(\\d+)-(\\d+)" "a10-20b")
    _AssertError(lambda(() m->group(1.0) t)  "group: float 1.0 raises")
    _AssertError(lambda(() m->group(1.5) t)  "group: float 1.5 raises")
    _AssertError(lambda(() m->group(0.0) t)  "group: float 0.0 raises")
    let((l_r t_msg)
        l_r = errset(m->group(1.0) nil)
        t_msg = car(car(cdr(cdr(cdr(cdr(errset.errset))))))
        _Assert(!l_r && pcreMatchp("expected group number" t_msg)
            "group: float error has Matched->group context"
        )
    )
    l_g = m->groups()
    setcar(l_g "X")
    _Assert(m->group(1) == "10"  "groups: returned list is a copy")
    _AssertSameSeq(m->groups() '("10" "20")  "groups: internal state unchanged")
)

; --- 5d. anchor offset hard limit ---
let((p l_r t_msg)
    p = ycRegEx::Compile("x")
    _Assert(pcreObjectp(ycRegEx:::_AnchorAt(p 65535))  "anchor: 65535 allowed")
    l_r = errset(ycRegEx:::_AnchorAt(p 65536) nil)
    t_msg = car(car(cdr(cdr(cdr(cdr(errset.errset))))))
    _Assert(!l_r && pcreMatchp("65535-byte limit" t_msg)
        "anchor: 65536 has explicit limit message"
    )
    l_r = errset(ycRegEx:::_AnchorAt(p 70000) nil)
    t_msg = car(car(cdr(cdr(cdr(cdr(errset.errset))))))
    _Assert(!l_r && pcreMatchp("65535-byte limit" t_msg)
        "anchor: 70000 has explicit limit message"
    )
)

; --- 5e. groups empty replacement ---
let((m)
    m = ycRegEx::Search("(a)|(b)" "a")
    _AssertSameSeq(m->groups() '("a" "")  "groups: default keeps empty")
    _AssertSameSeq(m->groups(?empty "NA") '("a" "NA")  "groups: replaces empty")
    _Assert(car(cdr(m->groups(?empty 0))) == 0  "groups: replacement accepts any type")
    _Assert(car(cdr(m->groups(?empty nil))) == nil  "groups: nil replacement")
    m = ycRegEx::Search("(a)()" "a")
    _AssertSameSeq(m->groups(?empty "NA") '("a" "NA")  "groups: matched empty also replaced")
)
_Assert(ycRegEx::Search("a" "a")->groups(?empty "NA") == nil  "groups: no groups stays nil")

; --- 6. non-participating groups (pinned: CPython None -> "") ---
let((m)
    m = ycRegEx::Fullmatch("(a)|(ab)" "ab")
    _Assert(m && m->group() == "ab"  "fullmatch: whole 'ab'")
    _Assert(m->group(1) == ""  "fullmatch: group(1) '' (CPython None)")
    _Assert(m->group(2) == "ab"  "fullmatch: group(2) 'ab'")
    _AssertSameSeq(m->groups() '("" "ab")  "groups: CPython (None,'ab') -> ('','ab')")
    m = ycRegEx::Search("(a)|(b)" "ab")
    _AssertSameSeq(m->groups() '("a" "")  "groups: CPython ('a',None) -> ('a','')")
    _Assert(m->group(2) == ""  "group(2): CPython None -> ''")
)

; --- 7. error contracts (free functions) ---
_AssertError(lambda(() ycRegEx::Compile("(") t)  "compile: unbalanced paren raises")
_AssertError(lambda(() ycRegEx::Compile("*") t)  "compile: nothing to repeat raises")
_AssertError(lambda(() ycRegEx::Compile(42) t)  "compile: non-string pattern raises")
_AssertError(lambda(() ycRegEx::Search(42 "a") t)  "search: non-string pattern raises")
_AssertError(lambda(() ycRegEx::Search("a" 42) t)  "search: non-string subject raises")
_AssertError(lambda(() ycRegEx::Search("a" nil) t)  "search: nil subject raises")
_AssertError(lambda(() ycRegEx::Match("a" "b" ?flags 'Z) t)  "match: unknown flag raises")
_AssertError(lambda(() ycRegEx::Match("a" "b" ?flags 2) t)  "match: numeric flag raises")
_Assert(ycRegEx::Match("a" "A" ?flags "I") != nil  "match: string flags accepted")
_AssertError(lambda(() ycRegEx::Search(ycRegEx::Compile("\\d+") "1" ?flags 'I) t)  "search: flags + compiled pattern raise")
_AssertError(lambda(() ycRegEx::Sub("\\d" "#" "a1b2" ?flags 'g) t)  "flags: 'g rejected -> use ?all")
_Assert(ycRegEx::Match("a" "A" ?flags 'i) != nil  "flags: symbol 'i caseless")
_Assert(ycRegEx::Match("ab" "AB" ?flags "iI") != nil  "flags: mixed-case duplicate ok")
_Assert(ycRegEx::Match("a" "a" ?flags "") != nil  "flags: empty string = no flags")
_AssertError(lambda(() ycRegEx::Findall("\\d" "a1b2" ?all t) t)  "findall: ?all is not a key -> raises")

; --- 8. marker conflict pins (readme limitation fixtures) ---
let((l_r)
    l_r = ycRegEx::Subn("x" "y" "<YC-N>x")
    _Assert(car(l_r) == "y"  "subn: marker-in-subject stripped (CPython '<YC-N>y')")
    _Assert(car(cdr(l_r)) == 2  "subn: marker double counted (CPython 1)")
)
_AssertSameSeq(ycRegEx::Findall("(<YC-B>)" "<YC-B>") '("<YC-B>")  "findall: marker inside group preserved")

; --- 9. byte engine facts ---
_Assert(length("中文") == 6  "byte engine: length counts bytes")
let((l_l)
    l_l = ycRegEx::Finditer("中文" "前中文后")
    _Assert(length(l_l) == 1  "byte engine: one CJK match")
    _AssertSameInts(_StartsOf(l_l) '(3)  "byte engine: CJK start byte 3 (CPython char 1)")
    _AssertSameInts(_EndsOf(l_l) '(9)  "byte engine: CJK end byte 9 (CPython char 3)")
)

; --- 10. Pattern object ---
let((m p p2 l_r)
    p = ycRegEx::Compile("\\d+")
    _Assert(p->groups() == 0  "Pattern: groups count 0")
    _Assert(p->pattern() == "\\d+"  "Pattern: pattern roundtrip")
    _Assert(ycRegEx::Compile(p) == p  "Pattern: reCompile reuses instance")
    _Assert(ycRegEx::Search(p "a123") != nil  "Pattern: free fn accepts compiled instance")
    _AssertError(lambda(() ycRegEx::Compile(p ?flags 'I) t)  "Pattern: reCompile + flags raise")
    _Assert(printself(p) == "<ycRegEx::Pattern \"\\\\d+\">"  "Pattern: printself literal format")
    _Assert(p->match("123") != nil  "Pattern: match method")
    m = p->search("a123")
    _Assert(m && m->start() == 1  "Pattern: search method start 1")
    _Assert(p->fullmatch("123") != nil  "Pattern: fullmatch method")
    _AssertSameSeq(p->findall("a1b22") '("1" "22")  "Pattern: findall method")
    _Assert(length(p->finditer("a1b22")) == 2  "Pattern: finditer length 2")
    _Assert(p->sub("#" "a1b2") == "a#b2"  "Pattern: sub method default single")
    _Assert(p->sub("#" "a1b2" ?all t) == "a#b#"  "Pattern: sub method ?all")
    l_r = p->subn("#" "a1b2")
    _Assert(car(l_r) == "a#b2" && car(cdr(l_r)) == 1  "Pattern: subn default single")
    l_r = p->subn("#" "a1b2" ?all t)
    _Assert(car(l_r) == "a#b#" && car(cdr(l_r)) == 2  "Pattern: subn ?all")
    p2 = ycRegEx::Compile(",")
    _AssertSameSeq(p2->split("a,b,c") '("a" "b,c")  "Pattern: split default single")
    _AssertSameSeq(p2->split("a,b,c" ?all t) '("a" "b" "c")  "Pattern: split ?all")
    _Assert(p2->groups() == 0  "Pattern: groups count 0 (comma)")
    _AssertError(lambda(() p->search("1" 'I) t)  "Pattern: extra positional arg raises")
    _AssertError(lambda(() p->search() t)  "Pattern: missing subject raises")
    _AssertError(lambda(() p->sub("1") t)  "Pattern: missing subject raises")
    _AssertError(lambda(() p->sub(42 "1") t)  "Pattern: non-string repl raises")
)
let((p2)
    p2 = ycRegEx::Compile("(\\d)(\\w)")
    _Assert(p2->groups() == 2  "Pattern: groups count 2")
)

; --- 9b. compile options ---
let((p)
    _Assert(ycRegEx::Compile("ABC" ?compileOpts 'caseLess)->match("abc") != nil
        "compileOpts: caseLess")
    _Assert(ycRegEx::Compile("b" ?compileOpts 'anchored)->search("ab") == nil
        "compileOpts: anchored")
    _Assert(ycRegEx::Compile("(a)" ?compileOpts 'no_auto_capture)->groups() == 0
        "compileOpts: no_auto_capture")
    _Assert(ycRegEx::Compile("a$" ?compileOpts 'dollar_endonly)->search(strcat("a" "\n")) == nil
        "compileOpts: dollar_endonly")
    _Assert(ycRegEx::Compile("a+" ?compileOpts 'ungreedy)->match("aaa")->group() == "a"
        "compileOpts: ungreedy")
    _Assert(ycRegEx::Compile("b" ?compileOpts 'firstline)->search(strcat("a" "\n" "b")) == nil
        "compileOpts: firstline")
    _Assert(ycRegEx::Compile("a b" ?compileOpts 'extended)->match("ab") != nil
        "compileOpts: extended")
    _Assert(ycRegEx::Compile("ABC" ?compileOpts list('caseLess 'anchored))->match("abc") != nil
        "compileOpts: list form")
    p = ycRegEx::Compile("a")
    _AssertError(lambda(() ycRegEx::Compile(p ?compileOpts 'caseLess) t)
        "compileOpts: compiled Pattern rejects options")
    _AssertError(lambda(() ycRegEx::Compile("a" ?compileOpts 'bogus) t)
        "compileOpts: unknown option raises")
    _AssertError(lambda(() ycRegEx::Compile("a" ?compileOpts 42) t)
        "compileOpts: non-symbol option raises")
)

; --- 9c. execution options ---
let((p)
    _Assert(ycRegEx::Search("^a" "a" ?execOpts 'notbol) == nil
        "execOpts: notbol"
    )
    _Assert(ycRegEx::Search("a$" "a" ?execOpts 'noteol) == nil
        "execOpts: noteol"
    )
    _Assert(ycRegEx::Search("a?" "b" ?execOpts 'notempty) == nil
        "execOpts: notempty"
    )
    _Assert(ycRegEx::Search("b" "ab" ?execOpts 'anchored) == nil
        "execOpts: anchored"
    )
    _Assert(ycRegEx::Search("^a" "a" ?execOpts list('notbol 'notempty)) == nil
        "execOpts: list form"
    )
    p = ycRegEx::Compile("^a")
    _Assert(p->search("a" ?execOpts 'notbol) == nil
        "execOpts: Pattern method"
    )
    _AssertError(lambda(() ycRegEx::Search("a" "a" ?execOpts 'bogus) t)
        "execOpts: unknown option raises"
    )
    _AssertError(lambda(() ycRegEx::Search("a" "a" ?execOpts 42) t)
        "execOpts: non-symbol option raises"
    )
    let((m)
        m = ycRegEx::Search("a?" "b a" ?execOpts 'notempty)
        _AssertSameSpan(m 2 3  "execOpts: lazy span keeps option")
        _Assert(m->expand("&") == "a"  "execOpts: expand keeps option")
    )
    _AssertSameSeq(ycRegEx::Findall("x*" "abc" ?execOpts 'anchored) '("")
        "execOpts: anchored zero-width findall"
    )
    _AssertSameSeq(ycRegEx::Findall("a*" "aaa" ?execOpts 'notempty) '("aaa")
        "execOpts: notempty zero-width/mixed"
    )
    _Assert(ycRegEx::Findall("x*" "abc" ?execOpts 'notempty) == nil
        "execOpts: notempty rejects all empty"
    )
    _AssertSameSeq(ycRegEx::Findall("a?" "b a" ?execOpts 'notempty) '("a")
        "execOpts: notempty advances to nonempty"
    )
)

; --- 9d. partial probe ---
_Assert(ycRegEx::Partialp("ab" "a")  "partialp: incomplete prefix")
_Assert(ycRegEx::Partialp("ab" "ab")  "partialp: complete match")
_Assert(ycRegEx::Partialp("ab" "ac") == nil  "partialp: impossible prefix")
_Assert(ycRegEx::Compile("ab")->partialp("a")  "partialp: Pattern method")
_AssertError(lambda(() ycRegEx::Partialp("ab" "a" ?execOpts 'bogus) t)
    "partialp: unknown exec option raises"
)

; --- 10. recursion limit wrappers ---
let((n_orig)
    n_orig = ycRegEx::GetRecursionLimit()
    _Assert(n_orig == 10000000  "recursion: default 10000000")
    _Assert(ycRegEx::SetRecursionLimit(1000)  "recursion: set 1000")
    _Assert(ycRegEx::GetRecursionLimit() == 1000  "recursion: get 1000")
    _Assert(ycRegEx::SetRecursionLimit(n_orig)  "recursion: restore")
    _AssertError(lambda(() ycRegEx::SetRecursionLimit(1.5) t)  "recursion: float rejected")
)

_TestCoreDone = t
; END
