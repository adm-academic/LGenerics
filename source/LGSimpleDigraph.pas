{****************************************************************************
*                                                                           *
*   This file is part of the LGenerics package.                             *
*   Generic simple directed graph implementation.                           *
*                                                                           *
*   Copyright(c) 2018 A.Koverdyaev(avk)                                     *
*                                                                           *
*   This code is free software; you can redistribute it and/or modify it    *
*   under the terms of the Apache License, Version 2.0;                     *
*   You may obtain a copy of the License at                                 *
*     http://www.apache.org/licenses/LICENSE-2.0.                           *
*                                                                           *
*  Unless required by applicable law or agreed to in writing, software      *
*  distributed under the License is distributed on an "AS IS" BASIS,        *
*  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. *
*  See the License for the specific language governing permissions and      *
*  limitations under the License.                                           *
*                                                                           *
*****************************************************************************}
unit LGSimpleDigraph;

{$mode objfpc}{$H+}
{$INLINE ON}{$WARN 6058 off : }
{$MODESWITCH ADVANCEDRECORDS}

interface

uses
  Classes, SysUtils,
  LGUtils,
  {%H-}LGHelpers,
  LGQueue,
  LGVector,
  LGHashMap,
  LGCustomGraph,
  LGStrConst;

type
  TSortOrder = LGUtils.TSortOrder;

  { TGSimpleDiGraph implements simple sparse directed graph based on adjacency lists;

      functor TEqRel must provide:
        class function HashCode([const[ref]] aValue: TVertex): SizeInt;
        class function Equal([const[ref]] L, R: TVertex): Boolean; }
  generic TGSimpleDiGraph<TVertex, TEdgeData, TEqRel> = class(specialize TGCustomGraph<TVertex, TEdgeData, TEqRel>)
  protected
  type
    TReachabilityMatrix = record
    private
      FMatrix: TSquareBitMatrix;
      FIds: TIntArray;
      function  GetSize: SizeInt; inline;
      procedure Clear; inline;
    public
      constructor Create(constref aMatrix: TSquareBitMatrix; constref aIds: TIntArray);
      function  IsEmpty: Boolean; inline;
      function  Reachable(aSrc, aDst: SizeInt): Boolean; inline;
      property  Size: SizeInt read GetSize;
    end;

  protected
    FReachabilityMatrix: TReachabilityMatrix;
    function  GetReachabilityValid: Boolean; inline;
    function  GetDensity: Double; inline;
    procedure DoRemoveVertex(aIndex: SizeInt);
    function  DoAddEdge(aSrc, aDst: SizeInt; aData: TEdgeData): Boolean;
    function  DoRemoveEdge(aSrc, aDst: SizeInt): Boolean;
    function  CreateSkeleton: TSkeleton;
    procedure AssignGraph(aGraph: TGSimpleDiGraph);
    function  FindCycle(aRoot: SizeInt; out aCycle: TIntArray): Boolean;
    function  CycleExists: Boolean;
    function  TopoSort: TIntArray;
    function  GetDagLongestPaths(aSrc: SizeInt): TIntArray;
    function  GetDagLongestPaths(aSrc: SizeInt; out aTree: TIntArray): TIntArray;
    function  SearchForStrongComponents(out aIds: TIntArray): SizeInt;
    function  GetReachabilityMatrix(constref aScIds: TIntArray; aScCount: SizeInt): TReachabilityMatrix;
  public
{**********************************************************************************************************
  class management utilities
***********************************************************************************************************}

    procedure Clear; override;
    function  Clone: TGSimpleDiGraph;
    function  Reverse: TGSimpleDiGraph;
  { saves graph in its own binary format }
    procedure SaveToStream(aStream: TStream);
    procedure LoadFromStream(aStream: TStream);
    procedure SaveToFile(const aFileName: string);
    procedure LoadFromFile(const aFileName: string);

