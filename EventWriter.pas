unit EventWriter;

interface
uses Windows,Classes,SyncObjs,Contnrs,SysUtils,DateUtils,Forms,StrUtils,System.IOUtils ;

type
TNeedMakeHeader = procedure of object;

TEventToDiskWriter = class (TThread)
  private
    ThisDay : Word;
    EventsQueue : TStringList;
    CSEvents : TCriticalSection;
    FLogPath : string;
    FDaysOld : Integer;
    FExtention : String;
    procedure ClearArhive;
    procedure WriteEvent (EventStr : String);
  protected
    procedure Execute; override;
    function GetArhiveFileName () : String; virtual;
  public
    property LogPath : string read FLogPath write FLogPath;
    property DaysOld : Integer read FDaysOld write FDaysOld;
    property Extention : String read FExtention write FExtention;
    Constructor Create (CreateSuspended: Boolean);
    destructor Destroy; override;
end;

TProgramLogger = class (TEventToDiskWriter)
  public
    Constructor Create (ALogPath: string);
    function GetArhiveFileName () : String; override;
    procedure LogEvent(LogStr : String);
end;

TOnErrBufMsg = procedure (bufMsg : string) of object;

TProgramLoggerEx = class (TProgramLogger)
  private
    FOnErrMsg : TOnErrBufMsg;
    FOnWrnMsg : TOnErrBufMsg;
    FOnInfMsg : TOnErrBufMsg;
  public
    property OnErrMsg : TOnErrBufMsg read FOnErrMsg write FOnErrMsg;
    property OnWrnMsg : TOnErrBufMsg read FOnWrnMsg write FOnWrnMsg;
    property OnInfMsg : TOnErrBufMsg read FOnInfMsg write FOnInfMsg;
    Constructor Create (ALogPath: string);
    procedure AddErrorMessage (errMess : string);
    procedure AddInfoMessage(infoMess : string);
    procedure AddWarningMessage(warnMess : string);
end;

TArchiveLogger = class (TEventToDiskWriter)
private
  FName : String;
  public
    property Name : String read FName;
    Constructor Create (AName : String; ALogPath: string);
    function GetArhiveFileName () : String; override;
    procedure LogEvent(LogStr : String);
end;

TSSDLogger = class (TEventToDiskWriter)
private
  FName : String;
  FComputerName : String;
  FStationCode : String;
  FNeedMakeHeader : TNeedMakeHeader;
  FFirstRecord : Boolean;
  FisCreateFooter : Boolean;
  function GetStrComputerName : String;
public
  strHeader : TStringList;
  property Name : String read FName;
  property StationCode : String  read FStationCode write FStationCode;
  property ComputerName : String read FComputerName;
  property NeedMakeHeader : TNeedMakeHeader read FNeedMakeHeader write FNeedMakeHeader;
  property FirstRecord : boolean read FFirstRecord write FFirstRecord;
  property isCreateFooter : Boolean read FisCreateFooter write FisCreateFooter;
  Constructor Create (AName : string; ALogPath: string);
  function GetArhiveFileName () : String; override;
  procedure LogEvent(OwnerPrifix : string; Subgr1 : String; Subgr2 : String; Subgr3 : String; TagName : String; TagValue : string; DataType : string; EventType : String);
  procedure LogEventToBaseArchive(Subgr1 : String; Subgr2 : String; Subgr3 : String; TagName : String; TagValue : string; DataType : string; EventType : String);
  procedure SpecialLogEvent(AYear : Word; AMonth : Word; ADay : Word; AHour : Word; AMinute : Word; ASecond : Word; AMillisecond : Word;
  Subgr1 : String; Subgr2 : String; Subgr3 : String; TagName : String; TagValue : string; DataType : string; EventType : String);
  procedure Execute; override;
  function GetArchiveFileNameFromMessage(AMes : String) : String;
  procedure MakeHeader (var wrF : TextFile);
  destructor Destroy; override;
end;

TExtentionArchiveLogger = class (TEventToDiskWriter)
  public
    Constructor Create (ALogPath: string; AExt : string);
    function GetArhiveFileName () : String; override;
    procedure LogEvent(LogStr : String);
