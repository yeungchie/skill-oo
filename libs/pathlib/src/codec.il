;--------------------------
; Program  : ycPathLib(src/codec.il)
; Language : Cadence Skill
;--------------------------

ycNamespace:::require("ycJson")
ycNamespace:::require("ycYaml")
ycNamespace:::require("ycCsv")
ycNamespace:::require("ycToml")

useNamespace("ycPathLib")

inScheme(
procedure(_installCodec(self "g")  ; -> any
    ; 把 codec 方法安装到 Path 类（由 initializeInstance 调用）。
    ;
    ; **返回**
    ;   (any) - 返回最后一条安装赋值的结果，调用方忽略

procedure(_error(t_method t_formatString \@rest g_args "ttg")  ; -> never
    ; 按统一格式 error() 中断：消息形如 <类名>-><方法名>: <说明>。
    ;
    ; **参数**
    ;   t_method        (str) - 出错的方法名
    ;   t_formatString  (str) - 错误说明格式串（lsprintf 格式）
    ;   g_args          (list) - 变参：格式串实参
    ;
    ; **返回**
    ;   (never) - 总是调用 error()，不返回
    error("%A->%s: %s" className(self) t_method apply('lsprintf t_formatString g_args))
)

self->readJson = lambda((\@rest l_args "g")  ; -> any | list
    ; 读取整个文件内容并解码为 JSON 值；实参原样透传给 ycJson::decode。
    ;
    ; **参数**
    ;   l_args  (list) - 原样透传给 ycJson::decode 的实参（?format、?maxDepth 等；可全部省略）
    ;
    ; **返回**
    ;   (any|list) - ycJson::decode 的返回值（jsonl 为 list）；ycJson 未加载、文件错误、解码失败均以 error() 中断
    unless(fboundp('ycJson:::decode)
        _error("readJson" "ycJson is not loaded - load it first")
    )
    apply('ycJson:::decode self->readText() l_args)
)

self->readYaml = lambda((\@rest l_args "g")  ; -> any | list
    ; 读取整个文件内容并解码为 YAML 值；实参原样透传给 ycYaml::decode。
    ;
    ; **参数**
    ;   l_args  (list) - 原样透传给 ycYaml::decode 的实参（?format、?maxDepth 等；可全部省略）
    ;
    ; **返回**
    ;   (any|list) - ycYaml::decode 的返回值（yaml-stream 为 list）；ycYaml 未加载、文件错误、解码失败均以 error() 中断
    unless(fboundp('ycYaml:::decode)
        _error("readYaml" "ycYaml is not loaded - load it first")
    )
    apply('ycYaml:::decode self->readText() l_args)
)

self->readCsv = lambda((\@rest l_args "g")  ; -> Table
    ; 读取整个文件内容并解码为 CSV/TSV Table；实参原样透传给 ycCsv::decode。
    ;
    ; **参数**
    ;   l_args  (list) - 原样透传给 ycCsv::decode 的实参（?format、?header、?delimiter 等；可全部省略）
    ;
    ; **返回**
    ;   (Table) - ycCsv::Table；ycCsv 未加载、文件错误、解码失败均以 error() 中断
    unless(fboundp('ycCsv:::decode)
        _error("readCsv" "ycCsv is not loaded - load it first")
    )
    apply('ycCsv:::decode self->readText() l_args)
)

self->readToml = lambda((\@rest l_args "g")  ; -> table
    ; 读取整个文件内容并解码为 TOML 根 table；实参原样透传给 ycToml::decode。
    ;
    ; **参数**
    ;   l_args  (list) - 原样透传给 ycToml::decode 的实参（?maxDepth 等；可全部省略）
    ;
    ; **返回**
    ;   (table) - ycToml::decode 的根 table；ycToml 未加载、文件错误、解码失败均以 error() 中断
    unless(fboundp('ycToml:::decode)
        _error("readToml" "ycToml is not loaded - load it first")
    )
    apply('ycToml:::decode self->readText() l_args)
)
)
)

unuseNamespace("ycPathLib")

; END
