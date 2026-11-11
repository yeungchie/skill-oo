useNamespace("ycQueue")

; ---------- 共享助手 ----------
;
; 空读契约：「未指定 ?onEmpty」与「?onEmpty 显式给 nil」必须可区分，而引擎不会
; 把未传的关键字暴露给过程体。标记是普通符号字面量 '_NoneArg（只在本模块使用，
; 不是命名空间变量、无需登记）；缺省位与空读比较都直接写这个字面量，比较用值
; 相等 ==。本库内写裸名，三冒号只用于跨库引用；「不供用户使用」只是命名约定。

; 两个助手都由方法 lambda 显式传入队列对象（全局过程读不到调用方的 self）。

procedure(_EmptyResult(g_obj t_method g_onEmpty "gtg")  ; -> any
    ; 统一空读契约：未指定 ?onEmpty 时报错，否则原样返回给定值。
    ;
    ; **参数**
    ;   g_obj      (any) - 调用方队列对象，用于错误消息里的类名
    ;   t_method   (str) - 错误消息里的方法名
    ;   g_onEmpty  (any) - 空读返回值；未指定时为内部标记符号
    ;
    ; **返回**
    ;   (any) - g_onEmpty 的原值；未指定时以 error() 中断
    when(g_onEmpty == '_NoneArg
        error("%A->%s: queue is empty" className(g_obj) t_method)
    )
    g_onEmpty
)

procedure(_Position(g_obj t_method n_index n_size "gtxx")  ; -> int
    ; 把 peek 的 0-based/负索引换算成从表头起的位置，并统一越界报错。
    ;
    ; **参数**
    ;   g_obj      (any) - 调用方队列对象，用于错误消息里的类名
    ;   t_method   (str) - 错误消息里的方法名
    ;   n_index    (int) - 调用方给的索引（可负）
    ;   n_size     (int) - 队列当前元素数（调用方保证 > 0）
    ;
    ; **返回**
    ;   (int) - 从表头起的位置（0 ≤ 位置 < n_size）；越界时以 error() 中断
    when(n_index >= n_size || n_index < -n_size
        error("%A->%s: index %d out of range (size %d)" className(g_obj) t_method n_index n_size)
    )
    if(n_index >= 0
    then
        n_index
    else
        n_size + n_index
    )
)

unuseNamespace("ycQueue")

; END