end;

implementation

Constructor TEventToDiskWriter.Create(CreateSuspended: Boolean);
begin
  FExtention := '.txt';
  EventsQueue := TStringList.Create;
  CSEvents := TCriticalSection.Create;
  inherited Create (CreateSuspended);
  ThisDay := 0;
end;

Destructor TEventToDiskWriter.Destroy;
begin
  Terminate;
  If EventsQueue.Count > 0 Then
    Execute;
  EventsQueue.Free;
  CSEvents.Free;
  inherited;
end;

procedure TEventToDiskWriter.Execute;
var
    f : TextFile;
    ArhiveFileName : String;
  begin
    repeat
      ArhiveFileName := GetArhiveFileName();
      If Length (ArhiveFileName) = 0 Then Continue;
      If EventsQueue.Count > 0 Then
      begin
        AssignFile(f,ArhiveFileName);
        if not DirectoryExists(ExtractFilePath(ArhiveFileName)) then
        begin
          try
            //CreateDirectory(PChar(ExtractFilePath(ArhiveFileName)),nil);
            TDirectory.CreateDirectory(ExtractFilePath(ArhiveFileName));
          except
            continue;
          end;
          try
            Rewrite(f);
          except
            Continue;
          end;
        end
        else
        begin
          if FileExists(ArhiveFileName) then
          begin
            try
              Append(f);
            except
              {try
                Rewrite(f);
              except
                Continue;
              end; }
              Continue;
            end;
          end
          else
          begin
            try
              Rewrite(f);
            except
              Continue;
            end;
          end;
        end;
        CSEvents.Enter;
        While EventsQueue.Count > 0 do
        begin
          try
            Writeln(f,EventsQueue[0]);
            EventsQueue.Delete(0);
          except
            Continue;
          end;
        end;
        CSEvents.Leave;
        try
          CloseFile(f);
        except
          Continue;
        end;
      end;
      try
        ClearArhive;
      except
        //
      end;
      If Terminated Then break;
      Sleep(1000);
    until Terminated;
  end;

procedure TEventToDiskWriter.WriteEvent(EventStr: string);
begin
  if not Assigned(CSEvents) Then Exit;
  CSEvents.Enter;
  try
    if Assigned(EventsQueue) then
      EventsQueue.Add (EventStr);
  finally
    CSEvents.Leave;
  end;
end;

function TEventToDiskWriter.GetArhiveFileName;
begin
  Result := '';
end;

Constructor TProgramLogger.Create(ALogPath: string);
begin
  inherited Create(False);
  FLogPath := ALogPath;
end;

function TProgramLogger.GetArhiveFileName;
var
    TmpStr : String;
    Year,Month,Day : Word;
  begin
    Result := '';
    DecodeDate(NOW,Year,Month,Day);
    TmpStr := FLogPath + Forms.Application.Title;
    TmpStr := TmpStr + IntToStr(Year) + '-' +
    IntToStr(Month) + '-' + IntToStr(Day) + '.log';
    Result := TmpStr;
  end;
procedure TProgramLogger.LogEvent(LogStr: string);
var
    BYear,BMonth,BDay,BHour,BMinute,BSecond,BMilliSecond : Word;
    DateTimeStr : String;
  begin
     DecodeDateTime(Now,BYear,BMonth,BDay,BHour,BMinute,BSecond,BMilliSecond);
     If BDay >= 10 Then
      DateTimeStr := IntToStr(BDay) + '.'
     else
      DateTimeStr := '0'+IntToStr(BDay) + '.';
     IF BMonth >= 10 Then
      DateTimeStr := DateTimeStr + IntToStr(BMonth) + '.'
     else
      DateTimeStr := DateTimeStr + '0' + IntToStr(BMonth) + '.';
     DateTimeStr := DateTimeStr + IntToStr(BYear) + ' ';
     If BHour >= 10 Then
      DateTimeStr := DateTimeStr + IntToStr(BHour) + ':'
     else
      DateTimeStr := DateTimeStr + '0' + IntToStr(BHour) + ':';
     If BMinute >= 10 Then
      DateTimeStr := DateTimeStr + IntToStr(BMinute) + ':'
     else
      DateTimeStr := DateTimeStr + '0' + IntToStr(BMinute) + ':';
     If BSecond >= 10 Then
      DateTimeStr := DateTimeStr + IntToStr(BSecond) + ':'
     else
      DateTimeStr := DateTimeStr + '0' + IntToStr(BSecond) + ':';
     DateTimeStr := DateTimeStr + IntToStr (BMilliSecond) + ' ';
     WriteEvent(DateTimeStr + ' ' + Forms.Application.Title + ': ' + LogStr);
  end;

