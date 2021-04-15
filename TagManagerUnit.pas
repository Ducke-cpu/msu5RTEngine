unit TagManagerUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Buttons, Vcl.ExtCtrls,
  Vcl.ComCtrls, MSUCore;

type
  TfrmTagManager = class(TForm)
    tmStatusBar: TStatusBar;
    tvTagTree: TTreeView;
    tmSplitter: TSplitter;
    tmListView: TListView;
    tmPanel: TPanel;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    edFindTag: TEdit;
    lbFindTag: TLabel;
    procedure FormShow(Sender: TObject);
    procedure tvTagTreeMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure edFindTagChange(Sender: TObject);
  private
    AllNode : TTreeNode;
    GeneralNode : TTreeNode;
    FCurrentTreeNode : TTreeNode;
    procedure OnSelectTreeNode(ATreeNode : TTreeNode);
    procedure SetCurrentTreeNode(Value : TTreeNode);
    procedure AddMPRArray(AObjLst : TStringList; AParentNode : TTreeNode);
  public
    msu5RTECore : TMSURTECore;
    property CurrentTreeNode : TTreeNode read FCurrentTreeNode write SetCurrentTreeNode;
  end;

var
  frmTagManager: TfrmTagManager;

implementation
uses WatchWindowUnit;
{$R *.dfm}

procedure TfrmTagManager.edFindTagChange(Sender: TObject);
var
  lvItem: TListItem;
begin
  if string(edFindTag.Text).Trim().Equals(string.Empty) then Exit;
  lvItem := tmListView.FindCaption(0,edFindTag.Text,True,True,False);
  if lvItem <> nil then
  begin
    tmListView.Selected := lvItem;
    lvItem.MakeVisible(True);
    //tmListView.SetFocus;
  end;
end;

procedure TfrmTagManager.FormShow(Sender: TObject);
var
  tnParent : TTreeNode;
begin
  tvTagTree.Items.Clear;
  tmListView.Items.Clear;
  if not Assigned(msu5RTECore) then Exit;
  AllNode := tvTagTree.Items.AddChild(nil,'ВСЕ тэги');
  GeneralNode := tvTagTree.Items.AddChild(AllNode,'Общие тэги');
  tnParent := tvTagTree.Items.AddChild(AllNode,'Секции');
  AddMPRArray(msu5RTECore.RTESections,tnParent);
  tnParent := tvTagTree.Items.AddChild(AllNode,'Стрелки');
  AddMPRArray(msu5RTECore.RTEMainPoints,tnParent);
  tnParent := tvTagTree.Items.AddChild(AllNode,'Сигналы');
  AddMPRArray(msu5RTECore.RTESignals,tnParent);
  tnParent := tvTagTree.Items.AddChild(AllNode,'Переезды');
  AddMPRArray(msu5RTECore.RTECrossings,tnParent);
  tnParent := tvTagTree.Items.AddChild(AllNode,'Вершины');
  AddMPRArray(msu5RTECore.RTENodes,tnParent);
  tnParent := tvTagTree.Items.AddChild(AllNode,'Соединения');
  AddMPRArray(msu5RTECore.RTEConnections,tnParent);
  tnParent := tvTagTree.Items.AddChild(AllNode,'Ограждения');
  AddMPRArray(msu5RTECore.RTEFences,tnParent);
  tnParent := tvTagTree.Items.AddChild(AllNode,'Участки приближения');
  AddMPRArray(msu5RTECore.RTECrossPPs,tnParent);
  tnParent := tvTagTree.Items.AddChild(AllNode,'Лунные светофоры');
  AddMPRArray(msu5RTECore.RTEMLs,tnParent);
  tnParent := tvTagTree.Items.AddChild(AllNode,'ДАБ');
  AddMPRArray(msu5RTECore.RTEDABs,tnParent);
  tnParent := tvTagTree.Items.AddChild(AllNode,'ПАБ');
  AddMPRArray(msu5RTECore.RTEPABs,tnParent);
  tnParent := tvTagTree.Items.AddChild(AllNode,'Въездные светофоры');
  AddMPRArray(msu5RTECore.RTEVSSignals,tnParent);
  tnParent := tvTagTree.Items.AddChild(AllNode,'СЭС');
  AddMPRArray(msu5RTECore.RTESysESes,tnParent);
  tnParent := tvTagTree.Items.AddChild(AllNode,'Предохранители');
  AddMPRArray(msu5RTECore.RTEStativ_Fuses,tnParent);
  tnParent := tvTagTree.Items.AddChild(AllNode,'Заградительные светофоры');
  AddMPRArray(msu5RTECore.RTEZSSignals,tnParent);
  tnParent := tvTagTree.Items.AddChild(AllNode,'Дополнительные светофоры');
  AddMPRArray(msu5RTECore.RTEAddSignals,tnParent);
  tnParent := tvTagTree.Items.AddChild(AllNode,'СТП');
  AddMPRArray(msu5RTECore.RTESTPs,tnParent);
  tnParent := tvTagTree.Items.AddChild(AllNode,'Модули ввода/вывода');
  AddMPRArray(msu5RTECore.RTESlaves,tnParent);
  tnParent := tvTagTree.Items.AddChild(AllNode,'Внешние приложения');
  AddMPRArray(msu5RTECore.RTEExtApps,tnParent);
  tvTagTree.Select(GeneralNode);
  CurrentTreeNode := GeneralNode;
