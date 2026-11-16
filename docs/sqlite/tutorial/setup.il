;--------------------------
; Program  : ycSQLite tutorial setup
; Language : Cadence Skill
;--------------------------
; 教程辅助脚本：建库、装载样例数据、显示查询结果。
; 这些过程只服务于教程，不是 ycSQLite 的公开 API。

let((res path dir)
    res = errset(get_filename(piport) nil)
    path = when(res && car(res) && stringp(car(res)) && car(res) != ""
        car(res)
    )
    unless(path
        error("ycSQLite tutorial: can't determine setup.il path")
    )
    unless(pcreMatchp("^[~/]|^\\.{1,2}/" path)
        path = strcat("./" path)
    )
    dir = simplifyFilename(pcreReplace(pcreCompile("(?<=/)[^/]+/*$") path "" 0) t)
    unless(pcreMatchp("/$" dir)
        dir = strcat(dir "/")
    )
    _TutorialDir = dir
    _TutorialDataDir = strcat(dir "data/")
)

unless(findNamespace("ycSQLite")
    loadi(simplifyFilename(strcat(_TutorialDir "../../../libs/load.il")))
)

procedure(_TutorialSql(t_name "t")  ; -> str
    ; 读取 data 目录中的 SQL 文件。
    ;
    ; **参数**
    ;   t_name  (str) - SQL 文件名
    ;
    ; **返回**
    ;   (str) - 文件内容
    ycPathLib::Path(_TutorialDataDir)->join(t_name)->readText()
)

procedure(_TutorialApply(g_db t_name "gt")  ; -> t
    ; 把一个 SQL 文件交给数据库会话执行。
    ;
    ; **参数**
    ;   g_db    (ycSQLite::Database) - 目标数据库
    ;   t_name  (str) - SQL 文件名
    ;
    ; **返回**
    ;   (t) - 恒为 t
    g_db->executeScript(_TutorialSql(t_name))
    t
)

procedure(ycSQLiteTutorialShow(g_result "g")  ; -> str
    ; 把查询结果打印成文本表格，方便在 CIW 中阅读。
    ;
    ; **参数**
    ;   g_result  (ycSQLite::Result) - 查询结果
    ;
    ; **返回**
    ;   (str) - 渲染后的表格文本
    let((l_headers l_rows t_text)
        l_headers = g_result->columns()
        l_rows = mapcar(
            lambda((g_row) g_row->toList())
            g_result->rows()
        )
        t_text = if(l_headers
        then
            ycTabulate::Render(
                l_rows
                ?headers l_headers
                ?format "simple"
            )
        else
            ycTabulate::Render(l_rows ?format "simple")
        )
        printf("%s\n" t_text)
        t_text
    )
)

procedure(ycSQLiteTutorialSetup(\@key (dir "./sqlite-tutorial") (stage 'full) "ggg")  ; -> list
    ; 重建教程数据库。
    ;
    ; **参数**
    ;   ?dir    (str) - 数据库目录；默认 ./sqlite-tutorial
    ;   ?stage  (sym) - flat/full 建 drc 与 signoff；sch 建连接库；layout 建版图库；all 建四个
    ;
    ; **返回**
    ;   (list) - 本次建好的数据库路径
    let((p t_drc t_signoff t_sch t_layout l_paths l_built db sdb)
        unless(member(stage '(flat full sch layout all))
            error("ycSQLiteTutorialSetup: stage must be flat, full, sch, layout or all")
        )
        p = ycPathLib::Path(dir)
        p->mkdir(?parents t ?existOk t)
        t_drc = p->join("drc.db")->str()
        t_signoff = p->join("signoff.db")->str()
        t_sch = p->join("sch.db")->str()
        t_layout = p->join("layout.db")->str()
        when(stage == 'flat || stage == 'full || stage == 'all
            l_paths = append(l_paths list(t_drc t_signoff))
        )
        when(stage == 'sch || stage == 'all
            l_paths = append(l_paths list(t_sch))
        )
        when(stage == 'layout || stage == 'all
            l_paths = append(l_paths list(t_layout))
        )
        foreach(t_path l_paths
            ycPathLib::Path(t_path)->unlink(?missingOk t)
        )

        when(stage == 'flat || stage == 'full || stage == 'all
            db = ycSQLite::Open(t_drc)
            _TutorialApply(db "01_layers.sql")
            _TutorialApply(db "02_flat.sql")
            when(stage == 'full || stage == 'all
                _TutorialApply(db "03_relational.sql")
                _TutorialApply(db "04_waivers.sql")
            )
            db->close()

            sdb = ycSQLite::Open(t_signoff)
            _TutorialApply(sdb "05_signoff.sql")
            sdb->close()
            l_built = append(l_built list(t_drc t_signoff))
        )

        when(stage == 'sch || stage == 'all
            db = ycSQLite::Open(t_sch)
            _TutorialApply(db "06_sch.sql")
            db->close()
            l_built = append(l_built list(t_sch))
        )

        when(stage == 'layout || stage == 'all
            db = ycSQLite::Open(t_layout)
            _TutorialApply(db "07_layout.sql")
            db->close()
            l_built = append(l_built list(t_layout))
        )

        printf("tutorial setup: stage=%A dir=%s\n" stage dir)
        l_built
    )
)

procedure(ycSQLiteTutorialReset(\@key (dir "./sqlite-tutorial") "g")  ; -> t
    ; 删除教程数据库，让下一次 setup 从干净状态开始。
    ;
    ; **参数**
    ;   ?dir  (str) - 数据库目录；默认 ./sqlite-tutorial
    ;
    ; **返回**
    ;   (t) - 恒为 t
    let((p)
        p = ycPathLib::Path(dir)
        when(p->exists()
            foreach(t_name list("drc.db" "signoff.db" "sch.db" "layout.db" "scratch.db")
                p->join(t_name)->unlink(?missingOk t)
            )
        )
        printf("tutorial reset: removed databases under %s\n" dir)
        t
    )
)

; END
