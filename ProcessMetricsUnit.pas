unit ProcessMetricsUnit;

interface
uses Windows, Messages, SysUtils,TlHelp32,psAPI;

type
   TProcessMetrics = class
   private
    FQuality : TDateTime;
    FLastUpdateSucces : Boolean;
    FProcessName : String;
    FMemoryUsageInKb : Integer;
    FMemoryUsage : Integer;
    FGlobalMemoryLoad : Integer;
    function IntToMemory(i:Integer):Integer;
    procedure SetLastUpdateSucces (Value : Boolean);
   public
    property LastUpdateSucces : Boolean read FLastUpdateSucces write SetLastUpdateSucces;
    property Quality : TDateTime read FQuality write FQuality;
    property ProcessName : String read FProcessName write FProcessName;
    property MemoryUsageInKb : Integer read FMemoryUsageInKb write FMemoryUsageInKb;
    property MemoryUsage : Integer read FMemoryUsage write FMemoryUsage;
    property GlobalMemoryLoad : Integer read FGlobalMemoryLoad write FGlobalMemoryLoad;
    Constructor Create (ExeName : Pchar);
    procedure Update;
   end;

implementation

Constructor  TProcessMetrics.Create;
begin
  inherited Create;
  ProcessName := UpperCase(ExtractFileName(ExeName));
  FLastUpdateSucces := FALSE;
end;

function TProcessMetrics.IntToMemory(i: Integer): Integer;
begin
  Result:=i div 1024;
end;

procedure TProcessMetrics.Update;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
  h:THandle;
  PMC:TProcessMemoryCounters;
  MS : TMemoryStatus;
begin
  FLastUpdateSucces := FALSE;
  try
     MS.dwLength := SizeOf(MS);
     GlobalMemoryStatus(MS);
     GlobalMemoryLoad := MS.dwMemoryLoad;
     FSnapshotHandle := CreateToolhelp32Snapshot
    (TH32CS_SNAPPROCESS, 0);
    FProcessEntry32.dwSize := Sizeof(FProcessEntry32);
    ContinueLoop := Process32First(FSnapshotHandle,
    FProcessEntry32);
    while integer(ContinueLoop) <> 0 do
    begin
      if UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) = ProcessName then
      begin
        h:=OpenProcess(PROCESS_QUERY_INFORMATION,False,FProcessEntry32.th32ProcessID);
        if GetProcessMemoryInfo(h,@PMC,SizeOf(PMC)) then
        begin
          MemoryUsage := PMC.WorkingSetSize;
          MemoryUsageInKb := IntToMemory(PMC.WorkingSetSize);
        end;
        CloseHandle(h);
        LastUpdateSucces := True;
        break;
      end
      else
      begin
        ContinueLoop := Process32Next(FSnapshotHandle,FProcessEntry32);
      end;
    end;
    CloseHandle(FSnapshotHandle);
  except
    LastUpdateSucces := FALSE;
  end;
end;

procedure TProcessMetrics.SetLastUpdateSucces(Value: Boolean);
begin
  FLastUpdateSucces := Value;
  Quality := Now;
end;

end.