{**********************************************************************************************************
  structural management utilities
***********************************************************************************************************}

  { returns True and vertex index, if it was added, False otherwise }
    function  AddVertex(constref aVertex: TVertex; out aIndex: SizeInt): Boolean;
    function  AddVertex(constref aVertex: TVertex): Boolean; inline;
    procedure RemoveVertex(constref aVertex: TVertex); inline;
    procedure RemoveVertexI(aIndex: SizeInt);
  { returns True if the edge is added, False, if such an edge already exists }
    function  AddEdge(constref aSrc, aDst: TVertex; aData: TEdgeData): Boolean;
    function  AddEdge(constref aSrc, aDst: TVertex): Boolean; inline;
    function  AddEdgeI(aSrc, aDst: SizeInt; aData: TEdgeData): Boolean;
    function  AddEdgeI(aSrc, aDst: SizeInt): Boolean; inline;
    function  RemoveEdge(constref aSrc, aDst: TVertex): Boolean; inline;
    function  RemoveEdgeI(aSrc, aDst: SizeInt): Boolean;
    function  InDegree(constref aVertex: TVertex): SizeInt; inline;
    function  InDegreeI(aIndex: SizeInt): SizeInt;
    function  OutDegree(constref aVertex: TVertex): SizeInt; inline;
    function  OutDegreeI(aIndex: SizeInt): SizeInt;
    function  Degree(constref aVertex: TVertex): SizeInt; inline;
    function  DegreeI(aIndex: SizeInt): SizeInt;
    function  Isolated(constref aVertex: TVertex): Boolean; inline;
    function  IsolatedI(aIndex: SizeInt): Boolean; inline;
    function  IsSource(constref aVertex: TVertex): Boolean; inline;
    function  IsSourceI(aIndex: SizeInt): Boolean;
    function  IsSink(constref aVertex: TVertex): Boolean; inline;
    function  IsSinkI(aIndex: SizeInt): Boolean;
    function  SourceCount: SizeInt;
    function  SinkCount: SizeInt;
  { checks whether the aDst is reachable from the aSrc(each vertex is reachable from itself) }
    function  PathExists(constref aSrc, aDst: TVertex): Boolean; inline;
    function  PathExistsI(aSrc, aDst: SizeInt): Boolean;
  { checks whether exists any cycle in subgraph that reachable from a aRoot;
    if True then aCycle will contain indices of the vertices of the cycle }
    function  ContainsCycle(constref aRoot: TVertex; out aCycle: TIntArray): Boolean; inline;
    function  ContainsCycleI(aRoot: SizeInt; out aCycle: TIntArray): Boolean;
    function  ContainsEulerianCycle: Boolean;//todo: else from specified source
    function  FindEulerianCycle(out aCycle: TIntArray): Boolean;//todo: else from specified source
  { returns count of the strong connected components; the corresponding element of the
    aCompIds will contain its component index(used Gabow's algorithm) }
    function  FindStrongComponents(out aCompIds: TIntArray): SizeInt;
  { creates internal reachability matrix }
    procedure FillReachabilityMatrix;
  { creates internal reachability matrix using pre-calculated results of FindStrongComponents }
    procedure FillReachabilityMatrix(constref aScIds: TIntArray; aScCount: SizeInt);
  { returns True, radus and diameter, if graph is strongly connected, False otherwise }
    function  GetRadiusDiameter(out aRadius, aDiameter: SizeInt): Boolean;
  { returns True and indices of the central vertices in aCenter,
    if graph is strongly connected, False otherwise }
    function  FindCenter(out aCenter: TIntArray): Boolean;
  { returns True and indices of the inner central vertices in aCenter,
    if graph is strongly connected, False otherwise }
    function  FindInnerCenter(out aCenter: TIntArray): Boolean;
{**********************************************************************************************************
  DAG utilities
***********************************************************************************************************}

  { returns array of vertex indices in topological order, without any acyclic checks }
    function  TopologicalSort(aOrder: TSortOrder = soAsc): TIntArray;
    function  IsDag: Boolean;
  { for an acyclic graph returns an array containing in the corresponding components the length of
    the longest path from aSrc to it (in sense 'edges count'), or -1 if it is unreachable from aSrc }
    function  DagLongestPathsMap(constref aSrc: TVertex): TIntArray; inline;
    function  DagLongestPathsMapI(aSrc: SizeInt): TIntArray;
  { same as above and in aPathTree returns paths }
    function  DagLongestPathsMap(constref aSrc: TVertex; out aPathTree: TIntArray): TIntArray; inline;
    function  DagLongestPathsMapI(aSrc: SizeInt; out aPathTree: TIntArray): TIntArray;
  { for an acyclic graph returns an array containing in the corresponding components the length of
    the longest path starting with it(in sense 'edges count') }
    function  DagLongesPaths: TIntArray;

{**********************************************************************************************************
  properties
***********************************************************************************************************}

    property  ReachabilityValid: Boolean read GetReachabilityValid;
    property  Density: Double read GetDensity;
  end;

  { TGFlowChart: simple outline;
      functor TEqRel must provide:
        class function HashCode([const[ref]] aValue: TVertex): SizeInt;
        class function Equal([const[ref]] L, R: TVertex): Boolean; }
  generic TGFlowChart<TVertex, TEqRel> = class(specialize TGSimpleDiGraph<TVertex, TEmptyRec, TEqRel>)
  private
    procedure ReadData(aStream: TStream; out aValue: TEmptyRec);
    procedure WriteData(aStream: TStream; constref aValue: TEmptyRec);
  public
    constructor Create;
    function Clone: TGFlowChart;
    function Reverse: TGFlowChart;
  end;

  generic TGDigraphDotWriter<TVertex, TEdgeData, TEqRel> = class(
    specialize TGCustomDotWriter<TVertex, TEdgeData, TEqRel>)
  protected
    function Graph2Dot(aGraph: TGraph): utf8string; override;
  public
    constructor Create;
  end;

  TIntFlowChart = class(specialize TGFlowChart<Integer, Integer>)
  protected
    procedure WriteVertex(aStream: TStream; constref aValue: Integer);
    procedure ReadVertex(aStream: TStream; out aValue: Integer);
  public
    constructor Create;
    function Clone: TIntFlowChart;
    function Reverse: TIntFlowChart;
  end;

  TIntFlowChartDotWriter = class(specialize TGDigraphDotWriter<Integer, TEmptyRec, Integer>)
  protected
    function DefaultWriteEdge(aGraph: TGraph; constref aEdge: TGraph.TEdge): utf8string; override;
  end;

  { TStrFlowChart
    warning: SaveToStream limitation for max string length = High(SmallInt) }
  TStrFlowChart = class(specialize TGFlowChart<string, string>)
  protected
    procedure WriteVertex(aStream: TStream; constref aValue: string);
    procedure ReadVertex(aStream: TStream; out aValue: string);
  public
    constructor Create;
    function Clone: TStrFlowChart;
    function Reverse: TStrFlowChart;
  end;

  TStrFlowChartDotWriter = class(specialize TGDigraphDotWriter<string, TEmptyRec, string>)
  protected
    function DefaultWriteEdge(aGraph: TGraph; constref aEdge: TGraph.TEdge): utf8string; override;
  end;

  { TGWeightedDiGraph implements simple sparse directed weighted graph based on adjacency lists;

      functor TEqRel must provide:
        class function HashCode([const[ref]] aValue: TVertex): SizeInt;
        class function Equal([const[ref]] L, R: TVertex): Boolean;

      TEdgeData must provide field/property/function Weight: TWeight;

      TWeight must be one of predefined signed numeric types;
      properties MinValue, MaxValue used as infinity weight values }
  generic TGWeightedDiGraph<TVertex, TWeight, TEdgeData, TEqRel> = class(
     specialize TGSimpleDiGraph<TVertex, TEdgeData, TEqRel>)
  protected
  type
    TWeightHelper = specialize TGWeightHelper<TVertex, TWeight, TEdgeData, TEqRel>;

  public
  type
    TWeightItem   = TWeightHelper.TWeightItem;
    TWeightArray  = TWeightHelper.TWeightArray;
    TEstimate     = TWeightHelper.TEstimate;
    TWeightEdge   = TWeightHelper.TWeightEdge;
    TEdgeArray    = array of TWeightEdge;
    TWeightMatrix = TWeightHelper.TWeightsMatrix;
    TApspCell     = TWeightHelper.TApspCell;
    TApspMatrix   = TWeightHelper.TApspMatrix;

  protected
    function CreateEdgeArray: TEdgeArray;
    function GetDagMaxPaths(aSrc: SizeInt): TWeightArray;
    function GetDagMaxPaths(aSrc: SizeInt; out aTree: TIntArray): TWeightArray;
  public
{**********************************************************************************************************
  auxiliary utilities
***********************************************************************************************************}

    class function wMin(L, R: TWeight): TWeight; static; inline;
    class function wMax(L, R: TWeight): TWeight; static; inline;
    class function InfWeight: TWeight; static; inline;
    class function NegInfWeight: TWeight; static; inline;
  { returns True if exists arc with negative weight }
    function ContainsNegWeightEdge: Boolean;
  { checks whether exists any negative weight cycle in subgraph that reachable from a aRoot;
    if True then aCycle will contain indices of the vertices of the cycle }
    function ContainsNegCycle(constref aRoot: TVertex; out aCycle: TIntArray): Boolean; inline;
    function ContainsNegCycleI(aRootIdx: SizeInt; out aCycle: TIntArray): Boolean;
{**********************************************************************************************************
  class management utilities
***********************************************************************************************************}
    function Clone: TGWeightedDiGraph;
    function Reverse: TGWeightedDiGraph;
{**********************************************************************************************************
  shortest path problem utilities
***********************************************************************************************************}

  { finds all paths of minimal weight from a given vertex to the remaining vertices in the same
    connected component(SSSP), the weights of all edges must be nonnegative;
    the result contains in the corresponding component the weight of the path to the vertex or
    InfWeight if the vertex is unreachable; used Dijkstra's algorithm  }
    function MinPathsMap(constref aSrc: TVertex): TWeightArray; inline;
    function MinPathsMapI(aSrc: SizeInt): TWeightArray;
  { same as above and in aPathTree returns paths }
    function MinPathsMap(constref aSrc: TVertex; out aPathTree: TIntArray): TWeightArray; inline;
    function MinPathsMapI(aSrc: SizeInt; out aPathTree: TIntArray): TWeightArray;
  { finds the path of minimal weight from a aSrc to aDst if it exists(pathfinding);
    the weights of all edges must be nonnegative;
    returns path weight or InfWeight if the vertex is unreachable; used Dijkstra's algorithm  }
    function MinPathWeight(constref aSrc, aDst: TVertex): TWeight; inline;
    function MinPathWeightI(aSrc, aDst: SizeInt): TWeight;
  { returns the vertex path of minimal weight from a aSrc to aDst, if exists, and its weight in aWeight }
    function MinPath(constref aSrc, aDst: TVertex; out aWeight: TWeight): TIntArray; inline;
    function MinPathI(aSrc, aDst: SizeInt; out aWeight: TWeight): TIntArray;
  { finds the path of minimal weight from a aSrc to aDst if it exists;
    the weights of all edges must be nonnegative; used A* algorithm if aEst <> nil }
    function MinPathAStar(constref aSrc, aDst: TVertex; out aWeight: TWeight; aEst: TEstimate): TIntArray; inline;
    function MinPathAStarI(aSrc, aDst: SizeInt; out aWeight: TWeight; aEst: TEstimate): TIntArray;
  { returns False if exists negative weighted cycle, otherwise returns the vertex path
    of minimal weight from a aSrc to aDst in aPath, if exists, and its weight in aWeight;
    to distinguish 'unreachable' and 'negative cycle': in case negative cycle aWeight returns ZeroWeight,
    but InfWeight if aDst unreachable; used BFMT algorithm }
    function FindMinPath(constref aSrc, aDst: TVertex; out aPath: TIntArray; out aWeight: TWeight): Boolean; inline;
    function FindMinPathI(aSrc, aDst: SizeInt; out aPath: TIntArray; out aWeight: TWeight): Boolean;
  { finds all paths of minimal weight from a given vertex to the remaining vertices in the same
    connected component(SSSP), the weights of the edges can be negative;
    returns False and empty aWeights if there is a negative weight cycle, otherwise
    aWeights will contain in the corresponding component the weight of the minimum path to the vertex or
    InfWeight if the vertex is unreachable; used BFMT algorithm  }
    function FindMinPathsMap(constref aSrc: TVertex; out aWeights: TWeightArray): Boolean; inline;
    function FindMinPathsMapI(aSrc: SizeInt; out aWeights: TWeightArray): Boolean;
  { same as above and in aPaths returns paths,
    if there is a negative weight cycle, then aPaths will contain that cycle }
    function FindMinPathsMap(constref aSrc: TVertex; out aPaths: TIntArray; out aWeights: TWeightArray): Boolean; inline;
    function FindMinPathsMapI(aSrc: SizeInt; out aPaths: TIntArray; out aWeights: TWeightArray): Boolean;
  { creates a matrix of weights of arcs }
    function CreateWeightsMatrix: TWeightMatrix; inline;
  { returns True and the shortest paths between all pairs of vertices in matrix aPaths
    if non empty and no negative weight cycles exist,
    otherwise returns False and if negative weight cycle exists then in single cell of aPaths
    returns index of the vertex from which this cycle is reachable }
    function FindAllPairMinPaths(out aPaths: TApspMatrix): Boolean;
    function ExtractMinPath(constref aSrc, aDst: TVertex; constref aPaths: TApspMatrix): TIntArray; inline;
    function ExtractMinPathI(aSrc, aDst: SizeInt; constref aPaths: TApspMatrix): TIntArray;
  { returns False if is empty or exists negative weight cycle reachable from aVertex,
    otherwise returns True and the weighted eccentricity of the aVertex in aValue }
    function FindEccentricity(constref aVertex: TVertex; out aValue: TWeight): Boolean; inline;
    function FindEccentricityI(aIndex: SizeInt; out aValue: TWeight): Boolean;
  { returns False if is not strongly connected or exists negative weight cycle,
    otherwise returns True and weighted radus and diameter of the graph }
    function FindRadiusDiameter(out aRadius, aDiameter: TWeight): Boolean;
  { returns False if is not strongly connected or exists negative weight cycle,
    otherwise returns True and indices of the central vertices in aCenter }
    function FindWeightedCenter(out aCenter: TIntArray): Boolean;
  { returns False if is not strongly connected or exists negative weight cycle,
    otherwise returns True and indices of the inner central vertices in aCenter }
    function FindInnerWeightedCenter(out aCenter: TIntArray): Boolean;
{**********************************************************************************************************
  DAG utilities
***********************************************************************************************************}

  { for an acyclic graph returns an array containing in the corresponding components the maximal weight of
    the path from aSrc to it, or NegInfWeight if it is unreachable from aSrc }
    function DagMaxPathsMap(constref aSrc: TVertex): TWeightArray; inline;
    function DagMaxPathsMapI(aSrc: SizeInt): TWeightArray;
  { same as above and in aPathTree returns paths }
    function DagMaxPathsMap(constref aSrc: TVertex; out aPathTree: TIntArray): TWeightArray; inline;
    function DagMaxPathsMapI(aSrc: SizeInt; out aPathTree: TIntArray): TWeightArray;
  { for an acyclic graph returns an array containing in the corresponding components the maximal weight of
    the path starting with it }
    function DagMaxPaths: TWeightArray;
  end;

  { TGIntWeightDiGraph specializes TWeight with Int64 }
  generic TGIntWeightDiGraph<TVertex, TEdgeData, TEqRel> = class(
     specialize TGWeightedDiGraph<TVertex, Int64, TEdgeData, TEqRel>)
  public
  type
    TWeight = Int64;

  protected
  const
    MAX_WEIGHT = High(Int64);
    MIN_WEIGHT = Low(Int64);

    {$I IntDiGraphHelpH.inc}

     function IsCostsCorrect(constref aCosts: TCostEdgeArray; out aMap: TEdgeCostMap): Boolean;
  public
{**********************************************************************************************************
  class management utilities
***********************************************************************************************************}

    function Clone: TGIntWeightDiGraph;
    function Reverse: TGIntWeightDiGraph;
{**********************************************************************************************************
  matching utilities
***********************************************************************************************************}

  { returns False if graph is not bipartite, otherwise in aMatch returns the matching of
    the maximum cardinality and minimum weight }
    function FindBipartiteMinWeightMatching(out aMatch: TEdgeArray): Boolean;
  { returns False if graph is not bipartite, otherwise in aMatch returns the matching of
    the maximum cardinality and maximum weight }
    function FindBipartiteMaxWeightMatching(out aMatch: TEdgeArray): Boolean;
{**********************************************************************************************************
  networks utilities treat the weight of the arc as its capacity
***********************************************************************************************************}
  type
    TNetworkState = (nsOk, nsTrivial, nsInvalidSource, nsInvalidSink, nsNegCapacity, nsSinkUnreachable);

    function GetNetworkState(constref aSource, aSink: TVertex): TNetworkState; inline;
    function GetNetworkStateI(aSrcIndex, aSinkIndex: SizeInt): TNetworkState;
  { returns state of the network with aSource as source and aSink as sink;
    returns maximum flow through the network in aFlow, if result = nsOk, 0 otherwise;
    used PR algorithm }
    function FindMaxFlowPr(constref aSource, aSink: TVertex; out aFlow: TWeight): TNetworkState; inline;
    function FindMaxFlowPrI(aSrcIndex, aSinkIndex: SizeInt; out aFlow: TWeight): TNetworkState;
  { returns state of network with aSource as source and aSink as sink;
    returns maximum flow through the network in aFlow and flows through the arcs
    in array a, if result = nsOk, 0 and nil otherwise; used PR algorithm }
    function FindMaxFlowPr(constref aSource, aSink: TVertex; out aFlow: TWeight; out a: TEdgeArray): TNetworkState;
             inline;
    function FindMaxFlowPrI(aSrcIndex, aSinkIndex: SizeInt; out aFlow: TWeight; out a: TEdgeArray): TNetworkState;
  { returns state of the network with aSource as source and aSink as sink;
    returns maximum flow through the network in aFlow, if result = nsOk, 0 otherwise;
    used Dinitz's algorithm }
    function FindMaxFlowD(constref aSource, aSink: TVertex; out aFlow: TWeight): TNetworkState; inline;
    function FindMaxFlowDI(aSrcIndex, aSinkIndex: SizeInt; out aFlow: TWeight): TNetworkState;
  { returns state of network with aSource as source and aSink as sink;
    returns maximum flow through the network in aFlow and flows through the arcs
    in array a, if result = nsOk, 0 and nil otherwise; used Dinitz's algorithm }
    function FindMaxFlowD(constref aSource, aSink: TVertex; out aFlow: TWeight; out a: TEdgeArray): TNetworkState;
             inline;
    function FindMaxFlowDI(aSrcIndex, aSinkIndex: SizeInt; out aFlow: TWeight; out a: TEdgeArray): TNetworkState;
  {  }
    function IsFeasibleFlow(constref aSource, aSink: TVertex; constref a: TEdgeArray): Boolean;
    function IsFeasibleFlowI(aSrcIndex, aSinkIndex: SizeInt; constref a: TEdgeArray): Boolean;

  type
    //s-t vertex partition
    TStCut = record
      S,
      T: TIntArray;
    end;

  { returns state of the network with aSource as source and aSink as sink;
    returns value of the minimum cut in aValue and vertex partition in aCut,
    if result = nsOk, otherwise 0 and empty partition; used PR algorithm }
    function FindMinSTCutPr(constref aSource, aSink: TVertex; out aValue: TWeight; out aCut: TStCut): TNetworkState;
    function FindMinSTCutPrI(aSrcIndex, aSinkIndex: SizeInt; out aValue: TWeight; out aCut: TStCut): TNetworkState;
  { returns state of the network with aSource as source and aSink as sink;
    returns value of the minimum cut in aValue and vertex partition in aCut,
    if result = nsOk, otherwise 0 and empty partition; used Dinitz's algorithm }
    function FindMinSTCutD(constref aSource, aSink: TVertex; out aValue: TWeight; out aCut: TStCut): TNetworkState;
    function FindMinSTCutDI(aSrcIndex, aSinkIndex: SizeInt; out aValue: TWeight; out aCut: TStCut): TNetworkState;
  { negative costs allows; returns True if arc cost function defined correctly
    (except negative cycles), False otherwise }
    function IsProperCosts(constref aCosts: TCostEdgeArray): Boolean;
  { param aReqFlow specifies the required flow > 0 (can be MAX_WEIGHT);
    returns False if network is not correct or arc costs are not correct or network
    contains negative cycle or aNeedFlow < 1,
    otherwise returns True, flow = min(aReqFlow, maxflow) in aReqFlow and
    total flow cost in aTotalCost }
    function FindMinCostFlowSsp(constref aSource, aSink: TVertex; constref aCosts: TCostEdgeArray;
                             var aReqFlow: TWeight; out aTotalCost: TCost): Boolean; inline;
    function FindMinCostFlowSspI(aSrcIndex, aSinkIndex: SizeInt; constref aCosts: TCostEdgeArray;
                              var aReqFlow: TWeight; out aTotalCost: TCost): Boolean;
  { same as above and in addition returns flows through the arcs in array a }
    function FindMinCostFlowSsp(constref aSource, aSink: TVertex; constref aCosts: TCostEdgeArray;
                             var aReqFlow: TWeight; out aTotalCost: TCost; out a: TEdgeArray): Boolean; inline;
    function FindMinCostFlowSspI(aSrcIndex, aSinkIndex: SizeInt; constref aCosts: TCostEdgeArray;
                              var aReqFlow: TWeight; out aTotalCost: TCost; out aArcFlows: TEdgeArray): Boolean;
  { param aReqFlow specifies the required flow > 0 (can be MAX_WEIGHT);
    returns False if network is not correct or arc costs are not correct or network
    contains negative cycle or aNeedFlow < 1,
    otherwise returns True, flow = min(aReqFlow, maxflow) in aReqFlow and
    total flow cost in aTotalCost; used cost scaling algorithm }
    function FindMinCostFlowCs(constref aSource, aSink: TVertex; constref aCosts: TCostEdgeArray;
                             var aReqFlow: TWeight; out aTotalCost: TCost): Boolean; inline;
    function FindMinCostFlowCsI(aSrcIndex, aSinkIndex: SizeInt; constref aCosts: TCostEdgeArray;
                              var aReqFlow: TWeight; out aTotalCost: TCost): Boolean;
  { same as above and in addition returns flows through the arcs in array a }
    function FindMinCostFlowCs(constref aSource, aSink: TVertex; constref aCosts: TCostEdgeArray;
                             var aReqFlow: TWeight; out aTotalCost: TCost; out a: TEdgeArray): Boolean; inline;
    function FindMinCostFlowCsI(aSrcIndex, aSinkIndex: SizeInt; constref aCosts: TCostEdgeArray;
                                var aReqFlow: TWeight; out aTotalCost: TCost; out aArcFlows: TEdgeArray): Boolean;
  end;

implementation
{$B-}{$COPERATORS ON}
uses
  bufstream;

{ TGSimpleDiGraph.TReachabilityMatrix }

function TGSimpleDiGraph.TReachabilityMatrix.GetSize: SizeInt;
begin
  Result := FMatrix.Size;
end;

procedure TGSimpleDiGraph.TReachabilityMatrix.Clear;
begin
  if FMatrix.Size > 0 then
    begin
      FMatrix.Clear;
      FIds := nil;
    end;
end;

constructor TGSimpleDiGraph.TReachabilityMatrix.Create(constref aMatrix: TSquareBitMatrix; constref aIds: TIntArray);
begin
  FMatrix := aMatrix;
  FIds := aIds;
end;

function TGSimpleDiGraph.TReachabilityMatrix.IsEmpty: Boolean;
begin
  Result := FMatrix.Size = 0;
end;

function TGSimpleDiGraph.TReachabilityMatrix.Reachable(aSrc, aDst: SizeInt): Boolean;
begin
  Result := FMatrix[FIds[aSrc], FIds[aDst]];
end;

{ TGSimpleDiGraph }

function TGSimpleDiGraph.GetDensity: Double;
begin
  if NonEmpty then
    Result := Double(EdgeCount)/(Double(VertexCount) * Double(Pred(VertexCount)))
  else
    Result := 0.0;
end;

function TGSimpleDiGraph.GetReachabilityValid: Boolean;
begin
  Result := NonEmpty and not FReachabilityMatrix.IsEmpty;
end;

procedure TGSimpleDiGraph.DoRemoveVertex(aIndex: SizeInt);
var
  I, J: SizeInt;
  p: ^TAdjItem;
  CurrEdges: TAdjList.TAdjItemArray;
begin
  FEdgeCount -= FNodeList[aIndex].AdjList.Count;
  for p in FNodeList[aIndex].AdjList do
    Dec(FNodeList[p^.Destination].Tag);
  Delete(aIndex);
  for I := 0 to Pred(VertexCount) do
    begin
      CurrEdges := FNodeList[I].AdjList.ToArray;
      FNodeList[I].AdjList.MakeEmpty;
      for J := 0 to System.High(CurrEdges) do
        begin
          if CurrEdges[J].Destination <> aIndex then
            begin
              if CurrEdges[J].Destination > aIndex then
                Dec(CurrEdges[J].Destination);
              FNodeList[I].AdjList.Add(CurrEdges[J]);
            end;
        end;
    end;
  FReachabilityMatrix.Clear;
end;

function TGSimpleDiGraph.DoAddEdge(aSrc, aDst: SizeInt; aData: TEdgeData): Boolean;
begin
  if aSrc = aDst then
    exit(False);
  Result := FNodeList[aSrc].AdjList.Add(TAdjItem.Create(aDst, aData));
  if Result then
    begin
      Inc(FNodeList[aDst].Tag);
      Inc(FEdgeCount);
      FReachabilityMatrix.Clear;
    end;
end;

function TGSimpleDiGraph.DoRemoveEdge(aSrc, aDst: SizeInt): Boolean;
begin
  if aSrc = aDst then
    exit(False);
  Result := FNodeList[aSrc].AdjList.Remove(aDst);
  if Result then
    begin
      Dec(FNodeList[aDst].Tag);
      Dec(FEdgeCount);
      FReachabilityMatrix.Clear;
    end;
end;

function TGSimpleDiGraph.CreateSkeleton: TSkeleton;
var
  I: SizeInt;
begin
  Result := TSkeleton.Create(VertexCount, True);
  Result.FEdgeCount := EdgeCount;
  for I := 0 to Pred(VertexCount) do
    Result[I]^.AssignList(AdjLists[I]);
end;

procedure TGSimpleDiGraph.AssignGraph(aGraph: TGSimpleDiGraph);
var
  I: SizeInt;
begin
  Clear;
  FCount := aGraph.VertexCount;
  FEdgeCount := aGraph.EdgeCount;
  FTitle := aGraph.Title;
  FDescription.Assign(aGraph.FDescription);
  if aGraph.NonEmpty then
    begin
      FChainList := System.Copy(aGraph.FChainList);
      System.SetLength(FNodeList, System.Length(aGraph.FNodeList));
      for I := 0 to Pred(VertexCount) do
        FNodeList[I].Assign(aGraph.FNodeList[I]);
    end;
  if not aGraph.FReachabilityMatrix.IsEmpty then
    begin
      FReachabilityMatrix.FMatrix.FSize := aGraph.FReachabilityMatrix.FMatrix.FSize;
      FReachabilityMatrix.FMatrix.FBits := System.Copy(aGraph.FReachabilityMatrix.FMatrix.FBits);
      FReachabilityMatrix.FIds := System.Copy(aGraph.FReachabilityMatrix.FIds);
    end;
end;

function TGSimpleDiGraph.FindCycle(aRoot: SizeInt; out aCycle: TIntArray): Boolean;
var
  Stack: TSimpleStack;
  AdjEnums: TAdjEnumArray;
  InStack: TBitVector;
  PreOrd, Parents: TIntArray;
  Counter, Next: SizeInt;
begin
  AdjEnums := CreateAdjEnumArray;
  Stack := TSimpleStack.Create(VertexCount);
  PreOrd := CreateIntArray;
  Parents := CreateIntArray;
  InStack.Size := VertexCount;
  PreOrd[aRoot] := 0;
  Counter := 1;
  Stack.Push(aRoot);
  while Stack.TryPeek(aRoot) do
    if AdjEnums[aRoot].MoveNext then
      begin
        Next := AdjEnums[aRoot].Current;
        if PreOrd[Next] = -1 then
          begin
            Parents[Next] := aRoot;
            PreOrd[Next] := Counter;
            InStack[Next] := True;
            Inc(Counter);
            Stack.Push(Next);
          end
        else
          if (PreOrd[aRoot] >= PreOrd[Next]) and InStack[Next] then
            begin
              aCycle := TreePathFromTo(Parents, Next, aRoot);
              exit(True);
            end;
      end
    else
      InStack[Stack.Pop{%H-}] := False;
  Result := False;
end;

function TGSimpleDiGraph.CycleExists: Boolean;
var
  Stack: TSimpleStack;
  AdjEnums: TAdjEnumArray;
  InStack: TBitVector;
  PreOrd: TIntArray;
  Counter, I, Curr, Next: SizeInt;
begin
  AdjEnums := CreateAdjEnumArray;
  Stack := TSimpleStack.Create(VertexCount);
  PreOrd := CreateIntArray;
  InStack.Size := VertexCount;
  Counter := 0;
  for I := 0 to Pred(VertexCount) do
    if PreOrd[I] = -1 then
      begin
        PreOrd[I] := Counter;
        Inc(Counter);
        Stack.Push(I);
        while Stack.TryPeek(Curr) do
          if AdjEnums[{%H-}Curr].MoveNext then
            begin
              Next := AdjEnums[Curr].Current;
              if PreOrd[Next] = -1 then
                begin
                  PreOrd[Next] := Counter;
                  InStack[Next] := True;
                  Inc(Counter);
                  Stack.Push(Next);
                end
              else
                if (PreOrd[Curr] >= PreOrd[Next]) and InStack[Next] then
                  exit(True);
            end
          else
            InStack[Stack.Pop{%H-}] := False;
      end;
  Result := False;
end;

function TGSimpleDiGraph.TopoSort: TIntArray;
var
  Stack: TSimpleStack;
  AdjEnums: TAdjEnumArray;
  Visited: TBitVector;
  Counter, I, Curr, Next: SizeInt;
begin
  AdjEnums := CreateAdjEnumArray;
  Stack := TSimpleStack.Create(VertexCount);
  Result := CreateIntArray;
  Visited.Size := VertexCount;
  Counter := Pred(VertexCount);
  for I := 0 to Pred(VertexCount) do
    if not Visited[I] then
      begin
        Visited[I] := True;
        Stack.Push(I);
        while Stack.TryPeek(Curr) do
          if AdjEnums[{%H-}Curr].MoveNext then
            begin
              Next := AdjEnums[Curr].Current;
              if not Visited[Next] then
                begin
                  Visited[Next] := True;
                  Stack.Push(Next);
                end;
            end
          else
            begin
              Result[Counter] := Stack.Pop;
              Dec(Counter);
            end;
      end;
end;

function TGSimpleDiGraph.GetDagLongestPaths(aSrc: SizeInt): TIntArray;
var
  Stack: TSimpleStack;
  AdjEnums: TAdjEnumArray;
  Visited: TBitVector;
  d, Curr, Next: SizeInt;
begin
  AdjEnums := CreateAdjEnumArray;
  Stack := TSimpleStack.Create(VertexCount);
  Result := CreateIntArray;
  Visited.Size := VertexCount;
  Visited[aSrc] := True;
  Result[aSrc] := 0;
  Stack.Push(aSrc);
  while Stack.TryPeek(Curr) do
    if AdjEnums[{%H-}Curr].MoveNext then
      begin
        Next := AdjEnums[Curr].Current;
        if not Visited[Next] then
          begin
            Visited[Next] := True;
            d := Succ(Result[Curr]);
            if d > Result[Next] then
              Result[Next] := d;
            Stack.Push(Next);
          end;
      end
    else
      Stack.Pop;
end;

function TGSimpleDiGraph.GetDagLongestPaths(aSrc: SizeInt; out aTree: TIntArray): TIntArray;
var
  Stack: TSimpleStack;
  AdjEnums: TAdjEnumArray;
  Visited: TBitVector;
  d, Curr, Next: SizeInt;
begin
  AdjEnums := CreateAdjEnumArray;
  Stack := TSimpleStack.Create(VertexCount);
  Result := CreateIntArray;
  aTree := CreateIntArray;
  Visited.Size := VertexCount;
  Visited[aSrc] := True;
  Result[aSrc] := 0;
  {%H-}Stack.Push(aSrc);
  while Stack.TryPeek(Curr) do
    if AdjEnums[{%H-}Curr].MoveNext then
      begin
        Next := AdjEnums[Curr].Current;
        if not Visited[Next] then
          begin
            Visited[Next] := True;
            d := Succ(Result[Curr]);
            if d > Result[Next] then
              begin
                Result[Next] := d;
                aTree[Next] := Curr;
              end;
            Stack.Push(Next);
          end;
      end
    else
      Stack.Pop;
end;

function TGSimpleDiGraph.SearchForStrongComponents(out aIds: TIntArray): SizeInt;
var
  Stack, VtxStack, PathStack: TSimpleStack;
  AdjEnums: TAdjEnumArray;
  PreOrd: TIntArray;
  I, Counter, Curr, Next: SizeInt;
begin
  Stack := TSimpleStack.Create(VertexCount);
  VtxStack := TSimpleStack.Create(VertexCount);
  PathStack := TSimpleStack.Create(VertexCount);
  PreOrd := CreateIntArray;
  aIds := CreateIntArray;
  AdjEnums := CreateAdjEnumArray;
  Counter := 0;
  Result := 0;
  for I := 0 to Pred(VertexCount) do
    if PreOrd[I] = -1 then
      begin
        PreOrd[I] := Counter;
        Inc(Counter);
        Stack.Push(I);
        VtxStack.Push(I);
        PathStack.Push(I);
        while Stack.TryPeek(Curr) do
          if AdjEnums[{%H-}Curr].MoveNext then
            begin
              Next := AdjEnums[Curr].Current;
              if PreOrd[Next] = -1 then
                begin
                  PreOrd[Next] := Counter;
                  Inc(Counter);
                  Stack.Push(Next);
                  VtxStack.Push(Next);
                  PathStack.Push(Next);
                end
              else
                if aIds[Next] = -1 then
                  while PreOrd[PathStack.Peek] > PreOrd[Next] do
                    PathStack.Pop;
            end
          else
            begin
              Curr := Stack.Pop;
              if PathStack.Peek = Curr then
                begin
                  PathStack.Pop;
                  repeat
                    Next := VtxStack.Pop;
                    aIds[Next] := Result;
                  until Next = Curr;
                  Inc(Result);
                end;
            end;
      end;
end;

function TGSimpleDiGraph.GetReachabilityMatrix(constref aScIds: TIntArray; aScCount: SizeInt): TReachabilityMatrix;
var
  Stack: TSimpleStack;
  Visited, IdVisited: TBitVector;
  IdParents, IdOrd: TIntArray;
  m: TSquareBitMatrix;
  Pairs: TIntPairSet;
  AdjEnums: TAdjEnumArray;
  I, J, Counter, Curr, Next, CurrId, NextId: SizeInt;
begin
  Stack := TSimpleStack.Create(VertexCount);
  IdParents := CreateIntArray(aScCount, -1);
  IdOrd := CreateIntArray(aScCount, -1);
  Visited.Size := VertexCount;
  IdVisited.Size := aScCount;
  AdjEnums := CreateAdjEnumArray;
  Counter := 0;
  m := TSquareBitMatrix.Create(aScCount);
  for I := 0 to Pred(VertexCount) do
    if not Visited[I] then
      begin
        Visited[I] := True;
        Stack.Push(I);
        if IdOrd[aScIds[I]] = -1 then
          begin
            IdOrd[aScIds[I]] := Counter;
            Inc(Counter);
          end;
        while Stack.TryPeek(Curr) do
          begin
            CurrId := aScIds[{%H-}Curr];
            if AdjEnums[{%H-}Curr].MoveNext then
              begin
                Next := AdjEnums[Curr].Current;
                NextId := aScIds[Next];
                m[CurrId, NextId] := True;
                if IdOrd[CurrId] < IdOrd[NextId] then
                  continue;
                if not Visited[Next] then
                  begin
                    Visited[Next] := True;
                    Stack.Push(Next);
                    if IdOrd[NextId] = -1 then
                      begin
                        IdOrd[NextId] := Counter;
                        IdParents[NextId] := CurrId;
                        Inc(Counter);
                      end
                  end
                    else
                      if Pairs.Add(IdOrd[CurrId], IdOrd[NextId]) then
                        for J := 0 to Pred(aScCount) do
                          if m[NextId, J] then
                            m[CurrId, J] := True;
              end
            else
              begin
                Next := aScIds[Stack.Pop];
                if not IdVisited[Next] then
                  begin
                    IdVisited[Next] := True;
                    Curr := IdParents[Next];
                    if Curr <> -1 then
                      for J := 0 to Pred(aScCount) do
                        if m[Next, J] then
                          m[Curr, J] := True;
                  end;
              end;
          end;
      end;
  Result := TReachabilityMatrix.Create(m, aScIds);
end;

procedure TGSimpleDiGraph.Clear;
begin
  inherited;
  FReachabilityMatrix.Clear;
end;

function TGSimpleDiGraph.Clone: TGSimpleDiGraph;
var
  I: SizeInt;
begin
  Result := TGSimpleDiGraph.Create;
  Result.FCount := VertexCount;
  Result.FEdgeCount := EdgeCount;
  Result.FTitle := Title;
  if NonEmpty then
    begin
      Result.FChainList := System.Copy(FChainList);
      System.SetLength(Result.FNodeList, System.Length(FNodeList));
      for I := 0 to Pred(VertexCount) do
        Result.FNodeList[I].Assign(FNodeList[I]);
    end;
end;

function TGSimpleDiGraph.Reverse: TGSimpleDiGraph;
var
  e: TEdge;
  v: TVertex;
begin
  Result := TGSimpleDiGraph.Create;
  for v in Vertices do
    Result.AddVertex(v);
  for e in Edges do
    Result.AddEdgeI(e.Destination, e.Source, e.Data);
end;

procedure TGSimpleDiGraph.SaveToStream(aStream: TStream);
var
  Header: TStreamHeader;
  s, d: Integer;
  Edge: TEdge;
  gTitle, Descr: utf8string;
  wbs: TWriteBufStream;
begin
  if not Assigned(OnStreamWriteVertex) then
    raise EGraphError.Create(SEStreamWriteVertMissed);
  if not Assigned(OnStreamWriteData) then
    raise EGraphError.Create(SEStreamWriteDataMissed);
{$IFDEF CPU64}
  if VertexCount > System.High(Integer) then
    raise EGraphError.CreateFmt(SEStreamSizeExceedFmt, [VertexCount]);
{$ENDIF CPU64}
  wbs := TWriteBufStream.Create(aStream);
  try
    //write header
    Header.Magic := GRAPH_MAGIC;
    Header.Version := GRAPH_HEADER_VERSION;
    gTitle := Title;
    Header.TitleLen := System.Length(gTitle);
    Descr := Description.Text;
    Header.DescriptionLen := System.Length(Descr);
    Header.VertexCount := VertexCount;
    Header.EdgeCount := EdgeCount;
    wbs.WriteBuffer(Header, SizeOf(Header));
    //write title
    if Header.TitleLen > 0 then
      wbs.WriteBuffer(Pointer(gTitle)^, Header.TitleLen);
    //write description
    if Header.DescriptionLen > 0 then
      wbs.WriteBuffer(Pointer(Descr)^, Header.DescriptionLen);
    //write Items, but does not save any info about connected
    //this should allow transfer data between directed/undirected graphs ???
    for s := 0 to Pred(Header.VertexCount) do
      OnStreamWriteVertex(wbs, FNodeList[s].Vertex);
    //write edges
    for Edge in Edges do
      begin
        s := Edge.Source;
        d := Edge.Destination;
        wbs.WriteBuffer(NtoLE(s), SizeOf(s));
        wbs.WriteBuffer(NtoLE(d), SizeOf(d));
        OnStreamWriteData(wbs, Edge.Data);
      end;
  finally
    wbs.Free;
  end;
end;

procedure TGSimpleDiGraph.LoadFromStream(aStream: TStream);
var
  Header: TStreamHeader;
  s, d: Integer;
  I, Ind: SizeInt;
  Data: TEdgeData;
  Vertex: TVertex;
  gTitle, Descr: utf8string;
  rbs: TReadBufStream;
begin
  if not Assigned(OnStreamReadVertex) then
    raise EGraphError.Create(SEStreamReadVertMissed);
  if not Assigned(OnStreamReadData) then
    raise EGraphError.Create(SEStreamReadDataMissed);
  rbs := TReadBufStream.Create(aStream);
  try
    //read header
    rbs.ReadBuffer(Header, SizeOf(Header));
    if Header.Magic <> GRAPH_MAGIC then
      raise EGraphError.Create(SEUnknownGraphStreamFmt);
    if Header.Version > GRAPH_HEADER_VERSION then
      raise EGraphError.Create(SEUnsuppGraphFmtVersion);
    Clear;
    EnsureCapacity(Header.VertexCount);
    //read title
    if Header.TitleLen > 0 then
      begin
        System.SetLength(gTitle, Header.TitleLen);
        rbs.ReadBuffer(Pointer(gTitle)^, Header.TitleLen);
        FTitle := gTitle;
      end;
    //read description
    if Header.DescriptionLen > 0 then
      begin
        System.SetLength(Descr, Header.DescriptionLen);
        rbs.ReadBuffer(Pointer(Descr)^, Header.DescriptionLen);
        Description.Text := Descr;
      end;
    //read Items
    for I := 0 to Pred(Header.VertexCount) do
      begin
        OnStreamReadVertex(rbs, Vertex);
        if not AddVertex(Vertex, Ind) then
          raise EGraphError.Create(SEGraphStreamCorrupt);
        if Ind <> I then
          raise EGraphError.Create(SEGraphStreamReadIntern);
      end;
    //read edges
    Data := Default(TEdgeData);
    for I := 0 to Pred(Header.EdgeCount) do
      begin
        rbs.ReadBuffer(s, SizeOf(s));
        rbs.ReadBuffer(d, SizeOf(d));
        OnStreamReadData(rbs, Data);
        AddEdgeI(LEToN(s), LEToN(d), Data);
      end;
  finally
    rbs.Free;
  end;
end;

procedure TGSimpleDiGraph.SaveToFile(const aFileName: string);
var
  fs: TStream;
begin
  fs := TFileStream.Create(aFileName, fmCreate);
  try
    SaveToStream(fs);
  finally
    fs.Free;
  end;
end;

procedure TGSimpleDiGraph.LoadFromFile(const aFileName: string);
var
  fs: TStream;
begin
  fs := TFileStream.Create(aFileName, fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(fs);
  finally
    fs.Free;
  end;
end;

function TGSimpleDiGraph.AddVertex(constref aVertex: TVertex; out aIndex: SizeInt): Boolean;
begin
  Result := not FindOrAdd(aVertex, aIndex);
  if Result then
    begin
      FNodeList[aIndex].Tag := 0;
      FReachabilityMatrix.Clear;
    end;
end;

function TGSimpleDiGraph.AddVertex(constref aVertex: TVertex): Boolean;
var
  Dummy: SizeInt;
begin
  Result := AddVertex(aVertex, Dummy);
end;

procedure TGSimpleDiGraph.RemoveVertex(constref aVertex: TVertex);
begin
  RemoveVertexI(IndexOf(aVertex));
end;

procedure TGSimpleDiGraph.RemoveVertexI(aIndex: SizeInt);
begin
  CheckIndexRange(aIndex);
  DoRemoveVertex(aIndex);
end;

function TGSimpleDiGraph.AddEdge(constref aSrc, aDst: TVertex; aData: TEdgeData): Boolean;
var
  SrcIdx, DstIdx: SizeInt;
begin
  AddVertex(aSrc, SrcIdx);
  AddVertex(aDst, DstIdx);
  Result := DoAddEdge(SrcIdx, DstIdx, aData);
end;

function TGSimpleDiGraph.AddEdge(constref aSrc, aDst: TVertex): Boolean;
begin
  Result := AddEdge(aSrc, aDst, Default(TEdgeData));
end;

function TGSimpleDiGraph.AddEdgeI(aSrc, aDst: SizeInt; aData: TEdgeData): Boolean;
begin
  CheckIndexRange(aSrc);
  CheckIndexRange(aDst);
  Result := DoAddEdge(aSrc, aDst, aData);
end;

function TGSimpleDiGraph.AddEdgeI(aSrc, aDst: SizeInt): Boolean;
begin
  Result := AddEdgeI(aSrc, aDst, Default(TEdgeData));
end;

function TGSimpleDiGraph.RemoveEdge(constref aSrc, aDst: TVertex): Boolean;
begin
  Result := RemoveEdgeI(IndexOf(aSrc), IndexOf(aDst));
end;

function TGSimpleDiGraph.RemoveEdgeI(aSrc, aDst: SizeInt): Boolean;
begin
  CheckIndexRange(aSrc);
  CheckIndexRange(aDst);
  Result := DoRemoveEdge(aSrc, aDst);
end;

function TGSimpleDiGraph.InDegree(constref aVertex: TVertex): SizeInt;
begin
  Result := InDegreeI(IndexOf(aVertex));
end;

function TGSimpleDiGraph.InDegreeI(aIndex: SizeInt): SizeInt;
begin
  CheckIndexRange(aIndex);
  Result := FNodeList[aIndex].Tag;
end;

function TGSimpleDiGraph.OutDegree(constref aVertex: TVertex): SizeInt;
begin
  Result := OutDegreeI(IndexOf(aVertex));
end;

function TGSimpleDiGraph.OutDegreeI(aIndex: SizeInt): SizeInt;
begin
  CheckIndexRange(aIndex);
  Result := FNodeList[aIndex].AdjList.Count;
end;

function TGSimpleDiGraph.Degree(constref aVertex: TVertex): SizeInt;
begin
  Result := DegreeI(IndexOf(aVertex));
end;

function TGSimpleDiGraph.DegreeI(aIndex: SizeInt): SizeInt;
begin
  CheckIndexRange(aIndex);
  Result := FNodeList[aIndex].AdjList.Count + FNodeList[aIndex].Tag;
end;

function TGSimpleDiGraph.Isolated(constref aVertex: TVertex): Boolean;
begin
  Result := Degree(aVertex) = 0;
end;

function TGSimpleDiGraph.IsolatedI(aIndex: SizeInt): Boolean;
begin
  Result := DegreeI(aIndex) = 0;
end;

function TGSimpleDiGraph.IsSource(constref aVertex: TVertex): Boolean;
begin
  Result := IsSourceI(IndexOf(aVertex));
end;

function TGSimpleDiGraph.IsSourceI(aIndex: SizeInt): Boolean;
begin
  CheckIndexRange(aIndex);
  Result := (FNodeList[aIndex].AdjList.Count <> 0) and (FNodeList[aIndex].Tag = 0);
end;

function TGSimpleDiGraph.IsSink(constref aVertex: TVertex): Boolean;
begin
  Result := IsSinkI(IndexOf(aVertex));
end;

function TGSimpleDiGraph.IsSinkI(aIndex: SizeInt): Boolean;
begin
  CheckIndexRange(aIndex);
  Result := (FNodeList[aIndex].AdjList.Count = 0) and (FNodeList[aIndex].Tag <> 0);
end;

function TGSimpleDiGraph.SourceCount: SizeInt;
var
  I: SizeInt;
begin
  Result := 0;
  for I := 0 to Pred(VertexCount) do
    if (FNodeList[I].AdjList.Count <> 0) and (FNodeList[I].Tag = 0) then
      Inc(Result);
end;

function TGSimpleDiGraph.SinkCount: SizeInt;
var
  I: SizeInt;
begin
  Result := 0;
  for I := 0 to Pred(VertexCount) do
    if (FNodeList[I].AdjList.Count = 0) and (FNodeList[I].Tag <> 0) then
      Inc(Result);
end;

function TGSimpleDiGraph.PathExists(constref aSrc, aDst: TVertex): Boolean;
begin
  Result := PathExistsI(IndexOf(aSrc), IndexOf(aDst));
end;

function TGSimpleDiGraph.PathExistsI(aSrc, aDst: SizeInt): Boolean;
begin
  CheckIndexRange(aSrc);
  CheckIndexRange(aDst);
  if aSrc = aDst then
    exit(True);
  if ReachabilityValid then
    exit(FReachabilityMatrix.Reachable(aSrc, aDst));
  Result := CheckPathExists(aSrc, aDst);
end;

function TGSimpleDiGraph.ContainsCycle(constref aRoot: TVertex; out aCycle: TIntArray): Boolean;
begin
  Result := ContainsCycleI(IndexOf(aRoot), aCycle);
end;

function TGSimpleDiGraph.ContainsCycleI(aRoot: SizeInt; out aCycle: TIntArray): Boolean;
begin
  CheckIndexRange(aRoot);
  if VertexCount < 2 then
    exit(False);
  aCycle := nil;
  FindCycle(aRoot, aCycle);
  Result := System.Length(aCycle) <> 0;
end;

function TGSimpleDiGraph.ContainsEulerianCycle: Boolean;
var
  I, d: SizeInt;
begin
  if VertexCount < 2 then
    exit(False);
  d := 0;
  for I := 0 to Pred(VertexCount) do
    begin
      if InDegreeI(I) <> OutDegreeI(I) then
        exit(False);
      d += DegreeI(I);
    end;
  Result := d > 0;
end;

function TGSimpleDiGraph.FindEulerianCycle(out aCycle: TIntArray): Boolean;
var
  g: TSkeleton;
  Stack, Path: TIntStack;
  s, d: SizeInt;
begin
  aCycle := nil;
  if not ContainsEulerianCycle then
    exit(False);
  g := CreateSkeleton;
  s := 0;
  while g.Degree[s] = 0 do
    Inc(s);
  {%H-}Stack.Push(s);
  while Stack.TryPeek(s) do
    if g[s]^.FindFirst(d) then
      begin
        g.RemoveEdge(s, d);
        Stack.Push(d);
      end
    else
      {%H-}Path.Push(Stack.Pop{%H-});
  System.SetLength(aCycle, Path.Count);
  d := 0;
  for s in Path.Reverse do
    begin
      aCycle[d] := s;
      Inc(d);
    end;
  Result := True;
end;

function TGSimpleDiGraph.FindStrongComponents(out aCompIds: TIntArray): SizeInt;
begin
  if IsEmpty then
    exit(0);
  if VertexCount = 1 then
    begin
      aCompIds := [0];
      exit(1);
    end;
  if ReachabilityValid then
    begin
      aCompIds := System.Copy(FReachabilityMatrix.FIds);
      exit(FReachabilityMatrix.Size);
    end;
  Result := SearchForStrongComponents(aCompIds);
end;

procedure TGSimpleDiGraph.FillReachabilityMatrix;
var
  Ids: TIntArray;
  ScCount: SizeInt;
begin
  if IsEmpty or ReachabilityValid then
    exit;
  ScCount := SearchForStrongComponents(Ids);
  FillReachabilityMatrix(Ids, ScCount);
end;

procedure TGSimpleDiGraph.FillReachabilityMatrix(constref aScIds: TIntArray; aScCount: SizeInt);
var
  m: TSquareBitMatrix;
begin
  if aScCount = 1 then
    begin
      m := TSquareBitMatrix.Create(aScCount);
      m[0, 0] := True;
      FReachabilityMatrix := TReachabilityMatrix.Create(m, aScIds);
      exit;
    end;
  FReachabilityMatrix := GetReachabilityMatrix(aScIds, aScCount);
end;

function TGSimpleDiGraph.GetRadiusDiameter(out aRadius, aDiameter: SizeInt): Boolean;
var
  Queue, Dist: TIntArray;
  VertCount, I, Ecc, J, d, qHead, qTail: SizeInt;
  p: PAdjItem;
begin
  if IsEmpty then
    exit(False);
  I := FindStrongComponents(Dist);
  if I > 1 then
    exit(False);
  VertCount := VertexCount;
  aRadius := VertCount;
  aDiameter := 0;
  Queue.Length := VertCount;
  Dist.Length := VertCount;
  for I := 0 to Pred(VertCount) do
    begin
      System.FillChar(Pointer(Dist)^, VertCount * SizeOf(SizeInt), $ff);
      Dist[I] := 0;
      Ecc := 0;
      qHead := 0;
      qTail := 0;
      Queue[qTail] := I;
      Inc(qTail);
      while qHead < qTail do
        begin
          J := Queue[qHead];
          Inc(qHead);
          for p in AdjLists[J]^ do
            if Dist[p^.Key] = NULL_INDEX then
              begin
                Queue[qTail] := p^.Key;
                Inc(qTail);
                d := Succ(Dist[J]);
                Dist[p^.Key] := d;
                if Ecc < d then
                  Ecc := d;
              end;
        end;
      if Ecc < aRadius then
        aRadius := Ecc;
      if Ecc > aDiameter then
        aDiameter := Ecc;
    end;
  Result := True;
end;

function TGSimpleDiGraph.FindCenter(out aCenter: TIntArray): Boolean;
var
  Queue, Dist, Eccs: TIntArray;
  VertCount, Radius, I, Ecc, J, d, qHead, qTail: SizeInt;
  p: PAdjItem;
begin
  if IsEmpty then
    exit(False);
  I := FindStrongComponents(Dist);
  if I > 1 then
    exit(False);
  VertCount := VertexCount;
  Radius := VertCount;
  Queue.Length := VertCount;
  Dist.Length := VertCount;
  Eccs.Length := VertCount;
  for I := 0 to Pred(VertCount) do
    begin
      System.FillChar(Pointer(Dist)^, VertCount * SizeOf(SizeInt), $ff);
      Dist[I] := 0;
      Ecc := 0;
      qHead := 0;
      qTail := 0;
      Queue[qTail] := I;
      Inc(qTail);
      while qHead < qTail do
        begin
          J := Queue[qHead];
          Inc(qHead);
          for p in AdjLists[J]^ do
            if Dist[p^.Key] = NULL_INDEX then
              begin
                Queue[qTail] := p^.Key;
                Inc(qTail);
                d := Succ(Dist[J]);
                Dist[p^.Key] := d;
                if Ecc < d then
                  Ecc := d;
              end;
        end;
      Eccs[I] := Ecc;
      if Ecc < Radius then
        Radius := Ecc;
    end;
  aCenter.Length := VertCount;
  J := 0;
  for I := 0 to Pred(VertCount) do
    if Eccs[I] = Radius then
      begin
        aCenter[J] := I;
        Inc(J);
      end;
  aCenter.Length := J;
  Result := True;
end;

function TGSimpleDiGraph.FindInnerCenter(out aCenter: TIntArray): Boolean;
var
  Queue, Dist, Eccs: TIntArray;
  VertCount, Radius, I, Ecc, J, d, qHead, qTail: SizeInt;
  p: PAdjItem;
begin
  if IsEmpty then
    exit(False);
  I := FindStrongComponents(Dist);
  if I > 1 then
    exit(False);
  VertCount := VertexCount;
  Radius := VertCount;
  Queue.Length := VertCount;
  Dist.Length := VertCount;
  Eccs := CreateIntArray(0);
  for I := 0 to Pred(VertCount) do
    begin
      System.FillChar(Pointer(Dist)^, VertCount * SizeOf(SizeInt), $ff);
      Dist[I] := 0;
      Ecc := 0;
      qHead := 0;
      qTail := 0;
      Queue[qTail] := I;
      Inc(qTail);
      while qHead < qTail do
        begin
          J := Queue[qHead];
          Inc(qHead);
          for p in AdjLists[J]^ do
            if Dist[p^.Key] = NULL_INDEX then
              begin
                Queue[qTail] := p^.Key;
                Inc(qTail);
                d := Succ(Dist[J]);
                Dist[p^.Key] := d;
                if Ecc < d then
                  Ecc := d;
                if Dist[p^.Key] > Eccs[p^.Key] then
                  Eccs[p^.Key] := Dist[p^.Key];
              end;
        end;
      if Ecc < Radius then
        Radius := Ecc;
    end;
  aCenter.Length := VertCount;
  J := 0;
  for I := 0 to Pred(VertCount) do
    if Eccs[I] = Radius then
      begin
        aCenter[J] := I;
        Inc(J);
      end;
  aCenter.Length := J;
  Result := True;
end;

function TGSimpleDiGraph.TopologicalSort(aOrder: TSortOrder): TIntArray;
begin
  if IsEmpty then
    exit(nil);
  Result := TopoSort;
  if aOrder = soDesc then
    TIntHelper.Reverse(Result);
end;

function TGSimpleDiGraph.IsDag: Boolean;
begin
  if IsEmpty then
    exit(False);
  if VertexCount = 1 then
    exit(True);
  Result := not CycleExists;
end;

function TGSimpleDiGraph.DagLongestPathsMap(constref aSrc: TVertex): TIntArray;
begin
  Result := DagLongestPathsMapI(IndexOf(aSrc));
end;

function TGSimpleDiGraph.DagLongestPathsMapI(aSrc: SizeInt): TIntArray;
begin
  CheckIndexRange(aSrc);
  Result := GetDagLongestPaths(aSrc);
end;

function TGSimpleDiGraph.DagLongestPathsMap(constref aSrc: TVertex; out aPathTree: TIntArray): TIntArray;
begin
  Result := DagLongestPathsMapI(IndexOf(aSrc), aPathTree);
end;

function TGSimpleDiGraph.DagLongestPathsMapI(aSrc: SizeInt; out aPathTree: TIntArray): TIntArray;
begin
  CheckIndexRange(aSrc);
  Result := GetDagLongestPaths(aSrc, aPathTree);
end;

function TGSimpleDiGraph.DagLongesPaths: TIntArray;
var
  TopoOrd: TIntArray;
  I, J, d: SizeInt;
begin
  TopoOrd := TopologicalSort(soDesc);
  Result := CreateIntArray(0);
  for I := 1 to Pred(VertexCount) do
    for J := 0 to Pred(I) do
      if AdjacentI(TopoOrd[I], TopoOrd[J]) then
        begin
          d := Succ(Result[TopoOrd[J]]);
          if d > Result[TopoOrd[I]] then
            Result[TopoOrd[I]] := d;
        end;
end;

{ TGFlowChart }

procedure TGFlowChart.ReadData(aStream: TStream; out aValue: TEmptyRec);
begin
  aStream.ReadBuffer(aValue{%H-}, SizeOf(aValue));
end;

procedure TGFlowChart.WriteData(aStream: TStream; constref aValue: TEmptyRec);
begin
  aStream.WriteBuffer(aValue, SizeOf(aValue));
end;

constructor TGFlowChart.Create;
begin
  inherited;
  OnStreamReadData := @ReadData;
  OnStreamWriteData := @WriteData;
end;

function TGFlowChart.Clone: TGFlowChart;
begin
  Result := TGFlowChart.Create;
  Result.AssignGraph(Self);
end;

function TGFlowChart.Reverse: TGFlowChart;
begin
  Result := inherited Reverse as TGFlowChart;
end;

{ TGDigraphDotWriter }

function TGDigraphDotWriter.Graph2Dot(aGraph: TGraph): utf8string;
var
  s: utf8string;
  I: SizeInt;
  e: TGraph.TEdge;
begin
  if aGraph.Title <> '' then
    s := '"' + aGraph.Title + '"'
  else
    s := 'Untitled';
  with TStringList.Create do
    try
      SkipLastLineBreak := True;
      WriteBOM := False;
      DefaultEncoding := TEncoding.UTF8;
      Add(FGraphMark + s + ' {');
      Add(DIRECTS[Direction]);
      if Assigned(OnStartWrite) then
        begin
          s := OnStartWrite(aGraph);
          Add(s);
        end;
      if Assigned(OnWriteVertex) then
        for I := 0 to Pred(aGraph.VertexCount) do
          begin
            s := OnWriteVertex(aGraph, I);
            Add(s);
          end;
        for e in aGraph.Edges do
          begin
            if Assigned(OnWriteEdge) then
              s := OnWriteEdge(aGraph, e)
            else
              s := DefaultWriteEdge(aGraph, e);
            Add(s);
          end;
      Add('}');
      Result := Text;
    finally
      Free;
    end;
end;

constructor TGDigraphDotWriter.Create;
begin
  FGraphMark := 'digraph ';
  FEdgeMark := '->';
end;

{ TIntFlowChart }

procedure TIntFlowChart.WriteVertex(aStream: TStream; constref aValue: Integer);
begin
  aStream.WriteBuffer(NtoLE(aValue), SizeOf(aValue));
end;

procedure TIntFlowChart.ReadVertex(aStream: TStream; out aValue: Integer);
begin
  aStream.ReadBuffer(aValue{%H-}, SizeOf(aValue));
  aValue := LEtoN(aValue);
end;

constructor TIntFlowChart.Create;
begin
  inherited;
  OnStreamReadVertex := @ReadVertex;
  OnStreamWriteVertex := @WriteVertex;
end;

function TIntFlowChart.Clone: TIntFlowChart;
begin
  Result := TIntFlowChart.Create;
  Result.AssignGraph(Self);
end;

function TIntFlowChart.Reverse: TIntFlowChart;
begin
  Result := inherited Reverse as TIntFlowChart;
end;

{ TIntFlowChartDotWriter }

function TIntFlowChartDotWriter.DefaultWriteEdge(aGraph: TGraph; constref aEdge: TGraph.TEdge): utf8string;
begin
  Result := IntToStr(aGraph[aEdge.Source]) + FEdgeMark + IntToStr(aGraph[aEdge.Destination]) + ';';
end;

{ TStrFlowChart }

procedure TStrFlowChart.WriteVertex(aStream: TStream; constref aValue: string);
var
  Len: SizeInt;
  sLen: SmallInt;
begin
  Len := System.Length(aValue);
  if Len > High(SmallInt) then
    raise EGraphError.CreateFmt(SEStrLenExceedFmt, [Len]);
  sLen := Len;
  aStream.WriteBuffer(sLen, SizeOf(sLen));
  aStream.WriteBuffer(Pointer(aValue)^, Len);
end;

procedure TStrFlowChart.ReadVertex(aStream: TStream; out aValue: string);
var
  Len: SmallInt;
begin
  aStream.ReadBuffer(Len{%H-}, SizeOf(Len));
  System.SetLength(aValue, Len);
  aStream.ReadBuffer(Pointer(aValue)^, Len);
end;

constructor TStrFlowChart.Create;
begin
  inherited;
  OnStreamReadVertex := @ReadVertex;
  OnStreamWriteVertex := @WriteVertex;
end;

function TStrFlowChart.Clone: TStrFlowChart;
begin
  Result := TStrFlowChart.Create;
  Result.AssignGraph(Self);
end;

function TStrFlowChart.Reverse: TStrFlowChart;
begin
  Result := inherited Reverse as TStrFlowChart;
end;

{ TStrFlowChartDotWriter }

function TStrFlowChartDotWriter.DefaultWriteEdge(aGraph: TGraph; constref aEdge: TGraph.TEdge): utf8string;
begin
  Result := '"' + aGraph[aEdge.Source] + '"' + FEdgeMark + '"' + aGraph[aEdge.Destination] + '";';
end;

{ TGWeightedDiGraph }

function TGWeightedDiGraph.CreateEdgeArray: TEdgeArray;
var
  I: SizeInt = 0;
  e: TEdge;
begin
  System.SetLength(Result, EdgeCount);
  for e in Edges do
    begin
      Result[I] := TWeightEdge.Create(e.Source, e.Destination, e.Data.Weight);
      Inc(I);
    end;
end;

function TGWeightedDiGraph.GetDagMaxPaths(aSrc: SizeInt): TWeightArray;
var
  Stack: TSimpleStack;
  AdjEnums: TAdjEnumArray;
  Visited: TBitVector;
  Curr, Next: SizeInt;
  w: TWeight;
begin
  AdjEnums := CreateAdjEnumArray;
  Stack := TSimpleStack.Create(VertexCount);
  Result := TWeightHelper.CreateWeightArrayNI(VertexCount);
  Visited.Size := VertexCount;
  Visited[aSrc] := True;
  Result[aSrc] := 0;
  Stack.Push(aSrc);
  while Stack.TryPeek(Curr) do
    if AdjEnums[{%H-}Curr].MoveNext then
      begin
        Next := AdjEnums[Curr].Current;
        if not Visited[Next] then
          begin
            Visited[Next] := True;
            Stack.Push(Next);
          end;
        w := Result[Curr] + GetEdgeDataPtr(Curr, Next)^.Weight;
        if w > Result[Next] then
          Result[Next] := w;
      end
    else
      Stack.Pop;
end;

function TGWeightedDiGraph.GetDagMaxPaths(aSrc: SizeInt; out aTree: TIntArray): TWeightArray;
var
  Stack: TSimpleStack;
  AdjEnums: TAdjEnumArray;
  Visited: TBitVector;
  Curr, Next: SizeInt;
  w: TWeight;
begin
  AdjEnums := CreateAdjEnumArray;
  Stack := TSimpleStack.Create(VertexCount);
  Result := TWeightHelper.CreateWeightArrayNI(VertexCount);
  aTree := CreateIntArray;
  Visited.Size := VertexCount;
  Visited[aSrc] := True;
  Result[aSrc] := 0;
  {%H-}Stack.Push(aSrc);
  while Stack.TryPeek(Curr) do
    if AdjEnums[{%H-}Curr].MoveNext then
      begin
        Next := AdjEnums[Curr].Current;
        if not Visited[Next] then
          begin
            Visited[Next] := True;
            Stack.Push(Next);
          end;
        w := Result[Curr] + GetEdgeDataPtr(Curr, Next)^.Weight;
        if w > Result[Next] then
          begin
            Result[Next] := w;
            aTree[Next] := Curr;
          end;
      end
    else
      Stack.Pop;
end;

class function TGWeightedDiGraph.wMin(L, R: TWeight): TWeight;
begin
  if L <= R then
    Result := L
  else
    Result := R;
end;

class function TGWeightedDiGraph.wMax(L, R: TWeight): TWeight;
begin
  if L >= R then
    Result := L
  else
    Result := R;
end;

class function TGWeightedDiGraph.InfWeight: TWeight;
begin
  Result :=  TWeightHelper.InfWeight;
end;

class function TGWeightedDiGraph.NegInfWeight: TWeight;
begin
  Result := TWeightHelper.NegInfWeight;
end;

function TGWeightedDiGraph.ContainsNegWeightEdge: Boolean;
var
  e: TEdge;
begin
  for e in Edges do
    if e.Data.Weight < 0 then
      exit(True);
  Result := False;
end;

function TGWeightedDiGraph.ContainsNegCycle(constref aRoot: TVertex; out aCycle: TIntArray): Boolean;
begin
  Result := ContainsNegCycleI(IndexOf(aRoot), aCycle);
end;

function TGWeightedDiGraph.ContainsNegCycleI(aRootIdx: SizeInt; out aCycle: TIntArray): Boolean;
begin
  CheckIndexRange(aRootIdx);
  aCycle := TWeightHelper.NegCycleDetect(Self, aRootIdx);
  Result := aCycle <> nil;
end;

function TGWeightedDiGraph.Clone: TGWeightedDiGraph;
begin
  Result := inherited Clone as TGWeightedDiGraph;
end;

function TGWeightedDiGraph.Reverse: TGWeightedDiGraph;
begin
  Result := inherited Reverse as TGWeightedDiGraph;
end;

function TGWeightedDiGraph.MinPathsMap(constref aSrc: TVertex): TWeightArray;
begin
  Result := MinPathsMapI(IndexOf(aSrc));
end;

function TGWeightedDiGraph.MinPathsMapI(aSrc: SizeInt): TWeightArray;
begin
  CheckIndexRange(aSrc);
  Result := TWeightHelper.DijkstraSssp(Self, aSrc);
end;

function TGWeightedDiGraph.MinPathsMap(constref aSrc: TVertex; out aPathTree: TIntArray): TWeightArray;
begin
  Result := MinPathsMapI(IndexOf(aSrc), aPathTree);
end;

function TGWeightedDiGraph.MinPathsMapI(aSrc: SizeInt; out aPathTree: TIntArray): TWeightArray;
begin
  CheckIndexRange(aSrc);
  Result := TWeightHelper.DijkstraSssp(Self, aSrc, aPathTree);
end;

function TGWeightedDiGraph.MinPathWeight(constref aSrc, aDst: TVertex): TWeight;
begin
  Result := MinPathWeightI(IndexOf(aSrc), IndexOf(aDst));
end;

function TGWeightedDiGraph.MinPathWeightI(aSrc, aDst: SizeInt): TWeight;
begin
  CheckIndexRange(aSrc);
  CheckIndexRange(aDst);
  Result := TWeightHelper.DijkstraPath(Self, aSrc, aDst);
end;

function TGWeightedDiGraph.MinPath(constref aSrc, aDst: TVertex; out aWeight: TWeight): TIntArray;
begin
  Result := MinPathI(IndexOf(aSrc), IndexOf(aDst), aWeight);
end;

function TGWeightedDiGraph.MinPathI(aSrc, aDst: SizeInt; out aWeight: TWeight): TIntArray;
begin
  CheckIndexRange(aSrc);
  CheckIndexRange(aDst);
  Result := TWeightHelper.DijkstraPath(Self, aSrc, aDst, aWeight);
end;

function TGWeightedDiGraph.MinPathAStar(constref aSrc, aDst: TVertex; out aWeight: TWeight;
  aEst: TEstimate): TIntArray;
begin
  Result := MinPathAStarI(IndexOf(aSrc), IndexOf(aDst), aWeight, aEst);
end;

function TGWeightedDiGraph.MinPathAStarI(aSrc, aDst: SizeInt; out aWeight: TWeight; aEst: TEstimate): TIntArray;
begin
  CheckIndexRange(aSrc);
  CheckIndexRange(aDst);
  if aEst <> nil then
    Result := TWeightHelper.AStar(Self, aSrc, aDst, aWeight, aEst)
  else
    Result := TWeightHelper.DijkstraPath(Self, aSrc, aDst, aWeight);
end;

function TGWeightedDiGraph.FindMinPath(constref aSrc, aDst: TVertex; out aPath: TIntArray;
  out aWeight: TWeight): Boolean;
begin
  Result := FindMinPathI(IndexOf(aSrc), IndexOf(aDst), aPath, aWeight);
end;

function TGWeightedDiGraph.FindMinPathI(aSrc, aDst: SizeInt; out aPath: TIntArray; out aWeight: TWeight): Boolean;
begin
  CheckIndexRange(aSrc);
  CheckIndexRange(aDst);
  Result := TWeightHelper.BfmtPath(Self, aSrc, aDst, aPath, aWeight);
end;

function TGWeightedDiGraph.FindMinPathsMap(constref aSrc: TVertex; out aWeights: TWeightArray): Boolean;
begin
  Result := FindMinPathsMapI(IndexOf(aSrc), aWeights);
end;

function TGWeightedDiGraph.FindMinPathsMapI(aSrc: SizeInt; out aWeights: TWeightArray): Boolean;
begin
  CheckIndexRange(aSrc);
  Result := TWeightHelper.BfmtSssp(Self, aSrc, aWeights);
end;

function TGWeightedDiGraph.FindMinPathsMap(constref aSrc: TVertex; out aPaths: TIntArray;
  out aWeights: TWeightArray): Boolean;
begin
  Result := FindMinPathsMapI(IndexOf(aSrc), aPaths, aWeights);
end;

function TGWeightedDiGraph.FindMinPathsMapI(aSrc: SizeInt; out aPaths: TIntArray;
  out aWeights: TWeightArray): Boolean;
begin
  CheckIndexRange(aSrc);
  Result := TWeightHelper.BfmtSssp(Self, aSrc, aPaths, aWeights);
end;

function TGWeightedDiGraph.CreateWeightsMatrix: TWeightMatrix;
begin
  Result := TWeightHelper.CreateWeightsMatrix(Self);
end;

function TGWeightedDiGraph.FindAllPairMinPaths(out aPaths: TApspMatrix): Boolean;
begin
  if IsEmpty then
    exit(False);
  if Density <= DENSE_CUTOFF then
    if Density <= JOHNSON_CUTOFF then
      Result := TWeightHelper.BfmtApsp(Self, True, aPaths)
    else
      Result := TWeightHelper.JohnsonApsp(Self, aPaths)
  else
    Result := TWeightHelper.FloydApsp(Self, aPaths);
end;

function TGWeightedDiGraph.ExtractMinPath(constref aSrc, aDst: TVertex; constref aPaths: TApspMatrix): TIntArray;
begin
  Result := ExtractMinPathI(IndexOf(aSrc), IndexOf(aDst), aPaths);
end;

function TGWeightedDiGraph.ExtractMinPathI(aSrc, aDst: SizeInt; constref aPaths: TApspMatrix): TIntArray;
begin
  CheckIndexRange(aSrc);
  CheckIndexRange(aDst);
  Result := TWeightHelper.ExtractMinPath(aSrc, aDst, aPaths);
end;

function TGWeightedDiGraph.FindEccentricity(constref aVertex: TVertex; out aValue: TWeight): Boolean;
begin
  Result := FindEccentricityI(IndexOf(aVertex), aValue);
end;

function TGWeightedDiGraph.FindEccentricityI(aIndex: SizeInt; out aValue: TWeight): Boolean;
var
  Weights: TWeightArray;
  I: SizeInt;
  w, Inf: TWeight;
begin
  if IsEmpty then
    exit(False);
  Result := FindMinPathsMapI(aIndex, Weights);
  if not Result then
    exit;
  Inf := InfWeight;
  aValue := 0;
  for I := 0 to System.High(Weights) do
    begin
      w := Weights[I];
      if (w <> Inf) and (w > aValue) then
        aValue := w;
    end;
end;

function TGWeightedDiGraph.FindRadiusDiameter(out aRadius, aDiameter: TWeight): Boolean;
var
  Bfmt: TWeightHelper.TBfmt;
  Weights: TWeightArray;
  Ids: TIntArray;
  I, J: SizeInt;
  Ecc, Inf, w: TWeight;
begin
  if IsEmpty then
    exit(False);
  I := FindStrongComponents(Ids);
  if I > 1 then
    exit(False);
  Ids := nil;
  Result := TWeightHelper.BfmtReweight(Self, Weights) < 0;
  if not Result then
    exit;
  Weights := nil;
  Bfmt := TWeightHelper.TBfmt.Create(Self, True);
  Inf := InfWeight;
  aRadius := Inf;
  aDiameter := 0;
  for I := 0 to Pred(VertexCount) do
    begin
      Bfmt.Sssp(I);
      Ecc := 0;
      with Bfmt do
        for J := 0 to Pred(VertexCount) do
          if I <> J then
            begin
              w := Nodes[J].Weight;
              if (w <> Inf) and (w > Ecc) then
                Ecc := w;
            end;
      if Ecc < aRadius then
        aRadius := Ecc;
      if Ecc > aDiameter then
        aDiameter := Ecc;
    end;
end;

function TGWeightedDiGraph.FindWeightedCenter(out aCenter: TIntArray): Boolean;
var
  Bfmt: TWeightHelper.TBfmt;
  Eccs: TWeightArray;
  Ids: TIntArray;
  I, J: SizeInt;
  Inf, Radius, Ecc, w: TWeight;
begin
  if IsEmpty then
    exit(False);
  I := FindStrongComponents(Ids);
  if I > 1 then
    exit(False);
  Ids := nil;
  Result := TWeightHelper.BfmtReweight(Self, Eccs) < 0;
  if not Result then
    exit;
  Bfmt := TWeightHelper.TBfmt.Create(Self, True);
  Inf := InfWeight;
  Radius := Inf;
  for I := 0 to Pred(VertexCount) do
    begin
      Bfmt.Sssp(I);
      Ecc := 0;
      with Bfmt do
        for J := 0 to Pred(VertexCount) do
          if I <> J then
            begin
              w := Nodes[J].Weight;
              if (w <> Inf) and (w > Ecc) then
                Ecc := w;
            end;
      Eccs[I] := Ecc;
      if Ecc < Radius then
        Radius := Ecc;
    end;
  aCenter.Length := VertexCount;
  J := 0;
  for I := 0 to Pred(VertexCount) do
    if Eccs[I] <= Radius then
      begin
        aCenter[J] := I;
        Inc(J);
      end;
  aCenter.Length := J;
end;

function TGWeightedDiGraph.FindInnerWeightedCenter(out aCenter: TIntArray): Boolean;
var
  Bfmt: TWeightHelper.TBfmt;
  Eccs: TWeightArray;
  Ids: TIntArray;
  I, J: SizeInt;
  Inf, Radius, Ecc, w: TWeight;
begin
  if IsEmpty then
    exit(False);
  I := FindStrongComponents(Ids);
  if I > 1 then
    exit(False);
  Ids := nil;
  Result := TWeightHelper.BfmtReweight(Self, Eccs) < 0;
  if not Result then
    exit;
  for I := 0 to Pred(VertexCount) do
    Eccs[I] := 0;
  Bfmt := TWeightHelper.TBfmt.Create(Self, True);
  Inf := InfWeight;
  Radius := Inf;
  for I := 0 to Pred(VertexCount) do
    begin
      Bfmt.Sssp(I);
      Ecc := 0;
      with Bfmt do
        for J := 0 to Pred(VertexCount) do
          if I <> J then
            begin
              w := Nodes[J].Weight;
              if (w <> Inf) and (w > Ecc) then
                Ecc := w;
              if w > Eccs[J] then
                Eccs[J] := w;
            end;
      if Ecc < Radius then
        Radius := Ecc;
    end;
  aCenter.Length := VertexCount;
  J := 0;
  for I := 0 to Pred(VertexCount) do
    if Eccs[I] <= Radius then
      begin
        aCenter[J] := I;
        Inc(J);
      end;
  aCenter.Length := J;
end;

function TGWeightedDiGraph.DagMaxPathsMap(constref aSrc: TVertex): TWeightArray;
begin
  Result := DagMaxPathsMapI(IndexOf(aSrc));
end;

function TGWeightedDiGraph.DagMaxPathsMapI(aSrc: SizeInt): TWeightArray;
begin
  CheckIndexRange(aSrc);
  Result := GetDagMaxPaths(aSrc);
end;

function TGWeightedDiGraph.DagMaxPathsMap(constref aSrc: TVertex; out aPathTree: TIntArray): TWeightArray;
begin
  Result := DagMaxPathsMapI(IndexOf(aSrc), aPathTree);
end;

function TGWeightedDiGraph.DagMaxPathsMapI(aSrc: SizeInt; out aPathTree: TIntArray): TWeightArray;
var
  I: SizeInt;
begin
  CheckIndexRange(aSrc);
  Result := GetDagMaxPaths(aSrc, aPathTree);
end;

function TGWeightedDiGraph.DagMaxPaths: TWeightArray;
var
  TopoOrd: TIntArray;
  I, J: SizeInt;
  w: TWeight;
begin
  TopoOrd := TopologicalSort(soDesc);
  Result := TWeightHelper.CreateWeightArrayZ(VertexCount);
  for I := 1 to Pred(VertexCount) do
    for J := 0 to Pred(I) do
      if AdjacentI(TopoOrd[I], TopoOrd[J]) then
        begin
          w := Result[TopoOrd[J]] + GetEdgeDataPtr(TopoOrd[I], TopoOrd[J])^.Weight;
          if w > Result[TopoOrd[I]] then
            Result[TopoOrd[I]] := w;
        end;
end;

{$I IntDiGraphHelp.inc}

{ TGIntWeightDiGraph }

function TGIntWeightDiGraph.IsCostsCorrect(constref aCosts: TCostEdgeArray; out aMap: TEdgeCostMap): Boolean;
var
  Arc: TCostEdge;
  vCount: SizeUInt;
begin
  aMap.Clear;
  if IsEmpty then
    exit(aCosts = nil);
  if System.Length(aCosts) <> EdgeCount then
    exit(False);
  vCount := SizeUInt(VertexCount);
  aMap.EnsureCapacity(EdgeCount);
  for Arc in aCosts do
    begin
      if (SizeUInt(Arc.Source) >= vCount) or (SizeUInt(Arc.Destination) >= vCount) then //invalid arc
        exit(False);
      if not AdjLists[Arc.Source]^.Contains(Arc.Destination) then //no such arc
        exit(False);
      if not aMap.Add(TIntEdge.Create(Arc.Source, Arc.Destination), Arc.Cost) then //contains duplicates
        exit(False);
    end;
  Result := True;
end;

function TGIntWeightDiGraph.Clone: TGIntWeightDiGraph;
begin
  Result := TGIntWeightDiGraph.Create;
  Result.AssignGraph(Self);
end;

function TGIntWeightDiGraph.Reverse: TGIntWeightDiGraph;
begin
  Result := inherited Reverse as TGIntWeightDiGraph;
end;

function TGIntWeightDiGraph.FindBipartiteMinWeightMatching(out aMatch: TEdgeArray): Boolean;
var
  w, g: TIntArray;
begin
  if not IsBipartite(w, g) then
    exit(False);
  aMatch := TWeightHelper.MinWeightMatchingB(Self, w, g);
  Result := True;
end;

function TGIntWeightDiGraph.FindBipartiteMaxWeightMatching(out aMatch: TEdgeArray): Boolean;
var
  w, g: TIntArray;
begin
  if not IsBipartite(w, g) then
    exit(False);
  aMatch := TWeightHelper.MaxWeightMatchingB(Self, w, g);
  Result := True;
end;

function TGIntWeightDiGraph.GetNetworkState(constref aSource, aSink: TVertex): TNetworkState;
begin
  Result := GetNetworkStateI(IndexOf(aSource), IndexOf(aSink));
end;

function TGIntWeightDiGraph.GetNetworkStateI(aSrcIndex, aSinkIndex: SizeInt): TNetworkState;
var
  Queue: TIntArray;
  Visited: TBitVector;
  Curr: SizeInt;
  p: PAdjItem;
  qHead: SizeInt = 0;
  qTail: SizeInt = 0;
  SinkFound: Boolean = False;
begin
  CheckIndexRange(aSrcIndex);
  CheckIndexRange(aSinkIndex);
  if VertexCount < 2 then
    exit(nsTrivial);
  if not IsSourceI(aSrcIndex) then
    exit(nsInvalidSource);
  if not IsSinkI(aSinkIndex) then
    exit(nsInvalidSink);
  Queue := CreateIntArray;
  Visited.Size := VertexCount;
  Visited[aSrcIndex] := True;
  Queue[qTail] := aSrcIndex;
  Inc(qTail);
  while qHead < qTail do
    begin
      Curr := Queue[qHead];
      Inc(qHead);
      for p in AdjLists[Curr]^ do
        begin
          if p^.Data.Weight < 0 then // network should not contains arcs with negative capacity
            exit(nsNegCapacity);
          if not Visited[p^.Destination] and (p^.Data.Weight > 0) then
            begin
              Queue[qTail] := p^.Destination;
              Inc(qTail);
              Visited[p^.Destination] := True;
              SinkFound := SinkFound or (p^.Destination = aSinkIndex);
            end;
        end;
    end;
  if not SinkFound then // sink should be reachable from the source
    exit(nsSinkUnreachable);
  Result := nsOk;
end;

function TGIntWeightDiGraph.FindMaxFlowPr(constref aSource, aSink: TVertex; out aFlow: TWeight): TNetworkState;
begin
  Result := FindMaxFlowPrI(IndexOf(aSource), IndexOf(aSink), aFlow);
end;

function TGIntWeightDiGraph.FindMaxFlowPrI(aSrcIndex, aSinkIndex: SizeInt; out aFlow: TWeight): TNetworkState;
var
  Helper: THPrHelper;
begin
  aFlow := 0;
  Result := GetNetworkStateI(aSrcIndex, aSinkIndex);
  if Result <> nsOk then
    exit;
  aFlow := Helper.GetMaxFlow(Self, aSrcIndex, aSinkIndex);
end;

function TGIntWeightDiGraph.FindMaxFlowPr(constref aSource, aSink: TVertex; out aFlow: TWeight;
  out a: TEdgeArray): TNetworkState;
begin
  Result := FindMaxFlowPrI(IndexOf(aSource), IndexOf(aSink), aFlow, a);
end;

function TGIntWeightDiGraph.FindMaxFlowPrI(aSrcIndex, aSinkIndex: SizeInt; out aFlow: TWeight;
  out a: TEdgeArray): TNetworkState;
var
  Helper: THPrHelper;
begin
  aFlow := 0;
  a := nil;
  Result := GetNetworkStateI(aSrcIndex, aSinkIndex);
  if Result <> nsOk then
    exit;
  aFlow := Helper.GetMaxFlow(Self, aSrcIndex, aSinkIndex, a);
end;

function TGIntWeightDiGraph.FindMaxFlowD(constref aSource, aSink: TVertex; out aFlow: TWeight): TNetworkState;
begin
  Result := FindMaxFlowDI(IndexOf(aSource), IndexOf(aSink), aFlow);
end;

function TGIntWeightDiGraph.FindMaxFlowDI(aSrcIndex, aSinkIndex: SizeInt; out aFlow: TWeight): TNetworkState;
var
  Helper: TDinitzHelper;
begin
  aFlow := 0;
  Result := GetNetworkStateI(aSrcIndex, aSinkIndex);
  if Result <> nsOk then
    exit;
  aFlow := Helper.GetMaxFlow(Self, aSrcIndex, aSinkIndex);
end;

function TGIntWeightDiGraph.FindMaxFlowD(constref aSource, aSink: TVertex; out aFlow: TWeight;
  out a: TEdgeArray): TNetworkState;
begin
  Result := FindMaxFlowDI(IndexOf(aSource), IndexOf(aSink), aFlow, a);
end;

function TGIntWeightDiGraph.FindMaxFlowDI(aSrcIndex, aSinkIndex: SizeInt; out aFlow: TWeight;
  out a: TEdgeArray): TNetworkState;
var
  Helper: TDinitzHelper;
begin
  aFlow := 0;
  a := nil;
  Result := GetNetworkStateI(aSrcIndex, aSinkIndex);
  if Result <> nsOk then
    exit;
  aFlow := Helper.GetMaxFlow(Self, aSrcIndex, aSinkIndex, a);
end;

function TGIntWeightDiGraph.IsFeasibleFlow(constref aSource, aSink: TVertex; constref a: TEdgeArray): Boolean;
begin
  Result := IsFeasibleFlowI(IndexOf(aSource), IndexOf(aSink), a);
end;

function TGIntWeightDiGraph.IsFeasibleFlowI(aSrcIndex, aSinkIndex: SizeInt; constref a: TEdgeArray): Boolean;
var
  v: array of TWeight;
  e: TWeightEdge;
  d: TEdgeData;
  I: SizeInt;
begin
  CheckIndexRange(aSrcIndex);
  CheckIndexRange(aSinkIndex);
  if System.Length(a) <> EdgeCount then
    exit(False);
  v := TWeightHelper.CreateWeightArrayZ(VertexCount);
  for e in a do
    begin
      if not GetEdgeDataI(e.Source, e.Destination, d) then
        exit(False);
      if e.Weight > d.Weight then
        exit(False);
      v[e.Source] -= e.Weight;
      v[e.Destination] += e.Weight;
    end;
  for I := 0 to System.High(v) do
    if (I <> aSrcIndex) and (I <> aSinkIndex) then
      if v[I] <> 0 then
        exit(False);
  Result := True;
end;

function TGIntWeightDiGraph.FindMinSTCutPr(constref aSource, aSink: TVertex; out aValue: TWeight;
  out aCut: TStCut): TNetworkState;
begin
  Result := FindMinSTCutPrI(IndexOf(aSource), IndexOf(aSink), aValue, aCut);
end;

function TGIntWeightDiGraph.FindMinSTCutPrI(aSrcIndex, aSinkIndex: SizeInt; out aValue: TWeight;
  out aCut: TStCut): TNetworkState;
var
  Helper: THPrHelper;
  TmpSet: TBoolVector;
  I: SizeInt;
begin
  aValue := 0;
  aCut.S := [];
  aCut.T := [];
  CheckIndexRange(aSrcIndex);
  CheckIndexRange(aSinkIndex);
  Result := GetNetworkStateI(aSrcIndex, aSinkIndex);
  if Result <> nsOk then
    exit;
  aValue := Helper.GetMinCut(Self, aSrcIndex, aSinkIndex, aCut.S);
  TmpSet.InitRange(VertexCount);
  for I in aCut.S do
    TmpSet[I] := False;
  aCut.T := TmpSet.ToArray;
end;

function TGIntWeightDiGraph.FindMinSTCutD(constref aSource, aSink: TVertex; out aValue: TWeight;
  out aCut: TStCut): TNetworkState;
begin
  Result := FindMinSTCutDI(IndexOf(aSource), IndexOf(aSink), aValue, aCut);
end;

function TGIntWeightDiGraph.FindMinSTCutDI(aSrcIndex, aSinkIndex: SizeInt; out aValue: TWeight;
  out aCut: TStCut): TNetworkState;
var
  Helper: TDinitzHelper;
  TmpSet: TBoolVector;
  I: SizeInt;
begin
  aValue := 0;
  aCut.S := [];
  aCut.T := [];
  CheckIndexRange(aSrcIndex);
  CheckIndexRange(aSinkIndex);
  Result := GetNetworkStateI(aSrcIndex, aSinkIndex);
  if Result <> nsOk then
    exit;
  aValue := Helper.GetMinCut(Self, aSrcIndex, aSinkIndex, aCut.S);
  TmpSet.InitRange(VertexCount);
  for I in aCut.S do
    TmpSet[I] := False;
  aCut.T := TmpSet.ToArray;
end;

function TGIntWeightDiGraph.IsProperCosts(constref aCosts: TCostEdgeArray): Boolean;
var
  m: TEdgeCostMap;
begin
  Result := IsCostsCorrect(aCosts, m);
end;

function TGIntWeightDiGraph.FindMinCostFlowSsp(constref aSource, aSink: TVertex; constref aCosts: TCostEdgeArray;
  var aReqFlow: TWeight; out aTotalCost: TCost): Boolean;
begin
  Result := FindMinCostFlowSspI(IndexOf(aSource), IndexOf(aSink), aCosts, aReqFlow, aTotalCost);
end;

function TGIntWeightDiGraph.FindMinCostFlowSspI(aSrcIndex, aSinkIndex: SizeInt; constref aCosts: TCostEdgeArray;
  var aReqFlow: TWeight; out aTotalCost: TCost): Boolean;
var
  Helper: TSspMcfHelper;
  CostMap: TEdgeCostMap;
begin
  aTotalCost := 0;
  if aReqFlow < 1 then
    exit(False);
  if GetNetworkStateI(aSrcIndex, aSinkIndex) <> nsOk then
    exit(False);
  if not IsCostsCorrect(aCosts, CostMap) then
    exit(False);
  aReqFlow := Helper.GetMinCostFlow(Self, aSrcIndex, aSinkIndex, aReqFlow, CostMap, aTotalCost);
  Result := aReqFlow <> 0;
end;

function TGIntWeightDiGraph.FindMinCostFlowSsp(constref aSource, aSink: TVertex; constref aCosts: TCostEdgeArray;
  var aReqFlow: TWeight; out aTotalCost: TCost; out a: TEdgeArray): Boolean;
begin
  Result := FindMinCostFlowSspI(IndexOf(aSource), IndexOf(aSink), aCosts, aReqFlow, aTotalCost, a);
end;

function TGIntWeightDiGraph.FindMinCostFlowSspI(aSrcIndex, aSinkIndex: SizeInt; constref aCosts: TCostEdgeArray;
  var aReqFlow: TWeight; out aTotalCost: TCost; out aArcFlows: TEdgeArray): Boolean;
var
  Helper: TSspMcfHelper;
  CostMap: TEdgeCostMap;
begin
  aTotalCost := 0;
  aArcFlows := nil;
  if aReqFlow < 1 then
    exit(False);
  if GetNetworkStateI(aSrcIndex, aSinkIndex) <> nsOk then
    exit(False);
  if not IsCostsCorrect(aCosts, CostMap) then
    exit(False);
  aReqFlow := Helper.GetMinCostFlow(Self, aSrcIndex, aSinkIndex, aReqFlow, CostMap, aTotalCost, aArcFlows);
  Result := aReqFlow <> 0;
end;

function TGIntWeightDiGraph.FindMinCostFlowCs(constref aSource, aSink: TVertex; constref aCosts: TCostEdgeArray;
  var aReqFlow: TWeight; out aTotalCost: TCost): Boolean;
begin
  Result := FindMinCostFlowCsI(IndexOf(aSource), IndexOf(aSink), aCosts, aReqFlow, aTotalCost);
end;

function TGIntWeightDiGraph.FindMinCostFlowCsI(aSrcIndex, aSinkIndex: SizeInt; constref aCosts: TCostEdgeArray;
  var aReqFlow: TWeight; out aTotalCost: TCost): Boolean;
var
  Helper: TCsMcfHelper;
  CostMap: TEdgeCostMap;
begin
  aTotalCost := 0;
  if aReqFlow < 1 then
    exit(False);
  if GetNetworkStateI(aSrcIndex, aSinkIndex) <> nsOk then
    exit(False);
  if not IsCostsCorrect(aCosts, CostMap) then
    exit(False);
  aReqFlow := Helper.GetMinCostFlow(Self, aSrcIndex, aSinkIndex, aReqFlow, CostMap, aTotalCost);
  Result := aReqFlow <> 0;
end;

function TGIntWeightDiGraph.FindMinCostFlowCs(constref aSource, aSink: TVertex; constref aCosts: TCostEdgeArray;
  var aReqFlow: TWeight; out aTotalCost: TCost; out a: TEdgeArray): Boolean;
begin
  Result := FindMinCostFlowCsI(IndexOf(aSource), IndexOf(aSink), aCosts, aReqFlow, aTotalCost, a);
end;

function TGIntWeightDiGraph.FindMinCostFlowCsI(aSrcIndex, aSinkIndex: SizeInt; constref aCosts: TCostEdgeArray;
  var aReqFlow: TWeight; out aTotalCost: TCost; out aArcFlows: TEdgeArray): Boolean;
var
  Helper: TCsMcfHelper;
  CostMap: TEdgeCostMap;
begin
  aTotalCost := 0;
  aArcFlows := nil;
  if aReqFlow < 1 then
    exit(False);
  if GetNetworkStateI(aSrcIndex, aSinkIndex) <> nsOk then
    exit(False);
  if not IsCostsCorrect(aCosts, CostMap) then
    exit(False);
  aReqFlow := Helper.GetMinCostFlow(Self, aSrcIndex, aSinkIndex, aReqFlow, CostMap, aTotalCost, aArcFlows);
  Result := aReqFlow <> 0;
end;

end.

