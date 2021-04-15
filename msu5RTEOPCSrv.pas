unit msu5RTEOPCSrv;

interface
uses
  SysUtils, Classes, prOpcServer, prOpcTypes,Winapi.ActiveX,
  System.Variants;

type
 OPCSrv = class(TOpcItemServer)
  public
    function GetItemInfo(const ItemID: String; var AccessPath: String;
       var AccessRights: TAccessRights): Integer; override;
    procedure ListItemIDs(List: TItemIDList); override;
    function GetItemValue(ItemHandle: TItemHandle;
                            var Quality: Word): OleVariant; override;
    procedure SetItemValue(ItemHandle: TItemHandle; const Value: OleVariant); override;
    procedure OnClientDisconnect(aServer: TClientInfo); override;
    procedure OnClientSetName(aServer: TClientInfo); override;
    procedure OnAddGroup(Group: TGroupInfo); override;
    procedure OnRemoveGroup(Group: TGroupInfo); override;
  end;

function InitOPCSrvAdressSpace : boolean;

var
  msu5OPCSrv : OPCSrv;

implementation
uses
  prOpcError, Windows,  ComCtrls, MSUCore, frmMainUnit, prOpcDa;

const
  ServerGuid: TGUID = '{C74C050F-F8FD-4DC3-8019-7384C79F59DD}';
  ServerVersion = 1;
  ServerDesc = 'msu5RTE';
  ServerVendor = 'OAO VIST GROUP';

var
 rteOPCSrvSymbolList : TStringList;

function OPCSrv.GetItemInfo(const ItemID: string; var AccessPath: string; var AccessRights: TAccessRights): Integer;
var
  ThisTag : TRTETag;
begin
  Result:=rteOPCSrvSymbolList.IndexOf(ItemID);
  if Result < 0 then
  begin
    raise EOpcError.Create(OPC_E_INVALIDITEMID)
  end
  else
  begin
    ThisTag := TRTETag(rteOPCSrvSymbolList.Objects[Result]);
    AccessRights:= [iaRead, iaWrite];
    if not ThisTag.OPCWritable then
        AccessRights:= [iaRead];
  end;
end;

function InitOPCSrvAdressSpace;
var
  i : Integer;
  ThisTag : TRTETag;
//  ARights : set of TAccessRight;
begin
  Result := false;
  rteOPCSrvSymbolList.Clear;
  if not Assigned(frmMSURTEMain) then Exit;
  if not Assigned(frmMSURTEMain.msu5RTECore) then Exit;
  if frmMSURTEMain.msu5RTECore.GlobalTags.Count > 0  then
  begin
    For i := 0 To frmMSURTEMain.msu5RTECore.GlobalTags.Count - 1 do
    begin
      ThisTag := TRTETag(frmMSURTEMain.msu5RTECore.GlobalTags.Objects[i]);
      if ThisTag.IsOPCTag then
      begin
        if not ThisTag.Name.Trim().Equals(string.Empty) Then
        begin
          if frmMSURTEMain.msu5RTECore.MSURTESettings.IsEmulation  then
            if (ThisTag.PLCTagEntry.Phisical) AND (not ThisTag.forCstApps)  then
              if not ThisTag.TagServerTagEntry.IOReadOnly then continue;
          rteOPCSrvSymbolList.AddObject(ThisTag.Name,ThisTag);
        end;
      end;//if ThisTag.IsOPCTag
    end;//for i
    msu5OPCSrv.OPCItemServerState := OPC_STATUS_RUNNING;
  end;//if frmMSURTEMain.msu5RTECore.GlobalTags.Count > 0
  Result := true;
end;

procedure OPCSrv.ListItemIDs(List: TItemIdList);
var
  i : Integer;
  ThisTag : TRTETag;
  ARights : set of TAccessRight;
begin
  if rteOPCSrvSymbolList.Count = 0 then
    InitOPCSrvAdressSpace;
  if rteOPCSrvSymbolList.Count = 0 then Exit;
  for i := 0 to rteOPCSrvSymbolList.Count - 1 do
  begin
    ThisTag := TRTETag(rteOPCSrvSymbolList.Objects[i]);
    ARights := [iaRead];
    if ThisTag.OPCWritable then
      ARights:= [iaRead, iaWrite];
    List.AddItemId(ThisTag.Name,ARights,ThisTag.TagType);
  end;//for i
end;

function OPCSrv.GetItemValue(ItemHandle: Integer; var Quality: Word): OleVariant;
var
  ThisTag : TRTETag;
begin
  if (ItemHandle >= 0) And (ItemHandle < rteOPCSrvSymbolList.Count) then
  begin
    ThisTag := TRTETag(rteOPCSrvSymbolList.Objects[ItemHandle]);
    Result := ThisTag.Value;
    quality:=192;
  end
  else
  begin
    raise EOpcError.Create(OPC_E_INVALIDHANDLE);
  end
