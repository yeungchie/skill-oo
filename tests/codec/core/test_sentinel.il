; --- 构造与驻留 ---
_Assert(ycCodec::Type("TRUE") == ycCodec::True  "sentinel: constructor canonicalizes TRUE")
_Assert(ycCodec::Type("false") == ycCodec::False  "sentinel: constructor canonicalizes false")
_Assert(ycCodec::Type("true") == ycCodec::Type("TRUE")  "sentinel: constructor returns the unique True instance")
_Assert(ycCodec::Type("Null") == ycCodec::Null  "sentinel: constructor returns the unique Null instance")
_Assert(ycCodec::Type("missing") == ycCodec::Missing  "sentinel: constructor returns the unique Missing instance")

; --- 转换 ---
_Assert(ycCodec::True->toSkill() == t  "sentinel: True toSkill is t")
_Assert(ycCodec::False->toSkill() == nil  "sentinel: False toSkill is nil")
_Assert(ycCodec::Null->toSkill() == 'unbound  "sentinel: Null toSkill is unbound")
_Assert(ycCodec::Missing->toSkill() == 'unbound  "sentinel: Missing toSkill is unbound")

; --- 错误 ---
_AssertError(lambda(() ycCodec::Type("xml"))  "sentinel: unknown Type name errors")
_AssertError(lambda(() ycCodec::Type(42))  "sentinel: integer Type name errors")
_AssertError(lambda(() ycCodec::Type(1.5))  "sentinel: float Type name errors")

; --- 打印 ---
_Assert(printself(ycCodec::True) == "ycCodec::Type(\"True\")"  "sentinel: True printself format")
_Assert(printself(ycCodec::False) == "ycCodec::Type(\"False\")"  "sentinel: False printself format")
_Assert(printself(ycCodec::Missing) == "ycCodec::Type(\"Missing\")"  "sentinel: Missing printself format")
_Assert(car(errset(evalstring(printself(ycCodec::Null)) nil)) == ycCodec::Null  "sentinel: evalstring roundtrip")
_TestSentinelDone = t

; END
