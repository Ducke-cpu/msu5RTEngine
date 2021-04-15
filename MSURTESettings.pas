unit MSURTESettings;

interface
uses System.IniFiles,Vcl.Forms,System.SysUtils,System.Win.Registry,Winapi.Windows;

type
TMSURTESettings = class
  private
    FAppLoggerPath : String;
    FMPRFile : String;
    DebugLogsPath_DEF : String;
    TagLogsPath_DEF : String;
    FDaysOld : Integer;
    FMPRFromSV : Boolean;
    FOPC_Server_ProgId : string;
    FIsEmulation : Boolean;
    FTagLogsPath : String;
    FTagLoggingOn : Boolean;
    FWorkInterval : Integer;
    FLogWatchDogs : Boolean;
    FIOUpdateRate : Integer;
    FsppUpdateRate : Integer;
    FNWEnabled : Boolean;
    FPHL_CardName : String;
    FPHL_CardVendor : Integer;
    FPHL_NameMethod : Integer;
    FPHL_PFBConnDelay : Integer;
    FPHL_ModuleNameMethod : Integer;
    FAdmModePass : String;
    function ReadMPRPathFromRegistry : boolean;
  protected
    SVD_PHL_NameMethod : Integer;
    procedure ReadSettingsFromFile;
    function SaveSettingsToFile : Boolean;
  public
    StoreSettingsFile : String;
    property AppLoggerPath : String read FAppLoggerPath;
    property MPRFile : string read FMPRFile;
    property DaysOld : Integer read FDaysOld;
    property MPRFromSV : Boolean read FMPRFromSV;
    property IsEmulation : Boolean read FIsEmulation;
    property OPC_Server_ProgId : string read FOPC_Server_ProgId;
    property TagLogsPath : String read FTagLogsPath;
    property TagLoggingOn : Boolean read FTagLoggingOn;
    property WorkInterval : Integer read FWorkInterval;
    property LogWatchDogs : boolean read FLogWatchDogs;
    property IOUpdateRate : Integer read FIOUpdateRate;
    property sppUpdateRate : Integer read FsppUpdateRate;
    property NWEnabled : Boolean read FNWEnabled write FNWEnabled;
    property PHL_CardName : string read FPHL_CardName;
    property PHL_CardVendor : Integer read FPHL_CardVendor;  //0 - SST; 1 - Siemens
    property PHL_NameMethod : Integer read FPHL_NameMethod write FPHL_NameMethod; //Имена Item - ов в OPC - сервере карты:
    //0 - имена по умолчанию; 1 - имена МСУ; 2 - имена байтов и слов задаются (как в InControl)
    property PHL_PFBConnDelay : Integer read FPHL_PFBConnDelay write FPHL_PFBConnDelay;//задержка (в рабочих циклах) между попытками полключиться к PFB карте
    property PHL_ModuleNameMethod : Integer read FPHL_ModuleNameMethod write FPHL_ModuleNameMethod;//метод именования: 0 -  с применением номера модуля, 1 - без номера модуля
    property AdmModePass : string read FAdmModePass write FAdmModePass;
    Constructor Create;
    Destructor Destroy; override;
end;

const
  DaysOld_DEF = 3;
  MPRFromSV_DEF = TRUE;
  OPC_Server_ProgId_DEF = 'StationEmulator.TseOPCSrv.1';
  IsEmulation_DEF = TRUE;
  TagLoggingOn_DEF = FALSE;
  WorkInterval_DEF = 100;
  LogWatchDogs_DEF = FALSE;
  IOUpdateRate_DEF = 100;
  sppUpdateRate_DEF = 100;
  NWEnabled_DEF = TRUE;
  PHL_CardName_DEF = 'CP 5611';
  PHL_CardVendor_DEF = 1;
  PHL_NameMethod_DEF = 0;
  PHL_PFBConnDelay_DEF = 300;
  PHL_ModuleNameMethod_DEF = 0;
  AdmModePass_DEF = 'bb581ae6e14c688444d538e1d1d05801';//msuscb46rus - https://www.md5online.org/
implementation

Constructor TMSURTESettings.Create;
begin
  inherited;
  StoreSettingsFile := ExtractFileDir(Application.ExeName) + '\' + ChangeFileExt(ExtractFileName(Application.ExeName),'.ini');
  DebugLogsPath_DEF := ExtractFilePath(Application.ExeName) + 'Logs\';
  TagLogsPath_DEF := DebugLogsPath_DEF + 'TagLogging\';
  FDaysOld := DaysOld_DEF;
  ReadSettingsFromFile;
end;

Destructor TMSURTESettings.Destroy;
begin
  SaveSettingsToFile;
  inherited;
end;

procedure TMSURTESettings.ReadSettingsFromFile;
var
  ini : TIniFile;
