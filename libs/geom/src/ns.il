unless(findNamespace("ycGeom")
    makeNamespace("ycGeom")
)
; 收录规则：各来源文件的全部顶层 procedure、defclass 与顶层变量都列入，
; 只排除定义在 inScheme/let/procedure 内、名字不外泄的闭包；不按「是否被
; 外部引用」取舍，避免名单退化成随意子集。新增顶层符号须同步加进本表。
addToNamespace("ycGeom"
    mapcar('symbolToString '(
        ; point.il
        Point  ; proc, class
        _PointData  ; class
        _InstallPoint  ; proc

        ; segment.il
        Segment  ; proc, class
        _SegmentData  ; class
        _SegPointAt  ; proc
        _LineSegmentIntersection  ; proc
        _SegSegIntersection  ; proc
        _InstallSegment  ; proc

        ; line.il
        Line  ; proc, class
        _LineData  ; class
        _InstallLine  ; proc

        ; rect.il
        Rect  ; proc, class
        _RectData  ; class
        _RectPolygon  ; proc
        _InstallRect  ; proc

        ; route.il
        Route  ; proc, class
        _RouteData  ; class
        _InstallRoute  ; proc

        ; path.il
        Path  ; proc, class
        _PathData  ; class
        _InstallPath  ; proc

        ; polygon.il
        Polygon  ; proc, class
        _PolygonData  ; class
        _CheckPolygon  ; proc
        _ShapePolys  ; proc
        _ShapeOp  ; proc
        _InstallPolygon  ; proc

        ; region.il
        Region  ; proc, class
        _RegionData  ; class
        _UnionAll  ; proc
        _InstallRegion  ; proc

        ; internal.il
        _Eps  ; proc
        _AngleTol  ; proc
        _Grid  ; proc
        _SnapRound  ; proc
        _Snap  ; proc
        _Near  ; proc
        _Nth1  ; proc
        _PointP  ; proc
        _SegmentP  ; proc
        _LineP  ; proc
        _RectP  ; proc
        _PolygonP  ; proc
        _RegionP  ; proc
        _PairP  ; proc
        _PointAt  ; proc
        _AsPoint  ; proc
        _AsPointList  ; proc
        _TwoPoints  ; proc
        _AsSegment  ; proc
        _AsLine  ; proc
        _AsLineOrSegment  ; proc
        _AsPolygon  ; proc
        _AsPolygonList  ; proc
        _AsPolygons  ; proc
        _AsRegion  ; proc
        _GeomKind  ; proc
        _ConvertToGeomObject  ; proc
        ConvertToGeomObject  ; proc
        _SamePoint  ; proc
        _NumKey  ; proc
        _PtKey  ; proc
        _EdgeKey  ; proc
        _CellNumKey  ; proc
        _CanonPoint  ; proc
        _CanonRing  ; proc
        _Cross  ; proc
        _AreaTol  ; proc
        _SignedArea  ; proc
        _PointInRing  ; proc
        _OnSegment  ; proc
        _Orient  ; proc
        _SegmentsCross  ; proc
        _SeamKeys  ; proc
        _Rings  ; proc
        _RemovePoint  ; proc
        _FirstAdjPoint  ; proc
        _CollinearClean  ; proc
        _RingPointsClean  ; proc
        _BoundaryMode  ; proc
        _Flag  ; proc

        ; boolean.il
        _SnapRing  ; proc
        _CollectRings  ; proc
        _InsideRings  ; proc
        _ClassifyEdges  ; proc
        _RingEdgeList  ; proc
        _EdgeT  ; proc
        _AddCut  ; proc
        _InsertNum  ; proc
        _SortUniqueNums  ; proc
        _Lerp  ; proc
        _SplitEdges  ; proc
        _TraceLoops  ; proc
        _FirstTraceEdge  ; proc
        _ChooseNext  ; proc
        _RemoveEdge  ; proc
        _EvenDepth  ; proc
        _LoopDepth  ; proc
        _NestLoops  ; proc
        _RightmostIndex  ; proc
        _Rotate  ; proc
        _AxisHit  ; proc
        _SpliceHole  ; proc
        _BuildPolygons  ; proc
        _InResult  ; proc
        _Boolean  ; proc
        _CleanPolygons  ; proc
        Boolean  ; proc

        ; size.il
        _SizeRegion  ; proc
        _SizePolygon  ; proc
        _SizeExtendCap  ; proc
        _SizeCapSelected  ; proc
        _SizeRoundCap  ; proc
        _SizeStrip  ; proc
        _SizeLinePoint  ; proc
        _SizeEdgeDistance  ; proc
        _SizeEdgeSelected  ; proc
        _SizeRingEdges  ; proc
        _SizeOrientRings  ; proc
        _SizeCheck  ; proc
        _SizeRoundSegments  ; proc
        _SizeMiterLimit  ; proc
        _SizeCorner  ; proc
        _SizeDirs  ; proc
        _SizeDirP  ; proc

        ; stroke.il
        _StrokePolygon  ; proc
        _StrokeBand  ; proc
        _StrokeCircle  ; proc
        _StrokeJoin  ; proc
        _StrokeCap  ; proc

        ; to_path.il
        _PolyMid  ; proc
        _PolyLineDist  ; proc
        _PolyToPathVerify  ; proc
        _PolyToPathRect  ; proc
        _PolyToPathOpenAt  ; proc
        _PolyToPathOpen  ; proc
        _PolyToPathRing  ; proc
        _InstallPolygonToPath  ; proc
    ))
)
unuseNamespace("ycGeom")

; END
