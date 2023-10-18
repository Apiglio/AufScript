
unit SynHighlighterAuf;

interface

uses
  Classes,
  Graphics,
  SynEditTypes, SynEditHighlighter;

type
  TtkTokenKind = (tkComment, tkText, tkSection, tkKey, tkNull, tkNumber,
    tkSpace, tkString, tkSymbol, tkUnknown, tkAtExpr, tkAddr, tkArv);

  TProcTableProc = procedure of object;

type

  { TSynAufSyn }

  TSynAufSyn = class(TSynCustomHighlighter)
  private
    fLine: PChar;
    fLineNumber: Integer;
    fProcTable: array[#0..#255] of TProcTableProc;
    Run: LongInt;
    fTokenPos: Integer;
    FTokenID: TtkTokenKind;
    fCommentAttri: TSynHighlighterAttributes;
    fTextAttri: TSynHighlighterAttributes;
    fSectionAttri: TSynHighlighterAttributes;
    fOpCodeAttri: TSynHighlighterAttributes;
    fNumberAttri: TSynHighlighterAttributes;
    fSpaceAttri: TSynHighlighterAttributes;
    fStringAttri: TSynHighlighterAttributes;
    fSymbolAttri: TSynHighlighterAttributes;
    fAtExprAttri: TSynHighlighterAttributes;
    fAddrAttri: TSynHighlighterAttributes;
    fArvAttri: TSynHighlighterAttributes;
    FInternalFunc:string;
    FExternalFunc:string;
    procedure SectionOpenProc;
    procedure OpCodeProc;
    procedure AtExprProc;
    procedure AddrProc;
    procedure ArvProc;
    procedure CRProc;
    procedure EqualProc;
    procedure TextProc;
    procedure LFProc;
    procedure NullProc;
    procedure NumberProc;
    procedure SemiColonProc;
    procedure SpaceProc;
    procedure StringProc;  // ""
    procedure StringProc1; // ''
    procedure MakeMethodTables;
  protected
    {General Stuff}
    function GetIdentChars: TSynIdentChars; override;
    function GetSampleSource: String; override;
  public
    class function GetLanguageName: string; override;
  public
    constructor Create(AOwner: TComponent); override;
    function GetDefaultAttribute(Index: integer): TSynHighlighterAttributes;
      override;
    function GetEol: Boolean; override;
    function GetTokenID: TtkTokenKind;
    procedure SetLine(const NewValue: String; LineNumber:Integer); override;
    function GetToken: String; override;
    procedure GetTokenEx(out TokenStart: PChar; out TokenLength: integer); override;
    function GetTokenAttribute: TSynHighlighterAttributes; override;
    function GetTokenKind: integer; override;
    function GetTokenPos: Integer; override;
    procedure Next; override;
  published
    property InternalFunc:string read FInternalFunc write FInternalFunc;
    property ExternalFunc:string read FExternalFunc write FExternalFunc;

    property CommentAttri: TSynHighlighterAttributes read fCommentAttri
      write fCommentAttri;
    property TextAttri   : TSynHighlighterAttributes read fTextAttri
      write fTextAttri;
    property SectionAttri: TSynHighlighterAttributes read fSectionAttri
      write fSectionAttri;
    property KeyAttri    : TSynHighlighterAttributes read fOpCodeAttri
      write fOpCodeAttri;
    property NumberAttri : TSynHighlighterAttributes read fNumberAttri
      write fNumberAttri;
    property SpaceAttri  : TSynHighlighterAttributes read fSpaceAttri
      write fSpaceAttri;
    property StringAttri : TSynHighlighterAttributes read fStringAttri
      write fStringAttri;
    property SymbolAttri : TSynHighlighterAttributes read fSymbolAttri
      write fSymbolAttri;
    property AtExprAttri : TSynHighlighterAttributes read fAtExprAttri
      write fAtExprAttri;
    property AddrAttri : TSynHighlighterAttributes read fAddrAttri
      write fAddrAttri;
    property ArvAttri : TSynHighlighterAttributes read fArvAttri
      write fArvAttri;

  end;

  {}function numberic_check(str:string):byte;//0-text 1-float 2-decimal 3-hex 4-binary

implementation

uses
  SynEditStrConst;



procedure TSynAufSyn.MakeMethodTables;
var
  i: Char;
begin
  for i := #0 to #255 do
    case i of
      #0      : fProcTable[i] := @NullProc;
      #10 {LF}: fProcTable[i] := @LFProc;
      #13 {CR}: fProcTable[i] := @CRProc;
      #34 {"} : fProcTable[i] := @StringProc;
      //#39 {'} : fProcTable[i] := @StringProc1;
      //'0'..'9','a'..'f','A'..'F': fProcTable[i] := @NumberProc;
      #59,'/' {;} : fProcTable[i] := @SemiColonProc;
      //#61 {=} : fProcTable[i] := @EqualProc;
      //#91 {[} : fProcTable[i] := @SectionOpenProc;
      #1..#9, #11, #12, #14..#32,',': fProcTable[i] := @SpaceProc;
      '@'     : fProcTable[i] := @AtExprProc;
      ':'     : fProcTable[i] := @AddrProc;
      '~','$','#': fProcTable[i] := @ArvProc;

    else
      fProcTable[i] := @TextProc;
    end;
end;

constructor TSynAufSyn.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  //FInternalFunc:=',mov,add,sub,mul,div,mod,';
  //FExternalFunc:=',jmp,ret,call,';
  FInternalFunc:=',';
  FExternalFunc:=',';

  fCommentAttri            := TSynHighlighterAttributes.Create(@SYNS_AttrComment);
  fCommentAttri.Style      := [fsItalic];
  fCommentAttri.Foreground := clGreen;

  fTextAttri               := TSynHighlighterAttributes.Create(@SYNS_AttrText);
  fTextAttri.Foreground    := clblack;

  fSectionAttri            := TSynHighlighterAttributes.Create(@SYNS_AttrSection);
  fSectionAttri.Style      := [fsBold];

  fOpCodeAttri             := TSynHighlighterAttributes.Create(@SYNS_AttrKey);
  fOpCodeAttri.Foreground  := clBlack;
  fOpCodeAttri.Style       := [fsBold];

  fNumberAttri             := TSynHighlighterAttributes.Create(@SYNS_AttrNumber);
  fNumberAttri.Foreground  := $770000;
  //fNumberAttri.Background  := $DDDDDD;
  fSpaceAttri              := TSynHighlighterAttributes.Create(@SYNS_AttrSpace);
  fStringAttri             := TSynHighlighterAttributes.Create(@SYNS_AttrString);
  fStringAttri.Foreground  := clBlue;
  //fStringAttri.Style       := [fsUnderLine];

  fSymbolAttri            := TSynHighlighterAttributes.Create(@SYNS_AttrSymbol);
  fSymbolAttri.Foreground := clRed;
  //fSymbolAttri.Style      := [fsBold];

  fAtExprAttri            := TSynHighlighterAttributes.Create(@SYNS_AttrSymbol);
  fAtExprAttri.Foreground := clRed;
  //fAtExprAttri.Style      := [fsItalic];

  fAddrAttri            := TSynHighlighterAttributes.Create(@SYNS_AttrSymbol);
  fAddrAttri.Foreground := clPurple;
  //fAddrAttri.Background := $333333;
  fAddrAttri.Style      := [fsBold];

  fArvAttri            := TSynHighlighterAttributes.Create(@SYNS_AttrSymbol);
  fArvAttri.Foreground := $0000CC;
  //fArvAttri.Style      := [fsItalic];

  AddAttribute(fCommentAttri);
  AddAttribute(fTextAttri);
  AddAttribute(fSectionAttri);
  AddAttribute(fOpCodeAttri);
  AddAttribute(fNumberAttri);
  AddAttribute(fSpaceAttri);
  AddAttribute(fStringAttri);
  AddAttribute(fSymbolAttri);

  SetAttributesOnChange(@DefHighlightChange);

  fDefaultFilter      := SYNS_FilterINI;
  MakeMethodTables;
end; { Create }

procedure TSynAufSyn.SetLine(const NewValue: String; LineNumber:Integer);
begin
  inherited;
  fLine := PChar(NewValue);
  Run := 0;
  fLineNumber := LineNumber;
  Next;
end; { SetLine }

procedure TSynAufSyn.SectionOpenProc;
begin
  // if it is not column 0 mark as tkText and get out of here
  if Run > 0 then
  begin
    fTokenID := tkText;
    inc(Run);
    Exit;
  end;

  // this is column 0 ok it is a Section
  fTokenID := tkSection;
  inc(Run);
  while FLine[Run] <> #0 do
    case FLine[Run] of
      ']': begin inc(Run); break end;
      #10: break;
      #13: break;
    else inc(Run);
    end;
end;

procedure TSynAufSyn.CRProc;
begin
  fTokenID := tkSpace;
  Case FLine[Run + 1] of
    #10: inc(Run, 2);
  else inc(Run);
  end;
end;

procedure TSynAufSyn.EqualProc;
begin
  inc(Run);
  fTokenID := tkSymbol;
end;

procedure TSynAufSyn.OpCodeProc;
begin
  fTokenID := tkKey;
  inc(Run);
  while FLine[Run] <> #0 do
    case FLine[Run] of
      ' ',',': break;
      #10: break;
      #13: break;
    else inc(Run);
    end;
end;

procedure TSynAufSyn.AtExprProc;
begin
  fTokenID := tkAtExpr;
  inc(Run);
  while FLine[Run] <> #0 do
    case FLine[Run] of
      ' ',',': break;
      #10: break;
      #13: break;
    else inc(Run);
    end;
end;

procedure TSynAufSyn.AddrProc;
begin
  fTokenID := tkAddr;
  inc(Run);
  while FLine[Run] <> #0 do
    case FLine[Run] of
      ' ',',': break;
      #10: break;
      #13: break;
    else inc(Run);
    end;
end;

procedure TSynAufSyn.ArvProc;
begin
  fTokenID := tkArv;
  inc(Run);
  while FLine[Run] <> #0 do
    case FLine[Run] of
      ' ',',': break;
      #10: break;
      #13: break;
    else inc(Run);
    end;
end;
{
procedure TSynAufSyn.TextProc;
begin

  if Run = 0 then begin
    OpCodeProc
  end else begin

    inc(Run);
    while (fLine[Run] in [#128..#191]) OR // continued utf8 subcode
     ((fLine[Run]<>#0) and (fProcTable[fLine[Run]] = @TextProc)) do inc(Run);
    fTokenID := tkText;
    //fTokenID := tkText;
    //inc(Run);

  end;

end;
}
//{

function numberic_check(str:string):byte;//0-text 1-float 2-decimal 3-hex 4-binary
var pi:word;
    is_binary,is_hex,is_float,is_ne,have_dot,have_symbol:boolean;
begin
  pi:=1;
  result:=2;
  is_binary:=true;
  is_hex:=false;
  is_float:=false;
  is_ne:=false;
  have_dot:=false;
  have_symbol:=false;
  while pi<=length(str) do
    begin
      if str[pi] in ['0'..'9'] then
        begin
          if not (str[pi] in ['0','1']) then is_binary:=false;
        end
      else
        begin
          case str[pi] of
            'a','c','d','f','A','C','D','F','b','B':
              begin
                is_hex:=true;
                is_ne:=true;
                {
                case str[pi] of 'b','B':
                  begin
                    'B','b':
                      begin
                        if pi=length(str) then begin
                          if is_binary and (not have_symbol) and (not have_dot) then begin result:=4;exit end
                          else begin result:=0;exit end;
                        end;
                        is_hex:=true;
                        is_ne:=true;
                      end;
                  end;
                  }
                  //B结尾二进制不启用
              end;
            '.':
              begin
                if have_dot then begin result:=0;exit end;
                is_float:=true;
                have_dot:=true;
              end;
            '+','-':
              begin
                if pi<>1 then begin
                  if str[pi-1] in ['E','e'] then is_float:=true
                  else begin result:=0;exit end;
                end;
                have_symbol:=true;
              end;
            'E','e':
              begin
                is_hex:=true;
                is_float:=true;
              end;
            'H','h':
              begin
                if (pi=length(str)) and (not have_symbol) and (not have_dot) then begin result:=3;exit end
                else begin result:=0;exit end;
              end;
            else begin result:=0;exit end;
          end;
        end;
      inc(pi);
    end;
  if is_float then begin
    if (not is_ne) and (str[1] in ['0'..'9','+','-','.']) and (str[length(str)] in ['0'..'9']) then begin result:=1;exit end
    else begin result:=0;exit end;
  end;
  if is_hex then result:=0;
end;

procedure TSynAufSyn.TextProc;//新方法
label skipp;
var offset,posi,pose:word;
    element:string;
    in_quote:boolean;
begin
  offset:=0;
  in_quote:=false;
  element:='';
  repeat
    if fLine[Run+offset]='"' then in_quote:=in_quote xor true;
    element:=element+fLine[Run+offset];
    inc(offset);
  until (fLine[Run+offset]=#0) or ((not in_quote) and (fLine[Run+offset] in [',',' ']));

  if element[length(element)]=':' then begin
    fTokenID := tkAddr;
    goto skipp;
  end;
  if numberic_check(element)<>0 then begin
    fTokenID := tkNumber;
    goto skipp;
  end;

  posi:=pos(','+lowercase(element)+',',Self.FInternalFunc);
  pose:=pos(','+lowercase(element)+',',Self.FExternalFunc);
  if (posi<=0) and (pose<=0) then
    fTokenID := tkText
  else
    fTokenID := tkKey;


skipp:
  //for poss:=0 to offset-1 do inc(Run);
  inc(Run,offset);
end;
//}
procedure TSynAufSyn.LFProc;
begin
  fTokenID := tkSpace;
  inc(Run);
end;

procedure TSynAufSyn.NullProc;
begin
  fTokenID := tkNull;
end;

procedure TSynAufSyn.NumberProc;//不要了
begin
  {
  if Run = 0 then
    OpCodeProc
  else begin
  }
    inc(Run);
    fTokenID := tkNumber;
    while FLine[Run] in ['0'..'9','a'..'f','A'..'F','.'] do inc(Run);
    if FLine[Run] in ['a'..'z','A'..'Z'] then TextProc;
  {
  end;
  }
end;

// ;
procedure TSynAufSyn.SemiColonProc;
begin
  // if it is not column 0 mark as tkText and get out of here
  if (Run > 1) or (FLine[Run+1]<>'/') then
  begin
    fTokenID := tkText;
    inc(Run);
    Exit;
  end;

  // this is column 0 ok it is a comment
  fTokenID := tkComment;
  inc(Run);
  while FLine[Run] <> #0 do
    case FLine[Run] of
      #10: break;
      #13: break;
    else inc(Run);
    end;
end;

procedure TSynAufSyn.SpaceProc;
begin
  inc(Run);
  fTokenID := tkSpace;
  while FLine[Run] in [#1..#9, #11, #12, #14..#32] do inc(Run);
end;

// ""
procedure TSynAufSyn.StringProc;
begin
  fTokenID := tkString;
  if (FLine[Run + 1] = #34) and (FLine[Run + 2] = #34) then inc(Run, 2);
  repeat
    case FLine[Run] of
      #0, #10, #13: break;
    end;
    inc(Run);
  until FLine[Run] = #34;
  if FLine[Run] <> #0 then inc(Run);
end;

// ''
procedure TSynAufSyn.StringProc1;
begin
  fTokenID := tkString;
  if (FLine[Run + 1] = #39) and (FLine[Run + 2] = #39) then inc(Run, 2);
  repeat
    case FLine[Run] of
      #0, #10, #13: break;
    end;
    inc(Run);
  until FLine[Run] = #39;
  if FLine[Run] <> #0 then inc(Run);
end;

procedure TSynAufSyn.Next;
begin
  fTokenPos := Run;
  fProcTable[fLine[Run]];
end;

function TSynAufSyn.GetDefaultAttribute(Index: integer): TSynHighlighterAttributes;
begin
  case Index of
    SYN_ATTR_COMMENT: Result := fCommentAttri;
    SYN_ATTR_KEYWORD: Result := fOpCodeAttri;
    SYN_ATTR_STRING: Result := fStringAttri;
    SYN_ATTR_WHITESPACE: Result := fSpaceAttri;
    SYN_ATTR_SYMBOL: Result := fSymbolAttri;
    SYN_ATTR_NUMBER: Result := fNumberAttri;
  else
    Result := nil;
  end;
end;

function TSynAufSyn.GetEol: Boolean;
begin
  Result := fTokenId = tkNull;
end;

function TSynAufSyn.GetToken: String;
var
  Len: LongInt;
begin
  Len := Run - fTokenPos;
  SetString(Result, (FLine + fTokenPos), Len);
end;

procedure TSynAufSyn.GetTokenEx(out TokenStart: PChar; out TokenLength: integer);
begin
  TokenLength := Run - fTokenPos;
  TokenStart := FLine + fTokenPos;
end;

function TSynAufSyn.GetTokenID: TtkTokenKind;
begin
  Result := fTokenId;
end;

function TSynAufSyn.GetTokenAttribute: TSynHighlighterAttributes;
begin
  case fTokenID of
    tkComment: Result := fCommentAttri;
    tkText   : Result := fTextAttri;
    tkSection: Result := fSectionAttri;
    tkKey    : Result := fOpCodeAttri;
    tkNumber : Result := fNumberAttri;
    tkSpace  : Result := fSpaceAttri;
    tkString : Result := fStringAttri;
    tkSymbol : Result := fSymbolAttri;
    tkUnknown: Result := fTextAttri;
    tkAtExpr : Result := fAtExprAttri;
    tkAddr   : Result := fAddrAttri;
    tkArv    : Result := fArvAttri;
    else Result := nil;
  end;
end;

function TSynAufSyn.GetTokenKind: integer;
begin
  Result := Ord(fTokenId);
end;

function TSynAufSyn.GetTokenPos: Integer;
begin
 Result := fTokenPos;
end;

function TSynAufSyn.GetIdentChars: TSynIdentChars;
begin
  Result := TSynValidStringChars;
end;

class function TSynAufSyn.GetLanguageName: string;
begin
  Result := SYNS_LangINI;
end;

function TSynAufSyn.GetSampleSource: String;
begin
  Result := '; Syntax highlighting'#13#10+
            '[Section]'#13#10+
            'Key=value'#13#10+
            'String="Arial"'#13#10+
            'Number=123456';
end;

initialization
  RegisterPlaceableHighlighter(TSynAufSyn);

end.