end;

procedure TfrmTagManager.AddMPRArray(AObjLst: TStringList; AParentNode: TTreeNode);
var
  i : Integer;
  RTEMatter : TRTEMatter;
begin
  if not Assigned(AObjLst) then Exit;
  if AObjLst.Count > 0 then
  begin
    for i := 0 to AObjLst.Count - 1 do
    begin
      RTEMatter := TRTEMatter(AObjLst.Objects[i]);
      if Assigned(RTEMatter) then
      begin
        tvTagTree.Items.AddChildObject(AParentNode,RTEMatter.Name,RTEMatter);
      end;
    end;//for i
  end; //if
end;

procedure TfrmTagManager.OnSelectTreeNode;
var
  RTEMatter : TRTEMatter;
  RTETag : TRTETag;
  i : Integer;
  LItem : TListItem;
begin
  if not Assigned(ATreeNode) then Exit;
  tmListView.Items.BeginUpdate;
  try
    tmListView.Items.Clear;
    if ATreeNode = AllNode Then
    begin
      if msu5RTECore.GlobalTags.Count > 0 then
      begin
        for i := 0 to msu5RTECore.GlobalTags.Count - 1 do
        begin
          RTETag := TRTETag(msu5RTECore.GlobalTags.Objects[i]);
          LItem := tmListView.Items.Add;
          LItem.Caption := RTETag.Name;
          LItem.SubItems.Add(GetStrTypeDescription(RTETag.TagType));
          LItem.SubItems.Add(RTETag.Description);
          LItem.Data := RTETag;
        end;//for i
      end; //if
      //Exit;
    end
    else
    begin
      if ATreeNode = GeneralNode then
      begin
        if msu5RTECore.GlobalTags.Count > 0 then
        begin
          for i := 0 to msu5RTECore.GlobalTags.Count - 1 do
          begin
            RTETag := TRTETag(msu5RTECore.GlobalTags.Objects[i]);
            if RTETag.OwnedObject = msu5RTECore then
            begin
              LItem := tmListView.Items.Add;
              LItem.Caption := RTETag.Name;
              LItem.SubItems.Add(GetStrTypeDescription(RTETag.TagType));
              LItem.SubItems.Add(RTETag.Description);
              LItem.Data := RTETag;
            end;
          end;//for i
        end; //if
        //Exit;
      end
      else
      begin
        if Assigned(ATreeNode.Data) then
        begin
          RTEMatter := TRTEMatter(ATreeNode.Data);
          if Assigned(RTEMatter) then
          begin
            if msu5RTECore.GlobalTags.Count > 0 then
            begin
              for i := 0 to msu5RTECore.GlobalTags.Count - 1 do
              begin
                RTETag := TRTETag(msu5RTECore.GlobalTags.Objects[i]);
                if RTETag.OwnedObject = RTEMatter then
                begin
                  LItem := tmListView.Items.Add;
                  LItem.Caption := RTETag.Name;
                  LItem.SubItems.Add(GetStrTypeDescription(RTETag.TagType));
                  LItem.SubItems.Add(RTETag.Description);
                  LItem.Data := RTETag;
                end;
              end;//for i
            end; //if
          end;
        end;
      end;
    end;
  finally
    tmListView.Items.EndUpdate;
  end;
end;

procedure TfrmTagManager.tvTagTreeMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if not Assigned(msu5RTECore) then Exit;
  CurrentTreeNode := tvTagTree.GetNodeAt(X,Y);
  if Assigned(CurrentTreeNode) then
    tvTagTree.Select(CurrentTreeNode);
end;

procedure TfrmTagManager.SetCurrentTreeNode(Value: TTreeNode);
begin
  if FCurrentTreeNode <> Value then
  begin
    FCurrentTreeNode := Value;
    OnSelectTreeNode(FCurrentTreeNode);
  end;
end;

end.
