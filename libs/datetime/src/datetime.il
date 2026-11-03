useNamespace("ycDateTime")


; ---------- class definition ----------

; 数据桶：DateTime 状态（Unix 秒）收敛为单一 _data 槽
defclass(_DateTimeData () (
    ; _DateTimeData 数据桶：收纳 DateTime 的 Unix 秒，构造后禁写。
    time(
        \@initarg time
        \@initform 0
    )
))

defclass(DateTime () (
    ; DateTime 实例：以 Unix 秒为唯一状态的不可变时间对象；同一秒驻留共享同一实例。
    ; 状态桶（_DateTimeData：time），构造后禁写
    _data(
        \@initarg _data
        \@initform nil
    )
    epoch()
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
    ; 返回 DateTime 的打印描述串，形如 ycDateTime::DateTime(1793715057)。
    ;
    ; **返回**
    ;   (str) - 命名空间限定的构造调用形式，顶层 evalstring 可复得同一驻留实例
    lsprintf("%A(%d)" className(self) self->_data->time)
)


; ---------- residency and constructors ----------

; 驻留表：Unix 秒 → DateTime（同一秒共享同一实例，== 为真）。
; 有界：超过 _DateTimeCacheCap 条整体清空重计（丢共享只弱化 == 快路径，不改结果）。
_DateTimeCache = makeTable("ycDateTimeCache" nil)
_DateTimeCacheCap = 8192
_DateTimeCacheN = 0


procedure(_DateTimeTime(g_x "g")  ; -> int | nil
    ; 取 DateTime 或整数时间值对应的 Unix 秒。
    ;
    ; **参数**
    ;   g_x  (any) - DateTime 实例或整数秒
    ;
    ; **返回**
    ;   (int|nil) - 可识别时返回秒；其他类型返回 nil
    cond(
        (fixp(g_x) g_x)
        (t
            let((l_res)
                l_res = errset(g_x->epoch() nil)
                when(l_res && car(l_res) && fixp(car(l_res))
                    car(l_res)
                )
            )
        )
    )
)


procedure(_MkDateTime(n_time "x")  ; -> DateTime
    ; 按 Unix 秒取回（或新建）驻留实例。
    ;
    ; **参数**
    ;   n_time  (int) - Unix 秒（1970-01-01 00:00:00 UTC 起算，可为负）
    ;
    ; **返回**
    ;   (DateTime) - 同一秒共享同一实例；超过 _DateTimeCacheCap 条整表清空重计
    let((hit)
        hit = _DateTimeCache[n_time]
        unless(hit
            hit = makeInstance('DateTime ?_data makeInstance('_DateTimeData ?time n_time))
            _DateTimeCache[n_time] = hit
            _DateTimeCacheN++
            when(_DateTimeCacheCap < _DateTimeCacheN
                _DateTimeCache = makeTable("ycDateTimeCache" nil)
                _DateTimeCacheN = 0
            )
        )
        hit
    )
)


procedure(DateTime(n_time "x")  ; -> DateTime
    ; 按 Unix 秒构造时间对象。
    ;
    ; **参数**
    ;   n_time  (int) - Unix 秒（1970-01-01 00:00:00 UTC 起算，可为负）
    ;
    ; **返回**
    ;   (DateTime) - 该秒的驻留实例
    _MkDateTime(n_time)
)


procedure(Now()  ; -> DateTime
    ; 返回当前时刻的 DateTime。
    ;
    ; **返回**
    ;   (DateTime) - 由 getCurrentTime() 换算的当前时刻；读取失败时 error() 中断
    let((n_now)
        n_now = stringToTime(getCurrentTime())
        unless(fixp(n_now) && 0 <= n_now
            error("ycDateTime::Now: cannot read the current time")
        )
        _MkDateTime(n_now)
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
    ; 返回 Unix 秒。
    ;
    ; **返回**
    ;   (int) - 1970-01-01 00:00:00 UTC 起算的秒数（可为负）
    self->_data->time
)

self->format = lambda((\@optional t_pattern("%F %T") "t")  ; -> str
    ; 按模板把本地时间格式化为串。
    ;
    ; **参数**
    ;   t_pattern  (str) - 模板；默认 "%F %T"（等值于 "%Y-%m-%d %H:%M:%S"，令牌见 README）
    ;
    ; **返回**
    ;   (str) - 格式化结果；未知令牌或末尾悬空 % 时 error() 中断
    _FormatTime(self->_data->time t_pattern "ycDateTime::DateTime->format")
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

self->add = lambda((\@key (seconds 0) (minutes 0) (hours 0) (days 0) "xxxx")  ; -> DateTime
    ; 按固定时长偏移，返回新时刻（原对象不变）。
    ;
    ; **参数**
    ;   ?seconds  (int) - 秒增量（默认 0，可为负）
    ;   ?minutes  (int) - 分钟增量（默认 0，可为负）
    ;   ?hours    (int) - 小时增量（默认 0，可为负）
    ;   ?days     (int) - 天数增量（默认 0，可为负；一天按 86400 秒计）
    ;
    ; **返回**
    ;   (DateTime) - 新时刻；增量全为 0 时返回自身（同一驻留实例）
    _MkDateTime(self->_data->time + seconds + minutes * 60 + hours * 3600 + days * 86400)
)

self->diff = lambda((g_other "g")  ; -> int
    ; 返回与另一时刻的秒差。
    ;
    ; **参数**
    ;   g_other  (DateTime|int) - 另一个时刻，或整数 Unix 秒
    ;
    ; **返回**
    ;   (int) - self 减 g_other 的秒数（self 更晚为正）；参数不可识别时 _err() 中断
    let((n_other)
        n_other = _DateTimeTime(g_other)
        unless(fixp(n_other)
            _err("diff" "expected a DateTime or an integer time, got %A" g_other)
        )
        self->_data->time - n_other
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
    let((n_other n_delta)
        n_other = _DateTimeTime(g_other)
        unless(fixp(n_other)
            _err("compare" "expected a DateTime or an integer time, got %A" g_other)
        )
        n_delta = self->_data->time - n_other
        cond(
            (n_delta < 0 -1)
            (0 < n_delta 1)
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
