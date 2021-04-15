unit frmMainUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, MSUCore, prOPCClient, Winapi.ActiveX,
  Vcl.StdCtrls, prOPCTypes, Vcl.ExtCtrls, ProcessMetricsUnit, System.Actions,
  Vcl.ActnList, Vcl.Menus, prOpcDa, Vcl.ComCtrls, Vcl.ImgList, AboutF;

type
  TMSUGroupInfo = class
  public
    Name : String;
    UpdateRate : Cardinal;
  end;

  TMSUClientInfo = class
  public
    Name : String;
    Groups : TStringList;
    Constructor Create;
    Destructor Destroy;override;
  end;

  TfrmMSURTEMain = class(TForm)
    MainTimer: TTimer;
    tiRTE: TTrayIcon;
    pmRTE: TPopupMenu;
    ActionList1: TActionList;
    aExit: TAction;
    N1: TMenuItem;
    ShowMainWindow: TAction;
    HideMainWindow: TAction;
    N2: TMenuItem;
    N3: TMenuItem;
    tvClientInfo: TTreeView;
    StatusBar1: TStatusBar;
    ilMain: TImageList;
    pcMain: TPageControl;
    tsOPCClients: TTabSheet;
    tsErrBuffer: TTabSheet;
    lvErrBuf: TListView;
    ilErrBuffer: TImageList;
    pnErrBuffer: TPanel;
    btClear: TButton;
    ClearErrBuffer: TAction;
    N4: TMenuItem;
    ShowWatchWindow: TAction;
    HideWatchWindow: TAction;
    msu5RTEngine1: TMenuItem;
    N5: TMenuItem;
    N6: TMenuItem;
    tshSrvItems: TTabSheet;
    reSrvItems: TRichEdit;
    btDel: TButton;
    Splitter1: TSplitter;
    tvIOTags: TTreeView;
    aAbout: TAction;
    N7: TMenuItem;
    N8: TMenuItem;
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure MainTimerTimer(Sender: TObject);
    procedure aExitExecute(Sender: TObject);
    procedure ShowMainWindowExecute(Sender: TObject);
    procedure HideMainWindowExecute(Sender: TObject);
    procedure StatusBar1Click(Sender: TObject);
    procedure ClearErrBufferExecute(Sender: TObject);
    procedure ShowWatchWindowExecute(Sender: TObject);
    procedure HideWatchWindowExecute(Sender: TObject);
    procedure btDelClick(Sender: TObject);
    procedure aAboutExecute(Sender: TObject);
    procedure AppException(Sender: TObject; E: Exception);
  private
    PM : TProcessMetrics;
    PMCounter : Cardinal;
    //OTICounter : Cardinal;
    //ITICounter : Cardinal;
    ErrMsgCounter : Cardinal;
    WrnMsgCounter : Cardinal;
    InfMsgCounter : Cardinal;
    msgEmptyServerSend : boolean;
    tryPFBConnDelay : Integer;
    pfbRejectedTags : TStringList;
    procedure RejectNonExistentItems(AOPCItemsList : TStringList; AExistentItems : TStringList);
    procedure SetAllTagsToReadOnly (AOPCItemsList : TStringList);
    procedure SetThisTagsAsPhisicalValue (AOPCItemsList : TStringList);
    function TryToConnectPFB : boolean;
    procedure AddIOBranch (ABranchName : string; AIOTagList : TStringList);
    function GetProductVersion (ExeName : PCHar) : String;
  protected
    procedure ReadGroupeDataChange (Sender: TOpcGroup; ItemIndex: Integer; const NewValue: Variant;
                                NewQuality: Word; NewTimestamp: TDateTime);
    procedure sppReadGroupDC (Sender: TOpcGroup; ItemIndex: Integer; const NewValue: Variant;
                                NewQuality: Word; NewTimestamp: TDateTime);
    procedure RefreshOutputs;
    procedure NoClose(var message : TMessage);message WM_NCLBUTTONDOWN;
    procedure OnErrMsg(errStr : string);
    procedure OnWrnMsg (warnStr : string);
    procedure OnInfMsg(InfStr : string);
    function tryToConnectEmulator : boolean;
  public
    VersionStr : String;
    clInfoLst : TStringList;
    msu5RTECore : TMSURTECore;
    Client : TOpcSimpleClient;
    WriteGroup : TOPCGroup;
    SPPClient : TOPCSimpleClient;
    procedure UpdateClientInfo;
  end;
const
  msu5ScanTime = 100;
  mcInterval = 3000;//5 мин.

var
  frmMSURTEMain: TfrmMSURTEMain;

implementation
uses
  msu5RTEOPCSrv,prOpcComn, WatchWindowUnit, TagManagerUnit, ChangeValueUnit, Password, chgPass;
{$R *.dfm}

procedure TfrmMSURTEMain.aExitExecute(Sender: TObject);
begin
  Close;
end;

procedure TfrmMSURTEMain.btDelClick(Sender: TObject);
var
  LItem: TListItem;
