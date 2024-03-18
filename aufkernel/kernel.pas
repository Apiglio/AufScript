unit kernel;

{$mode objfpc}{$H+}

interface

uses
  {$ifdef UNIX}
  cthreads,
  {$endif}
  Classes, SysUtils,
  svo_tree, word_tree;

type

  pFuncAufKernelStr = procedure(Sender:TObject;str:string);

  TAufKernel = class(TSVO_Concept)
    FAufScpt:TObject;//TAufScript 临时的对接方案
  public
    procedure Writeln(str:string);
  public
    function PrintVersion(Subject:TSVO_Concept;Objects:TSVO_Concept_List):TSVO_Concept;
  end;

implementation
uses Apiglio_Useful;

{ TAufKernel }
procedure TAufKernel.Writeln(str:string);
var AufScpt:TAufScript;
begin
  AufScpt:=FAufScpt as TAufScript;
  AufScpt.writeln(str);
end;

function TAufKernel.PrintVersion(Subject:TSVO_Concept;Objects:TSVO_Concept_List):TSVO_Concept;
begin
  Self.Writeln('AufScript version:');
  Self.Writeln(AufScript_Version);
  Self.Writeln(AufScript_OS+' ('+AufScript_CPU+')');
  result:=Self;
end;


end.