Constructor TArchiveLogger.Create;
begin
  inherited Create (False);
  FLogPath := ALogPath;
  FName := AName;
end;

function TArchiveLogger.GetArhiveFileName;
var
    TmpStr : String;
    Year,Month,Day : Word;
  begin
    Result := '';
    DecodeDate(NOW,Year,Month,Day);
    TmpStr := FLogPath + Name;
    TmpStr := TmpStr + IntToStr(Year) + '-' +
    IntToStr(Month) + '-' + IntToStr(Day) + Extention;
    Result := TmpStr;
  end;
procedure TArchiveLogger.LogEvent(LogStr: string);
var
    BYear,BMonth,BDay,BHour,BMinute,BSecond,BMilliSecond : Word;
    DateTimeStr : String;
  begin
     DecodeDateTime(Now,BYear,BMonth,BDay,BHour,BMinute,BSecond,BMilliSecond);
     If BDay >= 10 Then
      DateTimeStr := IntToStr(BDay) + '.'
     else
      DateTimeStr := '0'+IntToStr(BDay) + '.';
     IF BMonth >= 10 Then
      DateTimeStr := DateTimeStr + IntToStr(BMonth) + '.'
     else
      DateTimeStr := DateTimeStr + '0' + IntToStr(BMonth) + '.';
     DateTimeStr := DateTimeStr + IntToStr(BYear) + ' ';
     If BHour >= 10 Then
      DateTimeStr := DateTimeStr + IntToStr(BHour) + ':'
     else
      DateTimeStr := DateTimeStr + '0' + IntToStr(BHour) + ':';
     If BMinute >= 10 Then
      DateTimeStr := DateTimeStr + IntToStr(BMinute) + ':'
     else
      DateTimeStr := DateTimeStr + '0' + IntToStr(BMinute) + ':';
     If BSecond >= 10 Then
      DateTimeStr := DateTimeStr + IntToStr(BSecond) + ':'
     else
      DateTimeStr := DateTimeStr + '0' + IntToStr(BSecond) + ':';
     DateTimeStr := DateTimeStr + IntToStr (BMilliSecond) + ' ';
     WriteEvent(DateTimeStr + ' ' + LogStr);
  end;

Constructor TSSDLogger.Create;
begin
  inherited Create (False);
  FLogPath := ALogPath;
  FName := AName;
  FStationCode := '0';
  FComputerName := GetStrComputerName;
  FNeedMakeHeader := nil;
  strHeader := TStringList.Create;
  FFirstRecord := true;
  FisCreateFooter := true;
end;

function TSSDLogger.GetArhiveFileName;
var
    TmpStr : String;
    Year,Month,Day : Word;
  begin
    Result := '';
    DecodeDate(NOW,Year,Month,Day);
    TmpStr := FLogPath + Name;
    TmpStr := TmpStr + IntToStr(Year) + '-' +
    IntToStr(Month) + '-' + IntToStr(Day) + '.txt';
    Result := TmpStr;
  end;
