;--------------------------
; Program  : ycString(src/sort.il)
; Language : Cadence Skill
;--------------------------

useNamespace("ycString")

procedure(_DigitRunEnd(t_s n_from "tx")  ; -> int
    ; 返回自 n_from 起连续数字段之后的下标（内部实现）。
    ;
    ; **参数**
    ;   t_s     (str) - 输入串
    ;   n_from  (int) - 起始下标（1 基）
    ;
    ; **返回**
    ;   (int) - 数字段末尾的下一个下标；该处不是数字时原样返回 n_from
    let((len i)
        len = length(t_s)
        i = n_from
        while(i <= len && _IsDigitChar(substring(t_s i 1))
            i++
        )
        i
    )
)

procedure(_StripZeros(t_s "t")  ; -> str
    ; 去掉数字串的前导零，至少保留一位（内部实现）。
    ;
    ; **参数**
    ;   t_s (str) - 纯数字串
    ;
    ; **返回**
    ;   (str) - 去零后的数字串
    let((len i)
        len = length(t_s)
        i = 1
        while(i < len && substring(t_s i 1) == "0"
            i++
        )
        substring(t_s i)
    )
)

procedure(NaturalLess(t_a t_b "tt")  ; -> t | nil
    ; 自然序比较：数字段按数值比，其余按大小写不敏感比，完全相同时按原串定序。
    ;
    ; 数字段按「有效位数 → 数字串 → 前导零个数」比较，任意长度都不丢精度；
    ; 大小写不敏感的两次比较都相等时，回落到原串比较，保证定序可复现。
    ;
    ; **参数**
    ;   t_a (str) - 左串
    ;   t_b (str) - 右串
    ;
    ; **返回**
    ;   (t|nil) - t 表示 a 排在 b 之前；相等或 a 在后回 nil
    let((la lb i j sign ea eb ca cb ra rb sa sb)
        la = length(t_a)
        lb = length(t_b)
        i = 1
        j = 1
        sign = 0
        while(sign == 0 && i <= la && j <= lb
            ca = substring(t_a i 1)
            cb = substring(t_b j 1)
            if(ca == cb
            then
                i++
                j++
            else
                if(_IsDigitChar(ca) && _IsDigitChar(cb)
                then
                    ea = _DigitRunEnd(t_a i)
                    eb = _DigitRunEnd(t_b j)
                    ra = substring(t_a i (ea - i))
                    rb = substring(t_b j (eb - j))
                    sa = _StripZeros(ra)
                    sb = _StripZeros(rb)
                    cond(
                        (length(sa) != length(sb)
                            sign = if(length(sa) < length(sb) -1 1)
                        )
                        (sa != sb
                            sign = strcmp(sa sb)
                        )
                        (length(ra) != length(rb)
                            sign = if(length(ra) < length(rb) -1 1)
                        )
                    )
                    i = ea
                    j = eb
                else
                    sign = strcmp(lowerCase(ca) lowerCase(cb))
                    i++
                    j++
                )
            )
        )
        cond(
            (sign != 0 sign < 0)
            (i > la && j > lb strcmp(t_a t_b) < 0)
            (i > la t)
            (t nil)
        )
    )
)

procedure(NaturalSort(l_items \@key (reverse nil) "lg")  ; -> list
    ; 返回按自然序排序的副本，输入列表保持不变。
    ;
    ; **参数**
    ;   l_items  (list[str]) - 待排序的字符串列表
    ;   ?reverse (t|nil)     - 非 nil 时降序；默认 nil
    ;
    ; **返回**
    ;   (list[str]) - 新列表；空输入回 nil
    let((out idx)
        idx = 0
        foreach(item l_items
            idx++
            unless(stringp(item)
                error("ycString::NaturalSort: item #%d must be a string, got %A" idx item)
            )
        )
        out = sort(copy(l_items) 'ycString::NaturalLess)
        if(reverse
            reverse(out)
            out
        )
    )
)

unuseNamespace("ycString")

; END
