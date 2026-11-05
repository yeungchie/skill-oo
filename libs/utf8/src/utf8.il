useNamespace("ycUtf8")

; ---------- 共享扫描器 ----------

procedure(_Next(t_s n_i "tx")  ; -> list
    ; 从 1-based 字节位置读取一个 UTF-8 码点。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;   n_i  (int) - 1-based 字节位置
    ;
    ; **返回**
    ;   (list) - 合法为 (码点 下一位置)，非法为 (nil 起始位置)
    let((len c need left cp k b bad)
        len = length(t_s)
        c = charToInt(getchar(t_s n_i))
        cond(
            (c <= 127
                need = 0
                cp = c
            )
            (c >= 194 && c <= 223
                need = 1
                cp = c - 192
            )
            (c >= 224 && c <= 239
                need = 2
                cp = c - 224
            )
            (c >= 240 && c <= 244
                need = 3
                cp = c - 240
            )
            (t
                need = -1
            )
        )
        when(need >= 1
            left = need
            k = n_i
            while(left > 0 && !bad
                k++
                when(k > len
                    bad = t
                )
                unless(bad
                    b = charToInt(getchar(t_s k))
                    unless(b >= 128 && b <= 191
                        bad = t
                    )
                    unless(bad
                        cp = cp * 64 + b - 128
                    )
                )
                left--
            )
            unless(bad
                cond(
                    (need == 1 && cp < 128 bad = t)
                    (need == 2 && cp < 2048 bad = t)
                    (need == 3 && cp < 65536 bad = t)
                )
                when(cp > 1114111 || (cp >= 55296 && cp <= 57343)
                    bad = t
                )
            )
        )
        if(bad || need < 0
            list(nil n_i)
            list(cp n_i + need + 1)
        )
    )
)

procedure(_Read(t_s n_i g_strict t_ctx "txgt")  ; -> list
    ; 读取一个码点；严格模式非法即报错，宽松模式以 U+FFFD 替换并前进一字节。
    ;
    ; **参数**
    ;   t_s      (str) - 输入串
    ;   n_i      (int) - 1-based 字节位置
    ;   g_strict (any) - 非 nil 为严格模式
    ;   t_ctx    (str) - 错误消息上下文（如 "ycUtf8::Decode"）
    ;
    ; **返回**
    ;   (list) - (码点 下一位置)
    let((res)
        res = _Next(t_s n_i)
        cond(
            (car(res) res)
            (g_strict
                error("%s: invalid UTF-8 at byte %d" t_ctx n_i)
            )
            (t list(65533 n_i + 1))
        )
    )
)

procedure(_EncCp(n_cp "x")  ; -> str
    ; 将码点编码为 UTF-8 字节串（1..4 字节）。
    ;
    ; **参数**
    ;   n_cp  (int) - 0..0x10FFFF 的码点
    ;
    ; **返回**
    ;   (str) - UTF-8 字节串
    cond(
        (n_cp < 128
            strcat(intToChar(n_cp))
        )
        (n_cp < 2048
            strcat(intToChar(192 + n_cp/64) intToChar(128 + remainder(n_cp 64)))
        )
        (n_cp < 65536
            lsprintf("%s%s%s"
                intToChar(224 + n_cp/4096)
                intToChar(128 + remainder(n_cp/64 64))
                intToChar(128 + remainder(n_cp 64))
            )
        )
        (t
            lsprintf("%s%s%s%s"
                intToChar(240 + n_cp/262144)
                intToChar(128 + remainder(n_cp/4096 64))
                intToChar(128 + remainder(n_cp/64 64))
                intToChar(128 + remainder(n_cp 64))
            )
        )
    )
)

procedure(_Build(l_p "l")  ; -> str
    ; 将 tconc 容器拼接为字符串。
    ;
    ; **参数**
    ;   l_p  (list) - tconc 头容器或 nil
    ;
    ; **返回**
    ;   (str) - 各片段顺序拼接；空容器回 ""
    buildString(car(l_p) "")
)

; ---------- 公开接口 ----------

