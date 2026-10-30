unless(findNamespace("ycPathLib")
    makeNamespace("ycPathLib")
)
addToNamespace("ycPathLib"
    mapcar('symbolToString '(
        ; path.il
        Path  ; proc, class
        PathData  ; class
        Cwd  ; proc
        Home  ; proc
        CurrentFile  ; proc
        _AsPath  ; proc
        _ParsePath  ; proc
        _PathKey  ; proc
        _MkPath  ; proc
        _LastItem  ; proc
        _DropLast  ; proc
        _DropFirstN  ; proc
        _DotIndex  ; proc
        _LstripDots  ; proc
        _SplitKeep  ; proc
        _EndsWith  ; proc
        _StrMember  ; proc
        _ShellQuote  ; proc

        ; fnmatch.il
        _FnmatchBracket  ; proc
        _FnmatchToPcre  ; proc
        _Fnmatch1  ; proc
        _CanMatchEmpty  ; proc
        _AllMatchp  ; proc
        _SuffixMatchp  ; proc

        ; pure.il
        _InstallPure  ; proc

        ; fs.il
        _FsName  ; proc
        _DirNames  ; proc
        _InstallFs  ; proc

        ; glob.il
        _CollapseStars  ; proc
        _GlobDirs  ; proc
        _GlobTree  ; proc
        _GlobChain  ; proc
        _GlobPattern  ; proc
        _InstallGlob  ; proc

        ; codec.il
        _InstallCodec  ; proc
    ))
)
unuseNamespace("ycPathLib")

; END
