ycNamespace:::Require("ycCsv")
ycNamespace:::Require("ycLang")
ycNamespace:::Require("ycSubProcess")

useNamespace("ycSQLite")


defclass(_DatabaseData () (
    ; _DatabaseData 数据桶：数据库路径、客户端、会话与事务状态。
    path(
        \@initarg path
        \@initform ""
    )
    client(
        \@initarg client
        \@initform nil
    )
    timeout(
        \@initarg timeout
        \@initform 10
    )
    busyTimeout(
        \@initarg busyTimeout
        \@initform nil
    )
    foreignKeys(
        \@initarg foreignKeys
        \@initform nil
    )
    job(
        \@initarg job
        \@initform nil
    )
    closed(
        \@initarg closed
        \@initform nil
    )
    counter(
        \@initarg counter
        \@initform 0
    )
    txDepth(
        \@initarg txDepth
        \@initform 0
    )
))

defclass(Database () (
    ; Database 长驻 SQLite 会话：查询、执行、事务与 schema 访问。
    _data(
        \@initarg _data
        \@initform nil
    )
    path()
    client()
    isPersistent()
    isClosed()
    close()
    query()
    execute()
    executeScript()
    transaction()
    tables()
    columns()
    schema()
    exists()
))


procedure(_DbError(g_obj t_method t_format \@rest l_args "gttg")  ; -> never
    ; 按 Database 方法上下文报错。
    ;
    ; **参数**
    ;   g_obj     (Database) - 数据库对象
    ;   t_method  (str) - 方法名
    ;   t_format  (str) - 消息格式
    ;   l_args    (list) - 格式参数
    ;
    ; **返回**
    ;   (never) - 总是 error() 中断
    error("%A->%s: %s" className(g_obj) t_method
        apply('lsprintf t_format l_args))
)


procedure(_CheckDatabase(g_obj g_data t_method "ggt")  ; -> t
    ; 校验会话仍打开。
    ;
    ; **参数**
    ;   g_obj     (Database) - 数据库对象
    ;   g_data    (_DatabaseData) - 数据桶
    ;   t_method  (str) - 方法名
    ;
    ; **返回**
    ;   (t) - 打开时返回 t；已关闭时 error() 中断
    when(g_data->closed
        _DbError(g_obj t_method "database is closed: %s" g_data->path)
    )
    t
)


procedure(_SessionAlive(g_data "g")  ; -> t | nil
    ; 判断会话进程是否仍存活。
    ;
    ; **参数**
    ;   g_data  (_DatabaseData) - 数据桶
    ;
    ; **返回**
    ;   (t|nil) - 存活为 t
    g_data->job && !g_data->closed && g_data->job->state() != 'Dead
)


procedure(_SessionErrorLine(t_text "t")  ; -> str | nil
    ; 从客户端诊断输出中找 SQLite 错误行。
    ;
    ; **参数**
    ;   t_text  (str) - 客户端诊断输出（stderr）
    ;
    ; **返回**
    ;   (str|nil) - 第一条错误行
    let((found)
        foreach(line _SplitLines(t_text)
            when(!found
                && !_StrPos(line "__YC_SQLITE_BARRIER")
                && pcreMatchp(
                    "^(Error|Parse error|Runtime error)( near line [0-9]+)?:"
                    line)
                found = line
            )
        )
        found
    )
)


procedure(_StripBarrier(t_text "t")  ; -> str
    ; 去掉 stderr 屏障产生的诊断行。
    ;
    ; 按内部前缀匹配所有屏障 id，而不是只匹配当前请求的 id：
    ; 慢客户端上，上一条屏障的后续行可能在本轮才到达。
    ;
    ; **参数**
    ;   t_text  (str) - 客户端诊断输出
    ;
    ; **返回**
    ;   (str) - 不含屏障行的诊断输出
    let((res)
        foreach(line _SplitLines(t_text)
            unless(_StrPos(line "__YC_SQLITE_BARRIER")
                res = strcat(if(res res "") if(res "\n" "") line)
            )
        )
        if(res res "")
    )
)


procedure(_SessionSend(g_obj g_data t_text t_method "ggtt")  ; -> str
    ; 向长驻会话发送请求并读取到唯一标记。
    ; 每次请求后额外发送一个必然失败的函数调用作为 stderr 屏障，
    ; 确保客户端诊断已进入读取缓冲后再判断错误。
    ; stderr 严重滞后时，真实诊断可能落到下一次请求；
    ; 本函数无法把迟到的诊断归回原请求。
    ;
    ; **参数**
    ;   g_obj     (Database) - 数据库对象
    ;   g_data    (_DatabaseData) - 数据桶
    ;   t_text    (str) - SQL 或点命令
    ;   t_method  (str) - 方法名
    ;
    ; **返回**
    ;   (str) - 标记之前的输出；超时、进程退出或 SQL 错误时 error() 中断
    let((job marker barrier text pos body errText errMsg limit n)
        _CheckDatabase(g_obj g_data t_method)
        job = g_data->job
        unless(job && job->state() != 'Dead
            g_data->closed = t
            _DbError(g_obj t_method "database session is not running: %s"
                g_data->path)
        )
        g_data->counter = g_data->counter + 1
        marker = lsprintf("__YC_SQLITE_%A_%d__"
            gensym() g_data->counter)
        barrier = lsprintf("__YC_SQLITE_BARRIER_%d__"
            g_data->counter)
        job->send("%s" t_text)
        job->send("select %s();" barrier)
        job->send(".print %s" marker)
        limit = if(g_data->timeout g_data->timeout 10)
        n = 0
        text = ""
        while(n < limit * 20
            text = job->stdout()->text()
            when(_StrPos(text marker) || job->state() == 'Dead
                n = limit * 20
            )
            unless(_StrPos(text marker) || job->state() == 'Dead
                job->sleep(0.05)
                n++
            )
        )
        text = job->stdout()->text()
        pos = _StrPos(text marker)
        unless(pos
            body = text
            errset(job->kill() nil)
            g_data->closed = t
            _DbError(g_obj t_method
                "session timed out or terminated while running; output: %A"
                body)
        )
        body = if(pos > 1 substring(text 1 pos - 1) "")
        ; 等待 stderr 屏障；标准 sqlite3 会立即出现，超时则按旧路径处理。
        n = 0
        errText = job->stderr()->text()
        while(n < 15 && !_StrPos(errText barrier) && job->state() != 'Dead
            job->sleep(0.02)
            errText = job->stderr()->text()
            n++
        )
        job->stdout()->text(?clear t)
        errText = _StripBarrier(job->stderr()->text(?clear t))
        errMsg = _SessionErrorLine(errText)
        when(errMsg
            _DbError(g_obj t_method "%s" errMsg)
        )
        body
    )
)


procedure(_StartSession(g_obj g_data "gg")  ; -> t
    ; 启动数据库长驻会话并发送初始化命令。
    ;
    ; **参数**
    ;   g_obj   (Database) - 数据库对象
    ;   g_data  (_DatabaseData) - 数据桶
    ;
    ; **返回**
    ;   (t) - 启动成功；失败时清理进程并 error() 中断
    let((res msg)
        res = errset(
            let((cmd job)
                cmd = g_data->client->sessionCommand(g_data->path)
                job = apply('ycSubProcess::CreateJob car(cmd) cdr(cmd))->start()
                g_data->job = job
                job->sleep(0.2)
                _SessionSend(g_obj g_data ".bail off" "open")
                _SessionSend(g_obj g_data ".headers off" "open")
                _SessionSend(g_obj g_data ".mode list" "open")
                _SessionSend(g_obj g_data ".separator |" "open")
                _SessionSend(g_obj g_data
                    lsprintf("pragma foreign_keys=%s;"
                        if(g_data->foreignKeys "on" "off"))
                    "open")
                _SessionSend(g_obj g_data "select 1;" "open")
                when(g_data->busyTimeout
                    _SessionSend(g_obj g_data
                        lsprintf("pragma busy_timeout=%d;" g_data->busyTimeout)
                        "open")
                )
                t
            )
            nil
        )
        unless(res
            msg = _ErrText(errset.errset)
            errset(_CloseDatabase(g_obj g_data) nil)
            error("ycSQLite::Open: cannot start database session: %s"
                msg)
        )
        car(res)
    )
)


procedure(_Query(g_obj g_data t_sql "ggt")  ; -> Result
    ; 执行只读查询并返回结果集。
    ;
    ; **参数**
    ;   g_obj   (Database) - 数据库对象
    ;   g_data  (_DatabaseData) - 数据桶
    ;   t_sql   (str) - 已绑定参数的 SELECT/WITH/VALUES
    ;
    ; **返回**
    ;   (Result) - 查询结果
    let((res msg text header columns rows)
        res = errset(
            let((result)
                _CheckQuery(t_sql)
                _SessionSend(g_obj g_data
                    "drop table if exists temp.__yc_sqlite_q;" "query")
                _SessionSend(g_obj g_data
                    lsprintf("create temp table __yc_sqlite_q as %s\n;" t_sql)
                    "query")
                _SessionSend(g_obj g_data ".mode csv" "query")
                header = _SessionSend(g_obj g_data
                    "pragma table_info(__yc_sqlite_q);" "query")
                columns = _ParseTableInfo(header "ycSQLite::Database->query")
                _SessionSend(g_obj g_data ".mode list" "query")
                _SessionSend(g_obj g_data ".separator |" "query")
                text = _SessionSend(g_obj g_data
                    _EncodedSelect(columns) "query")
                rows = _ParseRows(text columns "ycSQLite::Database->query")
                Result(?columns columns ?rows rows)
            )
            nil
        )
        when(!res
            msg = _ErrText(errset.errset)
        )
        errset(
            _SessionSend(g_obj g_data ".headers off" "query")
            nil
        )
        errset(
            _SessionSend(g_obj g_data ".mode list" "query")
            nil
        )
        errset(
            _SessionSend(g_obj g_data ".separator |" "query")
            nil
        )
        errset(
            _SessionSend(g_obj g_data
                "drop table if exists temp.__yc_sqlite_q;" "query")
            nil
        )
        unless(res
            error("%s" msg)
        )
        car(res)
    )
)


procedure(_Pragma(g_obj g_data t_sql "ggt")  ; -> Result
    ; 执行 PRAGMA 并按 CSV 结果构造字符串结果集。
    ;
    ; **参数**
    ;   g_obj   (Database) - 数据库对象
    ;   g_data  (_DatabaseData) - 数据桶
    ;   t_sql   (str) - PRAGMA 语句
    ;
    ; **返回**
    ;   (Result) - 结果集
    let((res msg text table rawRows header rows columns)
        res = errset(
            let((result)
                _SessionSend(g_obj g_data ".headers on" "columns")
                _SessionSend(g_obj g_data ".mode csv" "columns")
                text = _SessionSend(g_obj g_data t_sql "columns")
                _SessionSend(g_obj g_data ".headers off" "columns")
                _SessionSend(g_obj g_data ".mode list" "columns")
                _SessionSend(g_obj g_data ".separator |" "columns")
                table = ycCsv:::Decode(text ?header nil)
                rawRows = table->rows()
                unless(rawRows
                    _DbError(g_obj "columns" "PRAGMA returned no rows: %s" t_sql)
                )
                header = car(rawRows)
                columns = list()
                foreach(name header
                    columns = tconc(columns name)
                )
                columns = car(columns)
                rows = nil
                foreach(raw cdr(rawRows)
                    rows = tconc(rows Row(raw columns))
                )
                Result(?columns columns ?rows car(rows))
            )
            nil
        )
        when(!res
            msg = _ErrText(errset.errset)
        )
        errset(
            _SessionSend(g_obj g_data ".headers off" "columns")
            nil
        )
        errset(
            _SessionSend(g_obj g_data ".mode list" "columns")
            nil
        )
        errset(
            _SessionSend(g_obj g_data ".separator |" "columns")
            nil
        )
        unless(res
            error("%s" msg)
        )
        car(res)
    )
)


procedure(_CloseDatabase(g_obj g_data "gg")  ; -> t
    ; 关闭数据库会话；幂等。
    ;
    ; **参数**
    ;   g_obj   (Database) - 数据库对象
    ;   g_data  (_DatabaseData) - 数据桶
    ;
    ; **返回**
    ;   (t) - 恒为 t
    unless(g_data->closed
        g_data->closed = t
        when(g_data->job
            when(g_data->job->state() != 'Dead
                errset(g_data->job->send(".quit") nil)
                g_data->job->sleep(0.2)
                when(g_data->job->state() != 'Dead
                    errset(g_data->job->kill() nil)
                )
            )
            errset(g_data->job->close() nil)
        )
    )
    t
)


procedure(_Transaction(g_obj g_data g_body "ggg")  ; -> any
    ; 在长驻会话中执行事务回调，支持嵌套保存点。
    ;
    ; **参数**
    ;   g_obj   (Database) - 数据库对象
    ;   g_data  (_DatabaseData) - 数据桶
    ;   g_body  (function) - 回调，接收 Database 对象
    ;
    ; **返回**
    ;   (any) - 回调返回值；回调失败时回滚并重新抛出错误
    let((depth sp res msg)
        depth = g_data->txDepth + 1
        sp = lsprintf("yc_sqlite_sp_%d" depth)
        if(depth == 1
        then
            _SessionSend(g_obj g_data "begin;" "transaction")
        else
            _SessionSend(g_obj g_data
                lsprintf("savepoint %s;" sp) "transaction")
        )
        g_data->txDepth = depth
        res = errset(funcall(g_body g_obj) nil)
        if(res
        then
            if(depth == 1
            then
                _SessionSend(g_obj g_data "commit;" "transaction")
            else
                _SessionSend(g_obj g_data
                    lsprintf("release savepoint %s;" sp) "transaction")
            )
            g_data->txDepth = depth - 1
            car(res)
        else
            msg = _ErrText(errset.errset)
            errset(
                if(depth == 1
                then
                    _SessionSend(g_obj g_data "rollback;" "transaction")
                else
                    _SessionSend(g_obj g_data
                        lsprintf("rollback to savepoint %s; release savepoint %s;"
                            sp sp)
                        "transaction")
                )
                nil
            )
            g_data->txDepth = depth - 1
            error("ycSQLite::Database->transaction: %s" msg)
        )
    )
)


defmethod(printself (self(Database))  ; -> str
    ; 返回数据库对象的打印描述串。
    ;
    ; **返回**
    ;   (str) - <ycSQLite::Database path="..." closed=nil>
    lsprintf("<%A path=%A closed=%A>"
        className(self) self->_data->path self->_data->closed)
)


defmethod(__ycWithEnter__ (self(Database))  ; -> Database
    ; with 协议：进入作用域时返回数据库自身。
    ;
    ; **返回**
    ;   (Database) - self
    self
)


defmethod(__ycWithExit__ (self(Database))  ; -> t
    ; with 协议：退出作用域时关闭数据库会话。
    ;
    ; **返回**
    ;   (t) - close() 的返回值
    self->close()
)


inScheme(
procedure(_InstallDatabase(self "g")  ; -> t
    ; 安装 Database 的全部方法。
    ;
    ; **返回**
    ;   (t) - 安装完成
    self->path = lambda(()  ; -> str
        ; 返回数据库路径。
        ;
        ; **返回**
        ;   (str) - 数据库路径
        self->_data->path
    )
    self->client = lambda(()  ; -> Client
        ; 返回客户端对象。
        ;
        ; **返回**
        ;   (Client) - 客户端对象
        self->_data->client
    )
    self->isPersistent = lambda(()  ; -> t
        ; 首版始终使用长驻会话。
        ;
        ; **返回**
        ;   (t) - 恒为 t
        t
    )
    self->isClosed = lambda(()  ; -> t | nil
        ; 查询会话是否关闭。
        ;
        ; **返回**
        ;   (t|nil) - 已关闭为 t
        self->_data->closed
    )
    self->close = lambda(()  ; -> t
        ; 关闭会话；可重复调用。
        ;
        ; **返回**
        ;   (t) - 恒为 t
        _CloseDatabase(self self->_data)
    )
    self->query = lambda((t_sql \@key (params nil) "tg")  ; -> Result
        ; 执行只读查询。
        ;
        ; **参数**
        ;   t_sql   (str) - SELECT/WITH/VALUES
        ;   ?params (list|nil) - 位置参数
        ;
        ; **返回**
        ;   (Result) - 查询结果
        _Query(self self->_data _BindSql(t_sql params))
    )
    self->execute = lambda((t_sql \@key (params nil) "tg")  ; -> Result
        ; 执行 DDL/DML。
        ;
        ; **参数**
        ;   t_sql   (str) - DDL/DML
        ;   ?params (list|nil) - 位置参数
        ;
        ; **返回**
        ;   (Result) - changes 与 lastInsertRowid
        let((text lines baselineText baseline parsed total delta sql)
            sql = _BindSql(t_sql params)
            _CheckNoDotCommands(sql "ycSQLite::Database->execute")
            text = _SessionSend(self self->_data
                lsprintf("select total_changes();\n%s\n;\nselect changes(), last_insert_rowid(), total_changes();"
                    sql)
                "execute")
            lines = _SplitLines(text)
            unless(2 <= length(lines)
                error("ycSQLite::Database->execute: unexpected session output %A"
                    text)
            )
            baselineText = car(lines)
            unless(pcreMatchp("^[0-9]+$" baselineText)
                error("ycSQLite::Database->execute: invalid total_changes() output %A"
                    baselineText)
            )
            baseline = _ParseInteger(baselineText
                "ycSQLite::Database->execute")
            unless(fixp(baseline)
                error("ycSQLite::Database->execute: total_changes() exceeds the fixnum range; reopen the database to reset it")
            )
            parsed = _ParseChanges(
                car(reverse(lines)) "ycSQLite::Database->execute")
            total = nth(2 parsed)
            unless(fixp(total)
                error("ycSQLite::Database->execute: total_changes() exceeds the fixnum range; reopen the database to reset it")
            )
            delta = total - baseline
            Result(
                ?changes delta
                ?lastInsertRowid cadr(parsed)
            )
        )
    )
    self->executeScript = lambda((t_sql "t")  ; -> t
        ; 执行多语句脚本。
        ;
        ; **参数**
        ;   t_sql  (str) - SQL 脚本
        ;
        ; **返回**
        ;   (t) - 执行完成
        _CheckNoDotCommands(t_sql "ycSQLite::Database->executeScript")
        _SessionSend(self self->_data strcat(t_sql "\n;") "executeScript")
        t
    )
    self->transaction = lambda((g_body "g")  ; -> any
        ; 执行事务回调。
        ;
        ; **参数**
        ;   g_body  (function) - 接收 Database 的回调
        ;
        ; **返回**
        ;   (any) - 回调返回值
        _Transaction(self self->_data g_body)
    )
    self->tables = lambda(()  ; -> list[str]
        ; 返回用户表名列表。
        ;
        ; **返回**
        ;   (list[str]) - 表名
        let((res rows)
            rows = _Query(self self->_data
                "select name from sqlite_master where type = 'table' and name not like 'sqlite_%' order by name;")
            foreach(row rows->rows()
                res = tconc(res row->get(0))
            )
            car(res)
        )
    )
    self->columns = lambda((t_table "t")  ; -> Result
        ; 返回表的 PRAGMA table_info 结果。
        ;
        ; **参数**
        ;   t_table  (str) - 表名
        ;
        ; **返回**
        ;   (Result) - 字符串形式的列信息
        _Pragma(self self->_data
            lsprintf("pragma table_info(%s);" _QuoteIdentifier(t_table)))
    )
    self->schema = lambda((\@key (table nil) "g")  ; -> str | nil
        ; 返回表或视图的 CREATE 语句。
        ;
        ; **参数**
        ;   ?table  (str|nil) - 表名；nil 返回全部 schema
        ;
        ; **返回**
        ;   (str|nil) - schema 文本
        let((result rows)
            result = if(table
            then
                _Query(self self->_data
                    _BindSql(
                        "select sql from sqlite_master where type in ('table', 'view') and name = ?;"
                        list(table)
                    )
                )
            else
                _Query(self self->_data
                    "select sql from sqlite_master where type in ('table', 'view') order by name;")
            )
            rows = result->rows()
            when(rows
                if(table
                then
                    car(rows)->get(0)
                else
                    let((text)
                        text = ""
                        foreach(row rows
                            text = strcat(text if(text "\n" "")
                                row->get(0))
                        )
                        text
                    )
                )
            )
        )
    )
    self->exists = lambda((t_table "t")  ; -> t | nil
        ; 查询表或视图是否存在。
        ;
        ; **参数**
        ;   t_table  (str) - 表名
        ;
        ; **返回**
        ;   (t|nil) - 存在为 t
        let((result)
            result = _Query(self self->_data
                _BindSql(
                    "select 1 from sqlite_master where type in ('table', 'view') and name = ? limit 1;"
                    list(t_table)
                )
            )
            result->rowCount() > 0
        )
    )
    t
)
)


procedure(Open(t_path \@key (timeout nil) (busyTimeout nil) (foreignKeys 'ycLang:::NoneArg) "tggg")  ; -> Database
    ; 打开数据库并启动长驻会话。
    ;
    ; **参数**
    ;   t_path        (str) - 数据库路径或 ":memory:"
    ;   ?timeout      (int|nil) - 会话等待秒数
    ;   ?busyTimeout  (int|nil) - PRAGMA busy_timeout 毫秒数
    ;   ?foreignKeys  (t|nil) - 会话启动时的外键开关；省略为 t
    ;
    ; **返回**
    ;   (Database) - 数据库对象；配置或会话失败时 error() 中断
    let((client2 limit)
        unless(stringp(t_path) && t_path != ""
            error("ycSQLite::Open: path must be a non-empty string")
        )
        when(timeout
            unless(fixp(timeout) && timeout > 0
                error("ycSQLite::Open: ?timeout must be a positive integer or nil")
            )
        )
        when(busyTimeout
            unless(fixp(busyTimeout) && busyTimeout >= 0
                error("ycSQLite::Open: ?busyTimeout must be a non-negative integer or nil")
            )
        )
        when(foreignKeys == 'ycLang:::NoneArg
            foreignKeys = t
        )
        unless(foreignKeys == t || foreignKeys == nil
            error("ycSQLite::Open: ?foreignKeys must be t or nil")
        )
        client2 = DefaultClient()
        client2->validate()
        unless(client2->isValid()
            error("ycSQLite::Open: client validation failed: %s"
                client2->diagnostics())
        )
        unless(client2->supports('session)
            error("ycSQLite::Open: client has no persistent session capability: %s"
                buildString(client2->command() " "))
        )
        limit = if(timeout timeout if(client2->timeout() client2->timeout() 10))
        makeInstance('Database ?_data makeInstance('_DatabaseData
            ?path t_path
            ?client client2
            ?timeout limit
            ?busyTimeout busyTimeout
            ?foreignKeys foreignKeys
        ))
    )
)


inScheme(
defmethod(initializeInstance (self(Database) \@rest _args)
    ; 构造 Database 实例时安装方法并启动会话。
    ;
    ; **参数**
    ;   _args  (list) - 附加参数，本实现忽略
    ;
    ; **返回**
    ;   (t) - 启动完成
    _InstallDatabase(self)
    _StartSession(self self->_data)
    t
)
)

unuseNamespace("ycSQLite")

; END
