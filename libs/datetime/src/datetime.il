useNamespace("ycDateTime")


; ---------- class definition ----------

; 数据桶：DateTime 状态（Unix 秒 + 纳秒）收敛为单一 _data 槽
defclass(_DateTimeData () (
    ; _DateTimeData 数据桶：收纳 DateTime 的 Unix 秒与纳秒小数，构造后禁写。
    time(
        \@initarg time
        \@initform 0
    )
    nanos(
        \@initarg nanos
        \@initform 0
    )
))

defclass(DateTime () (
    ; DateTime 实例：以「Unix 秒 + 纳秒」为状态的不可变时间对象；同一时刻驻留共享同一实例。
    ; 状态桶（_DateTimeData：time + nanos），构造后禁写
    _data(
        \@initarg _data
        \@initform nil
    )
    epoch()
    nanos()
    millis()
    format()
    year()
    month()
    day()
    hour()
    minute()
    second()
    weekday()
    yday()
    add()
    diff()
    compare()
))


defmethod(printself (self(DateTime))  ; -> str
    ; 返回 DateTime 的打印描述串，形如 ycDateTime::DateTime(1793715057) 或带纳秒的两参形式。
    ;
    ; **返回**
    ;   (str) - 命名空间限定的构造调用形式，顶层 evalstring 可复得同一驻留实例
    if(self->_data->nanos == 0
        lsprintf("%A(%d)" className(self) self->_data->time)
        lsprintf("%A(%d %d)" className(self) self->_data->time self->_data->nanos)
    )
)


; ---------- residency and constructors ----------

; 驻留表：时刻键 → DateTime（同一时刻共享同一实例，== 为真）。
; 有界：超过 _DateTimeCacheCap 条整体清空重计（丢共享只弱化 == 快路径，不改结果）。
_DateTimeCache = makeTable("ycDateTimeCache" nil)
_DateTimeCacheCap = 8192
_DateTimeCacheN = 0


procedure(_DateTimeParts(g_x "g")  ; -> list[int] | nil
    ; 取 DateTime 或整数秒对应的 (秒, 纳秒)。
    ;
    ; **参数**
    ;   g_x  (any) - DateTime 实例或整数秒
    ;
    ; **返回**
    ;   (list[int]|nil) - (秒, 纳秒)；其他类型返回 nil
    cond(
        (fixp(g_x) list(g_x 0))
        (t
            let((l_sec l_ns)
                l_sec = errset(g_x->epoch() nil)
                unless(l_sec && car(l_sec) && fixp(car(l_sec))
                    return(nil)
                )
                l_ns = errset(g_x->nanos() nil)
                list(
                    car(l_sec)
                    if(l_ns && car(l_ns) && fixp(car(l_ns)) car(l_ns) 0)
                )
            )
        )
    )
)


