_WithCalls = nil
_WithBodyRan = nil
_WithEvals = nil


; ---------- helpers ----------

procedure(_WithMake()  ; -> WithOk
    ; 记录一次对象表达式的求值，并返回新实例。
    ;
    ; **返回**
    ;   (WithOk) - 新实例
    _WithEvals = tconc(_WithEvals 'make)
    makeInstance('WithOk)
)


; ---------- probe classes ----------

defclass(WithOk () ())

defmethod(__ycWithEnter__ (self(WithOk))
    ; 返回自身。
    ;
    ; **参数**
    ;   self  (WithOk) - 实例
    ;
    ; **返回**
    ;   (WithOk) - self
    self
)

defmethod(__ycWithExit__ (self(WithOk))
    ; 记录退出。
    ;
    ; **参数**
    ;   self  (WithOk) - 实例
    ;
    ; **返回**
    ;   (t) - 恒为 t
    _WithCalls = tconc(_WithCalls 'ok)
    t
)

defclass(WithHandle () ())

defmethod(__ycWithEnter__ (self(WithHandle))
    ; 返回一个非对象的绑定值。
    ;
    ; **参数**
    ;   self  (WithHandle) - 实例
    ;
    ; **返回**
    ;   (sym) - handle
    'handle
)

defmethod(__ycWithExit__ (self(WithHandle))
    ; 记录退出。
    ;
    ; **参数**
    ;   self  (WithHandle) - 实例
    ;
    ; **返回**
    ;   (t) - 恒为 t
    _WithCalls = tconc(_WithCalls 'handle)
    t
)

defclass(WithErr () ())

defmethod(__ycWithEnter__ (self(WithErr))
    ; 返回自身。
    ;
    ; **参数**
    ;   self  (WithErr) - 实例
    ;
    ; **返回**
    ;   (WithErr) - self
    self
)

defmethod(__ycWithExit__ (self(WithErr))
    ; 记录退出。
    ;
    ; **参数**
    ;   self  (WithErr) - 实例
    ;
    ; **返回**
    ;   (t) - 恒为 t
    _WithCalls = tconc(_WithCalls 'err)
    t
)

defclass(WithEnterErr () ())

defmethod(__ycWithEnter__ (self(WithEnterErr))
    ; 进入时直接报错。
    ;
    ; **参数**
    ;   self  (WithEnterErr) - 实例
    ;
    ; **返回**
    ;   (never) - 总是报错
    error("with probe: enter failure")
)

defmethod(__ycWithExit__ (self(WithEnterErr))
    ; 记录退出。
    ;
    ; **参数**
    ;   self  (WithEnterErr) - 实例
    ;
    ; **返回**
    ;   (t) - 恒为 t
    _WithCalls = tconc(_WithCalls 'entererr)
    t
)

defclass(WithNoExit () ())

defmethod(__ycWithEnter__ (self(WithNoExit))
    ; 记录进入；用于验证缺 exit 时不会被调用。
    ;
    ; **参数**
    ;   self  (WithNoExit) - 实例
    ;
    ; **返回**
    ;   (WithNoExit) - self
    _WithCalls = tconc(_WithCalls 'noexitenter)
    self
)

defclass(WithOnlyExit () ())

defmethod(__ycWithExit__ (self(WithOnlyExit))
    ; 记录退出；用于验证缺 enter 时不会被调用。
    ;
    ; **参数**
    ;   self  (WithOnlyExit) - 实例
    ;
    ; **返回**
    ;   (t) - 恒为 t
    _WithCalls = tconc(_WithCalls 'onlyexit)
    t
)

defclass(WithPlain () ())

defclass(WithBase () ())

defmethod(__ycWithEnter__ (self(WithBase))
    ; 返回自身。
    ;
    ; **参数**
    ;   self  (WithBase) - 实例
    ;
    ; **返回**
    ;   (WithBase) - self
    self
)

defmethod(__ycWithExit__ (self(WithBase))
    ; 记录退出。
    ;
    ; **参数**
    ;   self  (WithBase) - 实例
    ;
    ; **返回**
    ;   (t) - 恒为 t
    _WithCalls = tconc(_WithCalls 'base)
    t
)

defclass(WithSub (WithBase) ())

defclass(WithNestA () ())

defmethod(__ycWithEnter__ (self(WithNestA))
    ; 返回自身。
    ;
    ; **参数**
    ;   self  (WithNestA) - 实例
    ;
    ; **返回**
    ;   (WithNestA) - self
    self
)

defmethod(__ycWithExit__ (self(WithNestA))
    ; 记录退出。
    ;
    ; **参数**
    ;   self  (WithNestA) - 实例
    ;
    ; **返回**
    ;   (t) - 恒为 t
    _WithCalls = tconc(_WithCalls 'a)
    t
)

defclass(WithNestB () ())

defmethod(__ycWithEnter__ (self(WithNestB))
    ; 返回自身。
    ;
    ; **参数**
    ;   self  (WithNestB) - 实例
    ;
    ; **返回**
    ;   (WithNestB) - self
    self
)

defmethod(__ycWithExit__ (self(WithNestB))
    ; 记录退出。
    ;
    ; **参数**
    ;   self  (WithNestB) - 实例
    ;
    ; **返回**
    ;   (t) - 恒为 t
    _WithCalls = tconc(_WithCalls 'b)
    t
)

defclass(WithNilName () ())

defmethod(__ycWithEnter__ (self(WithNilName))
    ; 记录进入并返回一个应被丢弃的值。
    ;
    ; **参数**
    ;   self  (WithNilName) - 实例
    ;
    ; **返回**
    ;   (sym) - ignored
    _WithCalls = tconc(_WithCalls 'nilenter)
    'ignored
)

defmethod(__ycWithExit__ (self(WithNilName))
    ; 记录退出。
    ;
    ; **参数**
    ;   self  (WithNilName) - 实例
    ;
    ; **返回**
    ;   (t) - 恒为 t
    _WithCalls = tconc(_WithCalls 'nilexit)
    t
)

defclass(WithEnterNil () ())

defmethod(__ycWithEnter__ (self(WithEnterNil))
    ; 记录进入并返回 nil。
    ;
    ; **参数**
    ;   self  (WithEnterNil) - 实例
    ;
    ; **返回**
    ;   (nil) - nil
    _WithCalls = tconc(_WithCalls 'enternil)
    nil
)

defmethod(__ycWithExit__ (self(WithEnterNil))
    ; 记录退出。
    ;
    ; **参数**
    ;   self  (WithEnterNil) - 实例
    ;
    ; **返回**
    ;   (t) - 恒为 t
    _WithCalls = tconc(_WithCalls 'enternilx)
    t
)

defclass(WithExitErr () ())

defmethod(__ycWithEnter__ (self(WithExitErr))
    ; 返回自身。
    ;
    ; **参数**
    ;   self  (WithExitErr) - 实例
    ;
    ; **返回**
    ;   (WithExitErr) - self
    self
)

defmethod(__ycWithExit__ (self(WithExitErr))
    ; 退出时直接报错。
    ;
    ; **参数**
    ;   self  (WithExitErr) - 实例
    ;
    ; **返回**
    ;   (never) - 总是报错
    error("with probe: exit failure")
)


; ---------- tests ----------

_WithCalls = nil
_Assert(ycWith(x makeInstance('WithOk)
        42) == 42
    "with: returns last body value")
_AssertSameSeq(car(_WithCalls) list('ok)
    "with: exit called on normal return")

_WithCalls = nil
_WithEvals = nil
_Assert(ycWith(x _WithMake()
        3) == 3
    "with: object expression value is used once")
_Assert(length(car(_WithEvals)) == 1
    "with: object expression runs exactly once")

_WithCalls = nil
_Assert(ycWith(h makeInstance('WithHandle)
        h == 'handle)
    "with: enter return binds")
_AssertSameSeq(car(_WithCalls) list('handle)
    "with: exit sees the original object")

_WithCalls = nil
let((res)
    res = errset(ycWith(x makeInstance('WithErr)
            error("with probe: body failure")
        ) nil)
    _Assert(res == nil  "with: body error propagates")
    _AssertSameSeq(car(_WithCalls) list('err)
        "with: exit runs on body error")
)

_WithCalls = nil
_AssertErrorMsg(lambda(() ycWith(x makeInstance('WithEnterErr)
            x))
    "with probe: enter failure"  "with: enter error propagates")
_Assert(_WithCalls == nil  "with: exit not called when enter fails")

_WithCalls = nil
_WithBodyRan = nil
_AssertErrorMsg(lambda(() ycWith(x makeInstance('WithPlain)
            _WithBodyRan = t))
    "does not implement __ycWithEnter__"  "with: missing enter rejected")
_Assert(_WithCalls == nil && _WithBodyRan == nil
    "with: missing enter never reaches the body")

_WithCalls = nil
_WithBodyRan = nil
_AssertErrorMsg(lambda(() ycWith(x makeInstance('WithNoExit)
            _WithBodyRan = t))
    "does not implement __ycWithExit__"  "with: missing exit rejected before enter")
_Assert(_WithCalls == nil && _WithBodyRan == nil
    "with: missing exit never calls enter or the body")

_WithCalls = nil
_WithBodyRan = nil
_AssertErrorMsg(lambda(() ycWith(x makeInstance('WithOnlyExit)
            _WithBodyRan = t))
    "does not implement __ycWithEnter__"  "with: only exit rejected")
_Assert(_WithCalls == nil && _WithBodyRan == nil
    "with: only exit never calls exit or the body")

_AssertErrorMsg(lambda(() ycWith(x nil
            x))
    "expression evaluated to nil"  "with: nil expression rejected")

_WithCalls = nil
_Assert(ycWith(x makeInstance('WithSub)
        7) == 7
    "with: inherited hooks work")
_AssertSameSeq(car(_WithCalls) list('base)
    "with: inherited exit called")

_WithCalls = nil
_Assert(ycWith(a makeInstance('WithNestA)
        ycWith(b makeInstance('WithNestB)
            99)) == 99
    "with: nested returns inner value")
_AssertSameSeq(car(_WithCalls) list('b 'a)
    "with: nested exits inner first")

_AssertErrorMsg(lambda(() __ycWithEnter__(makeInstance('WithPlain)))
    "does not implement __ycWithEnter__"  "with: default hook reports the class")

_WithCalls = nil
_Assert(ycWith(nil makeInstance('WithNilName)
        42) == 42
    "with: nil name returns the body value")
_AssertSameSeq(car(_WithCalls) list('nilenter 'nilexit)
    "with: nil name still calls both hooks")

_WithCalls = nil
let((res)
    res = errset(ycWith(nil makeInstance('WithNilName)
            error("with probe: nil body failure")
        ) nil)
    _Assert(res == nil  "with: nil name body error propagates")
    _AssertSameSeq(car(_WithCalls) list('nilenter 'nilexit)
        "with: nil name exits on body error")
)

_WithCalls = nil
_WithBodyRan = nil
_AssertErrorMsg(lambda(() ycWith(nil makeInstance('WithEnterErr)
            _WithBodyRan = t))
    "with probe: enter failure"  "with: nil name enter error propagates")
_Assert(_WithCalls == nil && _WithBodyRan == nil
    "with: nil name never exits when enter fails")

_WithCalls = nil
_Assert(ycWith(x makeInstance('WithEnterNil)
        list(x)) == list(nil)
    "with: enter may return nil")
_AssertSameSeq(car(_WithCalls) list('enternil 'enternilx)
    "with: enter nil still calls exit")

_WithCalls = nil
_Assert(ycWith(x makeInstance('WithOk)) == nil
    "with: omitted body returns nil")
_AssertSameSeq(car(_WithCalls) list('ok)
    "with: omitted body still exits")

_WithCalls = nil
_Assert(ycWith(nil makeInstance('WithNilName)) == nil
    "with: omitted body with nil name returns nil")
_AssertSameSeq(car(_WithCalls) list('nilenter 'nilexit)
    "with: omitted body with nil name still calls hooks")

_AssertErrorMsg(lambda(() ycWith(x makeInstance('WithExitErr)
            error("with probe: body failure")))
    "with probe: exit failure"  "with: exit error overrides body error")

__ycWithObj__ = 'outer
_Assert(ycWith(x makeInstance('WithOk)
        __ycWithObj__) == 'outer
    "with: hidden binding does not capture body symbols")

_WithCalls = nil
_Assert(ycWith(__ycWithObj__ makeInstance('WithOk)
        className(__ycWithObj__)) == 'WithOk
    "with: binding name may reuse the former hidden name")

let((seen)
    ycWith(ycPathLib::Path makeInstance('WithOk)
        seen = ycPathLib::Path
    )
    _Assert(seen && className(seen) == 'WithOk
        "with: namespace-qualified binding name binds the scope value")
)
_Assert(fboundp('ycPathLib::Path)
    "with: namespace-qualified binding does not clobber the global")

_Assert(errset(expandMacro('(ycWith 42 makeInstance('WithOk) 1)) nil) == nil
    "with: non-symbol binding name rejected")
_AssertErrorMsg(lambda(() expandMacro('(ycWith t makeInstance('WithOk) 1)))
    "symbol other than t"  "with: t is not a usable binding name")

; ---------- 共享标记 ----------

_Assert('ycLang:::NoneArg == findSymbol("NoneArg" ?namespace "ycLang")
    "lang: NoneArg is the namespace symbol constant")
_Assert(!fboundp('ycLang:::NoneArg) && !boundp('ycLang:::NoneArg)
    "lang: NoneArg stays a symbol constant, not a binding")

_TestChildDone = t

; END
