_WithCalls = nil
_WithBodyRan = nil


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
    _WithCalls = tconc(_WithCalls 'noexit-enter)
    self
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


; ---------- tests ----------

_WithCalls = nil
_Assert(ycWith(x makeInstance('WithOk)
        42) == 42
    "with: returns last body value")
_AssertSameSeq(car(_WithCalls) list('ok)
    "with: exit called on normal return")

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

_TestChildDone = t

; END