procedure(_MkDateTime(n_time n_nanos "xx")  ; -> DateTime
    ; 按 Unix 秒与纳秒取回（或新建）驻留实例。
    ;
    ; **参数**
    ;   n_time   (int) - Unix 秒（1970-01-01 00:00:00 UTC 起算，可为负）
    ;   n_nanos  (int) - 秒内的小数部分（0～999999999）
    ;
    ; **返回**
    ;   (DateTime) - 同一时刻共享同一实例；超过 _DateTimeCacheCap 条整表清空重计
    let((t_key hit)
        t_key = lsprintf("%d:%09d" n_time n_nanos)
        hit = _DateTimeCache[t_key]
        unless(hit
            hit = makeInstance('DateTime ?_data
                makeInstance('_DateTimeData ?time n_time ?nanos n_nanos))
            _DateTimeCache[t_key] = hit
            _DateTimeCacheN++
            when(_DateTimeCacheCap < _DateTimeCacheN
                _DateTimeCache = makeTable("ycDateTimeCache" nil)
                _DateTimeCacheN = 0
            )
        )
        hit
    )
)


procedure(DateTime(n_time \@optional n_nanos(0) "nx")  ; -> DateTime
    ; 按 Unix 秒（整数或浮点）与纳秒构造时间对象。
    ;
    ; **参数**
    ;   n_time   (num) - Unix 秒；整数按秒解释，浮点按「秒 + 小数」拆分（单精度）
    ;   n_nanos  (int) - 秒内的小数部分（0～999999999，默认 0；仅整数时间可用）
    ;
    ; **返回**
    ;   (DateTime) - 该时刻的驻留实例；纳秒越界或与浮点时间同用时 error() 中断
    let((n_sec n_ns n_frac)
        if(fixp(n_time)
        then
            n_sec = n_time
            n_ns = n_nanos
        else
            when(n_nanos != 0
                error("ycDateTime::DateTime: nanos cannot be combined with a fractional time")
            )
            n_sec = fix2(n_time)
            n_frac = n_time - n_sec
            when(n_frac < 0
                ; fix2 的浮点修正可能把秒向上取整，小数部分随之略小于 0
                n_frac = 0
            )
            n_ns = round2(n_frac * fix(1e9))
        )
        when(n_ns < 0 || fix(1e9) <= n_ns
            when(n_ns == fix(1e9)
                n_ns = 0
                n_sec++
            )
            when(n_ns < 0 || fix(1e9) <= n_ns
                error("ycDateTime::DateTime: nanos must be 0..999999999, got %A" n_ns)
            )
        )
        _MkDateTime(n_sec n_ns)
    )
)


procedure(Current()  ; -> DateTime
    ; 返回当前时刻的 DateTime（秒级，纳秒为 0）。
    ;
    ; **返回**
    ;   (DateTime) - 由 getCurrentTime() 换算的当前时刻；读取失败时 error() 中断
    let((n_now)
        n_now = stringToTime(getCurrentTime())
        unless(fixp(n_now) && 0 <= n_now
            error("ycDateTime::Current: cannot read the current time")
        )
        _MkDateTime(n_now 0)
    )
)


; ---------- method installation ----------

inScheme(
procedure(_InstallDateTime(self "g")  ; -> t
    ; 把 DateTime 方法安装到 DateTime 类（由 initializeInstance 调用）。
    ;
    ; **返回**
    ;   (t) - 安装完成；调用方忽略

procedure(_err(t_method t_formatString \@rest l_args "ttg")  ; -> never
    ; 按统一格式 error() 中断：消息形如 <类名>-><方法名>: <说明>。
    ;
    ; **参数**
    ;   t_method        (str) - 出错的方法名
    ;   t_formatString  (str) - 错误说明格式串（lsprintf 格式）
    ;   l_args          (list) - 变参：格式串实参
    ;
    ; **返回**
    ;   (never) - 总是调用 error()，不返回
    error("%A->%s: %s" className(self) t_method apply('lsprintf t_formatString l_args))
)

procedure(_tm(self "g")  ; -> tm
    ; 返回本地时间结构（timeToTm）。
    ;
    ; **返回**
    ;   (tm) - 本地时间结构；转换失败时 _err() 中断
    let((tm)
        tm = timeToTm(self->_data->time)
        unless(tm
            _err("epoch" "cannot convert time %A" self->_data->time)
        )
        tm
    )
)

self->epoch = lambda(()  ; -> int
    ; 返回 Unix 秒（纳秒部分不参与）。
    ;
    ; **返回**
    ;   (int) - 1970-01-01 00:00:00 UTC 起算的秒数（可为负）
    self->_data->time
)

self->nanos = lambda(()  ; -> int
    ; 返回秒内的小数部分。
    ;
    ; **返回**
    ;   (int) - 纳秒（0～999999999）
    self->_data->nanos
)

self->millis = lambda(()  ; -> int
    ; 返回秒内小数部分的毫秒值（截断）。
    ;
    ; **返回**
    ;   (int) - 毫秒（0～999）
    self->_data->nanos / fix(1e6)
)

self->format = lambda((\@optional t_pattern("%F %T") "t")  ; -> str
    ; 按模板把本地时间格式化为串。
    ;
    ; **参数**
    ;   t_pattern  (str) - 模板；默认 "%F %T"（等值于 "%Y-%m-%d %H:%M:%S"，令牌见 README）
    ;
    ; **返回**
    ;   (str) - 格式化结果；未知令牌或末尾悬空 % 时 error() 中断
    _FormatTime(self->_data->time self->_data->nanos t_pattern "ycDateTime::DateTime->format")
)

self->year = lambda(()  ; -> int
    ; 返回本地时间的年份。
    ;
    ; **返回**
    ;   (int) - 实际年份（如 2026）
    let((tm)
        tm = _tm(self)
        tm->tm_year + 1900
    )
)

self->month = lambda(()  ; -> int
    ; 返回本地时间的月份。
    ;
    ; **返回**
    ;   (int) - 1～12
    let((tm)
        tm = _tm(self)
        tm->tm_mon + 1
    )
)

self->day = lambda(()  ; -> int
    ; 返回本地时间的日。
    ;
    ; **返回**
    ;   (int) - 1～31
    let((tm)
        tm = _tm(self)
        tm->tm_mday
    )
)

self->hour = lambda(()  ; -> int
    ; 返回本地时间的小时。
    ;
    ; **返回**
    ;   (int) - 0～23
    let((tm)
        tm = _tm(self)
        tm->tm_hour
    )
)

self->minute = lambda(()  ; -> int
    ; 返回本地时间的分钟。
    ;
    ; **返回**
    ;   (int) - 0～59
    let((tm)
        tm = _tm(self)
        tm->tm_min
    )
)

self->second = lambda(()  ; -> int
    ; 返回本地时间的秒。
    ;
    ; **返回**
    ;   (int) - 0～59
    let((tm)
        tm = _tm(self)
        tm->tm_sec
    )
)

self->weekday = lambda(()  ; -> int
    ; 返回本地时间的星期。
    ;
    ; **返回**
    ;   (int) - 0～6，0 为周日
    let((tm)
        tm = _tm(self)
        tm->tm_wday
    )
)

self->yday = lambda(()  ; -> int
    ; 返回本地时间在当年中的序日。
    ;
    ; **返回**
    ;   (int) - 1～366
    let((tm)
        tm = _tm(self)
        tm->tm_yday + 1
    )
)

self->add = lambda((\@key (seconds 0) (minutes 0) (hours 0) (days 0) (millis 0) (nanos 0) "xxxxxx")  ; -> DateTime
    ; 按固定时长偏移，返回新时刻（原对象不变）。
    ;
    ; **参数**
    ;   ?seconds  (int) - 秒增量（默认 0，可为负）
    ;   ?minutes  (int) - 分钟增量（默认 0，可为负）
    ;   ?hours    (int) - 小时增量（默认 0，可为负）
    ;   ?days     (int) - 天数增量（默认 0，可为负；一天按 86400 秒计）
    ;   ?millis   (int) - 毫秒增量（默认 0，可为负）
    ;   ?nanos    (int) - 纳秒增量（默认 0，可为负）
    ;
    ; **返回**
    ;   (DateTime) - 新时刻；增量全为 0 时返回自身（同一驻留实例）
    let((n_dsec n_dns n_sec n_ns)
        n_dsec = seconds + minutes * 60 + hours * 3600 + days * 86400
        n_dns = millis * fix(1e6) + nanos
        n_sec = self->_data->time + n_dsec
        n_ns = self->_data->nanos + n_dns
        n_sec = n_sec + n_ns / fix(1e9)
        n_ns = remainder(n_ns fix(1e9))
        when(n_ns < 0
            n_ns = n_ns + fix(1e9)
            n_sec--
        )
        _MkDateTime(n_sec n_ns)
    )
)

self->diff = lambda((g_other "g")  ; -> float
    ; 返回与另一时刻的秒差（含亚秒部分）。
    ;
    ; **参数**
    ;   g_other  (DateTime|int) - 另一个时刻，或整数 Unix 秒
    ;
    ; **返回**
    ;   (float) - self 减 g_other 的秒数（self 更晚为正，单精度）；参数不可识别时 _err() 中断
    let((l_o n_sec n_ns)
        l_o = _DateTimeParts(g_other)
        unless(l_o
            _err("diff" "expected a DateTime or an integer time, got %A" g_other)
        )
        n_sec = self->_data->time - car(l_o)
        n_ns = self->_data->nanos - cadr(l_o)
        n_sec = n_sec + n_ns / fix(1e9)
        n_ns = remainder(n_ns fix(1e9))
        when(n_ns < 0
            n_ns = n_ns + fix(1e9)
            n_sec--
        )
        n_sec + n_ns / 1e9
    )
)

self->compare = lambda((g_other "g")  ; -> int
    ; 比较两个时刻的先后。
    ;
    ; **参数**
    ;   g_other  (DateTime|int) - 另一个时刻，或整数 Unix 秒
    ;
    ; **返回**
    ;   (int) - self 早于为 -1、相同为 0、晚于为 1；参数不可识别时 _err() 中断
    let((l_o n_o_sec n_o_ns)
        l_o = _DateTimeParts(g_other)
        unless(l_o
            _err("compare" "expected a DateTime or an integer time, got %A" g_other)
        )
        n_o_sec = car(l_o)
        n_o_ns = cadr(l_o)
        cond(
            (self->_data->time < n_o_sec -1)
            (n_o_sec < self->_data->time 1)
            (self->_data->nanos < n_o_ns -1)
            (n_o_ns < self->_data->nanos 1)
            (t 0)
        )
    )
)

t
))


inScheme(
defmethod(initializeInstance (self(DateTime) \@rest _args)
    ; 构造 DateTime 实例时调用 _InstallDateTime 安装全部方法集。
    ;
    ; **参数**
    ;   _args  (list) - 变参：附加初始化参数，本实现忽略
    ;
    ; **返回**
    ;   (t) - 安装完成后返回 t
    _InstallDateTime(self)
    t
)
)

unuseNamespace("ycDateTime")

; END
