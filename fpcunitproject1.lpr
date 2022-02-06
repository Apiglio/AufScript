program fpcunitproject1;

{$define GUI_TEST}

{$ifdef GUI_TEST}
  {$apptype GUI}
{$else}
  {$apptype console}
{$endif}

{$mode objfpc}{$H+}

uses
  Classes, StdCtrls, ExtCtrls, Sysutils, Forms, consoletestrunner, Interfaces, LazUTF8, Windows, Apiglio_Useful, auf_ram_var;

type

  {$ifdef GUI_TEST}
  TMyTestForm = class(TForm)
  published
    Memo_cmd,Memo_output:TMemo;
    Button_run,Button_pause,Button_stop:TButton;
  public
    constructor CreateNew(AOwner:TComponent);
    procedure InitializeForm;
    procedure ResizeForm(Sender:TObject);
    procedure FormDestroy(Sender:TObject);
    procedure OnRunClick(Sender:TObject);
    procedure OnStopClick(Sender:TObject);
    procedure OnPauseClick(Sender:TObject);
  public
    procedure test;
  end;

  {$else}
  { TLazTestRunner }
  TMyTestRunner = class(TTestRunner)
  protected
  // override the protected methods of TTestRunner to customize its behavior
  end;
  {$endif}


var
  {$ifdef GUI_TEST}
     Application:TApplication;
     Test_Form:TMyTestForm;
  {$else}
     Application: TMyTestRunner;
  {$endif}
  i:integer;
  b:byte;
  fptr:pFuncFileByte;
  ts:TStringlist;
  ptr:pointer;
  s:string;
  v1,v2:TAufRamVar;


{$ifdef GUI_TEST}
procedure command_decoder(var str:string);
begin
  str:=utf8towincp(str);
  str:=StringReplace(str,'\s',' ',[rfReplaceAll]);

end;
procedure renew_pre;
begin Application.ProcessMessages end;
procedure renew_post;
begin Application.ProcessMessages end;
procedure renew_mid;
begin Application.ProcessMessages end;
procedure renew_beginning;
begin
  Test_Form.Memo_output.Clear;
  Test_Form.Button_run.Enabled:=false;
  Test_Form.Button_stop.Enabled:=true;
  Test_Form.Button_pause.Enabled:=true;
  Test_Form.Memo_cmd.ReadOnly:=true;
  Application.ProcessMessages;
end;
procedure renew_ending;
begin
  Test_Form.Button_run.Enabled:=true;
  Test_Form.Button_stop.Enabled:=false;
  Test_Form.Button_pause.Enabled:=false;
  Test_Form.Memo_cmd.ReadOnly:=false;
  Application.ProcessMessages;
end;
procedure renew_writeln(str:string);
begin
  Test_Form.Memo_output.lines.add(ansitoutf8(str));
  Application.ProcessMessages;
end;
procedure renew_write(str:string);
begin
  Test_Form.Memo_output.lines[Test_Form.Memo_output.Lines.Count-1]:=
  Test_Form.Memo_output.lines[Test_Form.Memo_output.Lines.Count-1]+
  ansitoutf8(str);
  Application.ProcessMessages;
end;
{ TMyTestForm }
procedure TMyTestForm.test;
begin
  MessageBox(0,'TEST:OK','TEST',MB_OK);