procedure(Decode(t_str \@key (strict t) "tg")  ; -> list | nil
    ; 将 UTF-8 字节串解码为码点列表。
    ;
    ; **参数**
    ;   t_str   (str) - UTF-8 字节串
    ;   ?strict (any) - 非 nil 时非法序列报错；nil 时逐字节替换为 U+FFFD；默认 t
    ;
    ; **返回**
    ;   (list|nil) - 码点列表；空串为 nil
    unless(stringp(t_str)
        error("ycUtf8::Decode: expects a string")
    )
    let((res p i)
        i = 1
        while(i <= length(t_str)
            res = _Read(t_str i strict "ycUtf8::Decode")
            p = tconc(p car(res))
            i = cadr(res)
        )
        car(p)
    )
)

procedure(Encode(l_cps "l")  ; -> str
    ; 将码点列表编码为 UTF-8 字节串。
    ;
    ; **参数**
    ;   l_cps  (list) - 码点列表
    ;
    ; **返回**
    ;   (str) - UTF-8 字节串；nil 回 ""
    unless(listp(l_cps)
        error("ycUtf8::Encode: expects a list")
    )
    let((p idx cp)
        idx = 0
        foreach(cp2 l_cps
            idx++
            unless(fixp(cp2) && cp2 >= 0 && cp2 <= 1114111
                error("ycUtf8::Encode: invalid codepoint at index %d (%A)" idx cp2)
            )
            when(cp2 >= 55296 && cp2 <= 57343
                error("ycUtf8::Encode: invalid codepoint at index %d (%A)" idx cp2)
            )
            when(cp2 == 0
                error("ycUtf8::Encode: codepoint at index %d (%A) cannot be represented in a SKILL string" idx cp2)
            )
            p = tconc(p _EncCp(cp2))
        )
        _Build(p)
    )
)

procedure(CharCount(t_str \@key (strict t) "tg")  ; -> int
    ; 统计 UTF-8 字节串的码点个数。
    ;
    ; **参数**
    ;   t_str   (str) - UTF-8 字节串
    ;   ?strict (any) - 非 nil 时非法序列报错；nil 时逐字节替换为 U+FFFD；默认 t
    ;
    ; **返回**
    ;   (int) - 码点个数；空串为 0
    unless(stringp(t_str)
        error("ycUtf8::CharCount: expects a string")
    )
    let((res i n)
        i = 1
        n = 0
        while(i <= length(t_str)
            res = _Read(t_str i strict "ycUtf8::CharCount")
            i = cadr(res)
            n++
        )
        n
    )
)

procedure(Slice(t_str n_start n_len \@key (strict t) "txxg")  ; -> str | nil
    ; 按码点切片（1-based 起点）。
    ;
    ; **参数**
    ;   t_str    (str) - UTF-8 字节串
    ;   n_start  (int) - 1-based 码点起点（>= 1）
    ;   n_len    (int) - 码点长度（>= 0）
    ;   ?strict  (any) - 非 nil 时非法序列报错；nil 时以 U+FFFD 替换；默认 t
    ;
    ; **返回**
    ;   (str|nil) - 切片结果；起点超过码点总数时为 nil
    unless(stringp(t_str)
        error("ycUtf8::Slice: expects a string")
    )
    unless(fixp(n_start) && n_start >= 1
        error("ycUtf8::Slice: start must be an integer >= 1")
    )
    unless(fixp(n_len) && n_len >= 0
        error("ycUtf8::Slice: length must be an integer >= 0")
    )
    let((res p i total seen take)
        total = length(t_str)
        i = 1
        seen = 0
        while(i <= total && seen < n_start - 1
            res = _Read(t_str i strict "ycUtf8::Slice")
            i = cadr(res)
            seen++
        )
        unless(i > total
            take = 0
            while(i <= total && take < n_len
                res = _Read(t_str i strict "ycUtf8::Slice")
                p = tconc(p _EncCp(car(res)))
                i = cadr(res)
                take++
            )
            _Build(p)
        )
    )
)

procedure(IsValid(t_str "t")  ; -> t | nil
    ; 判断字节串是否为合法 UTF-8。
    ;
    ; **参数**
    ;   t_str  (str) - 待检查字节串
    ;
    ; **返回**
    ;   (t|nil) - 合法回 t；非法回 nil
    unless(stringp(t_str)
        error("ycUtf8::IsValid: expects a string")
    )
    let((res i ok)
        i = 1
        ok = t
        while(ok && i <= length(t_str)
            res = _Next(t_str i)
            if(car(res)
                i = cadr(res)
                ok = nil
            )
        )
        ok
    )
)

unuseNamespace("ycUtf8")

; END
