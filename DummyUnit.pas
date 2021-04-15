unit DummyUnit;

interface
uses msu5MPR;

procedure rmbDo2;
procedure rmbDo3;
procedure ShwMes;
procedure pQue;
procedure connDS;

implementation

procedure rmbDo2;
var
  I : Integer;
begin
  I := gv.sesDo_I;
  MPR_RWSESArray.List[I].RMB_OUT := NOT MPR_RWSESArray.List[I].RMB_BUTTON;
end;

procedure rmbDo3;
var
  I : Integer;
begin
  I := gv.sesDo_I;
  MPR_RWSESArray.List[I].RMB_OUT := NOT MPR_RWSESArray.List[I].RMB_BUTTON;
end;

procedure ShwMes;
begin
  Exit;
end;

procedure pQue;
begin
  (*в МСУ2 очередью управляет StationView*)
  gv.pQue_Result := TRUE;
end;

procedure connDS;
begin
  (*в МСУ 2 главный тэг соединения Connection_N формирует StationView*)
  (*в дальнейшем необходимо, чтобы главный тэг соединения стал для StationView readOnly*)
  (*после данных переделок нужно будет включить connDS в список конвертируемых процедур*)
  Exit;
end;

end.