end;
procedure TMyTestForm.InitializeForm;
begin
  Self.Memo_cmd:=TMemo.Create(Self);
  Self.Memo_output:=TMemo.Create(Self);
  Self.Button_run:=TButton.Create(Self);
  Self.Button_stop:=TButton.Create(Self);
  Self.Button_pause:=TButton.Create(Self);
  Self.Memo_cmd.Parent:=Self;
  Self.Memo_output.Parent:=Self;
  Self.Button_run.Parent:=Self;
  Self.Button_stop.Parent:=Self;
  Self.Button_pause.Parent:=Self;

  Self.Memo_cmd.ScrollBars:=ssAutoVertical;
  Self.Memo_output.ScrollBars:=ssAutoVertical;

  Self.Button_run.Caption:='开始';
  Self.Button_stop.Caption:='停止';
  Self.Button_pause.Caption:='暂停';

  Self.Button_run.OnClick:=@Self.OnRunClick;
  Self.Button_stop.OnClick:=@Self.OnStopClick;
  Self.Button_pause.OnClick:=@Self.OnPauseClick;
  Self.ResizeForm(nil);
  Self.OnResize:=@Self.ResizeForm;
  Self.OnDestroy:=@Self.FormDestroy;

  Test_Form.Caption:='Auf GUI Tester';
  Test_Form.Width:=300;
  Test_Form.Height:=200;
  Test_Form.Position:=poScreenCenter;
  Test_Form.Show;
  {
  MessageBox(0,
      Usf.ExPChar(
                  '@Auf.Script.Func_process.beginning=$'+
                  Usf.to_hex(dword(Auf.Script.Func_process.beginning),8)+
                  #13+#10+'@renew_beginning=$'+
                  Usf.to_hex(dword(@renew_beginning),8)
                  ),
      'Process_Check',
      MB_OK);
  }
  Auf.Script.IO_fptr.command_decode:=@command_decoder;
  Auf.Script.IO_fptr.echo:=@renew_writeln;
  Auf.Script.IO_fptr.print:=@renew_write;
  Auf.Script.IO_fptr.pause:=@de_nil;
  Auf.Script.IO_fptr.error:=@renew_writeln;
  Auf.Script.Func_process.beginning:=@renew_beginning;
  Auf.Script.Func_process.ending:=@renew_ending;
  Auf.Script.Func_process.pre:=@renew_pre;
  Auf.Script.Func_process.mid:=@renew_mid;
  Auf.Script.Func_process.post:=@renew_post;
  {
  MessageBox(0,
      Usf.ExPChar(
                  '@Auf.Script.Func_process.beginning=$'+
                  Usf.to_hex(dword(Auf.Script.Func_process.beginning),8)+
                  #13+#10+'@renew_beginning=$'+
                  Usf.to_hex(dword(@renew_beginning),8)
                  ),
      'Process_Check',
      MB_OK);
  }

end;
constructor TMyTestForm.CreateNew(AOwner:TComponent);
begin
  inherited CreateNew(AOwner);
  Self.InitializeForm;
end;
procedure TMyTestForm.ResizeForm(Sender:TObject);
var DI,TRE:word;//二分、三分宽度
    gap:word;//通用间隔
    BtnH:word;//按钮高度
begin
  gap:=6;
  BtnH:=30;
  DI:=(Self.Width-3*gap)div 2;
  TRE:=(Self.Width-4*gap)div 3;

  Self.Memo_cmd.Height:=Self.Height - 3*gap - BtnH;
  Self.Memo_output.Height:=Self.Height - 3*gap - BtnH;
  Self.Memo_cmd.Width:=DI;
  Self.Memo_output.Width:=DI;
  Self.Memo_cmd.Top:=gap;
  Self.Memo_output.Top:=gap;
  Self.Memo_cmd.Left:=gap;
  Self.Memo_output.Left:=Self.Memo_cmd.Width + 2*gap;
  Self.Button_run.Left:=gap;
  Self.Button_run.Top:=Self.Height - BtnH - gap;
  Self.Button_run.Width:=TRE;
  Self.Button_run.Height:=BtnH;

  Self.Button_pause.Left:=2*gap+TRE;
  Self.Button_pause.Top:=Self.Height - BtnH - gap;
  Self.Button_pause.Width:=TRE;
  Self.Button_pause.Height:=BtnH;

  Self.Button_stop.Left:=3*gap+2*TRE;
  Self.Button_stop.Top:=Self.Height - BtnH - gap;
  Self.Button_stop.Width:=TRE;
  Self.Button_stop.Height:=BtnH;

end;
procedure TMyTestForm.FormDestroy(Sender:TObject);
begin
  //Application.Terminate;
  Halt;
end;
procedure TMyTestForm.OnRunClick(Sender:TObject);
begin
  Auf.Script.command(Self.Memo_cmd.Lines);
end;
procedure TMyTestForm.OnStopClick(Sender:TObject);
begin
  Auf.Script.Stop;
end;
procedure TMyTestForm.OnPauseClick(Sender:TObject);
var btn:TButton;
begin
  btn:=Sender as TButton;
  if btn.Caption='暂停' then begin
    //Auf.Script.Time.TimerPause:=true;
    Auf.Script.Pause;
    btn.Caption:='继续';
  end else begin
    //Auf.Script.Time.TimerPause:=false;
    //Auf.Script.send(AufProcessControl_RunNext);
    Auf.Script.Resume;
    btn.Caption:='暂停';
  end;
end;
{$else}
{$endif}

procedure test(str:string);
begin
  writeln(str);
