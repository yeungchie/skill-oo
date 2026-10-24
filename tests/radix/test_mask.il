_TestMaskDone = nil

; ---- Mask ----
_Assert(ycRadix::Mask(0) == 0  "mask: 0 bits")
_Assert(ycRadix::Mask(1) == 1  "mask: 1 bit")
_Assert(ycRadix::Mask(8) == 255  "mask: 8 bits")
_Assert(ycRadix::Mask(16) == 65535  "mask: 16 bits")
_Assert(ycRadix::Mask(30) == 1073741823  "mask: 30 bits")
_Assert(ycRadix::Mask(31) == 2147483647  "mask: 31 bits")
_Assert(ycRadix::Mask(32) == -1  "mask: 32 bits")

; ---- ApplyMask ----
_Assert(ycRadix::ApplyMask(4660 8) == 52  "apply: low byte")
_Assert(ycRadix::ApplyMask(-1 8) == 255  "apply: all ones byte")
_Assert(ycRadix::ApplyMask(256 8) == 0  "apply: clear bit 8")
_Assert(ycRadix::ApplyMask((-1 - 2147483647) 31) == 0  "apply: sign bit outside 31")
_Assert(ycRadix::ApplyMask(-1 31) == 2147483647  "apply: all ones 31")
_Assert(ycRadix::ApplyMask(-1 32) == -1  "apply: all ones 32")
_Assert(ycRadix::ApplyMask(0 0) == 0  "apply: zero width")
_Assert(ycRadix::ApplyMask(0 32) == 0  "apply: zero value 32")
_Assert(ycRadix::ApplyMask(2147483647 31) == 2147483647  "apply: max 31")
_Assert(ycRadix::ApplyMask(-1 0) == 0  "apply: negative zero width")
_Assert(ycRadix::ApplyMask(15 4) == 15  "apply: exact nibble")
_Assert(ycRadix::ApplyMask(16 4) == 0  "apply: nibble overflow")

; ---- errors ----
_AssertError(lambda(() ycRadix::Mask(-1))  "mask error: negative bits")
_AssertError(lambda(() ycRadix::Mask(33))  "mask error: 33 bits")
_AssertError(lambda(() ycRadix::Mask(8.0))  "mask error: float bits")
_AssertError(lambda(() ycRadix::Mask("8"))  "mask error: string bits")
_AssertError(lambda(() ycRadix::Mask(nil))  "mask error: nil bits")
_AssertError(lambda(() ycRadix::ApplyMask("1" 8))  "apply error: string value")
_AssertError(lambda(() ycRadix::ApplyMask(1 "8"))  "apply error: string bits")
_AssertError(lambda(() ycRadix::ApplyMask(1 33))  "apply error: 33 bits")
_AssertError(lambda(() ycRadix::ApplyMask(1 -1))  "apply error: negative bits")
_AssertError(lambda(() ycRadix::ApplyMask(1.0 8))  "apply error: float value")
_AssertError(lambda(() ycRadix::ApplyMask(1 8.0))  "apply error: float bits")
_AssertError(lambda(() ycRadix::ApplyMask(1))  "apply error: missing bits")

_TestMaskDone = t
