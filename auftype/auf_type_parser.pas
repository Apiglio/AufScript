unit auf_type_parser;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  auf_type_base, auf_type_array;

type
  AufScriptParserError = class(Exception)
    constructor Create;
  end;

function AufBaseParser(syntax:string):TAufBase;
function AufArrayParser(line:string):TAufBase; //有可能不是数组，因此会返回基本类型

implementation

constructor AufScriptParserError.Create;
begin
  inherited Create('AufScript Parser Error');
end;

function AufBaseParser(syntax:string):TAufBase;
var itmp:int64;
    idx,codee:integer;
    ftmp:double;
    stmp:string;
    he,hd:boolean;
begin
  //type priority: integer float string
  //临时的方法，之后用语法树来实现，数组之类的先不实现
  result:=nil;
  if syntax='' then exit;
  if syntax[1]+syntax[length(syntax)]='""' then begin
    stmp:=syntax;
    if length(stmp)<2 then exit;
    delete(stmp,length(stmp),1);
    delete(stmp,1,1);
    result:=TAufBase.CreateAsString(stmp);
    exit;
  end;
  he:=false;
  hd:=false;
  for idx:=1 to length(syntax) do begin
    if syntax[idx] in ['e','E'] then he:=true;
    if syntax[idx]='.' then hd:=true;
  end;
  if he or hd then begin
    try
      ftmp:=StrToFloat(syntax);
      result:=TAufBase.CreateAsDouble(ftmp);
    except
      //
    end;
  end else begin
    val(syntax,itmp,codee);
    if codee<=0 then begin
      result:=TAufBase.CreateAsFixnum(itmp);
    end;
  end;
end;

function AufArrayParser(line:string):TAufBase;
var current_array,parent_array,last_array:TAufArray;
    tmpAufBase:TAufBase;
    idx,len:integer;
    current_line:string;
begin
  //由于早期指令解析中的前后缀特性，目前数组元素并不能是字符串。
  //这是此函数以外的问题。
  current_array:=nil;
  last_array:=nil;
  current_line:='';
  len:=length(line);
  idx:=1;
  repeat
    case line[idx] of
      '[':
        begin
          parent_array:=current_array;
          current_array:=TAufArray.Create;
          current_array.ParentArray:=parent_array;
          if parent_array<>nil then parent_array.LinkAppend(current_array);
          current_line:='';
        end;
      ']':
        begin
          if current_line<>'' then begin
            tmpAufBase:=AufArrayParser(current_line);
            current_array.LinkAppend(tmpAufBase);
            current_line:='';
          end;
          last_array:=current_array;
          current_array:=current_array.ParentArray;
        end;
      ',',';':
        begin
          //因为以行为指令单元的语法将逗号用于参数划分，此处的逗号仅作为保留。
          //所以目前数组的语法暂时以分号分隔元素。
          if current_line<>'' then begin
            tmpAufBase:=AufArrayParser(current_line);
            current_array.LinkAppend(tmpAufBase);
            current_line:='';
          end;
        end;
      else
        begin
          current_line:=current_line+line[idx];
        end;
    end;
    inc(idx);
  until idx>len;
  if current_array<>nil then raise AufScriptParserError.Create;
  if last_array=nil then result:=AufBaseParser(current_line)
  else result:=last_array;
end;

end.

