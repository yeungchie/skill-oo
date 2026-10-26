;--------------------------
; Program  : ycRadix(src/radix.il)
; Language : Cadence Skill
;--------------------------

useNamespace("ycRadix")

; ---------- 内部辅助 ----------

procedure(_DigitValue(n_ch "x")  ; -> int | nil
    ; 返回 ASCII 字节对应的 0–35 数字值（内部实现）。
    ;
    ; **参数**
    ;   n_ch  (int) - 字节值
    ;
    ; **返回**
    ;   (int|nil) - 十进制数字、大小写字母对应的值；其他字符为 nil
    cond(
        ((n_ch >= 48 && n_ch <= 57) n_ch - 48)
        ((n_ch >= 65 && n_ch <= 90) n_ch - 55)
        ((n_ch >= 97 && n_ch <= 122) n_ch - 87)
        (t nil)
    )
)

procedure(_PrefixBase(t_text n_pos "tx")  ; -> list | nil
    ; 识别 0b/0o/0x 前缀（内部实现）。
    ;
    ; **参数**
    ;   t_text  (str) - 输入串
    ;   n_pos   (int) - 1-based 前缀起点
    ;
    ; **返回**
    ;   (list|nil) - (进制 前缀长度)；不是前缀时为 nil
    when(n_pos + 1 <= length(t_text)
        let((t_two)
            t_two = lowerCase(substring(t_text n_pos 2))
            cond(
                (t_two == "0b" list(2 2))
                (t_two == "0o" list(8 2))
                (t_two == "0x" list(16 2))
                (t nil)
            )
        )
    )
)

procedure(_Mask(n_bits t_ctx "xt")  ; -> int
    ; 生成指定位宽的低位掩码（内部实现）。
    ;
    ; **参数**
    ;   n_bits  (int) - 位宽 0–32
    ;   t_ctx   (str) - 错误消息上下文
    ;
    ; **返回**
    ;   (int) - 低位掩码；32 位为 -1
    unless(fixp(n_bits) && 0 <= n_bits && n_bits <= 32
        error("%s: bits must be an integer in 0..32, got %A" t_ctx n_bits)
    )
    case(n_bits
        (0 0)
        (32 -1)
        (t (1 << n_bits) - 1)
    )
)

; ---------- 解析 ----------

procedure(Parse(t_text \@key (base nil) (prefix t) (wrap nil) "tggg")  ; -> int
    ; 按指定或前缀推断的进制解析整数。
    ;
    ; **参数**
    ;   t_text    (str)    - 输入文本：可选正负号 + 数字；前缀 0b/0o/0x 大小写皆可
    ;   ?base     (int)    - 2–36；nil 时按前缀或前导 0 推断，否则十进制；默认 nil
    ;   ?prefix   (t|nil)  - 是否识别 0b/0o/0x 与前导 0 八进制；默认 t
    ;   ?wrap     (t|nil)  - t 时允许 32 位无符号位型（最高位为 1 返回负数）；默认 nil
    ;
    ; **返回**
    ;   (int) - 解析结果；超出 32 位、非法数字或缺数字时 error
    let((n_len n_i n_ch g_neg n_base l_pf f_acc n_digit)
        unless(prefix == t || prefix == nil
            error("ycRadix::Parse: ?prefix must be t or nil, got %A" prefix)
        )
        unless(wrap == t || wrap == nil
            error("ycRadix::Parse: ?wrap must be t or nil, got %A" wrap)
        )
        unless(base == nil
            unless(fixp(base) && 2 <= base && base <= 36
                error("ycRadix::Parse: base must be an integer in 2..36, got %A" base)
            )
        )
        n_len = length(t_text)
        unless(n_len > 0
            error("ycRadix::Parse: expected a non-empty string")
        )
        n_i = 1
        n_ch = charToInt(getchar(t_text 1))
        when(n_ch == 43 || n_ch == 45
            g_neg = (n_ch == 45)
            n_i = 2
        )
        when(prefix
            l_pf = _PrefixBase(t_text n_i)
            when(l_pf
                when(base && base != car(l_pf)
                    error("ycRadix::Parse: prefix implies base %d, conflicts with base %d"
                        car(l_pf) base
                    )
                )
                n_base = car(l_pf)
                n_i = n_i + cadr(l_pf)
            )
            unless(l_pf
                when(base == nil && n_i <= n_len && charToInt(getchar(t_text n_i)) == 48
                    n_base = 8
                )
            )
        )
        unless(n_base
            n_base = if(base base 10)
        )
        when(n_i > n_len
            error("ycRadix::Parse: missing digits in %A" t_text)
        )
        f_acc = 0.0
        while(n_i <= n_len
            n_digit = _DigitValue(charToInt(getchar(t_text n_i)))
            when(n_digit == nil || n_digit >= n_base
                error("ycRadix::Parse: invalid digit %A for base %d in %A"
                    getchar(t_text n_i) n_base t_text
                )
            )
            f_acc = f_acc * n_base + n_digit
            when(f_acc > 4294967295.0
                error("ycRadix::Parse: value out of 32-bit range in %A" t_text)
            )
            n_i = n_i + 1
        )
        cond(
            (g_neg
                let((n_val)
                    when(f_acc > 2147483648.0
                        error("ycRadix::Parse: value out of 32-bit range in %A" t_text)
                    )
                    n_val = int(0.0 - f_acc)
                    n_val
                )
            )
            (f_acc <= 2147483647.0
                int(f_acc)
            )
            (wrap
                int(f_acc - 4294967296.0)
            )
            (t
                error("ycRadix::Parse: value out of signed 32-bit range; use ?wrap t for bit patterns")
            )
        )
    )
)

