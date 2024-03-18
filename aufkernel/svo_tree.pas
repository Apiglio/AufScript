unit svo_tree;

//each has word-name is concept
//concepts includes nouns, verbs and sentences
//nouns and verbs are both TBaseConcept objects and share the same word-tree
//each sentence is made up of subject, verb and list of objects
//bracket is delimiter of sentences
//verb-word is permanent, once-defined by application
//non-verb concepts are stored as TSVO_Word and translated during runtime

{$mode ObjFPC}{$H+}

interface

uses
  {$ifdef UNIX}
  cthreads,
  {$endif}
  Classes, SysUtils,
  word_tree;

type
  TSVO_Word = string;
  TSVO_Concept = class;
  TSVO_Concept_List = class;
  TSVO_Verb = class;
  TSVO_Noun = class;
  TSVO_Concept_Func = function (Subject:TSVO_Concept;Objects:TSVO_Concept_List):TSVO_Concept of object;

  TSVO_Concept = class
    FName:String;
  public
    function NameAs(Subject:TSVO_Concept;Objects:TSVO_Concept_List):TSVO_Concept;virtual;
    function ReturnClass(Subject:TSVO_Concept;Objects:TSVO_Concept_List):TSVO_Concept;virtual;
    function Print(Subject:TSVO_Concept;Objects:TSVO_Concept_List):TSVO_Concept;virtual;
    function PrintHex(Subject:TSVO_Concept;Objects:TSVO_Concept_List):TSVO_Concept;virtual;
  public
    constructor Create;
    destructor Destroy; override;
  end;
  TSVO_Concept_List = class(TSVO_Concept)
    FList:TList;
  end;
  TSVO_Verb = class(TSVO_Concept);
  TSVO_Noun = class(TSVO_Concept);
  TSVO_Sentence = class(TSVO_Concept)
    FSubject:TSVO_Concept;
    FVerb:TSVO_Verb;
    FObjects:TSVO_Concept_List;
  end;
  TSVO_Sentences = class(TSVO_Concept_List)
  public
    procedure Clear;
    constructor Create;
    destructor Destroy; override;
  end;

  TSVO_Tree = class
    FWord:TSVO_Word;
    FList:TList;
    FDefinitionTree:TWordTreeNode;
    FParent:TSVO_Tree;
  protected
    function GetConceptDefine(aConceptName:TSVO_Word):TSVO_Concept;
    procedure SetConceptDefine(aConceptName:TSVO_Word;aValue:TSVO_Concept);
  public
    property ConceptDefine[aConceptName:TSVO_Word]:TSVO_Concept read GetConceptDefine write SetConceptDefine;
  public
    procedure Clear;
    constructor Create;
    destructor Destroy; override;
  end;

implementation



{ TSVO_Concept }

function TSVO_Concept.NameAs(Subject:TSVO_Concept;Objects:TSVO_Concept_List):TSVO_Concept;
begin

end;

function TSVO_Concept.ReturnClass(Subject:TSVO_Concept;Objects:TSVO_Concept_List):TSVO_Concept;
begin

end;

function TSVO_Concept.Print(Subject:TSVO_Concept;Objects:TSVO_Concept_List):TSVO_Concept;
begin

end;

function TSVO_Concept.PrintHex(Subject:TSVO_Concept;Objects:TSVO_Concept_List):TSVO_Concept;
begin

end;

constructor TSVO_Concept.Create;
begin
  inherited Create;
end;

destructor TSVO_Concept.Destroy;
begin
  inherited Destroy;
end;

procedure TSVO_Sentences.Clear;
begin
  while FList.Count>0 do begin;
    TSVO_Sentence(FList.Items[0]).Free;
    FList.Delete(0);
  end;
end;

constructor TSVO_Sentences.Create;
begin
  inherited Create;
  FList:=TList.Create;
end;

destructor TSVO_Sentences.Destroy;
begin
  Clear;
  FList.Free;
  inherited Destroy;
end;


{ TSVO_Tree }

function TSVO_Tree.GetConceptDefine(aConceptName:TSVO_Word):TSVO_Concept;
begin
  result:=TSVO_Concept(FDefinitionTree[aConceptName]);
  if (result=nil) and (FParent<>nil) then result:=TSVO_Concept(FParent.GetConceptDefine(aConceptName));
end;

procedure TSVO_Tree.SetConceptDefine(aConceptName:TSVO_Word;aValue:TSVO_Concept);
var former:Pointer;
begin
  former:=FDefinitionTree[aConceptName];
  if former<>nil then begin
    //覆盖定义时的操作
  end;
  FDefinitionTree[aConceptName]:=aValue;
end;

procedure TSVO_Tree.Clear;
begin
  while FList.Count>0 do begin
    TSVO_Tree(FList.Items[0]).Free;
    FList.Delete(0);
  end;
end;

constructor TSVO_Tree.Create;
begin
  inherited Create;
  FList:=TList.Create;
  FDefinitionTree:=TWordTreeNode.Create;
  FParent:=nil;
end;

destructor TSVO_Tree.Destroy;
begin
  FDefinitionTree.Free;
  Clear;
  FList.Free;
  inherited Destroy;
end;

end.

