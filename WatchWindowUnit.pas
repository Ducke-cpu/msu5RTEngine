unit WatchWindowUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.Grids, Vcl.ExtCtrls,
  Vcl.Menus, System.Actions, Vcl.ActnList, MSUCore, Vcl.StdCtrls, System.SyncObjs, Xml.XMLDoc, Xml.XMLIntf,
  Vcl.ImgList, System.Win.Registry;

type
  TfrmWatchWindow = class(TForm)
    wwStatusBar: TStatusBar;
    pnlWatch: TPanel;
    lvWatch: TListView;
    alWatch: TActionList;
    aAddTag: TAction;
    aExit: TAction;
    mmWatch: TMainMenu;
    miTags: TMenuItem;
    N1: TMenuItem;
    N2: TMenuItem;
    pmWatch: TPopupMenu;
    N3: TMenuItem;
    aDelTag: TAction;
    N4: TMenuItem;
    N5: TMenuItem;
    lbFreq1: TLabel;
    cbFreq: TComboBox;
    lbFreq2: TLabel;
    tmrWatch: TTimer;
    aChangeTag: TAction;
    N6: TMenuItem;
    N7: TMenuItem;
    odWatch: TOpenDialog;
    aOpenWatchList: TAction;
    aSaveWatchList: TAction;
    N8: TMenuItem;
    N9: TMenuItem;
    N10: TMenuItem;
    sdWatch: TSaveDialog;
    ilWatch: TImageList;
    aAdmModeON: TAction;
    aAdmModeOFF: TAction;
    N11: TMenuItem;
    N12: TMenuItem;
    N13: TMenuItem;
    aChangePassword: TAction;
    N14: TMenuItem;
    aChangePassword1: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure aExitExecute(Sender: TObject);
    procedure aAddTagExecute(Sender: TObject);
    procedure lvWatchMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure aDelTagExecute(Sender: TObject);
    procedure tmrWatchTimer(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure aChangeTagExecute(Sender: TObject);
    procedure lvWatchDblClick(Sender: TObject);
    procedure aOpenWatchListExecute(Sender: TObject);
    procedure aSaveWatchListExecute(Sender: TObject);
    procedure aAdmModeONExecute(Sender: TObject);
    procedure aAdmModeOFFExecute(Sender: TObject);
    procedure aChangePasswordExecute(Sender: TObject);
  private
    csWatch : TCriticalSection;
    setsWatch : TXMLDocument;
    FAdmMode : boolean;
    procedure SaveWatchToFile (AFilePath : string);
    procedure OpenWatchFromFile (AFilePath : string);
    procedure SetAdmMode (aValue : boolean);
  protected
    procedure CloseToDestroy(var message : TMessage);message WM_NCLBUTTONDOWN;
  public
    property AdmMode : Boolean read FAdmMode write SetAdmMode;
  end;

const
  cnstCapt = 'Просмотр/изменение значений тэгов.';

var
  frmWatchWindow: TfrmWatchWindow;

implementation
uses frmMainUnit, TagManagerUnit, ChangeValueUnit, Password, chgPass;
{$R *.dfm}

procedure TfrmWatchWindow.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  tmrWatch.Enabled := false;
  frmMSURTEMain.ShowWatchWindow.Enabled := true;
  frmMSURTEMain.HideWatchWindow.Enabled := false;
end;

procedure TfrmWatchWindow.FormCreate(Sender: TObject);
begin
  csWatch := TCriticalSection.Create;
  Application.CreateForm(TfrmTagManager, frmTagManager);
  Application.CreateForm(TfrmChangeValue, frmChangeValue);
  Application.CreateForm(TPasswordDlg, PasswordDlg);
  Application.CreateForm(TdlgChgPass, dlgChgPass);
  if Assigned(frmMSURTEMain) then
    frmTagManager.msu5RTECore := frmMSURTEMain.msu5RTECore;
  setsWatch := TXMLDocument.Create(Self);
  setsWatch.Active := true;
  if Assigned(frmMSURTEMain) then
  begin
    OpenWatchFromFile(ExtractFilePath(frmMSURTEMain.msu5RTECore.MSURTESettings.MPRFile) + 'Watch.lst');
  end;
  FAdmMode := false;
  Caption := cnstCapt + ' Режим: "ПРОСМОТР"';
  aAdmModeON.Enabled := TRUE;
  aAdmModeOFF.Enabled := FALSE;
end;

procedure TfrmWatchWindow.FormDestroy(Sender: TObject);
begin
  if Assigned(frmMSURTEMain) then
  begin
    SaveWatchToFile(ExtractFilePath(frmMSURTEMain.msu5RTECore.MSURTESettings.MPRFile) + 'Watch.lst');
  end;
  if Assigned(setsWatch) then
  begin
    setsWatch.Active := false;
    setsWatch := nil;
  end;
  csWatch.Free;
end;

procedure TfrmWatchWindow.lvWatchDblClick(Sender: TObject);
begin
  aChangeTagExecute(Sender);
end;

procedure TfrmWatchWindow.lvWatchMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  If Button <> mbRight then  Exit;
  pmWatch.Popup (lvWatch.ClientOrigin.x + X , lvWatch.ClientOrigin.y + Y);
end;

procedure TfrmWatchWindow.tmrWatchTimer(Sender: TObject);
var
  LItem : TListItem;
  i : Integer;
  RTETag : TRTETag;
begin
  tmrWatch.Enabled := false;
  csWatch.Enter;
  try
    if lvWatch.Items.Count > 0 then
    begin
      for i := lvWatch.Items.Count - 1 downto 0 do
      begin
        try
          LItem := lvWatch.Items[i];
          if Assigned(LItem.Data) then
          begin
            RTETag := TRTETag(LItem.Data);
            if RTETag.PhisicalValue  then
              LItem.ImageIndex := 1
            else
              LItem.ImageIndex := 2;
            LItem.SubItems[1]:= string(RTETag.Value);
            if RTETag.Forced  then
            begin
              LItem.SubItemImages[1] := 0;
            end
            else
            begin
              LItem.SubItemImages[1] := -1;
            end;
          end;
        except
          continue;
        end;
      end;
    end;
  finally
    csWatch.Leave;
  end;
  try
    tmrWatch.Interval := StrToInt(cbFreq.Text);
  except
    tmrWatch.Interval := 250;
  end;
  tmrWatch.Enabled := true;
end;

procedure TfrmWatchWindow.aAddTagExecute(Sender: TObject);
var
  LItem, SrcItem : TListItem;
  RTETag : TRTETag;
begin
  if frmTagManager.ShowModal = mrOK then
  begin
    if frmTagManager.tmListView.SelCount > 0 then
    begin
      SrcItem := frmTagManager.tmListView.Selected;
      while SrcItem <> nil do
      begin
        if Assigned(SrcItem.Data) then
        begin
          RTETag := TRTETag(SrcItem.Data);
          csWatch.Enter;
          try
            if lvWatch.SelCount > 0 then
            begin
              LItem := lvWatch.Items.Insert(lvWatch.ItemIndex);
            end
            else
            begin
              LItem := lvWatch.Items.Add;
            end;
            LItem.Caption := RTETag.Name;
            LItem.SubItems.Add(GetStrTypeDescription(RTETag.TagType));
            LItem.SubItems.Add(RTETag.Value);
            LItem.SubItems.Add(RTETag.Description);
            LItem.Data := RTETag;
            if RTETag.PhisicalValue  then
              LItem.ImageIndex := 1
            else
              LItem.ImageIndex := 2;
          finally
            csWatch.Leave;
          end;
        end; //if
        SrcItem := frmTagManager.tmListView.GetNextItem(SrcItem, sdAll, [isSelected]);
      end;//while
    end;//if
  end;
end;

procedure TfrmWatchWindow.aAdmModeOFFExecute(Sender: TObject);
begin
  AdmMode := FALSE;
end;

procedure TfrmWatchWindow.aAdmModeONExecute(Sender: TObject);
begin
if PasswordDlg.ShowModal = mrOk then
  AdmMode := TRUE;
end;

procedure TfrmWatchWindow.aChangePasswordExecute(Sender: TObject);
var
  Registry : TRegistry;
  strKey : string;
begin
  if dlgChgPass.ShowModal = mrOK  then
  begin
    if not Assigned(frmMSURTEMain) then Exit;
    try
      Registry := TRegistry.Create(KEY_READ);
      Registry.Access := KEY_WRITE;
      strKey := 'SOFTWARE\msu5StationMPR';
      try
        Registry.RootKey := HKEY_CURRENT_USER;
        If Registry.KeyExists(strKey) Then
        begin
          if Registry.OpenKey(strKey,true) then
          begin
           Registry.WriteString('HPS',frmMSURTEMain.msu5RTECore.MSURTESettings.AdmModePass);
           Registry.CloseKey;
          end;
        end;
        Registry.Free;
      except
        if Assigned(Registry) then
          Registry.Free;
        Exit;
      end;
    except
      Exit;
    end;
  end;
end;

procedure TfrmWatchWindow.aChangeTagExecute(Sender: TObject);
var
  chItem : TListItem;
  CurrentTag : TRTETag;
begin
  if not AdmMode then
  begin
    MessageBox(handle,'В режиме "ПРОСМОТР" изменение тэга недоступно!',PChar(Caption),MB_ICONINFORMATION);
    Exit;
  end;
  case lvWatch.SelCount of
    0:
      begin
        MessageBox(handle,'Для изменения нужно выделить тэг!',PChar(Caption),MB_ICONERROR);
      end;
    1:
      begin
        chItem := lvWatch.Selected;
        if Assigned(chItem.Data) then
        begin
          CurrentTag := TRTETag(chItem.Data);
          frmChangeValue.CurrentTag := CurrentTag;
          frmChangeValue.ShowModal;
        end;
      end
     else
     begin
       MessageBox(handle,'Функция изменения доступна только для одного тэга!',PChar(Caption),MB_ICONERROR);
     end;
  end;
end;

procedure TfrmWatchWindow.aDelTagExecute(Sender: TObject);
var
  DlItem : TListItem;
  DlIndexes : TArray<Integer>;
  i : Integer;
begin
  if lvWatch.SelCount > 0 then
  begin
    i := 0;
    SetLength(DlIndexes,lvWatch.SelCount);
    DlItem := lvWatch.Selected;
    DlIndexes[i] := DlItem.Index;
    while DlItem <> nil do
    begin
      inc(i);
      DlItem := lvWatch.GetNextItem(DlItem, sdAll, [isSelected]);
      if Assigned(DlItem) then
        DlIndexes[i] := DlItem.Index;
    end;
    csWatch.Enter;
    try
      for i := lvWatch.SelCount - 1 downto 0 do
      begin
        lvWatch.Items.Delete(DlIndexes[i]);
      end;
    finally
      csWatch.Leave;
    end;
  end;
end;

procedure TfrmWatchWindow.aExitExecute(Sender: TObject);
begin
  frmMSURTEMain.HideWatchWindowExecute(frmMSURTEMain);
end;

procedure TfrmWatchWindow.aOpenWatchListExecute(Sender: TObject);
begin
  if odWatch.Execute then
  begin
    OpenWatchFromFile(odWatch.FileName);
  end;
end;

procedure TfrmWatchWindow.aSaveWatchListExecute(Sender: TObject);
begin
  if sdWatch.Execute  then
  begin
    SaveWatchToFile(sdWatch.FileName);
  end;
end;

procedure TfrmWatchWindow.CloseToDestroy(var message: TMessage);
begin
  if message.WParam = HTCLOSE then
  begin
    frmMSURTEMain.HideWatchWindowExecute(frmMSURTEMain);
  end
  else
  begin
    inherited;
  end;
end;

procedure TfrmWatchWindow.SaveWatchToFile(AFilePath: string);
var
  LNode: IXMLNode;
  i : Integer;
  LItem : TListItem;
  RTETag : TRTETag;
begin
  if Assigned(setsWatch) then
  begin
    setsWatch.DocumentElement := setsWatch.CreateNode('Tags', ntElement, '');
    if lvWatch.Items.Count > 0 then
    begin
      for i := 0 to lvWatch.Items.Count - 1 do
      begin
        LItem := lvWatch.Items[i];
        if Assigned(LItem.Data) then
        begin
          RTETag := TRTETag(LItem.Data);
          LNode := setsWatch.DocumentElement.AddChild(RTETag.Name);
        end;
      end; //for i
    end;
    setsWatch.SaveToFile(AFilePath);
  end;
end;

procedure TfrmWatchWindow.OpenWatchFromFile(AFilePath: string);
var
  tagsNode: IXMLNode;
  TagNode : IXMLNode;
  TagName : string;
  LItem : TListItem;
  TagIdx : Integer;
  RTETag : TRTETag;
begin
  lvWatch.Items.Clear;
  if Assigned(setsWatch) then
  begin
    if FileExists(AFilePath) then
    begin
      try
        setsWatch.LoadFromFile(AFilePath);
        tagsNode := setsWatch.ChildNodes['Tags'];
        if Assigned(tagsNode) then
        begin
          if tagsNode.ChildNodes.Count > 0 then
          begin
            TagNode := tagsNode.ChildNodes[0];
            while Assigned(TagNode) do
            begin
              TagName := TagNode.NodeName;
              if Assigned(frmMSURTEMain.msu5RTECore) then
              begin
                TagIdx := frmMSURTEMain.msu5RTECore.GlobalTags.IndexOf(TagName);
                if TagIdx > -1 then
                begin
                  RTETag := TRTETag(frmMSURTEMain.msu5RTECore.GlobalTags.Objects[TagIdx]);
                  csWatch.Enter;
                  try
                    LItem := lvWatch.Items.Add;
                    LItem.Caption := TagName;
                    LItem.SubItems.Add(GetStrTypeDescription(RTETag.TagType));
                    LItem.SubItems.Add(RTETag.Value);
                    LItem.SubItems.Add(RTETag.Description);
                    LItem.Data := RTETag;
                    if RTETag.PhisicalValue  then
                      LItem.ImageIndex := 1
                    else
                      LItem.ImageIndex := 2;
                  finally
                    csWatch.Leave;
                  end;
                end;//if TagIdx > -1
              end;//if Assigned(frmMSURTEMain.msu5RTECore)
              TagNode := TagNode.NextSibling;
            end;//while
          end;
        end;
      except
        Exit;
      end;
    end;
  end;
end;

procedure TfrmWatchWindow.SetAdmMode(aValue: Boolean);
begin
  if FAdmMode = aValue then Exit;
  if aValue then
  begin
    Caption := cnstCapt + ' Режим: "ПРОСМОТР/ИЗМЕНЕНИЕ"';
    frmMSURTEMain.msu5RTECore.AppLogger.AddInfoMessage('Режим "ПРОСМОТР/ИЗМЕНЕНИЕ" тэгов ВКЛЮЧЕН.');
    aAdmModeON.Enabled := FALSE;
    aAdmModeOFF.Enabled := TRUE;
  end
  else
  begin
    Caption := cnstCapt + ' Режим: "ПРОСМОТР"';
    frmMSURTEMain.msu5RTECore.AppLogger.AddInfoMessage('Режим "ПРОСМОТР/ИЗМЕНЕНИЕ" тэгов ВЫКЛЮЧЕН.');
    aAdmModeON.Enabled := TRUE;
    aAdmModeOFF.Enabled := FALSE;
  end;
  FAdmMode := aValue;
end;

initialization


end.