; ---------- 格式化 ----------

procedure(Format(n_value \@key (base 10) (prefix nil) (upper nil) (width nil) (pad "0") "xggggt")  ; -> str
    ; 将整数格式化为指定进制的文本。
    ;
    ; **参数**
    ;   n_value   (int)       - 待格式化整数
    ;   ?base     (int)       - 2–36，默认 10
    ;   ?prefix   (t|nil|str) - t 时 2/8/16 用 0b/0o/0x；字符串为自定义前缀；默认 nil
    ;   ?upper    (t|nil)     - t 时数字与规范前缀用大写；默认 nil
    ;   ?width    (int)       - 数字部分最小宽度；默认 nil（不补）
    ;   ?pad      (str)       - 单字符填充，默认 "0"
    ;
    ; **返回**
    ;   (str) - 格式化文本；负数为符号加绝对值，宽度不含符号与前缀
    let((t_digits g_neg n_mag n_quot n_rem t_out t_pre n_need)
        unless(fixp(base) && 2 <= base && base <= 36
            error("ycRadix::Format: base must be an integer in 2..36, got %A" base)
        )
        unless(prefix == nil || prefix == t || stringp(prefix)
            error("ycRadix::Format: ?prefix must be nil, t, or a string, got %A" prefix)
        )
        unless(upper == t || upper == nil
            error("ycRadix::Format: ?upper must be t or nil, got %A" upper)
        )
        unless(stringp(pad) && length(pad) == 1
            error("ycRadix::Format: ?pad must be a single-character string, got %A" pad)
        )
        when(width
            unless(fixp(width) && width >= 0
                error("ycRadix::Format: ?width must be a non-negative integer, got %A" width)
            )
        )
        t_digits = if(upper
            "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
            "0123456789abcdefghijklmnopqrstuvwxyz"
        )
        g_neg = n_value < 0
        n_mag = if(n_value == (-1 - 2147483647)
            2147483648.0
            abs(n_value)
        )
        t_out = ""
        while(n_mag > 0
            n_quot = int((1.0 * n_mag) / base)
            n_rem = int(n_mag - (1.0 * n_quot) * base)
            t_out = strcat(substring(t_digits n_rem + 1 1) t_out)
            n_mag = n_quot
        )
        when(t_out == ""
            t_out = "0"
        )
        t_pre = cond(
            (prefix == nil "")
            (prefix == t
                let((t_p)
                    cond(
                        (base == 2 t_p = "0b")
                        (base == 8 t_p = "0o")
                        (base == 16 t_p = "0x")
                        (t error("ycRadix::Format: ?prefix t is only supported for base 2, 8, or 16"))
                    )
                    when(upper
                        t_p = upperCase(t_p)
                    )
                    t_p
                )
            )
            (t prefix)
        )
        when(width
            n_need = width - length(t_out)
            while(n_need > 0
                t_out = strcat(pad t_out)
                n_need = n_need - 1
            )
        )
        lsprintf("%s%s%s" if(g_neg "-" "") t_pre t_out)
    )
)

; ---------- 掩码 ----------

procedure(Mask(n_bits "x")  ; -> int
    ; 返回指定位宽的低位掩码。
    ;
    ; **参数**
    ;   n_bits  (int) - 位宽 0–32
    ;
    ; **返回**
    ;   (int) - 低位掩码；32 位为 -1
    _Mask(n_bits "ycRadix::Mask")
)

procedure(ApplyMask(n_value n_bits "xx")  ; -> int
    ; 将整数按指定位宽做低位掩码。
    ;
    ; **参数**
    ;   n_value  (int) - 输入整数
    ;   n_bits   (int) - 位宽 0–32
    ;
    ; **返回**
    ;   (int) - n_value 的低 n_bits 位
    let((n_mask)
        n_mask = _Mask(n_bits "ycRadix::ApplyMask")
        n_value & n_mask
    )
)

unuseNamespace("ycRadix")

; END