procedure TSSDLogger.LogEvent;
var
    BYear,BMonth,BDay,BHour,BMinute,BSecond,BMilliSecond : Word;
    SSDStr : String;
  begin
     SSDStr := 'Station' + StationCode + '@';
     DecodeDateTime(Now,BYear,BMonth,BDay,BHour,BMinute,BSecond,BMilliSecond);
     SSDStr := SSDStr + IntToStr(BYear) + '@';
     SSDStr := SSDStr + IntToStr(BMonth) + '@';
     SSDStr := SSDStr + IntToStr(BDay) + '@';
     SSDStr := SSDStr + IntToStr(BHour) + '@';
     SSDStr := SSDStr + IntToStr(BMinute) + '@';
     SSDStr := SSDStr + IntToStr(BSecond) + '@';
     SSDStr := SSDStr + IntToStr (BMilliSecond) + '@';
     SSDStr := SSDStr + '4@';//Группа ССД
     SSDStr := SSDStr + Subgr1 + '@';//подгруппа 1
     SSDStr := SSDStr + Subgr2 + '@';//подгруппа 2
     SSDStr := SSDStr + Subgr3 + '@';//подгруппа 3
     SSDStr := SSDStr + OwnerPrifix + ':' + TagName + '@'; //код тэга
     SSDStr := SSDStr + TagValue + '@'; //значение тэга
     SSDStr := SSDStr + '0@'; //Отметка по регистрации(служебное)
     SSDStr := SSDStr + DataType + '@'; //Тип данных: 0 - текст, 1 - целое, 2 - с плавающей запятой.
     SSDStr := SSDStr + '0@'; //Значение тэга как числа с плавающей запятой
     SSDStr := SSDStr + EventType + '@'; //Вид события: 0,1,2 - обычный 3 - не писать в БД, 4 - восстанавливаемый тэг.
     SSDStr := SSDStr + DateTimeToStr(Now) + '@'; //Дата регистрации
     SSDStr := SSDStr + '0@';//смена
     SSDStr := SSDStr + DateTimeToStr(Now) + '@'; //Отчетные сутки
     WriteEvent(SSDStr);
  end;

procedure TSSDLogger.LogEventToBaseArchive;
var
    BYear,BMonth,BDay,BHour,BMinute,BSecond,BMilliSecond : Word;
    SSDStr : String;
  begin
     SSDStr := 'Station' + StationCode + '@';
     DecodeDateTime(Now,BYear,BMonth,BDay,BHour,BMinute,BSecond,BMilliSecond);
     SSDStr := SSDStr + IntToStr(BYear) + '@';
     SSDStr := SSDStr + IntToStr(BMonth) + '@';
     SSDStr := SSDStr + IntToStr(BDay) + '@';
     SSDStr := SSDStr + IntToStr(BHour) + '@';
     SSDStr := SSDStr + IntToStr(BMinute) + '@';
     SSDStr := SSDStr + IntToStr(BSecond) + '@';
     SSDStr := SSDStr + IntToStr (BMilliSecond) + '@';
     SSDStr := SSDStr + '4@';//Группа ССД
     SSDStr := SSDStr + Subgr1 + '@';//подгруппа 1
     SSDStr := SSDStr + Subgr2 + '@';//подгруппа 2
     SSDStr := SSDStr + Subgr3 + '@';//подгруппа 3
     SSDStr := SSDStr + TagName + '@'; //код тэга
     SSDStr := SSDStr + Trim(TagValue) + '@'; //значение тэга
     SSDStr := SSDStr + '0@'; //Отметка по регистрации(служебное)
     SSDStr := SSDStr + DataType + '@'; //Тип данных: 0 - текст, 1 - целое, 2 - с плавающей запятой.
     SSDStr := SSDStr + '0@'; //Значение тэга как числа с плавающей запятой
     SSDStr := SSDStr + EventType + '@'; //Вид события: 0,1,2 - обычный 3 - не писать в БД, 4 - восстанавливаемый тэг.
     SSDStr := SSDStr + DateTimeToStr(Now) + '@'; //Дата регистрации
     SSDStr := SSDStr + '0@';//смена
     SSDStr := SSDStr + DateTimeToStr(Now) + '@'; //Отчетные сутки
     WriteEvent(SSDStr);
  end;