begin
  if lvErrBuf.SelCount > 0 then
  begin
    LItem := lvErrBuf.Selected;
    while LItem <> nil do
    begin
      case LItem.ImageIndex of
        0: dec(InfMsgCounter);//Info
        1: dec(WrnMsgCounter);//Warning
        2: dec(ErrMsgCounter);//Error
      end; //case
      lvErrBuf.Selected.Delete;
      LItem := lvErrBuf.GetNextItem(LItem, sdAll, [isSelected]);
    end;//while
  end;
end;

procedure TfrmMSURTEMain.ClearErrBufferExecute(Sender: TObject);
begin
  lvErrBuf.Items.Clear;
  ErrMsgCounter := 0;
  WrnMsgCounter := 0;
  InfMsgCounter := 0;
end;

function TfrmMSURTEMain.TryToConnectPFB;
var
  AllItems : TStringList;
  ThisGroup : TOPCGroup;
  tryCounter : integer;
  SrvStatus : TServerStatus;
  i,q : Integer;
  ioArea : TioArea;
  tagName : String;
  RTESlave : TRTEPFBSlave;
procedure faultExit;
begin
  Client.Disconnect;
  if not msgEmptyServerSend then
  begin
    msgEmptyServerSend := true;
    msu5RTECore.AppLogger.AddWarningMessage('OPC - сервер ' + msu5RTECore.MSURTESettings.OPC_Server_ProgId + ' не содержит ни одного Item-a. Возможно, следует включить питание полевой шины.');
  end;
  if Assigned(AllItems) then
  begin
    AllItems.Free;
    AllItems := nil;
  end;
