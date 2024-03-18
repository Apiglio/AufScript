unit word_tree;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TWordTreeNodeEnumerator = class;
  TWordTreeNode = class
    FChildren:TStringList;
    FParent:TWordTreeNode;
    FPointer:Pointer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
  protected
    function GetWord(aName:String):Pointer;
    procedure SetWord(aName:String;aValue:Pointer);
  public
    property Word[Name:String]:Pointer read GetWord write SetWord;default;
    function GetEnumerator:TWordTreeNodeEnumerator;
  end;

  TWordTreeNodeEnumerator = class
  private
    FList:TList;
    FPosition:Integer;
  protected
    procedure RecurWord(AWordTreeNode:TWordTreeNode);
  public
    constructor Create(AWordTreeNode:TWordTreeNode);
    function GetCurrent:Pointer;
    function MoveNext:Boolean;
    property Current:Pointer read GetCurrent;
  end;

implementation


constructor TWordTreeNode.Create;
begin
  inherited Create;
  FChildren:=TStringList.Create;
  FChildren.Sorted:=true;
  FParent:=nil;
  FPointer:=nil;
end;

destructor TWordTreeNode.Destroy;
begin
  Clear;
  FChildren.Free;
  inherited Destroy;
end;

procedure TWordTreeNode.Clear;
begin
  while FChildren.Count>0 do begin
    TWordTreeNode(FChildren.Objects[0]).Clear;
    FChildren.Delete(0);
  end;
end;

function TWordTreeNode.GetWord(aName:String):Pointer;
var s1,s2:string;
    index:integer;
    found:boolean;
begin
  result:=nil;
  if length(aName)<=0 then exit;
  s1:=aName[1];
  s2:=aName;
  System.Delete(s2,1,1);
  found:=FChildren.Find(s1,index);
  if s2='' then begin
    if found then result:=TWordTreeNode(FChildren.Objects[index]).FPointer;
  end else begin
    if found then result:=TWordTreeNode(FChildren.Objects[index]).GetWord(s2);
  end;
end;

procedure TWordTreeNode.SetWord(aName:String;aValue:Pointer);
var s1,s2:string;
    index:integer;
    found:boolean;
    tmpNode:TWordTreeNode;
begin
  if length(aName)<=0 then begin
    FPointer:=aValue;
    exit;
  end;
  s1:=aName[1];
  s2:=aName;
  System.Delete(s2,1,1);
  found:=FChildren.Find(s1,index);
  if s2='' then begin
    if found then begin
      TWordTreeNode(FChildren.Objects[index]).FPointer:=aValue;
    end else begin
      tmpNode:=TWordTreeNode.Create;
      tmpNode.FPointer:=aValue;
      tmpNode.FParent:=Self;
      FChildren.AddObject(s1,tmpNode);
    end;
  end else begin
    if found then begin
      TWordTreeNode(FChildren.Objects[index]).SetWord(s2,aValue);
    end else begin
      tmpNode:=TWordTreeNode.Create;
      tmpNode.FParent:=Self;
      FChildren.AddObject(s1,tmpNode);
      tmpNode.SetWord(s2,aValue);
    end;
  end;
end;

function TWordTreeNode.GetEnumerator:TWordTreeNodeEnumerator;
begin
  result:=TWordTreeNodeEnumerator.Create(Self);
end;

{ TWordTreeNodeEnumerator }

procedure TWordTreeNodeEnumerator.RecurWord(AWordTreeNode:TWordTreeNode);
var idx:integer;
begin
  if AWordTreeNode.FPointer<>nil then FList.Add(AWordTreeNode.FPointer);
  idx:=0;
  while idx<AWordTreeNode.FChildren.Count do begin
    RecurWord(TWordTreeNode(AWordTreeNode.FChildren.Objects[idx]));
    inc(idx);
  end;
end;

constructor TWordTreeNodeEnumerator.Create(AWordTreeNode:TWordTreeNode);
begin
  FList:=TList.Create;
  RecurWord(AWordTreeNode);
  FPosition:=-1;
end;

function TWordTreeNodeEnumerator.GetCurrent:Pointer;
begin
  result:=FList.Items[FPosition];
end;

function TWordTreeNodeEnumerator.MoveNext:Boolean;
begin
  result:=true;
  inc(FPosition);
  if FPosition<FList.Count then exit;
  result:=false;
  FList.Free;
end;

end.

