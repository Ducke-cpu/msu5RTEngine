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
  (*� ���2 �������� ��������� StationView*)
  gv.pQue_Result := TRUE;
end;

procedure connDS;
begin
  (*� ��� 2 ������� ��� ���������� Connection_N ��������� StationView*)
  (*� ���������� ����������, ����� ������� ��� ���������� ���� ��� StationView readOnly*)
  (*����� ������ ��������� ����� ����� �������� connDS � ������ �������������� ��������*)
  Exit;
end;

end.