begin
  try
    ini := TIniFile.Create(StoreSettingsFile);
  except
    Exit;
  end;
  try
    AdmModePass := AdmModePass_DEF;
    FAppLoggerPath := ini.ReadString('General','LogPath', DebugLogsPath_DEF);
    FTagLogsPath := ini.ReadString('General', 'TagLogsPath', TagLogsPath_DEF);
    FMPRFromSV := ini.ReadBool('General','MPRFromSV',MPRFromSV_DEF);
    if MPRFromSV then
    begin
      if not ReadMPRPathFromRegistry then
        FMPRFile := ini.ReadString('General','MPRFile','Station.mpr');
    end
    else
    begin
      FMPRFile := ini.ReadString('General','MPRFile','Station.mpr');
    end;
    FDaysOld := ini.ReadInteger('General','DaysOld',DaysOld_DEF);
    FIsEmulation := ini.ReadBool('General','IsEmulation',IsEmulation_DEF);
    if FIsEmulation = IsEmulation_DEF then
    begin
      FOPC_Server_ProgId := OPC_Server_ProgId_DEF;
    end
    else
    begin
      FOPC_Server_ProgId := ini.ReadString('General','OPC_Server_ProgId',OPC_Server_ProgId_DEF);
    end;
    FTagLoggingOn := ini.ReadBool('General','TagLoggingOn',TagLoggingOn_DEF);
    FWorkInterval := ini.ReadInteger('General','WorkInterval',WorkInterval_DEF);
    FLogWatchDogs := ini.ReadBool('General','LogWatchDogs',LogWatchDogs_DEF);
    FIOUpdateRate := ini.ReadInteger('General','IOUpdateRate', IOUpdateRate_DEF);
    FsppUpdateRate := ini.ReadInteger('General','sppUpdateRate',sppUpdateRate_DEF);
    FNWEnabled := ini.ReadBool('General','NWEnabled',NWEnabled_DEF);
    FPHL_CardName := ini.ReadString('PhysicalLayer', 'CardName', PHL_CardName_DEF);
    FPHL_CardVendor := ini.ReadInteger('PhysicalLayer', 'CardVendor', PHL_CardVendor_DEF);
    FPHL_NameMethod := ini.ReadInteger('PhysicalLayer', 'NameMethod', PHL_NameMethod_DEF);
    SVD_PHL_NameMethod := FPHL_NameMethod;
    FPHL_PFBConnDelay := ini.ReadInteger('PhysicalLayer', 'PFBConnDelay', PHL_PFBConnDelay_DEF);
    FPHL_ModuleNameMethod := ini.ReadInteger('PhysicalLayer', 'ModuleNameMethod', PHL_ModuleNameMethod_DEF);
  finally
    ini.Free;
  end;


end;

function TMSURTESettings.SaveSettingsToFile;
var
  ini : TIniFile;
begin
  Result := False;
  try
    ini := TIniFile.Create(StoreSettingsFile);
  except
    Exit;
  end;
  try
    ini.WriteString('General','LogPath',AppLoggerPath);
    ini.WriteString('General', 'TagLogsPath',TagLogsPath);
    ini.WriteString('General','MPRFile',MPRFile);
    ini.WriteInteger('General','DaysOld',DaysOld);
    ini.WriteBool('General','MPRFromSV',MPRFromSV);
    ini.WriteBool('General','IsEmulation',IsEmulation);
    if FIsEmulation <> IsEmulation_DEF then
      ini.WriteString('General','OPC_Server_ProgId',OPC_Server_ProgId);
    ini.WriteBool('General','TagLoggingOn',TagLoggingOn);
    ini.WriteInteger('General','WorkInterval',WorkInterval);
    ini.WriteBool('General','LogWatchDogs',LogWatchDogs);
    ini.WriteInteger('General','IOUpdateRate',IOUpdateRate);
    ini.WriteInteger('General','sppUpdateRate',sppUpdateRate);
    ini.WriteBool('General','NWEnabled',NWEnabled);
    ini.WriteString('PhysicalLayer', 'CardName', PHL_CardName);
    ini.WriteInteger('PhysicalLayer', 'CardVendor', PHL_CardVendor);
    ini.WriteInteger('PhysicalLayer', 'NameMethod', SVD_PHL_NameMethod);
    ini.WriteInteger('PhysicalLayer', 'PFBConnDelay', PHL_PFBConnDelay);
    ini.WriteInteger('PhysicalLayer', 'ModuleNameMethod', PHL_ModuleNameMethod);
  finally
    ini.Free;
  end;
  Result := True;
end;

function TMSURTESettings.ReadMPRPathFromRegistry;
var
  Registry : TRegistry;
  strKey : string;
begin
  try
    Registry := TRegistry.Create(KEY_READ);
    strKey := 'SOFTWARE\msu5StationMPR';
    try
      Registry.RootKey := HKEY_CURRENT_USER;
      If Registry.KeyExists(strKey) Then
      begin
        if Registry.OpenKey(strKey,true) then
        begin
          FMPRFile := Registry.ReadString('Path');
          FAdmModePass := Registry.ReadString('HPS');
          if FAdmModePass.Equals (string.Empty) then
            AdmModePass := AdmModePass_DEF;
          Registry.CloseKey;
        end;
      end;
      Registry.Free;
    except
      if Assigned(Registry) then
        Registry.Free;
      Exit;
    end;
    Result := true;
  except
    Result := false;
    Exit;
  end;
end;

end.