procedure TSSDLogger.SpecialLogEvent;
var
    SSDStr : String;
    DateTimeStr : String;
    BYear,BMonth,BDay,BHour,BMinute,BSecond,BMilliSecond : String;
  begin
     try
      BYear := IntToStr(AYear);
      BMonth := IntToStr(AMonth);
      BDay := IntToStr(ADay);
      BHour := IntToStr(AHour);
      BMinute := IntToStr(AMinute);
      BSecond := IntToStr(ASecond);
      BMilliSecond := IntToStr(AMillisecond);
     except
      Exit;
     end;
     SSDStr := 'Station' + StationCode + '@';
     SSDStr := SSDStr + BYear + '@';
     SSDStr := SSDStr + BMonth + '@';
     SSDStr := SSDStr + BDay + '@';
     SSDStr := SSDStr + BHour + '@';
     SSDStr := SSDStr + BMinute + '@';
     SSDStr := SSDStr + BSecond + '@';
     SSDStr := SSDStr + BMilliSecond + '@';
     SSDStr := SSDStr + '4@';//Группа ССД
     SSDStr := SSDStr + Subgr1 + '@';//подгруппа 1
     SSDStr := SSDStr + Subgr2 + '@';//подгруппа 2
     SSDStr := SSDStr + Subgr3 + '@';//подгруппа 3
     SSDStr := SSDStr + TagName + '@'; //код тэга
     SSDStr := SSDStr + Trim(TagValue) + '@'; //значение тэга
     SSDStr := SSDStr + '0@'; //Отметка по регистрации(служебное)
     SSDStr := SSDStr + DataType + '@'; //Тип данных: 0 - текст, 1 - целое, 2 - с плавающей запятой.
     SSDStr := SSDStr + '0@'; //Значение тэга как числа с плавающей запятой
     SSDStr := SSDStr + EventType + '@'; //Вид события: 0,1,2 - обычный 3 - не писать в БД, 4 - восстанавливаемый тэг.
     //SSDStr := SSDStr + DateTimeToStr(Now) + '@'; //Дата регистрации
     If ADay >= 10 Then
      DateTimeStr := BDay + '.'
     else
      DateTimeStr := '0'+ BDay + '.';
     IF AMonth >= 10 Then
      DateTimeStr := DateTimeStr + BMonth + '.'
     else
      DateTimeStr := DateTimeStr + '0' + BMonth + '.';
     DateTimeStr := DateTimeStr + BYear + ' ';
     If AHour >= 10 Then
      DateTimeStr := DateTimeStr + BHour + ':'
     else
      DateTimeStr := DateTimeStr + '0' + BHour + ':';
     If AMinute >= 10 Then
      DateTimeStr := DateTimeStr + BMinute + ':'
     else
      DateTimeStr := DateTimeStr + '0' + BMinute + ':';
     If ASecond >= 10 Then
      DateTimeStr := DateTimeStr + BSecond + ':'
     else
      DateTimeStr := DateTimeStr + '0' + BSecond + ':';
     DateTimeStr := DateTimeStr + BMilliSecond + ' ';
     SSDStr := SSDStr + DateTimeStr + '@'; //Дата регистрации
     SSDStr := SSDStr + '0@';//смена
     //SSDStr := SSDStr + DateTimeToStr(Now) + '@'; //Отчетные сутки
     SSDStr := SSDStr + DateTimeStr + '@'; //Отчетные сутки
     WriteEvent(SSDStr);
  end;

function TSSDLogger.GetStrComputerName;
var
  StrCompName : array[0..MAX_COMPUTERNAME_LENGTH] of Char;
  CompNameLen : DWORD;
begin
  CompNameLen := MAX_COMPUTERNAME_LENGTH + 1;
  IF GetComputerName (@StrCompName,CompNameLen) then
    Result := Copy(StrCompName,1,CompNameLen)
  else
    Result := 'Unnamed';
end;

