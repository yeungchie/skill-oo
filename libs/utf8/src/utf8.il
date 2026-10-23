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
    let((n_len n_c n_need n_left n_cp n_k n_b g_bad)
        n_len = length(t_s)
        n_c = charToInt(getchar(t_s n_i))
        cond(
            (n_c <= 127
                n_need = 0
                n_cp = n_c
            )
            (n_c >= 194 && n_c <= 223
                n_need = 1
                n_cp = n_c - 192
            )
            (n_c >= 224 && n_c <= 239
                n_need = 2
                n_cp = n_c - 224
            )
            (n_c >= 240 && n_c <= 244
                n_need = 3
                n_cp = n_c - 240
            )
            (t
                n_need = -1
            )
        )
        when(n_need >= 1
            n_left = n_need
            n_k = n_i
            while(n_left > 0 && !g_bad
                n_k = n_k + 1
                when(n_k > n_len
                    g_bad = t
                )
                unless(g_bad
                    n_b = charToInt(getchar(t_s n_k))
                    unless(n_b >= 128 && n_b <= 191
                        g_bad = t
                    )
                    unless(g_bad
                        n_cp = n_cp * 64 + n_b - 128
                    )
                )
                n_left = n_left - 1
            )
            unless(g_bad
                cond(
                    (n_need == 1 && n_cp < 128 g_bad = t)
                    (n_need == 2 && n_cp < 2048 g_bad = t)
                    (n_need == 3 && n_cp < 65536 g_bad = t)
                )
                when(n_cp > 1114111 || (n_cp >= 55296 && n_cp <= 57343)
                    g_bad = t
                )
            )
        )
        if(g_bad || n_need < 0
            list(nil n_i)
            list(n_cp n_i + n_need + 1)
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
    let((l_res)
        l_res = _Next(t_s n_i)
        if(car(l_res)
            l_res
            if(g_strict
                error("%s: invalid UTF-8 at byte %d" t_ctx n_i)
                list(65533 n_i + 1)
            )
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
            strcat(
                intToChar(224 + n_cp/4096)
                intToChar(128 + remainder(n_cp/64 64))
                intToChar(128 + remainder(n_cp 64))
            )
        )
        (t
            strcat(
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
    let((l_res l_p n_i)
        n_i = 1
        while(n_i <= length(t_str)
            l_res = _Read(t_str n_i strict "ycUtf8::Decode")
            l_p = tconc(l_p car(l_res))
            n_i = cadr(l_res)
        )
        car(l_p)
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
    let((l_p n_idx g_cp)
        n_idx = 0
        foreach(g_cp l_cps
            n_idx = n_idx + 1
            unless(fixp(g_cp) && g_cp >= 0 && g_cp <= 1114111
                error("ycUtf8::Encode: invalid codepoint at index %d (%A)" n_idx g_cp)
            )
            when(g_cp >= 55296 && g_cp <= 57343
                error("ycUtf8::Encode: invalid codepoint at index %d (%A)" n_idx g_cp)
            )
            when(g_cp == 0
                error("ycUtf8::Encode: codepoint at index %d (%A) cannot be represented in a SKILL string" n_idx g_cp)
            )
            l_p = tconc(l_p _EncCp(g_cp))
        )
        _Build(l_p)
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
    let((l_res n_i n_n)
        n_i = 1
        n_n = 0
        while(n_i <= length(t_str)
            l_res = _Read(t_str n_i strict "ycUtf8::CharCount")
            n_i = cadr(l_res)
            n_n = n_n + 1
        )
        n_n
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
    let((l_res l_p n_i n_total n_seen n_take)
        n_total = length(t_str)
        n_i = 1
        n_seen = 0
        while(n_i <= n_total && n_seen < n_start - 1
            l_res = _Read(t_str n_i strict "ycUtf8::Slice")
            n_i = cadr(l_res)
            n_seen = n_seen + 1
        )
        unless(n_i > n_total
            n_take = 0
            while(n_i <= n_total && n_take < n_len
                l_res = _Read(t_str n_i strict "ycUtf8::Slice")
                l_p = tconc(l_p _EncCp(car(l_res)))
                n_i = cadr(l_res)
                n_take = n_take + 1
            )
            _Build(l_p)
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
    let((l_res n_i g_ok)
        n_i = 1
        g_ok = t
        while(g_ok && n_i <= length(t_str)
            l_res = _Next(t_str n_i)
            if(car(l_res)
                n_i = cadr(l_res)
                g_ok = nil
            )
        )
        g_ok
    )
)

unuseNamespace("ycUtf8")

; END