end;

begin
  {$ifdef GUI_TEST}
  Application:=TApplication.Create(nil);
  Application.Initialize;
  Application.CreateForm(TMyTestForm,Test_Form);

  Auf.Free;
  Auf:=TAuf.Create(Test_Form);
  Auf.Script.InternalFuncDefine;

  Test_Form.InitializeForm;
  Test_Form.Memo_cmd.Lines.CommaText:='aa:,echoln\s"aaa",sleep\s100,jmp\s:aa';

  Application.Run;
  {$else}
  Application := TMyTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'FPCUnit Console test runner';

  writeln;
  writeln;
  writeln;
  writeln;

  pLongint(Auf.Script.PSW.run_parameter.ram_zero)^:=$DDCCBBAA;
  Auf.ReadArgs('mov $"@@@@@@@A|@C"');
  writeln(arv_to_hex(Auf.Script.RamVar(Auf.nargs[1])));

  //这一段介绍Auf.ReadArg(str)返回的Auf对象之下的ArgsCount,divi,iden,toto,args[]和nargs[]属性
  Auf.ReadArgs('addb $2,1,"(345,234,12)",@112~,$"S#@FA|@",?"134<<2+22<<4",?"$12[33]",&&"sasde??s"$$,&"@@@@@@@@A"');
  //for i:=0 to args_range-1 do writeln('Auf.args[',i,']=',Auf.args[i]);
  for i:=0 to args_range-1 do
    begin
      write('Auf.nargs[',i,']=',Auf.nargs[i].pre);
      write(utf8toansi('囗'),Auf.nargs[i].arg);
      writeln(utf8toansi('囗'),Auf.nargs[i].post);
    end;
  writeln('zeroplus=',Usf.zeroplus(1234,5));
  writeln('Auf.divi=',Auf.divi);
  writeln('Auf.iden=',Auf.iden);
  writeln('Auf.toto=',Auf.toto);
  writeln('Auf.ArgsCount=',Auf.ArgsCount);

  writeln(isprintable('<WWF#$'));
  writeln(isprintable('WWF#$'));
  writeln(isprintable('<W:WF#$'));
  writeln(isprintable('WW5236,.;F#$'));


  Auf.Script.command('help');
  writeln('----------------------');
  writeln;
  writeln;
  writeln;


  ts:=TStringList.Create;
  //ts.add('mov $1,0');
  //ts.add('aa:');
  //ts.add('add $1,1');
  //ts.add('echo "<"');
  //ts.add('print $1');
  //ts.add('echoln ">" ');
  //ts.add('ncje $1,10,:aa');
  //ts.add('nife $1,10,:aa');
  //ts.add('echoln 44444');
  //ts.add('sqrt $1');
  //ts.add('cwln');
  //ts.add('end');

  //ts.add('mov @0,1234');
  //ts.add('mov @4,12345');
  //ts.add('test $"@@@@@@@@|@D",$"@@@@@@@D|@D"');
  //ts.add('end');

  //以下是内存区置零代码

  ts.Add('mov,@0,32');
  ts.Add('loo:');
  ts.Add('mov $32{0},0000H');
  ts.Add('add @0,32');
  ts.Add('cjl @0,'+Usf.i_to_s(ram_range*256)+',:loo');
  ts.Add('mov $32[0],0000H');
  ts.Add('echoln "done"');
  ts.Add('end');

  //以下是检测高运算次数可行性的代码
  {
  ts.Add('mov @0,0');
  ts.Add('loo:');
  ts.Add('mov @4,@0');
  ts.Add('mod @4,4096');
  ts.Add('ncje @4,0,:skip');
  ts.Add('echoln @0');
  ts.Add('skip:');
  ts.Add('add @0,1');
  ts.Add('jmp :loo');
  }

  Auf.Script.command(ts);

  {
  Usf.fassign('1.txt');
  Usf.freset('1.txt');
  Usf.fwrites('1.txt',4,'aaaaaaaa');
  Usf.fclose('1.txt');
  }

  for i:=0 to ts.Count-1 do
  writeln(ts.Strings[i]);

  writeln('----------------------');
  while true do begin
    write('AufScript>');readln(s);
    Auf.Script.command(s);
    writeln;
  end;

  //////////////////
  //fptr:=@test;
  //Usf.each_file('F:\temp',fptr);
  //////////////////
  readln;

  Application.Run;
  Application.Free;
  {$endif}

end.