end;
begin
  Result := false;
  reSrvItems.Lines.Clear;
  pfbRejectedTags.Clear;
  if not Assigned(Client) then Exit;
  try
    Client.Connect(true);
  with Client.OpcServer as IOPCCommon do
    SetClientName(PWideChar('msu5RTEngine'));
  except
     msu5RTECore.AppLogger.AddErrorMessage('Не удалось подключиться к OPC серверу ' + msu5RTECore.MSURTESettings.OPC_Server_ProgId);
  end;
  AllItems := TStringList.Create;
  try
    if Client.Active  then
    begin
      tryCounter := 0;
      repeat
        SrvStatus := Client.GetServerStatus;
        if SrvStatus.ServerState <> OPC_STATUS_RUNNING  then
        begin
          inc(tryCounter);
          sleep(500);
        end;
      until ((tryCounter > 5) OR (SrvStatus.ServerState = OPC_STATUS_RUNNING));
      //проверка на полноту предоставляемых сервером данных
      Client.GetAllItems(AllItems);
      if AllItems.Count > 0 then
      begin
        reSrvItems.Lines.AddStrings(AllItems);
        case msu5RTECore.MSURTESettings.PHL_NameMethod  of
        0,2: //0 - имена по умолчанию, 2 - как в InControl
          begin
            msu5RTECore.IASymbols.Clear;
            msu5RTECore.OASymbols.Clear;
            if msu5RTECore.RTESlaves.Count > 0 then
            begin
              for q := 0 to msu5RTECore.RTESlaves.Count - 1 do
              begin
                RTESlave := TRTEPFBSlave(msu5RTECore.RTESlaves.Objects[q]);
                if Assigned(RTESlave._State)  then
                begin
                  tagName := RTESlave._State.OPCItemName;
                  if AllItems.IndexOf(tagName) > -1 then
                  begin
                    msu5RTECore.IASymbols.AddObject(tagName,RTESlave._State);
                  end
                  else
                  begin
                    //нет смысла искать другие Item-ы, если не найдено слово состояния
                    continue;
                  end;
                end;
                if RTESlave.ioAreas.Count > 0 then
                begin
                  for i := 0 to RTESlave.ioAreas.Count - 1 do
                  begin
                    if AllItems.IndexOf(RTESlave.ioAreas[i]) > -1 then
                    begin
                      ioArea := TioArea(RTESlave.ioAreas.Objects[i]);
                      if ioArea.isOutput then
                      begin
                        msu5RTECore.OASymbols.AddObject(ioArea.Name,ioArea);
                        ioArea.SetTagsAsPhisicalVaue;
                      end
                      else
                      begin
                        msu5RTECore.IASymbols.AddObject(ioArea.Name,ioArea);
                        ioArea.SetTagsAsPhisicalVaue;
                      end;
                    end
                    else
                    begin
                      pfbRejectedTags.AddObject(RTESlave.ioAreas[i], RTESlave.ioAreas.Objects[i]);
                    end;//if Allitems.IndexOf(msu5RTECore.ioAreas[i]) > -1
                  end;//for i
                end;//if msu5RTECore.ioAreas.Count > 0
              end;//for q
              if (msu5RTECore.OASymbols.Count = 0) and (msu5RTECore.IASymbols.Count = 0) then
              begin
                faultExit;
                Exit;
              end;
            end;//if msu5RTECore.RTESlaves.Count > 0
          end ////0 - имена по умолчанию
        else
          begin
            //1 - имена МСУ
             if msu5RTECore.IASymbols.Count > 0 then
                for i := 0 to msu5RTECore.IASymbols.Count - 1 do
                begin
                  case msu5RTECore.MSURTESettings.PHL_CardVendor of
                  1: //Siemens
                    begin
                      tagName := '\SYM:\' + msu5RTECore.IASymbols[i];
                    end
                  else
                    begin
                      tagName := msu5RTECore.IASymbols[i];
                    end;
                  end;//case
                  msu5RTECore.IASymbols[i] := tagName;
                end; //for i
            RejectNonExistentItems(msu5RTECore.IASymbols, AllItems);
            if msu5RTECore.OASymbols.Count > 0 then
                for i := 0 to msu5RTECore.OASymbols.Count - 1 do
                begin
                  case msu5RTECore.MSURTESettings.PHL_CardVendor of
                  1: //Siemens
                    begin
                      tagName := '\SYM:\' + msu5RTECore.OASymbols[i];
                    end
                  else
                    begin
                      tagName := msu5RTECore.OASymbols[i];
                    end;
                  end;//case
                  msu5RTECore.OASymbols[i] := tagName;
                end; //for i
            RejectNonExistentItems(msu5RTECore.OASymbols, AllItems);
          end;//1
        end;//case
      end
      else
      begin
        //Item-ов один или меньше
        faultExit;
        Exit;
      end;//if AllItems.Count > 0 then
      tvIOTags.Items.Clear;
      if (pfbRejectedTags.Count > 0) then
        AddIOBranch('Отсутствующие в OPC-сервере тэги',pfbRejectedTags);
      AddIOBranch('Входные тэги',msu5RTECore.IASymbols);
      if msu5RTECore.IASymbols.Count > 0 then
      begin
        SetThisTagsAsPhisicalValue(msu5RTECore.IASymbols);
        try
          ThisGroup := Client.Groups.Add;
          if Assigned(ThisGroup) then
          begin
            ThisGroup.Name := 'readField';
            ThisGroup.Items.AddStrings(msu5RTECore.IASymbols);
            ThisGroup.UpdateRate := msu5RTECore.MSURTESettings.IOUpdateRate;
            ThisGroup.OnDataChange := ReadGroupeDataChange;
            ThisGroup.Active := true;
          end;
        except
          msu5RTECore.AppLogger.AddErrorMessage('Не удалось добавить группу readField OPC серверу ' + msu5RTECore.MSURTESettings.OPC_Server_ProgId);
        end;
      end;//if msu5RTECore.IASymbols.Count > 0
      AddIOBranch('Выходные тэги',msu5RTECore.OASymbols);
      if msu5RTECore.OASymbols.Count > 0 then
      begin
        SetThisTagsAsPhisicalValue(msu5RTECore.OASymbols);
        try
          ThisGroup := Client.Groups.Add;
          if Assigned(ThisGroup) then
          begin
            ThisGroup.Name := 'writeField';
            ThisGroup.Items.AddStrings(msu5RTECore.OASymbols);
            ThisGroup.UpdateRate := msu5RTECore.MSURTESettings.IOUpdateRate;
            ThisGroup.Active := true;
            WriteGroup := ThisGroup;
          end;
        except
          msu5RTECore.AppLogger.AddErrorMessage('Не удалось добавить группу writeField OPC серверу ' + msu5RTECore.MSURTESettings.OPC_Server_ProgId);
        end;
      end;//if msu5RTECore.OASymbols.Count > 0
      try
        if Client.Groups.Count > 0 then
          Client.ConnectGroups;
        Result := true;
      except
        msu5RTECore.AppLogger.AddErrorMessage('Не удалось выполнить команду присоединения групп к серверу ' + msu5RTECore.MSURTESettings.OPC_Server_ProgId);
      end;
    end;//if Client.Active  then
    finally
      AllItems.Free;
    end;
end;

procedure TfrmMSURTEMain.FormCreate(Sender: TObject);
var
  ThisGroup : TOPCGroup;
  tryCounter : integer;
  SrvStatus : TServerStatus;
  InsppServerTags : TStringList;
