; --- 构造与驻留 ---
_assert(ycCodec::Type("TRUE") == ycCodec::True  "sentinel: constructor canonicalizes TRUE")
_assert(ycCodec::Type("false") == ycCodec::False  "sentinel: constructor canonicalizes false")
_assert(ycCodec::Type("true") == ycCodec::Type("TRUE")  "sentinel: constructor returns the unique True instance")
_assert(ycCodec::Type("Null") == ycCodec::Null  "sentinel: constructor returns the unique Null instance")
_assert(ycCodec::Type("missing") == ycCodec::Missing  "sentinel: constructor returns the unique Missing instance")

; --- 转换 ---
_assert(ycCodec::True->toSkill() == t  "sentinel: True toSkill is t")
_assert(ycCodec::False->toSkill() == nil  "sentinel: False toSkill is nil")
_assert(ycCodec::Null->toSkill() == 'unbound  "sentinel: Null toSkill is unbound")
_assert(ycCodec::Missing->toSkill() == 'unbound  "sentinel: Missing toSkill is unbound")

; --- 错误 ---
_assertError(lambda(() ycCodec::Type("xml"))  "sentinel: unknown Type name errors")
_assertError(lambda(() ycCodec::Type(42))  "sentinel: integer Type name errors")
_assertError(lambda(() ycCodec::Type(1.5))  "sentinel: float Type name errors")

; --- 打印 ---
_assert(printself(ycCodec::True) == "ycCodec::Type(\"True\")"  "sentinel: True printself format")
_assert(printself(ycCodec::False) == "ycCodec::Type(\"False\")"  "sentinel: False printself format")
_assert(printself(ycCodec::Missing) == "ycCodec::Type(\"Missing\")"  "sentinel: Missing printself format")
_assert(car(errset(evalstring(printself(ycCodec::Null)) nil)) == ycCodec::Null  "sentinel: evalstring roundtrip")
_TestSentinelDone = t

; END