end;

procedure OPCSrv.SetItemValue(ItemHandle: Integer; const Value: OleVariant);
var
  ThisTag : TRTETag;
begin
  if (ItemHandle >= 0) And (ItemHandle < rteOPCSrvSymbolList.Count) then
  begin
    ThisTag := TRTETag(rteOPCSrvSymbolList.Objects[ItemHandle]);
    if ThisTag.PhisicalValue then Exit;
    try
      ThisTag.Value := Value;
    except
      Exit;
    end;
  end
  else
  begin
    raise EOpcError.Create(OPC_E_INVALIDHANDLE);
  end
end;

procedure OPCSrv.OnClientSetName(aServer: TClientInfo);
var
  clInfo : TMSUClientInfo;
begin
  clInfo := TMSUClientInfo.Create;
  clInfo.Name := aServer.ClientName;
  frmMSURTEMain.clInfoLst.AddObject(clInfo.Name, clInfo);
  frmMSURTEMain.UpdateClientInfo;
end;


procedure OPCSrv.OnClientDisconnect(aServer: TClientInfo);
var
  clName : String;
  clIdx : Integer;
  clInfo : TMSUClientInfo;
begin
  clName := aServer.ClientName;
  if clName.Equals(string.Empty) then
  begin
    clName := 'Unnamed';
    clIdx := frmMSURTEMain.clInfoLst.IndexOf(clName);
    if clIdx > -1 then
    begin
      clInfo := TMSUClientInfo(frmMSURTEMain.clInfoLst.Objects[clIdx]);
      if clInfo.Groups.Count = 0 then
      begin
        frmMSURTEMain.clInfoLst.Delete(clIdx);
        frmMSURTEMain.UpdateClientInfo;
      end;
    end;
  end
  else
  begin
    clIdx := frmMSURTEMain.clInfoLst.IndexOf(clName);
    if clIdx > -1 then
    begin
      frmMSURTEMain.clInfoLst.Delete(clIdx);
      frmMSURTEMain.UpdateClientInfo;
    end;
  end;
end;

procedure OPCSrv.OnAddGroup(Group: TGroupInfo);
var
  clName : String;
  clIdx : Integer;
  clInfo : TMSUClientInfo;
  grInfo : TMSUGroupInfo;
begin
  clName := Group.ClientInfo.ClientName;
  if clName.Equals(string.Empty) then
  begin
    clName := 'Unnamed';
    clIdx := frmMSURTEMain.clInfoLst.IndexOf(clName);
    if clIdx = -1 then
    begin
      clInfo := TMSUClientInfo.Create;
      clInfo.Name := clName;
      clIdx := frmMSURTEMain.clInfoLst.AddObject(clInfo.Name, clInfo);
    end;
  end
  else
  begin
    clIdx := frmMSURTEMain.clInfoLst.IndexOf(clName);
  end;
  if clIdx > -1 then
  begin
    clInfo := TMSUClientInfo(frmMSURTEMain.clInfoLst.Objects[clIdx]);
    grInfo := TMSUGroupInfo.Create;
    grInfo.Name := Group.Name;
    grInfo.UpdateRate := Group.UpdateRate;
    clInfo.Groups.AddObject(grInfo.Name, grInfo);
    frmMSURTEMain.UpdateClientInfo;
  end;
end;

procedure OPCSrv.OnRemoveGroup(Group: TGroupInfo);
var
  clName : String;
  clIdx : Integer;
  clInfo : TMSUClientInfo;
  grIdx : Integer;
begin
  clName := Group.ClientInfo.ClientName;
  if clName.Equals(string.Empty) then
  begin
    clName := 'Unnamed';
  end;
  clIdx := frmMSURTEMain.clInfoLst.IndexOf(clName);
  if clIdx > -1 then
  begin
    clInfo := TMSUClientInfo(frmMSURTEMain.clInfoLst.Objects[clIdx]);
    if clInfo.Groups.Count > 0 then
    begin
      grIdx := clInfo.Groups.IndexOf(Group.Name);
      if grIdx > -1 then
      begin
        clInfo.Groups.Delete(grIdx);
        frmMSURTEMain.UpdateClientInfo;
      end;
    end;
  end;
end;

initialization
  msu5OPCSrv := OPCSrv.Create;
  msu5OPCSrv.OPCItemServerState := OPC_STATUS_SUSPENDED;
  RegisterOPCServer(ServerGUID, ServerVersion, ServerDesc, ServerVendor, msu5OPCSrv);
  rteOPCSrvSymbolList := TStringList.Create(false);//не удалять
finalization
  rteOPCSrvSymbolList.Free;
end.
