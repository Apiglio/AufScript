unit auf_ram_syntax;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, auf_ram_var;

type

  TARS_Function = class
    func_name:string;
    func_addr:function(AList:TList):TAufRamVar;
  end;

  TAufRamSyntaxNode=class
    FList:TList;//参数
    FARS:TARS_Function;//调用参数函数
    FARV:TAufRamVar;//无函数时的值
  public
    constructor Create;
    destructor Destroy;
    procedure DoSyntax;
    procedure FreeARV;
    procedure CopyARV(arv:TAufRamVar);

  end;


implementation

constructor TAufRamSyntaxNode.Create;
begin
  inherited Create;
  FList:=TList.Create;
  FARS:=nil;
  FARV.VarType:=ARV_Raw;
  FARV.size:=0;
end;

destructor TAufRamSyntaxNode.Destroy;
begin
  while FList.Count>0 do
    begin
      TAufRamSyntaxNode(FList.Items[0]).Free;
      FList.Delete(0);
    end;
  FreeARV;
  FList.Free;
  inherited Destroy;
end;

procedure TAufRamSyntaxNode.DoSyntax;
var index:integer;
    tmpNode:TAufRamSyntaxNode;
begin
  index:=0;
  while index<FList.Count do
    begin
      tmpNode:=TAufRamSyntaxNode(FList.Items[index]);
      if tmpNode.FARS<>nil then tmpNode.DoSyntax;
      inc(index);
    end;
  FARV:=FARS.func_addr(FList);
end;

procedure TAufRamSyntaxNode.FreeARV;
begin
  if FARV.size<>0 then freemem(FARV.Head,FARV.size);
end;

procedure TAufRamSyntaxNode.CopyARV(arv:TAufRamVar);
begin
  FARV.size:=arv.size;
  FARV.Head:=getmem(FARV.size);
  move(arv.Head,FARV.Head,arv.size);
  FARV.VarType:=arv.VarType;
end;

end.