begin
  VersionStr := GetProductVersion(PChar(ParamStr(0)));
  Caption := Caption + ' v.' + VersionStr;
  tiRTE.Hint := tiRTE.Hint + ' v.' + VersionStr;
  Application.ShowMainForm := False;
  msgEmptyServerSend := false;
  InfMsgCounter := 0;
  ErrMsgCounter := 0;
  WrnMsgCounter := 0;
  WriteGroup := nil;
  MainTimer.Enabled := false;
  clInfoLst := TStringList.Create(true);
  msu5RTECore := TMSURTECore.Create;
  msu5RTECore.AppLogger.OnErrMsg := OnErrMsg;
  msu5RTECore.AppLogger.OnWrnMsg := OnWrnMsg;
  msu5RTECore.AppLogger.OnInfMsg := OnInfMsg;
  Application.OnException := AppException;
  InsppServerTags := TStringList.Create;
  pfbRejectedTags := TStringList.Create(false);
  //повышение приоритета приложения
  try
    if SetPriorityClass(GetCurrentProcess, HIGH_PRIORITY_CLASS) Then
    begin
       msu5RTECore.AppLogger.AddInfoMessage('Приоритет msu5RTEngine изменен на HIGH_PRIORITY.');
    end
    else
    begin
       msu5RTECore.AppLogger.AddWarningMessage('Не удалось изменить приоритет msu5RTEngine. Ошибка: ' + IntToStr(GetLastError()));
    end;
  except
      msu5RTECore.AppLogger.AddWarningMessage('Сбой при попытке изменить приоритет msu5RTEngine.');
  end;
  try
    msu5RTECore.CreateCoreFromMPR;
    try
      Client:=TOpcSimpleClient.Create(nil);
      Client.ProgID:=msu5RTECore.MSURTESettings.OPC_Server_ProgId;
      msu5RTECore.PFBConnected := false;
      if msu5RTECore.MSURTESettings.IsEmulation  then
      begin
        tshSrvItems.TabVisible := false;
        Client.Connect(true);
        with Client.OpcServer as IOPCCommon do
          SetClientName(PWideChar('msu5RTEngine'));
      end
      else
      begin
        tshSrvItems.TabVisible := true;
        //msu5RTECore.PFBConnected := TryToConnectPFB;
        //tryPFBConnDelay:= msu5RTECore.MSURTESettings.PHL_PFBConnDelay;
        tryPFBConnDelay := 0;
      end;
    except
       msu5RTECore.AppLogger.AddErrorMessage('Не удалось подключиться к OPC серверу ' + msu5RTECore.MSURTESettings.OPC_Server_ProgId);
    end;
    if Assigned(msu5RTECore.MPR) then
      if msu5RTECore.MPR.ESSOLink = '1' then
      begin
        try
          SPPClient := TOpcSimpleClient.Create(nil);
          SPPClient.ProgID := SPPOPC_NAME;
          SPPClient.Connect(true);
          with SPPClient.OpcServer as IOPCCommon do
          SetClientName(PWideChar('msu5RTEngine'));
        except
          msu5RTECore.AppLogger.AddErrorMessage('Не удалось подключиться к OPC серверу ' + SPPOPC_NAME);
        end;
      end;
    try
      PM := TProcessMetrics.Create(PChar(Application.ExeName));
      PMCounter := mcInterval - 600; //определить объем занимаемой памяти через минуту после запуска
    except
      PM := nil;
    end;
    (*if msu5RTECore.MSURTESettings.IsEmulation  then
    begin
      if Client.Active  then
      begin
        tryCounter := 0;
        repeat
          SrvStatus := Client.GetServerStatus;
          if SrvStatus.ServerState <> OPC_STATUS_RUNNING  then
          begin
            inc(tryCounter);
            sleep(500);
          end;
        until ((tryCounter > 5) OR (SrvStatus.ServerState = OPC_STATUS_RUNNING));
        if msu5RTECore.IASymbols.Count > 0 then
        begin
          try
            ThisGroup := Client.Groups.Add;
            if Assigned(ThisGroup) then
            begin
              ThisGroup.Name := 'readField';
              ThisGroup.Items.AddStrings(msu5RTECore.IASymbols);
              ThisGroup.UpdateRate := msu5RTECore.MSURTESettings.IOUpdateRate;
              ThisGroup.Active := true;
              ThisGroup.OnDataChange := ReadGroupeDataChange;
            end;
          except
            msu5RTECore.AppLogger.AddErrorMessage('Не удалось добавить группу readField OPC серверу ' + msu5RTECore.MSURTESettings.OPC_Server_ProgId);
          end;
        end;//if msu5RTECore.IASymbols.Count > 0
        if msu5RTECore.OASymbols.Count > 0 then
        begin
          try
            ThisGroup := Client.Groups.Add;
            if Assigned(ThisGroup) then
            begin
              ThisGroup.Name := 'writeField';
              ThisGroup.Items.AddStrings(msu5RTECore.OASymbols);
              ThisGroup.UpdateRate := msu5RTECore.MSURTESettings.IOUpdateRate;
              ThisGroup.Active := true;
              WriteGroup := ThisGroup;
            end;
          except
            msu5RTECore.AppLogger.AddErrorMessage('Не удалось добавить группу writeField OPC серверу ' + msu5RTECore.MSURTESettings.OPC_Server_ProgId);
          end;
        end;//if msu5RTECore.OASymbols.Count > 0
        try
          if Client.Groups.Count > 0 then
            Client.ConnectGroups;
        except
          msu5RTECore.AppLogger.AddErrorMessage('Не удалось выполнить команду присоединения групп к серверу ' + msu5RTECore.MSURTESettings.OPC_Server_ProgId);
        end;
      end;//if Client.Active  then
    end;//if msu5RTECore.MSURTESettings.IsEmulation  then   *)
    //СПП
    if Assigned(msu5RTECore.MPR) then
      if msu5RTECore.MPR.ESSOLink = '1' then
      begin
        if Assigned(SPPClient) then
        begin
          if SPPClient.Active  then
          begin
            tryCounter := 0;
            repeat
              SrvStatus := SPPClient.GetServerStatus;
              if SrvStatus.ServerState <> OPC_STATUS_RUNNING  then
              begin
                inc(tryCounter);
                sleep(500);
              end;
            until ((tryCounter > 5) OR (SrvStatus.ServerState = OPC_STATUS_RUNNING));
            //здесь нужна проверка на полноту предоставляемых сервером данных
            SPPClient.GetAllItems(InsppServerTags);
            RejectNonExistentItems(msu5RTECore.sppIASymbols, InsppServerTags);
            SetAllTagsToReadOnly (msu5RTECore.sppIASymbols);
            if msu5RTECore.sppIASymbols.Count > 0 then
            begin
              try
                ThisGroup := SPPClient.Groups.Add;
                if Assigned(ThisGroup) then
                begin
                  ThisGroup.Name := 'sppReadOnly';
                  ThisGroup.Items.AddStrings(msu5RTECore.sppIASymbols);
                  ThisGroup.UpdateRate := msu5RTECore.MSURTESettings.sppUpdateRate;
                  ThisGroup.Active := true;
                  ThisGroup.OnDataChange := sppReadGroupDC;
                end;
              except
                msu5RTECore.AppLogger.AddErrorMessage('Не удалось добавить группу sppReadOnly OPC серверу ' + SPPOPC_NAME);
              end;
            end;
            if SPPClient.Groups.Count > 0 then
              SPPClient.ConnectGroups;
          end;//if sppClient.Active  then
        end;//if Assigned(SPPClient) then
      end;//if msu5RTECore.MPR.ESSOLink = '1' then
  finally
    InsppServerTags.Free;
    InsppServerTags := nil;
    MainTimer.Enabled := true;
  end;
end;

procedure TfrmMSURTEMain.FormDestroy(Sender: TObject);
begin
  MainTimer.Enabled := false;
  if Assigned(pfbRejectedTags) then
  begin
    pfbRejectedTags.Free;
    pfbRejectedTags := nil;
  end;
  if Assigned(clInfoLst) then
  begin
    clInfoLst.Free;
    clInfoLst := nil;
  end;
  if Assigned(PM) then
  begin
    PM.Free;
    PM := nil;
  end;
  if Assigned(Client) then
  begin
    Client.Active := false;
    Client.Free;
    Client:=nil;
  end;
  if Assigned(SPPClient) then
  begin
    SPPClient.Active := false;
    SPPClient.Free;
    SPPClient:=nil;
  end;
  If Assigned(msu5RTECore) Then
    msu5RTECore.Free;
end;


procedure TfrmMSURTEMain.HideMainWindowExecute(Sender: TObject);
begin
  Application.MainForm.Visible := false;
end;

procedure TfrmMSURTEMain.HideWatchWindowExecute(Sender: TObject);
begin
  if Assigned(dlgChgPass) then
  begin
    dlgChgPass.Free;
    dlgChgPass := nil;
  end;
  if Assigned(PasswordDlg) then
  begin
    PasswordDlg.Free;
    PasswordDlg := nil;
  end;
  if Assigned(frmTagManager) then
  begin
    frmTagManager.Free;
    frmTagManager := nil;
  end;
  if Assigned(frmChangeValue) then
  begin
    frmChangeValue.Free;
    frmChangeValue := nil;
  end;
  if Assigned(frmWatchWindow) then
  begin
    frmWatchWindow.Close;
    frmWatchWindow.Free;
    frmWatchWindow := nil;
  end;
  ShowWatchWindow.Enabled := true;
  HideWatchWindow.Enabled := false;
end;

procedure TfrmMSURTEMain.MainTimerTimer(Sender: TObject);
var
  SrvStatus : TServerStatus;
begin
  MainTimer.Enabled := false;
  if not msu5RTECore.PFBConnected then
  begin
    if tryPFBConnDelay > 0 then
    begin
      tryPFBConnDelay := tryPFBConnDelay - 1;
    end
    else
    begin
      if msu5RTECore.MSURTESettings.IsEmulation  then
      begin
        msu5RTECore.PFBConnected := tryToConnectEmulator;
        tryPFBConnDelay:= msu5RTECore.MSURTESettings.PHL_PFBConnDelay;
      end
      else
      begin
        msu5RTECore.PFBConnected := TryToConnectPFB;
        tryPFBConnDelay:= msu5RTECore.MSURTESettings.PHL_PFBConnDelay;
      end;
    end;
  end;
  msu5RTECore.Run;
  RefreshOutputs;
  //MainTimer.Interval := msu5ScanTime;
  MainTimer.Interval := msu5RTECore.MSURTESettings.WorkInterval;
  //вычисление вочдога для OPC - серевера производителя
  if msu5RTECore.BOS_WatchDog then
  begin
    //if msu5RTECore.MSURTESettings.IsEmulation OR (not msu5RTECore.MSURTESettings.IsEmulation and msu5RTECore.PFBConnected) then
    if msu5RTECore.PFBConnected then
    begin
      try
        SrvStatus := Client.GetServerStatus;
        if SrvStatus.ServerState = OPC_STATUS_RUNNING  then
        begin
          msu5RTECore.IncBOS_WatchDog;
        end;
      except

      end;
    end;
  end;
  //определение размера занимаемой памяти
  if Assigned (PM) then
  begin
    if PMCounter > mcInterval then
    begin
      PM.Update;
      msu5RTECore.AppLogger.LogEvent('Занимаемая память: ' + IntToStr(PM.MemoryUsageInKb) + ' Кб.');
      PMCounter := 0;
    end
    else
    begin
      inc(PMCounter);
    end;
    //меню
    HideMainWindow.Enabled := Application.MainForm.Visible;
    ShowMainWindow.Enabled := not Application.MainForm.Visible;
    //иконка
    if ErrMsgCounter > 0 then
    begin
      tiRTE.IconIndex := 2
    end
    else
      if WrnMsgCounter > 0 then
      begin
        tiRTE.IconIndex := 1;
      end
      else
        tiRTE.IconIndex := 0;
  end;
  MainTimer.Enabled := true;
end;

procedure TfrmMSURTEMain.ReadGroupeDataChange(Sender: TOpcGroup; ItemIndex: Integer; const NewValue: Variant; NewQuality: Word; NewTimestamp: TDateTime);
var
  RTETag : TRTETag;
begin
  if msu5RTECore.IASymbols.Count = 0 then Exit;
  if ItemIndex > (msu5RTECore.IASymbols.Count - 1) then Exit;

  RTETag := TRTETag(msu5RTECore.IASymbols.Objects[ItemIndex]);
  if Assigned(RTETag) then
  begin
    RTETag.Quality := NewQuality;
    try
      //здесь могут быть нюансы
      RTETag.Value := NewValue;
    except
      msu5RTECore.AppLogger.AddErrorMessage('Для тэга ' + RTETag.Name + ' принято значение, не соответствующее его типу!');
    end;

  end;
end;

procedure TfrmMSURTEMain.sppReadGroupDC(Sender: TOpcGroup; ItemIndex: Integer; const NewValue: Variant; NewQuality: Word; NewTimestamp: TDateTime);
var
  RTETag : TRTETag;
begin
  RTETag := TRTETag(msu5RTECore.sppIASymbols.Objects[ItemIndex]);
  if Assigned(RTETag) then
  begin
    RTETag.Value := NewValue;
  end;
end;

procedure TfrmMSURTEMain.RefreshOutputs;
var
  RTETag : TRTETag;
  i : Integer;
begin
  if not Assigned(msu5RTECore) then Exit;
  if not msu5RTECore.MPRLoaded  then Exit;
  if not msu5RTECore.CoreCreated  then Exit;
  if msu5RTECore.OASymbols.Count = 0 then Exit;
  case msu5RTECore.MSURTESettings.PHL_NameMethod of
  0,2:
    begin
    if msu5RTECore.RTESlaves.Count > 0 then
      for i := 0 to msu5RTECore.RTESlaves.Count - 1 do
      begin
        TRTEPFBSlave(msu5RTECore.RTESlaves.Objects[i]).AssemblyOutputBits;
      end;
    end;
  end;// case
  for i := 0 to msu5RTECore.OASymbols.Count - 1 do
  begin
    RTETag := TRTETag(msu5RTECore.OASymbols.Objects[i]);
    if not Assigned(RTETag) then Continue;
    if RTETag.Changed  then
    begin
      if Assigned(WriteGroup) then
      begin
        try
          WriteGroup.SyncWriteItem(i,RTETag.Value);
        except
          msu5RTECore.AppLogger.AddErrorMessage('Не удалось записать новое значение в тэг: ' + RTETag.Name + '.');
        end;
      end;
      RTETag.Changed := false;
    end;
  end;//for i
end;

procedure TfrmMSURTEMain.ShowMainWindowExecute(Sender: TObject);
begin
  Application.MainForm.Visible := True;
end;

procedure TfrmMSURTEMain.ShowWatchWindowExecute(Sender: TObject);
begin
  if not Assigned(frmWatchWindow) then
  begin
    Application.CreateForm(TfrmWatchWindow, frmWatchWindow);
  end;
  frmWatchWindow.Show;
  ShowWatchWindow.Enabled := false;
  HideWatchWindow.Enabled := true;
end;

procedure TfrmMSURTEMain.StatusBar1Click(Sender: TObject);
begin
  HideMainWindowExecute(Sender);
end;

procedure TfrmMSURTEMain.UpdateClientInfo;
var
  i,j: Integer;
  clInfo : TMSUClientInfo;
  treeNode : TTreeNode;
  grInfo : TMSUGroupInfo;
begin
  tvClientInfo.Items.Clear;
  if clInfoLst.Count > 0 then
  begin
    for i := 0 to clInfoLst.Count - 1 do
    begin
      clInfo := TMSUClientInfo(clInfoLst.Objects[i]);
      treeNode := tvClientInfo.Items.Add(nil,clInfo.Name);
      treeNode := tvClientInfo.Items.AddChild(treeNode,'Группы: ' + IntToStr(clInfo.Groups.Count));
      if clInfo.Groups.Count > 0 then
      begin
        for j := 0 to clInfo.Groups.Count - 1 do
        begin
          grInfo := TMSUGroupInfo(clInfo.Groups.Objects[j]);
          tvClientInfo.Items.AddChild(treeNode,'Имя: ' + grInfo.Name + ' UpdateRate: ' + IntToStr(grInfo.UpdateRate) + ' мс.');
        end;
      end;
    end;
  end;
  tvClientInfo.Refresh;
end;

constructor TMSUClientInfo.Create;
begin
  inherited;
  Groups := TStringList.Create(true);
end;

Destructor TMSUClientInfo.Destroy;
begin
  if Assigned(Groups) then
  begin
    Groups.Free;
    Groups := nil;
  end;
  inherited;
end;

procedure TfrmMSURTEMain.NoClose(var message: TMessage);
begin
  if message.WParam = HTCLOSE then
  begin
    HideMainWindowExecute(Self);
  end
  else
  begin
    inherited;
  end;
end;

procedure TfrmMSURTEMain.RejectNonExistentItems(AOPCItemsList : TStringList; AExistentItems : TStringList);
var
  i : Integer;
begin
  if not Assigned(AOPCItemsList) then Exit;
  if not Assigned(AExistentItems) then Exit;
  if AExistentItems.Count > 0 then
  begin
    if AOPCItemsList.Count > 0 then
    begin
      for i := AOPCItemsList.Count - 1 downto 0 do
      begin
        if AExistentItems.IndexOf(AOPCItemsList[i]) = -1 then
        begin
          msu5RTECore.AppLogger.AddWarningMessage('Тэг: ' + AOPCItemsList[i] + ' был исключен из OPC - группы. Причина: отсутствие тэга в адресном пространстве сервера.');
          pfbRejectedTags.AddObject(AOPCItemsList[i],AOPCItemsList.Objects[i]);
          AOPCItemsList.Delete(i);
        end;
      end;
    end;
  end
  else
  begin
    AOPCItemsList.Clear;
  end;//if ExistentItems.Count > 0
end;

procedure TfrmMSURTEMain.SetAllTagsToReadOnly(AOPCItemsList: TStringList);
var
  RTETag : TRTETag;
  i : Integer;
begin
  if AOPCItemsList.Count > 0 then
  begin
    for i := 0 to AOPCItemsList.Count - 1 do
    begin
      RTETag := TRTETag(AOPCItemsList.Objects[i]);
      RTETag.OPCWritable := false;
    end;
  end;
end;

procedure TfrmMSURTEMain.SetThisTagsAsPhisicalValue(AOPCItemsList: TStringList);
var
  RTETag : TRTETag;
  i : Integer;
begin
  if not Assigned(AOPCItemsList) then Exit;
  if AOPCItemsList.Count > 0 then
  begin
    for i := 0 to AOPCItemsList.Count - 1 do
    begin
      RTETag := TRTETag(AOPCItemsList.Objects[i]);
      if not RTETag.forCstApps  then
        RTETag.PhisicalValue := true;
    end;
  end;
end;

procedure TfrmMSURTEMain.OnErrMsg(errStr: string);
var
  LItem: TListItem;
begin
  LItem := lvErrBuf.Items.Add;
  LItem.Caption := DateTimeToStr(Now) + ' ' + errStr;
  LItem.ImageIndex := 2;
  ErrMsgCounter := ErrMsgCounter + 1;
end;

procedure TfrmMSURTEMain.OnWrnMsg(warnStr: string);
var
  LItem: TListItem;
begin
  LItem := lvErrBuf.Items.Add;
  LItem.Caption := DateTimeToStr(Now) + ' ' + warnStr;
  LItem.ImageIndex := 1;
  WrnMsgCounter := WrnMsgCounter + 1;
end;

procedure TfrmMSURTEMain.OnInfMsg(InfStr: string);
var
  LItem: TListItem;
begin
  LItem := lvErrBuf.Items.Add;
  LItem.Caption := DateTimeToStr(Now) + ' ' + InfStr;
  LItem.ImageIndex := 0;
  InfMsgCounter := InfMsgCounter + 1;
end;

procedure TfrmMSURTEMain.aAboutExecute(Sender: TObject);
begin
  ShowAbout;
end;

procedure TfrmMSURTEMain.AddIOBranch(ABranchName: string; AIOTagList: TStringList);
var
  rootNode, tnIoArea : TTreeNode;
  i,j : Integer;
  RTETag : TRTETag;
  ioArea : TioArea;
begin
  if ABranchName.Equals(string.Empty) then Exit;
  rootNode := tvIOTags.Items.Add(nil,ABranchName);
  if not Assigned(AIOTagList) then Exit;
  if AIOTagList.Count > 0 then
  begin
    for i := 0 to AIOTagList.Count - 1 do
    begin
      RTETag := TRTETag(AIOTagList.Objects[i]);
      tnIoArea := tvIOTags.Items.AddChild(rootNode,AIOTagList[i]);
      if RTETag.ClassType <> TRTETag then
       begin
        ioArea := TioArea(RTETag);
        if Length(ioArea.Bits) > 0 then
        begin
          for j := 0 to High(ioArea.Bits) do
          begin
            RTETag := ioArea.Bits[j];
            if Assigned(RTETag) then
            begin
              tvIOTags.Items.AddChild(tnIoArea,'[' + IntToStr(j) + '] ' + RTETag.Name);
            end;
          end; //for j
        end;
       end;
    end;//for i
  end;

end;

function TfrmMSURTEMain.tryToConnectEmulator;
var
  ThisGroup : TOPCGroup;
  tryCounter : integer;
  SrvStatus : TServerStatus;
begin
  Result := false;
  if Client.Active  then
  begin
    tryCounter := 0;
    repeat
      SrvStatus := Client.GetServerStatus;
      if SrvStatus.ServerState <> OPC_STATUS_RUNNING  then
      begin
        inc(tryCounter);
        sleep(500);
      end;
    until ((tryCounter > 5) OR (SrvStatus.ServerState = OPC_STATUS_RUNNING));
    if (SrvStatus.ServerState <> OPC_STATUS_RUNNING) then Exit;
    if msu5RTECore.IASymbols.Count > 0 then
    begin
      try
        ThisGroup := Client.Groups.Add;
        if Assigned(ThisGroup) then
        begin
          ThisGroup.Name := 'readField';
          ThisGroup.Items.AddStrings(msu5RTECore.IASymbols);
          ThisGroup.UpdateRate := msu5RTECore.MSURTESettings.IOUpdateRate;
          ThisGroup.Active := true;
          ThisGroup.OnDataChange := ReadGroupeDataChange;
        end;
      except
        msu5RTECore.AppLogger.AddErrorMessage('Не удалось добавить группу readField OPC серверу ' + msu5RTECore.MSURTESettings.OPC_Server_ProgId);
      end;
    end;//if msu5RTECore.IASymbols.Count > 0
    if msu5RTECore.OASymbols.Count > 0 then
    begin
      try
        ThisGroup := Client.Groups.Add;
        if Assigned(ThisGroup) then
        begin
          ThisGroup.Name := 'writeField';
          ThisGroup.Items.AddStrings(msu5RTECore.OASymbols);
          ThisGroup.UpdateRate := msu5RTECore.MSURTESettings.IOUpdateRate;
          ThisGroup.Active := true;
          WriteGroup := ThisGroup;
        end;
      except
        msu5RTECore.AppLogger.AddErrorMessage('Не удалось добавить группу writeField OPC серверу ' + msu5RTECore.MSURTESettings.OPC_Server_ProgId);
      end;
    end;//if msu5RTECore.OASymbols.Count > 0
    try
      if Client.Groups.Count > 0 then
        Client.ConnectGroups;
    except
      msu5RTECore.AppLogger.AddErrorMessage('Не удалось выполнить команду присоединения групп к серверу ' + msu5RTECore.MSURTESettings.OPC_Server_ProgId);
    end;
    Result := true;
  end;
end;

function TfrmMSURTEMain.GetProductVersion;
const
   cDot = '.';
 var
     VerInfoSize,
     VerValueSize,
     Dummy          : DWORD;
     VerInfo        : Pointer;
     VerValue      : PVSFixedFileInfo;
     V1, V2, V3, V4 : Word;
 begin
   Result := 'Неизвестно.';
   VerInfoSize := GetFileVersionInfoSize(ExeName,Dummy);
   if (VerInfoSize = 0) then  Exit;
   GetMem(VerInfo, VerInfoSize);
   try
     GetFileVersionInfo(PChar(ParamStr(0)), 0, VerInfoSize,VerInfo);
     if VerQueryValue(VerInfo, '\', Pointer(VerValue), VerValueSize)then
     begin
       if (VerValue <> nil)
         then begin
               with VerValue^ do
               begin
                 V1 := dwFileVersionMS shr 16;
                 V2 := dwFileVersionMS and $FFFF;
                 V3 := dwFileVersionLS shr 16;
                 V4 := dwFileVersionLS and $FFFF;
               end;
               Result := IntToStr(V1)+ cDot +
                         IntToStr(V2)+ cDot +
                         IntToStr(V3)+ cDot +
                         IntToStr(V4);
             end;
     end
   finally
     FreeMem(VerInfo, VerInfoSize);
   end;
 end;

procedure TfrmMSURTEMain.AppException(Sender: TObject; E: Exception);
begin
  msu5RTECore.AppLogger.AddErrorMessage('Необработанное исключение: ' + E.Message);
end;

end.
