unit svo_tree;

{$mode ObjFPC}{$H+}

interface

uses
  {$ifdef UNIX}
  cthreads,
  {$endif}
  Classes, SysUtils;

type
  TSVO_Word = string;
  TSVO_WordTree = class

  end;

  TSVO_Concept = class;
  TSVO_Concept_List = class;
  TSVO_Action = class;
  TSVO_Action_List = class;
  TSVO_Concept_Func = function (Subject:TSVO_Concept;Objects:TSVO_Concept_List):TSVO_Concept of object;

  // any object-like concept that can be subject or object in a sentence
  TSVO_Concept = class
  private
    FFuncNameList:array of TSVO_Word;
    FFuncObjectList:array of TSVO_Concept_Func;
  end;

  // a series of concept that can be objects
  TSVO_Concept_List = class
  private
    FList:array of TSVO_Concept;
  end;

  // any method-like action that can be verb in a sentence
  TSVO_Action = class
  private
    FConceptTypeList:array of TClass;
    FFuncObjectList:array of TSVO_Concept_Func;
  end;

  // name-method pairs list of a concept
  TSVO_Action_List = class
  private
    FList:array of TSVO_Action;
  end;

  // any statement-like unit representing a sentence
  // sentence can also be a object (maybe subject as well),
  //   so sentence is concept, which is similar to block
  TSVO_Sentence = class(TSVO_Concept)
  private
    FSubject:TSVO_Concept;
    FVerb:TSVO_Action;
    FObjects:TSVO_Concept_List;
  end;

implementation

end.

