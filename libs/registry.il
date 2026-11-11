;--------------------------
; Program  : skill-oo(libs/registry.il)
; Language : Cadence Skill
;--------------------------

; Known namespaces accepted by ycNamespace:::Require. This is a plain name
; list: loading order and file lists stay in libs/load.il and each package
; load.il; shells created by Require hold no code - they only make
; cross-library references (ycOther:::name) readable before that library is
; loaded. Keep this list in sync with the packages under libs/.

unless(findNamespace("ycNamespace")
    makeNamespace("ycNamespace")
)

; 所有命名空间符号都登记（2026-11-11 用户裁决）：图省事写成 ::: 定义并不等于
; 「不登记」；这里补 addToNamespace，让 _ValidNames / Require 同在导出名单里。
addToNamespace("ycNamespace"
    mapcar('symbolToString '(
        ; registry.il
        _ValidNames  ; var
        Require  ; proc
    ))
)

ycNamespace:::_ValidNames = list(
    "ycPathLib"
    "ycIO"
    "ycLang"
    "ycRegEx"
    "ycSubProcess"
    "ycCodec"
    "ycJson"
    "ycYaml"
    "ycCsv"
    "ycToml"
    "ycIni"
    "ycUtf8"
    "ycString"
    "ycUnits"
    "ycRadix"
    "ycGeom"
    "ycTextwrap"
    "ycTabulate"
    "ycDateTime"
    "ycLog"
    "ycQueue"
)

procedure(ycNamespace:::Require(@rest l_names "t")  ; -> t
    ; 确保给定命名空间均可用：不存在者建立空壳命名空间，不加载任何代码；
    ; 名单外的名字报错。
    ;
    ; **参数**
    ;   l_names  (list[str]) - 命名空间名列表（@rest 收集，可多个；零参即空列表）
    ;
    ; **返回**
    ;   (t) - 全部已存在或已建立；名单外名字 error
    foreach(name l_names
        when(findNamespace(name) == nil
            unless(member(name ycNamespace:::_ValidNames)
                error("ycNamespace::Require: unknown namespace %A" name)
            )
            makeNamespace(name)
            unuseNamespace(name)
        )
    )
    t
)

unuseNamespace("ycNamespace")

; END