procedure TEventToDiskWriter.ClearArhive;
  var
    AYear,AMonth,ADay : Word;
    FYear, FMonth, FDay : Word;
    PathStr : String;
    DelPath : String;
    SR : TSearchRec;
    TirePos : Integer;
    ThisFileName : String;
    LastFileName : String;
    tmpStr : String;
    FileDate : TDateTime;
    DaysOfInterval : Integer;
  begin
    If DaysOld = 0 Then Exit;
    DecodeDate(NOW,AYear,AMonth,ADay);
    If ADay = ThisDay Then Exit;
    FDay := 0;
    FMonth := 0;
    FYear := 0;
    ThisDay := ADay;
    DelPath := LogPath;
    //if self.ClassNameIs('TProgramLogger') then
    if Pos('TProgramLogger', self.ClassName) > 0 then
      PathStr := LogPath + '*.log'
    else
      PathStr := LogPath + '*.txt';
    LastFileName := '';
    FindFirst(PathStr,faAnyFile,SR);
    While SR.Name <> LastFileName Do
    begin
      ThisFileName := SR.Name;
      LastFileName := SR.Name;
      //year
      TirePos := Pos('-',ThisFileName);
      tmpStr := Copy(ThisFileName,1,TirePos - 1);
      If (Length(tmpStr) > 4) then
      begin
        tmpStr := RightStr(tmpStr,4);
      end;
      try
        FYear := StrToInt(tmpStr);
      except
        FindNext(SR);
        Continue;
      end;
      Delete(ThisFileName,1,TirePos);
      //Month
      TirePos := Pos('-',ThisFileName);
      tmpStr := Copy(ThisFileName,1,TirePos - 1);
      try
        FMonth := StrToInt(tmpStr);
      except
        FindNext(SR);
        Continue;
      end;
      Delete(ThisFileName,1,TirePos);
      //Day
      TirePos := Pos('.',ThisFileName);
      tmpStr := Copy(ThisFileName,1,TirePos - 1);
      try
        FDay := StrToInt(tmpStr);
      except
        FindNext(SR);
        Continue;
      end;
      FileDate := EncodeDate(FYear,FMonth,FDay);
      DaysOfInterval := DaysBetween(Now,FileDate);
      If DaysOfInterval > DaysOld Then
      begin
        try
          DeleteFile (DelPath + SR.Name);
          //WriteEvent('Удален файл ' + SR.Name);
        except
          //WriteEvent('НЕ удалось удалить файл ' + SR.Name);
          FindNext(SR);
          Continue;
        end;
      end;
      FindNext(SR);
    end;
    FindClose(SR);
  end;
procedure TSSDLogger.Execute;
var
    f : TextFile;
    ArhiveFileName : String;
  begin
    repeat
      If EventsQueue.Count > 0 Then
      begin
        CSEvents.Enter;
        While EventsQueue.Count > 0 do
        begin
          ArhiveFileName := GetArchiveFileNameFromMessage(EventsQueue[0]);
          AssignFile(f,ArhiveFileName);
          if not DirectoryExists(ExtractFilePath(ArhiveFileName)) then
          begin
            try
              TDirectory.CreateDirectory(ExtractFilePath(ArhiveFileName));
            except
              continue;
            end;
            try
              Rewrite(f);
            except
              Continue;
            end;
          end
          else
          begin
            if FileExists(ArhiveFileName) then
            begin
              try
                Append(f);
                if FirstRecord then
                begin
                  isCreateFooter := false;
                  MakeHeader(f);
                  FirstRecord := false;
                end;
              except
                try
                  Rewrite(f);
                except
                  Continue;
                end;
                isCreateFooter := true;
                MakeHeader(f);
              end;
            end
            else
            begin
              //новый файл
              try
                Rewrite(f);
              except
                Continue;
              end;
              isCreateFooter := true;
              MakeHeader(f);
            end;
          end;
          try
            Writeln(f,EventsQueue[0]);
            EventsQueue.Delete(0);
            FirstRecord := false;
          except
            Continue;
          end;
          try
            CloseFile(f);
          except
            Continue;
          end;
        end;
        CSEvents.Leave;
      end;
      try
        ClearArhive;
      except
        //
      end;
      If Terminated Then break;
      Sleep(1000);
    until Terminated;
  end;

function TSSDLogger.GetArchiveFileNameFromMessage;
var
  spltArray : TArray<String>;
begin
  Result := FLogPath + Name;
  spltArray := AMes.Split(['@']);
  if Length(spltArray) > 5 then
    Result := Result + spltArray[1] + '-' + spltArray[2] + '-' + spltArray[3] + '.txt';
end;

