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
    let((n_len n_i)
        n_len = length(t_s)
        n_i = n_from
        while(n_i <= n_len && _IsDigitChar(substring(t_s n_i 1))
            n_i++
        )
        n_i
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
    let((n_len n_i)
        n_len = length(t_s)
        n_i = 1
        while(n_i < n_len && substring(t_s n_i 1) == "0"
            n_i++
        )
        substring(t_s n_i)
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
    let((n_la n_lb n_i n_j n_sign n_ea n_eb t_ca t_cb t_ra t_rb t_sa t_sb)
        n_la = length(t_a)
        n_lb = length(t_b)
        n_i = 1
        n_j = 1
        n_sign = 0
        while(n_sign == 0 && n_i <= n_la && n_j <= n_lb
            t_ca = substring(t_a n_i 1)
            t_cb = substring(t_b n_j 1)
            if(t_ca == t_cb
            then
                n_i++
                n_j++
            else
                if(_IsDigitChar(t_ca) && _IsDigitChar(t_cb)
                then
                    n_ea = _DigitRunEnd(t_a n_i)
                    n_eb = _DigitRunEnd(t_b n_j)
                    t_ra = substring(t_a n_i (n_ea - n_i))
                    t_rb = substring(t_b n_j (n_eb - n_j))
                    t_sa = _StripZeros(t_ra)
                    t_sb = _StripZeros(t_rb)
                    cond(
                        (length(t_sa) != length(t_sb)
                            n_sign = if(length(t_sa) < length(t_sb) -1 1)
                        )
                        (t_sa != t_sb
                            n_sign = strcmp(t_sa t_sb)
                        )
                        (length(t_ra) != length(t_rb)
                            n_sign = if(length(t_ra) < length(t_rb) -1 1)
                        )
                    )
                    n_i = n_ea
                    n_j = n_eb
                else
                    n_sign = strcmp(lowerCase(t_ca) lowerCase(t_cb))
                    n_i++
                    n_j++
                )
            )
        )
        cond(
            (n_sign != 0 n_sign < 0)
            (n_i > n_la && n_j > n_lb strcmp(t_a t_b) < 0)
            (n_i > n_la t)
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
    let((l_out n_idx)
        n_idx = 0
        foreach(t_item l_items
            n_idx++
            unless(stringp(t_item)
                error("ycString::NaturalSort: item #%d must be a string, got %A" n_idx t_item)
            )
        )
        l_out = sort(copy(l_items) 'ycString::NaturalLess)
        if(reverse
            reverse(l_out)
            l_out
        )
    )
)

unuseNamespace("ycString")

; END