procedure TSSDLogger.MakeHeader;
var
  i : Integer;
  BYear,BMonth,BDay,BHour,BMinute,BSecond,BMilliSecond : Word;
  SSDStr : String;
begin
  strHeader.Clear;
  if Assigned(FNeedMakeHeader) Then
    synchronize(FNeedMakeHeader);
  if strHeader.Count > 0 then
  begin
    for i := 0 to strHeader.Count - 1 do
    begin
      writeln(wrF,strHeader[i]);
    end;
  end;

end;

destructor TSSDLogger.Destroy;
begin
  strHeader.Free;
  inherited;
end;

constructor TExtentionArchiveLogger.Create;
begin
  inherited Create(False);
  FLogPath := ALogPath;
  Extention := AExt;
end;

function TExtentionArchiveLogger.GetArhiveFileName;
var
    TmpStr : String;
    Year,Month,Day : Word;
    StrMonth : String;
    StrDay : String;
  begin
    Result := '';
    DecodeDate(NOW,Year,Month,Day);
    StrMonth := IntToStr(Month);
    if Month < 10 Then
      StrMonth := '0' + StrMonth;
    StrDay := IntToStr(Day);
    if Day < 10 Then
      StrDay := '0' + StrDay;
    TmpStr := FLogPath + IntToStr(Year) + '-' +
    StrMonth + '-' + StrDay + Extention;
    Result := TmpStr;
  end;

procedure TExtentionArchiveLogger.LogEvent;
var
    BYear,BMonth,BDay,BHour,BMinute,BSecond,BMilliSecond : Word;
    DateTimeStr : String;
  begin
     DecodeDateTime(Now,BYear,BMonth,BDay,BHour,BMinute,BSecond,BMilliSecond);
     { DateTimeStr := Format('%.2d.%.2d.%.4d %.2d:%.2d:%.2d.%.3d',[BDay, BMonth, BYear, BHour, BMinute, BSecond, BMilliSecond]) + ' ';}
     If BDay >= 10 Then
      DateTimeStr := IntToStr(BDay) + '.'
     else
      DateTimeStr := '0'+IntToStr(BDay) + '.';
     IF BMonth >= 10 Then
      DateTimeStr := DateTimeStr + IntToStr(BMonth) + '.'
     else
      DateTimeStr := DateTimeStr + '0' + IntToStr(BMonth) + '.';
     DateTimeStr := DateTimeStr + IntToStr(BYear) + ' ';
     If BHour >= 10 Then
      DateTimeStr := DateTimeStr + IntToStr(BHour) + ':'
     else
      DateTimeStr := DateTimeStr + '0' + IntToStr(BHour) + ':';
     If BMinute >= 10 Then
      DateTimeStr := DateTimeStr + IntToStr(BMinute) + ':'
     else
      DateTimeStr := DateTimeStr + '0' + IntToStr(BMinute) + ':';
     If BSecond >= 10 Then
      DateTimeStr := DateTimeStr + IntToStr(BSecond) + ':'
     else
      DateTimeStr := DateTimeStr + '0' + IntToStr(BSecond) + ':';
     DateTimeStr := DateTimeStr + IntToStr (BMilliSecond) + ' ';
     WriteEvent(DateTimeStr + ' ' + LogStr);
  end;

procedure TProgramLoggerEx.AddErrorMessage;
begin
  LogEvent('[ОШИБКА]: ' + errMess);
  if Assigned(FOnErrMsg) then
    FOnErrMsg(errMess);
end;

procedure TProgramLoggerEx.AddInfoMessage;
begin
  LogEvent(infoMess);
  if Assigned(FOnInfMsg) then
    FOnInfMsg(infoMess);
end;

procedure TProgramLoggerEx.AddWarningMessage;
begin
  LogEvent('[ПРЕДУПРЕЖДЕНИЕ]: ' + warnMess);
  if Assigned(FOnWrnMsg) then
    FOnWrnMsg(warnMess);
end;

Constructor TProgramLoggerEx.Create(ALogPath: string);
begin
  inherited Create(ALogPath);
  FOnErrMsg := nil;
  FOnWrnMsg := nil;
  FOnInfMsg := nil;
end;

end.
