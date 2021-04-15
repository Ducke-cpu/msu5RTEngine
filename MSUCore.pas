unit MSUCore;

interface
uses MSURTESettings, EventWriter, SpacialLib, System.Classes, System.SysUtils,
System.IOUtils, Winapi.ActiveX, msu5MPR, msu5AlgoLib, lgkCrossing, System.Generics.Collections,
msu2FenceUnit, msu5RTEOPCSrv, inifiles, prOpcDa, System.Variants, prObjInit, System.DateUtils;

const
  cnstDSDelay=100;
  //значения параметров по-умолчанию
  SPPOPC_NAME = 'msu5SPP.OPCSrv.1';
  NWApp_NAME = 'vistgw.Caller.1';
type

  TMSURTECore = class;

  TTagEntry = class
    public
      Phisical : boolean;
      Memory : boolean;
      IOReadOnly : boolean;
      IOWriteOnly : boolean;
      IOReadWrite : boolean;
      ServerAlias : string;
      OPCItemUseTagname : boolean;
      OPCItemName : String;
      DiscReversConversion : boolean;
      Constructor Create;
  end;

  TRTEMatter = class
    public
      MPRCore : TMSURTECore;
      Name : string;
      Constructor Create (AMPRCore : TMSURTECore);
      function PostProcessing : boolean;virtual;abstract;
  end;

  TRTETag = class
    private
      LastValue : OleVariant;
      FValue : OleVariant;
      FForced : boolean;
      FQuality: Word;
      FDescription : string;
      procedure SetTagValue(aValue : OleVariant);
      procedure LogValue(aOldValue : OleVariant; aNewValue  : OleVariant);
      procedure SetForceValue(aForceValue : OleVariant);
      procedure DirectSetValue(aRawValue : OleVariant);virtual;
      procedure SetQuality (qValue : Word);
    public
      Name : string;
      TagType : TVarType;
      InitialValue : OleVariant;
      OwnedObject : TRTEMatter;
      IsOPCTag : boolean;
      OPCReadable : boolean;
      OPCWritable : boolean;
      OPCItemUseTagname : boolean;
      OPCItemName : string;
      PLCTagEntry : TTagEntry;
      TagServerTagEntry : TTagEntry;
      NoCreate : boolean;
      Changed : boolean;
      NoTagLogging : boolean;
      PhisicalValue : boolean;
      forCstApps : boolean;
      property Value : OleVariant read FValue write SetTagValue;
      property Forced : Boolean read FForced write FForced;
      property ForceValue : OleVariant read FValue write SetForceValue;
      property Quality: Word read FQuality write SetQuality;
      property Description : string read FDescription write FDescription;
      Constructor Create(TagName : String; AHost : TRTEMatter; AType : TVarType; AIniValue : OleVariant);
      Destructor Destroy;override;
  end;

  TRTEConnect = class(TRTEMatter)
    private
      RWConnection : TRWConnection;
    public
      //тэги
      MainTag : TRTETag;
      _SL : TRTETag;
      _EMULATE : TRTETag;
      _LET_EMULATE : TRTETag;
      _SL_EMULATE : TRTETag;
      ViewTagNameConnected : TRTETag;
      StationConnected : TRTETag;
      _SV : TRTETag;
      NET_SV : TRTETag;
      _Watch : TRTETag;
      FieldBusConnected : TRTETag;
      MasterState : TRTETag;
      MasterState_OUT : TRTETag;
      _SF : TRTETag;
      //
      FSGateway : boolean;
      OnFieldBus : boolean;
      arrIndex : Integer;
      Constructor Create (AMPRCore : TMSURTECore; AConnectionCode : string; AFSGateway : boolean);overload; //создание соединения из секции или стрелки
      Constructor Create (AMPRCore : TMSURTECore; AIdx : Integer);overload; //создание соединения из массива МПР
      function PostProcessing : boolean;override;
  end;

  TRTESection = class (TRTEMatter)
    private
      RWSection : TRWSection;
      FCaption : String;
      FLongCaption : String;
      FLockSignalLink : Integer;
    public
      //тэги
      _L1 : TRTETag;
      _SV : TRTETag;
      GeneralTag : TRTETag;
      _GS : TRTETag;
      _SV_IN : TRTETag;
      _SV_OUT : TRTETag;
      _Result : TRTETag;
      _RLZ : TRTETag;
      _AB_1IO_R : TRTETag;
      _AB_1IO_OUT : TRTETag;
      _AB_2IO_L1 : TRTETag;
      _LZ : TRTETag;
      _AXES : TRTETag;
      _LRI : TRTETag;
      _OUT : TRTETag;
      _AB_1SVH_OUT : TRTETag;
      _R : TRTETag;
      //
      isSlave : Boolean;
      Connection : TRTEConnect;
      CrossType3 : boolean; //true - секция пересекается переездом 3-го типа
      CrossPP : TStringList;
      ContainedPoints : TStringList;
      RWAB : TRTEMatter;//автоблокировка, в которой участвует секция
      UABType : Integer;
      SPPType : Integer;
      property Caption : string read FCaption;
      property LongCaption : String read FLongCaption;
      property LockSignalLink : Integer read FLockSignalLink;
      Constructor Create (AMPRCore : TMSURTECore; ASct : TRWSection);
      function PostProcessing : boolean;override;
      Destructor Destroy; override;
  end;

  TRTEMainPoint = class;

  TRTEPoint = class (TRTEMatter)
    private
      RWThePoint : TRWThePoint;
      FCaption : String;
      CodingName : String;
    public
      Connection : TRTEConnect;
      OwnerRTESection : TRTESection;
      FencesWhereInvolve : TStringList;
      PointByBranch : TRTEPoint;
      PointType : Integer;
      DiscReadOnly : Integer;
      MainPoint : TRTEMainPoint;
      property Caption : string read FCaption;
      Constructor Create (AMPRCore : TMSURTECore; APnt : TRWThePoint);
      function PostProcessing : boolean;override;
      Destructor Destroy;override;
  end;

  TRTEMainPoint = class (TRTEMatter)
    private
      RWTheMainPoint : TMainRWPoints;
      FCaption : String;
      CodingName : String;
    public
      //тэги
      _L1 : TRTETag;
      _L2 : TRTETag;
      _OUT_P : TRTETag;
      _OUT_M : TRTETag;
      _OUT_BLOCK : TRTETag;
      _OUT_B : TRTETag;
      A_P : TRTETag;
      _Command : TRTETag;
      _Result : TRTETag;
      GeneralTag : TRTETag;
      _DeviceState : TRTETag;
      _Command_Fence : TRTETag;
      _Result_Fence : TRTETag;
      _RL : TRTETag;
      _MSSZ : TRTETag;
      _BSTP : TRTETag;
      _OUT_K : TRTETag;
      netMainTag : TRTETag;
      //
      FBLK : Array of TRTETag;
      RTEPoint : TRTEPoint;
      STPWhereInvolve : TStringList;
      Idx : Integer;
      NetPoint : boolean;
      property Caption : string read FCaption;
      Constructor Create (AMPRCore : TMSURTECore; APnt : TMainRWPoints);
      function PostProcessing : boolean;override;
      Destructor Destroy;override;
  end;

  TRTESignal = class (TRTEMatter)
    private
      RWSignal : TRWSignal;
      FCaption : String;
      CodingName : String;
      FSignalType : Integer;
      FSignalSubType : Integer;
      FAdditionalSubType : Integer;
      FUnVisible : Boolean;
    public
      //тэги
      _OFF : TRTETag;
      MainTag : TRTETag;
      _F : TRTETag;
      _Result : TRTETag;
      _DeviceState : TRTETag;
      _SK : TRTETag;
      _OPER : TRTETag;
      _Command : TRTETag;
      _SignalOn : TRTETag;
      _BlOCK : TRTETag;
      //красный
      _CTL0 : TRTETag;
      _L0 : TRTETag;
      //белый
      _CTL1 : TRTETag;
      _L1 : TRTETag;
      //зеленый
      _CTL4 : TRTETag;
      _L2 : TRTETag;
      //желтый верхний
      _L3 : TRTETag;
      _CTL3 : TRTETag;
      //желтый нижний
      _L4 : TRTETag;
      _CTL2 : TRTETag;
      _CTL21 : TRTETag;
      //проходной
      _OUT1 : TRTETag;
      _OUT2 : TRTETag;
      _OUT3 : TRTETag;
      NETSrc : TRTETag;
      RTEStandSection : TRTESection;
      Q1SVH_OUTSignalExists : Boolean;
      ShST2Crossings : TStringList;
      Connection : TRTEConnect;
      property SignalType : Integer read FSignalType;
      property SignalSubType : Integer read FSignalSubType;
      property AdditionalSubType : Integer read FAdditionalSubType;
      property Caption : string read FCaption;
      property UnVisible : Boolean read FUnVisible write FUnVisible;
      Constructor Create (AMPRCore : TMSURTECore; ASgn : TRWSignal);
      function PostProcessing : boolean;override;
      Destructor Destroy; override;
  end;

  TRTECrossPP = class(TRTEMatter)
    private
      RWCrossPP : TRWCrossPP;
      FCaption : String;
    public
      //тэги
      _L1 : TRTETag;
      _OUT : TRTETag;
      _RLZ : TRTETag;
      OrdinalNumb : Integer;
      OwnSection : TRTESection;
      property Caption : string read FCaption;
      Constructor Create (AMPRCore : TMSURTECore; ACrossPP : TRWCrossPP);
      function PostProcessing : boolean;override;
  end;

  TRTECrossing = class(TRTEMatter)
    private
      RWCrossing : TRWCrossing;
      FCaption : string;
      FCrossingType : Integer;
      FCrossingSubType : Integer;
    public
      //тэги
      A_G : TRTETag;
      _OUT : TRTETag;
      _EVEN_OUT : TRTETag;
      _ODD_OUT : TRTETag;
      _FAULT : TRTETag;
      _FAULT_L1 : TRTETag;
      _IN : TRTETag;
      _IN_L1 : TRTETag;
      _FENCE : TRTETag;
      _FENCE_L1 : TRTETag;
      _PROPERLY : TRTETag;
      _PROPERLY_L1 : TRTETag;
      _FUSEDLAMPS : TRTETag;
      _FUSEDLAMPS_L1 : TRTETag;
      _SIGNAL : TRTETag;
      _SIGNAL_L1 : TRTETag;
      _CLOSE : TRTETag;
      _CLOSE_L1 : TRTETag;
      _OPEN : TRTETag;
      _OPEN_L1 : TRTETag;
      _TR3 : TRTETag;
      MainTag : TRTETag;
      _DeviceState : TRTETag;
      CrossSignals : TStringList;
      OutSignalsNumber : Integer;
      property Caption : string read FCaption;
      property CrossingType : Integer read FCrossingType;
      property CrossingSubType : Integer read FCrossingSubType;
      Constructor Create (AMPRCore : TMSURTECore; ACrossing : TRWCrossing);
      function PostProcessing : boolean;override;
      Destructor Destroy;override;
  end;

  TRTECrossLine = class(TRTEMatter)
    private
      RWCrossLine : TRWCrossLine;
      FCaption : string;
      FChangeDirection : Integer;
    public
      //тэги
      _EVEN_OUT : TRTETag;
      _ODD_OUT : TRTETag;
      Owner : TRTECrossing;
      property Caption : string read FCaption;
      property ChangeDirection : Integer read FChangeDirection;
      Constructor Create (AMPRCore : TMSURTECore; ACrossLine : TRWCrossLine);
      Destructor Destroy;override;
      function PostProcessing : boolean;override;
  end;

  TRTEMLSignal = class(TRTEMatter)
    private
      RWML : TRWML;
      FCaption : string;
    public
      //тэги
      _COMM : TRTETag;
      MainTag : TRTETag;
      _BLOCK : TRTETag;
      _L1 : TRTETag;
      _OUT : TRTETag;
      property Caption : string read FCaption;
      Constructor Create (AMPRCore : TMSURTECore; ARWML : TRWML);
      function PostProcessing : boolean;override;
  end;

  TRTEPAB = class(TRTEMatter)
    private
      RWSA : TRWSA;
      FCaption : string;
      FVariant : integer;
    public
      //тэги
      _DS : TRTETag;
      _OS : TRTETag;
      _DP : TRTETag;
      _IR : TRTETag;
      _PO_L1 : TRTETag;
      _PS_L1 : TRTETag;
      _DS_L1 : TRTETag;
      _OPER : TRTETag;
      _PP : TRTETag;
      _PP_L1 : TRTETag;
      _PP_L2 : TRTETag;
      _OKSR_OUT : TRTETag;
      _DP_OUT : TRTETag;
      _DS_OUT : TRTETag;
      _IR_OUT : TRTETag;
      _OS_OUT : TRTETag;
      //
      RouteList : TStringList;
      property Caption : string read FCaption;
      property Variant : Integer read FVariant;
      Constructor Create (AMPRCore : TMSURTECore; ARWSA : TRWSA);
      function PostProcessing : boolean;override;
      Destructor Destroy; override;
  end;

  TRTEDAB = class(TRTEMatter)
    private
      RWCD : TRWCD;
      FCaption : string;
    public
      //тэги
      _SN : TRTETag;
      _SN_NET : TRTETag;
      _OV : TRTETag;
      _OV_NET : TRTETag;
      _PV : TRTETag;
      _PV_NET : TRTETag;
      _1IO_R : TRTETag;
      _1I_R : TRTETag;
      _2SN : TRTETag;
      _1SN : TRTETag;
      _KP_L1 : TRTETag;
      _2IP_L1 : TRTETag;
      _2IP : TRTETag;
      _2I_L1 : TRTETag;
      _2VSN_L1 : TRTETag;
      _2PV_L1 : TRTETag;
      _Command : TRTETag;
      _Result : TRTETag;
      _L1 : TRTETag;
      _L2 : TRTETag;
      _1IO_R_OUT : TRTETag;
      _1I_R_OUT : TRTETag;
      _BU : TRTETag;
      _SN_OUT : TRTETag;
      _PV_OUT : TRTETag;
      _OV_OUT : TRTETag;
      _2PBU : TRTETag;
      _1I_R_L1 : TRTETag;
      _2OV_L1 : TRTETag;
      _1OT_OUT : TRTETag;
      _1_PR_OUT : TRTETag;
      MainTag : TRTETag;
      _SN1 : TRTETag;
      _SN2 : TRTETag;
      _PKP_OUT : TRTETag;
      _KP_OUT : TRTETag;
      _KP_BLOCK : TRTETag;
      _1SN_OUT : TRTETag;
      _1OV_OUT : TRTETag;
      _2PV_OUT : TRTETag;
      _2VSN_OUT : TRTETag;
      _2VSN_BLOCK : TRTETag;
      _1IO_OUT : TRTETag;
      _1IO_BLOCK : TRTETag;
      _1I_OUT : TRTETag;
      _1I_BLOCK : TRTETag;
      _BU_OUT : TRTETag;
      _BU_BLOCK : TRTETag;
      _BU_L1 : TRTETag;
      _1PV_OUT : TRTETag;
      _1PV_BLOCK : TRTETag;
      _1SVH_OUT : TRTETag;
      _1SVH_BLOCK : TRTETag;
      _1PR_OUT : TRTETag;
      _1PR_BLOCK : TRTETag;
      _1OT_BLOCK : TRTETag;
      _2PBU_OUT : TRTETag;
      _2PBU_BLOCK : TRTETag;
      _2PBU_L1 : TRTETag;
      //
      Direction : Integer; //направление приема
      DABSections : TStringList; //Массив секций, входящих в данную ДАБ
      ControlMode : Integer; //
      ControlType : Integer;
      is2PBUExists : boolean; //Контролируются все блок-участки:0(по умолчанию) - да, 1 - нет
      isBU_L1Exists : boolean;//Вх. сигнал контроля свободности блок-участков:"0" (по умолчанию) - есть;"1" - нет.
      is2I_L1Exists : boolean;//Вх. сигнал 2И_L1: "0" (по умолчанию) - есть; 1 - нет.
      is2VSN_L1Exists : boolean; //Вх. сигнал смены направления с соседней станции: "0" (по умолчанию) - есть; 1 - нет.
      is1OT_OUTExists : boolean; //Вых. сигналы установленного направления: "0" (по умолчанию) - есть; 1 - нет.
      BusType : Integer;
      BindStationCode : string;
      CodeName : string;
      ISidx : Integer;//индекс входного светофора
      Connection : TRTEConnect;
      property Caption : string read FCaption;
      Constructor Create (AMPRCore : TMSURTECore; ARWCD : TRWCD);
      function PostProcessing : boolean;override;
      Destructor Destroy;override;
      function GetCodeName : string;
  end;

  TRTEVSSignal = class(TRTEMatter)
    private
      RW_V_Signal : TRW_V_Signal;
      FCaption : string;
    public
      //тэги
      MainTag : TRTETag;
      _L0 : TRTETag;
      _L1 : TRTETag;
      property Caption : string read FCaption;
      Constructor Create (AMPRCore : TMSURTECore; ARW_V_Signal : TRW_V_Signal);
      function PostProcessing : boolean;override;
  end;

  TRTESysES = class;

  TRTEStativ_Fuse = class(TRTEMatter)
    private
      StativFuse : TStativFuse;
      FCaption : string;
    public
      //тэги
      MainTag : TRTETag;
      _L1 : TRTETag;
      //
      SESIdx : Integer;
      RTESysES : TRTESysES;
      property Caption : string read FCaption;
      Constructor Create (AMPRCore : TMSURTECore; AStativFuse : TStativFuse);
      function PostProcessing : boolean;override;
  end;

  TRTESysES = class(TRTEMatter)
    private
      RWSysES : TSysES;
      FCaption : string;
    public
      //тэги
      RMB_BUTTON : TRTETag;
      RMB_OUT : TRTETag;
      RMB_MANUAL : TRTETag;
      FIDER1 : TRTETag;
      FIDER1_L1 : TRTETag;
      FIDER1_IN : TRTETag;
      FIDER1_IN_L1 : TRTETag;
      FIDER2 : TRTETag;
      FIDER2_L1 : TRTETag;
      FIDER2_IN : TRTETag;
      FIDER2_IN_L1 : TRTETag;
      FUSE : TRTETag;
      FUSE_L1 : TRTETag;
      AmperMeter : TRTETag;
      RMB_AUTO : TRTETag;
      AmperMeter_Control : TRTETag;
      //
      SESIdx : Integer;
      isAmpermetrExists : boolean;//наличие ампереметра
      AmpermeterMin : Integer;
      AmpermeterMax : Integer;
      ScaleMax : Integer;
      isFider1Exists : boolean;
      isFider2Exists : boolean;
      isFuseExists : boolean;
      isRMBButton : boolean;
      InversFiderControl : Integer;
      FiderControl : boolean;
      StativFuses : TStringList;
      property Caption : string read FCaption;
      Constructor Create (AMPRCore : TMSURTECore; ARWSysES : TSysES; AIdx : Integer);overload; //для нескольких систем питания на станции
      Constructor Create (AMPRCore : TMSURTECore);overload;//для одной системы питания на станции
      function PostProcessing : boolean;override;
      Destructor Destroy;override;
    public
  end;

  TRTEZSSignal = class(TRTEMatter)
    private
      RW_Z_Signal : TRW_Z_Signal;
      FCaption : string;
    public
      //тэги
      _L1 : TRTETag;
      _Control : TRTETag;
      //
      property Caption : string read FCaption;
      Constructor Create (AMPRCore : TMSURTECore; ARW_Z_Signal : TRW_Z_Signal);
      function PostProcessing : boolean;override;
  end;

  TRTEAddSignal = class(TRTEMatter)
    private
      RW_Add_Signal : TRW_Add_Signal;
      FCaption : string;
    public
      //тэги
      _L1 : TRTETag;
      _L2 : TRTETag;
      _OUT1 : TRTETag;
      _OUT2 : TRTETag;
      _OUT3 : TRTETag;
      _OUT : TRTETag;
      _DeviceState : TRTETag;
      MainTag : TRTETag;
      SignalType : Integer;
      SourceCode : string;
      SourceType : Integer;
      BlockingMode : Integer;
      ControlMode : Integer;
      property Caption : string read FCaption;
      Constructor Create (AMPRCore : TMSURTECore; ARW_Add_Signal : TRW_Add_Signal);
      function PostProcessing : boolean;override;
  end;

  TRTEFence = class(TRTEMatter)
    private
      RWFence : TRWFence;
      FCaption : string;
    public
      //тэги
      _AE : TRTETag;
      _IN : TRTETag;
      MainTag : TRTETag;
      _DA : TRTETag;
      _DeviceState : TRTETag;
      _PointsPlus : TRTETag;
      _PointsMinus : TRTETag;
      _OUT : TRTETag;
      //
      Idx : Integer;
      CodingName : string;
      FencePointsPlus : TStringList;
      FencePointsMinus : TStringList;
      AllFencePoints : TStringList;
      property Caption : string read FCaption;
      Constructor Create (AMPRCore : TMSURTECore; ARWFence : TRWFence);
      function PostProcessing : boolean;override;
      Destructor Destroy;override;
  end;

  TRTERoute = class(TRTEMatter)
    private
      RWRoute : TRWRoute;
      FCaption : string;
    public
      //тэги
      MainTag : TRTETag;
      _LR : TRTETag;
      _DA : TRTETag;
      _RM : TRTETag;
      _T : TRTETag;
      //
      FirstSignal : TRTESignal;
      property Caption : string read FCaption;
      Constructor Create (AMPRCore : TMSURTECore; ARWRoute : TRWRoute);
      function PostProcessing : boolean;override;
      Destructor Destroy;override;
  end;

  TRTESTP = class(TRTEMatter)
  private
    RWSTP : TRWSTP;
    FCaption : string;
  public
    property Caption : string read FCaption;
    Constructor Create (AMPRCore : TMSURTECore; ARWSTP : TRWSTP);
    function PostProcessing : boolean;override;
  end;

  TRTENode = class(TRTEMatter)
    private
      RWNode : TRWNode;
      FCaption : string;
      FNodeType : Integer;
      FInVisible : Boolean;
    public
      //тэги
      _S : TRTETag;
      _State : TRTETag;
      property Caption : string read FCaption;
      property NodeType : Integer read FNodeType;
      property InVisible : boolean read FInVisible;
      Constructor Create (AMPRCore : TMSURTECore; ARWNode : TRWNode);
      function PostProcessing : boolean;override;
  end;

  TMSURTECore = class(TRTEMatter)
    private
      FPFBConnected : Boolean;
      FMPRLoaded : Boolean;
      FCoreCreated : Boolean;
      SafeModeTimer : Integer;
      PLC_WatchDogTimeCounter : Integer;
      TS_WatchDogTimeCounter : Integer;
      BOS_WatchDogTimeCounter : Integer;
      ListSignalDoubles : TStringList;
      srcDoubles : array of TRTETag;
      dstDoubles : array of TRTETag;
      SomeDoubles : boolean;
      LastDateTime : TDateTime;
      function CreateGlobalTags : boolean;
      function CreateConnections : boolean;
      function CreateSections : boolean;
      function CreatePoints : boolean;
      function CreateSignals : boolean;
      function CreateCrossPPs : boolean;
      function CreateCrossings : boolean;
      function CreateCrossLines : boolean;
      function CreateMLs : boolean;
      function CreatePABs : boolean;
      function CreateDABs : boolean;
      function CreateVSSignals : boolean;
      function CreateStativ_Fuses : boolean;
      function CreateRTESysESes : boolean;
      function CreateRTEZSSignals : boolean;
      function CreateRTEAddSignals : boolean;
      function CreateRTEFences : boolean;
      function CreateRTERoutes : boolean;
      function CreateSTPs : boolean;
      function CreateRTENodes : boolean;
      function CreateExternalApps : boolean;
      function PrepareMPR : boolean;
      function GetInputSignalForDAB(ADABidx: Integer) : Integer;
      function PosToWord(APos : Integer) : WORD;
      function LoadUSO(AUSOFile : string) : boolean;
      function CreateUSOTag(AtagName : string; AType : TVarType; AIniValue : OleVariant) : TRTETag;
    protected
      function CreateCoreStructure : boolean;
      procedure LoadMPR(AMPRPath : String);
      //процедуры для msu5MPR
      procedure obMain;
      procedure parInit;
      //секции
      procedure rInit;
      procedure rRead;
      procedure rDO;
      procedure rWrite;
      //стрелки
      procedure pInit;
      procedure pRead;
      procedure pDo;
      procedure pWrite;
      //светофоры
      procedure sInit;
      procedure sRead;
      procedure sWrite;
      //СЭС
      procedure sesInit;
      procedure sesRead;
      procedure sesWrite;
      //въездные светофоры
      procedure sVInit;
      procedure sVRead;
      procedure sVWrite;
      //лунные
      procedure mlInit;
      procedure mlRead;
      procedure mlWrite;
      procedure mlDo;
      //маршруты
      procedure uInit;
      procedure uRead;
      //ДАБ
      procedure dabInit;
      procedure dabRead;
      procedure dabDO;
      procedure dabWrite;
      //переезды
      procedure gInit;
      procedure gRead;
      procedure gWrite;
      //ограждения
      procedure fInit;
      procedure fRead;
      procedure fWrite;
      //заградительные сигналы
      procedure zsRead;
      //соединения
      procedure connInit;
      procedure connRead;
      procedure connWrite;
      //ПАБ
      procedure pabInit;
      procedure pabRead;
      procedure pabDO;
      procedure pabWrite;
      //участки приближения
      procedure ppInit;
      procedure ppRead;
      procedure ppDo;
      procedure ppWrite;
      //дополнительные светофоры
      procedure asInit;
      procedure asRead;
      procedure asWrite;
      //PFB Slave
      procedure pfbInit;
      procedure pfbRead;
      procedure pfbWrite;
      //WatchDog
      procedure PLC_WatchDog;
      procedure TS_WatchDog;
      //выходные тэги - дубли
      procedure qdblInit;
      procedure qdblWrite;
    public
      //тэги
      RMBDeadBandTime : TRTETag;
      SEConnected : TRTETag;
      SEControl_TimeOut : TRTETag;
      FrausherStage1Delay : TRTETag;
      ResetLZStage1Delay : TRTETag;
      ResetLZStage2Delay : TRTETag;
      ResetLZStage3Delay : TRTETag;
      StationView_StationCode : TRTETag;
      StationView_WatchDog : TRTETag;
      StationView_Connected : TRTETag;
      vistgw_watchdog : TRTETag;
      vistgw_Connected : TRTETag;
      RepeatSignalsDelay : TRTETag;
      ConnectionControlInterval : TRTETag;
      StationPLC_ErrorStatus : TRTETag;
      StationPLC_Slave : TRTETag;
      WatchDogCycle : TRTETag;
      StationPLC_WatchDog : TRTETag;
      StationTagServer_WatchDog : TRTETag;
      BusOPCServer_WatchDog : TRTETag;
      //
      MSURTESettings : TMSURTESettings;
      AppLogger : TProgramLoggerEx;
      RTETagLogger : TExtentionArchiveLogger;
      MPR : TRWMPR;
      GlobalTags : TStringList;
      RTESections : TStringList;
      RTEPoints : TStringList;
      RTEMainPoints : TStringList;
      RTESignals : TStringList;
      RTEConnections : TStringList;
      RTECrossPPs : TStringList;
      RTECrossings : TStringList;
      RTEMLs : TStringList;
      RTEPABs : TStringList;
      RTEDABs : TStringList;
      RTEVSSignals : TStringList;
      RTEStativ_Fuses : TStringList;
      RTESysESes : TStringList;
      RTEZSSignals : TStringList;
      RTEAddSignals : TStringList;
      RTEFences : TStringList;
      RTERoutes : TStringList;
      RTECrossLines : TStringList;
      RTESTPs : TStringList;
      RTENodes : TStringList;
      RTESlaves : TStringList;
      RTEExtApps : TStringList;
      //
      IASymbols : TStringList;
      OASymbols : TStringList;
      sppIASymbols : TStringList;
      SimpleRWRoutes:array of Integer;//массив простых маршрутов
      ComplexRWRoutes:array of Integer;//массив составных маршрутов СМ
      //локальные переменные
      StationView_OldWatchDog : Integer;
      property MPRLoaded : Boolean read FMPRLoaded;
      property CoreCreated : Boolean read FCoreCreated;
      property PFBConnected : boolean read FPFBConnected write FPFBConnected;
      Constructor Create;
      Destructor Destroy; override;
      function PostProcessing : boolean;override;
      function isQ1SVHSignalExists(ARTESectionName : string) : TRTESignal;
      function GetMainPoint(APoint : TRTEPoint) : TRTEPoint;
      procedure CreateCoreFromMPR;
      procedure Run;
      procedure CalcSafeMode;
      function BOS_WatchDog : boolean;
      procedure IncBOS_WatchDog;
  end;

  TRTEPFBSlave = class;

  TioArea = class (TRTETag)
  private
    AreaLitera : string;
    procedure DirectSetValue(aRawValue : OleVariant);override;
    function GetModuleNumberStr : string;
  public
    MPRCore : TMSURTECore;
    Slave : TRTEPFBSlave;
    Module : Integer;
    Offset : Integer;
    Bits : array of TRTETag;
    isOutput : Boolean;
    Constructor Create(TagName : String; AHost : TRTEMatter; AType : TVarType; AIniValue : OleVariant; AModule : Integer; AOffset : Integer; AOut : Boolean);
    function GetAreaName : string; virtual; abstract;
    procedure AssemblyOutputBits;
    procedure SetTagsAsPhisicalVaue;
  end;

  TioByte = class(TioArea)
    public
      Constructor Create(TagName : String; AHost : TRTEMatter; AType : TVarType; AIniValue : OleVariant; AModule : Integer; AOffset : Integer; AOut : Boolean);
      function GetAreaName : string;override;
  end;

  TioWord = class(TioArea)
    public
      Constructor Create(TagName : String; AHost : TRTEMatter; AType : TVarType; AIniValue : OleVariant; AModule : Integer; AOffset : Integer; AOut : Boolean);
      function GetAreaName : string;override;
  end;

  //для аналоговых модулей
  TAioWord = class (TioArea)
    private
      procedure DirectSetValue(aRawValue : OleVariant);override;
    public
      Constructor Create(TagName : String; AHost : TRTEMatter; AType : TVarType; AIniValue : OleVariant; AModule : Integer; AOffset : Integer; AOut : Boolean);
      function GetAreaName : string;override;
  end;

  TRTEPFBSlave = class(TRTEMatter)
  private
    function GetSiemensSlaveStr : string;
  public
    _Status : TRTETag;
    _State : TRTETag;
    nmSlave : Integer;
    ioAreas : TStringList;
    Constructor Create (AMPRCore : TMSURTECore; ASlvNumber : Integer);
    Destructor Destroy;override;
    function GetSlaveStr : string;
    procedure AssemblyOutputBits;
    function PostProcessing : boolean;override;
  end;

  TRTEExtApp = class (TRTEMatter)
  public
    ExAppIniFile : string;
    Constructor Create (AMPRCore : TMSURTECore; AExAppIniFile : string);
  end;

  TRTEExAppDusting = class(TRTEExtApp)
  public
    Constructor Create (AName : String; AMPRCore: TMSURTECore; AExAppIniFile: string);
  end;

  TRTEExAppHeating = class(TRTEExtApp)
  public
    Constructor Create (AName : String; AMPRCore: TMSURTECore; AExAppIniFile: string);
  end;

  TRTEExAppPZ = class(TRTEExtApp)
  public
    Constructor Create (AName : String; AMPRCore: TMSURTECore; AExAppIniFile: string);
  end;

  TRTEExAppSprinkler = class(TRTEExtApp)
  public
    Constructor Create (AName : String; AMPRCore: TMSURTECore; AExAppIniFile: string);
  end;

  function GetStrTypeDescription (AType : TVarType) : string;
implementation

Constructor TTagEntry.Create;
begin
  inherited;
  Phisical := false;
  Memory := false;
  IOReadOnly := false;
  IOWriteOnly := false;
  IOReadWrite := false;
  ServerAlias := string.Empty;
  OPCItemUseTagname := true;
  OPCItemName := string.Empty;
  DiscReversConversion := false;
end;

Constructor TMSURTECore.Create;
begin
  inherited Create (Self);
  Name := 'Global';
  //тэги
  SEConnected := nil;
  SEControl_TimeOut := nil;
  RMBDeadBandTime := nil;
  FrausherStage1Delay := nil;
  ResetLZStage1Delay := nil;
  ResetLZStage2Delay := nil;
  ResetLZStage3Delay := nil;
  StationView_StationCode := nil;
  StationView_WatchDog := nil;
  StationView_Connected := nil;
  SafeModeTimer := 1;
  StationView_OldWatchDog := -3;
  vistgw_watchdog := nil;;
  vistgw_Connected := nil;
  RepeatSignalsDelay := nil;
  ConnectionControlInterval := nil;
  WatchDogCycle := nil;
  PLC_WatchDogTimeCounter := 1;
  StationPLC_WatchDog := nil;
  TS_WatchDogTimeCounter := 1;
  StationTagServer_WatchDog := nil;
  BOS_WatchDogTimeCounter := 1;
  BusOPCServer_WatchDog := nil;
  //MPRCore := Self;
  MSURTESettings := TMSURTESettings.Create;
  AppLogger := TProgramLoggerEx.Create(MSURTESettings.AppLoggerPath);
  AppLogger.DaysOld := MSURTESettings.DaysOld;
  if MSURTESettings.TagLoggingOn then
  begin
    RTETagLogger := TExtentionArchiveLogger.Create(MSURTESettings.TagLogsPath,'.txt');
    RTETagLogger.DaysOld := MSURTESettings.DaysOld;
  end
  else
  begin
    RTETagLogger := nil;
  end;
  //списки
  GlobalTags := TStringList.Create(true);
  RTESections := TStringList.Create(true);
  RTEPoints := TStringList.Create(true);
  RTEMainPoints := TStringList.Create(true);
  RTESignals := TStringList.Create(true);
  RTEConnections := TStringList.Create(true);
  RTECrossPPs := TStringList.Create(true);
  RTECrossings := TStringList.Create(true);
  RTECrossLines := TStringList.Create(true);
  RTEMLs := TStringList.Create(true);
  RTEPABs := TStringList.Create(true);
  RTEDABs := TStringList.Create(true);
  RTEVSSignals := TStringList.Create(true);
  RTEStativ_Fuses := TStringList.Create(true);
  RTESysESes := TStringList.Create(true);
  RTEZSSignals := TStringList.Create(true);
  RTEAddSignals := TStringList.Create(true);
  RTEFences := TStringList.Create(true);
  RTERoutes := TStringList.Create(true);
  RTESTPs := TStringList.Create(true);
  RTENodes := TStringList.Create(true);
  RTESlaves := TStringList.Create(true);
  RTEExtApps := TStringList.Create(true);
  IASymbols := TStringList.Create(false);
  OASymbols := TStringList.Create(false);
  sppIASymbols := TStringList.Create(false);
  ListSignalDoubles := TStringList.Create(false);
  MPR := nil;
  FMPRLoaded := false;
  FCoreCreated := false;
  FPFBConnected := false;
  MPR_Params.LastScanTime := MSURTESettings.WorkInterval;
end;

procedure TMSURTECore.CreateCoreFromMPR;
begin
  LoadMPR(MSURTESettings.MPRFile);
  if MPRLoaded then
  begin
     FCoreCreated := CreateCoreStructure;
  end;
  if CoreCreated then
  begin
    if MSURTESettings.PHL_NameMethod <> 1 then
      If not LoadUSO(TPath.ChangeExtension(MSURTESettings.MPRFile,'uso')) then
      begin
        MSURTESettings.PHL_NameMethod := 1; //в списках IASymbols и OASymbols уже находятся Item-ы OPC - сервера карты
        AppLogger.AddWarningMessage('Из-за ошибки чтения Station.uso, принудительно установлен режим прямого соответствия символов МСУ5 и символов сервера ' + MSURTESettings.OPC_Server_ProgId + '.');
      end;
    InitOPCSrvAdressSpace;
  end;
end;

Destructor TMSURTECore.Destroy;
begin
  if Assigned(ListSignalDoubles) then
  begin
    ListSignalDoubles.Free;
    ListSignalDoubles := nil;
  end;
  if Assigned(RTETagLogger) then
  begin
    RTETagLogger.FreeOnTerminate := true;
    RTETagLogger.Terminate;
  end;
  if Assigned(AppLogger) then
  begin
    AppLogger.FreeOnTerminate := True;
    AppLogger.Terminate;
  end;
  if Assigned(MPR) then
  begin
    MPR.Free;
    MPR := nil;
  end;
  if Assigned(RTEExtApps) then
  begin
    RTEExtApps.Free;
    RTEExtApps := nil;
  end;
  if Assigned(RTESlaves) then
  begin
    RTESlaves.Free;
    RTESlaves := nil;
  end;
  if Assigned(OASymbols) then
  begin
    OASymbols.Free;
    OASymbols := nil;
  end;
  if Assigned(IASymbols) then
  begin
    IASymbols.Free;
    IASymbols := nil;
  end;
  if Assigned(sppIASymbols) then
  begin
    sppIASymbols.Free;
    sppIASymbols := nil;
  end;
  if Assigned(RTENodes) then
  begin
    RTENodes.Free;
    RTENodes := nil;
  end;
  if Assigned(RTESTPs) then
  begin
    RTESTPs.Free;
    RTESTPs := nil;
  end;
  if Assigned(RTERoutes) then
  begin
    RTERoutes.Free;
    RTERoutes := nil;
  end;
  if Assigned(RTEFences) then
  begin
    RTEFences.Free;
    RTEFences := nil;
  end;
  if Assigned(RTEAddSignals) then
  begin
    RTEAddSignals.Free;
    RTEAddSignals := nil;
  end;
  if Assigned(RTEZSSignals) then
  begin
    RTEZSSignals.Free;
    RTEZSSignals := nil;
  end;
  if Assigned(RTESysESes) then
  begin
    RTESysESes.Free;
    RTESysESes := nil;
  end;
  if Assigned(RTEStativ_Fuses) then
  begin
    RTEStativ_Fuses.Free;
    RTEStativ_Fuses := nil;
  end;
  if Assigned(RTEVSSignals) then
  begin
    RTEVSSignals.Free;
    RTEVSSignals := nil;
  end;
  if Assigned(RTEDABs) then
  begin
    RTEDABs.Free;
    RTEDABs := nil;
  end;
  if Assigned(RTEPABs) then
  begin
    RTEPABs.Free;
    RTEPABs := nil;
  end;
  if Assigned(RTEMLs) then
  begin
    RTEMLs.Free;
    RTEMLs := nil;
  end;
  if Assigned(RTECrossings) then
  begin
    RTECrossings.Free;
    RTECrossings := nil;
  end;
  if Assigned(RTECrossLines) then
  begin
    RTECrossLines.Free;
    RTECrossLines := nil;
  end;
  if Assigned(RTECrossPPs) then
  begin
    RTECrossPPs.Free;
    RTECrossPPs := nil;
  end;
  if Assigned(RTEConnections) then
  begin
    RTEConnections.Free;
    RTEConnections := nil;
  end;
  if Assigned(RTESignals) then
  begin
    RTESignals.Free;
    RTESignals := nil;
  end;
  if Assigned(RTEMainPoints) then
  begin
    RTEMainPoints.Free;
    RTEMainPoints := nil;
  end;
  if Assigned(RTEPoints) then
  begin
    RTEPoints.Free;
    RTEPoints := nil;
  end;
  if Assigned(RTESections) then
  begin
    RTESections.Free;
    RTESections := nil;
  end;
  if Assigned(GlobalTags) then
  begin
    GlobalTags.Free;
    GlobalTags := nil;
  end;
  if Assigned(MSURTESettings) then
  begin
    MSURTESettings.Free;
    MSURTESettings := nil;
  end;
  inherited;
end;

procedure TMSURTECore.LoadMPR;
var
  List1, List2, List3 : TStringList;
  RTSPath, DicPath : String;
begin
  MPR := nil;
  FMPRLoaded := false;
  if AMPRPath.Trim().Equals(string.Empty) then
  begin
    AppLogger.AddErrorMessage('Файл модели не задан настройками.');
    Exit;
  end;
  if not FileExists(AMPRPath) then
  begin
    AppLogger.AddErrorMessage('Файл '+ AMPRPath +' не существует.');
    Exit;
  end;
  List1 := TStringList.Create;
  List2 := TStringList.Create;
  List3 := TStringList.Create;
  try
    try
      List1.LoadFromFile(AMPRPath);
    except
      AppLogger.AddErrorMessage('Файл '+ AMPRPath +' отсутствует или поврежден.');
      Exit;
    end;
    RTSPath := TPath.ChangeExtension(AMPRPath,'rts');
    try
      List2.LoadFromFile(RTSPath);
    except
      AppLogger.AddErrorMessage('Файл '+RTSPath+' отсутствует или поврежден.');
      Exit;
    end;
    DicPath := TPath.ChangeExtension(AMPRPath,'dic');
    try
      List3.LoadFromFile(DicPath);
    except
      AppLogger.AddErrorMessage('Файл '+DicPath+' отсутствует или поврежден.');
      Exit;
    end;
    If MPR <> nil then
    begin
      FreeAndNil(MPR);
    end;
    MPR := TRWMPR.CreateFromLists(List1,List2,List3,AMPRPath);
    If MPR.Status <> 1 then
    begin
      AppLogger.AddErrorMessage('***'+MPR.ErrorMessage);
      Exit;
    end;
  finally
    List1.Free;
    List2.Free;
    List3.Free;
  end;
  if not PrepareMPR then Exit;
  AppLogger.AddInfoMessage('МПР '+ AMPRPath +' загружен. Станция ' + MPR.StationCaption + '. Код ' + MPR.StationCode + '.');
  FMPRLoaded := TRUE;
end;

Constructor TRTEMatter.Create(AMPRCore: TMSURTECore);
begin
  inherited Create;
  MPRCore := AMPRCore;
  Name := string.Empty;
end;

Constructor TRTETag.Create;
begin
  inherited Create;
  OwnedObject := AHost;
  Name := TagName;
  TagType := AType;
  InitialValue := AIniValue;
  FValue := AIniValue;
  PLCTagEntry := TTagEntry.Create;
  TagServerTagEntry := TTagEntry.Create;
  IsOPCTag := false;
  OPCReadable := true;
  OPCWritable := true;
  OPCItemUseTagName := true;
  OPCItemName := string.Empty;
  NoCreate := false;
  Changed := true;
  NoTagLogging := false;
  FForced := false;
  PhisicalValue := false;
  forCstApps := false;
  FQuality := OPC_QUALITY_GOOD;
end;

Destructor TRTETag.Destroy;
begin
  PLCTagEntry.Free;
  PLCTagEntry := nil;
  TagServerTagEntry.Free;
  TagServerTagEntry := nil;
  inherited;
end;

procedure TRTETag.SetTagValue(aValue: OleVariant);
begin
  if Forced then Exit;
  if FValue <> aValue then
  begin
    if not Assigned(OwnedObject) then Exit;
    if not Assigned(OwnedObject.MPRCore) then Exit;
    if not Assigned(OwnedObject.MPRCore.MSURTESettings) then Exit;
    if OwnedObject.MPRCore.MSURTESettings.PHL_CardVendor <> 3 then
    begin
      if Quality <> OPC_QUALITY_GOOD then
      begin
        LastValue := aValue;
        Exit;
      end;
    end;
    DirectSetValue(aValue);
  end;
end;

procedure TRTETag.SetForceValue(aForceValue: OleVariant);
begin
  if FValue <> aForceValue then
  begin
    DirectSetValue(aForceValue);
  end;
end;

procedure TRTETag.DirectSetValue(aRawValue: OleVariant);
var
  oldValue : OleVariant;
begin
  oldValue := FValue;
  case TagType of
  VT_BOOL:
    begin
      if VarIsOrdinal(aRawValue) then
      begin
        FValue := aRawValue
      end
      else
      begin
        if aRawValue = '0' then
        begin
          FValue := FALSE
        end
        else
        begin
          if aRawValue = '1' then
          begin
            FValue := TRUE
          end
          else
          begin
            if Assigned(OwnedObject) then
              if Assigned(OwnedObject.MPRCore) then
                if Assigned(OwnedObject.MPRCore.AppLogger) then
                  OwnedObject.MPRCore.AppLogger.AddErrorMessage('Тэг '+Name+': попытка присвоения значения несовместимого типа.');
          end;
        end;
      end;
    end //VT_BOOL
  else
    begin
      try
        FValue := aRawValue;
      except
        if Assigned(OwnedObject) then
          if Assigned(OwnedObject.MPRCore) then
            if Assigned(OwnedObject.MPRCore.AppLogger) then
              OwnedObject.MPRCore.AppLogger.AddErrorMessage('Тэг '+Name+': попытка присвоения значения несовместимого типа.');
      end;
    end;
  end;//case
  if not NoTagLogging  then
    LogValue(oldValue,FValue);
  Changed := true;
end;

function TMSURTECore.CreateCoreStructure;
begin
  Result := false;
  if not CreateGlobalTags then Exit;
  if not CreateConnections then Exit;
  if not CreateSections then Exit;
  if not CreatePoints then Exit;
  if not CreateSignals then Exit;
  if not CreateCrossPPs then Exit;
  if not CreateCrossings then Exit;
  if not CreateCrossLines then Exit;
  if not CreateMLs then Exit;
  if not CreatePABs then Exit;
  if not CreateDABs then Exit;
  if not CreateVSSignals then Exit;
  if not CreateStativ_Fuses then Exit;
  if not CreateRTESysESes then Exit;
  if not CreateRTEZSSignals then Exit;
  if not CreateRTEAddSignals then Exit;
  if not CreateRTEFences then Exit;
  if not CreateRTERoutes then Exit;
  if not CreateSTPs then Exit;
  if not CreateRTENodes then Exit;
  if not CreateExternalApps then Exit;
  if not PostProcessing then Exit;
  Result := true;
end;

function TMSURTECore.CreateGlobalTags;
var
  NewTag : TRTETag;
begin
  //SPPSetValue
  NewTag := TRTETag.Create('SPPSetValue', MPRCore, VT_BOOL, true);
  NewTag.IsOPCTag := true;
  NewTag.PLCTagEntry.IOReadOnly := true;
  NewTag.TagServerTagEntry.Memory := true;
  GlobalTags.AddObject(NewTag.Name, NewTag);
  //GeneralScanTime
  NewTag := TRTETag.Create('GeneralScanTime', MPRCore, VT_I4, MPR.ScanInterval);
  NewTag.PLCTagEntry.Memory := true;
  GlobalTags.AddObject(NewTag.Name, NewTag);
  //GSDelay
  NewTag := TRTETag.Create('GSDelay', MPRCore, VT_I2, MPR.GSDelay div MPR.ScanInterval);
  NewTag.PLCTagEntry.Memory := true;
  GlobalTags.AddObject(NewTag.Name, NewTag);
  if MPR.LZEnabled Then
  begin
    if MPR.SPPType = '1' Then
    begin
      //Frausher
      //FrausherStage1Delay
      NewTag := TRTETag.Create('FrausherStage1Delay', MPRCore, VT_I2, 10);
      FrausherStage1Delay := NewTag;
      NewTag.PLCTagEntry.Memory := true;
      GlobalTags.AddObject(NewTag.Name, NewTag);
    end
    else
    begin
      //ЭССО
      //ResetLZStage1Delay
      NewTag := TRTETag.Create('ResetLZStage1Delay', MPRCore, VT_I2, 50);
      ResetLZStage1Delay := NewTag;
      NewTag.PLCTagEntry.Memory := true;
      GlobalTags.AddObject(NewTag.Name, NewTag);
      //ResetLZStage2Delay
      NewTag := TRTETag.Create('ResetLZStage2Delay', MPRCore, VT_I2, 30);
      ResetLZStage2Delay := NewTag;
      NewTag.PLCTagEntry.Memory := true;
      GlobalTags.AddObject(NewTag.Name, NewTag);
      //ResetLZStage3Delay
      NewTag := TRTETag.Create('ResetLZStage3Delay', MPRCore, VT_I2, 50);
      ResetLZStage3Delay := NewTag;
      NewTag.PLCTagEntry.Memory := true;
      GlobalTags.AddObject(NewTag.Name, NewTag);
    end;
  end;
  if MPR.AllowFormatMessage = 1 then
  begin
    NewTag := TRTETag.Create('ConnectionControlInterval', MPRCore, VT_I2, 100);
    ConnectionControlInterval := NewTag;
    NewTag.PLCTagEntry.Memory := true;
    GlobalTags.AddObject(NewTag.Name, NewTag);
  end;
  //SEConnected
  NewTag := TRTETag.Create('SEConnected', MPRCore, VT_I2, 0);
  SEConnected := NewTag;
  NewTag.PLCTagEntry.Memory := true;
  NewTag.NoTagLogging := not MSURTESettings.LogWatchDogs;
 // NewTag.NoTagLogging := true;
  NewTag.IsOPCTag := true;
  GlobalTags.AddObject(NewTag.Name, NewTag);
  if MSURTESettings.IsEmulation  then
      IASymbols.AddObject(NewTag.Name, NewTag);
  //SEControl_TimeOut
  NewTag := TRTETag.Create('SEControl_TimeOut', MPRCore, VT_I2, 100);
  SEControl_TimeOut := NewTag;
  NewTag.PLCTagEntry.Memory := true;
  GlobalTags.AddObject(NewTag.Name, NewTag);
  if MPR.UPSControl = 1 then
  begin
     NewTag := TRTETag.Create('T' + MPR.StationCode + '_UPS_AC', MPRCore, VT_BOOL, FALSE);
     NewTag.TagServerTagEntry.IOReadOnly := true;
     NewTag.PLCTagEntry.IOReadOnly := true;
     NewTag.PLCTagEntry.ServerAlias := 'UPSMonSrv';
     NewTag.IsOPCTag := true;
     GlobalTags.AddObject(NewTag.Name, NewTag);
     NewTag := TRTETag.Create('T' + MPR.StationCode + '_UPS_BAT', MPRCore, VT_BOOL, FALSE);
     NewTag.TagServerTagEntry.IOReadOnly := true;
     NewTag.PLCTagEntry.IOReadOnly := true;
     NewTag.PLCTagEntry.ServerAlias := 'UPSMonSrv';
     NewTag.IsOPCTag := true;
     GlobalTags.AddObject(NewTag.Name, NewTag);
     NewTag := TRTETag.Create('T' + MPR.StationCode + '_UPS_LINK', MPRCore, VT_BOOL, FALSE);
     NewTag.TagServerTagEntry.IOReadOnly := true;
     NewTag.PLCTagEntry.IOReadOnly := true;
     NewTag.PLCTagEntry.ServerAlias := 'UPSMonSrv';
     NewTag.IsOPCTag := true;
     GlobalTags.AddObject(NewTag.Name, NewTag);
     NewTag := TRTETag.Create('T' + MPR.StationCode + '_UPS_MON', MPRCore, VT_BOOL, FALSE);
     NewTag.TagServerTagEntry.IOReadOnly := true;
     NewTag.PLCTagEntry.IOReadOnly := true;
     NewTag.PLCTagEntry.ServerAlias := 'UPSMonSrv';
     NewTag.IsOPCTag := true;
     GlobalTags.AddObject(NewTag.Name, NewTag);
  end;
  if MPR.CancelDelayMode = 1 Then
  begin
     NewTag := TRTETag.Create('CancelDelayShunt', MPRCore, VT_I2, MPR.CancelDelayShunt div MPR.ScanInterval);
     NewTag.PLCTagEntry.Memory := true;
     GlobalTags.AddObject(NewTag.Name, NewTag);
     NewTag := TRTETag.Create('CancelDelayTrain', MPRCore, VT_I2, MPR.CancelDelayTrain div MPR.ScanInterval);
     NewTag.PLCTagEntry.Memory := true;
     GlobalTags.AddObject(NewTag.Name, NewTag);
   end;
   //PointsResultNoWait
   NewTag := TRTETag.Create('PointsResultNoWait', MPRCore, VT_I2, MPR.PointsResultNoWait);
   NewTag.PLCTagEntry.IOReadOnly := true;
   NewTag.TagServerTagEntry.Memory := true;
   NewTag.IsOPCTag := true;
   GlobalTags.AddObject(NewTag.Name, NewTag);
    //StationTagServer_StationCode
   NewTag := TRTETag.Create('StationTagServer_StationCode', MPRCore, VT_I2, MPR.StationCode);
   NewTag.TagServerTagEntry.Memory := true;
   NewTag.IsOPCTag := true;
   GlobalTags.AddObject(NewTag.Name, NewTag);
   //StationTagServer_WatchDog
   NewTag := TRTETag.Create('StationTagServer_WatchDog', MPRCore, VT_I2, 0);
   StationTagServer_WatchDog := NewTag;
   NewTag.TagServerTagEntry.Memory := true;
   NewTag.NoTagLogging := not MSURTESettings.LogWatchDogs;
   NewTag.IsOPCTag := true;
   GlobalTags.AddObject(NewTag.Name, NewTag);
   //StationView_WatchDog
   NewTag := TRTETag.Create('StationView_WatchDog', MPRCore, VT_I2, -5);
   StationView_WatchDog := NewTag;
   NewTag.TagServerTagEntry.Memory := true;
   NewTag.NoTagLogging := not MSURTESettings.LogWatchDogs;
   NewTag.IsOPCTag := true;
   GlobalTags.AddObject(NewTag.Name, NewTag);
    //StationPLC_StationCode
   NewTag := TRTETag.Create('StationPLC_StationCode', MPRCore, VT_I2, MPR.StationCode);
   NewTag.TagServerTagEntry.IOReadOnly := true;
   NewTag.PLCTagEntry.Memory := true;
   NewTag.IsOPCTag := true;
   GlobalTags.AddObject(NewTag.Name, NewTag);
   //StationPLC_WatchDog
   NewTag := TRTETag.Create('StationPLC_WatchDog', MPRCore, VT_I2, 0);
   StationPLC_WatchDog := NewTag;
   NewTag.TagServerTagEntry.IOReadOnly := true;
   NewTag.NoTagLogging := not MSURTESettings.LogWatchDogs;
   NewTag.PLCTagEntry.Memory := true;
   NewTag.IsOPCTag := true;
   GlobalTags.AddObject(NewTag.Name, NewTag);
   //StationPLC_ErrorStatus
   NewTag := TRTETag.Create('StationPLC_ErrorStatus', MPRCore, VT_I2, 0);
   StationPLC_ErrorStatus := NewTag;
   NewTag.TagServerTagEntry.IOReadOnly := true;
   NewTag.PLCTagEntry.Memory := true;
   NewTag.IsOPCTag := true;
   GlobalTags.AddObject(NewTag.Name, NewTag);
   //StationPLC_Slave
   NewTag := TRTETag.Create('StationPLC_Slave', MPRCore, VT_I2, 0);
   StationPLC_Slave := NewTag;
   NewTag.TagServerTagEntry.IOReadOnly := true;
   NewTag.PLCTagEntry.Memory := true;
   NewTag.IsOPCTag := true;
   GlobalTags.AddObject(NewTag.Name, NewTag);
   //BusOPCServer_WatchDog
   NewTag := TRTETag.Create('BusOPCServer_WatchDog', MPRCore, VT_I2, -5);
   BusOPCServer_WatchDog := NewTag;
   NewTag.TagServerTagEntry.Memory := true;
   NewTag.NoTagLogging := not MSURTESettings.LogWatchDogs;
   NewTag.IsOPCTag := true;
   GlobalTags.AddObject(NewTag.Name, NewTag);
    //StationCode
   NewTag := TRTETag.Create('StationCode', MPRCore, VT_BSTR, MPR.StationCode);
   NewTag.TagServerTagEntry.Memory := true;
   NewTag.IsOPCTag := true;
   GlobalTags.AddObject(NewTag.Name, NewTag);
    //VersionInfo
   NewTag := TRTETag.Create('VersionInfo', MPRCore, VT_BSTR, 'DateTime of Project: ' + DateTimeToStr(Now()));
   NewTag.TagServerTagEntry.Memory := true;
   //NewTag.IsOPCTag = true;
   GlobalTags.AddObject(NewTag.Name, NewTag);
    //PointsCatchDelay
   NewTag := TRTETag.Create('PointsCatchDelay', MPRCore, VT_I2, MPR.PointsCatchDelay div MPR.ScanInterval);
   NewTag.PLCTagEntry.Memory := true;
   GlobalTags.AddObject(NewTag.Name, NewTag);
   //ManPointsCatchDelay
   NewTag := TRTETag.Create('ManPointsCatchDelay', MPRCore, VT_I2, MPR.ManPointsCatchDelay div MPR.ScanInterval);
   NewTag.PLCTagEntry.Memory := true;
   GlobalTags.AddObject(NewTag.Name, NewTag);
    //RMBResetTime
   NewTag := TRTETag.Create('RMBResetTime', MPRCore, VT_I2, MPR.RMBResetTime div MPR.ScanInterval);
   NewTag.PLCTagEntry.Memory := true;
   GlobalTags.AddObject(NewTag.Name, NewTag);
    //SignalCommandTime
   NewTag := TRTETag.Create('SignalCommandTime', MPRCore, VT_I2, 20);
   NewTag.PLCTagEntry.Memory := true;
   GlobalTags.AddObject(NewTag.Name, NewTag);
    //RMBDeadBandTime
   NewTag := TRTETag.Create('RMBDeadBandTime', MPRCore, VT_I2, RMBDeadBandTime_DEF);
   RMBDeadBandTime := NewTag;
   NewTag.PLCTagEntry.Memory := true;
   GlobalTags.AddObject(NewTag.Name, NewTag);
   if MPR.PointsStrob = 1 then
   begin
       //PointsExecTime
       NewTag := TRTETag.Create('PointsExecTime', MPRCore, VT_I2, MPR.PointsExecTime div MPR.ScanInterval);
       NewTag.PLCTagEntry.Memory := true;
       GlobalTags.AddObject(NewTag.Name, NewTag);
       //PointsCatchWait
       NewTag := TRTETag.Create('PointsCatchWait', MPRCore, VT_I2, 200);
       NewTag.PLCTagEntry.Memory := true;
       GlobalTags.AddObject(NewTag.Name, NewTag);
       //PointsHoldTime
       NewTag := TRTETag.Create('PointsHoldTime', MPRCore, VT_I2, MPR.PointsHoldTime div MPR.ScanInterval);
       NewTag.PLCTagEntry.Memory := true;
       GlobalTags.AddObject(NewTag.Name, NewTag);
       //PointsMaxExecTime
       NewTag := TRTETag.Create('PointsMaxExecTime', MPRCore, VT_I2, MPR.PointsMaxExecTime div MPR.ScanInterval);
       NewTag.PLCTagEntry.Memory := true;
       GlobalTags.AddObject(NewTag.Name, NewTag);
   end;
   if not(MPR.PointsDefendMode = 0) then
   begin
       if MPR.SingleSysES then
       begin
           //PointsRMBTime
           NewTag := TRTETag.Create('PointsRMBTime', MPRCore, VT_I2, 70);
           NewTag.PLCTagEntry.Memory := true;
           GlobalTags.AddObject(NewTag.Name, NewTag);
       end;
   end;
   //A_Control_
   NewTag := TRTETag.Create('A_Control_' + MPR.StationCode, MPRCore, VT_BOOL, TRUE);
   NewTag.PLCTagEntry.Memory := true;
   NewTag.IsOPCTag := true;
   GlobalTags.AddObject(NewTag.Name, NewTag);
    //WatchDogCycle
   NewTag := TRTETag.Create('WatchDogCycle', MPRCore, VT_I2, 30);
   WatchDogCycle := NewTag;
   NewTag.PLCTagEntry.Memory := true;
   GlobalTags.AddObject(NewTag.Name, NewTag);
   //StationTagServerWDCycle
   NewTag := TRTETag.Create('StationTagServerWDCycle', MPRCore, VT_I2, 30);
   NewTag.PLCTagEntry.Memory := true;
   GlobalTags.AddObject(NewTag.Name, NewTag);
   //StationViewWDCycle
   NewTag := TRTETag.Create('StationViewWDCycle', MPRCore, VT_I2, 100);
   NewTag.PLCTagEntry.Memory := true;
   GlobalTags.AddObject(NewTag.Name, NewTag);
    //StationView_Connected
   NewTag := TRTETag.Create('StationView_Connected', MPRCore, VT_BOOL, FALSE);
   StationView_Connected := NewTag;
   NewTag.PLCTagEntry.IOReadOnly := true;
   NewTag.TagServerTagEntry.Memory := true;
   NewTag.IsOPCTag := true;
   GlobalTags.AddObject(NewTag.Name, NewTag);
   //StationView_StationCode
   NewTag := TRTETag.Create('StationView_StationCode', MPRCore, VT_I2, 0);
   StationView_StationCode := NewTag;
   NewTag.TagServerTagEntry.Memory := true;
   NewTag.IsOPCTag := true;
   GlobalTags.AddObject(NewTag.Name, NewTag);
    //ReInitAccessName
   NewTag := TRTETag.Create('ReInitAccessName', MPRCore, VT_BSTR, '');
   NewTag.TagServerTagEntry.Memory := true;
   NewTag.IsOPCTag := true;
   GlobalTags.AddObject(NewTag.Name, NewTag);
    //CustomRegister
   NewTag := TRTETag.Create('CustomRegister', MPRCore, VT_BSTR, '');
   NewTag.TagServerTagEntry.Memory := true;
   NewTag.IsOPCTag := true;
   GlobalTags.AddObject(NewTag.Name, NewTag);
    //StartTrigger
   NewTag := TRTETag.Create('StartTrigger', MPRCore, VT_BOOL, FALSE);
   NewTag.PLCTagEntry.IOReadOnly := true;
   NewTag.TagServerTagEntry.Memory := true;
   NewTag.IsOPCTag := true;
   GlobalTags.AddObject(NewTag.Name, NewTag);
    //AutoLastStore
   NewTag := TRTETag.Create('AutoLastStore', MPRCore, VT_BSTR, '');
   NewTag.TagServerTagEntry.Memory := true;
   NewTag.IsOPCTag := true;
   GlobalTags.AddObject(NewTag.Name, NewTag);
    //LastLoadTime
   NewTag := TRTETag.Create('LastLoadTime', MPRCore, VT_BSTR, '');
   NewTag.TagServerTagEntry.Memory := true;
   NewTag.IsOPCTag := true;
   GlobalTags.AddObject(NewTag.Name, NewTag);
    //FIO
   NewTag := TRTETag.Create('FIO', MPRCore,VT_BSTR, '');
   NewTag.TagServerTagEntry.Memory := true;
   NewTag.IsOPCTag := true;
   GlobalTags.AddObject(NewTag.Name, NewTag);
    //SSDEnable
   NewTag := TRTETag.Create('SSDEnable', MPRCore, VT_BOOL, FALSE);
   NewTag.TagServerTagEntry.Memory := true;
   NewTag.IsOPCTag := true;
   GlobalTags.AddObject(NewTag.Name, NewTag);
    //SignalsTime
   NewTag := TRTETag.Create('SignalsTime', MPRCore, VT_I2, 30);
   NewTag.PLCTagEntry.Memory := true;
   GlobalTags.AddObject(NewTag.Name, NewTag);
    //BlinkSignalTime
   NewTag := TRTETag.Create('BlinkSignalTime', MPRCore, VT_I2, 10);
   NewTag.PLCTagEntry.Memory := true;
   GlobalTags.AddObject(NewTag.Name, NewTag);
   //DABHoldTime
   NewTag := TRTETag.Create('DABHoldTime', MPRCore, VT_I2, 20);
   NewTag.PLCTagEntry.Memory := true;
   GlobalTags.AddObject(NewTag.Name, NewTag);
    //DABMaxExecTime
   NewTag := TRTETag.Create('DABMaxExecTime', MPRCore, VT_I2, 40);
   NewTag.PLCTagEntry.Memory := true;
   GlobalTags.AddObject(NewTag.Name, NewTag);
    //KPRepeatTime
   NewTag := TRTETag.Create('KPRepeatTime', MPRCore, VT_I2, 70);
   NewTag.PLCTagEntry.Memory := true;
   GlobalTags.AddObject(NewTag.Name, NewTag);
    //DelayOfMLSignals
   NewTag := TRTETag.Create('DelayOfMLSignals', MPRCore, VT_I2, 50);
   NewTag.PLCTagEntry.Memory := true;
   GlobalTags.AddObject(NewTag.Name, NewTag);
    //BlinkMLSignalTime
   NewTag := TRTETag.Create('BlinkMLSignalTime', MPRCore, VT_I2, 10);
   NewTag.PLCTagEntry.Memory := true;
   GlobalTags.AddObject(NewTag.Name, NewTag);
    //RepeatSignalsDelay
   NewTag := TRTETag.Create('RepeatSignalsDelay', MPRCore, VT_I2, 20);
   RepeatSignalsDelay := NewTag;
   NewTag.PLCTagEntry.Memory := true;
   GlobalTags.AddObject(NewTag.Name, NewTag);
   //CrossingTime
   NewTag := TRTETag.Create('CrossingTime', MPRCore, VT_I2, 50);
   NewTag.PLCTagEntry.Memory := true;
   GlobalTags.AddObject(NewTag.Name, NewTag);
   Result := true;
   //vistgw_watchdog
   NewTag := TRTETag.Create('vistgw_watchdog', MPRCore, VT_I2, -5);
   vistgw_watchdog := NewTag;
   NewTag.NoTagLogging := not MSURTESettings.LogWatchDogs;
   NewTag.IsOPCTag := true;
   GlobalTags.AddObject(NewTag.Name, NewTag);
   //
   NewTag := TRTETag.Create('vistgw_Connected', MPRCore, VT_BOOL, FALSE);
   vistgw_Connected := NewTag;
   NewTag.IsOPCTag := true;
   GlobalTags.AddObject(NewTag.Name, NewTag);
end;

Constructor TRTESection.Create;
var
  NewTag : TRTETag;
begin
  inherited Create(AMPRCore);
  _L1 := nil;
  _SV := nil;
  GeneralTag := nil;
  _GS := nil;
  _SV_IN := nil;
  _SV_OUT := nil;
  _Result := nil;
  _RLZ := nil;
  _AB_1IO_R := nil;
  _AB_1IO_OUT := nil;
  _AB_2IO_L1 := nil;
  _LZ := nil;
  _AXES := nil;
  _LRI := nil;
  _OUT := nil;
  _AB_1SVH_OUT := nil;
  _R := nil;
  RWAB := nil;
  CrossPP := TStringList.Create(false); //объекты не удаляются
  ContainedPoints := TStringList.Create(false);
  CrossType3 := false;
  RWSection := ASct;
  Name := RWSection.Code;
  FCaption := RWSection.Caption;
  FLongCaption := RWSection.LongCaption;
  FLockSignalLink := RWSection.LockSignalLink;
  if not Assigned(MPRCore) then Exit;
  isSlave := (RWSection.Master = 1);
  UABType := RWSection.AB_Type;
  SPPType := RWSection.SPPType;
  //тэги
  if ASct.SectionDummy = '0'  then
  begin
    if ASct.Master = 0 then
    begin
      //L1
      if ASct.WithoutControl = '0'  then
      begin
        NewTag := TRTETag.Create('R' + Name + '_L1', Self, VT_BOOL, false);
        _L1 := NewTag;
        NewTag.Description := ASct.Caption;
        NewTag.PLCTagEntry.Phisical := true;
        if ASct.AutoLock <> '0' then
        begin
          NewTag.TagServerTagEntry.IOReadOnly := true;
          //NewTag.OPCWritable := false;
        end;
        NewTag.IsOPCTag := true;
        MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
        MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
      end;//if ASct.NoControl = '0'
    end//if ASct.Master = 0 then
    else
    begin
      if ASct.Shared <> '0'  then
      begin
         NewTag := TRTETag.Create('R' + Name + '_L1', Self, VT_BOOL, false);
         _L1 := NewTag;
         case SPPType of
          4:
          begin
            NewTag.Description := ASct.Caption;
            NewTag.PLCTagEntry.Phisical := true;
            NewTag.IsOPCTag := true;
            MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
            MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
          end//4
          else
          begin
             NewTag.PLCTagEntry.IOReadOnly := true;
             NewTag.PLCTagEntry.ServerAlias := 'Station'+ASct.Shared;
             NewTag.IsOPCTag := true;
             MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
             if MPRCore.MSURTESettings.IsEmulation  then
                MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
          end;//else
         end;//case
      end;
    end;//if ASct.Master = 0 then
    //_SV
    NewTag := TRTETag.Create('R' + Name + '_SV', Self, VT_I2, 0);
    NewTag.Description := ASct.Caption + ' - тэг логического состояния.';
    _SV := NewTag;
    NewTag.PLCTagEntry.IOReadOnly := true;
    NewTag.TagServerTagEntry.Memory := true;
    NewTag.IsOPCTag := true;
    MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
    if MPRCore.MSURTESettings.IsEmulation  then
      MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
    //главный тэг
    NewTag := TRTETag.Create('R' + Name, Self, VT_I2, 0);
    NewTag.Description := ASct.Caption + ' - главный тэг.';
    GeneralTag := NewTag;
    NewTag.PLCTagEntry.IOReadOnly := true;
    NewTag.TagServerTagEntry.Memory := true;
    NewTag.IsOPCTag := true;
    MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
    //_JS
    NewTag := TRTETag.Create('R' + Name + '_JS', Self, VT_I2, 0);
    NewTag.TagServerTagEntry.Memory := true;
    NewTag.IsOPCTag := true;
    MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
    //_TS
    NewTag := TRTETag.Create('R' + Name + '_TS', Self,VT_I2, 0);
    NewTag.TagServerTagEntry.Memory := true;
    NewTag.IsOPCTag := true;
    MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
    //_LOC
    NewTag := TRTETag.Create('R' + Name + '_LOC', Self, VT_I2, 0);
    NewTag.TagServerTagEntry.Memory := true;
    NewTag.IsOPCTag := true;
    MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
    if ASct.SectionType = 1 then
    begin
        NewTag := TRTETag.Create('R' + Name + '_BE', Self, VT_BOOL, FALSE);
        NewTag.TagServerTagEntry.Memory := true;
        NewTag.IsOPCTag := true;
        MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
        NewTag := TRTETag.Create('R' + Name + '_Timer', Self, VT_I2, 0);
        NewTag.TagServerTagEntry.Memory := true;
        NewTag.IsOPCTag := true;
        MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
    end
    else
    begin
        NewTag := TRTETag.Create('R' + Name + '_EXC', Self, VT_I2, 0);
        NewTag.TagServerTagEntry.Memory := true;
        NewTag.IsOPCTag := true;
        MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
        NewTag := TRTETag.Create('R' + Name + '_Time', Self, VT_I2, 0);
        NewTag.TagServerTagEntry.Memory := true;
        NewTag.IsOPCTag := true;
        MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
    end;
    //_GS
    if ASct.WithoutControl <> '0' then
    begin
        NewTag := TRTETag.Create('R' + Name + '_GS', Self, VT_I2, 0);
    end
    else
    begin
        NewTag := TRTETag.Create('R' + Name + '_GS', Self, VT_I2, 2);
    end;
    NewTag.Description := ASct.Caption + ' - тэг физического состояния.';
    _GS := NewTag;
    NewTag.TagServerTagEntry.IOReadOnly := true;
    NewTag.PLCTagEntry.Memory := true;
    NewTag.IsOPCTag := true;
    MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
    if MPRCore.MSURTESettings.IsEmulation  then
      MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
    //сигнал с соседней станции
    case LockSignalLink of
      1:
      begin
          //_SV_IN
          NewTag := TRTETag.Create('R' + Name + '_SV_IN', Self, VT_BOOL, FALSE);
          _SV_IN := NewTag;
          NewTag.PLCTagEntry.Phisical := true;
          NewTag.TagServerTagEntry.IOReadOnly := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
          //_SV_OUT
          NewTag := TRTETag.Create('R' + Name + '_SV_OUT', Self, VT_BOOL, FALSE);
          _SV_OUT := NewTag;
          NewTag.PLCTagEntry.Phisical := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
      end;//1
      3: //только чтение
      begin
        //_SV_IN
        NewTag := TRTETag.Create('R' + Name + '_SV_IN', Self, VT_BOOL, FALSE);
        _SV_IN := NewTag;
        NewTag.PLCTagEntry.Phisical := true;
        NewTag.TagServerTagEntry.IOReadOnly := true;
        NewTag.IsOPCTag := true;
        MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
        MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
      end;//3
      4: //только запись
      begin
        //_SV_OUT
        NewTag := TRTETag.Create('R' + Name + '_SV_OUT', Self, VT_BOOL, FALSE);
        _SV_OUT := NewTag;
        NewTag.PLCTagEntry.Phisical := true;
        NewTag.IsOPCTag := true;
        MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
        MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
      end;//4
    end;//case
    if ASct.WithoutControl = '0' then
    begin
      if MPRCore.MPR.LZEnabled then
      begin
          if ASct.Master = 0 then
          begin
              NewTag := TRTETag.Create('R' + Name + '_Result', Self, VT_I2, 0);
              _Result := NewTag;
              NewTag.TagServerTagEntry.IOReadOnly := true;
              NewTag.PLCTagEntry.Memory := true;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              NewTag := TRTETag.Create('R' + Name + '_RLZ', Self, VT_BOOL, FALSE);
              _RLZ := NewTag;
              NewTag.PLCTagEntry.IOReadOnly := true;
              NewTag.TagServerTagEntry.Memory := true;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          end;
      end;
    end;
    case (ASct.AB_Type) of
       1:
        begin
            NewTag := TRTETag.Create('R' + Name + '_AB_1IO_R', Self, VT_BOOL, FALSE);
            _AB_1IO_R := NewTag;
            NewTag.PLCTagEntry.IOReadOnly := true;
            NewTag.TagServerTagEntry.Memory := true;
            NewTag.IsOPCTag := true;
            MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
            NewTag := TRTETag.Create('R' + Name + '_AB_1IO_OUT', Self, VT_BOOL, FALSE);
            _AB_1IO_OUT := NewTag;
            NewTag.PLCTagEntry.Phisical := true;
            NewTag.IsOPCTag := true;
            MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
            MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
        end;
        2:
        begin
            NewTag := TRTETag.Create('R' + Name + '_AB_2IO_L1', Self, VT_BOOL, FALSE);
            _AB_2IO_L1 := NewTag;
            NewTag.PLCTagEntry.Phisical := true;
            NewTag.TagServerTagEntry.IOReadOnly := true;
            NewTag.IsOPCTag := true;
            MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
            MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
        end;
    end;//case
    NewTag := TRTETag.Create('R' + Name + '_LZ', Self, VT_BOOL, FALSE);
    _LZ := NewTag;
    NewTag.PLCTagEntry.IOReadOnly := true;
    NewTag.TagServerTagEntry.Memory := true;
    NewTag.IsOPCTag := true;
    MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
    if ASct.Shared <> '0'  then
    begin
      //для сетевых секций
      if ((MPRCore.MPR.AllowFormatMessage = 0) OR (ASct.FormatExchange = 0) OR (ASct.ViaFSGateway = 0)) then
      begin
          NewTag := TRTETag.Create('R' + Name + '_RegEventDir', Self, VT_I2, 0);
          NewTag.TagServerTagEntry.Memory := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          NewTag := TRTETag.Create('R' + Name + '_RegEventQuery', Self, VT_I2, 0);
          NewTag.TagServerTagEntry.Memory := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          NewTag := TRTETag.Create('R' + Name + '_RegEventCode', Self, VT_BSTR, '');
          NewTag.TagServerTagEntry.Memory := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          NewTag := TRTETag.Create('R' + Name + '_RegEventDelta', Self, VT_BSTR, '');
          NewTag.TagServerTagEntry.Memory := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          NewTag := TRTETag.Create('R' + Name + '_RegEventStation', Self, VT_BSTR, '');
          NewTag.TagServerTagEntry.Memory := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          NewTag := TRTETag.Create('Station' + ASct.Shared + '_R' + Name + '_RegEventDelta', Self, VT_BSTR, '');
          NewTag.TagServerTagEntry.IOReadwrite := true;
          NewTag.TagServerTagEntry.OPCItemUseTagname := false;
          NewTag.TagServerTagEntry.ServerAlias := 'Station' + ASct.Shared;
          NewTag.TagServerTagEntry.OPCItemName := 'R' + Name + '_RegEventDelta';
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          NewTag := TRTETag.Create('Station' + ASct.Shared + '_R' + Name + '_RegEventCode', Self, VT_BSTR, '');
          NewTag.TagServerTagEntry.IOReadwrite := true;
          NewTag.TagServerTagEntry.OPCItemUseTagname := false;
          NewTag.TagServerTagEntry.ServerAlias := 'Station' + ASct.Shared;
          NewTag.TagServerTagEntry.OPCItemName := 'R' + Name + '_RegEventCode';
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          NewTag := TRTETag.Create('Station' + ASct.Shared + '_R' + Name + '_RegEventQuery', Self, VT_I2, 0);
          NewTag.TagServerTagEntry.IOReadwrite := true;
          NewTag.TagServerTagEntry.OPCItemUseTagname := false;
          NewTag.TagServerTagEntry.ServerAlias := 'Station' + ASct.Shared;
          NewTag.TagServerTagEntry.OPCItemName := 'R' + Name + '_RegEventQuery';
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          NewTag := TRTETag.Create('Station' + ASct.Shared + '_R' + Name + '_SV', Self, VT_I2, 0);
          NewTag.TagServerTagEntry.IOReadwrite := true;
          NewTag.TagServerTagEntry.OPCItemUseTagname := false;
          NewTag.TagServerTagEntry.ServerAlias := 'Station' + ASct.Shared;
          NewTag.TagServerTagEntry.OPCItemName := 'R' + Name + '_SV';
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          NewTag := TRTETag.Create('Station' + ASct.Shared + '_R' + Name + '_RegEventDir', Self, VT_I2, 0);
          NewTag.TagServerTagEntry.IOReadwrite := true;
          NewTag.TagServerTagEntry.OPCItemUseTagname := false;
          NewTag.TagServerTagEntry.ServerAlias := 'Station' + ASct.Shared;
          NewTag.TagServerTagEntry.OPCItemName := 'R' + Name + '_RegEventDir';
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
      end;
      if ((MPRCore.MPR.AllowFormatMessage = 1) AND (ASct.FormatExchange = 1)) then
      begin
          NewTag := TRTETag.Create('R' + Name + '_Out_Query', Self, VT_BSTR, '');
          NewTag.TagServerTagEntry.Memory := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          if (ASct.ViaFSGateway = 1) then
          begin
              NewTag := TRTETag.Create('R' + Name + '_In_Query', Self, VT_BSTR, '');
              NewTag.TagServerTagEntry.Memory := true;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          end
          else
          begin
              NewTag := TRTETag.Create('Station' + ASct.Shared + '_R' + Name + '_In_Query', Self, VT_BSTR, '');
              NewTag.TagServerTagEntry.IOReadwrite := true;
              NewTag.TagServerTagEntry.OPCItemUseTagname := false;
              NewTag.TagServerTagEntry.OPCItemName := 'R' + Name + '_Out_Query';
              NewTag.TagServerTagEntry.ServerAlias := 'Station' + ASct.Shared;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          end;
      end;
      if (ASct.AutoLock = '4') then
      begin
          NewTag := TRTETag.Create('R' + Name + '_AllowRoute', Self, VT_I2, 0);
          NewTag.TagServerTagEntry.Memory := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          NewTag := TRTETag.Create('Station' + ASct.Shared + '_R' + Name + '_AllowRoute', Self, VT_I2, 0);
          NewTag.TagServerTagEntry.IOReadOnly := true;
          NewTag.TagServerTagEntry.OPCItemUseTagname := false;
          NewTag.TagServerTagEntry.OPCItemName := 'R' + Name + '_AllowRoute';
          NewTag.TagServerTagEntry.ServerAlias := 'Station' + ASct.Shared;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
      end;
    end;
    if MPRCore.MPR.EssoLink = '1' then
    begin
        NewTag := TRTETag.Create('R' + Name + '_AXES', Self, VT_I2, 0);
        _AXES := NewTag;
        NewTag.PLCTagEntry.IOReadOnly := true;
        NewTag.TagServerTagEntry.Memory := true;
        NewTag.IsOPCTag := true;
        MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
        MPRCore.sppIASymbols.AddObject(NewTag.Name,NewTag);
    end;
    if ASct.CheckDowntime >= 1 then
    begin
        NewTag := TRTETag.Create('R' + Name + '_Idle', Self, VT_BSTR, '');
        NewTag.TagServerTagEntry.Memory := true;
        NewTag.IsOPCTag := true;
        MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
    end;
    NewTag := TRTETag.Create('R' + Name + '_S', Self, VT_BSTR, '');
    NewTag.TagServerTagEntry.Memory := true;
    NewTag.IsOPCTag := true;
    MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
    NewTag := TRTETag.Create('R' + Name + '_W', Self, VT_BSTR, '');
    NewTag.TagServerTagEntry.Memory := true;
    NewTag.IsOPCTag := true;
    MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
    NewTag := TRTETag.Create('R' + Name + '_R', Self, VT_BSTR, '');
    _R := NewTag;
    NewTag.TagServerTagEntry.Memory := true;
    NewTag.IsOPCTag := true;
    MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
    NewTag := TRTETag.Create('R' + Name + '_T', Self, VT_BSTR, '');
    NewTag.TagServerTagEntry.Memory := true;
    NewTag.IsOPCTag := true;
    MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
    NewTag := TRTETag.Create('R' + Name + '_Sh', Self, VT_BSTR, '');
    NewTag.TagServerTagEntry.Memory := true;
    NewTag.IsOPCTag := true;
    MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
    NewTag := TRTETag.Create('R' + Name + '_LOT', Self, VT_BSTR, '');
    NewTag.TagServerTagEntry.Memory := true;
    NewTag.IsOPCTag := true;
    MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
    NewTag := TRTETag.Create('R' + Name + '_TRAIN', Self, VT_BSTR, '');
    NewTag.TagServerTagEntry.Memory := true;
    NewTag.IsOPCTag := true;
    MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
    if MPRCore.MPR.CreateLRI = 1 then
    begin
        NewTag := TRTETag.Create('R' + Name + '_LRI', Self, VT_I2, -1);
        _LRI := NewTag;
        NewTag.TagServerTagEntry.Memory := true;
        NewTag.PLCTagEntry.IOReadOnly := true;
        NewTag.IsOPCTag := true;
        MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
    end;
  end;//if ASct.SectionDummy = '0'
end;

function TMSURTECore.CreateSections;
var
  OneRTESection : TRTESection;
  i, ConnIdx : Integer;
  ConnCode : Integer;
begin
  Result := false;
  RTESections.Clear;
  if not Assigned(MPR) then Exit;
  if not MPRLoaded then Exit;
  if Length(MPR.RWSections) <= 0 then Exit;
  OneRTESection := nil;
  for i := 0 to High(MPR.RWSections) do
  begin
    try
      OneRTESection := TRTESection.Create(Self,MPR.RWSections[i]);
      RTESEctions.AddObject(OneRTESection.Name, OneRTESection);
    except
      AppLogger.AddErrorMessage('Секция '+ MPR.RWSections[i].Caption +': сбой при создании объекта.');
      Exit;
    end;
    try
      ConnCode := StrToInt(MPR.RWSections[i].Shared);
    except
      ConnCode := 0;
    end;
    if ConnCode > 0 then
    begin
      ConnIdx := RTEConnections.IndexOf (MPR.RWSections[i].Shared);
      if ConnIdx > -1 then
      begin
        OneRTESection.Connection := TRTEConnect(RTEConnections.Objects[ConnIdx]);
      end;
      {else
      begin
        OneRTESection.Connection := TRTEConnect.Create(Self,MPR.RWSections[i].Shared,(MPR.RWSections[i].ViaFSGateway = 1));
        RTEConnections.AddObject(OneRTESection.Connection.Name, OneRTESection.Connection);
      end;       }
      if OneRTESection.SPPType = 4 then
        if Assigned(OneRTESection.Connection) then
          OneRTESection.Connection.OnFieldBus := TRUE;
    end; //if ConnCode > 0
  end;
  Result := true;
end;

function TRTESection.PostProcessing;
var
  NewTag : TRTETag;
begin
 // Result := false;
  if RWSection.SectionDummy = '0' then
  begin
    if RWSEction.Master = 0 then
    begin
      if (not CrossType3) AND (CrossPP.Count < 2) then
      begin
        //OUT
        if RWSection.WithoutControl = '0' then
        begin
          NewTag := TRTETag.Create('R' + Name + '_OUT', Self, VT_BOOL, FALSE);
          _OUT := NewTag;
          NewTag.PLCTagEntry.Phisical := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
        end; //if RWSection.WithoutControl = '0'
      end;//if (not CrossType3) AND (CrossPP.Count < 2) then
    end;//if RWSEction.Master = 0 then
    case RWSection.AB_Type of
      2:
      begin
        if MPRCore.isQ1SVHSignalExists(Name) <> nil then
        begin
            //_AB_1SVH_OUT
            NewTag := TRTETag.Create('R' + Name + '_AB_1SVH_OUT', Self, VT_BOOL, FALSE);
            _AB_1SVH_OUT := NewTag;
            NewTag.PLCTagEntry.Phisical := true;
            NewTag.IsOPCTag := true;
            MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
        end;//if MPRCore.isQ1SVHSignalExists(Name) <> nil then
      end;//2
    end;//case
  end;//if RWSection.SectionDummy = '0'
  Result := true;
end;

function TMSURTECore.PostProcessing;
var
  ThisObj : TRTEMatter;
  i : Integer;
begin
  Result := false;
  if RTESections.Count > 0 then
  begin
    for i := 0 to RTESections.Count - 1 do
    begin
      ThisObj := TRTEMatter(RTESections.Objects[i]);
      if not ThisObj.PostProcessing then
      begin
        AppLogger.AddErrorMessage('Секция '+ TRTESection(ThisObj).Caption +': сбой постпроцессинга.');
        Exit;
      end;
    end;//for i
  end;//if RTESections.Count > 0
  if RTEPoints.Count > 0 then
  begin
    for i := 0 to RTEPoints.Count - 1 do
    begin
      ThisObj := TRTEMatter(RTEPoints.Objects[i]);
      if not ThisObj.PostProcessing then
      begin
        AppLogger.AddErrorMessage('Стрелка '+ TRTEPoint(ThisObj).Caption +': сбой постпроцессинга.');
        Exit;
      end;
    end;//for i
  end;//if
  if RTEMainPoints.Count > 0 then
  begin
    for i := 0 to RTEMainPoints.Count - 1 do
    begin
      ThisObj := TRTEMatter(RTEMainPoints.Objects[i]);
      if not ThisObj.PostProcessing then
      begin
        AppLogger.AddErrorMessage('Главная стрелка '+ TRTEMainPoint(ThisObj).Caption +': сбой постпроцессинга.');
        Exit;
      end;
    end;
  end; //if RTEMainPoints.Count > 0
  if RTESignals.Count > 0 then
  begin
    for i := 0 to RTESignals.Count - 1 do
    begin
      ThisObj := TRTEMatter(RTESignals.Objects[i]);
      if not ThisObj.PostProcessing then
      begin
        AppLogger.AddErrorMessage('Светофор '+ TRTESignal(ThisObj).Caption +': сбой постпроцессинга.');
        Exit;
      end;
    end;//for i
  end;//if RTESections.Count > 0
  if RTERoutes.Count > 0 then
  begin
    for i := 0 to RTERoutes.Count - 1 do
    begin
      ThisObj := TRTEMatter(RTERoutes.Objects[i]);
      if not ThisObj.PostProcessing then
      begin
        AppLogger.AddErrorMessage('Маршрут '+ TRTERoute(ThisObj).Caption +': сбой постпроцессинга.');
        Exit;
      end;
    end;//for i
  end;
  if RTEPABs.Count > 0 then
  begin
    for i := 0 to RTEPABs.Count - 1 do
    begin
      ThisObj := TRTEMatter(RTEPABs.Objects[i]);
      if not ThisObj.PostProcessing then
      begin
        AppLogger.AddErrorMessage('ПАБ '+ TRTEPAB(ThisObj).Caption +': сбой постпроцессинга.');
        Exit;
      end;
    end;//for i
  end;
  if MSURTESettings.NWEnabled  then
  begin
    MSURTESettings.NWEnabled := (RTEConnections.Count > 0);
  end;
  Result := true;
end;

Constructor TRTEConnect.Create(AMPRCore: TMSURTECore; AConnectionCode: string; AFSGateway: Boolean);
var
  NewTag : TRTETag;
begin
  inherited Create(AMPRCore);
  arrIndex := -1;
  Name := AConnectionCode;
  FSGateway := AFSGateway;
  //тэги
  MainTag := nil;
  _SL := nil;
  _EMULATE := nil;
  _LET_EMULATE := nil;
  _SL_EMULATE := nil;
  ViewTagNameConnected := nil;
  StationConnected := nil;
  _SV := nil;
  NET_SV := nil;
  _Watch := nil;
  FieldBusConnected := nil;
  MasterState := nil;
  MasterState_OUT := nil;
  _SF := nil;
  //
  NewTag := TRTETag.Create('Connection_' + Name, Self, VT_I2, 0);
  MainTag := NewTag;
  NewTag.PLCTagEntry.IOReadOnly := true;
  NewTag.TagServerTagEntry.Memory := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  if MPRCore.MSURTESettings.IsEmulation  then
      MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
  //_SL
  NewTag := TRTETag.Create('Connection_' + Name + '_SL', Self, VT_I2, 0);
  _SL := NewTag;
  NewTag.PLCTagEntry.Memory := true;
  NewTag.TagServerTagEntry.IOReadOnly := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  //_EMULATE
  NewTag := TRTETag.Create('Connection_' + Name + '_EMULATE', Self, VT_BOOL, FALSE);
  _EMULATE := NewTag;
  NewTag.PLCTagEntry.Memory := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  if MPRCore.MSURTESettings.IsEmulation  then
      MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
  //_LET_EMULATE
  NewTag := TRTETag.Create('Connection_' + Name + '_LET_EMULATE', Self, VT_BOOL, FALSE);
  _LET_EMULATE := NewTag;
  NewTag.PLCTagEntry.Memory := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  if MPRCore.MSURTESettings.IsEmulation  then
      MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
  //_SL_EMULATE
  NewTag := TRTETag.Create('Connection_' + Name + '_SL_EMULATE', Self, VT_I2, 0);
  _SL_EMULATE := NewTag;
  NewTag.PLCTagEntry.Memory := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  if MPRCore.MSURTESettings.IsEmulation  then
      MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
  if ((MPRCore.MPR.AllowFormatMessage = 1) AND FSGateway) then
  begin
      //ControlTimer
      NewTag := TRTETag.Create('Connection' + Name + 'ControlTimer', Self, VT_I2, 0);
      NewTag.PLCTagEntry.Memory := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  end;
  if ((MPRCore.MPR.AllowFormatMessage = 0) OR (not FSGateway)) then
  begin
      NewTag := TRTETag.Create('Station' + Name + '_Connection_' + MPRCore.MPR.StationCode + '_SV', Self, VT_I2, 0);
      NET_SV := NewTag;
      NewTag.TagServerTagEntry.IOReadwrite := true;
      NewTag.TagServerTagEntry.OPCItemUseTagname := false;
      NewTag.TagServerTagEntry.OPCItemName := 'Connection_' + MPRCore.MPR.StationCode + '_SV';
      NewTag.TagServerTagEntry.ServerAlias := 'Station' + Name;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
      NewTag := TRTETag.Create('View' + Name + 'TagNameConnected', Self, VT_I2, 0);
      ViewTagNameConnected := NewTag;
      NewTag.PLCTagEntry.IOReadOnly := true;
      NewTag.PLCTagEntry.OPCItemUseTagname := false;
      NewTag.PLCTagEntry.OPCItemName := 'ViewTagNameConnected';
      NewTag.PLCTagEntry.ServerAlias := 'Station' + Name;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
      NewTag := TRTETag.Create('Station' + Name + 'Connected', Self, VT_BOOL, FALSE);
      StationConnected := NewTag;
      NewTag.PLCTagEntry.IOReadOnly := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  end
  else
  begin
      //Watch
      NewTag := TRTETag.Create('Connection' + Name + 'Watch', Self, VT_I2, 0);
      _Watch := NewTag;
      NewTag.TagServerTagEntry.Memory := true;
      NewTag.PLCTagEntry.IOReadOnly := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  end;
  NewTag := TRTETag.Create('Connection_' + Name + '_SV', Self, VT_I2, 1);
  _SV := NewTag;
  NewTag.TagServerTagEntry.Memory := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  //FieldBusConnected
  NewTag := TRTETag.Create('NC' + AMPRCore.MPR.StationCode + '_COMM' + Name, Self, VT_BOOL, false);
  FieldBusConnected := NewTag;
  NewTag.PLCTagEntry.Phisical := true;
  NewTag.IsOPCTag := true;
  NewTag.TagServerTagEntry.IOReadOnly := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
  NewTag := TRTETag.Create('NC' + Name + '_MasterState', Self, VT_BOOL, false);
  MasterState := NewTag;
  NewTag.PLCTagEntry.Phisical := true;
  NewTag.IsOPCTag := true;
  NewTag.TagServerTagEntry.IOReadOnly := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
  NewTag := TRTETag.Create('NC_MasterState' + Name, Self, VT_BOOL, false);
  MasterState_OUT := NewTag;
  NewTag.PLCTagEntry.Phisical := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
  //_SF
  NewTag := TRTETag.Create('Connection_' + Name + '_SF', Self, VT_I2, 0);
  _SF := NewTag;
  NewTag.PLCTagEntry.Memory := true;
  NewTag.TagServerTagEntry.IOReadOnly := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
end;

Constructor TRTEConnect.Create(AMPRCore : TMSURTECore; AIdx : Integer); //создание соединения из массива МПР
var
  NewTag : TRTETag;
begin
  inherited Create(AMPRCore);
  if not Assigned(AMPRCore) then Exit;
  if not Assigned(AMPRCore.MPR) then Exit;
  if Length(AMPRCore.MPR.RWConnections) = 0 then Exit;
  if (AIdx < 0) OR (AIdx > High(AMPRCore.MPR.RWConnections)) then Exit;

  arrIndex := AIdx;
  RWConnection := TRWConnection(AMPRCore.MPR.RWConnections[AIdx]);
  //if not Assigned(RWConnection) then Exit;
  Name := RWConnection.Code;
  FSGateway := (RWConnection.ViaFSGateway=1);
  OnFieldBus := RWConnection.OnFieldBus;
  //тэги
  MainTag := nil;
  _SL := nil;
  _EMULATE := nil;
  _LET_EMULATE := nil;
  _SL_EMULATE := nil;
  ViewTagNameConnected := nil;
  StationConnected := nil;
  _SV := nil;
  NET_SV := nil;
  _Watch := nil;
  FieldBusConnected := nil;
  MasterState := nil;
  MasterState_OUT := nil;
  _SF := nil;
  //
  NewTag := TRTETag.Create('Connection_' + Name, Self, VT_I2, 0);
  MainTag := NewTag;
  NewTag.PLCTagEntry.IOReadOnly := true;
  NewTag.TagServerTagEntry.Memory := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  if MPRCore.MSURTESettings.IsEmulation  then
      MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
  //_SL
  NewTag := TRTETag.Create('Connection_' + Name + '_SL', Self, VT_I2, 0);
  _SL := NewTag;
  NewTag.PLCTagEntry.Memory := true;
  NewTag.TagServerTagEntry.IOReadOnly := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  //_EMULATE
  NewTag := TRTETag.Create('Connection_' + Name + '_EMULATE', Self, VT_BOOL, FALSE);
  _EMULATE := NewTag;
  NewTag.PLCTagEntry.Memory := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  if MPRCore.MSURTESettings.IsEmulation  then
      MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
  //_LET_EMULATE
  NewTag := TRTETag.Create('Connection_' + Name + '_LET_EMULATE', Self, VT_BOOL, FALSE);
  _LET_EMULATE := NewTag;
  NewTag.PLCTagEntry.Memory := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  if MPRCore.MSURTESettings.IsEmulation  then
      MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
  //_SL_EMULATE
  NewTag := TRTETag.Create('Connection_' + Name + '_SL_EMULATE', Self, VT_I2, 0);
  _SL_EMULATE := NewTag;
  NewTag.PLCTagEntry.Memory := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  if MPRCore.MSURTESettings.IsEmulation  then
      MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
  if ((MPRCore.MPR.AllowFormatMessage = 1) AND FSGateway) then
  begin
      //ControlTimer
      NewTag := TRTETag.Create('Connection' + Name + 'ControlTimer', Self, VT_I2, 0);
      NewTag.PLCTagEntry.Memory := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  end;
  if ((MPRCore.MPR.AllowFormatMessage = 0) OR (not FSGateway)) then
  begin
      NewTag := TRTETag.Create('Station' + Name + '_Connection_' + MPRCore.MPR.StationCode + '_SV', Self, VT_I2, 0);
      NET_SV := NewTag;
      NewTag.TagServerTagEntry.IOReadwrite := true;
      NewTag.TagServerTagEntry.OPCItemUseTagname := false;
      NewTag.TagServerTagEntry.OPCItemName := 'Connection_' + MPRCore.MPR.StationCode + '_SV';
      NewTag.TagServerTagEntry.ServerAlias := 'Station' + Name;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
      NewTag := TRTETag.Create('View' + Name + 'TagNameConnected', Self, VT_I2, 0);
      ViewTagNameConnected := NewTag;
      NewTag.PLCTagEntry.IOReadOnly := true;
      NewTag.PLCTagEntry.OPCItemUseTagname := false;
      NewTag.PLCTagEntry.OPCItemName := 'ViewTagNameConnected';
      NewTag.PLCTagEntry.ServerAlias := 'Station' + Name;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
      NewTag := TRTETag.Create('Station' + Name + 'Connected', Self, VT_BOOL, FALSE);
      StationConnected := NewTag;
      NewTag.PLCTagEntry.IOReadOnly := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  end
  else
  begin
      //Watch
      NewTag := TRTETag.Create('Connection' + Name + 'Watch', Self, VT_I2, 0);
      _Watch := NewTag;
      NewTag.TagServerTagEntry.Memory := true;
      NewTag.PLCTagEntry.IOReadOnly := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  end;
  NewTag := TRTETag.Create('Connection_' + Name + '_SV', Self, VT_I2, 1);
  _SV := NewTag;
  NewTag.TagServerTagEntry.Memory := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  //FieldBusConnected
  If OnFieldBus then
  begin
    NewTag := TRTETag.Create('NC' + AMPRCore.MPR.StationCode + '_COMM' + Name, Self, VT_BOOL,FALSE);
    FieldBusConnected := NewTag;
    NewTag.PLCTagEntry.Phisical := true;
    NewTag.IsOPCTag := true;
    //NewTag.forCstApps := true;   //тэг нужен StationView
    //NewTag.OPCWritable := false; //писать нельзя
    NewTag.TagServerTagEntry.IOReadOnly := true;
    MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
    MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
    NewTag := TRTETag.Create('NC' + Name + '_MasterState', Self, VT_BOOL,FALSE);
    MasterState := NewTag;
    NewTag.PLCTagEntry.Phisical := true;
    NewTag.IsOPCTag := true;
    //NewTag.forCstApps := true;   //тэг нужен StationView
    //NewTag.OPCWritable := false; //писать нельзя
    NewTag.TagServerTagEntry.IOReadOnly := true;
    MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
    MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
    NewTag := TRTETag.Create('NC_MasterState' + Name, Self, VT_BOOL,FALSE);
    MasterState_OUT := NewTag;
    NewTag.PLCTagEntry.Phisical := true;
    NewTag.IsOPCTag := true;
    NewTag.forCstApps := true;   //тэг нужен StationView
    MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
    MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
  end
  else
  begin
    FieldBusConnected := nil;
  end;
  //_SF
  NewTag := TRTETag.Create('Connection_' + Name + '_SF', Self, VT_I2, 0);
  _SF := NewTag;
  NewTag.PLCTagEntry.Memory := true;
  NewTag.TagServerTagEntry.IOReadOnly := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
end;

Constructor TRTEPoint.Create;
var
  OwnerSection : string;
  SctIdx : Integer;
begin
  inherited Create(AMPRCore);
  OwnerRTESection := nil;
  MainPoint := nil;
  RWThePoint := APnt;
  Name := RWThePoint.Code;
  FCaption := RWThePoint.Caption;
  OwnerSection := RWThePoint.OwnerSection;
  DiscReadOnly := RWThePoint.Field_15;
  FencesWhereInvolve := TStringList.Create(false);
  PointByBranch := nil;
  CodingName := Name.Replace(MPRCore.MPR.StationCode + '_', '');
  if RWThePoint.MainPoints then
    PointType := 1
  else
    PointType := 0;
  if (not OwnerSection.Equals(string.Empty)) AND (not OwnerSection.Equals('0')) then
  begin
      if Assigned(MPRCore) then
        if MPRCore.RTESections.Count > 0 then
          begin
            SctIdx := MPRCore.RTESections.IndexOf(OwnerSection);
            if SctIdx > -1 then
            begin
              OwnerRTESection := TRTESection(MPRCore.RTESections.Objects [SctIdx]);
              if Assigned(OwnerRTESection) then
              begin
                if OwnerRTESection.ContainedPoints.IndexOf(Name)= -1 then
                begin
                  OwnerRTESection.ContainedPoints.AddObject(Name, Self);
                end;
              end;
            end;
          end;
  end;
end;

Destructor TRTEPoint.Destroy;
begin
  if Assigned(FencesWhereInvolve) then
  begin
    FencesWhereInvolve.Free;
    FencesWhereInvolve := nil;
  end;
  inherited;
end;

function TRTEPoint.PostProcessing;
var
  NewTag : TRTETag;
  ThisFence : TRTEFence;
  i : Integer;
begin
  if PointType = 1 then
  begin
      if FencesWhereInvolve.Count > 0 then
      begin
          for i := 0 to FencesWhereInvolve.Count - 1 do
          begin
              ThisFence := TRTEFence(FencesWhereInvolve.Objects[i]);
              NewTag := TRTETag.Create('P' + Name + '_' + ThisFence.CodingName + '_F', Self, VT_BOOL, FALSE);
              NewTag.TagServerTagEntry.IOReadwrite := true;
              NewTag.PLCTagEntry.Memory := true;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name,NewTag);
              if Assigned(MainPoint) then
              begin
                if ThisFence.Idx > -1 then
                begin
                  MainPoint.FBLK[ThisFence.Idx] := NewTag;
                end;
              end;
          end;
          NewTag := TRTETag.Create('P' + Name + '_Result_Fence', Self, VT_I2, 0);
          NewTag.PLCTagEntry.IOReadOnly := true;
          NewTag.TagServerTagEntry.Memory := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          if Assigned(MainPoint) then
            MainPoint._Result_Fence := NewTag;
          NewTag := TRTETag.Create('P' + Name + '_Command_Fence', Self, VT_I2, 0);
          NewTag.PLCTagEntry.Memory := true;
          NewTag.TagServerTagEntry.IOReadOnly := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          if Assigned(MainPoint) then
            MainPoint._Command_Fence := NewTag;
      end; //if FencesWhereInvolve.Count > 0 then
  end;//if PointType = 1 then
  Result := true;
end;

function TMSURTECore.CreatePoints;
var
  OneRTEPoint : TRTEPoint;
  i, ConnCode, ConnIdx, PntIdx : Integer;
  OneRTEMainPoint : TRTEMainPoint;
begin
  Result := false;
  RTEPoints.Clear;
  if not Assigned(MPR) then Exit;
  if not MPRLoaded then Exit;
  if Length(MPR.RWThePoints) <= 0 then Exit;
  OneRTEPoint := nil;
  for i := 0 to High(MPR.RWThePoints) do
  begin
    try
      OneRTEPoint := TRTEPOint.Create(Self,MPR.RWThePoints[i]);
      RTEPoints.AddObject(OneRTEPoint.Name, OneRTEPoint);
    except
      AppLogger.AddErrorMessage('Стрелка '+ MPR.RWThePoints[i].Caption +': сбой при создании объекта.');
      Exit;
    end;
    try
      ConnCode := StrToInt(MPR.RWThePoints[i].StationCode.Trim());
    except
      ConnCode := 0;
    end;
    if ConnCode > 0 then
    begin
      ConnIdx := RTEConnections.IndexOf (MPR.RWThePoints[i].StationCode.Trim());
      if ConnIdx > -1 then
      begin
        OneRTEPoint.Connection := TRTEConnect(RTEConnections.Objects[ConnIdx]);
      end;
      {else
      begin
        if Assigned(OneRTEPoint.OwnerRTESection) then
        begin
          OneRTEPoint.Connection := TRTEConnect.Create(Self,MPR.RWThePoints[i].StationCode.Trim(),(OneRTEPoint.OwnerRTESection.RWSection.ViaFSGateway = 1));
        end
        else
        begin
          OneRTEPoint.Connection := TRTEConnect.Create(Self,MPR.RWThePoints[i].StationCode.Trim(),false);
        end;
        RTEConnections.AddObject(OneRTEPoint.Connection.Name, OneRTEPoint.Connection);
      end; }
      if OneRTEPoint.DiscReadOnly = 1 then
        if Assigned(OneRTEPoint.Connection) then
          OneRTEPoint.Connection.OnFieldBus := TRUE;
    end; //if ConnCode > 0
  end;//for i
  //связываем стрелки по съезду
  if RTEPoints.Count > 0 then
  begin
    for i := 0 to RTEPoints.Count - 1 do
    begin
        OneRTEPoint := TRTEPoint(RTEPoints.Objects[i]);
        if (not OneRTEPoint.RWThePoint.WithPoints.Equals(string.Empty)) AND (not OneRTEPoint.RWThePoint.WithPoints.Equals('0')) then
        begin
          PntIdx := RTEPoints.IndexOf(OneRTEPoint.RWThePoint.WithPoints.Trim());
          if PntIdx > -1 then
          begin
            OneRTEPoint.PointByBranch := TRTEPoint(RTEPoints.Objects[PntIdx]);
          end;//if PntIdx > -1 then
        end;//if
    end;//for i
  end;//if RTEPoints.Count > 0 then
  //главные стрелки
  if Length(MPR.RWTheMainPoints) <= 0 then Exit;
  OneRTEMainPoint := nil;
  for i := 0 to High(MPR.RWTheMainPoints) do
  begin
    try
      OneRTEMainPoint := TRTEMainPoint.Create(Self,MPR.RWTheMainPoints[i]);
    except
      AppLogger.AddErrorMessage('Главная стрелка '+ MPR.RWTheMainPoints[i].Caption +': сбой при создании объекта.');
      Exit;
    end;
    OneRTEMainPoint.Idx := RTEMainPoints.AddObject(OneRTEMainPoint.Name, OneRTEMainPoint);
  end;//for i
  Result := true;
end;

Constructor TRTESignal.Create;
var
  NewTag : TRTETag;
  SctIdx : Integer;
begin
  inherited Create(AMPRCore);
  //тэги
    _OFF := nil;
    MainTag := nil;
    _F := nil;
    _Result := nil;
    _DeviceState := nil;
    _SK := nil;
    _OPER := nil;
    _Command := nil;
    _SignalOn := nil;
    _BlOCK := nil;
    //красный
    _CTL0 := nil;
    _L0 := nil;
    //белый
    _CTL1 := nil;
    _L1 := nil;
    //зеленый
    _CTL4 := nil;
    _L2 := nil;
    //желтый верхний
    _L3 := nil;
    _CTL3 := nil;
    //желтый нижний
    _L4 := nil;
    _CTL2 := nil;
    _CTL21 := nil;
    //проходной
    _OUT1 := nil;
    _OUT2 := nil;
    _OUT3 := nil;
    NETSrc := nil;
  RWSignal := ASgn;
  Name := RWSignal.Code;
  FCaption := RWSignal.Caption;
  CodingName := Name.Replace(MPRCore.MPR.StationCode + '_', '');
  FSignalType := RWSignal.SignalType;
  FSignalSubType := RWSignal.SignalSubType;
  FAdditionalSubType := RWSignal.PoputType;
  FUnVisible := (RWSignal.SignalVisible = '1');
  RTEStandSection := nil;
  Q1SVH_OUTSignalExists := (RWSignal.SVH_OUT = '1');
  ShST2Crossings := TStringList.Create(false);
  Connection := nil;
  if (MPRCore.RTESections.Count > 0) then
  begin
    SctIdx := MPRCore.RTESections.IndexOf (RWSignal.SectionCode);
    if (SctIdx > -1) then
    begin
        RTEStandSection := TRTESection(MPRCore.RTESections.Objects[SctIdx]);
        if Assigned(RTEStandSection.Connection)  then
          Connection := RTEStandSection.Connection;
    end;
  end;
  //тэги
  if (SignalType <> 4) OR (SignalType <> 5) then
  begin
    NewTag := TRTETag.Create('S' + Name + '_OFF', Self, VT_BOOL, FALSE);
    _OFF := NewTag;
    NewTag.TagServerTagEntry.Memory := true;
    NewTag.PLCTagEntry.IOReadOnly := true;
    NewTag.IsOPCTag := true;
    MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  end;
  if SignalType <> 4 then
  begin
      NewTag := TRTETag.Create('S' + Name, Self, VT_I2, 0);
      MainTag := NewTag;
      NewTag.PLCTagEntry.Memory := true;
      NewTag.TagServerTagEntry.IOReadOnly := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  end;
  case (SignalType) of
    1: //маневровый
    begin
      case (SignalSubType) of
        2:
        begin
            if (MPRCore.MPR.AllowSTP) AND (MPRCore.MPR.Man2Exists) then
            begin
                NewTag := TRTETag.Create('S' + Name + '_F', Self, VT_BOOL, FALSE);
                _F := NewTag;
                NewTag.PLCTagEntry.IOReadOnly := true;
                NewTag.TagServerTagEntry.Memory := true;
                NewTag.IsOPCTag := true;
                MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
            end;
        end;//2
      end;//case (SignalSubType)
    end;//1
  end;//case (SignalType)
  case (SignalType) of
    1,2,3,6:
    begin
      NewTag := TRTETag.Create('S' + Name + '_Result', Self, VT_I2, -1);
      _Result := NewTag;
      NewTag.PLCTagEntry.Memory := true;
      NewTag.TagServerTagEntry.IOReadOnly := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
      NewTag := TRTETag.Create('S' + Name + '_DeviceState', Self, VT_I2, 0);
      _DeviceState := NewTag;
      NewTag.PLCTagEntry.Memory := true;
      NewTag.TagServerTagEntry.IOReadOnly := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
    end; //1,2,3,6:
    7:
    begin
      NewTag := TRTETag.Create('S' + Name + '_DeviceState', Self, VT_I2, 0);
      _DeviceState := NewTag;
      NewTag.PLCTagEntry.Memory := true;
      NewTag.TagServerTagEntry.IOReadOnly := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
      if SignalSubType = 0 then
      begin
          if MPRCore.MPR.SpeedLimit then
          begin
              //_SK
              NewTag := TRTETag.Create('S' + Name + '_SK', Self, VT_BOOL, FALSE);
              _SK := NewTag;
              NewTag.PLCTagEntry.IOReadOnly := true;
              NewTag.TagServerTagEntry.Memory := true;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          end;
      end;
    end;//7
    8:
    begin
        NewTag := TRTETag.Create('S' + Name + '_DeviceState', Self, VT_I2, 0);
        _DeviceState := NewTag;
        NewTag.PLCTagEntry.Memory := true;
        NewTag.TagServerTagEntry.IOReadOnly := true;
        NewTag.IsOPCTag := true;
        MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
    end;//8
  end;//case (SignalType) of
  if MPRCore.MPR.F_3_5_10_11_MPR then
  begin
    NewTag := TRTETag.Create('S' + Name + '_OPER', Self, VT_I2, 0);
    _OPER := NewTag;
    NewTag.PLCTagEntry.IOReadOnly := true;
    NewTag.TagServerTagEntry.Memory := true;
    NewTag.IsOPCTag := true;
    MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
    case (SignalType) of
        1,2,3,6:
        begin
            NewTag := TRTETag.Create('S' + Name + '_Command', Self, VT_I2, -1);
            _Command := NewTag;
            NewTag.PLCTagEntry.IOReadOnly := true;
            NewTag.TagServerTagEntry.Memory := true;
            NewTag.IsOPCTag := true;
            MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
            NewTag := TRTETag.Create('S' + Name + '_SignalOn', Self, VT_I2, 0);
            _SignalOn := NewTag;
            NewTag.PLCTagEntry.IOReadwrite := true;
            NewTag.TagServerTagEntry.Memory := true;
            NewTag.IsOPCTag := true;
            MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
        end;//1,2,3,6
    end;//case
  end;//if MPRCore.MPR.F_3_5_10_11_MPR then
  //входные/выходные сигналы
  case (SignalType) of
    1: //маневровый
    begin
      if SignalSubType < 2 then
      begin
          case (RWSignal.SignalLockType) of
              0:
              begin
                if (MPRCore.MPR.ShuntBlock = '1') then
                begin
                    //Блокировка разрешаещего сигнала
                    NewTag := TRTETag.Create('S' + Name + '_BLOCK', Self, VT_BOOL, FALSE);
                    _BLOCK := NewTag;
                    NewTag.PLCTagEntry.Phisical := true;
                    NewTag.IsOPCTag := true;
                    MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
                    MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
                end;//if (MPRCore.MPR.ShuntBlock = '1') then
              end;//0
              1: //с помощью релейного индивидуального модуля УСО
              begin
                  //Блокировка разрешаещего сигнала
                  NewTag := TRTETag.Create('S' + Name + '_BLOCK', Self, VT_BOOL, FALSE);
                  _BLOCK := NewTag;
                  NewTag.PLCTagEntry.Phisical := true;
                  NewTag.IsOPCTag := true;
                  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
                  MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
              end;//1
          end;//case (RWSignal.SignalLockType)
      end;//if SignalSubType < 2 then
      //Красный
      NewTag := TRTETag.Create('S' + Name + '_CTL0', Self, VT_BOOL, FALSE);
      _CTL0 := NewTag;
      NewTag.PLCTagEntry.Phisical := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
      MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
      //Белый
      NewTag := TRTETag.Create('S' + Name + '_CTL1', Self, VT_BOOL, FALSE);
      _CTL1 := NewTag;
      NewTag.PLCTagEntry.Phisical := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
      MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
      if MPRCore.MPR.Man2Exists then
      begin
          case (SignalSubType) of
              2:
              begin
                NewTag := TRTETag.Create('S' + Name + '_CTL2', Self, VT_BOOL, FALSE);
                _CTL2 := NewTag;
                NewTag.PLCTagEntry.Phisical := true;
                NewTag.IsOPCTag := true;
                MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
                MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
                NewTag := TRTETag.Create('S' + Name + '_CTL21', Self, VT_BOOL, FALSE);
                _CTL21 := NewTag;
                NewTag.PLCTagEntry.Phisical := true;
                NewTag.IsOPCTag := true;
                MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
                MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
                //L0
                NewTag := TRTETag.Create('S' + Name + '_L0', Self, VT_BOOL, FALSE);
                _L0 := NewTag;
                NewTag.PLCTagEntry.Phisical := true;
                NewTag.IsOPCTag := true;
                MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
                MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
              end;//2
              3:
              begin
                NewTag := TRTETag.Create('S' + Name + '_CTL2', Self, VT_BOOL, FALSE);
                _CTL2 := NewTag;
                NewTag.PLCTagEntry.Phisical := true;
                NewTag.IsOPCTag := true;
                MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
                MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
                //L0
                NewTag := TRTETag.Create('S' + Name + '_L0', Self, VT_BOOL, FALSE);
                _L0 := NewTag;
                NewTag.PLCTagEntry.Phisical := true;
                NewTag.IsOPCTag := true;
                MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
                MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
              end;//3
          end;//case (SignalSubType) of
      end;//if MPRCore.MPR.Man2Exists
      //L1
      NewTag := TRTETag.Create('S' + Name + '_L1', Self, VT_BOOL, FALSE);
      _L1 := NewTag;
      NewTag.PLCTagEntry.Phisical := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
      MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
      //L2
      NewTag := TRTETag.Create('S' + Name + '_L2', Self, VT_BOOL, FALSE);
      _L2 := NewTag;
      NewTag.PLCTagEntry.Phisical := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
      MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
    end;//1
    2: //входной
    begin
        //Блокировка разрешаещего сигнала
        NewTag := TRTETag.Create('S' + Name + '_BLOCK', Self, VT_BOOL, FALSE);
        _BLOCK := NewTag;
        NewTag.PLCTagEntry.Phisical := true;
        NewTag.IsOPCTag := true;
        MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
        MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
        //L0 - контроль красного
        NewTag := TRTETag.Create('S' + Name + '_L0', Self, VT_BOOL, FALSE);
        _L0 := NewTag;
        NewTag.PLCTagEntry.Phisical := true;
        NewTag.IsOPCTag := true;
        MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
        MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
        //CTL0
        NewTag := TRTETag.Create('S' + Name + '_CTL0', Self, VT_BOOL, FALSE);
        _CTL0 := NewTag;
        NewTag.PLCTagEntry.Phisical := true;
        NewTag.IsOPCTag := true;
        MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
        MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
        if RWSignal.BeManevr then
        begin
            //L1 - Контроль Белого маневрового
            NewTag := TRTETag.Create('S' + Name + '_L1', Self, VT_BOOL, FALSE);
            _L1 := NewTag;
            NewTag.PLCTagEntry.Phisical := true;
            NewTag.IsOPCTag := true;
            MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
            MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
            //CTL1
            NewTag := TRTETag.Create('S' + Name + '_CTL1', Self, VT_BOOL, FALSE);
            _CTL1 := NewTag;
            NewTag.PLCTagEntry.Phisical := true;
            NewTag.IsOPCTag := true;
            MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
            MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
        end;//if RWSignal.BeManevr
        if (RWSignal.Green = 0) then
        begin
            //L2 - Контроль Зеленого
            NewTag := TRTETag.Create('S' + Name + '_L2', Self, VT_BOOL, FALSE);
            _L2 := NewTag;
            NewTag.PLCTagEntry.Phisical := true;
            NewTag.IsOPCTag := true;
            MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
            MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
            //CTL4 - зеленый
            NewTag := TRTETag.Create('S' + Name + '_CTL4', Self, VT_BOOL, FALSE);
            _CTL4 := NewTag;
            NewTag.PLCTagEntry.Phisical := true;
            NewTag.IsOPCTag := true;
            MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
            MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
        end;//if (RWSignal.Green = 0)
        if RWSignal.YellowTop = 0 then
        begin
            //L3 - Контроль Желтого верхнего
            NewTag := TRTETag.Create('S' + Name + '_L3', Self, VT_BOOL, FALSE);
            _L3 := NewTag;
            NewTag.PLCTagEntry.Phisical := true;
            NewTag.IsOPCTag := true;
            MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
            MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
            //CTL3 - Желтый верхний
            NewTag := TRTETag.Create('S' + Name + '_CTL3', Self, VT_BOOL, FALSE);
            _CTL3 := NewTag;
            NewTag.PLCTagEntry.Phisical := true;
            NewTag.IsOPCTag := true;
            MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
            MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
        end;//if RWSignal.YellowTop = 0 then
        if RWSignal.YellowBottom = 0 then
        begin
            //L4 - Контроль Желтого нижнего
            NewTag := TRTETag.Create('S' + Name + '_L4', Self, VT_BOOL, FALSE);
            _L4 := NewTag;
            NewTag.PLCTagEntry.Phisical := true;
            NewTag.IsOPCTag := true;
            MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
            MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
            //CTL2 - желтый нижний
            NewTag := TRTETag.Create('S' + Name + '_CTL2', Self, VT_BOOL, FALSE);
            _CTL2 := NewTag;
            NewTag.PLCTagEntry.Phisical := true;
            NewTag.IsOPCTag := true;
            MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
            MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
        end;//if RWSignal.YellowBottom
    end;//2
    3: //выходной
    begin
        //Блокировка разрешаещего сигнала
        NewTag := TRTETag.Create('S' + Name + '_BLOCK', Self, VT_BOOL, FALSE);
        _BLOCK := NewTag;
        NewTag.PLCTagEntry.Phisical := true;
        NewTag.IsOPCTag := true;
        MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
        MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
        //L0 - контроль красного
        NewTag := TRTETag.Create('S' + Name + '_L0', Self, VT_BOOL, FALSE);
        _L0 := NewTag;
        NewTag.PLCTagEntry.Phisical := true;
        NewTag.IsOPCTag := true;
        MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
        MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
        //CTL0
        NewTag := TRTETag.Create('S' + Name + '_CTL0', Self, VT_BOOL, FALSE);
        _CTL0 := NewTag;
        NewTag.PLCTagEntry.Phisical := true;
        NewTag.IsOPCTag := true;
        MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
        MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
        if SignalSubType = 0 then
        begin
            //L1 - Контроль Белого маневрового
            NewTag := TRTETag.Create('S' + Name + '_L1', Self, VT_BOOL, FALSE);
            _L1 := NewTag;
            NewTag.PLCTagEntry.Phisical := true;
            NewTag.IsOPCTag := true;
            MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
            MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
            //CTL1
            NewTag := TRTETag.Create('S' + Name + '_CTL1', Self, VT_BOOL, FALSE);
            _CTL1 := NewTag;
            NewTag.PLCTagEntry.Phisical := true;
            NewTag.IsOPCTag := true;
            MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
            MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
        end;
        if (RWSignal.Green = 0) then
        begin
            //L2 - Контроль Зеленого
            NewTag := TRTETag.Create('S' + Name + '_L2', Self, VT_BOOL, FALSE);
            _L2 := NewTag;
            NewTag.PLCTagEntry.Phisical := true;
            NewTag.IsOPCTag := true;
            MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
            MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
            //CTL4 - зеленый
            NewTag := TRTETag.Create('S' + Name + '_CTL4', Self, VT_BOOL, FALSE);
            _CTL4 := NewTag;
            NewTag.PLCTagEntry.Phisical := true;
            NewTag.IsOPCTag := true;
            MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
            MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
        end;
        if RWSignal.YellowTop = 0 then
        begin
            //L3 - Контроль Желтого верхнего
            NewTag := TRTETag.Create('S' + Name + '_L3', Self, VT_BOOL, FALSE);
            _L3 := NewTag;
            NewTag.PLCTagEntry.Phisical := true;
            NewTag.IsOPCTag := true;
            MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
            MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
            //CTL3 - Желтый верхний
            NewTag := TRTETag.Create('S' + Name + '_CTL3', Self, VT_BOOL, FALSE);
            _CTL3 := NewTag;
            NewTag.PLCTagEntry.Phisical := true;
            NewTag.IsOPCTag := true;
            MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
            MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
        end;
        if RWSignal.YellowBottom = 0 then
        begin
            //L4 - Контроль Желтого нижнего
            NewTag := TRTETag.Create('S' + Name + '_L4', Self, VT_BOOL, FALSE);
            _L4 := NewTag;
            NewTag.PLCTagEntry.Phisical := true;
            NewTag.IsOPCTag := true;
            MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
            MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
            //CTL2 - желтый нижний
            NewTag := TRTETag.Create('S' + Name + '_CTL2', Self, VT_BOOL, FALSE);
            _CTL2 := NewTag;
            NewTag.PLCTagEntry.Phisical := true;
            NewTag.IsOPCTag := true;
            MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
            MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
        end;
    end;//3
    6: //маршрутный
    begin
        //Блокировка разрешаещего сигнала
        NewTag := TRTETag.Create('S' + Name + '_BLOCK', Self, VT_BOOL, FALSE);
        _BLOCK := NewTag;
        NewTag.PLCTagEntry.Phisical := true;
        NewTag.IsOPCTag := true;
        MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
        MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
        //L0 - контроль красного
        NewTag := TRTETag.Create('S' + Name + '_L0', Self, VT_BOOL, FALSE);
        _L0 := NewTag;
        NewTag.PLCTagEntry.Phisical := true;
        NewTag.IsOPCTag := true;
        MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
        MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
        //CTL0
        NewTag := TRTETag.Create('S' + Name + '_CTL0', Self, VT_BOOL, FALSE);
        _CTL0 := NewTag;
        NewTag.PLCTagEntry.Phisical := true;
        NewTag.IsOPCTag := true;
        MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
        MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
        case (SignalSubType) of
           0,1:
            begin
                //L1 - Контроль Белого маневрового
                NewTag := TRTETag.Create('S' + Name + '_L1', Self, VT_BOOL, FALSE);
                _L1 := NewTag;
                NewTag.PLCTagEntry.Phisical := true;
                NewTag.IsOPCTag := true;
                MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
                MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
                //CTL1
                NewTag := TRTETag.Create('S' + Name + '_CTL1', Self, VT_BOOL, FALSE);
                _CTL1 := NewTag;
                NewTag.PLCTagEntry.Phisical := true;
                NewTag.IsOPCTag := true;
                MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
                MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
            end;//0,1
        end;//case
        if (RWSignal.Green = 0) then
        begin
            //L2 - Контроль Зеленого
            NewTag := TRTETag.Create('S' + Name + '_L2', Self, VT_BOOL, FALSE);
            _L2 := NewTag;
            NewTag.PLCTagEntry.Phisical := true;
            NewTag.IsOPCTag := true;
            MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
            MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
            //CTL4 - зеленый
            NewTag := TRTETag.Create('S' + Name + '_CTL4', Self, VT_BOOL, FALSE);
            _CTL4 := NewTag;
            NewTag.PLCTagEntry.Phisical := true;
            NewTag.IsOPCTag := true;
            MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
            MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
        end;
        if RWSignal.YellowTop = 0 then
        begin
            //L3 - Контроль Желтого верхнего
            NewTag := TRTETag.Create('S' + Name + '_L3', Self, VT_BOOL, FALSE);
            _L3 := NewTag;
            NewTag.PLCTagEntry.Phisical := true;
            NewTag.IsOPCTag := true;
            MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
            MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
            //CTL3 - Желтый верхний
            NewTag := TRTETag.Create('S' + Name + '_CTL3', Self, VT_BOOL, FALSE);
            _CTL3 := NewTag;
            NewTag.PLCTagEntry.Phisical := true;
            NewTag.IsOPCTag := true;
            MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
            MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
        end;
        if RWSignal.YellowBottom = 0 then
        begin
            //L4 - Контроль Желтого нижнего
            NewTag := TRTETag.Create('S' + Name + '_L4', Self, VT_BOOL, FALSE);
            _L4 := NewTag;
            NewTag.PLCTagEntry.Phisical := true;
            NewTag.IsOPCTag := true;
            MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
            MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
            //CTL2 - желтый нижний
            NewTag := TRTETag.Create('S' + Name + '_CTL2', Self, VT_BOOL, FALSE);
            _CTL2 := NewTag;
            NewTag.PLCTagEntry.Phisical := true;
            NewTag.IsOPCTag := true;
            MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
            MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
        end;
    end;//6
    7: //проходной
    begin
      if not UnVisible then
      begin
        case SignalSubType of
          0:
          begin
              //_OUT1
              NewTag := TRTETag.Create('S' + Name + '_OUT1', Self, VT_BOOL, FALSE);
              _OUT1 := NewTag;
              NewTag.PLCTagEntry.Phisical := true;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
              //_OUT2
              NewTag := TRTETag.Create('S' + Name + '_OUT2', Self, VT_BOOL, FALSE);
              _OUT2 := NewTag;
              NewTag.PLCTagEntry.Phisical := true;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
              //_OUT3
              NewTag := TRTETag.Create('S' + Name + '_OUT3', Self, VT_BOOL, FALSE);
              _OUT3 := NewTag;
              NewTag.PLCTagEntry.Phisical := true;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
              if MPRCore.MPR.SignalBlock = '1' then
              begin
                  //_BLOCK
                  NewTag := TRTETag.Create('S' + Name + '_BLOCK', Self, VT_BOOL, FALSE);
                  _BLOCK := NewTag;
                  NewTag.PLCTagEntry.Phisical := true;
                  NewTag.IsOPCTag := true;
                  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
                  MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
              end;
              //_L0
              NewTag := TRTETag.Create('S' + Name + '_L0', Self, VT_BOOL, FALSE);
              _L0 := NewTag;
              NewTag.PLCTagEntry.Phisical := true;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
              //_L1
              NewTag := TRTETag.Create('S' + Name + '_L1', Self, VT_BOOL, FALSE);
              _L1 := NewTag;
              NewTag.PLCTagEntry.Phisical := true;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
              //_L2
              NewTag := TRTETag.Create('S' + Name + '_L2', Self, VT_BOOL, FALSE);
              _L2 := NewTag;
              NewTag.PLCTagEntry.Phisical := true;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
          end; //0
          2:
          begin
            //_L0
            NewTag := TRTETag.Create('S' + Name + '_L0', Self, VT_BOOL, FALSE);
            _L0 := NewTag;
            NewTag.PLCTagEntry.Phisical := true;
            NewTag.IsOPCTag := true;
            MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
            MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
            //_L1
            NewTag := TRTETag.Create('S' + Name + '_L1', Self, VT_BOOL, FALSE);
            _L1 := NewTag;
            NewTag.PLCTagEntry.Phisical := true;
            NewTag.IsOPCTag := true;
            MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
            MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
            //_L2
            NewTag := TRTETag.Create('S' + Name + '_L2', Self, VT_BOOL, FALSE);
            _L2 := NewTag;
            NewTag.PLCTagEntry.Phisical := true;
            NewTag.IsOPCTag := true;
            MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
            MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
            if Assigned(Connection) then
              Connection.OnFieldBus := TRUE;
          end;//2
        end;//case
      end;//if
    end;//7
    5: //попутный
    begin
        case SignalSubType of
          0:
          begin
              //состояние по сети
              if (not RWSignal.PSCaption.Trim().Equals(string.Empty)) AND (not RWSignal.PSCaption.Trim().Equals('0')) then
              begin
                  NewTag := TRTETag.Create('S' + RWSignal.PSCaption.Trim(), Self, VT_I2, 0);
                  NETSrc := NewTag;
                  if not Assigned(RTEStandSection) then
                  begin
                      NewTag.PLCTagEntry.Memory := true;
                  end
                  else
                  begin
                      if RTEStandSection.RWSection.Shared = '0' then
                      begin
                          NewTag.PLCTagEntry.Memory := true;
                      end
                      else
                      begin
                          NewTag.PLCTagEntry.IOReadOnly := true;
                          NewTag.PLCTagEntry.ServerAlias := 'Station' + RTEStandSection.RWSection.Shared;
                      end;
                  end;
                  NewTag.IsOPCTag := true;
                  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
                  if MPRCore.MSURTESettings.IsEmulation  then
                    MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
              end;
          end;//0
          1:
          begin
              //состояние по физ. сигналу
              //_L1
              NewTag := TRTETag.Create('S' + Name + '_L1', Self, VT_BOOL, FALSE);
              _L1 := NewTag;
              NewTag.PLCTagEntry.Phisical := true;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
          end; //1
          2:
          begin
            case RWSignal.PoputType of
              1,4://клон маневрового
              begin
                //_L1
                NewTag := TRTETag.Create('S' + Name + '_L1', Self, VT_BOOL, FALSE);
                _L1 := NewTag;
                NewTag.PLCTagEntry.Phisical := true;
                NewTag.IsOPCTag := true;
                MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
                MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
                //_L2
                NewTag := TRTETag.Create('S' + Name + '_L2', Self, VT_BOOL, FALSE);
                _L0 := NewTag;
                NewTag.PLCTagEntry.Phisical := true;
                NewTag.IsOPCTag := true;
                MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
                MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
              end//1,4
              else
              begin
                //клон поездного
                //_L0
                NewTag := TRTETag.Create('S' + Name + '_L0', Self, VT_BOOL, FALSE);
                _L0 := NewTag;
                NewTag.PLCTagEntry.Phisical := true;
                NewTag.IsOPCTag := true;
                MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
                MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
                If RWSignal.BeManevr then
                begin
                  //_L1
                  NewTag := TRTETag.Create('S' + Name + '_L1', Self, VT_BOOL, FALSE);
                  _L1 := NewTag;
                  NewTag.PLCTagEntry.Phisical := true;
                  NewTag.IsOPCTag := true;
                  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
                  MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
                end;
                If RWSignal.Green = 0 then
                begin
                  //_L2
                  NewTag := TRTETag.Create('S' + Name + '_L2', Self, VT_BOOL, FALSE);
                  _L2 := NewTag;
                  NewTag.PLCTagEntry.Phisical := true;
                  NewTag.IsOPCTag := true;
                  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
                  MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
                end;
                If RWSignal.YellowTop = 0 then
                begin
                  //_L3
                  NewTag := TRTETag.Create('S' + Name + '_L3', Self, VT_BOOL, FALSE);
                  _L3 := NewTag;
                  NewTag.PLCTagEntry.Phisical := true;
                  NewTag.IsOPCTag := true;
                  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
                  MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
                end;
                If RWSignal.YellowBottom = 0 then
                begin
                  //_L4
                  NewTag := TRTETag.Create('S' + Name + '_L4', Self, VT_BOOL, FALSE);
                  _L4 := NewTag;
                  NewTag.PLCTagEntry.Phisical := true;
                  NewTag.IsOPCTag := true;
                  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
                  MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
                end;
              end;//else
            end;//case RWSignal.PoputType
            if Assigned(Connection) then
              Connection.OnFieldBus := TRUE;
          end;//2
        end;//case SignalSubType
    end;//5
  end;//case (SignalType)
  //Тэги - ссылки на светофоры соседней станции
  case (SignalType) of
    7: //проходной
    begin
        if SignalSubType = 1 then
        begin
            //без управления
            if Assigned(RTEStandSection) then
            begin
                if RTEStandSection.RWSection.Shared <> '0' then
                begin
                    if (not RWSignal.PSCaption.Trim().Equals(string.Empty)) AND (not RWSignal.PSCaption.Trim().Equals('0')) then
                    begin
                        NewTag := TRTETag.Create('S' + RWSignal.PSCaption.Trim(), Self, VT_I2, 0);
                        NETSrc := NewTag;
                        NewTag.PLCTagEntry.IOReadOnly := true;
                        NewTag.PLCTagEntry.ServerAlias := 'Station' + RTEStandSection.RWSection.Shared;
                        NewTag.IsOPCTag := true;
                        MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
                        if MPRCore.MSURTESettings.IsEmulation  then
                          MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
                    end;
                end;//if RTEStandSection.RWSection.Shared <> '0' then
            end;// if Assigned(RTEStandSection) then
        end;//if SignalSubType = 1 then
    end;//7
  end;//switch (SignalType)
end;

Destructor TRTESignal.Destroy;
begin
  if Assigned(ShST2Crossings) then
  begin
    ShST2Crossings.Free;
    ShST2Crossings := nil;
  end;
  inherited;
end;

function TRTESignal.PostProcessing;
var
  divList : TStringList;
  i,CrIdx : Integer;
begin
  Result := true;
  if MPRCore.RTECrossings.Count = 0 then Exit;
  Result := false;
  divList := TStringList.Create;
  try
    divList.Delimiter := '@';
    divList.DelimitedText := RWSignal.Man2_Z_CrossCodeList;
    if divList.Count > 0 then
    begin
      for i := 0 to divList.Count - 1 do
      begin
        CrIdx := MPRCore.RTECrossings.IndexOf(divList[i]);
        if CrIdx > -1 then
        begin
          ShST2Crossings.AddObject(TRTECrossing(MPRCore.RTECrossings.Objects[CrIdx]).Name,TRTECrossing(MPRCore.RTECrossings.Objects[CrIdx]));
        end;
      end;
    end
  finally
    if Assigned(divList) then
    divList.Free;
  end;
  Result := true;
end;

function TMSURTECore.CreateSignals;
var
  OneRTESignal : TRTESignal;
  i : Integer;
begin
  Result := false;
  RTESignals.Clear;
  if not Assigned(MPR) then Exit;
  if not MPRLoaded then Exit;
  if Length(MPR.RWSignals) <= 0 then Exit;
  OneRTESignal := nil;
  for i := 0 to High(MPR.RWSignals) do
  begin
    try
      OneRTESignal := TRTESignal.Create(Self,MPR.RWSignals[i]);
      RTESignals.AddObject(OneRTESignal.Name, OneRTESignal);
    except
      AppLogger.AddErrorMessage('Светофор '+ MPR.RWSignals[i].Caption +': сбой при создании объекта.');
      Exit;
    end;
  end;
  Result := true;
end;

Constructor TRTECrossPP.Create;
var
  NewTag : TRTETag;
  SctIdx : Integer;
begin
  inherited Create(AMPRCore);
  _L1 := nil;
  _OUT := nil;
  _RLZ := nil;
  RWCrossPP := ACrossPP;
  Name := ACrossPP.Code;
  FCaption := ACrossPP.Caption;
  OrdinalNumb := RWCrossPP.CrossLineNumber;
  OwnSection := nil;
  if MPRCore.RTESections.Count > 0 then
  begin
    SctIdx := MPRCore.RTESections.IndexOf(RWCrossPP.SectionOwner);
    if SctIdx > -1 then
    begin
      OwnSection := TRTESEction(MPRCore.RTESections.Objects[SctIdx]);
      if OwnSection.CrossPP.IndexOf (IntToStr(OrdinalNumb)) = -1 then
        OwnSection.CrossPP.AddObject(IntToStr(OrdinalNumb),Self);
    end;//if SctIdx > -1 then
  end;//MPRCore.RTESections.Count
  //тэги
  //_L1
  NewTag := TRTETag.Create('CR' + Name + '_L1', Self, VT_BOOL, FALSE);
  _L1 := NewTag;
  NewTag.PLCTagEntry.Phisical := true;
  NewTag.TagServerTagEntry.IOReadOnly := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
  NewTag := TRTETag.Create('CR' + Name + '_OUT', Self, VT_BOOL, FALSE);
  _OUT := NewTag;
  NewTag.PLCTagEntry.Phisical := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
  if MPRCore.MPR.LZEnabled then
  begin
      NewTag := TRTETag.Create('CR' + Name + '_RLZ', Self, VT_BOOL, FALSE);
      _RLZ := NewTag;
      NewTag.PLCTagEntry.Memory := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  end;
end;

function TRTECrossPP.PostProcessing;
begin
  Result := true;
end;

function TMSURTECore.CreateCrossPPs;
var
  OneRTECrossPP : TRTECrossPP;
  i : Integer;
begin
  Result := false;
  RTECrossPPs.Clear;
  if not Assigned(MPR) then Exit;
  if not MPRLoaded then Exit;
  if Length(MPR.RWCrossPPs) <= 0 then
  begin
    Result := true;
    Exit;
  end;
  OneRTECrossPP := nil;
  for i := 0 to High(MPR.RWCrossPPs) do
  begin
    try
      OneRTECrossPP := TRTECrossPP.Create(Self,MPR.RWCrossPPs[i]);
      RTECrossPPs.AddObject(OneRTECrossPP.Name, OneRTECrossPP);
    except
      AppLogger.AddErrorMessage('Участок приближения '+ MPR.RWCrossPPs[i].Caption +': сбой при создании объекта.');
      Exit;
    end;
  end;
  Result := true;
end;

function TRTEConnect.PostProcessing;
begin
  Result := true;
end;

Constructor TRTECrossing.Create;
var
  NewTag : TRTETag;
  i, SgnIdx : Integer;
  ThisRTESection : TRTESection;
begin
  inherited Create(AMPRCore);
  A_G := nil;
  _OUT := nil;
  _EVEN_OUT := nil;
  _ODD_OUT := nil;
  _FAULT := nil;
  _FAULT_L1 := nil;
  _IN := nil;
  _IN_L1 := nil;
  _FENCE := nil;
  _FENCE_L1 := nil;
  _PROPERLY := nil;
  _PROPERLY_L1 := nil;
  _FUSEDLAMPS := nil;
  _FUSEDLAMPS_L1 := nil;
  _SIGNAL := nil;
  _SIGNAL_L1 := nil;
  _CLOSE := nil;
  _CLOSE_L1 := nil;
  _OPEN := nil;
  _OPEN_L1 := nil;
  _TR3 := nil;
  MainTag := nil;
  _DeviceState := nil;
  RWCrossing := ACrossing;
  Name := ACrossing.Code;
  FCaption := ACrossing.Caption;
  FCrossingType := RWCrossing.CrossingType;
  FCrossingSubType := RWCrossing.CrossingSubType;
  CrossSignals := TStringList.Create(false);
  try
    OutSignalsNumber := StrToInt(RWCrossing.CloseSignal);
  except
    OutSignalsNumber := 0;
  end;
  //Тэги
  NewTag := TRTETag.Create('TriggerG' + Name, Self, VT_BOOL, FALSE);
  NewTag.TagServerTagEntry.Memory := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  NewTag := TRTETag.Create('A_G' + Name, Self, VT_BOOL, FALSE);
  A_G := NewTag;
  NewTag.TagServerTagEntry.Memory := true;
  NewTag.PLCTagEntry.IOReadOnly := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  Case (CrossingType)  of
      4, 3, 2, 6:
      begin
          NewTag := TRTETag.Create('G' + Name + '_OUT', Self, VT_BOOL, FALSE);
          _OUT := NewTag;
          if OutSignalsNumber = 0 then
          begin
              NewTag.PLCTagEntry.Phisical := true;
              MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
          end
          else
          begin
              NewTag.PLCTagEntry.Memory := true;
          end;
          NewTag.TagServerTagEntry.IOReadOnly := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          case (OutSignalsNumber) of
              1:
              begin
                  NewTag := TRTETag.Create('G' + Name + '_EVEN_OUT', Self, VT_BOOL, FALSE);
                  _EVEN_OUT := NewTag;
                  NewTag.PLCTagEntry.Phisical := true;
                  NewTag.IsOPCTag := true;
                  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
                  MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
                  NewTag := TRTETag.Create('G' + Name + '_ODD_OUT', Self, VT_BOOL, FALSE);
                  _ODD_OUT := NewTag;
                  NewTag.PLCTagEntry.Phisical := true;
                  NewTag.IsOPCTag := true;
                  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
                  MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
              end;//1
              2:
              begin
                  if Length(RWCrossing.Sections) > 0 then
                  begin
                      for i := 0 to High(RWCrossing.Sections) do
                      begin
                          //перенесено в перееездные линии
                          {NewTag := TRTETag.Create('G' + Name + '_'+ RWCrossing.Sections[i] + '_EVEN_OUT', Self, VT_BOOL, FALSE);
                          NewTag.PLCTagEntry.Phisical := true;
                          NewTag.IsOPCTag := true;
                          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
                          NewTag := TRTETag.Create('G' + Name + '_' + RWCrossing.Sections[i] + '_ODD_OUT', Self, VT_BOOL, FALSE);
                          NewTag.PLCTagEntry.Phisical := true;
                          NewTag.IsOPCTag := true;
                          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);  }
                          if CrossingType = 3 then
                          begin
                            if MPRCore.RTESections.Count > 0 then
                            begin
                              SgnIdx := MPRCore.RTESections.IndexOf(RWCrossing.Sections[i]);
                              if SgnIdx > -1 then
                              begin
                                ThisRTESection := TRTESection(MPRCore.RTESections.Objects[SgnIdx]);
                                ThisRTESection.CrossType3 := true;
                              end;
                            end;
                          end;//if CrossingType = 3 then
                      end;
                  end;
              end;//2
          end;//case (OutSignalsNumber) of
          NewTag := TRTETag.Create('G' + Name + '_FAULT', Self, VT_BOOL, FALSE);
          _FAULT := NewTag;
          NewTag.PLCTagEntry.Memory := true;
          NewTag.TagServerTagEntry.IOReadOnly := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          NewTag := TRTETag.Create('G' + Name + '_FAULT_L1', Self, VT_BOOL, FALSE);
          _FAULT_L1 := NewTag;
          NewTag.PLCTagEntry.Phisical := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
          if CrossingType <> 6 then
          begin
              NewTag := TRTETag.Create('G' + Name + '_IN', Self, VT_BOOL, FALSE);
              _IN := NewTag;
              NewTag.PLCTagEntry.Memory := true;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              NewTag := TRTETag.Create('G' + Name + '_IN_L1', Self, VT_BOOL, FALSE);
              _IN_L1 := NewTag;
              NewTag.PLCTagEntry.Phisical := true;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
          end;
          if (RWCrossing.FenceIs = '1') OR (CrossingType = 6) then
          begin
              NewTag := TRTETag.Create('G' + Name + '_FENCE', Self, VT_BOOL, FALSE);
              _FENCE := NewTag;
              NewTag.PLCTagEntry.Memory := true;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              NewTag := TRTETag.Create('G' + Name + '_FENCE_L1', Self, VT_BOOL, FALSE);
              _FENCE_L1 := NewTag;
              NewTag.PLCTagEntry.Phisical := true;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
          end;
          if Length(RWCrossing.SignalIndexes) > 0 then
          begin
              for i := 0 to High(RWCrossing.SignalIndexes) do
              begin
                  SgnIdx := RWCrossing.SignalIndexes[i];
                  if SgnIdx <> -1 then
                  begin
                    NewTag := TRTETag.Create('G' + Name + '_' + MPRCore.MPR.RWSignals[sgnIdx].RootName + '_OUT', Self, VT_BOOL, FALSE);
                    NewTag.PLCTagEntry.Memory := true;
                    NewTag.TagServerTagEntry.IOReadOnly := true;
                    NewTag.IsOPCTag := true;
                    MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
                    CrossSignals.AddObject(NewTag.Name, NewTag);
                  end;
              end;
          end;
      end;//4, 3, 2, 6
      1:
      begin
          NewTag := TRTETag.Create('G' + Name + '_IN', Self, VT_BOOL, FALSE);
          _IN := NewTag;
          NewTag.PLCTagEntry.Memory := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          NewTag := TRTETag.Create('G' + Name + '_IN_L1', Self, VT_BOOL, FALSE);
          _IN_L1 := NewTag;
          NewTag.PLCTagEntry.Phisical := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
          NewTag := TRTETag.Create('G' + Name + '_FAULT', Self, VT_BOOL, FALSE);
          _FAULT := NewTag;
          NewTag.PLCTagEntry.Memory := true;
          NewTag.TagServerTagEntry.IOReadOnly := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          NewTag := TRTETag.Create('G' + Name + '_FAULT_L1', Self, VT_BOOL, FALSE);
          _FAULT_L1 := NewTag;
          NewTag.PLCTagEntry.Phisical := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
          if (RWCrossing.FenceIs = '1') then
          begin
              NewTag := TRTETag.Create('G' + Name + '_FENCE', Self, VT_BOOL, FALSE);
              _FENCE := NewTag;
              NewTag.PLCTagEntry.Memory := true;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              NewTag := TRTETag.Create('G' + Name + '_FENCE_L1', Self, VT_BOOL, FALSE);
              _FENCE_L1 := NewTag;
              NewTag.PLCTagEntry.Phisical := true;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
          end;//if (RWCrossing.FenceIs = '1') then
      end;//1
  end;//Case (CrossingType)  of
  if CrossingType = 6 then
  begin
      //_PROPERLY
      NewTag := TRTETag.Create('G' + Name + '_PROPERLY', Self, VT_BOOL, FALSE);
      _PROPERLY := NewTag;
      NewTag.PLCTagEntry.Memory := true;
      NewTag.TagServerTagEntry.IOReadOnly := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
      NewTag := TRTETag.Create('G' + Name + '_PROPERLY_L1', Self, VT_BOOL, FALSE);
      _PROPERLY_L1 := NewTag;
      NewTag.PLCTagEntry.Phisical := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
      MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
      //_FUSEDLAMPS
      NewTag := TRTETag.Create('G' + Name + '_FUSEDLAMPS', Self, VT_BOOL, FALSE);
      _FUSEDLAMPS := NewTag;
      NewTag.PLCTagEntry.Memory := true;
      NewTag.TagServerTagEntry.IOReadOnly := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
      NewTag := TRTETag.Create('G' + Name + '_FUSEDLAMPS_L1', Self, VT_BOOL, FALSE);
      _FUSEDLAMPS_L1 := NewTag;
      NewTag.PLCTagEntry.Phisical := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
      MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
      //_SIGNAL
      NewTag := TRTETag.Create('G' + Name + '_SIGNAL', Self, VT_BOOL, FALSE);
      _SIGNAL := NewTag;
      NewTag.PLCTagEntry.Memory := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
      NewTag := TRTETag.Create('G' + Name + '_SIGNAL_L1', Self, VT_BOOL, FALSE);
      _SIGNAL_L1 := NewTag;
      NewTag.PLCTagEntry.Phisical := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
      MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
      //_CLOSE
      NewTag := TRTETag.Create('G' + Name + '_CLOSE', Self, VT_BOOL, FALSE);
      _CLOSE := NewTag;
      NewTag.PLCTagEntry.Memory := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
      NewTag := TRTETag.Create('G' + Name + '_CLOSE_L1', Self, VT_BOOL, FALSE);
      _CLOSE_L1 := NewTag;
      NewTag.PLCTagEntry.Phisical := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
      MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
      //_OPEN
      NewTag := TRTETag.Create('G' + Name + '_OPEN', Self, VT_BOOL, FALSE);
      _OPEN := NewTag;
      NewTag.PLCTagEntry.Memory := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
      NewTag := TRTETag.Create('G' + Name + '_OPEN_L1', Self, VT_BOOL, FALSE);
      _OPEN_L1 := NewTag;
      NewTag.PLCTagEntry.Phisical := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
      MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
      //TR3
      NewTag := TRTETag.Create('G' + Name + '_TR3', Self, VT_BOOL, FALSE);
      _TR3 := NewTag;
      NewTag.PLCTagEntry.Memory := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  end;
  NewTag := TRTETag.Create('SpendTimeG' + Name, Self, VT_I2, 0);
  NewTag.TagServerTagEntry.Memory := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  NewTag := TRTETag.Create('MyTimeNowG' + Name, Self, VT_I2, 0);
  NewTag.TagServerTagEntry.Memory := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  NewTag := TRTETag.Create('G' + Name, Self, VT_I2, 0);
  MainTag := NewTag;
  NewTag.PLCTagEntry.Memory := true;
  NewTag.TagServerTagEntry.IOReadOnly := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  NewTag := TRTETag.Create('G' + Name + '_DeviceState', Self, VT_I2, 0);
  _DeviceState := NewTag;
  NewTag.PLCTagEntry.Memory := true;
  NewTag.TagServerTagEntry.IOReadOnly := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  NewTag := TRTETag.Create('G' + Name + '_InputDELAY', Self, VT_I2, 4);
  NewTag.PLCTagEntry.Memory := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  if (RWCrossing.CloseDelay > 0) then
  begin
      NewTag := TRTETag.Create('G' + Name + '_DeadbandTime', Self, VT_I2, RWCrossing.CloseDelay);
      NewTag.PLCTagEntry.Memory := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  end;
end;

Destructor TRTECrossing.Destroy;
begin
  if Assigned(CrossSignals) then
  begin
    CrossSignals.Free;
    CrossSignals := nil;
  end;
  inherited;
end;

function TRTECrossing.PostProcessing;
begin
  Result := true;
end;

Destructor  TRTESection.Destroy;
begin
  if Assigned(ContainedPoints) then
  begin
    ContainedPoints.Free;
    ContainedPoints := nil;
  end;
  if Assigned(CrossPP) then
  begin
    CrossPP.Free;
    CrossPP := nil;
  end;
  inherited;
end;

function TMSURTECore.isQ1SVHSignalExists;
var
  i : Integer;
  ThisSignal : TRTESignal;
begin
  Result := nil;
  if RTESignals.Count > 0 then
  begin
    for i := 0 to RTESignals.Count - 1 do
    begin
        ThisSignal := TRTESignal(RTESignals.Objects[i]);
        if ThisSignal.SignalType = 2 then
        begin
            if ThisSignal.RTEStandSection.Name.Equals(ARTESectionName) then
            begin
                if (ThisSignal.Q1SVH_OUTSignalExists) then
                begin
                    Result := ThisSignal;
                    Exit;
                end;
                Result := nil;
                Exit;
            end;
        end; //if ThisSignal.SignalType = 2 then
    end;//for i
  end;
end;

function TMSURTECore.CreateCrossings;
var
  OneRTECrossing : TRTECrossing;
  i : Integer;
begin
  Result := false;
  RTECrossings.Clear;
  if not Assigned(MPR) then Exit;
  if not MPRLoaded then Exit;
  if Length(MPR.RWCrossings) <= 0 then
  begin
    Result := true;
    Exit;
  end;
  OneRTECrossing := nil;
  for i := 0 to High(MPR.RWCrossings) do
  begin
    try
      OneRTECrossing := TRTECrossing.Create(Self,MPR.RWCrossings[i]);
      RTECrossings.AddObject(OneRTECrossing.Name, OneRTECrossing);
    except
      AppLogger.AddErrorMessage('Переезд '+ MPR.RWCrossings[i].Caption +': сбой при создании объекта.');
      Exit;
    end;
    end;
  Result := true;
end;

function TMSURTECore.CreateCrossLines;
var
  OneRTECrossLine : TRTECrossLine;
  i : Integer;
begin
  Result := false;
  RTECrossLines.Clear;
  if not Assigned(MPR) then Exit;
  if not MPRLoaded then Exit;
  if Length(MPR.RWCrossLines)<= 0 then
  begin
    Result := true;
    Exit;
  end;
  OneRTECrossLine := nil;
  for i := 0 to High(MPR.RWCrossLines) do
  begin
    try
      OneRTECrossLine := TRTECrossLine.Create(Self,MPR.RWCrossLines[i]);
      RTECrossLines.AddObject(OneRTECrossLine.Name,OneRTECrossLine);
    except
      AppLogger.AddErrorMessage('Переездная линия '+ MPR.RWCrossLines[i].Caption +': сбой при создании объекта.');
      Exit;
    end;
  end; //for i
  Result := true;
end;

Constructor TRTEMLSignal.Create;
var
   NewTag : TRTETag;
begin
  inherited Create(AMPRCore);
  _COMM := nil;
  MainTag := nil;
  _BLOCK := nil;
  _L1 := nil;
  _OUT := nil;
  RWML := ARWML;
  Name := RWML.Code;
  FCaption := RWML.Caption;
  //Тэги
  NewTag := TRTETag.Create('S' + Name + '_COMM', Self, VT_BOOL, FALSE);
  _COMM := NewTag;
  NewTag.PLCTagEntry.Memory := true;
  NewTag.TagServerTagEntry.IOReadwrite := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  NewTag := TRTETag.Create('S' + Name, Self, VT_I2, 0);
  MainTag := NewTag;
  NewTag.PLCTagEntry.Memory := true;
  NewTag.TagServerTagEntry.IOReadwrite := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  //входные/выходные тэги
  //блокировка
  case RWML.SignalLockType of
    0:
    begin
        //определяется общими ключами
        if (MPRCore.MPR.ShuntBlock = '1') then
        begin
            NewTag := TRTETag.Create('S' + Name + '_BLOCK', Self, VT_BOOL, FALSE);
            _BLOCK := NewTag;
            NewTag.PLCTagEntry.Phisical := true;
            NewTag.IsOPCTag := true;
            MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
            MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
        end;
    end;//0
    1:
    begin
        NewTag := TRTETag.Create('S' + Name + '_BLOCK', Self, VT_BOOL, FALSE);
        _BLOCK := NewTag;
        NewTag.PLCTagEntry.Phisical := true;
        NewTag.IsOPCTag := true;
        MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
        MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
    end;//1
    end;//case
    //L1
    NewTag := TRTETag.Create('S' + Name + '_L1', Self, VT_BOOL, FALSE);
    _L1 := NewTag;
    NewTag.PLCTagEntry.Phisical := true;
    NewTag.IsOPCTag := true;
    MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
    MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
    //OUT
    NewTag := TRTETag.Create('S' + Name + '_OUT', Self, VT_BOOL, FALSE);
    _OUT := NewTag;
    NewTag.PLCTagEntry.Phisical := true;
    NewTag.IsOPCTag := true;
    MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
    MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
end;

function TRTEMLSignal.PostProcessing;
begin
  Result := true;
end;

function TMSURTECore.CreateMLs;
var
  OneRTEML : TRTEMLSignal;
  i : Integer;
begin
  Result := false;
  RTEMLs.Clear;
  if not Assigned(MPR) then Exit;
  if not MPRLoaded then Exit;
  if Length(MPR.RWML) <= 0 then
  begin
    Result := true;
    Exit;
  end;
  OneRTEML := nil;
  for i := 0 to High(MPR.RWML) do
  begin
    try
      OneRTEML := TRTEMLSignal.Create(Self,MPR.RWML[i]);
      RTEMLs.AddObject(OneRTEML.Name, OneRTEML);
    except
      AppLogger.AddErrorMessage('Лунно-белый пригласительный стгнал '+ MPR.RWML[i].Caption +': сбой при создании объекта.');
      Exit;
    end;
  end;
  Result := true;
end;

Constructor TRTEPAB.Create(AMPRCore: TMSURTECore; ARWSA: TRWSA);
var
   NewTag : TRTETag;
begin
  inherited Create(AMPRCore);
  RWSA := ARWSA;
  Name := RWSA.Code;
  FCaption := RWSA.Caption;
  RouteList := TStringList.Create (false);
  FVariant := RWSA.SAType;
  //тэги
  _DS := nil;
  _OS := nil;
  _DP := nil;
  _IR := nil;
  _PO_L1 := nil;
  _PS_L1 := nil;
  _DS_L1 := nil;
  _OPER := nil;
  _PP := nil;
  _PP_L1 := nil;
  _PP_L2 := nil;
  _OKSR_OUT := nil;
  _DP_OUT := nil;
  _DS_OUT := nil;
  _IR_OUT := nil;
  _OS_OUT := nil;
  //кнопка ДС
  NewTag := TRTETag.Create('SA' + Name + '_DS', Self, VT_BOOL, FALSE);
  _DS := NewTag;
  NewTag.PLCTagEntry.IOReadOnly := true;
  NewTag.TagServerTagEntry.Memory := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  //кнопка ОС
  NewTag := TRTETag.Create('SA' + Name + '_OS', Self, VT_BOOL, TRUE);
  _OS := NewTag;
  NewTag.PLCTagEntry.IOReadOnly := true;
  NewTag.TagServerTagEntry.Memory := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  //кнопка ДП
  NewTag := TRTETag.Create('SA' + Name + '_DP', Self, VT_BOOL, FALSE);
  _DP := NewTag;
  NewTag.PLCTagEntry.IOReadOnly := true;
  NewTag.TagServerTagEntry.Memory := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  //кнопка ИР
  NewTag := TRTETag.Create('SA' + Name + '_IR', Self, VT_BOOL, FALSE);
  _IR := NewTag;
  NewTag.PLCTagEntry.IOReadOnly := true;
  NewTag.TagServerTagEntry.Memory := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  //индикатор ПО
  NewTag := TRTETag.Create('SA' + Name + '_PO_L1', Self, VT_BOOL, FALSE);
  _PO_L1 := NewTag;
  NewTag.PLCTagEntry.Phisical := true;
  NewTag.TagServerTagEntry.IOReadOnly := true;//было read/write
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
  //индикатор ПС
  NewTag := TRTETag.Create('SA' + Name + '_PS_L1', Self, VT_BOOL, FALSE);
  _PS_L1 := NewTag;
  NewTag.PLCTagEntry.Phisical := true;
  NewTag.TagServerTagEntry.IOReadOnly := true;//было read/write
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
  //индикатор ДС
  NewTag := TRTETag.Create('SA' + Name + '_DS_L1', Self, VT_BOOL, FALSE);
  _DS_L1 := NewTag;
  NewTag.PLCTagEntry.Phisical := true;
  NewTag.TagServerTagEntry.IOReadOnly := true;//было read/write
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
  //тэг управления рэле ОКСР
  NewTag := TRTETag.Create('SA' + Name + '_OPER', Self, VT_I2, 0);
  _OPER := NewTag;
  NewTag.PLCTagEntry.IOReadOnly := true;
  NewTag.TagServerTagEntry.Memory := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  //_PP
  NewTag := TRTETag.Create('SA' + Name + '_PP', Self, VT_I2, 0);
  _PP := NewTag;
  NewTag.PLCTagEntry.Memory := true;
  NewTag.TagServerTagEntry.IOReadOnly := true;//было read/write
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  NewTag := TRTETag.Create('SA' + Name + '_PP_L1', Self, VT_BOOL, FALSE);
  _PP_L1 := NewTag;
  NewTag.PLCTagEntry.Phisical := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
  NewTag := TRTETag.Create('SA' + Name + '_PP_L2', Self, VT_BOOL, FALSE);
  _PP_L2 := NewTag;
  NewTag.PLCTagEntry.Phisical := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
  //OKSR
  NewTag := TRTETag.Create('SA' + Name + '_OKSR_OUT', Self, VT_BOOL, FALSE);
  _OKSR_OUT := NewTag;
  NewTag.PLCTagEntry.Phisical := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
  //_DP_OUT
  NewTag := TRTETag.Create('SA' + Name + '_DP_OUT', Self, VT_BOOL, FALSE);
  _DP_OUT := NewTag;
  NewTag.PLCTagEntry.Phisical := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
  //_DS_OUT
  NewTag := TRTETag.Create('SA' + Name + '_DS_OUT', Self, VT_BOOL, FALSE);
  _DS_OUT := NewTag;
  NewTag.PLCTagEntry.Phisical := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
  //_IR_OUT
  NewTag := TRTETag.Create('SA' + Name + '_IR_OUT', Self, VT_BOOL, FALSE);
  _IR_OUT := NewTag;
  NewTag.PLCTagEntry.Phisical := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
  //_OS_OUT
  NewTag := TRTETag.Create('SA' + Name + '_OS_OUT', Self, VT_BOOL, FALSE);
  _OS_OUT := NewTag;
  NewTag.PLCTagEntry.Phisical := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
end;

function TRTEPAB.PostProcessing;
var
  i : Integer;
  RTERoute : TRTERoute;
  RTESection : TRTESection;
begin
  if MPRCore.RTERoutes.Count > 0 then
  begin
    for i := 0 to MPRCore.RTERoutes.Count - 1 do
    begin
      RTERoute := TRTERoute(MPRCore.RTERoutes.Objects[i]);
      if RTERoute.RWRoute.RouteSimple = 1 then
      begin
        if RTERoute.RWRoute.SectionArrivalIndex < MPRCore.RTESections.Count then
        begin
          RTESection := TRTESection(MPRCore.RTESections.Objects[RTERoute.RWRoute.SectionArrivalIndex]);
          if RTESection.RWSection.SACode = Name then
          begin
            RouteList.AddObject(RTERoute.Name,RTERoute);
          end;
        end;
      end;//простой маршрут
    end;//for i
  end;
  Result := true;
end;

Destructor TRTEPAB.Destroy;
begin
  if Assigned(RouteList) then
  begin
    RouteList.Free;
    RouteList := nil;
  end;
  inherited;
end;

function TMSURTECore.CreatePABs;
var
  OneRTEPAB : TRTEPAB;
  i : Integer;
begin
  Result := false;
  if not Assigned(RTEPABs) then Exit;
  RTEPABs.Clear;
  if not Assigned(MPR) then Exit;
  if not MPRLoaded then Exit;
  if Length(MPR.RWSA) <= 0 then
  begin
    Result := true;
    Exit;
  end;
  OneRTEPAB := nil;
  for i := 0 to High(MPR.RWSA) do
  begin
    try
      OneRTEPAB := TRTEPAB.Create(Self,MPR.RWSA[i]);
    except
      AppLogger.AddErrorMessage('ПАБ '+ MPR.RWSA[i].Caption +': сбой при создании объекта.');
      Exit;
    end;
    RTEPABs.AddObject(OneRTEPAB.Name, OneRTEPAB);
  end;
  Result := true;
end;

Constructor TRTEDAB.Create;
var
   NewTag : TRTETag;
   ThisSection : TRTESection;
   i : Integer;
begin
  inherited Create(AMPRCore);
  //
  _SN := nil;
  _SN_NET := nil;
  _OV := nil;
  _OV_NET := nil;
  _PV := nil;
  _PV_NET := nil;
  _1IO_R := nil;
  _1I_R := nil;
  _2SN := nil;
  _1SN := nil;
  _KP_L1 := nil;
  _2IP_L1 := nil;
  _2IP := nil;
  _2I_L1 := nil;
  _2VSN_L1 := nil;
  _2PV_L1 := nil;
  _Command := nil;
  _Result := nil;
  _L1 := nil;
  _L2 := nil;
  _1IO_R_OUT := nil;
  _1I_R_OUT := nil;
  _BU := nil;
  _SN_OUT := nil;
  _PV_OUT := nil;
  _OV_OUT := nil;
  _2PBU := nil;
  _1I_R_L1 := nil;
  _2OV_L1 := nil;
  _1OT_OUT := nil;
  _1_PR_OUT := nil;
  MainTag := nil;
  _SN1 := nil;
  _SN2 := nil;
  _PKP_OUT := nil;
  _KP_OUT := nil;
  _KP_BLOCK := nil;
  _1SN_OUT := nil;
  _1OV_OUT := nil;
  _2PV_OUT := nil;
  _2VSN_OUT := nil;
  _2VSN_BLOCK := nil;
  _1IO_OUT := nil;
  _1IO_BLOCK := nil;
  _1I_OUT := nil;
  _1I_BLOCK := nil;
  _BU_OUT := nil;
  _BU_BLOCK := nil;
  _BU_L1 := nil;
  _1PV_OUT := nil;
  _1PV_BLOCK := nil;
  _1SVH_OUT := nil;
  _1SVH_BLOCK := nil;
  _1PR_OUT := nil;
  _1PR_BLOCK := nil;
  _1OT_BLOCK := nil;
  _2PBU_OUT := nil;
  _2PBU_BLOCK := nil;
  _2PBU_L1 := nil;
  //
  Connection := nil;
  ISidx := -1;
  RWCD := ARWCD;
  Name := RWCD.Code;
  FCaption := RWCD.Caption;
  //инициализация полей
  Direction := 0;
  DABSections := TStringList.Create(false);
  ControlMode := 0;
  ControlType := 0;
  is2PBUExists := true; //Контролируются все блок-участки:0(по умолчанию) - да, 1 - нет
  isBU_L1Exists := true;//Вх. сигнал контроля свободности блок-участков:"0" (по умолчанию) - есть;"1" - нет.
  is2I_L1Exists := true;//Вх. сигнал 2И_L1: "0" (по умолчанию) - есть; 1 - нет.
  is2VSN_L1Exists := true; //Вх. сигнал смены направления с соседней станции: "0" (по умолчанию) - есть; 1 - нет.
  is1OT_OUTExists := true; //Вых. сигналы установленного направления: "0" (по умолчанию) - есть; 1 - нет.
  BindStationCode := '0';
  CodeName := string.Empty;
  BusType := 0;
  //заполнение полей
  CodeName := GetCodeName();
  try
    Direction := StrToInt(RWCD.RD);
  except
    Direction := 0;
  end;
  ControlMode := RWCD.CDType;
  ControlType := RWCD.MasterSlave;
  is2PBUExists := (RWCD.AllBUControl = 0);
  isBU_L1Exists := (RWCD.BU_Control_28 = 0);
  is2I_L1Exists := (RWCD.BU_Control_29 = 0);
  is2VSN_L1Exists := (RWCD.BU_Control_30 = 0);
  is1OT_OUTExists := (RWCD.BU_Control_31 = 0);
  BusType := RWCD.BusType;
  if MPRCore.RTESections.Count > 0 then
  begin
      for i := 0 to MPRCore.RTESections.Count - 1 do
      begin
          ThisSection := TRTESection(MPRCore.RTESections.Objects[i]);
          if ThisSection.RWSection.CDCode.Equals(Name) then
          begin
              DABSections.AddObject(ThisSection.Name,ThisSection);
              if Assigned(ThisSection.Connection) then
                if not Assigned(Connection) then
                  Connection := ThisSection.Connection;
              ThisSection.RWAB := Self;
              if (not ThisSection.RWSection.Shared.Equals('0')) AND (not ThisSection.RWSection.Shared.Equals(string.Empty)) then
              begin
                  BindStationCode := ThisSection.RWSection.Shared;
              end;//if if (not ThisSection.RWSection.Shared.Equals('0'))
          end;//if
      end;//for i
  end;//if
  //тэги
  //кнопка СН
  NewTag := TRTETag.Create('CD' + Name + '_SN', Self, VT_BOOL, FALSE);
  _SN := NewTag;
  NewTag.PLCTagEntry.IOReadOnly := true;
  NewTag.TagServerTagEntry.Memory := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  //кнопка ОВ
  NewTag := TRTETag.Create('CD' + Name + '_OV', Self, VT_BOOL, FALSE);
  _OV := NewTag;
  NewTag.PLCTagEntry.IOReadOnly := true;
  NewTag.TagServerTagEntry.Memory := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  //кнопка ПВ
  NewTag := TRTETag.Create('CD' + Name + '_PV', Self, VT_BOOL, FALSE);
  _PV := NewTag;
  NewTag.PLCTagEntry.IOReadOnly := true;
  NewTag.TagServerTagEntry.Memory := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  case (ControlMode)  of
      0:
      begin
        //_L1
        NewTag := TRTETag.Create('CD' + Name + '_L1', Self, VT_BOOL, FALSE);
        _L1 := NewTag;
        NewTag.PLCTagEntry.Phisical := true;
        NewTag.TagServerTagEntry.IOReadOnly := true;
        NewTag.IsOPCTag := true;
        MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
        MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
        //_L2
        NewTag := TRTETag.Create('CD' + Name + '_L2', Self, VT_BOOL, FALSE);
        _L2 := NewTag;
        NewTag.PLCTagEntry.Phisical := true;
        NewTag.TagServerTagEntry.IOReadOnly := true;
        NewTag.IsOPCTag := true;
        MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
        MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
        //_KP_L1
        NewTag := TRTETag.Create('CD' + Name + '_KP_L1', Self, VT_BOOL, FALSE);
        _KP_L1 := NewTag;
        NewTag.PLCTagEntry.Phisical := true;
        NewTag.TagServerTagEntry.IOReadOnly := true;
        NewTag.IsOPCTag := true;
        MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
        MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
        NewTag := TRTETag.Create('CD' + Name + '_1I_R', Self, VT_BOOL, FALSE);
        _1I_R := NewTag;
        NewTag.PLCTagEntry.IOReadOnly := true;
        NewTag.TagServerTagEntry.Memory := true;
        NewTag.IsOPCTag := true;
        MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
        NewTag := TRTETag.Create('CD' + Name + '_Command', Self, VT_I2, 0);
        _Command := NewTag;
        NewTag.PLCTagEntry.IOReadOnly := true;
        NewTag.TagServerTagEntry.Memory := true;
        NewTag.IsOPCTag := true;
        MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
        NewTag := TRTETag.Create('CD' + Name + '_Result', Self, VT_I2, 0);
        _Result := NewTag;
        NewTag.PLCTagEntry.Memory := true;
        NewTag.TagServerTagEntry.IOReadOnly := true;
        NewTag.IsOPCTag := true;
        MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
      end;//0
      2:
      begin
          NewTag := TRTETag.Create('CD' + Name + '_1IO_R', Self, VT_BOOL, FALSE);
          _1IO_R := NewTag;
          NewTag.PLCTagEntry.IOReadOnly := true;
          NewTag.TagServerTagEntry.Memory := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          NewTag := TRTETag.Create('CD' + Name + '_1I_R', Self, VT_BOOL, FALSE);
          _1I_R := NewTag;
          NewTag.PLCTagEntry.IOReadOnly := true;
          NewTag.TagServerTagEntry.Memory := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          //_2SN
          NewTag := TRTETag.Create('CD' + Name + '_2SN', Self, VT_BOOL, FALSE);
          _2SN := NewTag;
          NewTag.PLCTagEntry.Phisical := true;
          NewTag.TagServerTagEntry.IOReadOnly := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
          //_1SN
          NewTag := TRTETag.Create('CD' + Name + '_1SN', Self, VT_BOOL, FALSE);
          _1SN := NewTag;
          NewTag.PLCTagEntry.Phisical := true;
          NewTag.TagServerTagEntry.IOReadOnly := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
          //_KP_L1
          NewTag := TRTETag.Create('CD' + Name + '_KP_L1', Self, VT_BOOL, FALSE);
          _KP_L1 := NewTag;
          NewTag.PLCTagEntry.Phisical := true;
          NewTag.TagServerTagEntry.IOReadOnly := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
          //_2IP_L1
          NewTag := TRTETag.Create('CD' + Name + '_2IP_L1', Self, VT_BOOL, FALSE);
          _2IP_L1 := NewTag;
          NewTag.PLCTagEntry.Phisical := true;
          NewTag.TagServerTagEntry.IOReadOnly := true;
          NewTag.TagServerTagEntry.OPCItemUseTagname := false;
          NewTag.TagServerTagEntry.OPCItemName := 'CD' + Name + '_2IP';
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
          //_2IP
          NewTag := TRTETag.Create('CD' + Name + '_2IP', Self, VT_BOOL, FALSE);
          _2IP := NewTag;
          NewTag.PLCTagEntry.Memory := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          //_2I_L1
          if is2I_L1Exists then
          begin
              NewTag := TRTETag.Create('CD' + Name + '_2I_L1', Self, VT_BOOL, FALSE);
              _2I_L1 := NewTag;
              NewTag.PLCTagEntry.Phisical := true;
              NewTag.TagServerTagEntry.IOReadOnly := true;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
          end;
          //_2VSN_L1
          if is2VSN_L1Exists then
          begin
              NewTag := TRTETag.Create('CD' + Name + '_2VSN_L1', Self, VT_BOOL, FALSE);
              _2VSN_L1 := NewTag;
              NewTag.PLCTagEntry.Phisical := true;
              NewTag.TagServerTagEntry.IOReadOnly := true;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
          end;
          //_2PV_L1
          NewTag := TRTETag.Create('CD' + Name + '_2PV_L1', Self, VT_BOOL, FALSE);
          _2PV_L1 := NewTag;
          NewTag.PLCTagEntry.Phisical := true;
          NewTag.TagServerTagEntry.IOReadOnly := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
          NewTag := TRTETag.Create('CD' + Name + '_Command', Self, VT_I2, 0);
          _Command := NewTag;
          NewTag.PLCTagEntry.IOReadOnly := true;
          NewTag.TagServerTagEntry.Memory := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          NewTag := TRTETag.Create('CD' + Name + '_Result', Self, VT_I2, 0);
          _Result := NewTag;
          NewTag.PLCTagEntry.Memory := true;
          NewTag.TagServerTagEntry.IOReadOnly := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
      end;//2
      1:
      begin
          //индикатор приема (желтый)
          NewTag := TRTETag.Create('CD' + Name + '_L1', Self, VT_BOOL, FALSE);
          _L1 := NewTag;
          NewTag.TagServerTagEntry.IOReadOnly := true;
          if (ControlType = 0) then
          begin
              NewTag.PLCTagEntry.Phisical := true;
              MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
          end
          else
          begin
              NewTag.PLCTagEntry.IOReadOnly := true;
              if (not BindStationCode.Equals('0')) AND (not BindStationCode.Equals(string.Empty)) then
              begin
                  NewTag.PLCTagEntry.OPCItemUseTagname := false;
                  NewTag.PLCTagEntry.OPCItemName := 'CD' + BindStationCode.Trim() + '_' + CodeName + '_L2';
                  NewTag.PLCTagEntry.ServerAlias := 'Station' + BindStationCode.Trim();
                  if MPRCore.MSURTESettings.IsEmulation  then
                    MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
              end;
          end;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          //индикатор отправления (зеленый)
          NewTag := TRTETag.Create('CD' + Name + '_L2', Self, VT_BOOL, FALSE);
          _L2 := NewTag;
          NewTag.TagServerTagEntry.IOReadOnly := true;
          if ControlType = 0 then
          begin
              NewTag.PLCTagEntry.Phisical := true;
              MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
          end
          else
          begin
              NewTag.PLCTagEntry.IOReadOnly := true;
              if (not BindStationCode.Equals('0')) AND (not BindStationCode.Equals(string.Empty)) then
              begin
                  NewTag.PLCTagEntry.OPCItemUseTagname := false;
                  NewTag.PLCTagEntry.OPCItemName := 'CD' + BindStationCode.Trim() + '_' + CodeName + '_L1';
                  NewTag.PLCTagEntry.ServerAlias := 'Station' + BindStationCode.Trim();
                  if MPRCore.MSURTESettings.IsEmulation  then
                    MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
              end;
          end;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          //сигналы с соседней станции
          if (not BindStationCode.Equals('0')) AND (not BindStationCode.Equals(string.Empty)) then
          begin
              NewTag := TRTETag.Create('CD' + BindStationCode.Trim() + '_' + CodeName + '_SN', Self, VT_BOOL, FALSE);
              _SN_NET := NewTag;
              NewTag.PLCTagEntry.IOReadOnly := true;
              NewTag.PLCTagEntry.ServerAlias := 'Station' + BindStationCode.Trim();
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              if MPRCore.MSURTESettings.IsEmulation  then
                MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
              NewTag := TRTETag.Create('CD' + BindStationCode.Trim() + '_' + CodeName + '_OV', Self, VT_BOOL, FALSE);
              _OV_NET := NewTag;
              NewTag.PLCTagEntry.IOReadOnly := true;
              NewTag.PLCTagEntry.ServerAlias := 'Station' + BindStationCode.Trim();
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              if MPRCore.MSURTESettings.IsEmulation  then
                MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
              NewTag := TRTETag.Create('CD' + BindStationCode.Trim() + '_' + CodeName + '_PV', Self, VT_BOOL, FALSE);
              _PV_NET := NewTag;
              NewTag.PLCTagEntry.IOReadOnly := true;
              NewTag.PLCTagEntry.ServerAlias := 'Station' + BindStationCode.Trim();
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              if MPRCore.MSURTESettings.IsEmulation  then
                MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
          end;//if
      end;//1
      3:
      begin
          NewTag := TRTETag.Create('CD' + Name + '_1IO_R', Self, VT_BOOL, FALSE);
          _1IO_R := NewTag;
          NewTag.PLCTagEntry.IOReadOnly := true;
          NewTag.TagServerTagEntry.Memory := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          NewTag := TRTETag.Create('CD' + Name + '_1I_R', Self, VT_BOOL, FALSE);
          _1I_R := NewTag;
          NewTag.PLCTagEntry.IOReadOnly := true;
          NewTag.TagServerTagEntry.Memory := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          //_2SN
          NewTag := TRTETag.Create('CD' + Name + '_2SN', Self, VT_BOOL, FALSE);
          _2SN := NewTag;
          NewTag.PLCTagEntry.Memory := true;
          NewTag.TagServerTagEntry.IOReadOnly := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          //_1SN
          NewTag := TRTETag.Create('CD' + Name + '_1SN', Self, VT_BOOL, FALSE);
          _1SN := NewTag;
          NewTag.PLCTagEntry.Memory := true;
          NewTag.TagServerTagEntry.IOReadOnly := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          //_KP_L1
          NewTag := TRTETag.Create('CD' + Name + '_KP_L1', Self, VT_BOOL, FALSE);
          _KP_L1 := NewTag;
          NewTag.PLCTagEntry.Memory := true;
          NewTag.TagServerTagEntry.IOReadOnly := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          //_2IP_L1
          NewTag := TRTETag.Create('CD' + Name + '_2IP_L1', Self, VT_BOOL, FALSE);
          _2IP_L1 := NewTag;
          NewTag.PLCTagEntry.Memory := true;
          NewTag.TagServerTagEntry.IOReadOnly := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          //Command
          NewTag := TRTETag.Create('CD' + Name + '_Command', Self, VT_I2, 0);
          _Command := NewTag;
          NewTag.PLCTagEntry.IOReadOnly := true;
          NewTag.TagServerTagEntry.Memory := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          //Result
          NewTag := TRTETag.Create('CD' + Name + '_Result', Self, VT_I2, 0);
          _Result := NewTag;
          NewTag.PLCTagEntry.Memory := true;
          NewTag.TagServerTagEntry.IOReadOnly := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          //_1IO_R_OUT
          NewTag := TRTETag.Create('CD' + Name + '_1IO_R_OUT', Self, VT_BOOL, FALSE);
          _1IO_R_OUT := NewTag;
          NewTag.PLCTagEntry.Memory := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          if BusType = 1 then
          begin
            MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
          end;
          //_1I_R_OUT
          NewTag := TRTETag.Create('CD' + Name + '_1I_R_OUT', Self, VT_BOOL, FALSE);
          _1I_R_OUT := NewTag;
          NewTag.PLCTagEntry.Memory := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          if BusType = 1 then
          begin
            MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
          end;
          //_BU
          NewTag := TRTETag.Create('CD' + Name + '_BU', Self, VT_BOOL, FALSE);
          _BU := NewTag;
          NewTag.PLCTagEntry.Memory := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          if BusType = 1 then
          begin
            MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
          end;
          //_SN_OUT
          NewTag := TRTETag.Create('CD' + Name + '_SN_OUT', Self, VT_BOOL, FALSE);
          _SN_OUT := NewTag;
          NewTag.PLCTagEntry.Memory := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          if MPRCore.MSURTESettings.IsEmulation OR (BusType = 1) then
            MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
          //_PV_OUT
          NewTag := TRTETag.Create('CD' + Name + '_PV_OUT', Self, VT_BOOL, FALSE);
          _PV_OUT := NewTag;
          NewTag.PLCTagEntry.Memory := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          if MPRCore.MSURTESettings.IsEmulation OR (BusType = 1) then
            MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
          //_OV_OUT
          NewTag := TRTETag.Create('CD' + Name + '_OV_OUT', Self, VT_BOOL, FALSE);
          _OV_OUT := NewTag;
          NewTag.PLCTagEntry.Memory := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          if MPRCore.MSURTESettings.IsEmulation OR (BusType = 1) then
            MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
          //индикатор приема (желтый)
          NewTag := TRTETag.Create('CD' + Name + '_L1', Self, VT_BOOL, FALSE);
          _L1 := NewTag;
          if ControlType = 0 then
          begin
              NewTag.PLCTagEntry.Phisical := true;
              NewTag.forCstApps := true;   //тэг нужен VistGW
              MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
          end
          else
          begin
              case BusType of
                0:
                begin
                  NewTag.PLCTagEntry.IOReadOnly := true;
                  if (not BindStationCode.Equals('0')) AND (not BindStationCode.Equals(string.Empty)) then
                  begin
                      NewTag.PLCTagEntry.OPCItemUseTagname := false;
                      NewTag.PLCTagEntry.OPCItemName := 'CD' + BindStationCode.Trim() + '_' + CodeName + '_L2';
                      NewTag.PLCTagEntry.ServerAlias := 'Station' + BindStationCode.Trim();
                      if MPRCore.MSURTESettings.IsEmulation  then
                      begin
                        MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
                      end;
                  end;
                end;//0
                1:
                begin
                  NewTag.PLCTagEntry.Phisical := true;
                  MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
                end;//1
              end;//case
          end;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          //индикатор отправления (зеленый)
          NewTag := TRTETag.Create('CD' + Name + '_L2', Self, VT_BOOL, FALSE);
          _L2 := NewTag;
          if ControlType = 0 then
          begin
              NewTag.PLCTagEntry.Phisical := true;
              NewTag.forCstApps := true; //тэг нужен VistGW
              MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
          end
          else
          begin
             case BusType of
                0:
                begin
                  NewTag.PLCTagEntry.IOReadOnly := true;
                  if (not BindStationCode.Equals('0')) AND (not BindStationCode.Equals(string.Empty)) then
                  begin
                      NewTag.PLCTagEntry.OPCItemUseTagname := false;
                      NewTag.PLCTagEntry.OPCItemName := 'CD' + BindStationCode.Trim() + '_' + CodeName + '_L2';
                      NewTag.PLCTagEntry.ServerAlias := 'Station' + BindStationCode.Trim();
                      if MPRCore.MSURTESettings.IsEmulation  then
                      begin
                        MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
                      end;
                  end;
                end;//0
                1:
                begin
                  NewTag.PLCTagEntry.Phisical := true;
                  MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
                end;//1
             end;//case
          end;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          //сигналы с соседней станции
          if (not BindStationCode.Equals('0')) AND (not BindStationCode.Equals(string.Empty)) then
          begin
              //_2PBU
              NewTag := TRTETag.Create('CD' + Name + '_2PBU', Self, VT_BOOL, FALSE);
              _2PBU := NewTag;
              NewTag.PLCTagEntry.IOReadOnly := true;
              NewTag.PLCTagEntry.OPCItemUseTagname := false;
              NewTag.PLCTagEntry.OPCItemName := 'CD' + BindStationCode.Trim() + '_' + CodeName + '_BU';
              NewTag.PLCTagEntry.ServerAlias := 'Station' + BindStationCode.Trim();
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              if MPRCore.MSURTESettings.IsEmulation OR (BusType = 1)  then
                MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
              //_2IP
              NewTag := TRTETag.Create('CD' + Name + '_2IP', Self, VT_BOOL, FALSE);
              _2IP := NewTag;
              NewTag.PLCTagEntry.IOReadOnly := true;
              NewTag.PLCTagEntry.OPCItemUseTagname := false;
              NewTag.PLCTagEntry.OPCItemName := 'CD' + BindStationCode.Trim() + '_' + CodeName + '_1IO_R_OUT';
              NewTag.PLCTagEntry.ServerAlias := 'Station' + BindStationCode.Trim();
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              if MPRCore.MSURTESettings.IsEmulation  OR (BusType = 1) then
                MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
              //_1I_R_L1
              NewTag := TRTETag.Create('CD' + Name + '_1I_R_L1', Self, VT_BOOL, FALSE);
              _1I_R_L1 := NewTag;
              NewTag.PLCTagEntry.IOReadOnly := true;
              NewTag.PLCTagEntry.OPCItemUseTagname := false;
              NewTag.PLCTagEntry.OPCItemName := 'CD' + BindStationCode.Trim() + '_' + CodeName + '_1I_R_OUT';
              NewTag.PLCTagEntry.ServerAlias := 'Station' + BindStationCode.Trim();
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              if MPRCore.MSURTESettings.IsEmulation  OR (BusType = 1) then
                MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
              NewTag := TRTETag.Create('CD' + Name + '_2VSN_L1', Self, VT_BOOL, FALSE);
              _2VSN_L1 := NewTag;
              NewTag.PLCTagEntry.IOReadOnly := true;
              NewTag.PLCTagEntry.OPCItemUseTagname := false;
              NewTag.PLCTagEntry.OPCItemName := 'CD' + BindStationCode.Trim() + '_' + CodeName + '_SN_OUT';
              NewTag.PLCTagEntry.ServerAlias := 'Station' + BindStationCode.Trim();
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              if MPRCore.MSURTESettings.IsEmulation  OR (BusType = 1) then
                MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
              NewTag := TRTETag.Create('CD' + Name + '_2PV_L1', Self, VT_BOOL, FALSE);
              _2PV_L1 := NewTag;
              NewTag.PLCTagEntry.IOReadOnly := true;
              NewTag.PLCTagEntry.OPCItemUseTagname := false;
              NewTag.PLCTagEntry.OPCItemName := 'CD' + BindStationCode.Trim() + '_' + CodeName + '_PV_OUT';
              NewTag.PLCTagEntry.ServerAlias := 'Station' + BindStationCode.Trim();
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              if MPRCore.MSURTESettings.IsEmulation  OR (BusType = 1) then
                MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
              NewTag := TRTETag.Create('CD' + Name + '_2OV_L1', Self, VT_BOOL, FALSE);
              _2OV_L1 := NewTag;
              NewTag.PLCTagEntry.IOReadOnly := true;
              NewTag.PLCTagEntry.OPCItemUseTagname := false;
              NewTag.PLCTagEntry.OPCItemName := 'CD' + BindStationCode.Trim() + '_' + CodeName + '_OV_OUT';
              NewTag.PLCTagEntry.ServerAlias := 'Station' + BindStationCode.Trim();
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              if MPRCore.MSURTESettings.IsEmulation  OR (BusType = 1) then
                MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
          end;
          //выходные тэги для полевой шины
          //_1OT_OUT команда на отправление
          NewTag := TRTETag.Create('CD' + Name + '_1OT_OUT', Self, VT_BOOL, FALSE);
          _1OT_OUT := NewTag;
          if ControlType = 0 then
          begin
              NewTag.PLCTagEntry.Phisical := true;
              MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
          end
          else
          begin
              NewTag.PLCTagEntry.Memory := true;
          end;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          //_1PR_OUT команда на прием
          NewTag := TRTETag.Create('CD' + Name + '_1PR_OUT', Self, VT_BOOL, FALSE);
          _1PR_OUT := NewTag;
          if ControlType = 0 then
          begin
              NewTag.PLCTagEntry.Phisical := true;
              MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
          end
          else
          begin
              NewTag.PLCTagEntry.Memory := true;
          end;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
      end;//3
  end;//case
  NewTag := TRTETag.Create('CD' + Name, Self, VT_I2, 0);
  MainTag := NewTag;
  NewTag.PLCTagEntry.Memory := true;
  NewTag.TagServerTagEntry.IOReadOnly := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  case (ControlMode) of
      0: //СЦБ
      begin
          NewTag := TRTETag.Create('CD' + Name + '_SN_OUT', Self, VT_BOOL, FALSE);
          _SN_OUT := NewTag;
          NewTag.PLCTagEntry.Phisical := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
          NewTag := TRTETag.Create('CD' + Name + '_OV_OUT', Self, VT_BOOL, FALSE);
          _OV_OUT := NewTag;
          NewTag.PLCTagEntry.Phisical := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
          NewTag := TRTETag.Create('CD' + Name + '_PV_OUT', Self, VT_BOOL, FALSE);
          _PV_OUT := NewTag;
          NewTag.PLCTagEntry.Phisical := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
          NewTag := TRTETag.Create('CD' + Name + '_1I_OUT', Self, VT_BOOL, FALSE);
          _1I_OUT := NewTag;
          NewTag.PLCTagEntry.Phisical := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
      end;//0
      1: //МСУ
      begin
          NewTag := TRTETag.Create('CD' + Name + '_SN1', Self, VT_BOOL, FALSE);
          _SN1 := NewTag;
          if ControlType = 0 then
          begin
              NewTag.PLCTagEntry.Phisical := true;
              MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
          end
          else
          begin
              NewTag.PLCTagEntry.Memory := true;
              if MPRCore.MSURTESettings.IsEmulation  then
                MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
          end;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          NewTag := TRTETag.Create('CD' + Name + '_SN2', Self, VT_BOOL, FALSE);
          _SN2 := NewTag;
          if ControlType = 0 then
          begin
              NewTag.PLCTagEntry.Phisical := true;
              MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
          end
          else
          begin
              NewTag.PLCTagEntry.Memory := true;
              if MPRCore.MSURTESettings.IsEmulation  then
                MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
          end;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
      end;//1
      2: //увязка с ЖДА
      begin
          NewTag := TRTETag.Create('CD' + Name + '_PKP_OUT', Self, VT_BOOL, FALSE);
          _PKP_OUT := NewTag;
          NewTag.PLCTagEntry.Phisical := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
          if is2I_L1Exists then
          begin
              NewTag := TRTETag.Create('CD' + Name + '_KP_OUT', Self, VT_BOOL, FALSE);
              _KP_OUT := NewTag;
              NewTag.PLCTagEntry.Phisical := true;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
              NewTag := TRTETag.Create('CD' + Name + '_KP_BLOCK', Self, VT_BOOL, FALSE);
              _KP_BLOCK := NewTag;
              NewTag.PLCTagEntry.Phisical := true;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
          end;
          NewTag := TRTETag.Create('CD' + Name + '_1SN_OUT', Self, VT_BOOL, FALSE);
          _1SN_OUT := NewTag;
          NewTag.PLCTagEntry.Phisical := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
          NewTag := TRTETag.Create('CD' + Name + '_1OV_OUT', Self, VT_BOOL, FALSE);
          _1OV_OUT := NewTag;
          NewTag.PLCTagEntry.Phisical := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
          NewTag := TRTETag.Create('CD' + Name + '_2PV_OUT', Self, VT_BOOL, FALSE);
          _2PV_OUT := NewTag;
          NewTag.PLCTagEntry.Phisical := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
          if is2VSN_L1Exists then
          begin
              NewTag := TRTETag.Create('CD' + Name + '_2VSN_OUT', Self, VT_BOOL, FALSE);
              _2VSN_OUT := NewTag;
              NewTag.PLCTagEntry.Phisical := true;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
              NewTag := TRTETag.Create('CD' + Name + '_2VSN_BLOCK', Self, VT_BOOL, FALSE);
              _2VSN_BLOCK := NewTag;
              NewTag.PLCTagEntry.Phisical := true;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
          end;
          NewTag := TRTETag.Create('CD' + Name + '_1IO_OUT', Self, VT_BOOL, FALSE);
          _1IO_OUT := NewTag;
          NewTag.PLCTagEntry.Phisical := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
          NewTag := TRTETag.Create('CD' + Name + '_1IO_BLOCK', Self, VT_BOOL, FALSE);
          _1IO_BLOCK := NewTag;
          NewTag.PLCTagEntry.Phisical := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
          NewTag := TRTETag.Create('CD' + Name + '_1I_OUT', Self, VT_BOOL, FALSE);
          _1I_OUT := NewTag;
          NewTag.PLCTagEntry.Phisical := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
          NewTag := TRTETag.Create('CD' + Name + '_1I_BLOCK', Self, VT_BOOL, FALSE);
          _1I_BLOCK := NewTag;
          NewTag.PLCTagEntry.Phisical := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
          if isBU_L1Exists then
          begin
              NewTag := TRTETag.Create('CD' + Name + '_BU_OUT', Self, VT_BOOL, FALSE);
              _BU_OUT := NewTag;
              NewTag.PLCTagEntry.Phisical := true;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
              NewTag := TRTETag.Create('CD' + Name + '_BU_BLOCK', Self, VT_BOOL, FALSE);
              _BU_BLOCK := NewTag;
              NewTag.PLCTagEntry.Phisical := true;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
              NewTag := TRTETag.Create('CD' + Name + '_BU_L1', Self, VT_BOOL, FALSE);
              _BU_L1 := NewTag;
              NewTag.PLCTagEntry.Phisical := true;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
          end;
          NewTag := TRTETag.Create('CD' + Name + '_1PV_OUT', Self, VT_BOOL, FALSE);
          _1PV_OUT := NewTag;
          NewTag.PLCTagEntry.Phisical := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
          NewTag := TRTETag.Create('CD' + Name + '_1PV_BLOCK', Self, VT_BOOL, FALSE);
          _1PV_BLOCK := NewTag;
          NewTag.PLCTagEntry.Phisical := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
          NewTag := TRTETag.Create('CD' + Name + '_1SVH_OUT', Self, VT_BOOL, FALSE);
          _1SVH_OUT := NewTag;
          NewTag.PLCTagEntry.Phisical := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
          NewTag := TRTETag.Create('CD' + Name + '_1SVH_BLOCK', Self, VT_BOOL, FALSE);
          _1SVH_BLOCK := NewTag;
          NewTag.PLCTagEntry.Phisical := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
          if is1OT_OUTExists then
          begin
              NewTag := TRTETag.Create('CD' + Name + '_1PR_OUT', Self, VT_BOOL, FALSE);
              _1PR_OUT := NewTag;
              NewTag.PLCTagEntry.Phisical := true;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
              NewTag := TRTETag.Create('CD' + Name + '_1PR_BLOCK', Self, VT_BOOL, FALSE);
              _1PR_BLOCK := NewTag;
              NewTag.PLCTagEntry.Phisical := true;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
              NewTag := TRTETag.Create('CD' + Name + '_1OT_OUT', Self, VT_BOOL, FALSE);
              _1OT_OUT := NewTag;
              NewTag.PLCTagEntry.Phisical := true;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
              NewTag := TRTETag.Create('CD' + Name + '_1OT_BLOCK', Self, VT_BOOL, FALSE);
              _1OT_BLOCK := NewTag;
              NewTag.PLCTagEntry.Phisical := true;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
          end;
          if not is2PBUExists then
          begin
              NewTag := TRTETag.Create('CD' + Name + '_2PBU_OUT', Self, VT_BOOL, FALSE);
              _2PBU_OUT := NewTag;
              NewTag.PLCTagEntry.Phisical := true;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
              NewTag := TRTETag.Create('CD' + Name + '_2PBU_BLOCK', Self, VT_BOOL, FALSE);
              _2PBU_BLOCK := NewTag;
              NewTag.PLCTagEntry.Phisical := true;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
              NewTag := TRTETag.Create('CD' + Name + '_2PBU_L1', Self, VT_BOOL, FALSE);
              _2PBU_L1 := NewTag;
              NewTag.PLCTagEntry.Phisical := true;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
          end;//if not is2PBUExists then
      end;//2
  end;//case
end;

Destructor TRTEDAB.Destroy;
begin
  if Assigned(DABSections) then
  begin
    DABSections.Free;
    DABSections := nil;
  end;
  inherited;
end;

function TRTEDAB.PostProcessing;
begin
  Result := true;
end;

function TRTEDAB.GetCodeName;
var
  UPos : integer;
begin
  UPos := Name.IndexOf(MPRCore.MPR.StationCode);
  if (UPos = -1) then
  begin
    Result :=  string.Empty;
    Exit;
  end;
  Result := Name.Substring(UPos + (MPRCore.MPR.StationCode + '_').Length);
end;

function TMSURTECore.CreateDABs;
var
  OneRTEDAB : TRTEDAB;
  i : Integer;
begin
  Result := false;
  if not Assigned(RTEDABs) then Exit;
  RTEDABs.Clear;
  if not Assigned(MPR) then Exit;
  if not MPRLoaded then Exit;
  if Length(MPR.RWCD) <= 0 then
  begin
    Result := true;
    Exit;
  end;
  OneRTEDAB := nil;
  for i := 0 to High(MPR.RWCD) do
  begin
    try
      OneRTEDAB := TRTEDAB.Create(Self,MPR.RWCD[i]);
      //OneRTEDAB.ISidx := MPRCore.GetInputSignalForDAB(i);
    except
      AppLogger.AddErrorMessage('ДАБ '+ MPR.RWCD[i].Caption +': сбой при создании объекта.');
      Exit;
    end;
    RTEDABs.AddObject(OneRTEDAB.Name, OneRTEDAB);
  end;
  Result := true;
end;

Constructor TRTEVSSignal.Create;
var
  NewTag : TRTETag;
begin
  inherited Create(AMPRCore);
  MainTag := nil;
  _L0 := nil;
  _L1 := nil;
  RW_V_Signal := ARW_V_Signal;
  Name := RW_V_Signal.Code;
  FCaption := RW_V_Signal.Caption;
  //глобальные тэги
  NewTag := TRTETag.Create('S' + Name, Self, VT_I2, 0);
  MainTag := NewTag;
  NewTag.PLCTagEntry.Memory := true;
  NewTag.TagServerTagEntry.IOReadOnly := true;//было read/write
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  if RW_V_Signal.ControlType = 1 then
  begin
      NewTag := TRTETag.Create('S' + Name + '_L1', Self, VT_BOOL, FALSE);
      _L1 := NewTag;
      NewTag.PLCTagEntry.Phisical := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
      MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
  end
  else
  begin
      NewTag := TRTETag.Create('S' + Name + '_L0', Self, VT_BOOL, FALSE);
      _L0 := NewTag;
      NewTag.PLCTagEntry.Phisical := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
      MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
      NewTag := TRTETag.Create('S' + Name + '_L1', Self, VT_BOOL, FALSE);
      _L1 := NewTag;
      NewTag.PLCTagEntry.Phisical := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
      MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
  end;
end;

function TRTEVSSignal.PostProcessing;
begin
  Result := true;
end;

function TMSURTECore.CreateVSSignals;
var
  OneRTEVSSignal : TRTEVSSignal;
  i : Integer;
begin
  Result := false;
  if not Assigned(RTEVSSignals) then Exit;
  RTEVSSignals.Clear;
  if not Assigned(MPR) then Exit;
  if not MPRLoaded then Exit;
  if Length(MPR.RW_V_Signals) <= 0 then
  begin
    Result := true;
    Exit;
  end;
  OneRTEVSSignal := nil;
  for i := 0 to High(MPR.RW_V_Signals) do
  begin
    try
      OneRTEVSSignal := TRTEVSSignal.Create(Self,MPR.RW_V_Signals[i]);
    except
      AppLogger.AddErrorMessage('Въездной светофор '+ MPR.RW_V_Signals[i].Caption +': сбой при создании объекта.');
      Exit;
    end;
    RTEVSSignals.AddObject(OneRTEVSSignal.Name, OneRTEVSSignal);
  end;
  Result := true;
end;

Constructor TRTEStativ_Fuse.Create;
var
  NewTag : TRTETag;
begin
  inherited Create(AMPRCore);
  RTESysES := nil;
  MainTag := nil;
  StativFuse := AStativFuse;
  Name := StativFuse.Code;
  FCaption := StativFuse.Caption;
  SESIdx := StativFuse.SysESIndex;
  //Тэги
  NewTag := TRTETag.Create('T' + Name, Self, VT_BOOL, FALSE);
  MainTag := NewTag;
  NewTag.TagServerTagEntry.IOReadOnly := true;
  NewTag.PLCTagEntry.Memory := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  NewTag := TRTETag.Create('T' + Name+ '_L1', Self, VT_BOOL, FALSE);
  _L1 := NewTag;
  NewTag.PLCTagEntry.Phisical := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
end;

function TRTEStativ_Fuse.PostProcessing;
begin
  Result := true;
end;

function TMSURTECore.CreateStativ_Fuses;
var
  OneRTEStativ_Fuse : TRTEStativ_Fuse;
  i : Integer;
begin
  Result := false;
  if not Assigned(RTEStativ_Fuses) then Exit;
  RTEStativ_Fuses.Clear;
  if not Assigned(MPR) then Exit;
  if not MPRLoaded then Exit;
  if Length(MPR.StativFuses) <= 0 then
  begin
    Result := true;
    Exit;
  end;
  OneRTEStativ_Fuse := nil;
  for i := 0 to High(MPR.StativFuses) do
  begin
    try
      OneRTEStativ_Fuse := TRTEStativ_Fuse.Create(Self,MPR.StativFuses[i]);
    except
      AppLogger.AddErrorMessage('Предохранитель на стативе '+ MPR.StativFuses[i].Caption +': сбой при создании объекта.');
      Exit;
    end;
    RTEStativ_Fuses.AddObject(OneRTEStativ_Fuse.Name, OneRTEStativ_Fuse);
  end;
  Result := true;
end;

Constructor TRTESysES.Create(AMPRCore : TMSURTECore; ARWSysES : TSysES; AIdx : Integer);
var
  NewTag : TRTETag;
  ThisFuse : TRTEStativ_Fuse;
  i : Integer;
begin
  inherited Create(AMPRCore);
  RWSysES := ARWSysES;
  Name := RWSysES.Code;
  FCaption := RWSysES.Caption;
  SESIdx := AIdx;
  StativFuses := TStringList.Create(false);
  isAmpermetrExists := true;//наличие ампереметра
  AmpermeterMin := 0;
  AmpermeterMax := 0;
  ScaleMax := 0;
  isFider1Exists := true;
  isFider2Exists := true;
  isFuseExists := true;
  isRMBButton := true;
  InversFiderControl := 0;
  //тэги
  RMB_BUTTON := nil;
  RMB_OUT := nil;
  RMB_MANUAL := nil;
  FIDER1 := nil;
  FIDER1_L1 := nil;
  FIDER1_IN := nil;
  FIDER1_IN_L1 := nil;
  FIDER2 := nil;
  FIDER2_L1 := nil;
  FIDER2_IN := nil;
  FIDER2_IN_L1 := nil;
  FUSE := nil;
  FUSE_L1 := nil;
  AmperMeter := nil;
  RMB_AUTO := nil;
  AmperMeter_Control := nil;
  //
  //заполнение свойств
  isAmpermetrExists := (RWSysES.Ampermeter_X <> -1);
  AmpermeterMin := RWSysES.Ampermeter_Min;
  AmpermeterMax := RWSysES.Ampermeter_Max;
  ScaleMax := RWSysES.Ampermeter_Scale;
  isFider1Exists := (RWSysES.Fider_1_X <> -1);
  isFider2Exists := (RWSysES.Fider_2_X <> -1);
  isFuseExists := (RWSysES.Fuse_X <> -1);
  isRMBButton := (RWSysES.RMB_X <> -1);
  InversFiderControl := RWSysES.InversFiderControl;
  FiderControl := MPRCore.MPR.FiderControl;
  if MPRCore.RTEStativ_Fuses.Count > 0 then
  begin
      for i := 0 to MPRCore.RTEStativ_Fuses.Count - 1 do
      begin
          ThisFuse := TRTEStativ_Fuse(MPRCore.RTEStativ_Fuses.Objects[i]);
          if (ThisFuse.SESIdx - 1) = SESIdx then
          begin
              ThisFuse.RTESysES := Self;
              StativFuses.AddObject(ThisFuse.Name,ThisFuse);
          end;
      end;//for
  end;//if

  //главные тэги
  if not(MPRCore.MPR.PointsDefendMode = 0) then
  begin
      if not MPRCore.MPR.SingleSysES then
      begin
          if isRMBButton then
          begin
              NewTag := TRTETag.Create('RMB_BUTTON_' + Name, Self, VT_BOOL, TRUE);
              RMB_BUTTON := NewTag;
              NewTag.PLCTagEntry.IOReadOnly := true;
              NewTag.TagServerTagEntry.Memory := true;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              NewTag := TRTETag.Create('RMB_OUT_' + Name, Self, VT_BOOL, TRUE);
              RMB_OUT := NewTag;
              NewTag.PLCTagEntry.Phisical := true;
              NewTag.TagServerTagEntry.IOReadOnly := true;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
              NewTag := TRTETag.Create('RMB_MANUAL_' + Name, Self, VT_BOOL, TRUE);
              RMB_MANUAL := NewTag;
              NewTag.PLCTagEntry.Memory := true;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              if isFider1Exists then
              begin
                  NewTag := TRTETag.Create('T' + MPRCore.MPR.StationCode + '_FIDER1_' + Name, Self, VT_BOOL, FALSE);
                  FIDER1 := NewTag;
                  NewTag.PLCTagEntry.Memory := true;
                  NewTag.TagServerTagEntry.IOReadOnly := true;
                  NewTag.IsOPCTag := true;
                  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
                  NewTag := TRTETag.Create('T' + MPRCore.MPR.StationCode + '_FIDER1_' + Name + '_L1', Self, VT_BOOL, FALSE);
                  FIDER1_L1 := NewTag;
                  NewTag.PLCTagEntry.Phisical := true;
                  NewTag.IsOPCTag := true;
                  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
                  MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
                  //_IN
                  if MPRCore.MPR.FiderControl then
                  begin
                      NewTag := TRTETag.Create('T' + MPRCore.MPR.StationCode + '_FIDER1_' + Name + '_IN', Self, VT_BOOL, FALSE);
                      FIDER1_IN := NewTag;
                      NewTag.PLCTagEntry.Memory := true;
                      NewTag.TagServerTagEntry.IOReadOnly := true;
                      NewTag.IsOPCTag := true;
                      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
                      NewTag := TRTETag.Create('T' + MPRCore.MPR.StationCode + '_FIDER1_' + Name + '_IN_L1', Self, VT_BOOL, FALSE);
                      FIDER1_IN_L1 := NewTag;
                      NewTag.PLCTagEntry.Phisical := true;
                      NewTag.IsOPCTag := true;
                      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
                      MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
                  end; //if MPRCore.MPR.FiderControl then
              end;//if isFider1Exists then
              if isFider2Exists then
              begin
                  NewTag := TRTETag.Create('T' + MPRCore.MPR.StationCode + '_FIDER2_' + Name, Self, VT_BOOL, FALSE);
                  FIDER2 := NewTag;
                  NewTag.PLCTagEntry.Memory := true;
                  NewTag.TagServerTagEntry.IOReadOnly := true;
                  NewTag.IsOPCTag := true;
                  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
                  NewTag := TRTETag.Create('T' + MPRCore.MPR.StationCode + '_FIDER2_' + Name + '_L1', Self, VT_BOOL, FALSE);
                  FIDER2_L1 := NewTag;
                  NewTag.PLCTagEntry.Phisical := true;
                  NewTag.IsOPCTag := true;
                  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
                  MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
                  //_IN
                  if MPRCore.MPR.FiderControl then
                  begin
                      NewTag := TRTETag.Create('T' + MPRCore.MPR.StationCode + '_FIDER2_' + Name + '_IN', Self, VT_BOOL, FALSE);
                      FIDER2_IN := NewTag;
                      NewTag.PLCTagEntry.Memory := true;
                      NewTag.TagServerTagEntry.IOReadOnly := true;
                      NewTag.IsOPCTag := true;
                      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
                      NewTag := TRTETag.Create('T' + MPRCore.MPR.StationCode + '_FIDER2_' + Name + '_IN_L1', Self, VT_BOOL, FALSE);
                      FIDER2_IN_L1 := NewTag;
                      NewTag.PLCTagEntry.Phisical := true;
                      NewTag.IsOPCTag := true;
                      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
                      MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
                  end;//if MPRCore.MPR.FiderControl then
              end;//if isFider2Exists then
              if isFuseExists then
              begin
                  NewTag := TRTETag.Create('T' + MPRCore.MPR.StationCode + '_FUSE_' + Name, Self, VT_BOOL, FALSE);
                  FUSE := NewTag;
                  NewTag.PLCTagEntry.Memory := true;
                  NewTag.TagServerTagEntry.IOReadOnly := true;
                  NewTag.IsOPCTag := true;
                  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
                  if StativFuses.Count = 0 then
                  begin
                      NewTag := TRTETag.Create('T' + MPRCore.MPR.StationCode + '_FUSE_' + Name + '_L1', Self, VT_BOOL, FALSE);
                      FUSE_L1 := NewTag;
                      NewTag.PLCTagEntry.Phisical := true;
                      NewTag.IsOPCTag := true;
                      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
                      MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
                  end;
              end;//if isFuseExists then
          end;//if isRMBButton
      end;//if MPRCore.MPR.SingleSysES = 1 then
  end; //if not(MPRCore.MPR.PointsDefendMode = 0) then
  if isAmpermetrExists then
  begin
      //integer тэг для AutoAmpermeterScale=1
      NewTag := TRTETag.Create('AmperMeter_' + Name, Self, VT_I2, 0);
      AmperMeter := NewTag;
      NewTag.PLCTagEntry.Phisical := true;
      NewTag.TagServerTagEntry.IOReadOnly := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
      MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
      //real-тэг для AutoAmpermeterScale=0
      NewTag := TRTETag.Create('AmperMeter_Control_' + Name, Self, VT_R4, 0);
      AmperMeter_Control := NewTag;
      NewTag.TagServerTagEntry.IOReadOnly := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  end;//if isAmpermetrExists then
end;

Constructor TRTESysES.Create(AMPRCore : TMSURTECore);
var
  NewTag : TRTETag;
  ThisFuse : TRTEStativ_Fuse;
  i : Integer;
begin
  inherited Create(AMPRCore);
  //RWSysES := nil;
  Name := MPRCore.MPR.StationCode + '_SysES0';  // "Код станции"+"_"+SysES"+номер.
  FCaption := MPRCore.MPR.StationCaption;
  SESIdx := 0;
  StativFuses := TStringList.Create(false);
  isAmpermetrExists := true;//наличие ампереметра
  AmpermeterMin := 0;
  AmpermeterMax := 0;
  ScaleMax := 0;
  isFider1Exists := true;
  isFider2Exists := true;
  isFuseExists := true;
  isRMBButton := true;
  InversFiderControl := 0;
  //тэги
  RMB_BUTTON := nil;
  RMB_OUT := nil;
  RMB_MANUAL := nil;
  FIDER1 := nil;
  FIDER1_L1 := nil;
  FIDER1_IN := nil;
  FIDER1_IN_L1 := nil;
  FIDER2 := nil;
  FIDER2_L1 := nil;
  FIDER2_IN := nil;
  FIDER2_IN_L1 := nil;
  FUSE := nil;
  FUSE_L1 := nil;
  AmperMeter := nil;
  RMB_AUTO := nil;
  AmperMeter_Control := nil;
  //
  //заполнение свойств
  isAmpermetrExists := (MPRCore.MPR.Ampermeter_X <> -1);
  AmpermeterMin := MPRCore.MPR.AmpermeterMin;
  AmpermeterMax := MPRCore.MPR.AmpermeterMax;
  ScaleMax := MPRCore.MPR.PointsAmpermeterScaleCount;
  isFider1Exists := (MPRCore.MPR.Fider1_X <> -1);
  isFider2Exists := (MPRCore.MPR.Fider2_X <> -1);
  isFuseExists := (MPRCore.MPR.Fuse_X <> -1);
  isRMBButton := (MPRCore.MPR.RMB_X <> -1);
  InversFiderControl := MPRCore.MPR.InversFiderControl;
  FiderControl := MPRCore.MPR.FiderControl;
  if MPRCore.RTEStativ_Fuses.Count > 0 then
  begin
      for i := 0 to MPRCore.RTEStativ_Fuses.Count - 1 do
      begin
        ThisFuse := TRTEStativ_Fuse(MPRCore.RTEStativ_Fuses.Objects[i]);
        ThisFuse.RTESysES := Self;
        StativFuses.AddObject(ThisFuse.Name,ThisFuse);
      end;//for
  end;//if
  //тэги
  if not(MPRCore.MPR.PointsDefendMode = 0) then
  begin
     NewTag := TRTETag.Create('RMB_BUTTON', MPRCore, VT_BOOL, TRUE);
     RMB_BUTTON := NewTag;
     NewTag.PLCTagEntry.IOReadOnly := true;
     NewTag.TagServerTagEntry.Memory := true;
     NewTag.IsOPCTag := true;
     MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
     NewTag := TRTETag.Create('RMB_OUT', MPRCore, VT_BOOL, TRUE);
     RMB_OUT := NewTag;
     NewTag.PLCTagEntry.Phisical := true;
     NewTag.TagServerTagEntry.IOReadOnly := true;
     NewTag.IsOPCTag := true;
     MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
     MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
  end;
  NewTag := TRTETag.Create('T' + MPRCore.MPR.StationCode + '_FIDER1', MPRCore, VT_BOOL, FALSE);
  FIDER1 := NewTag;
  NewTag.PLCTagEntry.Memory := true;
  NewTag.TagServerTagEntry.IOReadOnly := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  NewTag := TRTETag.Create('T' + MPRCore.MPR.StationCode + '_FIDER1_L1', MPRCore, VT_BOOL, FALSE);
  FIDER1_L1 := NewTag;
  NewTag.PLCTagEntry.Phisical := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
  if MPRCore.MPR.FiderControl then
  begin
    NewTag := TRTETag.Create('T' + MPRCore.MPR.StationCode + '_FIDER1_IN', MPRCore, VT_BOOL, FALSE);
    FIDER1_IN := NewTag;
    NewTag.PLCTagEntry.Memory := true;
    NewTag.TagServerTagEntry.IOReadOnly := true;
    NewTag.IsOPCTag := true;
    MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
    NewTag := TRTETag.Create('T' + MPRCore.MPR.StationCode + '_FIDER1_IN_L1', MPRCore, VT_BOOL, FALSE);
    FIDER1_IN_L1 := NewTag;
    NewTag.PLCTagEntry.Phisical := true;
    NewTag.IsOPCTag := true;
    MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
    MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
  end;
  NewTag := TRTETag.Create('T' + MPRCore.MPR.StationCode + '_FIDER2', MPRCore, VT_BOOL, FALSE);
  FIDER2 := NewTag;
  NewTag.PLCTagEntry.Memory := true;
  NewTag.TagServerTagEntry.IOReadOnly := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  NewTag := TRTETag.Create('T' + MPRCore.MPR.StationCode + '_FIDER2_L1', MPRCore, VT_BOOL, FALSE);
  FIDER2_L1 := NewTag;
  NewTag.PLCTagEntry.Phisical := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
  if MPRCore.MPR.FiderControl then
  begin
    NewTag := TRTETag.Create('T' + MPRCore.MPR.StationCode + '_FIDER2_IN', MPRCore, VT_BOOL, FALSE);
    FIDER2_IN := NewTag;
    NewTag.PLCTagEntry.Memory := true;
    NewTag.TagServerTagEntry.IOReadOnly := true;
    NewTag.IsOPCTag := true;
    MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
    NewTag := TRTETag.Create('T' + MPRCore.MPR.StationCode + '_FIDER2_IN_L1', MPRCore, VT_BOOL, FALSE);
    FIDER2_IN_L1 := NewTag;
    NewTag.PLCTagEntry.Phisical := true;
    NewTag.IsOPCTag := true;
    MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
    MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
  end;
  NewTag := TRTETag.Create('T' + MPRCore.MPR.StationCode + '_FUSE', MPRCore, VT_BOOL, FALSE);
  FUSE := NewTag;
  NewTag.PLCTagEntry.Memory := true;
  NewTag.TagServerTagEntry.IOReadOnly := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  if Length(MPRCore.MPR.StativFuses) = 0 Then
  begin
      NewTag := TRTETag.Create('T' + MPRCore.MPR.StationCode + '_FUSE_L1', MPRCore, VT_BOOL, FALSE);
      FUSE_L1 := NewTag;
      NewTag.PLCTagEntry.Phisical := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
      MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
  end;
  if not(MPRCore.MPR.PointsDefendMode = 0) then
  begin
     if MPRCore.MPR.PointsDefendMode = 1 Then
     begin
         //RMB_AUTO
         NewTag := TRTETag.Create('RMB_AUTO', MPRCore, VT_BOOL, TRUE);
         RMB_AUTO := NewTag;
         NewTag.PLCTagEntry.Memory := true;
         NewTag.IsOPCTag := true;
         MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
     end;
     //RMB_MANUAL
     NewTag := TRTETag.Create('RMB_MANUAL', MPRCore, VT_BOOL, TRUE);
     RMB_MANUAL := NewTag;
     NewTag.PLCTagEntry.Memory := true;
     NewTag.IsOPCTag := true;
     MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  end;
  //integer тэг для AutoAmpermeterScale=1
  NewTag := TRTETag.Create('AmperMeter', MPRCore, VT_I2, 0);
  AmperMeter := NewTag;
  NewTag.PLCTagEntry.Phisical := true;
  NewTag.TagServerTagEntry.IOReadOnly := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
  //real тэг для AutoAmpermeterScale=0
  NewTag := TRTETag.Create('AmperMeter_Control', MPRCore, VT_R4, 0);
  AmperMeter_Control := NewTag;
  NewTag.TagServerTagEntry.IOReadOnly := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
end;

function TRTESysES.PostProcessing;
begin
  Result := true;
end;

Destructor TRTESysES.Destroy;
begin
  if Assigned(StativFuses) then
  begin
    StativFuses.Free;
  end;
  inherited;
end;

function TMSURTECore.CreateRTESysESes;
var
  OneRTESysES : TRTESysES;
  i : Integer;
begin
  Result := false;
  if not Assigned(RTESysESes) then Exit;
  RTESysESes.Clear;
  if not Assigned(MPR) then Exit;
  if not MPRLoaded then Exit;
  if MPR.SingleSysES OR (Length(MPR.SysES) <= 0) then
  begin
    try
      OneRTESysES := TRTESysES.Create(Self);
      RTESysESes.AddObject(OneRTESysES.Name, OneRTESysES);
    except
      AppLogger.AddErrorMessage('Сбой при создании системы электропитания.');
      Exit;
    end;
  end
  else
  begin
    OneRTESysES := nil;
    for i := 0 to High(MPR.SysES) do
    begin
      try
        OneRTESysES := TRTESysES.Create(Self,MPR.SysES[i],i);
        RTESysESes.AddObject(OneRTESysES.Name, OneRTESysES);
      except
        AppLogger.AddErrorMessage('СЭС '+ MPR.SysES[i].Caption +': сбой при создании объекта.');
        Exit;
      end;
    end;
  end;
  Result := true;
end;

Constructor TRTEZSSignal.Create;
var
  NewTag : TRTETag;
begin
  inherited Create(AMPRCore);
  RW_Z_Signal := ARW_Z_Signal;
  Name := RW_Z_Signal.Code;
  FCaption := RW_Z_Signal.Caption;
  //тэги
  _L1 := nil;
  _Control := nil;
  //_L1
  NewTag := TRTETag.Create('Z' + Name + '_L1', Self, VT_BOOL, FALSE);
  _L1 := NewTag;
  NewTag.PLCTagEntry.Phisical := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
  //_Control
  NewTag := TRTETag.Create('Z' + Name + '_Control', Self, VT_BOOL, FALSE);
  _Control := NewTag;
  NewTag.TagServerTagEntry.IOReadOnly := true;
  NewTag.TagServerTagEntry.OPCItemUseTagname := false;
  NewTag.TagServerTagEntry.OPCItemName := 'Z' + Name + '_L1';
  NewTag.IsOPCTag := true;
  NewTag.OPCItemUseTagname := false;
  NewTag.OPCItemName := 'Z' + Name + '_L1';
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
end;

function TRTEZSSignal.PostProcessing;
begin
  Result := true;
end;

function TMSURTECore.CreateRTEZSSignals;
var
  OneRTEZSSignal : TRTEZSSignal;
  i : Integer;
begin
  Result := false;
  if not Assigned(RTEZSSignals) then Exit;
  RTEZSSignals.Clear;
  if not Assigned(MPR) then Exit;
  if not MPRLoaded then Exit;
  if Length(MPR.RW_Z_Signals) <= 0 then
  begin
    Result := true;
    Exit;
  end;
  OneRTEZSSignal := nil;
  for i := 0 to High(MPR.RW_Z_Signals) do
  begin
    try
      OneRTEZSSignal := TRTEZSSignal.Create(Self,MPR.RW_Z_Signals[i]);
    except
      AppLogger.AddErrorMessage('Заградительный светофор '+ MPR.RW_Z_Signals[i].Caption +': сбой при создании объекта.');
      Exit;
    end;
    RTEZSSignals.AddObject(OneRTEZSSignal.Name, OneRTEZSSignal);
  end;
  Result := true;
end;

Constructor TRTEAddSignal.Create;
var
  NewTag : TRTETag;
begin
  inherited Create(AMPRCore);
  _L1 := nil;
  _L2 := nil;
  _OUT1 := nil;
  _OUT2 := nil;
  _OUT3 := nil;
  _OUT := nil;
  _DeviceState := nil;
  MainTag := nil;
  RW_Add_Signal := ARW_Add_Signal;
  Name := RW_Add_Signal.Code;
  FCaption := RW_Add_Signal.Caption;
  SignalType := 0;
  SourceCode := string.Empty;
  SourceType := 0;
  BlockingMode := 0;
  ControlMode := 0;
  //тэги
  SignalType := RW_Add_Signal.SignalType;
  SourceCode := RW_Add_Signal.BasicSignalCode;
  SourceType := RW_Add_Signal.BasicSignalType;
  BlockingMode := RW_Add_Signal.SignalLockType;
  ControlMode := RW_Add_Signal.SignalControlType;
  //глобальные тэги
  NewTag := TRTETag.Create('S' + Name, Self, VT_I2, 0);
  MainTag := NewTag;
  case (SignalType) of
    6: //маршрутный указатель
    begin
        NewTag.PLCTagEntry.IOReadOnly := true;
        NewTag.TagServerTagEntry.Memory := true;
    end;//6
    else
    begin
        NewTag.PLCTagEntry.Memory := true;
        NewTag.TagServerTagEntry.IOReadOnly := true;
    end;//else
  end;//case (SignalType)
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  if SignalType = 1 then
  begin
      NewTag := TRTETag.Create('S' + Name + '_DeviceState', Self, VT_I2, 0);
      NewTag.PLCTagEntry.Memory := true;
      NewTag.TagServerTagEntry.IOReadOnly := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  end;//if SignalType = 1 then
  case (SignalType) of
    1://предупредительные
    begin
        case (SourceType) of//тип основного сигнала
          2: //поездной
          begin
              //используемые тэги
              NewTag := TRTETag.Create('S' + Name + '_L1', Self, VT_BOOL, FALSE);
              _L1 := NewTag;
              NewTag.PLCTagEntry.Phisical := true;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
              NewTag := TRTETag.Create('S' + Name + '_L2', Self, VT_BOOL, FALSE);
              _L2 := NewTag;
              NewTag.PLCTagEntry.Phisical := true;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
              //контроль
              if ControlMode = 0 then//программный тип управления
              begin
                  NewTag := TRTETag.Create('S' + Name + '_OUT1', Self, VT_BOOL, FALSE);
                  _OUT1 := NewTag;
                  NewTag.PLCTagEntry.Phisical := true;
                  NewTag.IsOPCTag := true;
                  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
                  MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
                  NewTag := TRTETag.Create('S' + Name + '_OUT2', Self, VT_BOOL, FALSE);
                  _OUT2 := NewTag;
                  NewTag.PLCTagEntry.Phisical := true;
                  NewTag.IsOPCTag := true;
                  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
                  MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
                  NewTag := TRTETag.Create('S' + Name + '_OUT3', Self, VT_BOOL, FALSE);
                  _OUT3 := NewTag;
                  NewTag.PLCTagEntry.Phisical := true;
                  NewTag.IsOPCTag := true;
                  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
                  MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
              end;
          end;//2
          5: //заградительный
          begin
              NewTag := TRTETag.Create('S' + Name + '_L1', Self, VT_BOOL, FALSE);
              _L1 := NewTag;
              NewTag.PLCTagEntry.Phisical := true;
              NewTag.IsOPCTag := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
          end;//5
        end;//case (SourceType) of
    end;//1
    2: //повторительные
    begin
        NewTag := TRTETag.Create('S' + Name + '_L1', Self, VT_BOOL, FALSE);
        _L1 := NewTag;
        NewTag.PLCTagEntry.Phisical := true;
        NewTag.IsOPCTag := true;
        MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
        MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
    end;//2
    6:
    begin
        NewTag := TRTETag.Create('S' + Name + '_OUT', Self, VT_BOOL, FALSE);
        _OUT := NewTag;
        NewTag.PLCTagEntry.Phisical := true;
        NewTag.IsOPCTag := true;
        MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
        MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
    end;//6
  end;//case (SignalType) of
end;

function TRTEAddSignal.PostProcessing;
begin
  Result := true;
end;

function TMSURTECore.CreateRTEAddSignals;
var
  OneRTEAddSignal : TRTEAddSignal;
  i : Integer;
begin
  Result := false;
  if not Assigned(RTEAddSignals) then Exit;
  RTEAddSignals.Clear;
  if not Assigned(MPR) then Exit;
  if not MPRLoaded then Exit;
  if Length(MPR.RW_Add_Signals) <= 0 then
  begin
    Result := true;
    Exit;
  end;
  OneRTEAddSignal := nil;
  for i := 0 to High(MPR.RW_Add_Signals) do
  begin
    try
      OneRTEAddSignal := TRTEAddSignal.Create(Self,MPR.RW_Add_Signals[i]);
    except
      AppLogger.AddErrorMessage('Дополнительный светофор '+ MPR.RW_Add_Signals[i].Caption +': сбой при создании объекта.');
      Exit;
    end;
    RTEAddSignals.AddObject(OneRTEAddSignal.Name, OneRTEAddSignal);
  end;
  Result := true;
end;

Constructor TRTEFence.Create;
var
  NewTag : TRTETag;
  ThisPoint : TRTEPoint;
  i,PntIdx : Integer;
begin
  inherited Create(AMPRCore);
  RWFence := ARWFence;
  Name := RWFence.Code;
  FCaption := RWFence.Caption;
  //
  _AE := nil;
  _IN := nil;
  MainTag := nil;
  _DA := nil;
  _DeviceState := nil;
  _PointsPlus := nil;
  _PointsMinus := nil;
  _OUT := nil;
  //
  Idx := -1;
  FencePointsPlus := TStringList.Create(false);
  FencePointsMinus := TStringList.Create(false);
  AllFencePoints := TStringList.Create(false);
  //
  CodingName := Name.Replace(MPRCore.MPR.StationCode + '_', '');
  if MPRCore.RTEPoints.Count > 0 then
  begin
      //Массив стрелок по плюсу
      if Length(RWFence.PointsPlus) > 0 then
      begin
        for i := 0 to High(RWFence.PointsPlus) do
        begin
          PntIdx := MPRCore.RTEPoints.IndexOf(RWFence.PointsPlus[i].Code);
          if PntIdx > -1 Then
          begin
              ThisPoint := TRTEPoint(MPRCore.RTEPoints.Objects[PntIdx]);
              ThisPoint := MPRCore.GetMainPoint(ThisPoint);
              if Assigned(ThisPoint) then
              begin
                  FencePointsPlus.AddObject(ThisPoint.Name,ThisPoint);
                  if ThisPoint.FencesWhereInvolve.IndexOf(Name) = -1 then
                      ThisPoint.FencesWhereInvolve.AddObject(Name, Self);
                  if AllFencePoints.IndexOf(ThisPoint.Name) = -1 then
                      AllFencePoints.AddObject(ThisPoint.Name, ThisPoint);
               end;// if Assigned(ThisPoint) then
          end;//if PntIdx > -1 Then
        end;//for i
      end;// if Length(RWFence.PointsPlus) > 0
      //Массив стрелок по минусу
      if Length(RWFence.PointsMinus) > 0 then
      begin
        for i := 0 to High(RWFence.PointsMinus) do
        begin
          PntIdx := MPRCore.RTEPoints.IndexOf(RWFence.PointsMinus[i].Code);
          if PntIdx > -1 Then
          begin
              ThisPoint := TRTEPoint(MPRCore.RTEPoints.Objects[PntIdx]);
              ThisPoint := MPRCore.GetMainPoint(ThisPoint);
              if Assigned(ThisPoint) then
              begin
                  FencePointsMinus.AddObject(ThisPoint.Name,ThisPoint);
                  if ThisPoint.FencesWhereInvolve.IndexOf(Name) = -1 then
                      ThisPoint.FencesWhereInvolve.AddObject(Name, Self);
                  if AllFencePoints.IndexOf(ThisPoint.Name) = -1 then
                      AllFencePoints.AddObject(ThisPoint.Name, ThisPoint);
               end;// if Assigned(ThisPoint) then
          end;//if PntIdx > -1 Then
        end;//for i
      end;// if Length(RWFence.PointsPlus) > 0
  end; //if MPRCore.RTEPoints.Count > 0 then
  //тэги
  NewTag := TRTETag.Create('F' + Name + '_AE', Self, VT_BOOL, FALSE);
  _AE := NewTag;
  NewTag.PLCTagEntry.Memory := true;
  NewTag.TagServerTagEntry.IOReadOnly := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  NewTag := TRTETag.Create('F' + Name + '_IN', Self, VT_BOOL, FALSE);
  _IN := NewTag;
  NewTag.PLCTagEntry.Phisical := true;
  NewTag.TagServerTagEntry.IOReadOnly := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
  NewTag := TRTETag.Create('F' + Name, Self, VT_I2, 0);
  MainTag := NewTag;
  NewTag.TagServerTagEntry.Memory := true;
  NewTag.PLCTagEntry.IOReadOnly := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  NewTag := TRTETag.Create('F' + Name + '_DA', Self, VT_I2, 0);
  _DA := NewTag;
  NewTag.PLCTagEntry.Memory := true;
  NewTag.TagServerTagEntry.IOReadwrite := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  NewTag := TRTETag.Create('F' + Name + '_DeviceState', Self, VT_I2, 0);
  _DeviceState := NewTag;
  NewTag.PLCTagEntry.Memory := true;
  NewTag.TagServerTagEntry.IOReadwrite := true;//????
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  NewTag := TRTETag.Create('F' + Name + '_PointsPlus', Self, VT_I2, 0);
  _PointsPlus := NewTag;
  NewTag.PLCTagEntry.Memory := true;
  NewTag.TagServerTagEntry.IOReadwrite := true;//????
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  NewTag := TRTETag.Create('F' + Name + '_PointsMinus', Self, VT_I2, 0);
  _PointsMinus := NewTag;
  NewTag.PLCTagEntry.Memory := true;
  NewTag.TagServerTagEntry.IOReadwrite := true;//????
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  NewTag := TRTETag.Create('F' + Name + '_OUT', Self, VT_BOOL, FALSE);
  _OUT := NewTag;
  NewTag.PLCTagEntry.Phisical := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
end;

Destructor TRTEFence.Destroy;
begin
  if Assigned(AllFencePoints) then
  begin
    AllFencePoints.Free;
    AllFencePoints := nil;
  end;
  if Assigned(FencePointsPlus) then
  begin
    FencePointsPlus.Free;
    FencePointsPlus := nil;
  end;
  if Assigned(FencePointsMinus) then
  begin
    FencePointsMinus.Free;
    FencePointsMinus := nil;
  end;
  inherited;
end;

function TRTEFence.PostProcessing;
begin
  Result := true;
end;

function TMSURTECore.CreateRTEFences;
var
  OneRTEFence : TRTEFence;
  i : Integer;
begin
  Result := false;
  if not Assigned(RTEFences) then Exit;
  RTEFences.Clear;
  if not Assigned(MPR) then Exit;
  if not MPRLoaded then Exit;
  if Length(MPR.RWFences) <= 0 then
  begin
    Result := true;
    Exit;
  end;
  OneRTEFence := nil;
  for i := 0 to High(MPR.RWFences) do
  begin
    try
      OneRTEFence := TRTEFence.Create(Self,MPR.RWFEnces[i]);
    except
      AppLogger.AddErrorMessage('Ограждение '+ MPR.RWFences[i].Caption +': сбой при создании объекта.');
      Exit;
    end;
    OneRTEFence.Idx := RTEFences.AddObject(OneRTEFence.Name, OneRTEFence);
  end;
  Result := true;
end;

function TMSURTECore.GetMainPoint;
begin
  if APoint.PointType = 1  then
  begin
    Result := APoint;
  end
  else
  begin
    Result := APoint.PointByBranch;
  end;
end;

Constructor TRTERoute.Create;
var
  NewTag : TRTETag;
begin
  inherited Create(AMPRCore);
  FirstSignal := nil;
  MainTag := nil;
  _LR := nil;
  _DA := nil;
  _RM := nil;
  _T := nil;
  RWRoute := ARWRoute;
  Name := RWRoute.Code;
  FCaption := RWRoute.Caption;
  //тэги
  //главный тэг
  NewTag := TRTETag.Create('U' + Name, Self, VT_I2, 0);
  MainTag := NewTag;
  NewTag.TagServerTagEntry.Memory := true;
  NewTag.PLCTagEntry.IOReadOnly := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  if MPRCore.MSURTESettings.IsEmulation  then
    if (RWRoute.RouteSimple = 1) then
      MPRCore.OASymbols.AddObject(NewTag.Name,NewTag);
  if (RWRoute.RouteSimple = 1) AND (Length(RWRoute.Crossings) > 0) then
  begin
      //создаем эти тэги только для простых маршрутов, содержащих переезды
      NewTag := TRTETag.Create('U' + Name + '_LR', Self, VT_I2, 0);
      _LR := NewTag;
      NewTag.TagServerTagEntry.Memory := true;
      NewTag.PLCTagEntry.IOReadOnly := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  end;
  if MPRCore.MPR.F_3_5_10_11_MPR then
  begin
      NewTag := TRTETag.Create('U' + Name + '_DA', Self, VT_I2, 0);
      _DA := NewTag;
      NewTag.TagServerTagEntry.Memory := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  end;
  if not MPRCore.MPR.F_3_5_10_11_MPR then
  begin
      if (RWRoute.RouteSimple = 1) then
      begin
          NewTag := TRTETag.Create('U' + Name + '_DA', Self, VT_I2, 0);
          _DA := NewTag;
          NewTag.TagServerTagEntry.Memory := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
      end;
  end;
  if not MPRCore.MPR.RouteControl then
  begin
      NewTag := TRTETag.Create('U' + Name + '_RM', Self, VT_BSTR, '');
      _RM := NewTag;
      NewTag.TagServerTagEntry.Memory := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
      NewTag := TRTETag.Create('U' + Name + '_T', Self, VT_BSTR, '');
      _T := NewTag;
      NewTag.TagServerTagEntry.Memory := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  end;//if not MPRCore.MPR.RouteControl then
end;

Destructor TRTERoute.Destroy;
begin
  inherited;
end;

function TRTERoute.PostProcessing;
var
  RTESignal : TRTESignal;
begin
  if RWRoute.RouteSimple = 1 then
  begin
    if MPRCore.RTESignals.Count > 0 then
    begin
      If RWRoute.FirstSignalIndex > -1 then
      begin
        try
          FirstSignal := TRTESignal(RWRoute.FirstSignalIndex);
        except
          FirstSignal := nil;
        end;
      end; //If RWRoute.FirstSignalIndex > -1
    end;//if MPRCore.RTESignals.Count > 0
  end;
  Result := true;
end;

function TMSURTECore.CreateRTERoutes;
var
  OneRTERoute : TRTERoute;
  i : Integer;
begin
  Result := false;
  if not Assigned(RTERoutes) then Exit;
  RTERoutes.Clear;
  if not Assigned(MPR) then Exit;
  if not MPRLoaded then Exit;
  if Length(MPR.RWRoutes) <= 0 then
  begin
    Result := true;
    Exit;
  end;
  OneRTERoute := nil;
  for i := 0 to High(MPR.RWRoutes) do
  begin
    try
      OneRTERoute := TRTERoute.Create(Self,MPR.RWRoutes[i]);
    except
      AppLogger.AddErrorMessage('Маршрут '+ MPR.RWRoutes[i].Caption +': сбой при создании объекта.');
      Exit;
    end;
    RTERoutes.AddObject(OneRTERoute.Name, OneRTERoute);
  end;
  Result := true;
end;

procedure TMSURTECore.Run;
begin
  //CalcSafeMode;
  obMain;
  PLC_WatchDog;
  TS_WatchDog;
  BOS_WatchDog;
end;

procedure TMSURTECore.obMain;
var
  CurrentDT: TDateTime;
begin
  if not Assigned(MPR) then Exit;
  (*определение длины последнего ScanTime*)
  CurrentDT := Now();
  (* При  запуске проекта вызвать функцию инициализации массивов и переменных МПР. *)
  IF not MPR_Params.OnStartUp THEN
  begin
    (* Сброс признака запуска проекта. *)
    MPR_Params.OnStartUp :=TRUE;
    (*Инициализация параметров и глобальных переменных МПР*)
    parInit;
    (*Инициализация массивов секций МПР*)
    rInit;
    (*Инициализация массивов стрелок МПР*)
    pInit;
    (*Инициализация массивов сигналов МПР*)
    sInit;
    (*Инициализация массивов СЭС МПР*)
    sesInit;
    (*Инициализация массивов въездных сигналов*)
    sVInit;
    (*инициализация лунных светофоров*)
    mlInit;
    (*Инициализация простых маршрутов МПР*)
    uInit;
    (*Инициализация ДАБ*)
    dabInit;
    (*Инициализация массивов переездов МПР*)
    gInit;
    (*Инициализация массивов ограждений МПР*)
    fInit;
    (*Инициализация массивов ПАБ МПР*)
    pabInit;
    (*Инициализация массива УП*)
    ppInit;
    (*Инициализация массива дополнительных сигналов*)
    asInit;
    (*Инициализация массива соединений*)
    connInit;
    (*Инициализация массива PFB Slave-ов*)
    pfbInit;
    (*инициализация массива выходных тэгов - дублей*)
    qdblInit;
  end
  else
  begin
    try
      MPR_Params.LastScanTime := MilliSecondsBetween(CurrentDT, LastDateTime);
    except
      MPR_Params.LastScanTime := MPR_Params.ScanInterval;
    end;
  end;
  LastDateTime := CurrentDT;
  (*1. Вызов функции чтения именованных тэгов в АП МПР *)
    connRead;(*Чтение тэгов соединений*)
    rRead;(*Функция чтения тэгов секций*)
    ppRead;(*чтение тэгов УП*)
    pRead;(*Чтение тэгов стрелок*)
    sRead;(*Чтение тэгов сигналов*)
    mlRead;(*Чтение тэгов лунных сигналов*)
    sVRead;(*Чтение тэгов въездных сигналов*)
    uRead;(*Чтение тэгов простых маршрутов*)
    dabRead;(*Чтение тэгов ДАБ*)
    gRead;(*Чтение тэгов переездов*)
    sesRead;(*Чтение тэгов СЭС*)
    fRead;(*Чтение тэгов ограждений*)
    zsRead;(*Чтение тэгов заградительных светофоров*)
    pabRead;(*Чтение тэгов ПАБ*)
    asRead; (*Чтение тэгов доп. сигналов*)
    pfbRead;(*Чтение тэгов состояния PFB Slave-ов*)
  (*2. вызов функций управления основными объектами станции *)
    connDo;(*вызов функции управления соединениями*)
    rDo;
    ppDo;
    pDo;(*Вызов функции управления главными стрелками станции. *)
    sDo;(*Вызов функции управления светофорами станции. *)
    mlDo;(*Вызов функции управления лунными пригласительными сигналами.*)
    dabDo;(*вызов функции управления ДАБ станции*)
    gDo;(*вызов функции управления переездами*)
    sesDo;(*вызов функции управления СЭС*)
    fDo;(*вызов функции управления ограждениями*)
    pabDo;
    asDo; (*доп. сигналы*)
    pfbDo; (*PFB Slaves*)
  (*4. Вызов функции записи изменений из АП МПР в именованные тэги*)
    rWrite;
    ppWrite;
    pWrite;(*Запись тэгов стрелок*)
    sWrite;(*Запись тэгов сигналов*)
    mlWrite;(*запись тэгов лунных сигналов*)
    sVWrite;(*запись тэгов въездных светофоров*)
    dabWrite;(*запись тэгов ДАБ*)
    gWrite;(*Запись тэгов переездов*)
    sesWrite;(*запись тэгов СЭС*)
    fWrite;(*Запись тэгов ограждений*)
    pabWrite;(*запись тэгов ПАБ*)
    asWrite;(*запись тэгов *)
    connWrite;(*запись тэгов соединений*)
    pfbWrite;(*запись тэгов состояния PFB Slave-ов*)
    qdblWrite;(* Запись в выходные тэги - дубли *)
end;

procedure TMSURTECore.parInit;
var
  J : Integer;
begin
  (*Инициализация параметров и глобальных переменных МПР*)
 (*Параметры станции,режимов и безопасности работы МПР*)
 //Параметры, совместимые с версией 2/4
 if not Assigned(MPR) then Exit;
 MPR_Params.ScanInterval := MPR.ScanInterval;
 J := MPR.ScanInterval;
 MPR_Params.CancelDelayShunt := MPR.CancelDelayShunt div J;
 MPR_Params.CancelDelayTrain := MPR.CancelDelayTrain div J;
 MPR_Params.TrainSignalDelay := MPR.TrainSignalDelay div J;
 MPR_Params.GSDelay := MPR.GSDelay div J;
 MPR_Params.UnLockSectionDelay := MPR.UnLockSectionDelay div J;
 MPR_Params.UnLockRouteSectionDelay := MPR.UnLockRouteSectionDelay div J;
 If MPR.SignalBlock = '1' then
  begin
    MPR_Params.SignalBlock := TRUE;
  end
  else
  begin
    MPR_Params.SignalBlock := FALSE;
  end;
 MPR_Params.PointsExecTime := MPR.PointsExecTime div J;
 MPR_Params.PointsMaxExecTime := MPR.PointsMaxExecTime div J;
 MPR_Params.PointsHoldTime := MPR.PointsHoldTime div J;
 MPR_Params.RouteDefineDelay := MPR.RouteDefineDelay div J;

 MPR_Params.PointsCatchDelay := MPR.PointsCatchDelay div J;
 MPR_Params.ManPointsCatchDelay := MPR.ManPointsCatchDelay div J;
 MPR_Params.ShuntBlock := (MPR.ShuntBlock = '1');
 //*** Параметры, совместимые с версией 2/4

 //Параметры, несовместимые с версией 2/4
 MPR_Params.SignalsTime := MPR.SignalsTime div J;
 MPR_Params.SignalCommandTime := MPR.SignalCommandTime div J;
 MPR_Params.RouteJumpScanCount := MPR.RouteJumpScanCount;
 MPR_Params.ReplaceCommandTimeOut := MPR.ReplaceCommandTimeOut div J;
 MPR_Params.DelayOfMLSignals := MPR.DelayOfMLSignals div J;
 MPR_Params.CrossingTime := MPR.CrossingTime div J;
 MPR_Params.CrossingHoldDirTime := MPR.CrossingHoldDirectionTime div J;
 MPR_Params.BlinkSignalTime := MPR.BlinkSignalTime div J;
 If MPR.NotManRouteToDAB then
   MPR_Params.NotManRouteToDAB := TRUE
 else
   MPR_Params.NotManRouteToDAB := FALSE;

 MPR_Params.TrainControl := MPR.TrainControl;(*Признак управления поездами в ТОС секций*)
 //Параметры, несовместимые с версией 2/4
 MPR_Params.HeatBoxes := Length(MPR.HeatBoxes);(*Количество шкафов обогрева*);
 MPR_Params.HeatDelay := MPR.HeatDelay div J;(*Задержка контроля включения обогрева*);
 MPR_Params.HighHeatBoxes := Length(MPR.HeatBoxes) - 1;(*Размер массива шкафов обогрева*)
 MPR_Params.AddSignalDelay := MPR.AddSignalDelay div J;(*время фиксации неисправности*)
 MPR_Params.LockDelayLGOK := MPR.LockDelayLGOK div J;(*задержка на прохождение сигналов ЛГОКа*)
 MPR_Params.ResetSectionDelay := MPR.ResetSectionDelay div J;(*Длина импульса сброса занятости секции*)

 MPR_Params.SPP_LinkType := MPR.SPP_LinkType;(*тип канала связи с СПП*)
 MPR_Params.PointsResultNoWait := MPR.PointsResultNoWait;(*0 - ручной перевод стрелок с ожиданием исполнения, 1 - с выдачей команды без ожидания исполнения.*)
 MPR_Params.PointsDefendMode := MPR.PointsDefendMode;(*Режим защиты привода стрелки*)

  (* *** См. Параметры программы ПЛС*)
 (*Верхний индекс массива доп. сигналов*)
 MPR_Params.HighAddSignals := High(MPR.RW_Add_Signals);
 (*Верхний индекс массива простых маршрутов*)
 MPR_Params.HighRWRoutes := High(SimpleRWRoutes);

 (*Верхний индекс массива составных маршрутов*)
 MPR_Params.HighRWComplexRoutes := High(ComplexRWRoutes);

 (*Верхний индекс массива ограждений*)
 MPR_Params.HighRWFences := High(MPR.RWFences);

 (*Верхний индекс массива секций*)
 MPR_Params.HighRWSections := High(MPR.RWSections);
 (*Верхний индекс массива стрелок*)
 MPR_Params.HighRWPoints := High(MPR.RWThePoints);
 (*Верхний индекс массива Главных стрелок*)
 MPR_Params.HighRWMainPoints := High(MPR.RWTheMainPoints);
 (*Верхний индекс массива светофоров*)
 MPR_Params.HighRWSignals := High(MPR.RWSignals);
 (*Верхний индекс массива переездов*)
 MPR_Params.HighRWCrossings := High(MPR.RWCrossings);
 (*Верхний индекс массива переездных линий*)
 MPR_Params.HighRWCrossLines := High(MPR.RWCrossLines);
 (*Верхний индекс массива въездных сигналов*)
 MPR_Params.HighRW_V_Signals := High(MPR.RW_V_Signals);
 (*Верхний индекс массива ПАБ*)
 MPR_Params.HighRWSA := High(MPR.RWSA);
 (*Верхний индекс массива лунных сигналов*)
 MPR_Params.HighRWML := High(MPR.RWML);
 (*Верхний индекс массива предохранителей на стативах*)
 MPR_Params.HighStativFuses := High(MPR.StativFuses);
 (*Верхний индекс массива МНЗ простых маршрутов*)
 //MPR_Params.HighRWRouteMNZ := MPR.HighRWRouteMNZ - 1;
 (*Верхний индекс массива ПЗ простых маршрутов*)
 //MPR_Params.HighRWRoutePZ := HighRWRoutePZ - 1;
 MPR_Params.HighRWConnections := RTEConnections.Count - 1;
 (*Верхний индекс массива СЭС*)
 if MPR.SingleSysES  then
  MPR_Params.HighSESArray := 0
 else
  MPR_Params.HighSESArray := High(MPR.SysES);

 (*Верхний индекс массива ДАБ*)
 MPR_Params.HighDABArray := High(MPR.RWCD);
 (*Верхний индекс массива ж/д элементов*)
 MPR_Params.HighRWElements := High(MPR.RWs);
 (*время в секундах ожидания восстановления пломбы контроллера стрелки*)
 MPR_Params.PcAvWaitTime := 210;
 (*время в секундах задержки для выравнивания мигания ж/д элементов*)
 MPR_Params.BEDelay := 10;
 (*Верхний индекс массива вариантных кнопок*)
 MPR_Params.HighRWVariants := High(MPR.RWVariants);
 (*Верхний индекс массива участков приближения*)
 MPR_Params.HighRWCrossPP := High(MPR.RWCrossPPs);
 (*Верхний индекс массива соединений*)
 MPR_Params.HighRWConnections := High(MPR.RWConnections);
(*Верхний индекс массива PFBSlaves*)
 MPR_Params.HighPFBSlaves := 126;
 (*Верхний индекс массива MPR_SingleHorns*)
 MPR_Params.HighSingleHorns := HighSingleHornsVALUE;
 SetLength(MPR_SingleHorns.List, HighSingleHornsVALUE + 1);
 (*Период мигания лунного*)
 MPR_Params.BlinkMLSignalTime := 10;
 (*Интервал непрерывной работы включенного пригласительного сигнала*)
 MPR_Params.MoonOnInterval := MPR.MoonOnInterval div J;
 (*Параметры ДАБ*)
 MPR_Params.DABHoldTime := 20;
 MPR_Params.DABMaxExecTime := 40;
 MPR_Params.KPRepeatTime := 70;
 (* *** Параметры станции,режимов и безопасности работы МПР*)
 MPR_Params.SPPON := TRUE;
 (*тип СПП*)
 try
  MPR_Params.SPPType := StrToInt(MPR.SPPType);
 except
  MPR_Params.SPPType := 0;
 end;
 MPR_Params.AllowFormatMessage := MPR.AllowFormatMessage;
 MPR_Params.HighPFBSlaves := RTESlaves.Count - 1;
 MPR_Params.LastScanTime := MPR.ScanInterval;
end;

procedure TMSURTECore.rInit;
begin
  SectionInitialization(MPR);
end;

(*procedure TMSURTECore.rInit;
var
  i,j,ppIdx : Integer;
  RTESection : TRTESection;
  RTECrossPP : TRTECrossPP;
begin
  //установление размерности массивов
  SetLength(MPR_RWSections.List, MPR_Params.HighRWSections + 1);
  SetLength(MPR_RWSections_F.List, MPR_Params.HighRWSections + 1);
  SetLength(RWSections_RLZ.List, MPR_Params.HighRWSections + 1);
  SetLength(MPR_RWSections_GSFree.List ,MPR_Params.HighRWSections + 1);
  //заполнение  элементов структуры секции
  for i := 0 to MPR_Params.HighRWSections DO
  begin
    MPR_RWSections.List[i].SAIndex := -1;
    MPR_RWSections.List[i]._RI := -1;
    MPR_RWSections_GSFree.List[i].SPPType := MPR.RWSections[i].SPPType;
    IF (MPR_RWSections_GSFree.List[i].SPPType = -1) THEN
    begin
      MPR_RWSections_GSFree.List[i].GS_DelayTime := MPR_Params.GSDelay;
    end;
    MPR_RWSections.List[i].SectionType := MPR.RWSections[i].SectionType;
    Case MPR.RWSections[i].LockSignalLink Of
    1:
     begin
      MPR_RWSections.List[i].SignalLink := TRUE;
     end;//1
    2:
     begin
      MPR_RWSections.List[i].LockAsLGOK := TRUE;
     end;
    end;// case LockSignalLink
    If (MPR.RWSections[i].SPPType <> -1) or (MPR.RWSections[i].SPPType <> MPR.ISPPType) then
    begin
       MPR_RWSections_GSFree.List[i].GS_DelayTime := MPR.RWSections[i].GS_DelayTime div MPR.ScanInterval;
    end;
    {If MPR.RWSections[i].Master <> 0 then
      MPR_RWSections.List[i].Master := FALSE;}
    MPR_RWSections.List[i].HasControl := (MPR.RWSections[i].WithoutControl = '0');
    MPR_RWSections.List[i].StubTrackLock := (MPR.RWSections[I].NoControl = '1');
    MPR_RWSections.List[i].RouteAllow := (MPR.RWSections[I].RouteAllow = '0');
    try
      MPR_RWSections.List[i].AutoLock := StrToInt(MPR.RWSections[i].AutoLock);
    except
      MPR_RWSections.List[i].AutoLock := 0;
    end;
    MPR_RWSections.List[i].CheckByWay := (MPR.RWSections[I].CheckByWay > 0);
    MPR_RWSections.List[i].CheckAddRoute := MPR.RWSections[i].CheckAddRoute;
    MPR_RWSections.List[i].V_SignalIndex := MPR.RWSections[I].VSIndex;
    If MPR_RWSections.List[i].AutoLock = 3 then
    begin
     MPR_RWSections.List[i].SAIndex := MPR.RWSections[I].SAIndex;
    end;
    If MPR_RWSections.List[i].AutoLock = 2 then
     begin
      MPR_RWSections.List[i].SAIndex := MPR.RWSections[I].CDIndex;
      If (MPR.RWSections[i].DAB_Auto > 0) then
      begin
        MPR_RWSections_F.List[i].DAB_Auto := TRUE;
      end;
     end;
     RTESection := TRTESection(RTESections.Objects[i]);
     if RTESection.CrossPP.Count > 0 then
     begin
      RWSections_RLZ.List[i].HighPPArray := RTESection.CrossPP.Count;
      RTESection.CrossPP.Sort;//имена - ординальные номера
      for j := 0 to RTESection.CrossPP.Count - 1 do
      begin
        RTECrossPP := TRTECrossPP(RTESection.CrossPP.Objects[j]);
        ppIdx := RTECrossPPs.IndexOf(RTECrossPP.Name);
        RWSections_RLZ.List[i].PP[(J + 1)]:= ppIdx;
      end;
    end;
    //UAB
    MPR_RWSections_F.List[i].UABType := MPR.RWSections[I].AB_Type;
    MPR_RWSections_F.List[i].Q1SVHSgn := -1;
    if Length(MPR.RWSignals) > 0 then
    begin
      for j := 0 to High(MPR.RWSignals) do
      begin
        if MPR.RWSignals[j].SignalType = 2 then
        begin
          if MPR.RWSignals[j].SectionCode = RTESection.Name then
          begin
            if MPR.RWSignals[j].SVH_OUT = '1' then
            begin
              MPR_RWSections_F.List[i].Q1SVHSgn := j;
              break;
            end;
          end;
        end;
      end;//for j
    end;
  end;//for i
end;    *)

procedure TMSURTECore.rRead;
var
  i : Integer;
  ThisRTESection : TRTESection;
begin
  for i := 0 to MPR_Params.HighRWSections DO
  begin
    ThisRTESection := TRTESection(RTESections.Objects[i]);
    if MPR.LZEnabled then
    begin
      if MPR_Params.SPPType = 0  then
      begin
        if Assigned(ResetLZStage1Delay) then
          RWSections_RLZ.List[i].Stage1Delay := ResetLZStage1Delay.Value;
        if Assigned(ResetLZStage2Delay) then
          RWSections_RLZ.List[i].Stage2Delay := ResetLZStage2Delay.Value;
        if Assigned(ResetLZStage3Delay) then
          RWSections_RLZ.List[i].Stage3Delay := ResetLZStage3Delay.Value;
      end;
    end;//if MPR.LZEnabled
    if Assigned(ThisRTESection._SV) then
      MPR_RWSections.List[i]._SV := ThisRTESection._SV.Value;
    if ThisRTESection.isSlave  then
    begin
      gv.rRS_I1 := FALSE;
      if Assigned(ThisRTESection.Connection) then
      begin
        case ThisRTESection.SPPType  of
          4:
          begin
             if ThisRTESection.Connection.arrIndex > -1 then
             begin
                if MPR_RWConnections.List[ThisRTESection.Connection.arrIndex].FieldBusConnected = 1 then
                begin
                  if Assigned(ThisRTESection._L1) then
                    gv.rRS_I1 := ThisRTESection._L1.Value;
                end;
             end;
          end //4
          else
          begin
            If Assigned(ThisRTESection.Connection._SL) then
            begin
              if ThisRTESection.Connection._SL.Value = 1 then
                if Assigned(ThisRTESection._L1) then
                  gv.rRS_I1 := ThisRTESection._L1.Value;
            end;
          end;//else
        end;//case
      end;
    end
    else
    begin
    if Assigned(ThisRTESection._L1) then
      gv.rRS_I1 := ThisRTESection._L1.Value;
    if MPR.LZEnabled then
    begin
      if Assigned(ThisRTESection._RLZ) then
        RWSections_RLZ.List[i].RLZ := ThisRTESection._RLZ.Value;
      end;
    end;
    gv.rRS_I2 := i;
    rRS;
    //UAB
    case ThisRTESection.UABType of
      1:
        begin
          if Assigned(ThisRTESection._AB_1IO_R) then
            MPR_RWSections_F.List[i]._AB_1IO_R := ThisRTESection._AB_1IO_R.Value;
        end;
    end;
    //LockSignalLink
    case ThisRTESection.LockSignalLink of
      1,3:
      begin
        if Assigned(ThisRTESection._SV_IN) then
        begin
          MPR_RWSections.List[i]._SV_IN := ThisRTESection._SV_IN.Value;
        end;
      end;//1
    end; //case LockSignalLink
  end;//for i
end;

procedure TMSURTECore.rDO;
var
  i : Integer;
  RTESection : TRTESection;
begin
  if RTESections.Count = 0 then Exit;
  for i := 0 to RTESections.Count - 1 do
  begin
    RTESection := TRTESection(RTESections.Objects[i]);
    gv.rRLZ_I := I;
    case RTESection.CrossPP.Count of
      0: //у секции нет участков приближения
      begin
        case MPR_Params.SPPType  of
          1:
          begin
            rRLZ1();   (*Фраушер*)
          end;//1
          else
          begin
            rRLZ0; (*ЭССО*)
          end;//else
        end;//case
      end; //0
      1:
      begin
        rRLZPP1;
      end;//1
      else
      begin
        rRLZPPN;
      end;
    end;//case
    //UAB
    if RTESection.UABType > 0 then
     begin
       gv.rUAB_I := I;
       rUAB;
     end;
  end;
end;

procedure TMSURTECore.rWrite;
var
  i : Integer;
  ThisRTESection : TRTESection;
  tagR_Value : String;
  tagSV_Value : Integer;
begin
  for i := 0 to MPR_Params.HighRWSections DO
  begin
    ThisRTESection := TRTESection(RTESections.Objects[i]);
    if Assigned(ThisRTESection._GS) then
    begin
      ThisRTESection._GS.Value := MPR_RWSections.List[i]._GS;
    end;
    if MPR.LZEnabled then
    begin
      if Assigned(ThisRTESection._OUT) then
      begin
        ThisRTESection._OUT.Value := RWSections_RLZ.List[I]._OUT;
      end;
      if Assigned(ThisRTESection._Result) then
      begin
        ThisRTESection._Result.Value := RWSections_RLZ.List[I].Result;
      end;
    end;
    //UAB
    case ThisRTESection.UABType of
      1:
        begin
          if Assigned(ThisRTESection._AB_1IO_OUT) then
            ThisRTESection._AB_1IO_OUT.Value := MPR_RWSections_F.List[i]._AB_1IO_OUT;
        end;
      2:
        begin
          if Assigned(ThisRTESection._AB_1SVH_OUT) then
            ThisRTESection._AB_1SVH_OUT.Value := MPR_RWSections_F.List[i]._AB_1SVH_OUT;
        end;
    end;//case
    case ThisRTESection.LockSignalLink  of
      1,4:
      begin
        if Assigned(ThisRTESection._R) then
        begin
          tagR_Value := ThisRTESection._R.Value;
          tagSV_Value := 0;
          if Assigned(ThisRTESection._SV) then
          begin
            tagSV_Value := ThisRTESection._SV.Value;
          end;
          If (not tagR_Value.Equals(string.Empty)) AND (tagSV_Value = 1) Then
          begin
            if Assigned(ThisRTESection._SV_OUT) then
              ThisRTESection._SV_OUT.Value := true;
          end
          else
          begin
            if Assigned(ThisRTESection._SV_OUT) then
              ThisRTESection._SV_OUT.Value := false;
          end;
          end;
        end;
    end;//case
  end;//for i
end;

Constructor TRTEMainPoint.Create;
var
  NewTag : TRTETag;
  pntIdx : Integer;
  NetStationCode : String;
  i : Integer;
begin
  inherited Create(AMPRCore);
  _L1 := nil;
  _L2 := nil;
  _OUT_P := nil;
  _OUT_M := nil;
  _OUT_BLOCK := nil;
  _OUT_B := nil;
  A_P := nil;
  _Command := nil;
  _Result := nil;
  GeneralTag := nil;
  _DeviceState := nil;
  _Command_Fence := nil;
  _Result_Fence := nil;
  _RL := nil;
  _MSSZ := nil;
  _BSTP := nil;
  _OUT_K := nil;
  RTEPoint := nil;
  netMainTag := nil;
  NetPoint := false;
  RWTheMainPoint := APnt;
  Name := RWTheMainPoint.Code;
  FCaption := RWTheMainPoint.Caption;
  CodingName := Name.Replace(MPRCore.MPR.StationCode + '_', '');
  STPWhereInvolve := TStringList.Create(false);
  if Length(MPRCore.MPR.RWFences) > 0 then
  begin
    SetLength(FBLK, Length(MPRCore.MPR.RWFences));
    for i := 0 to High(FBLK) do
    begin
      FBLK[i] := nil;
    end;
  end;
  if Assigned(MPRCore) then
  begin
    if MPRCore.RTEPoints.Count > 0 then
    begin
      pntIdx := MPRCore.RTEPoints.IndexOf(Name);
      if pntIdx > -1 then
      begin
        RTEPoint := TRTEPoint(MPRCore.RTEPoints.Objects[pntIdx]);
        if Assigned(RTEPoint) then
        begin
          RTEPoint.MainPoint := Self;
          if Assigned(RTEPoint.PointByBranch) then
            RTEPoint.PointByBranch.MainPoint := Self;
        end;
      end;
    end;//if MPRCore.RTEPoints.Count > 0
  end; //if Assigned(MPRCore)
  NewTag := TRTETag.Create('A_P' + Name + '_K', Self, VT_BOOL, FALSE);
  NewTag.TagServerTagEntry.Memory := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  NewTag := TRTETag.Create('P' + Name + '_OUT_B', Self, VT_BOOL, FALSE);
  _OUT_B := NewTag;
  NewTag.PLCTagEntry.Memory := true;
  NewTag.TagServerTagEntry.IOReadOnly := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  NewTag := TRTETag.Create('A_P' + Name, Self, VT_BOOL, FALSE);
  A_P := NewTag;
  NewTag.PLCTagEntry.Memory := true;
  NewTag.TagServerTagEntry.IOReadwrite := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  NewTag := TRTETag.Create('P' + Name + '_D', Self, VT_I2, 0);
  NewTag.TagServerTagEntry.Memory := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  NewTag := TRTETag.Create('P' + Name + '_Timer', Self, VT_I2, 0);
  NewTag.TagServerTagEntry.Memory := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  NewTag := TRTETag.Create('P' + Name + '_Command', Self, VT_I2, 0);
  _Command := NewTag;
  NewTag.TagServerTagEntry.Memory := true;
  NewTag.PLCTagEntry.IOReadOnly := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  NewTag := TRTETag.Create('P' + Name + '_OUT_K', Self, VT_I2, 0);
  _OUT_K := NewTag;
  NewTag.PLCTagEntry.IOReadOnly := true;
  NewTag.TagServerTagEntry.Memory := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  if MPRCore.MPR.LockTrapPoints = 1 then
  begin
      NewTag := TRTETag.Create('P' + Name + '_RL', Self, VT_I2, 0);
      _RL := NewTag;
      NewTag.PLCTagEntry.IOReadOnly := true;
      NewTag.TagServerTagEntry.Memory := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  end;
  if MPRCore.MPR.AllowMSSZ = 1 then
  begin
      NewTag := TRTETag.Create('P' + Name + '_MSSZ', Self, VT_I2, 0);
      _MSSZ := NewTag;
      NewTag.PLCTagEntry.IOReadOnly := true;
      NewTag.TagServerTagEntry.Memory := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  end;
  NewTag := TRTETag.Create('P' + Name + '_DeviceState', Self, VT_I2, 0);
  _DeviceState := NewTag;
  NewTag.PLCTagEntry.Memory := true;
  NewTag.TagServerTagEntry.IOReadOnly := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  NewTag := TRTETag.Create('P' + Name, Self, VT_I2, 0);
  GeneralTag := NewTag;
  NewTag.PLCTagEntry.Memory := true;
  NewTag.TagServerTagEntry.IOReadOnly := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  NewTag := TRTETag.Create('P' + Name + '_Result', Self, VT_I2, 0);
  _Result := NewTag;
  NewTag.PLCTagEntry.Memory := true;
  NewTag.TagServerTagEntry.IOReadOnly := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  NewTag := TRTETag.Create('P' + Name + '_S', Self, VT_BSTR, '');
  NewTag.TagServerTagEntry.Memory := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  NewTag := TRTETag.Create('P' + Name + '_W', Self, VT_BSTR, '');
  NewTag.TagServerTagEntry.Memory := true;
  NewTag.IsOPCTag := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  //входные/выходные сигналы
  if Assigned(RTEPoint) then
  begin
    NetStationCode := RTEPoint.RWThePoint.StationCode.Trim()
  end
  else
  begin
    NetStationCode := '0';
  end;
  //контроль стрелки с соседней станции
  if (not NetStationCode.Equals(string.Empty)) AND (not NetStationCode.Equals('0')) then
  begin
      if RTEPoint.RWThePoint.Field_15 = 1 then
      begin
        NetPoint := true;
        //контроль 'плюс'
        NewTag := TRTETag.Create('P' + Name + '_L1', Self, VT_BOOL, FALSE);
        _L1 := NewTag;
        NewTag.PLCTagEntry.Phisical := true;
        NewTag.IsOPCTag := true;
        MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
        MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
        //контроль минус'
        NewTag := TRTETag.Create('P' + Name + '_L2', Self, VT_BOOL, FALSE);
        _L2 := NewTag;
        NewTag.PLCTagEntry.Phisical := true;
        NewTag.IsOPCTag := true;
        MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
        MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
        if Assigned(RTEPoint.Connection)  then
          RTEPoint.Connection.OnFieldBus := true;
      end
      else
      begin
        NetPoint := true;
        NewTag := TRTETag.Create('P' + NetStationCode + '_' + CodingName, Self, VT_I2, 0);
        netMainTag := NewTag;
        NewTag.PLCTagEntry.IOReadOnly := true;
        NewTag.PLCTagEntry.ServerAlias := 'Station' + NetStationCode;
        NewTag.IsOPCTag := true;
        MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
        if MPRCore.MSURTESettings.IsEmulation  then
          MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
      end;
  end
  else
  begin
      //блокировка
      NewTag := TRTETag.Create('P' + Name + '_OUT_BLOCK', Self, VT_BOOL, FALSE);
      _OUT_BLOCK := NewTag;
      NewTag.PLCTagEntry.Phisical := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
      MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
      //команда 'на плюс'
      NewTag := TRTETag.Create('P' + Name + '_OUT_P', Self, VT_BOOL, FALSE);
      _OUT_P := NewTag;
      NewTag.PLCTagEntry.Phisical := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
      MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
      //команда 'на минус'
      NewTag := TRTETag.Create('P' + Name + '_OUT_M', Self, VT_BOOL, FALSE);
      _OUT_M := NewTag;
      NewTag.PLCTagEntry.Phisical := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
      MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
      //контроль 'плюс'
      NewTag := TRTETag.Create('P' + Name + '_L1', Self, VT_BOOL, FALSE);
      _L1 := NewTag;
      NewTag.PLCTagEntry.Phisical := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
      MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
      //контроль минус'
      NewTag := TRTETag.Create('P' + Name + '_L2', Self, VT_BOOL, FALSE);
      _L2 := NewTag;
      NewTag.PLCTagEntry.Phisical := true;
      NewTag.IsOPCTag := true;
      MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
      MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
  end;
end;

function TRTEMainPoint.PostProcessing;
var
  NewTag : TRTETag;
begin
  //СТП
  if MPRCore.MPR.AllowSTP then
  begin
      if (STPWhereInvolve.Count > 0) then
      begin
          NewTag := TRTETag.Create('P' + Name + '_BSTP', Self, VT_BOOL, FALSE);
          _BSTP := NewTag;
          NewTag.TagServerTagEntry.Memory := true;
          NewTag.PLCTagEntry.IOReadOnly := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name,NewTag);
      end;
  end;
  Result := true;
end;

Destructor TRTEMainPoint.Destroy;
begin
  if Assigned(STPWhereInvolve) then
  begin
    STPWhereInvolve.Free;
    STPWhereInvolve := nil;
  end;
  inherited;
end;

procedure TMSURTECore.pInit;
var
  i,J : Integer;
  RTEMainPoint : TRTEMainPoint;
begin
  if PointInitialization(MPR) then
  begin
    if Length(MPR.RWTheMainPoints) > 0 then
    begin
      for i:=0 to High(MPR.RWTheMainPoints) do
      begin
        RTEMainPoint := TRTEMainPoint(RTEMainPoints.Objects[i]);
        if Assigned(RTEMainPoint.RTEPoint) then
          if Assigned(RTEMainPoint.RTEPoint.Connection)  then
          begin
            J := RTEConnections.IndexOf(RTEMainPoint.RTEPoint.Connection.Name);
            MPR_RWMainPoints.List[i].ConnIdx := J;
          end;
      end;//for i
    end;//if Length(MPR.RWTheMainPoints) > 0
  end; //if PointInitialization(MPR) then
end;

procedure TMSURTECore.pRead;
var
  i : Integer;
  ThisRTEMainPoint : TRTEMainPoint;
begin
  for i := 0 to MPR_Params.HighRWMainPoints DO
  begin
    ThisRTEMainPoint := TRTEMainPoint(RTEMainPoints.Objects[i]);
    if ThisRTEMainPoint.NetPoint then
    begin
      if ThisRTEMainPoint.RTEPoint.RWThePoint.Field_15 = 1 then
      begin
        if Assigned(ThisRTEMainPoint._L1) then
          MPR_RWMainPoints.List[i]._L1 := ThisRTEMainPoint._L1.Value;
        if Assigned(ThisRTEMainPoint._L2) then
          MPR_RWMainPoints.List[i]._L2 := ThisRTEMainPoint._L2.Value;
      end
      else
      begin
        if Assigned(ThisRTEMainPoint.netMainTag) then
          MPR_RWMainPoints.List[i].netMainTag := ThisRTEMainPoint.netMainTag.Value;
      end;
    end
    else
    begin
      if Assigned(ThisRTEMainPoint._L1) then
        MPR_RWMainPoints.List[i]._L1 := ThisRTEMainPoint._L1.Value;
      if Assigned(ThisRTEMainPoint._L2) then
        MPR_RWMainPoints.List[i]._L2 := ThisRTEMainPoint._L2.Value;
      if Assigned(ThisRTEMainPoint.A_P) then
        MPR_RWMainPoints.List[I]._A := ThisRTEMainPoint.A_P.Value;
      if Assigned(ThisRTEMainPoint._OUT_K) then
        MPR_RWMainPoints.List[I]._OUT_K := ThisRTEMainPoint._OUT_K.Value;
      if Assigned(ThisRTEMainPoint._Command) then
        MPR_RWMainPoints.List[I]._Command := ThisRTEMainPoint._Command.Value;
      if Assigned(ThisRTEMainPoint._Result_Fence) then
        MPR_RWMainPoints.List[i]._Result_Fence := ThisRTEMainPoint._Result_Fence.Value;
      if Assigned(ThisRTEMainPoint._RL) then
        MPR_RWMainPoints.List[i]._RL := ThisRTEMainPoint._RL.Value;
      if Assigned(ThisRTEMainPoint._MSSZ) then
        MPR_RWMainPoints.List[i]._MSSZ := ThisRTEMainPoint._MSSZ.Value;
      if Assigned(ThisRTEMainPoint._BSTP) then
        MPR_RWMainPoints.List[i]._BSTP := ThisRTEMainPoint._BSTP.Value;
    end;
  end;
end;

procedure TMSURTECore.pDo;
var
  i : Integer;
begin
  if Length(MPR.RWTheMainPoints) > 0 then
    for i := 0 to High(MPR.RWTheMainPoints) do
    begin
      gv.pCon_I := i;
      CASE MPR_RWMainPoints.List[i].ReadOnlyMode OF
        0:
        begin
          pCon;
        end;//0
        1:
        begin
          pCon1;
        end;//1
      END;//case
    end;
end;

procedure TMSURTECore.pWrite;
var
  i,j : Integer;
  ThisRTEMainPoint : TRTEMainPoint;
begin
  for i :=0 to High(MPR.RWTheMainPoints) do
  begin
    gv.pDS_I := i;
    pDS;
    ThisRTEMainPoint := TRTEMainPoint(RTEMainPoints.Objects[i]);
    if Assigned(ThisRTEMainPoint.GeneralTag) then
      ThisRTEMainPoint.GeneralTag.Value := MPR_RWMainPoints.List[i].MainTag;
    if Assigned(ThisRTEMainPoint._DeviceState) then
      ThisRTEMainPoint._DeviceState.Value := MPR_RWMainPoints.List[i]._DeviceState;
    if Assigned(ThisRTEMainPoint._OUT_B) then
      ThisRTEMainPoint._OUT_B.Value := MPR_RWMainPoints.List[I]._OUT_B;
    if Assigned(ThisRTEMainPoint._OUT_M) then
      ThisRTEMainPoint._OUT_M.Value := MPR_RWMainPoints.List[i]._OUT_M;
    if Assigned(ThisRTEMainPoint._OUT_P) then
      ThisRTEMainPoint._OUT_P.Value := MPR_RWMainPoints.List[i]._OUT_P;
    if Assigned(ThisRTEMainPoint._OUT_BLOCK) then
      ThisRTEMainPoint._OUT_BLOCK.Value := MPR_RWMainPoints.List[i]._OUT_BLOCK;
    if Assigned(ThisRTEMainPoint._Result) then
    begin
      ThisRTEMainPoint._Result.Value := MPR_RWMainPoints.List[i]._Result
    end;
    if Assigned(ThisRTEMainPoint._Command_Fence) then
      ThisRTEMainPoint._Command_Fence.Value := MPR_RWMainPoints.List[i]._Command_Fence;
    if Length(ThisRTEMainPoint.FBLK) > 0 then
    begin
      for j := 0 to High(ThisRTEMainPoint.FBLK) do
      begin
        if Assigned(ThisRTEMainPoint.FBLK[j]) then
        begin
          ThisRTEMainPoint.FBLK[j].Value := MPR_RWMainPoints.List[i].FBLK[j];
        end;
      end;//for j
    end;
  end;
end;

procedure TMSURTECore.sesInit;
begin
  SESInitialization(MPR);
end;

{procedure TMSURTECore.sesInit;
var
  i : Integer;
  dStartValue : double;
  iStartValue : Integer;
  MAXSESPntDELAY : Integer;
begin
  if Length(MPR.StativFuses) > 0 then
    SetLength(MPR_StativFuses.List,Length(MPR.StativFuses));
  if MPR.SingleSysES  then
  begin
    SetLength(MPR_RWSESArray.List, 1);
    SetLength(MPR_RWSESArray.List[0].RMBResults, MPR_Params.HighRWMainPoints + 1);
    SetLength(MPR_RWSESArray.List[0].PointsInProcess, MPR_Params.HighRWMainPoints + 1);
    SetLength(MPR_RWSESArray.List[0].RMBQueries, MPR_Params.HighRWMainPoints + 1);
    MPR_RWSESArray.List[0].MaxNumberOfProcessPoints := MPR.PointsExecuteCount;
    MPR_RWSESArray.List[0].NumberOfProcessPoints := 0;
    dStartValue := ((MPR.AmpermeterMax  - MPR.AmpermeterMin) / MPR.PointsAmpermeterScaleCount) * 0.2;
    iStartValue := Round(dStartValue);
    MPR_RWSESArray.List[0].StartValue := iStartValue;
    MPR_RWSESArray.List[0].PointsRMBTime := 70;
    MPR_RWSESArray.List[0].RMBResetTime := MPR.RMBResetTime div MPR.ScanInterval;
    MPR_RWSESArray.List[0].TimeCounter := 1;
    if Assigned(RMBDeadBandTime) then
      MPR_RWSESArray.List[0].RMBDeadBandTime := RMBDeadBandTime.Value
    else
      MPR_RWSESArray.List[0].RMBDeadBandTime := RMBDeadBandTime_DEF;
    MPR_RWSESArray.List[0].rRMB_Time := 1;
    MPR_RWSESArray.List[0].AVRAlarmDT := 10;
    MPR_RWSESArray.List[0].AVRAlarmCT := 1;
    try
      MAXSESPntDELAY := MPR.PointsExecuteCount * (MPR.PointsMaxExecTime div MPR.ScanInterval);
    except
      MAXSESPntDELAY := 150;
    end;
    MPR_RWSESArray.List[0].MAXSESPntDELAY := MAXSESPntDELAY;
    MPR_RWSESArray.List[0].scaleCount :=MPR.PointsAmpermeterScaleCount;
    MPR_RWSESArray.List[0].rawMIN := MPR.AmpermeterMin;
    MPR_RWSESArray.List[0].rawMAX := MPR.AmpermeterMax;
  end
  else
  begin
    SetLength(MPR_RWSESArray.List, MPR_Params.HighSESArray + 1);
    for i := 0 to MPR_Params.HighSESArray do
    begin
      SetLength(MPR_RWSESArray.List[i].RMBResults, MPR_Params.HighRWMainPoints + 1);
      SetLength(MPR_RWSESArray.List[i].PointsInProcess, MPR_Params.HighRWMainPoints + 1);
      SetLength(MPR_RWSESArray.List[i].RMBQueries, MPR_Params.HighRWMainPoints + 1);
      MPR_RWSESArray.List[i].MaxNumberOfProcessPoints := MPR.PointsExecuteCount;
      MPR_RWSESArray.List[i].NumberOfProcessPoints := 0;
      dStartValue := ((MPR.SysES[i].Ampermeter_Max - MPR.SysES[i].Ampermeter_Min) / MPR.SysES[i].Ampermeter_Scale) * 0.2;
      iStartValue := Round(dStartValue);
      MPR_RWSESArray.List[i].StartValue := iStartValue;
      MPR_RWSESArray.List[i].PointsRMBTime := 70;
      MPR_RWSESArray.List[i].RMBResetTime := MPR.RMBResetTime div MPR.ScanInterval;
      MPR_RWSESArray.List[i].TimeCounter := 1;
      if Assigned(RMBDeadBandTime) then
        MPR_RWSESArray.List[i].RMBDeadBandTime := RMBDeadBandTime.Value
      else
        MPR_RWSESArray.List[i].RMBDeadBandTime := RMBDeadBandTime_DEF;
      MPR_RWSESArray.List[i].rRMB_Time := 1;
      MPR_RWSESArray.List[i].AVRAlarmDT := 10;
      MPR_RWSESArray.List[i].AVRAlarmCT := 1;
      try
        MAXSESPntDELAY := MPR.SysES[i].PointsExecuteCount * (MPR.PointsMaxExecTime div MPR.ScanInterval);
      except
        MAXSESPntDELAY := 150;
      end;
      MPR_RWSESArray.List[i].MAXSESPntDELAY := MAXSESPntDELAY;
      MPR_RWSESArray.List[i].scaleCount := MPR.SysES[i].Ampermeter_Scale;
      MPR_RWSESArray.List[i].rawMIN := MPR.SysES[i].Ampermeter_Min;
      MPR_RWSESArray.List[i].rawMAX := MPR.SysES[i].Ampermeter_Max;
    end;//for i
  end;
end;}

procedure TMSURTECore.sInit;
begin
  SignalInitialization(MPR);
end;
{procedure TMSURTECore.sInit;
var
  i, H, J, K, C1, A : Integer;
  FindNode, OtherNode, SignalNode : string;
  OtherNodeIdx, ChiefSignalIdx : Integer;
  lHighPoints, lHighCrossings : Integer;
  RTESection : TRTESection;
  RTEPoint : TRTEPoint;
begin
  if Length(MPR.RWSignals) > 0 then
  begin
    SetLength(MPR_RWSignals.List, MPR_Params.HighRWSignals + 1);
    for i :=0 to High(MPR.RWSignals) do
    begin
      MPR_RWSignals.List[i].SignalType := MPR.RWSignals[I].SignalType;
      MPR_RWSignals.List[i].SignalSubType := MPR.RWSignals[i].SignalSubType;
      MPR_RWSignals.List[i].SectionIndex := MPR.RWSignals[i].SectionIndex;
      MPR_RWSignals.List[i].Direction := (MPR.RWSignals[I].Direction = 1);

      CASE MPR.RWSignals[i].SignalType  OF
      2: //входной
        begin
          if MPR.RWSignals[i].BeManevr THEN
            MPR_RWSignals.List[i].WhiteOnTrainSignal := TRUE
          else
            MPR_RWSignals.List[i].WhiteOnTrainSignal := FALSE;
        end; //2
      3:  //выходной
        begin
          if MPR.RWSignals[I].SignalSubType = 0 then
            MPR_RWSignals.List[i].WhiteOnTrainSignal := TRUE
          else
            MPR_RWSignals.List[i].WhiteOnTrainSignal := FALSE;
        end;//3
        6://маршрутный
          begin
            case MPR.RWSignals[I].SignalSubType of
            0,1:
              Begin
                MPR_RWSignals.List[i].WhiteOnTrainSignal := TRUE;
              End;
            else
               MPR_RWSignals.List[i].WhiteOnTrainSignal := FALSE;
            end;
          end;//6
        7:
          begin
            MPR_RWSignals.List[i].PassDir := FALSE;
            MPR_RWSignals.List[i].NoPassDir := FALSE;
            MPR_RWSignals.List[i].notVisible := (MPR.RWSignals[i].SignalVisible.Trim() = '1');
            MPR_RWSignals.List[i].ABIdx := -1;
            MPR_RWSignals.List[i].StopSctIdx := -1;
            MPR_RWSignals.List[i].ChiefSgnIdx := -1;
            MPR_RWSignals.List[i].HighPoints := -1;
            MPR_RWSignals.List[i].Connection := 0;
            MPR_RWSignals.List[i].AddSubType := MPR.RWSignals[i].PoputType; //1 - предвходной
            MPR_RWSignals.List[i].netSgn_MainTag := -1;
            MPR_RWSignals.List[i].HighCrossings := -1;
            //поиск секции перед светофором
            if Length(MPR.RWs) > 0 then
            begin
              for J := 0 to High(MPR.RWs) do
              begin
                if MPR.RWSignals[I].Direction = 1 then
                begin
                  //Если группа движения светофора нечетная, то
                  //ищем ж/д элемент, у которого данный изостык - вершина А
                  FindNode := MPR.RWs[J].Node_A.Trim();
                  OtherNode := MPR.RWs[J].Node_B.Trim();
                end
                else
                begin
                  //Если группа движения светофора четная, то
                  //ищем ж/д элемент, у которого данный изостык - вершина B
                  FindNode := MPR.RWs[J].Node_B.Trim();
                  OtherNode := MPR.RWs[J].Node_A.Trim();
                end;
                if FindNode.Equals(MPR.RWSignals[I].NodeCode) then
                begin
                  MPR_RWSignals.List[i].StopSctIdx := MPR.RWs[J].SectionIndex;
                  break;
                end;
              end;//for J
              if MPR_RWSignals.List[i].StopSctIdx = MPR_RWSignals.List[i].SectionIndex then
              begin
                //Значит светофор створный - ищем далее
                MPR_RWSignals.List[i].StopSctIdx := -1;
                SignalNode := OtherNode;
                for J := 0 to High(MPR.RWs) do
                begin
                  if MPR.RWSignals[I].Direction = 1 then
                  begin
                    //Если группа движения светофора нечетная, то
                    //ищем ж/д элемент, у которого данный изостык - вершина А
                    FindNode := MPR.RWs[J].Node_A.Trim();
                    OtherNode := MPR.RWs[J].Node_B.Trim();
                  end
                  else
                  begin
                    //Если группа движения светофора четная, то
                    //ищем ж/д элемент, у которого данный изостык - вершина B
                    FindNode := MPR.RWs[J].Node_B.Trim();
                    OtherNode := MPR.RWs[J].Node_A.Trim();
                  end;
                  if FindNode.Equals(SignalNode) then
                  begin
                    MPR_RWSignals.List[i].StopSctIdx := MPR.RWs[J].SectionIndex;
                    break;
                  end;
                end;//for J
              end;
              OtherNodeIdx := -1;
              if Length(MPR.RWNodes) > 0 then
              begin
                for J := 0 to High(MPR.RWNodes) do
                begin
                  if MPR.RWNodes[J].Code.Equals(OtherNode)  then
                  begin
                    OtherNodeIdx := J;
                    break;
                  end;
                end;//for J
              end;
              if OtherNodeIdx > -1 then
              begin
                if MPR.RWNodes[OtherNodeIdx].NodeType = 4 then
                begin
                  ChiefSignalIdx := -1;
                  for J := 0 to High(MPR.RWSignals) do
                  begin
                    if MPR.RWSignals[J].Code.Equals(MPR.RWNodes[OtherNodeIdx].SignalCode) then
                    begin
                      ChiefSignalIdx := J;
                      break;
                    end;
                  end;//for J
                  if ChiefSignalIdx > -1 then
                  begin
                    if MPR.RWSignals[ChiefSignalIdx].Direction <>  MPR.RWSignals[i].Direction  then
                    begin
                      //Значит попутный сигнал створный - ищем дальше
                      OtherNodeIdx := -1;
                      ChiefSignalIdx := -1;
                      SignalNode := OtherNode;
                      for J := 0 to High(MPR.RWs) do
                      begin
                        if MPR.RWSignals[I].Direction = 1 then
                        begin
                          //Если группа движения светофора нечетная, то
                          //ищем ж/д элемент, у которого данный изостык - вершина А
                          FindNode := MPR.RWs[J].Node_A.Trim();
                          OtherNode := MPR.RWs[J].Node_B.Trim();
                        end
                        else
                        begin
                          //Если группа движения светофора четная, то
                          //ищем ж/д элемент, у которого данный изостык - вершина B
                          FindNode := MPR.RWs[J].Node_B.Trim();
                          OtherNode := MPR.RWs[J].Node_A.Trim();
                        end;
                        if FindNode.Equals(SignalNode) then
                        begin
                          break;
                        end;
                      end;//for J
                      if Length(MPR.RWNodes) > 0 then
                      begin
                        for J := 0 to High(MPR.RWNodes) do
                        begin
                          if MPR.RWNodes[J].Code.Equals(OtherNode)  then
                          begin
                            OtherNodeIdx := J;
                            break;
                          end;
                        end;//for J
                      end; //if Length(MPR.RWNodes) > 0
                      if OtherNodeIdx > -1 then
                      begin
                        if MPR.RWNodes[OtherNodeIdx].NodeType = 4 then
                        begin
                          ChiefSignalIdx := -1;
                          for J := 0 to High(MPR.RWSignals) do
                          begin
                            if MPR.RWSignals[J].Code.Equals(MPR.RWNodes[OtherNodeIdx].SignalCode) then
                            begin
                              ChiefSignalIdx := J;
                              break;
                            end;
                          end;//for J
                        end
                        else
                        begin
                          //значит перед светофором стрелочная секция
                          //ищем светофор с секцией стоянки, равной  StopSect
                           for J := 0 to High(MPR.RWSignals) do
                           begin
                              if MPR_RWSignals.List[i].StopSctIdx = MPR.RWSignals[J].SectionIndex  then
                              begin
                                if MPR.RWSignals[i].Direction = MPR.RWSignals[J].Direction then
                                begin
                                  ChiefSignalIdx := J;
                                  break;
                                end;
                              end;
                           end;//for J
                        end;//if MPR.RWNodes[OtherNodeIdx].NodeType = 4
                      end;// if OtherNodeIdx > -1
                    end;
                  end;//if ChiefSignalIdx > -1
                end
                else
                begin
                  //значит перед светофором стрелочная секция
                  //ищем светофор с секцией стоянки, равной  StopSect
                   for J := 0 to High(MPR.RWSignals) do
                   begin
                      if MPR_RWSignals.List[i].StopSctIdx = MPR.RWSignals[J].SectionIndex  then
                      begin
                        if MPR.RWSignals[i].Direction = MPR.RWSignals[J].Direction then
                        begin
                          ChiefSignalIdx := J;
                          break;
                        end;
                      end;
                   end;//for J
                end;
              end; // if OtherNodeIdx > -1
            end;//if Length(MPR.RWs) > 0
            MPR_RWSignals.List[i].ChiefSgnIdx := ChiefSignalIdx;
            //Для случаев с ДАБ
            if MPR.RWSignals[i].SectionIndex > -1 then
            begin
              if Length(MPR.RWSections) > MPR.RWSignals[i].SectionIndex then
              begin
                if MPR.RWSections[MPR.RWSignals[i].SectionIndex].AutoLock.Trim() = '2' then
                begin
                  if Length(MPR.RWCD) > 0 then
                  begin
                    for J := 0 to High(MPR.RWCD) do
                    begin
                      if MPR.RWCD[J].Code.Trim() = MPR.RWSections[MPR.RWSignals[i].SectionIndex].CDCode.Trim() then
                      begin
                        MPR_RWSignals.List[i].ABIdx := J;
                        break;
                      end;
                    end;
                  end;//if Length(MPR.RWCD) > 0
                end;
              end; //if Length(MPR.RWSections) > 0
            end;//MPR.RWSignals[J].SectionIndex > -1
            lHighPoints := -1;
            if MPR_RWSignals.List[i].StopSctIdx > -1 then
            begin
              if RTESections.Count > MPR_RWSignals.List[i].StopSctIdx then
              begin
                RTESection := TRTESection(RTESections.Objects[MPR_RWSignals.List[i].StopSctIdx]);
                if RTESection.ContainedPoints.Count > 0 then
                begin
                  for J := 0 to RTESection.ContainedPoints.Count - 1 do
                  begin
                    RTEPoint := TRTEPoint(RTESection.ContainedPoints.Objects[J]);
                    if Assigned(RTEPoint.MainPoint) then
                    begin
                      inc(lHighPoints);
                      MPR_RWSignals.List[i].Points[lHighPoints] := RTEPoint.MainPoint.Idx;
                    end;
                  end;
                end;
              end;
            end; // if MPR_RWSignals.List[i].StopSctIdx > -1
            MPR_RWSignals.List[i].HighPoints := lHighPoints;
            //массив переездов
            lHighCrossings := -1;
            if MPR_RWSignals.List[i].StopSctIdx > -1 then
            begin
              if Length(MPR.RWCrossings) > 0 then
              begin
                for J := 0 to High(MPR.RWCrossings) do
                begin
                  if High(MPR.RWCrossings[J].SectionIndexes) > -1 then
                  begin
                    for K := 0 to High(MPR.RWCrossings[J].SectionIndexes) do
                    begin
                      if MPR.RWCrossings[J].SectionIndexes[K] = MPR_RWSignals.List[i].StopSctIdx then
                      begin
                        inc(lHighCrossings);
                        MPR_RWSignals.List[i].Crossings[lHighCrossings] := J;
                        break;
                      end;
                    end;//for k
                  end;//if High(MPR.RWCrossings[J].SectionIndexes) > -1
                end;//for J
              end;
            end;
            MPR_RWSignals.List[i].HighCrossings := lHighCrossings;
          end;//7
       END;//CASE MPR.RWSignals[i].SignalType

      MPR_RWSignals.List[i].YellowTop := (MPR.RWSignals[i].YellowTop = 0);(*нет Верхнего Желтого*)

      MPR_RWSignals.List[i].YellowBottom := (MPR.RWSignals[I].YellowBottom = 0);(*нет Нижнего Желтого*)

      MPR_RWSignals.List[i].Green := (MPR.RWSignals[I].Green = 0);(*нет Зеленого*)

      MPR_RWSignals.List[i].ML_Index := MPR.RWSignals[i].ML_Index;

      MPR_RWSignals.List[i].CrossingDelay := MPR.RWSignals[I].CrossingDelay;

      If Length(MPR.RWSignals[I].RWSignal_SZS_List) > 0 then
      begin
        H := High(MPR.RWSignals[I].RWSignal_SZS_List);
        SetLength(MPR_RWSignals.List[i].RWSignal_SZS, H + 1);
        MPR_RWSignals.List[i].HighRWSignal_SZS := H;
        for J := 0 to High(MPR.RWSignals[I].RWSignal_SZS_List) do
         begin
          H := High(MPR.RWSignals[I].RWSignal_SZS_List[J].RWSignal_SZS);
          SetLength(MPR_RWSignals.List[i].RWSignal_SZS[J].RW_SZS, H + 1);
          MPR_RWSignals.List[i].RWSignal_SZS[J].HighList := H;
          for A :=0 to High(MPR.RWSignals[I].RWSignal_SZS_List[J].RWSignal_SZS) do
          begin
            K := MPR.RWSignals[I].RWSignal_SZS_List[J].RWSignal_SZS[A].MainPointsIndex;
            C1 :=MPR.RWSignals[I].RWSignal_SZS_List[J].RWSignal_SZS[A].Value;
            MPR_RWSignals.List[i].RWSignal_SZS[J].RW_SZS[A].MainPointsIndex := K;
            MPR_RWSignals.List[i].RWSignal_SZS[J].RW_SZS[A].Value := C1;
          end;//A
         end;//J
      end;
    end;//for i
  end;//if Length(MPR.RWSignals) > 0
end;   }

procedure TMSURTECore.sRead;
var
  i,j : Integer;
  RTESignal : TRTESignal;
  RTECrossing : TRTECrossing;
  RTEDAB : TRTEDAB;
begin
if Length(MPR.RWSignals) > 0 then
  for i :=0 to High(MPR.RWSignals) do
  begin
    RTESignal := TRTESignal(RTESignals.Objects[i]);
    if Assigned(RTESignal._OPER) then
    begin
      //MPR_RWSignals.List[i]._OPER - тип Boolean
      //RTESignal._OPER - Тип Integer
      if RTESignal._OPER.Value = 1 then
        MPR_RWSignals.List[i]._OPER := TRUE
      else
        MPR_RWSignals.List[i]._OPER := FALSE;
    end;
    Case MPR.RWSignals[I].SignalType Of
      1: //маневровый
      begin
        case MPR.RWSignals[i].SignalSubType  of
          2:
          begin
            if Assigned(RTESignal._L0) then
              MPR_RWSignals.List[i]._L0 := RTESignal._L0.Value;
            if Assigned(RTESignal._F) then
              MPR_RWSignals.List[i]._F := RTESignal._F.Value;
            MPR_RWSignals.List[i]._RBC := FALSE;
            if RTESignal.ShST2Crossings.Count > 0 then
            begin
              MPR_RWSignals.List[i]._RBC := TRUE;
              for j := 0 to RTESignal.ShST2Crossings.Count - 1 do
              begin
                RTECrossing := TRTECrossing(RTESignal.ShST2Crossings.Objects[j]);
                if Assigned(RTECrossing._FENCE_L1) then
                  MPR_RWSignals.List[i]._RBC := MPR_RWSignals.List[i]._RBC AND RTECrossing._FENCE_L1.Value;
              end;//for j
              MPR_RWSignals.List[i]._RBC := not MPR_RWSignals.List[i]._RBC;
            end
            else
            begin
              MPR_RWSignals.List[i]._RBC := FALSE;
            end;//if RTESignal.ShST2Crossings.Count > 0
          end;//2
          3:
          begin
            if Assigned(RTESignal._L0) then
              MPR_RWSignals.List[i]._L0 := RTESignal._L0.Value;
          end; //3
        end;//case MPR.RWSignals[i].SignalSubType
        if Assigned(RTESignal._L1) then
          MPR_RWSignals.List[i]._L1 := RTESignal._L1.Value;
        if Assigned(RTESignal._L2) then
          MPR_RWSignals.List[i]._L2 := RTESignal._L2.Value;
        if Assigned(RTESignal._Command) then
          MPR_RWSignals.List[i]._Command := RTESignal._Command.Value;
      end;//1
      2: //входной
       begin
        If MPR.RWSignals[i].BeManevr then
        begin
          if Assigned(RTESignal._L1) then
            MPR_RWSignals.List[i]._L1 := RTESignal._L1.Value;
        end;
        if Assigned(RTESignal._L0) then
          MPR_RWSignals.List[i]._L0 := RTESignal._L0.Value;

       If MPR.RWSignals[i].Green = 0 then
          begin
            if Assigned(RTESignal._L2) then
              MPR_RWSignals.List[i]._L2 := RTESignal._L2.Value;
          end;
       If MPR.RWSignals[i].YellowTop = 0 then
          begin
            if Assigned(RTESignal._L3) then
              MPR_RWSignals.List[i]._L3 := RTESignal._L3.Value;
          end;
       If MPR.RWSignals[i].YellowBottom = 0 then
          begin
            if Assigned(RTESignal._L4) then
              MPR_RWSignals.List[i]._L4 := RTESignal._L4.Value;
          end;
       if Assigned(RTESignal._Command) then
          MPR_RWSignals.List[i]._Command := RTESignal._Command.Value;
       end;//2
      3,6: //выходной, маршрутный
       begin
         If MPR.RWSignals[i].Green = 0 then
          begin
            if Assigned(RTESignal._L2) then
              MPR_RWSignals.List[i]._L2 := RTESignal._L2.Value;
          end;
         If MPR.RWSignals[i].YellowTop = 0 then
          begin
            if Assigned(RTESignal._L3) then
              MPR_RWSignals.List[i]._L3 := RTESignal._L3.Value;
          end;
         If MPR.RWSignals[i].YellowBottom = 0 then
          begin
            if Assigned(RTESignal._L4) then
              MPR_RWSignals.List[i]._L4 := RTESignal._L4.Value;
          end;
         if Assigned(RTESignal._L0) then
            MPR_RWSignals.List[i]._L0 := RTESignal._L0.Value;
         if Assigned(RTESignal._L1) then
            MPR_RWSignals.List[i]._L1 := RTESignal._L1.Value;
         if Assigned(RTESignal._Command) then
            MPR_RWSignals.List[i]._Command := RTESignal._Command.Value;
       end;//3,6
      5: //попутный
       begin
          case RTESignal.SignalSubType of
            0:
            begin
              if Assigned(RTESignal.NETSrc) then
                MPR_RWSignals.List[i].netSgn_MainTag := RTESignal.NETSrc.Value;
              if Assigned(RTESignal.Connection) then
                if Assigned(RTESignal.Connection._SL) then
                  MPR_RWSignals.List[i].Connection := RTESignal.Connection._SL.Value;
            end;//0
            1:
            begin
              if Assigned(RTESignal._L1) then
                MPR_RWSignals.List[i]._L1 := RTESignal._L1.Value;
            end;//1
            2:
            begin
              MPR_RWSignals.List[i].Connection := 0;
              if Assigned(RTESignal.Connection) then
              begin
                if RTESignal.Connection.arrIndex > -1 then
                begin
                  MPR_RWSignals.List[i].Connection := MPR_RWConnections.List[RTESignal.Connection.arrIndex].FieldBusConnected
                end;
              end;//if
              case MPR.RWSignals[i].PoputClone of
                1,4: //клон маневрового
                begin
                  if Assigned(RTESignal._L1) then
                    MPR_RWSignals.List[i]._L1 := RTESignal._L1.Value;
                  if Assigned(RTESignal._L2) then
                    MPR_RWSignals.List[i]._L2 := RTESignal._L2.Value;
                end;//1,4
                2,3,6:
                begin
                  if Assigned(RTESignal._L0) then
                    MPR_RWSignals.List[i]._L0 := RTESignal._L0.Value;
                  If MPR.RWSignals[I].BeManevr then
                  begin
                    if Assigned(RTESignal._L1) then
                      MPR_RWSignals.List[i]._L1 := RTESignal._L1.Value;
                  end;
                  If MPR.RWSignals[I].Green = 0 then
                  begin
                    if Assigned(RTESignal._L2) then
                      MPR_RWSignals.List[i]._L2 := RTESignal._L2.Value;
                  end;
                  If MPR.RWSignals[I].YellowTop = 0 then
                  begin
                    if Assigned(RTESignal._L3) then
                    MPR_RWSignals.List[i]._L3 := RTESignal._L3.Value;
                  end;
                  If MPR.RWSignals[I].YellowBottom = 0 then
                  begin
                    if Assigned(RTESignal._L4) then
                      MPR_RWSignals.List[i]._L4 := RTESignal._L4.Value;
                  end;
                end;//2,3,6
              end; //case
            end;//2
          end;//case RTESignal.SignalSubType
       end;//5
      7: //проходной
        begin
          MPR_RWSignals.List[i].PassDir := TRUE;
          MPR_RWSignals.List[i].NoPassDir := FALSE;
          if MPR_RWSignals.List[i].ABIdx > -1 then
          begin
            if RTEDABs.Count > MPR_RWSignals.List[i].ABIdx then
            begin
              RTEDAB := TRTEDAB(RTEDABs.Objects[MPR_RWSignals.List[i].ABIdx]);
              if ((RTEDAB.ControlMode = 1) AND (RTEDAB.ControlType = 0)) OR (RTEDAB.ControlMode = 2) OR (RTEDAB.ControlMode = 3) then
              begin
                if MPR.RWSignals[i].Direction = RTEDAB.Direction then
                begin
                  case RTEDAB.ControlMode  of
                    1,3:
                    begin
                      if Assigned(RTEDAB._L1) AND Assigned(RTEDAB._L2) then
                      begin
                        MPR_RWSignals.List[i].PassDir := RTEDAB._L1.Value ;
                        MPR_RWSignals.List[i].NoPassDir := RTEDAB._L2.Value ;
                      end
                      else
                      begin
                        MPR_RWSignals.List[i].PassDir := FALSE;
                        MPR_RWSignals.List[i].NoPassDir :=FALSE;
                      end;
                    end;//1,3
                    2:
                    begin
                      if Assigned(RTEDAB._1SN) AND Assigned(RTEDAB._2SN) then
                      begin
                        MPR_RWSignals.List[i].PassDir := RTEDAB._1SN.Value ;
                        MPR_RWSignals.List[i].NoPassDir := RTEDAB._2SN.Value ;
                      end
                      else
                      begin
                        MPR_RWSignals.List[i].PassDir := FALSE;
                        MPR_RWSignals.List[i].NoPassDir :=FALSE;
                      end;
                    end;//2
                  end;//case RTEDAB.ControlMode
                end
                else
                begin
                  case RTEDAB.ControlMode  of
                    1,3:
                    begin
                      if Assigned(RTEDAB._L1) AND Assigned(RTEDAB._L2) then
                      begin
                        MPR_RWSignals.List[i].PassDir := RTEDAB._L2.Value ;
                        MPR_RWSignals.List[i].NoPassDir := RTEDAB._L1.Value ;
                      end
                      else
                      begin
                        MPR_RWSignals.List[i].PassDir := FALSE;
                        MPR_RWSignals.List[i].NoPassDir :=FALSE;
                      end;
                    end;//1,3
                    2:
                    begin
                      if Assigned(RTEDAB._1SN) AND Assigned(RTEDAB._2SN) then
                      begin
                        MPR_RWSignals.List[i].PassDir := RTEDAB._2SN.Value ;
                        MPR_RWSignals.List[i].NoPassDir := RTEDAB._1SN.Value ;
                      end
                      else
                      begin
                        MPR_RWSignals.List[i].PassDir := FALSE;
                        MPR_RWSignals.List[i].NoPassDir :=FALSE;
                      end;
                    end;//2
                  end;//case RTEDAB.ControlMode
                end;//if MPR.RWSignals[i].Direction = RTEDAB.Direction
              end;
            end;
          end;//if MPR_RWSignals.List[i].ABIdx > -1
          //красный
          if Assigned(RTESignal._L0) then
              MPR_RWSignals.List[i]._L0 := RTESignal._L0.Value;
          //желтый
          if Assigned(RTESignal._L1) then
              MPR_RWSignals.List[i]._L3 := RTESignal._L1.Value;
          //зеленый
          if Assigned(RTESignal._L2) then
              MPR_RWSignals.List[i]._L2 := RTESignal._L2.Value;
          if (RTESignal.SignalSubType = 1) OR (RTESignal.AdditionalSubType = 1) then
          begin
            if Assigned(RTESignal.NETSrc) then
              MPR_RWSignals.List[i].netSgn_MainTag := RTESignal.NETSrc.Value;
            if Assigned(RTESignal.Connection) then
              if Assigned(RTESignal.Connection._SL) then
                MPR_RWSignals.List[i].Connection := RTESignal.Connection._SL.Value;
          end;
          if (RTESignal.SignalSubType = 2) then
          begin
           MPR_RWSignals.List[i].Connection := 0;
           if Assigned(RTESignal.Connection) then
            begin
              if RTESignal.Connection.arrIndex > -1 then
              begin
                MPR_RWSignals.List[i].Connection := MPR_RWConnections.List[RTESignal.Connection.arrIndex].FieldBusConnected
              end;
           end;//if
          end;
        end;
    end;// case SignalType
  end;//for i
end;


procedure TMSURTECore.sWrite;
var
  i : Integer;
  RTESignal : TRTESignal;
begin
if RTESignals.Count = 0 then Exit;
FOR i:=0 TO MPR_Params.HighRWSignals DO
begin
  RTESignal := TRTESignal(RTESignals.Objects[i]);
  CASE MPR_RWSignals.List[I].SignalType OF
  1,2,3,6:
    begin
      if Assigned(RTESignal.MainTag) then
        RTESignal.MainTag.Value := MPR_RWSignals.List[I].MainTag;
      gv.sCalcDS_I := i;
      sCalcDS;
      if Assigned(RTESignal._DeviceState) then
        RTESignal._DeviceState.Value := MPR_RWSignals.List[I]._DeviceState;
      if Assigned(RTESignal._Result) then
        RTESignal._Result.Value := MPR_RWSignals.List[I]._Result;
    end;//1,2,3,6:
  5:
    begin
      if Assigned(RTESignal.MainTag) then
        RTESignal.MainTag.Value := MPR_RWSignals.List[I].MainTag;
    end;
  END;//CASE MPR_RWSignals.List[I].SignalType
  Case MPR.RWSignals[I].SignalType Of
  1:
    begin
      if Assigned(RTESignal._CTL0) then
        RTESignal._CTL0.Value := MPR_RWSignals.List[I]._CTL0;
      if Assigned(RTESignal._CTL1) then
        RTESignal._CTL1.Value := MPR_RWSignals.List[I]._CTL1;
      case MPR.RWSignals[I].SignalSubType  of
      0,1:
        begin
         case MPR.RWSignals[I].SignalLockType of
           0:
              begin
                 If MPR.ShuntBlock = '1' then
                 begin
                  if Assigned(RTESignal._BLOCK) then
                    RTESignal._BLOCK.Value := MPR_RWSignals.List[i]._BLOCK;
                 end;
              end;
           1:
              begin
                if Assigned(RTESignal._BLOCK) then
                    RTESignal._BLOCK.Value := MPR_RWSignals.List[i]._BLOCK;
              end;
         end;//case MPR.RWSignals[I].SignalLockType
        end;//подтипы 0,1
      2:
        begin
          if Assigned(RTESignal._CTL2) then
            RTESignal._CTL2.Value := MPR_RWSignals.List[i]._CTL2;
          if Assigned(RTESignal._CTL21) then
            RTESignal._CTL21.Value := MPR_RWSignals.List[i]._CTL3;
        end;//подтип 2
      3:
        begin
          if Assigned(RTESignal._CTL2) then
            RTESignal._CTL2.Value := MPR_RWSignals.List[i]._CTL2;
        end;//подтип 3
      end;//case MPR.RWSignals[I].SignalSubType
   end;//1
  2:
    begin
      if Assigned(RTESignal._BLOCK) then
        RTESignal._BLOCK.Value := MPR_RWSignals.List[i]._BLOCK;
      if Assigned(RTESignal._CTL0) then
        RTESignal._CTL0.Value := MPR_RWSignals.List[I]._CTL0;
      If MPR.RWSignals[I].BeManevr then
      begin
       if Assigned(RTESignal._CTL1) then
         RTESignal._CTL1.Value := MPR_RWSignals.List[I]._CTL1;
      end;
      If MPR.RWSignals[I].YellowBottom = 0 then
      begin
        if Assigned(RTESignal._CTL2) then
            RTESignal._CTL2.Value := MPR_RWSignals.List[i]._CTL2;
      end;
      If MPR.RWSignals[I].YellowTop = 0 then
      begin
        if Assigned(RTESignal._CTL3) then
            RTESignal._CTL3.Value := MPR_RWSignals.List[i]._CTL3;
      end;
     If MPR.RWSignals[I].Green = 0 then
     begin
        if Assigned(RTESignal._CTL4) then
            RTESignal._CTL4.Value := MPR_RWSignals.List[i]._CTL4;
     end;
   end;//2
  3:
    begin
      if Assigned(RTESignal._BLOCK) then
        RTESignal._BLOCK.Value := MPR_RWSignals.List[i]._BLOCK;
      if Assigned(RTESignal._CTL0) then
        RTESignal._CTL0.Value := MPR_RWSignals.List[I]._CTL0;
      If MPR.RWSignals[I].SignalSubType = 0 then
      begin
       if Assigned(RTESignal._CTL1) then
         RTESignal._CTL1.Value := MPR_RWSignals.List[I]._CTL1;
      end;
      If MPR.RWSignals[I].YellowBottom = 0 then
      begin
        if Assigned(RTESignal._CTL2) then
            RTESignal._CTL2.Value := MPR_RWSignals.List[i]._CTL2;
      end;
      If MPR.RWSignals[I].YellowTop = 0 then
      begin
        if Assigned(RTESignal._CTL3) then
            RTESignal._CTL3.Value := MPR_RWSignals.List[i]._CTL3;
      end;
     If MPR.RWSignals[I].Green = 0 then
     begin
        if Assigned(RTESignal._CTL4) then
            RTESignal._CTL4.Value := MPR_RWSignals.List[i]._CTL4;
     end;
    end;//3
  6:
    begin
      if Assigned(RTESignal._BLOCK) then
        RTESignal._BLOCK.Value := MPR_RWSignals.List[i]._BLOCK;
      if Assigned(RTESignal._CTL0) then
        RTESignal._CTL0.Value := MPR_RWSignals.List[I]._CTL0;
      case MPR.RWSignals[I].SignalSubType of
      0,1:
        begin
          if Assigned(RTESignal._CTL1) then
            RTESignal._CTL1.Value := MPR_RWSignals.List[I]._CTL1;
        end;//0,1
      end;//case
      If MPR.RWSignals[I].YellowBottom = 0 then
      begin
        if Assigned(RTESignal._CTL2) then
            RTESignal._CTL2.Value := MPR_RWSignals.List[i]._CTL2;
      end;
      If MPR.RWSignals[I].YellowTop = 0 then
      begin
        if Assigned(RTESignal._CTL3) then
            RTESignal._CTL3.Value := MPR_RWSignals.List[i]._CTL3;
      end;
     If MPR.RWSignals[I].Green = 0 then
     begin
        if Assigned(RTESignal._CTL4) then
            RTESignal._CTL4.Value := MPR_RWSignals.List[i]._CTL4;
     end;
    end;//6
  5:
   begin
   end;//5
  7: //Проходной
    begin
      if Assigned(RTESignal.MainTag) then
        RTESignal.MainTag.Value := MPR_RWSignals.List[I].MainTag;
      if Assigned(RTESignal._BlOCK) then
        RTESignal._BlOCK.Value := MPR_RWSignals.List[I]._BlOCK;
      //красный
      if Assigned(RTESignal._OUT1) then
        RTESignal._OUT1.Value := MPR_RWSignals.List[I]._CTL0;
      //желтый
      if Assigned(RTESignal._OUT2) then
        RTESignal._OUT2.Value := MPR_RWSignals.List[I]._CTL3;
      //зеленый
      if Assigned(RTESignal._OUT3) then
        RTESignal._OUT3.Value := MPR_RWSignals.List[I]._CTL4;
      gv.sCalcDS_I := i;
      sCalcDS;
      if Assigned(RTESignal._DeviceState) then
        RTESignal._DeviceState.Value := MPR_RWSignals.List[I]._DeviceState;
    end; //7
  end;//case MPR_RWSignals.List[I].SignalType
end;//for i
end;

procedure TMSURTECore.sVInit;
var
  i : Integer;
begin
  if Length(MPR.RW_V_Signals) = 0 then Exit;
  SetLength(MPR_RW_V_Signals.List,Length(MPR.RW_V_Signals));
  for i :=0 to High(MPR.RW_V_Signals) do
  begin
    If (MPR.RW_V_Signals[i].Direction = 1) then
       MPR_RW_V_Signals.List[i].Direction := TRUE
    else
       MPR_RW_V_Signals.List[i].Direction := FALSE;
    MPR_RW_V_Signals.List[i].ControlType := MPR.RW_V_Signals[I].ControlType;
 end;//for i
end;

procedure TMSURTECore.sVRead;
var
  i : Integer;
  RTEVSSignal : TRTEVSSignal;
begin
  if RTEVSSignals.Count = 0 then Exit;
  for i :=0 to RTEVSSignals.Count - 1 do
  begin
    RTEVSSignal := TRTEVSSignal(RTEVSSignals.Objects[i]);
    If RTEVSSignal.RW_V_Signal.ControlType = 0 then
    begin
      if Assigned(RTEVSSignal._L0) then
        MPR_RW_V_Signals.List[i]._L0 := RTEVSSignal._L0.Value;
    end;
    if Assigned(RTEVSSignal._L1) then
        MPR_RW_V_Signals.List[i]._L1 := RTEVSSignal._L1.Value;
  end;//for i
end;

procedure TMSURTECore.sVWrite;
var
  i : Integer;
  RTEVSSignal : TRTEVSSignal;
begin
  if RTEVSSignals.Count = 0 then Exit;
  for i :=0 to RTEVSSignals.Count - 1 do
  begin
    RTEVSSignal := TRTEVSSignal(RTEVSSignals.Objects[i]);
    if Assigned(RTEVSSignal.MainTag) then
      RTEVSSignal.MainTag.Value := MPR_RW_V_Signals.List[i].MainTag;
  end;//for i
end;

procedure TMSURTECore.mlInit;
var
  i,idxOwnerSignal, Direction, idxFrwSct, j : Integer;
  idxFindNode,idxOtherNode, idxSignalNode : Integer;
begin
if Length(MPR.RWML) = 0 then Exit;
SetLength(MPR_RWML.List,Length(MPR.RWML));
for i := 0 to High(MPR.RWML) do
 begin
    idxOwnerSignal := MPR.RWML[I].OwnerIndex;
    if idxOwnerSignal < 0  then Continue;
    MPR_RWML.List[i].OwnerIndex := MPR.RWML[I].OwnerIndex;
    Direction := MPR.RWSignals[idxOwnerSignal].Direction;
    idxFrwSct := -1;
    idxOtherNode := -1;
    for j := 0 to High(MPR.RWs) do
    begin
      if Direction = 1 then
      begin
        //Если группа движения светофора нечетная, то
        //ищем ж/д элемент, у которого данный изостык - вершина А
        idxFindNode := MPR.RWs[j].Node_AIndex;
        idxOtherNode := MPR.RWs[j].Node_BIndex;
      end
      else
      begin
        //Если группа движения светофора четная, то
        //ищем ж/д элемент, у которого данный изостык - вершина B
        idxFindNode := MPR.RWs[j].Node_BIndex;
        idxOtherNode := MPR.RWs[j].Node_AIndex;
      end;
      if idxFindNode = MPR.RWSignals[idxOwnerSignal].NodeIndex then
      begin
        idxFrwSct := MPR.RWs[j].SectionIndex;
        break;
      end;
    end;//for j
    if idxFrwSct = -1 then  continue;
    if idxFrwSct = MPR.RWSignals[idxOwnerSignal].SectionIndex then
    begin
      //Значит светофор створный - ищем далее
      idxSignalNode := idxOtherNode;
      for j := 0 to High(MPR.RWs) do
      begin
        if Direction = 1 then
        begin
          //Если группа движения светофора нечетная, то
          //ищем ж/д элемент, у которого данный изостык - вершина А
          idxFindNode := MPR.RWs[j].Node_AIndex;
          idxOtherNode := MPR.RWs[j].Node_BIndex;
        end
        else
        begin
          //Если группа движения светофора четная, то
          //ищем ж/д элемент, у которого данный изостык - вершина B
          idxFindNode := MPR.RWs[j].Node_BIndex;
          idxOtherNode := MPR.RWs[j].Node_AIndex;
        end;
        if idxFindNode = idxSignalNode then
        begin
          idxFrwSct := MPR.RWs[j].SectionIndex;
          break;
        end;
      end;//for j
    end;
    if idxFrwSct = -1 then  continue;
    MPR_RWML.List[i].idxFrwSct := idxFrwSct;
 end; //for i
end;

procedure TMSURTECore.mlRead;
var
  i : Integer;
  RTEMLSignal : TRTEMLSignal;
begin
  if RTEMLs.Count = 0 then Exit;
  for i := 0 TO RTEMLs.Count - 1 do
  begin
    RTEMLSignal := TRTEMLSignal(RTEMLs.Objects[i]);
    if Assigned(RTEMLSignal._COMM) then
      MPR_RWML.List[I].btPsd := RTEMLSignal._COMM.Value;
    if Assigned(RTEMLSignal._L1) then
      MPR_RWML.List[i]._L1 := RTEMLSignal._L1.Value;
  end;
end;

procedure TMSURTECore.mlWrite;
var
  i : Integer;
  RTEMLSignal : TRTEMLSignal;
begin
  if RTEMLs.Count = 0 then Exit;
  for i :=0 TO RTEMLs.Count - 1 do
  begin
    RTEMLSignal := TRTEMLSignal(RTEMLs.Objects[i]);
    if Assigned(RTEMLSignal.MainTag) then
      RTEMLSignal.MainTag.Value := MPR_RWML.List[i].MainTag;
    if Assigned(RTEMLSignal._COMM) then
      RTEMLSignal._COMM.Value := MPR_RWML.List[i].btPsd;
    if Assigned(RTEMLSignal._OUT) then
      RTEMLSignal._OUT.Value := MPR_RWML.List[i]._OUT;
    case RTEMLSignal.RWML.SignalLockType of
    0:
      begin
        If MPR.ShuntBlock = '1' then
        begin
          if Assigned(RTEMLSignal._BLOCK) then
            RTEMLSignal._BLOCK.Value := MPR_RWML.List[i]._BLOCK;
        end;
      end;//0
    1:
      begin
        if Assigned(RTEMLSignal._BLOCK) then
            RTEMLSignal._BLOCK.Value := MPR_RWML.List[i]._BLOCK;
      end;//1
    end;//case
  end;//for i
end;

procedure TMSURTECore.mlDo;
var
  i : Integer;
begin
  if RTEMLs.Count = 0 then Exit;
  for i := 0 to RTEMLs.Count - 1 do
  begin
    gv.sC_ML_I := i;
	  sC_ML;
  end;//for i
end;

procedure TMSURTECore.uInit;
var
  i, j, RouteIndex, N : Integer;
begin
if Length(SimpleRWRoutes) = 0 then Exit;
SetLength(MPR_RWRoutes_F.List,Length(SimpleRWRoutes));
SetLength(MPR_RWRoutes.List,Length(SimpleRWRoutes));
SetLength(MPR_RWRouteSections.List,Length(SimpleRWRoutes));
SetLength(MPR_RWRoutePoints.List,Length(SimpleRWRoutes));
SetLength(MPR_RWRoutePoints_Dep.List,Length(SimpleRWRoutes));
SetLength(MPR_RWRoutePoints_Flag.List,Length(SimpleRWRoutes));
for i := 0 to MPR_Params.HighRWRoutes do
begin
  MPR_RWRoutes_F.List[i].RouteBasic := TRUE;
  MPR_RWRoutes_F.List[i].RouteDirection := TRUE;
  MPR_RWRoutes_F.List[i].RouteManevr := TRUE;
  MPR_RWRoutes.List[i].RWPZ_Index := -1;
  MPR_RWRoutes.List[i].SectionSpecArrivalIndex := -1;
  MPR_RWRoutes.List[i].TailRouteIndex := -1;
  MPR_RWRoutes.List[i].ThirdSignalIndex := -1;
  MPR_RWRoutes.List[i].VarButtonIndex := -1;
  MPR_RWRouteSections.List[i].HighList := -1;
  MPR_RWRoutePoints.List[i].HighList := -1;
  MPR_RWRoutePoints_Dep.List[i].HighList := -1;
end;//for i
for i :=0 to High(SimpleRWRoutes) do
begin
  RouteIndex := SimpleRWRoutes[i];
  If MPR.RWRoutes[RouteIndex].RouteMode = 1 then
  begin
    MPR_RWRoutes_F.List[i].RouteManevr := TRUE;
  end
  else
  begin
    MPR_RWRoutes_F.List[i].RouteManevr := FALSE;
  end;
  If (MPR.RWRoutes[RouteIndex].Direction = 2) then
     MPR_RWRoutes_F.List[i].RouteDirection := FALSE;(*четное*)
  // только для поездных
  If (MPR.RWRoutes[RouteIndex].RouteMode = 2) then
  begin
    If (MPR.RWRoutes[RouteIndex].RouteOperation in [1,3]) then
      MPR_RWRoutes_F.List[i].RouteReceive := TRUE(*приема*)
     else
      MPR_RWRoutes_F.List[i].RouteReceive := FALSE;(*отправление*)
    If (MPR.RWRoutes[RouteIndex].ArrivalMain = 1) then
      MPR_RWRoutes_F.List[i].ArrivalMain := TRUE(*по главному*)
     else
      MPR_RWRoutes_F.List[i].ArrivalMain := FALSE;(*по боковому*)
    If (MPR.RWRoutes[RouteIndex].DepartureMain = 1) then
      MPR_RWRoutes_F.List[i].DepartureMain := TRUE(*по главному*)
    else
      MPR_RWRoutes_F.List[i].DepartureMain := FALSE;(*по боковому*)
    N := MPR.RWRoutes[RouteIndex].ThirdSignalIndex;
    If N <> -1 then
      MPR_RWRoutes.List[i].ThirdSignalIndex := N
    else
      MPR_RWRoutes.List[i].ThirdSignalIndex := -1;
  end;//If (MPR.RWRoutes[RouteIndex].RouteMode = 2)
  N := MPR.RWRoutes[RouteIndex].SectionSpecialArrivalIndex;
  If N <> -1 then
     MPR_RWRoutes.List[i].SectionSpecArrivalIndex := N;(*секция-соседка для спец. маневрового без секций '+MPR.RWSections[N].Caption+'*)
  N := MPR.RWRoutes[RouteIndex].RouteBasic;
  If N = 2 then
     MPR_RWRoutes_F.List[i].RouteBasic := FALSE;(*специальный,по попутным сигналам*)
  N := MPR.RWRoutes[RouteIndex].FirstSignalIndex;
  MPR_RWRoutes.List[i].FirstSignalIndex := N;(*Первый светофор '+MPR.RWSignals[N].Caption+'*)
  N := MPR.RWRoutes[RouteIndex].SecondSignalIndex;
  MPR_RWRoutes.List[i].SecondSignalIndex := N;(*Второй светофор '+MPR.RWSignals[N].Caption+'*)
  N := MPR.RWRoutes[RouteIndex].VariantButton;
  MPR_RWRoutes.List[i].VarButtonIndex := N;(*Индекс вариантной кнопки*)

  //заполнение блока секций маршрутов
  MPR_RWRouteSections.List[i].HighList := High(MPR.RWRoutes[RouteIndex].Sections);
  If Length(MPR.RWRoutes[RouteIndex].Sections) > 0 then
  begin
    SetLength(MPR_RWRouteSections.List[i].List,Length(MPR.RWRoutes[RouteIndex].Sections));
    for j :=0 to High(MPR.RWRoutes[RouteIndex].Sections) do
    begin
      N := MPR.RWRoutes[RouteIndex].Sections[j];
      MPR_RWRouteSections.List[i].List[j] := N;(*'+MPR.RWSections[N].Caption+'*)
    end;
  end;

  MPR_RWRoutePoints.List[i].HighList := High(MPR.RWRoutes[RouteIndex].PointsF3);
  If Length(MPR.RWRoutes[RouteIndex].PointsF3) > 0 then
  begin
    SetLength(MPR_RWRoutePoints.List[i].List,Length(MPR.RWRoutes[RouteIndex].PointsF3));
    SetLength(MPR_RWRoutePoints_Flag.List[i].List,Length(MPR.RWRoutes[RouteIndex].PointsF3));
    SetLength(MPR_RWRoutePoints_Dep.List[i].List,Length(MPR.RWRoutes[RouteIndex].PointsF3));
     for j := 0 to High(MPR.RWRoutes[RouteIndex].PointsF3) do
     begin
        N := MPR.RWRoutes[RouteIndex].PointsF3[j].ThePointIndex;
        MPR_RWRoutePoints.List[i].List[j].PointsIndex := N;
        If MPR.RWRoutes[RouteIndex].PointsF3[j].Value = 2 then
          MPR_RWRoutePoints_Flag.List[i].List[j].Value := TRUE;
        If MPR.RWRoutes[RouteIndex].PointsF3[j].DependOnValue <> 0 then
        begin
          MPR_RWRoutePoints_Flag.List[i].List[j].Trap := TRUE;
          //индекс охраняемой стрелки в общем массиве
          N := MPR.RWRoutes[RouteIndex].PointsF3[j].MovePointsIndex;
          MPR_RWRoutePoints_Dep.List[i].List[j].DependPointsIndex := N;
        end;//if
     end;//for j
  end;//If Length(MPR.RWRoutes[RouteIndex].PointsF3) > 0 then
 end;//for i
end;

procedure TMSURTECore.uRead;
var
  i,RouteIndex : Integer;
  RTERoute : TRTERoute;
begin
if RTERoutes.Count = 0 then Exit;
if Length(SimpleRWRoutes) = 0 then Exit;
for i :=0 to High(SimpleRWRoutes) do
begin
  RouteIndex := SimpleRWRoutes[i];
  if (RouteIndex < 0) OR (RouteIndex >= RTERoutes.Count) then continue;
  RTERoute := TRTERoute(RTERoutes.Objects[RouteIndex]);
  if Assigned(RTERoute) then
  begin
    if Assigned(RTERoute.MainTag) then
      MPR_RWRoutes.List[i].MainTag := RTERoute.MainTag.Value;
    if Assigned(RTERoute._LR) then
      MPR_RWRoutes.List[i]._LR := RTERoute._LR.Value;
  end;// if Assigned(RTERoute)
end;//for i
end;

function TMSURTECore.PrepareMPR;
//подготовка МПР к работе
var
I,J:Integer;
List:TStringList;
begin
Result := False;
//подготовка массива секций
for I:=0 to High(MPR.RWSections) do
begin
  //невидимая секция не имеет контроль
If MPR.RWSections[I].SectionDummy = '1' then
   MPR.RWSections[I].WithoutControl := '1';
end;
//формирование массива простых маршрутов
SimpleRWRoutes := nil;
If MPR = nil then
begin
  AppLogger.AddErrorMessage ('*** МПР не создан.');
  Exit;
end;
If Length(MPR.RWRoutes) <= 0 then
begin
  AppLogger.AddErrorMessage ('*** маршрутов в МПР нет.');
  Exit;
end;

List := TStringList.Create;
try
With List do
 begin
 for I:=0 to High(MPR.RWRoutes) do
  begin
  If MPR.RWRoutes[I].RouteSimple = 2 then Continue;
  Add(IntToStr(I));
  end;
 end;// with List
If List.Count = 0 then
begin
  AppLogger.AddErrorMessage ('*** простых маршрутов в МПР нет.');
  Exit;
end;

SetLength(SimpleRWRoutes,List.Count);
for I:=0 to List.Count-1 do
 begin
 J := StrToInt(List[I]);
 SimpleRWRoutes[I] := J;
 end;

//формирование массива СМ
List.Clear;
ComplexRWRoutes := nil;
With List do
 begin
 for I:=0 to High(MPR.RWRoutes) do
  begin
  If MPR.RWRoutes[I].RouteSimple = 1 then Continue;
  Add(IntToStr(I));
  end;
 end;// with List
case MPR.DeviationStation  of
1:
begin

end //1
else
  begin
    If List.Count = 0 then
    begin
      AppLogger.AddErrorMessage('*** составных маршрутов в МПР нет.');
      Exit;
    end;

    SetLength(ComplexRWRoutes,List.Count);
    for I:=0 to List.Count-1 do
     begin
     J := StrToInt(List[I]);
     ComplexRWRoutes[I] := J;
     end;
  end;//else
end;//case
finally
if Assigned(List) then
  List.Free;
end;
Result := True;
end;

procedure TMSURTECore.dabInit;
begin
  DABInitialization(MPR);
end;

{procedure TMSURTECore.dabInit;
var
  i : Integer;
begin
  if Length(MPR.RWCD) = 0 then Exit;
  SetLength(MPR_RWDABArray.List, Length(MPR.RWCD));
  for i :=0 to High(MPR.RWCD) do
  begin
    MPR_RWDABArray.List[i].DABType := MPR.RWCD[i].CDType;
    try
      MPR_RWDABArray.List[i].Direction := StrToInt(MPR.RWCD[I].RD);
    except
      MPR_RWDABArray.List[i].Direction := 1;
    end;
    (*_1I_RO - извещение идет нулем*)
    MPR_RWDABArray.List[i]._1I_R := TRUE;
    (*сброс тэга _I_R - это типа захвата направления при =0*)
    MPR_RWDABArray.List[i]._1IO_R := TRUE;
    case MPR_RWDABArray.List[i].DABType of
      1,3:
      begin
        MPR_RWDABArray.List[i].ControlType := MPR.RWCD[i].MasterSlave;
      end;//1
    end; //case
  end; //for i
end;  }

procedure TMSURTECore.dabRead;
var
  i,j : Integer;
  RTEDAB : TRTEDAB;
  RTESection : TRTESection;
begin
  if RTEDABs.Count = 0 then Exit;
  //входные от ДСП
  for i:=0 TO RTEDABs.Count - 1 do
  begin
    RTEDAB := TRTEDAB(RTEDABs.Objects[i]);
    if Assigned(RTEDAB._SN) then
      MPR_RWDABArray.List[i]._SN := RTEDAB._SN.Value;
    if Assigned(RTEDAB._OV) then
      MPR_RWDABArray.List[i]._OV := RTEDAB._OV.Value;
    if Assigned(RTEDAB._PV) then
      MPR_RWDABArray.List[i]._PV := RTEDAB._PV.Value;
    if Assigned(RTEDAB._1I_R) then
      MPR_RWDABArray.List[i]._1I_R := RTEDAB._1I_R.Value;
    case RTEDAB.ControlMode of
      0:
      begin
        if Assigned(RTEDAB._L1) then
          MPR_RWDABArray.List[i]._L1 := RTEDAB._L1.Value;
        if Assigned(RTEDAB._L2) then
          MPR_RWDABArray.List[i]._L2 := RTEDAB._L2.Value;
        if Assigned(RTEDAB._KP_L1) then
          MPR_RWDABArray.List[i]._KP_L1 := RTEDAB._KP_L1.Value;
        if Assigned(RTEDAB._Command) then
          MPR_RWDABArray.List[i].Command := RTEDAB._Command.Value;
        if Assigned(RTEDAB._1I_R) then
          MPR_RWDABArray.List[i]._1I_R := RTEDAB._1I_R.Value;
      end;
      1:
      begin
        MPR_RWDABArray.List[i].InterConnect := 0;
        if Assigned(RTEDAB.Connection) then
        begin
          if Assigned(RTEDAB.Connection._SL) then
            MPR_RWDABArray.List[i].InterConnect := RTEDAB.Connection._SL.Value;
        end;
        if RTEDAB.ControlType = 0  then
        begin
          //только через полевую шину
          if Assigned(RTEDAB._L1) then
            MPR_RWDABArray.List[i]._L1 := RTEDAB._L1.Value;
          if Assigned(RTEDAB._L2) then
            MPR_RWDABArray.List[i]._L2 := RTEDAB._L2.Value;
        end
        else
        begin
          if MPR_RWDABArray.List[i].InterConnect = 0 then
          begin
            MPR_RWDABArray.List[i]._L1 := FALSE;
            MPR_RWDABArray.List[i]._L2 := FALSE;
          end
          else
          begin
            if Assigned(RTEDAB._L1) then
              MPR_RWDABArray.List[i]._L1 := RTEDAB._L1.Value;
            if Assigned(RTEDAB._L2) then
              MPR_RWDABArray.List[i]._L2 := RTEDAB._L2.Value;
          end;
        end;
        if Assigned(RTEDAB._SN) then
          MPR_RWDABArray.List[i]._SN := RTEDAB._SN.Value;
        if Assigned(RTEDAB._OV) then
          MPR_RWDABArray.List[i]._OV := RTEDAB._OV.Value;
        if Assigned(RTEDAB._PV) then
          MPR_RWDABArray.List[i]._PV := RTEDAB._PV.Value;
        if MPR_RWDABArray.List[i].InterConnect = 0 then
        begin
          MPR_RWDABArray.List[i]._SN_NET := FALSE;
          MPR_RWDABArray.List[i]._OV_NET := FALSE;
          MPR_RWDABArray.List[i]._PV_NET := FALSE;
        end
        else
          if Assigned(RTEDAB._SN_NET) then
            MPR_RWDABArray.List[i]._SN_NET := RTEDAB._SN_NET.Value;
          if Assigned(RTEDAB._OV_NET) then
            MPR_RWDABArray.List[i]._OV_NET := RTEDAB._OV_NET.Value;
          if Assigned(RTEDAB._PV_NET) then
            MPR_RWDABArray.List[i]._PV_NET := RTEDAB._PV_NET.Value;
        begin
        end;
        MPR_RWDABArray.List[i].ISFREE := TRUE;
        MPR_RWDABArray.List[i].ISNOTINROOT := TRUE;
        if RTEDAB.DABSections.Count > 0 then
        begin
          for j := 0 to RTEDAB.DABSections.Count - 1 do
          begin
            RTESection := TRTESection(RTEDAB.DABSections.Objects[j]);
            if Assigned(RTESection.GeneralTag) then
            begin
              MPR_RWDABArray.List[i].ISFREE := MPR_RWDABArray.List[i].ISFREE AND (RTESection.GeneralTag.Value = 0);
            end;
            if Assigned(RTESection._SV) then
            begin
              MPR_RWDABArray.List[i].ISFREE := MPR_RWDABArray.List[i].ISFREE AND (RTESection._SV.Value = 0);
              MPR_RWDABArray.List[i].ISNOTINROOT := MPR_RWDABArray.List[i].ISNOTINROOT AND (RTESection._SV.Value <> 1) AND (RTESection._SV.Value <> 3);
            end;
          end;//for j
        end;//if RTEDAB.DABSections.Count
      end;
      2:
      begin
        if Assigned(RTEDAB._1SN) then
          MPR_RWDABArray.List[i]._1SN := RTEDAB._1SN.Value;
        if Assigned(RTEDAB._2SN) then
          MPR_RWDABArray.List[i]._2SN := RTEDAB._2SN.Value;
        if Assigned(RTEDAB._KP_L1) then
          MPR_RWDABArray.List[i]._KP_L1 := RTEDAB._KP_L1.Value;
        if Assigned(RTEDAB._2IP_L1) then
          MPR_RWDABArray.List[i]._2IP_L1 := RTEDAB._2IP_L1.Value;
        if MPR.RWCD[I].BU_Control_29 = 0 then
        begin
          if Assigned(RTEDAB._2I_L1) then
            MPR_RWDABArray.List[i]._2I_L1 := RTEDAB._2I_L1.Value;
        end
        else
        begin
          MPR_RWDABArray.List[i]._2I_L1 := FALSE;
        end;
        if MPR.RWCD[I].BU_Control_30 = 0 then
        begin
          if Assigned(RTEDAB._2VSN_L1) then
            MPR_RWDABArray.List[i]._2VSN_L1 := RTEDAB._2VSN_L1.Value;
        end
        else
        begin
          MPR_RWDABArray.List[i]._2VSN_L1 := FALSE;
        end;
        if Assigned(RTEDAB._2PV_L1) then
          MPR_RWDABArray.List[i]._2PV_L1 := RTEDAB._2PV_L1.Value;
        if MPR.RWCD[I].AllBUControl = 0 then
        begin
          if Assigned(RTEDAB._2PBU_L1) then
            MPR_RWDABArray.List[i]._2PBU_L1 := RTEDAB._2PBU_L1.Value;
        end
        else
        begin
          MPR_RWDABArray.List[i]._2PBU_L1 := FALSE;
        end;
        if MPR.RWCD[i].BU_Control_28 = 0 then
        begin
          if Assigned(RTEDAB._BU_L1) then
            MPR_RWDABArray.List[i]._BU_L1 := RTEDAB._BU_L1.Value;
        end
        else
        begin
          MPR_RWDABArray.List[i]._BU_L1 := FALSE;
        end;
        if Assigned(RTEDAB._1IO_R) then
          MPR_RWDABArray.List[i]._1IO_R := RTEDAB._1IO_R.Value;
        if Assigned(RTEDAB._1I_R) then
          MPR_RWDABArray.List[i]._1I_R := RTEDAB._1I_R.Value;
        if MPR_RWDABArray.List[i].ISidx = -1 then
        begin
          MPR_RWDABArray.List[i].ISExpr := FALSE;
        end
        else
        begin
          MPR_RWDABArray.List[i].ISExpr := (MPR_RWSignals.List[MPR_RWDABArray.List[i].ISidx].MainTag >= 2);
        end;
        MPR_RWDABArray.List[i].ConnectState := MPR_Params.SafeMode;
        if Assigned(RTEDAB._Command) then
          MPR_RWDABArray.List[i].Command := RTEDAB._Command.Value;
      end;//2
      3:
      begin
        MPR_RWDABArray.List[i].InterConnect := 0;
        if Assigned(RTEDAB.Connection) then
        begin
          case RTEDAB.BusType of
            0:
            begin
              if Assigned(RTEDAB.Connection._SL) then
                MPR_RWDABArray.List[i].InterConnect := RTEDAB.Connection._SL.Value;
            end;//0
            1:
            begin
              if RTEDAB.Connection.arrIndex > - 1 then
              begin
                MPR_RWDABArray.List[i].InterConnect := MPR_RWConnections.List[RTEDAB.Connection.arrIndex].FieldBusConnected;
              end;//if
            end;//1
          end;//case
        end;
        if RTEDAB.ControlType = 0  then
        begin
          //только через полевую шину
          if Assigned(RTEDAB._L1) then
            MPR_RWDABArray.List[i]._L1 := RTEDAB._L1.Value;
          if Assigned(RTEDAB._L2) then
            MPR_RWDABArray.List[i]._L2 := RTEDAB._L2.Value;
        end
        else
        begin
          if MPR_RWDABArray.List[i].InterConnect = 0 then
          begin
            MPR_RWDABArray.List[i]._L1 := FALSE;
            MPR_RWDABArray.List[i]._L2 := FALSE;
          end
          else
          begin
            if Assigned(RTEDAB._L1) then
              MPR_RWDABArray.List[i]._L1 := RTEDAB._L1.Value;
            if Assigned(RTEDAB._L2) then
              MPR_RWDABArray.List[i]._L2 := RTEDAB._L2.Value;
          end;
        end;
        if MPR_RWDABArray.List[i].InterConnect = 0 then
        begin
          MPR_RWDABArray.List[i]._2PBU := FALSE;
          MPR_RWDABArray.List[i]._2IP := FALSE;
          MPR_RWDABArray.List[i]._1I_R_L1 := FALSE;
          MPR_RWDABArray.List[i]._2VSN_L1 := FALSE;
          MPR_RWDABArray.List[i]._2PV_L1 := FALSE;
          MPR_RWDABArray.List[i]._2OV_L1 := FALSE;
        end
        else
        begin
          if Assigned(RTEDAB._2PBU) then
            MPR_RWDABArray.List[i]._2PBU := RTEDAB._2PBU.Value;
          if Assigned(RTEDAB._2IP) then
            MPR_RWDABArray.List[i]._2IP := RTEDAB._2IP.Value;
          if Assigned(RTEDAB._1I_R_L1) then
            MPR_RWDABArray.List[i]._1I_R_L1 := RTEDAB._1I_R_L1.Value;
          if Assigned(RTEDAB._2VSN_L1) then
            MPR_RWDABArray.List[i]._2VSN_L1 := RTEDAB._2VSN_L1.Value;
          if Assigned(RTEDAB._2PV_L1) then
            MPR_RWDABArray.List[i]._2PV_L1 := RTEDAB._2PV_L1.Value;
          if Assigned(RTEDAB._2OV_L1) then
            MPR_RWDABArray.List[i]._2OV_L1 := RTEDAB._2OV_L1.Value;
        end;
        MPR_RWDABArray.List[i].ConnectState := MPR_Params.SafeMode;
        if Assigned(RTEDAB._Command) then
          MPR_RWDABArray.List[i].Command := RTEDAB._Command.Value;
        if Assigned(RTEDAB._1IO_R) then
          MPR_RWDABArray.List[i]._1IO_R := RTEDAB._1IO_R.Value;
        if Assigned(RTEDAB._1I_R) then
          MPR_RWDABArray.List[i]._1I_R := RTEDAB._1I_R.Value;
        MPR_RWDABArray.List[i].ISFREE := TRUE;
        if RTEDAB.DABSections.Count > 0 then
        begin
          for j := 0 to RTEDAB.DABSections.Count - 1 do
          begin
            RTESection := TRTESection(RTEDAB.DABSections.Objects[j]);
            if Assigned(RTESection.GeneralTag) then
            begin
              MPR_RWDABArray.List[i].ISFREE := MPR_RWDABArray.List[i].ISFREE AND (RTESection._GS.Value = 0);
            end;
            if Assigned(RTESection._SV) then
            begin
              MPR_RWDABArray.List[i].ISFREE := MPR_RWDABArray.List[i].ISFREE AND (RTESection._SV.Value <> 1);
            end;
          end;//for j
        end;
      end;//3
    end;
   end;
end;

function TMSURTECore.GetInputSignalForDAB(ADABidx: Integer) : Integer;
var
  DABCode : String;
  i,j : Integer;
  SctList : TStringList;
  DABDir : Integer;
begin
  Result := -1;
  try
    DABDir := StrToInt(MPR.RWCD[ADABidx].RD);
  except
    Exit;
  end;
  if Length(MPR.RWSignals) <= 0 then Exit;
  DABCode := MPR.RWCD[ADABidx].Code;
  SctList := TStringList.Create;
  try
    if Length(MPR.RWSections) > 0 then
    begin
      for i := 0 to High (MPR.RWSections) do
      begin
        if MPR.RWSections[i].CDCode = DABCode then
        begin
          SctList.Add(MPR.RWSections[i].Code);
        end;
      end;//for i
    end;
    if SctList.Count > 0 then
    begin
      for i := 0 to SctList.Count - 1 do
      begin
        for j := 0 to High(MPR.RWSignals) do
        begin
          if MPR.RWSignals[j].SignalType = 2 then
            if MPR.RWSignals[j].Direction = DABDir then
              if MPR.RWSignals[j].SectionCode = SctList[i] then
              begin
                Result := j;
                SctList.Free;
                SctList := nil;
                Exit;
              end;
        end;
      end;
    end;
  finally
    if Assigned(SctList) then
      SctList.Free;
  end;
end;

procedure TMSURTECore.dabDO;
var
  i : Integer;
  RTEDAB : TRTEDAB;
begin
  if RTEDABs.Count = 0 then Exit;
  for i:=0 TO RTEDABs.Count - 1 do
  begin
    RTEDAB := TRTEDAB(RTEDABs.Objects[i]);
    gv.dabDo_I := i;
    case RTEDAB.ControlMode  of
      0:
        begin
          DAB0;
        end;
      1:
      begin
        DAB1;
      end;
      2:
      begin
        DAB2;
      end;//2
      3:
      begin
        DAB3;
      end;//3
    end;//case
  end; //for i
end;

procedure TMSURTECore.dabWrite;
var
  i : Integer;
  RTEDAB : TRTEDAB;
begin
  if RTEDABs.Count = 0 then Exit;
  for i:=0 TO RTEDABs.Count - 1 do
  begin
    RTEDAB := TRTEDAB(RTEDABs.Objects[i]);
    case RTEDAB.ControlMode  of
      0:
      begin
        if Assigned(RTEDAB.MainTag) then
          RTEDAB.MainTag.Value := MPR_RWDABArray.List[i].MainTag;
        if Assigned(RTEDAB._OV_OUT) then
          RTEDAB._OV_OUT.Value := MPR_RWDABArray.List[i]._OV_OUT;
        if Assigned(RTEDAB._PV_OUT) then
          RTEDAB._PV_OUT.Value := MPR_RWDABArray.List[i]._PV_OUT;
        if Assigned(RTEDAB._SN_OUT) then
          RTEDAB._SN_OUT.Value := MPR_RWDABArray.List[i]._SN_OUT;
        if Assigned(RTEDAB._1I_OUT) then
          RTEDAB._1I_OUT.Value := MPR_RWDABArray.List[i]._1I_OUT;
        if Assigned(RTEDAB._Result) then
          RTEDAB._Result.Value := MPR_RWDABArray.List[i].Result;
      end;
      1:
      begin
        if Assigned(RTEDAB.MainTag) then
          RTEDAB.MainTag.Value := MPR_RWDABArray.List[i].MainTag;
        if Assigned(RTEDAB._SN1) then
          RTEDAB._SN1.Value := MPR_RWDABArray.List[i]._SN1;
        if Assigned(RTEDAB._SN2) then
          RTEDAB._SN2.Value := MPR_RWDABArray.List[i]._SN2;
      end;//1
      2:
      begin
        if Assigned(RTEDAB._2IP)  then
          RTEDAB._2IP.Value := MPR_RWDABArray.List[i]._2IP;
        if Assigned(RTEDAB._PKP_OUT) then
          RTEDAB._PKP_OUT.Value := MPR_RWDABArray.List[i]._PKP_OUT;
        if MPR.RWCD[I].BU_Control_29 = 0 then
        begin
          if Assigned(RTEDAB._KP_OUT) then
            RTEDAB._KP_OUT.Value := MPR_RWDABArray.List[i]._KP_OUT;
          if Assigned(RTEDAB._KP_BLOCK) then
            RTEDAB._KP_BLOCK.Value := MPR_RWDABArray.List[i]._KP_BLOCK;
        end;
        if Assigned(RTEDAB._1SN_OUT) then
          RTEDAB._1SN_OUT.Value := MPR_RWDABArray.List[i]._1SN_OUT;
        if Assigned(RTEDAB._1OV_OUT) then
          RTEDAB._1OV_OUT.Value := MPR_RWDABArray.List[i]._1OV_OUT;
        if Assigned(RTEDAB._2PV_OUT) then
          RTEDAB._2PV_OUT.Value := MPR_RWDABArray.List[i]._2PV_OUT;
        if MPR.RWCD[I].BU_Control_30 = 0 then
        begin
          if Assigned(RTEDAB._2VSN_OUT) then
            RTEDAB._2VSN_OUT.Value := MPR_RWDABArray.List[i]._2VSN_OUT;
          if Assigned(RTEDAB._2VSN_BLOCK) then
            RTEDAB._2VSN_BLOCK.Value := MPR_RWDABArray.List[i]._2VSN_BLOCK;
        end;
        if Assigned(RTEDAB._1IO_OUT) then
          RTEDAB._1IO_OUT.Value := MPR_RWDABArray.List[i]._1IO_OUT;
        if Assigned(RTEDAB._1I_OUT) then
          RTEDAB._1I_OUT.Value := MPR_RWDABArray.List[i]._1I_OUT;
        if MPR.RWCD[I].BU_Control_28 = 0 then
        begin
          if Assigned(RTEDAB._BU_OUT) then
            RTEDAB._BU_OUT.Value := MPR_RWDABArray.List[i]._BU_OUT;
          if Assigned(RTEDAB._BU_BLOCK) then
            RTEDAB._BU_BLOCK.Value := MPR_RWDABArray.List[i]._BU_BLOCK;
        end;
        if Assigned(RTEDAB._1PV_OUT) then
          RTEDAB._1PV_OUT.Value := MPR_RWDABArray.List[i]._1PV_OUT;
        if Assigned(RTEDAB._1SVH_OUT) then
          RTEDAB._1SVH_OUT.Value := MPR_RWDABArray.List[i]._1SVH_OUT;
        if MPR.RWCD[I].BU_Control_31 = 0 then
        begin
          if Assigned(RTEDAB._1PR_OUT) then
            RTEDAB._1PR_OUT.Value := MPR_RWDABArray.List[i]._1PR_OUT;
          if Assigned(RTEDAB._1OT_OUT) then
            RTEDAB._1OT_OUT.Value := MPR_RWDABArray.List[i]._1OT_OUT;
          if Assigned(RTEDAB._1PR_BLOCK) then
            RTEDAB._1PR_BLOCK.Value := MPR_RWDABArray.List[i]._1PR_BLOCK;
          if Assigned(RTEDAB._1OT_BLOCK) then
            RTEDAB._1OT_BLOCK.Value := MPR_RWDABArray.List[i]._1OT_BLOCK;
        end;
        if MPR.RWCD[I].AllBUControl = 0 then
        begin
          if Assigned(RTEDAB._2PBU_OUT) then
            RTEDAB._2PBU_OUT.Value := MPR_RWDABArray.List[i]._2PBU_OUT;
          if Assigned(RTEDAB._2PBU_BLOCK) then
            RTEDAB._2PBU_BLOCK.Value := MPR_RWDABArray.List[i]._2PBU_BLOCK;
        end;
        if Assigned(RTEDAB._1IO_BLOCK) then
          RTEDAB._1IO_BLOCK.Value := MPR_RWDABArray.List[i]._1IO_BLOCK;
        if Assigned(RTEDAB._1I_BLOCK) then
          RTEDAB._1I_BLOCK.Value := MPR_RWDABArray.List[i]._1I_BLOCK;
        if Assigned(RTEDAB._1PV_BLOCK) then
          RTEDAB._1PV_BLOCK.Value := MPR_RWDABArray.List[i]._1PV_BLOCK;
        if Assigned(RTEDAB._1SVH_BLOCK) then
          RTEDAB._1SVH_BLOCK.Value := MPR_RWDABArray.List[i]._1SVH_BLOCK;
        if Assigned(RTEDAB.MainTag) then
          RTEDAB.MainTag.Value := MPR_RWDABArray.List[i].MainTag;
        if Assigned(RTEDAB._Result) then
          RTEDAB._Result.Value := MPR_RWDABArray.List[i].Result;
      end;//2
      3:
      begin
        if Assigned(RTEDAB.MainTag) then
          RTEDAB.MainTag.Value := MPR_RWDABArray.List[i].MainTag;
        if Assigned(RTEDAB._1SN) then
          RTEDAB._1SN.Value := MPR_RWDABArray.List[i]._1SN;
        if Assigned(RTEDAB._2SN) then
          RTEDAB._2SN.Value := MPR_RWDABArray.List[i]._2SN;
        if Assigned(RTEDAB._Result) then
          RTEDAB._Result.Value := MPR_RWDABArray.List[i].Result;
        if Assigned(RTEDAB._1IO_R_OUT) then
          RTEDAB._1IO_R_OUT.Value := MPR_RWDABArray.List[i]._1IO_R_OUT;
        if Assigned(RTEDAB._1I_R_OUT) then
          RTEDAB._1I_R_OUT.Value := MPR_RWDABArray.List[i]._1I_R_OUT;
        if Assigned(RTEDAB._1OT_OUT) then
          RTEDAB._1OT_OUT.Value := MPR_RWDABArray.List[i]._1OT_OUT;
        if Assigned(RTEDAB._1PR_OUT) then
          RTEDAB._1PR_OUT.Value := MPR_RWDABArray.List[i]._1PR_OUT;
        if Assigned(RTEDAB._OV_OUT) then
          RTEDAB._OV_OUT.Value := MPR_RWDABArray.List[i]._OV_OUT;
        if Assigned(RTEDAB._PV_OUT) then
          RTEDAB._PV_OUT.Value := MPR_RWDABArray.List[i]._PV_OUT;
        if Assigned(RTEDAB._SN_OUT) then
          RTEDAB._SN_OUT.Value := MPR_RWDABArray.List[i]._SN_OUT;
        if Assigned(RTEDAB._KP_L1) then
          RTEDAB._KP_L1.Value := MPR_RWDABArray.List[i]._KP_L1;
        if Assigned(RTEDAB._2IP_L1) then
          RTEDAB._2IP_L1.Value := MPR_RWDABArray.List[i]._2IP_L1;
        if Assigned(RTEDAB._BU) then
          RTEDAB._BU.Value := MPR_RWDABArray.List[i]._BU;
      end;//3
    end;//case
  end;//for i
end;

Constructor TRTECrossLine.Create(AMPRCore: TMSURTECore; ACrossLine: TRWCrossLine);
var
  i : Integer;
  RTECrossing : TRTECrossing;
  NewTag : TRTETag;
  RTESection : TRTESection;
begin
  inherited Create(AMPRCore);
  RWCrossLine := ACrossLine;
  Name := ACrossLine.Code;
  FCaption := ACrossLine.Caption;
  Owner := nil;
  _EVEN_OUT := nil;
  _ODD_OUT := nil;
  if MPRCore.RTECrossings.Count = 0 then Exit;
  for i := 0 to MPRCore.RTECrossings.Count - 1 do
  begin
    RTECrossing := TRTECrossing(MPRCore.RTECrossings.Objects[i]);
    if RTECrossing.Name.Equals(RWCrossLine.Owner.Trim()) then
    begin
      Owner := RTECrossing;
      if Owner.OutSignalsNumber = 2 then
      begin
        NewTag := TRTETag.Create('G' + RTECrossing.Name + '_'+ RWCrossLine.OwnerSection + '_EVEN_OUT', Owner, VT_BOOL, FALSE);
        _EVEN_OUT := NewTag;
        NewTag.PLCTagEntry.Phisical := true;
        NewTag.IsOPCTag := true;
        MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
        MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
        NewTag := TRTETag.Create('G' + RTECrossing.Name + '_' + RWCrossLine.OwnerSection + '_ODD_OUT', Owner, VT_BOOL, FALSE);
        _ODD_OUT := NewTag;
        NewTag.PLCTagEntry.Phisical := true;
        NewTag.IsOPCTag := true;
        MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
        MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
      end;
      break;
    end;//if RTECrossing.Name.Equals(RWCrossLine.Owner.Trim())
  end;//for i
  if MPRCore.RTESections.Count = 0 then Exit;
  for i := 0 to MPRCore.RTESections.Count - 1 do
  begin
    RTESection := TRTESection(MPRCore.RTESections.Objects[i]);
    if RTESection.Name.Equals(RWCrossLine.OwnerSection) then
    begin
      FChangeDirection := RTESection.RWSection.Rotary;
      break;
    end;
  end;
end;

Destructor TRTECrossLine.Destroy;
begin
  inherited;
end;

function TRTECrossLine.PostProcessing;
begin
  Result := true;
end;

procedure TMSURTECore.gInit;
begin
  CrossInitialization(MPR,SimpleRWRoutes);
end;

procedure TMSURTECore.gRead;
var
  i : Integer;
  RTECrossing : TRTECrossing;
begin
if RTECrossings.Count = 0 then Exit;
for i :=0 to RTECrossings.Count - 1 do
begin
    RTECrossing := TRTECrossing(RTECrossings.Objects[i]);
    if MPR_RWCrossings.List[i].HasButton then
    begin
      if Assigned(RTECrossing.A_G) then
        MPR_RWCrossings.List[i].A_G := not RTECrossing.A_G.Value;
      MPR_RWCrossings.List[I].btDwn := 0;
    end;//if MPR_RWCrossings.List[i].HasButton
    case MPR.RWCrossings[i].CrossingType  of
    1,2,3,4:
         begin
           if Assigned(RTECrossing._IN_L1) then
             MPR_RWCrossings.List[i]._IN_L1 := RTECrossing._IN_L1.Value;
           if Assigned(RTECrossing._FAULT_L1) then
             MPR_RWCrossings.List[i]._FAULT_L1 := RTECrossing._FAULT_L1.Value;
         end;//1,2,3,4
    end;
    case MPR.RWCrossings[I].CrossingType  of
    3,4:
      begin
        if MPR.RWCrossings[I].FenceIs = '1' then
        begin
          if Assigned(RTECrossing._FENCE_L1) then
            MPR_RWCrossings.List[i]._F_L1 := RTECrossing._FENCE_L1.Value;
        end
        else
        begin
          MPR_RWCrossings.List[i]._F_L1 := TRUE;
        end;
      end;
    6:
      begin
        if Assigned(RTECrossing._SIGNAL_L1) then
          MPR_RWCrossings.List[i]._SIGNAL_L1 := RTECrossing._SIGNAL_L1.Value;
        if Assigned(RTECrossing._CLOSE_L1) then
          MPR_RWCrossings.List[i]._CLOSE_L1 := RTECrossing._CLOSE_L1.Value;
        if Assigned(RTECrossing._OPEN_L1) then
          MPR_RWCrossings.List[i]._OPEN_L1 := RTECrossing._OPEN_L1.Value;
        if Assigned(RTECrossing._FENCE_L1) then
          MPR_RWCrossings.List[i]._F_L1 := RTECrossing._FENCE_L1.Value;
        if Assigned(RTECrossing._FUSEDLAMPS_L1) then
          MPR_RWCrossings.List[i]._FUSEDLAMPS_L1 := RTECrossing._FUSEDLAMPS_L1.Value;
        if Assigned(RTECrossing._PROPERLY_L1) then
          MPR_RWCrossings.List[i]._PROPERLY_L1 := RTECrossing._PROPERLY_L1.Value;
        if Assigned(RTECrossing._FAULT_L1) then
          MPR_RWCrossings.List[i]._FAULT_L1 := RTECrossing._FAULT_L1.Value;
      end;
    end;
end;//for i
end;


procedure TMSURTECore.gWrite;
var
  i,iB,j : Integer;
  RTECrossing : TRTECrossing;
  RTECrossLine : TRTECrossLine;
  RTETag : TRTETag;
begin
if RTECrossings.Count = 0 then Exit;
for i := 0 to RTECrossings.Count - 1 do
begin
  RTECrossing := TRTECrossing(RTECrossings.Objects[i]);
  if Assigned(RTECrossing.MainTag) then
    RTECrossing.MainTag.Value := MPR_RWCrossings.List[i].MainTag;
  gv.gDS_I := i;
  gDS;
  if Assigned(RTECrossing._DeviceState) then
    RTECrossing._DeviceState.Value := MPR_RWCrossings.List[i]._DeviceState;
  case MPR.RWCrossings[I].CrossingType  of
  2:
   begin
    if Assigned(RTECrossing._OUT) then
      RTECrossing._OUT.Value := MPR_RWCrossings.List[i]._OUT;
   end;//2
  3,4,6:
  begin
     try
       iB := StrToInt(MPR.RWCrossings[I].CloseSignal);
     except
       iB := 0;
     end;
     case iB of
     0:  //одним сигналом
       begin
         if Assigned(RTECrossing._OUT) then
            RTECrossing._OUT.Value := MPR_RWCrossings.List[i]._OUT;
       end;//0
     1: //двумя на переезд
      begin
        if Assigned(RTECrossing._EVEN_OUT) then
          RTECrossing._EVEN_OUT.Value := MPR_RWCrossings.List[i]._EVEN_OUT;
        if Assigned(RTECrossing._ODD_OUT) then
          RTECrossing._ODD_OUT.Value := MPR_RWCrossings.List[i]._ODD_OUT;
      end;//1
     end;//case iB
     if Assigned(RTECrossing._FAULT) then
     begin
        RTECrossing._FAULT.Value := MPR_RWCrossings.List[i]._FAULT;
     end;
     //лампы
     if MPR.RWCrossings[I].CrossingType = 6 then
     begin
      if Assigned(RTECrossing._PROPERLY) then
      begin
        RTECrossing._PROPERLY.Value := MPR_RWCrossings.List[i]._PROPERLY;
      end;
      if Assigned(RTECrossing._FUSEDLAMPS) then
      begin
        RTECrossing._FUSEDLAMPS.Value := MPR_RWCrossings.List[i]._FUSEDLAMPS;
      end;
     end;//if MPR.RWCrossings[I].CrossingType = 6
  end;//3,4,6
  end;//case MPR.RWCrossings[I].CrossingType
  IF RTECrossing.CrossSignals.Count > 0 Then
  begin
    if MPR_RWCrossings.List[i].HighCrossSignals > -1 then
    begin
      for j := 0 to RTECrossing.CrossSignals.Count - 1 do
      begin
        RTETag := TRTETag(RTECrossing.CrossSignals.Objects[j]);
        if not Assigned(RTETag) then continue;
          RTETag.Value := MPR_RWCrossings.List[i].CrossSignals[j]._OUT;
      end;//for j
    end;
  end; //IF RTECrossing.CrossSignals.Count > 0
end;//for i
//переездные линии
if RTECrossLines.Count = 0 then Exit;
for i := 0 to RTECrossLines.Count - 1 do
begin
  RTECrossLine := TRTECrossLine(RTECrossLines.Objects[i]);
  if not Assigned(RTECrossLine.Owner) then continue;
  if RTECrossLine.Owner.OutSignalsNumber = 2 then
  begin
    if Assigned(RTECrossLine._EVEN_OUT) then
      RTECrossLine._EVEN_OUT.Value := MPR_RWCrossLines.List[i].EvenCome AND MPR_RWCrossLines.List[i].sgnEvenCome;
    if Assigned(RTECrossLine._ODD_OUT) then
      RTECrossLine._ODD_OUT.Value := MPR_RWCrossLines.List[i].OddCome AND MPR_RWCrossLines.List[i].sgnOddCome;
  end;//if OutSignalsNumber = 2
end;//for i
end;


procedure TMSURTECore.sesRead;
var
  i, j : Integer;
  RTESysES : TRTESysES;
  RTEStativ_Fuse : TRTEStativ_Fuse;
begin
// массив предохранителей на стативах
if RTEStativ_Fuses.Count > 0 then
begin
    for i :=0 to RTEStativ_Fuses.Count - 1 do
    begin
      RTEStativ_Fuse := TRTEStativ_Fuse(RTEStativ_Fuses.Objects[i]);
      if Assigned(RTEStativ_Fuse.MainTag) then
        if Assigned(RTEStativ_Fuse._L1) then
        begin
          RTEStativ_Fuse.MainTag.Value := RTEStativ_Fuse._L1.Value;
          MPR_StativFuses.List[i].MainTag := RTEStativ_Fuse.MainTag.Value;
        end;
    end;
end;//if RTEStativ_Fuses.Count > 0
if RTESysESes.Count = 0 then Exit;
for i := 0 to RTESysESes.Count - 1 do
begin
  RTESysES := TRTESysES(RTESysESes.Objects[i]);
  if Assigned(RTESysES.RMB_BUTTON) then
    MPR_RWSESArray.List[i].RMB_BUTTON := NOT RTESysES.RMB_BUTTON.Value;
  if RTESysES.InversFiderControl = 1  then
  begin
    if Assigned(RTESysES.FIDER1_L1) then
      MPR_RWSESArray.List[i].FIDER1 := NOT RTESysES.FIDER1_L1.Value;
    if Assigned(RTESysES.FIDER2_L1) then
      MPR_RWSESArray.List[i].FIDER2 := NOT RTESysES.FIDER2_L1.Value;
  end
  else
  begin
    if Assigned(RTESysES.FIDER1_L1) then
      MPR_RWSESArray.List[i].FIDER1 := RTESysES.FIDER1_L1.Value;
    if Assigned(RTESysES.FIDER2_L1) then
      MPR_RWSESArray.List[i].FIDER2 := RTESysES.FIDER2_L1.Value;
  end;//if RTESysES.InversFiderControl = 1  then
  if RTESysES.FiderControl then
  begin
    if Assigned(RTESysES.FIDER1_IN_L1) then
      MPR_RWSESArray.List[i].FIDER1_IN := RTESysES.FIDER1_IN_L1.Value;
    if Assigned(RTESysES.FIDER2_IN_L1) then
      MPR_RWSESArray.List[i].FIDER2_IN := RTESysES.FIDER2_IN_L1.Value;
  end;
  //MPR_RWSESArray.List[0].AmperMeter := WORD_TO_INT(AmperMeter);');
  if Assigned(RTESysES.AmperMeter) then
    MPR_RWSESArray.List[i].rawAmperMeter := RTESysES.AmperMeter.Value;
  if RTESysES.StativFuses.Count > 0 then
  begin
    MPR_RWSESArray.List[i].FUSE := FALSE;
    for j := 0 to RTESysES.StativFuses.Count - 1 do
    begin
      RTEStativ_Fuse := TRTEStativ_Fuse(RTESysES.StativFuses.Objects[j]);
      if Assigned(RTEStativ_Fuse.MainTag) then
        MPR_RWSESArray.List[i].FUSE := MPR_RWSESArray.List[i].FUSE OR RTEStativ_Fuse.MainTag.Value;
    end;//for j
  end
  else
  begin
    if Assigned(RTESysES.FUSE_L1) then
      MPR_RWSESArray.List[i].FUSE := RTESysES.FUSE_L1.Value;
  end;//if RTESysES.StativFuses.Count > 0 then
  //параметры
  if Assigned(RMBDeadBandTime) then
    MPR_RWSESArray.List[i].RMBDeadBandTime := RMBDeadBandTime.Value
  else
    MPR_RWSESArray.List[i].RMBDeadBandTime := RMBDeadBandTime_DEF;
end;//for i
end;

procedure TMSURTECore.sesWrite;
var
  i : Integer;
  RTESysES : TRTESysES;
begin
if RTESysESes.Count = 0 then Exit;
for i := 0 to RTESysESes.Count - 1 do
begin
  RTESysES := TRTESysES(RTESysESes.Objects[i]);
  if Assigned(RTESysES.RMB_OUT) then
    RTESysES.RMB_OUT.Value := MPR_RWSESArray.List[i].RMB_OUT;
  if Assigned(RTESysES.FIDER1) then
    RTESysES.FIDER1.Value := MPR_RWSESArray.List[i].FIDER1;
  if Assigned(RTESysES.FIDER2) then
    RTESysES.FIDER2.Value := MPR_RWSESArray.List[i].FIDER2;
  if Assigned(RTESysES.FUSE) then
    RTESysES.FUSE.Value := MPR_RWSESArray.List[i].FUSE;
  if MPRCore.MPR.FiderControl then
  begin
    if Assigned(RTESysES.FIDER1_IN) then
      RTESysES.FIDER1_IN.Value := MPR_RWSESArray.List[i].FIDER1_IN;
    if Assigned(RTESysES.FIDER2_IN) then
      RTESysES.FIDER2_IN.Value := MPR_RWSESArray.List[i].FIDER2_IN;
  end;
  if Assigned(RTESysES.AmperMeter_Control) then
    RTESysES.AmperMeter_Control.Value := MPR_RWSESArray.List[i].realAmperMeter;
end;//for i
end;

procedure TMSURTECore.fInit;
var
  i,j,q : Integer;
  PRWFence : ^TRWFence;
begin
if Length(MPR.RWFences) = 0 then Exit;
SetLength(MPR_RWFences.List,Length(MPR.RWFences));
for i :=0 to High(MPR.RWFences) do
begin
    MPR_RWFences.List[i].IndexInGroup := MPR.RWFences[I].IndexInGroupe;
    MPR_RWFences.List[i].GroupIndex := MPR.RWFences[I].GroupIndex;
    MPR_RWFences.List[i].SctIdx := MPR.RWFences[I].SectionIndex;
    MPR_RWFences.List[i].HighFencePoints := Length(MPR.RWFences[I].FencePoints);
    MPR_RWFences.List[i].DSDelay := cnstDSDelay;
    MPR_RWFences.List[i].Prev := FALSE;
    if Length(MPR.RWFences[I].FencePoints) > 0 then
    begin
      SetLength(MPR_RWFences.List[i].AllFencePoints, Length(MPR.RWFences[I].FencePoints));
      for j := 0 to High(MPR.RWFences[I].FencePoints) do
      begin
        MPR_RWFences.List[i].AllFencePoints[j] := MPR.RWFences[I].FencePoints[J].Index;
      end;//for j
    end;
    MPR_RWFences.List[i].HighEvenFenceSolutions := MPR.RWFences[I].HighEvenFenceSolutions;
    if MPR.RWFences[I].HighEvenFenceSolutions > 0 then
    begin
      SetLength(MPR_RWFences.List[i].EvenFenceSolutions, MPR.RWFences[i].HighEvenFenceSolutions);
      for j := 0 to MPR.RWFences[I].HighEvenFenceSolutions - 1 do
      begin
        MPR_RWFences.List[i].EvenFenceSolutions[j].HighPoints := MPR.RWFences[I].EvenFenceSolutions[J].HighPoints;
        if MPR.RWFences[I].EvenFenceSolutions[J].HighPoints > 0 then
        begin
          SetLength(MPR_RWFences.List[i].EvenFenceSolutions[j].SolPoints,MPR.RWFences[I].EvenFenceSolutions[J].HighPoints);
          for q := 0 to MPR.RWFences[I].EvenFenceSolutions[J].HighPoints - 1 do
          begin
            MPR_RWFences.List[i].EvenFenceSolutions[j].SolPoints[q].PntIndex := MPR.RWFences[i].EvenFenceSolutions[j].SolPoints[q].PntIndex;
            MPR_RWFences.List[i].EvenFenceSolutions[j].SolPoints[q].PntEnState := MPR.RWFences[i].EvenFenceSolutions[j].SolPoints[q].PntEnState;
            MPR_RWFences.List[i].EvenFenceSolutions[j].SolPoints[q].PntDsState := MPR.RWFences[i].EvenFenceSolutions[j].SolPoints[q].PntDsState;
            //MPR_RWFences.List[i].EvenFenceSolutions[j].SolPoints[q].AFPPos := StrToInt64(MPR.RWFences[i].EvenFenceSolutions[j].SolPoints[q].AFPPos);
            MPR_RWFences.List[i].EvenFenceSolutions[j].SolPoints[q].MinusPos := PosToWord(MPR.RWFences[i].EvenFenceSolutions[j].SolPoints[q].MinusPos);
            MPR_RWFences.List[i].EvenFenceSolutions[j].SolPoints[q].PlusPos := PosToWord(MPR.RWFences[i].EvenFenceSolutions[j].SolPoints[q].PlusPos);
          end;//for q
        end;//if MPR.RWFences[I].EvenFenceSolutions[J].HighPoints > 0
      end;//for j
    end;//if MPR.RWFences[I].HighEvenFenceSolutions > 0
    MPR_RWFences.List[i].HighOddFenceSolutions := MPR.RWFences[i].HighOddFenceSolutions;
    if MPR.RWFences[I].HighOddFenceSolutions > 0 then
    begin
      SetLength(MPR_RWFences.List[i].OddFenceSolutions,MPR.RWFences[I].HighOddFenceSolutions);
      for j := 0 to MPR.RWFences[I].HighOddFenceSolutions - 1 do
      begin
        MPR_RWFences.List[i].OddFenceSolutions[j].HighPoints := MPR.RWFences[i].OddFenceSolutions[j].HighPoints;
        if MPR.RWFences[i].OddFenceSolutions[j].HighPoints > 0 then
        begin
          SetLength(MPR_RWFences.List[i].OddFenceSolutions[j].SolPoints, MPR.RWFences[i].OddFenceSolutions[j].HighPoints);
          for q := 0 to MPR.RWFences[i].OddFenceSolutions[j].HighPoints - 1 do
          begin
            MPR_RWFences.List[i].OddFenceSolutions[j].SolPoints[q].PntIndex := MPR.RWFences[i].OddFenceSolutions[j].SolPoints[q].PntIndex;
            MPR_RWFences.List[i].OddFenceSolutions[j].SolPoints[q].PntEnState := MPR.RWFences[i].OddFenceSolutions[j].SolPoints[q].PntEnState;
            MPR_RWFences.List[i].OddFenceSolutions[j].SolPoints[q].PntDsState := MPR.RWFences[i].OddFenceSolutions[j].SolPoints[q].PntDsState;
            //MPR_RWFences.List[i].OddFenceSolutions[j].SolPoints[q].AFPPos := StrToInt64(MPR.RWFences[i].OddFenceSolutions[j].SolPoints[q].AFPPos);
            MPR_RWFences.List[i].OddFenceSolutions[j].SolPoints[q].MinusPos := PosToWord(MPR.RWFences[i].OddFenceSolutions[j].SolPoints[q].MinusPos);
            MPR_RWFences.List[i].OddFenceSolutions[j].SolPoints[q].PlusPos := PosToWord(MPR.RWFences[i].OddFenceSolutions[j].SolPoints[q].PlusPos);
          end;//for q
        end;//if MPR.RWFences[i].OddFenceSolutions[j].HighPoints > 0
      end;//for j
    end;//if MPR.RWFences[I].HighOddFenceSolutions > 0
end;//for i
if MPR.RWFenceGroups.Count > 0 then
begin
  SetLength(MPR_RWFenceGroups.List, MPR.RWFenceGroups.Count);
  for i := 0 to MPR.RWFenceGroups.Count - 1 do
  begin
    MPR_RWFenceGroups.List[i].HighFences := MPR.RWFenceGroups[i].Members.Count;
    MPR_RWFenceGroups.List[i].FenceIndex := -1;
    if MPR.RWFenceGroups[i].Members.Count > 0 then
    begin
      SetLength(MPR_RWFenceGroups.List[i].Fences, MPR.RWFenceGroups[i].Members.Count);
      for j := 0 to MPR.RWFenceGroups[i].Members.Count - 1 do
      begin
        PRWFence := MPR.RWFenceGroups[I].Members[J];
        MPR_RWFenceGroups.List[i].Fences[j] := PRWFence^.IndexInArray;
      end;//for j
    end;//if MPR.RWFenceGroups[i].Members.Count > 0 then
  end;//for i
end;//if MPR.RWFenceGroups.Count > 0
end;

procedure TMSURTECore.fRead;
var
  i : Integer;
  RTEFence : TRTEFence;
begin
  if RTEFences.Count = 0 then Exit;
  for i :=0 to RTEFences.Count - 1 do
  begin
    RTEFence := TRTEFence(RTEFences.Objects[i]);
    if Assigned(RTEFence.MainTag) then
      MPR_RWFences.List[i].MainTag := RTEFence.MainTag.Value;
    if Assigned(RTEFence._IN) then
      MPR_RWFences.List[i]._IN := RTEFence._IN.Value;
  end;
end;

procedure TMSURTECore.fWrite;
var
  i : Integer;
  RTEFence : TRTEFence;
begin
  if RTEFences.Count = 0 then Exit;
  for i :=0 to RTEFences.Count - 1 do
  begin
    RTEFence := TRTEFence(RTEFences.Objects[i]);
    //BrokenPoints := ' + cMPR+'RWFences.List[I].BrokenPoints;');
    if Assigned(RTEFence._DA) then
      RTEFence._DA.Value := MPR_RWFences.List[i]._DA;
    if Assigned(RTEFence._PointsPlus) then
      RTEFence._PointsPlus.Value := MPR_RWFences.List[i].LPP;
    if Assigned(RTEFence._PointsMinus) then
      RTEFence._PointsMinus.Value := MPR_RWFences.List[i].LPM;
    if Assigned(RTEFence._DeviceState) then
      RTEFence._DeviceState.Value := MPR_RWFences.List[i]._DeviceState;
    if Assigned(RTEFence._AE) then
      RTEFence._AE.Value := MPR_RWFences.List[i]._AE;
    if Assigned(RTEFence._OUT) then
      RTEFence._OUT.Value := MPR_RWFences.List[i]._OUT;
  end;
end;

procedure TMSURTECore.zsRead;
var
  i : Integer;
  RTEZSSignal : TRTEZSSignal;
begin
  if RTEZSSignals.Count = 0 then Exit;
  for i := 0 to RTEZSSignals.Count - 1 do
  begin
    RTEZSSignal := TRTEZSSignal(RTEZSSignals.Objects[i]);
    if Assigned(RTEZSSignal._L1) then
      if Assigned(RTEZSSignal._Control) then
        RTEZSSignal._Control.Value := RTEZSSignal._L1.Value;
  end;//for i
end;

function TMSURTECore.PosToWord;
begin
Result := $0;
case APos of
  0: Result := $1;
  1: Result := $2;
  2: Result := $4;
  3: Result := $8;
  4: Result := $10;
  5: Result := $20;
  6: Result := $40;
  7: Result := $80;
  8: Result := $100;
  9: Result := $200;
  10:Result := $400;
  11:Result := $800;
  12:Result := $1000;
  13:Result := $2000;
  14:Result := $4000;
  15:Result := $8000;
end;
end;



procedure TMSURTECore.pabRead;
var
  i : Integer;
  RTEPAB : TRTEPAB;
begin
  if RTEPABs.Count > 0 then
    for i := 0 to RTEPABs.Count - 1 do
    begin
      RTEPAB := TRTEPAB(RTEPABs.Objects[i]);
      if Assigned(RTEPAB._DP) then
        MPR_RWSA.List[i]._DP := RTEPAB._DP.Value;
      if Assigned(RTEPAB._DS) then
        MPR_RWSA.List[i]._DS := RTEPAB._DS.Value;
      if Assigned(RTEPAB._IR) then
        MPR_RWSA.List[i]._IR := RTEPAB._IR.Value;
      if Assigned(RTEPAB._OS) then
        MPR_RWSA.List[i]._OS := RTEPAB._OS.Value;
      if Assigned(RTEPAB._PP_L1) then
        MPR_RWSA.List[i]._PP_L1 := RTEPAB._PP_L1.Value;
      if Assigned(RTEPAB._PP_L2) then
        MPR_RWSA.List[i]._PP_L2 := RTEPAB._PP_L2.Value;
    end;
end;

procedure TMSURTECore.pabWrite;
var
  i,j : Integer;
  RTEPAB : TRTEPAB;
  RouteCondition : boolean;
  RTERoute : TRTERoute;
  RTESignal : TRTESignal;
begin
  if RTEPABs.Count > 0 then
    for i := 0 to RTEPABs.Count - 1 do
    begin
      RTEPAB := TRTEPAB(RTEPABs.Objects[i]);
      if Assigned(RTEPAB._DP_OUT)  then
        RTEPAB._DP_OUT.Value := MPR_RWSA.List[i]._DP_OUT;
      if Assigned(RTEPAB._DS_OUT)  then
        RTEPAB._DS_OUT.Value := MPR_RWSA.List[i]._DS_OUT;
      if Assigned(RTEPAB._IR_OUT)  then
        RTEPAB._IR_OUT.Value := MPR_RWSA.List[i]._IR_OUT;
      if Assigned(RTEPAB._OS_OUT)  then
        RTEPAB._OS_OUT.Value := MPR_RWSA.List[i]._OS_OUT;
      if Assigned(RTEPAB._PP) then
        RTEPAB._PP.Value := MPR_RWSA.List[i]._PP;
      //ОКСР
      if Assigned(RTEPAB._OKSR_OUT) then
      begin
        if MPR_Params.SafeMode  then
        begin
          RTEPAB._OKSR_OUT.Value := FALSE;
        end
        else
        begin
          if RTEPAB.Variant = 1 then
          begin
            if Assigned(RTEPAB._OPER) then
            begin
              if (RTEPAB._OPER.Value = 1) then
                RTEPAB._OKSR_OUT.Value := TRUE
              else
                RTEPAB._OKSR_OUT.Value := FALSE;
            end
            else
            begin
              RTEPAB._OKSR_OUT.Value := FALSE;
            end;
          end
          else
          begin
            RouteCondition := false;
            if RTEPAB.RouteList.Count > 0 then
              for j := 0 to RTEPAB.RouteList.Count - 1 do
              begin
                RTERoute := TRTERoute(RTEPAB.RouteList.Objects[j]);
                if Assigned(RTERoute.FirstSignal) then
                begin
                  RTESignal := RTERoute.FirstSignal;
                  if Assigned(RTERoute.MainTag) AND Assigned(RTESignal.MainTag) then
                  begin
                    RouteCondition := RouteCondition OR ((RTERoute.MainTag.Value > 0) AND (RTESignal.MainTag.Value > 1))
                  end;
                end;
              end;//for j
            RTEPAB._OKSR_OUT.Value := RouteCondition;
          end;
        end; //if MPR_Params.SafeMode
      end;//if Assigned(RTEPAB._OKSR_OUT)
    end;
end;

procedure TMSURTECore.pabInit;
begin
  if Length(MPR.RWSA) = 0 then Exit;
  SetLength(MPR_RWSA.List,Length(MPR.RWSA));
end;

procedure TMSURTECore.pabDO;
var
  i : Integer;
begin
  if RTEPABs.Count > 0 then
    for i := 0 to RTEPABs.Count - 1 do
    begin
      gv.pabDo_I := i;
      PAB;
    end;//for i
end;

procedure TMSURTECore.CalcSafeMode;
begin
  if Assigned(StationView_StationCode) and Assigned(StationView_WatchDog) and Assigned(StationView_Connected) then
  begin
    if StationView_StationCode.Value > 0 then
    begin
      if SafeModeTimer > 70 then
      begin
        SafeModeTimer := 1;
        IF StationView_OldWatchDog = StationView_WatchDog.Value THEN
        begin
            StationView_Connected.Value := false;
        end
        ELSE
        begin
            StationView_Connected.Value := true;
        end;
        StationView_OldWatchDog := StationView_WatchDog.Value;
      end
      else
      begin
        inc(SafeModeTimer);
      end;
    end;
    MPR_Params.SafeMode := not StationView_Connected.Value;
  end;
end;

procedure TRTETag.LogValue(aOldValue: OleVariant; aNewValue: OleVariant);
var
  strOldValue, strNewValue : String;
begin
  if not Assigned(OwnedObject) then Exit;
  if not Assigned(OwnedObject.MPRCore) then Exit;
  if OwnedObject.MPRCore.MSURTESettings.TagLoggingOn  then
  begin
    if not Assigned(OwnedObject.MPRCore.RTETagLogger) then  Exit;
    try
      strOldValue := aOldValue;
      strNewValue := aNewValue;
      OwnedObject.MPRCore.RTETagLogger.LogEvent(Name + '=' + strOldValue + '->' + strNewValue);
    except
      Exit;
    end;
  end;
end;

procedure TMSURTECore.ppInit;
begin
  if MPR_Params.HighRWCrossPP = -1 then Exit;
  //установление размерности массива
  SetLength(MPR_RWCrossPP.List, MPR_Params.HighRWCrossPP + 1);
end;

procedure TMSURTECore.ppRead;
var
  RTECrossPP : TRTECrossPP;
  i : Integer;
begin
  if MPR_Params.HighRWCrossPP = -1 then Exit;
  for i := 0 to MPR_Params.HighRWCrossPP DO
  begin
    RTECrossPP := TRTECrossPP(RTECrossPPs.Objects[i]);
    if Assigned(RTECrossPP._L1) then
      MPR_RWCrossPP.List[i]._L1 := RTECrossPP._L1.Value;
    if MPR.LZEnabled then
    begin
      if MPR_Params.SPPType = 0  then
      begin
        if Assigned(ResetLZStage1Delay) then
          MPR_RWCrossPP.List[i].Stage1Delay := ResetLZStage1Delay.Value;
        if Assigned(ResetLZStage2Delay) then
          MPR_RWCrossPP.List[i].Stage2Delay := ResetLZStage2Delay.Value;
        if Assigned(ResetLZStage3Delay) then
          MPR_RWCrossPP.List[i].Stage3Delay := ResetLZStage3Delay.Value;
      end;
    end;//if MPR.LZEnabled
  end;//for i
end;

procedure TMSURTECore.ppDo;
begin

end;

procedure TMSURTECore.ppWrite;
var
  RTECrossPP : TRTECrossPP;
  i : Integer;
begin
  if MPR_Params.HighRWCrossPP = -1 then Exit;
  for i := 0 to MPR_Params.HighRWCrossPP DO
  begin
    RTECrossPP := TRTECrossPP(RTECrossPPs.Objects[i]);
    if Assigned(RTECrossPP._OUT) then
      RTECrossPP._OUT.Value := MPR_RWCrossPP.List[i]._OUT;
  end;//for i
end;

procedure TMSURTECore.asInit;
begin
  AddSignalsInitialization(MPR);
end;

{procedure TMSURTECore.asInit;
var
  i,j : Integer;
begin
  if MPR_Params.HighAddSignals = -1 then Exit;
  //установление размерности массива
  SetLength(MPR_AddSignals.List, MPR_Params.HighAddSignals + 1);
  for i := 0 to High(MPR.RW_Add_Signals) do
  begin
    MPR_AddSignals.List[i].SignalType := MPR.RW_Add_Signals[i].SignalType;
    MPR_AddSignals.List[i].SrcType := MPR.RW_Add_Signals[i].BasicSignalType;
    MPR_AddSignals.List[i].TimeCounter := 1;
    MPR_AddSignals.List[i].WOSrcSgn := true;
    MPR_AddSignals.List[i].SrcSgnIdx := -1;
    if MPR.RW_Add_Signals[i].BasicSignalCode <> '0' then
    begin
      if Length(MPR.RWSignals) > 0 then
      begin
        for j := 0 to High(MPR.RWSignals) do
        begin
          if MPR.RWSignals[j].Code = MPR.RW_Add_Signals[i].BasicSignalCode then
          begin
            MPR_AddSignals.List[i].WOSrcSgn := false;
            MPR_AddSignals.List[i].SrcSgnIdx := j;
            break;
          end;
        end;
      end;
    end;//if MPR.RW_Add_Signals[i].BasicSignalCode <> '0'
  end;//for i
end;  }

procedure TMSURTECore.asRead;
var
  i : Integer;
  RTEAddSignal : TRTEAddSignal;
begin
  if MPR_Params.HighAddSignals = -1 then Exit;
  for i := 0 to MPR_Params.HighAddSignals do
  begin
    RTEAddSignal := TRTEAddSignal(RTEAddSignals.Objects[i]);
    CASE MPR_AddSignals.List[I].SignalType OF
      1:
        begin
          if MPR_AddSignals.List[i].WOSrcSgn  then
          begin
            MPR_AddSignals.List[i]._PreventSignalsDelay := 1;
          end
          else
          begin
            MPR_AddSignals.List[i]._PreventSignalsDelay := MPR_Params.AddSignalDelay;
          end;
          if Assigned(RTEAddSignal._L1) then
            MPR_AddSignals.List[i]._L1 := RTEAddSignal._L1.Value;
          CASE MPR_AddSignals.List[I].SrcType OF
            2:
              begin
                if Assigned(RTEAddSignal._L2) then
                  MPR_AddSignals.List[i]._L2 := RTEAddSignal._L2.Value;
                end;
              end;
        end;//1
      2:
        begin
          if Assigned(RepeatSignalsDelay) then
            MPR_AddSignals.List[i]._RepeatSignalsDelay := RepeatSignalsDelay.Value;
          if Assigned(RTEAddSignal._L1) then
            MPR_AddSignals.List[i]._L1 := RTEAddSignal._L1.Value;
        end;//2
      6:
        begin
          if Assigned(RTEAddSignal.MainTag) then
            MPR_AddSignals.List[i].MainTag := RTEAddSignal.MainTag.Value;
        end;//6
    end;
  end;//for i
end;

procedure TMSURTECore.asWrite;
var
  i : Integer;
  RTEAddSignal : TRTEAddSignal;
begin
  if MPR_Params.HighAddSignals = -1 then Exit;
  for i := 0 to MPR_Params.HighAddSignals do
  begin
    RTEAddSignal := TRTEAddSignal(RTEAddSignals.Objects[i]);
    CASE MPR_AddSignals.List[I].SignalType OF
      1:
        begin
          if Assigned(RTEAddSignal.MainTag) then
            RTEAddSignal.MainTag.Value := MPR_AddSignals.List[i].MainTag;
          CASE MPR_AddSignals.List[I].SrcType OF
            2:
              begin
                gv.asCalcDS_I := I;
                asCalcDS();
                if Assigned(RTEAddSignal._DeviceState) then
                  RTEAddSignal._DeviceState.Value := MPR_AddSignals.List[i]._DeviceState;
                if RTEAddSignal.ControlMode = 0 then
                begin
                  if Assigned(RTEAddSignal._OUT1) then
                    RTEAddSignal._OUT1.Value := MPR_AddSignals.List[i]._OUT1;
                  if Assigned(RTEAddSignal._OUT2) then
                    RTEAddSignal._OUT2.Value := MPR_AddSignals.List[i]._OUT2;
                  if Assigned(RTEAddSignal._OUT3) then
                    RTEAddSignal._OUT3.Value := MPR_AddSignals.List[i]._OUT3;
                end;
              end;
          end;
        end;//1
      2:
        begin
          if Assigned(RTEAddSignal.MainTag) then
            RTEAddSignal.MainTag.Value := MPR_AddSignals.List[i].MainTag;
        end;//2
      6:
        begin
          if Assigned(RTEAddSignal._OUT) then
            RTEAddSignal._OUT.Value := MPR_AddSignals.List[i]._OUT;
        end;//6
    end;

  end;
end;

Constructor TRTESTP.Create(AMPRCore: TMSURTECore; ARWSTP: TRWSTP);
var
  tmpStr : String;
  spltArray, spltStr : TArray<string>;
  i, pntIdx : Integer;
  PointCode : string;
  RTEPoint : TRTEPoint;
begin
  inherited Create(AMPRCore);
  RWSTP := ARWSTP;
  Name := RWSTP.Code;
  tmpStr := RWSTP.PointsListText;
  if tmpStr.Equals(string.Empty) or tmpStr.Equals('0') then Exit;
  spltArray := tmpStr.Split(['@']);
  if Length(spltArray) = 0 then Exit;
  for i := 0 to High(spltArray) do
  begin
    spltStr := spltArray[i].Split([':']);
    if Length(spltStr) = 2 then
    begin
      PointCode := spltStr[0];
      if MPRCore.RTEPoints.Count > 0 then
      begin
        pntIdx := MPRCore.RTEPoints.IndexOf(PointCode);
        if pntIdx >= 0 then
        begin
          RTEPoint := TRTEPoint(MPRCore.RTEPoints.Objects[pntIdx]);
          if Assigned(RTEPoint.MainPoint) then
          begin
            RTEPoint.MainPoint.STPWhereInvolve.AddObject(Name,Self);
          end;
        end;
      end;
    end;
  end;//for i
end;

function TRTESTP.PostProcessing;
begin
  Result := true;
end;

function TMSURTECore.CreateSTPs;
var
  RTESTP : TRTESTP;
  i : Integer;
begin
  Result := false;
  if not Assigned(RTESTPs) then Exit;
  RTESTPs.Clear;
  if not Assigned(MPR) then Exit;
  if not MPRLoaded then Exit;
  if Length(MPR.RWSTPs) <= 0 then
  begin
    Result := true;
    Exit;
  end;
  RTESTP := nil;
  for i := 0 to High(MPR.RWSTPs) do
  begin
    try
      RTESTP := TRTESTP.Create(Self,MPR.RWSTPs[i]);
    except
      AppLogger.AddErrorMessage('СТП '+ MPR.RWSTPs[i].Caption +': сбой при создании объекта.');
      Exit;
    end;
    RTESTPs.AddObject(RTESTP.Name, RTESTP);
  end;
  Result := true;
end;

procedure TMSURTECore.connInit;
var
  i : Integer;
  RTEConnection : TRTEConnect;
begin
  {if RTEConnections.Count = 0 then Exit;
  SetLength(MPR_RWConnections.List,RTEConnections.Count);
  GlbConn.SETimeCounter := 1;
  GlbConn.oldSEConn := -3;
  GlbConn.vistgwTimeCounter := 1;
  GlbConn.oldvistgWatch := -3;
  for i := 0 to RTEConnections.Count - 1 do
  begin
    RTEConnection := TRTEConnect(RTEConnections.Objects[i]);
    MPR_RWConnections.List[i].FSGateway := RTEConnection.FSGateway;
    MPR_RWConnections.List[i].ConnCtrlTimer := 1;
    MPR_RWConnections.List[i].ConnWatchVal := -3;
  end; }
  ConnectionInitialization(MPR);
end;

procedure TMSURTECore.connRead;
var
  RTEConnection : TRTEConnect;
  i : Integer;
  lConnected, lMasterState : Boolean;
begin
  if RTEConnections.Count = 0 then Exit;
  if Assigned(SEConnected) then
    GlbConn.SEConn := SEConnected.Value;
  if Assigned(SEControl_TimeOut) then
    GlbConn.valSETimeOut := SEControl_TimeOut.Value;
  if Assigned(vistgw_watchdog) then
    GlbConn.vistgwWatch := vistgw_watchdog.Value;
  if Assigned(StationView_StationCode) then
    GlbConn.StV_StCode := StationView_StationCode.Value;
  if Assigned(StationView_WatchDog) then
    GlbConn.StV_WtchDog := StationView_WatchDog.Value;
  for i := 0 to RTEConnections.Count - 1 do
  begin
    RTEConnection := TRTEConnect(RTEConnections.Objects[i]);
    if Assigned(RTEConnection.MainTag) then
      MPR_RWConnections.List[i].MainTag := RTEConnection.MainTag.Value;
    if Assigned(RTEConnection._LET_EMULATE) then
      MPR_RWConnections.List[i]._LET_EMULATE := RTEConnection._LET_EMULATE.Value;
    if Assigned(RTEConnection._SL_EMULATE) then
      MPR_RWConnections.List[i]._SL_EMULATE := RTEConnection._SL_EMULATE.Value;
    if (MPR_Params.AllowFormatMessage = 1) and (MPR_RWConnections.List[i].FSGateway)  then
    begin
      if Assigned(ConnectionControlInterval) then
        MPR_RWConnections.List[i].ConnCtrlInt := ConnectionControlInterval.Value;
      if Assigned(RTEConnection._Watch) then
        MPR_RWConnections.List[i].ConnWatch := RTEConnection._Watch.Value;
    end
    else
    begin
      if Assigned(RTEConnection.ViewTagNameConnected) then
        MPR_RWConnections.List[i].ViewTagNameConnected := RTEConnection.ViewTagNameConnected.Value;
      if Assigned(RTEConnection.StationConnected) then
        MPR_RWConnections.List[i].StationConnected := RTEConnection.StationConnected.Value;
    end;
    if RTEConnection.OnFieldBus  then
    begin
      lConnected := false;
      if Assigned(RTEConnection.FieldBusConnected) then
      begin
        lConnected := RTEConnection.FieldBusConnected.Value;
      end;
      lMasterState := false;
      if Assigned(RTEConnection.MasterState) then
      begin
        lMasterState := RTEConnection.MasterState.Value;
      end;
      if lConnected AND lMasterState Then
        MPR_RWConnections.List[i].FieldBusConnected := 1
      else
        MPR_RWConnections.List[i].FieldBusConnected := 0;
    end
    else
    begin
      MPR_RWConnections.List[i].FieldBusConnected := 0;
    end;
  end;//for i
end;

procedure TMSURTECore.connWrite;
var
  i : Integer;
  RTEConnection : TRTEConnect;
begin
  if RTEConnections.Count = 0 then Exit;
  if Assigned(vistgw_Connected) then
      vistgw_Connected.Value := GlbConn.vistgw_Connected;
  if Assigned(StationView_Connected) then
    StationView_Connected.Value := GlbConn.StV_Conn;
  for i := 0 to RTEConnections.Count - 1 do
  begin
    RTEConnection := TRTEConnect(RTEConnections.Objects[i]);
    if Assigned(RTEConnection._SL) then
      RTEConnection._SL.Value := MPR_RWConnections.List[i]._SL;
    if Assigned(RTEConnection._EMULATE) then
      RTEConnection._EMULATE.Value := MPR_RWConnections.List[i]._EMULATE;
    if Assigned(RTEConnection.MasterState_OUT) then
      RTEConnection.MasterState_OUT.Value := TRUE;
    if Assigned(RTEConnection._SF) then
      RTEConnection._SF.Value := MPR_RWConnections.List[i].FieldBusConnected;
  end;
end;

Constructor TRTENode.Create(AMPRCore: TMSURTECore; ARWNode: TRWNode);
var
  NewTag : TRTETag;
begin
  inherited Create(AMPRCore);
  RWNode := ARWNode;
  Name := RWNode.Code;
  FCaption := RWNode.Caption;
  FNodeType := RWNode.NodeType;
  FInVisible := RWNode.NodeInVisible;
  _S := nil;
  _State := nil;
  if MPRCore.MPR.EssoLink = '1' then
  begin
    if not InVisible then
    begin
      case NodeType of
        4,5:
        begin
          //_State
          NewTag := TRTETag.Create('I' + Name + '_State', Self, VT_I2, 0);
          _State := NewTag;
          NewTag.TagServerTagEntry.IOReadOnly := true;
          NewTag.PLCTagEntry.Memory := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          MPRCore.sppIASymbols.AddObject(NewTag.Name, NewTag);
          //_S
          NewTag := TRTETag.Create('I' + Name + '_S', Self, VT_BSTR, string.Empty);
          _S := NewTag;
          NewTag.TagServerTagEntry.IOReadOnly := true;
          NewTag.PLCTagEntry.Memory := true;
          NewTag.IsOPCTag := true;
          MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
          MPRCore.sppIASymbols.AddObject(NewTag.Name, NewTag);
        end;//4,5
      end;//case
    end;//if not InVisible
  end;//if MPRCore.MPR.EssoLink = '1' then
end;

function TRTENode.PostProcessing;
begin
  Result := true;
end;

function TMSURTECore.CreateRTENodes;
var
  RTENode : TRTENode;
  i : Integer;
begin
  Result := false;
  RTENodes.Clear;
  if not Assigned(MPR) then Exit;
  if not MPRLoaded then Exit;
  if Length(MPR.RWNodes) <= 0 then Exit;
  for i := 0 to High(MPR.RWNodes) do
  begin
    try
      RTENode := TRTENode.Create(Self,MPR.RWNodes[i]);
      RTENodes.AddObject(RTENode.Name, RTENode);
    except
      AppLogger.AddErrorMessage('Вершина '+ MPR.RWNodes[i].Caption +': сбой при создании объекта.');
      Exit;
    end;
  end;
  Result := true;
end;

 function GetStrTypeDescription (AType : TVarType) : string;
 begin
  Result := 'Неизвестно';
   case AType of
    VT_BOOL : Result := 'BOOL';
    VT_BSTR : Result := 'STRING';
    VT_I2 : Result := 'INT16';
    VT_I4 : Result := 'INT32';
    VT_UI1 : Result := 'VT_UI1';
    VT_R4 : Result := 'REAL32';
    VT_R8 : Result := 'REAL64';
   end;
 end;

 function TMSURTECore.LoadUSO;
 var
   Slaves, Modules : TStringList;
   i,j,q : Integer;
   USO : TIniFile;
   ioArea : TioArea;
   tmpStr, tmpStr2, tagName : String;
   spltArr, spltArr2 : TArray<string>;
   nmContacts, nmSlave, nmModule, iaOffset, oaOffset : Integer;
   ContactOffset, tagIdx : Integer;
   RTESlave : TRTEPFBSlave;
   cntcCnt : Integer;
 begin
    Result := false;
    RTESlaves.Clear;
    if not FileExists(AUSOFile) then
    begin
      AppLogger.AddWarningMessage ('Файл '+ AUSOFile +' не существует!');
      Exit;
    end;
    try
      Slaves := TStringList.Create;
      Modules := TStringList.Create;
      USO := TIniFile.Create(AUSOFile);
      USO.ReadSection('Slaves',Slaves);
      if Slaves.Count > 0 then
      begin
        for i := 0 to Slaves.Count - 1 do
        begin
          try
            nmSlave := StrToInt(Slaves[i]);
            RTESlave := TRTEPFBSlave.Create(Self,nmSlave);
            RTESlaves.AddObject(RTESlave.Name, RTESlave);
          except
            continue;
          end;
          USO.ReadSection(Slaves[i],Modules);
          if Modules.Count > 0 then
          begin
            iaOffset := 0;
            oaOffset := 0;
            nmModule := 0;
            for j := 0 to Modules.Count - 1 do
            begin
              ContactOffset := 0;
              tmpStr := USO.ReadString(Slaves[i],Modules[j],string.Empty);
              if tmpStr.Equals(string.Empty) then continue;
              spltArr := tmpStr.Split([',']);
              if Length(spltArr) >= 4 then
              begin
                if spltArr[0] = '3' then
                begin
                  continue;
                end
                else
                begin
                  case MPRCore.MSURTESettings.PHL_NameMethod of
                    2:
                    begin
                      inc(nmModule);
                    end
                    else
                    begin
                      try
                        nmModule := StrToInt(Modules[j]);
                      except
                        continue;
                      end;
                    end;
                  end;
                end;//if spltArr[1] = '3' then
                if spltArr[1] = '1' then
                begin
                  //аналоговый модуль
                  //входы
                  try
                    nmContacts := StrToInt(spltArr[2]);
                  except
                    nmContacts := 2;
                  end;
                  ioArea := nil;
                  tmpStr2 := Slaves[i] + '.' + Modules[j];
                  for cntcCnt := 0 to nmContacts - 1 do
                  begin
                    ioArea := TAioWord.Create(string.Empty,RTESlave,VT_UI2,0,nmModule,iaOffset,false);
                    RTESlave.ioAreas.AddObject(ioArea.Name,ioArea);
                    tmpStr := USO.ReadString(tmpStr2,IntToStr(cntcCnt),string.Empty);
                    if tmpStr.Equals(string.Empty) then continue;
                    spltArr2 := tmpStr.Split([',']);
                    if Length(spltArr2) >= 1 then
                    begin
                      tagName := spltArr2[0];
                      tagIdx := IASymbols.IndexOf(tagName);
                      if tagIdx > -1 then
                      begin
                        ioArea.Bits[0] := TRTETag(IASymbols.Objects[tagIdx]);
                        TRTETag(IASymbols.Objects[tagIdx]).Description := spltArr2[1].Trim();
                      end;
                    end;
                    case MPRCore.MSURTESettings.PHL_CardVendor of
                      0,2,3: //SST
                      begin
                        iaOffset := iaOffset + 1;
                      end;
                      1: //SIEMENS
                      begin
                        iaOffset := iaOffset + 2;
                      end;
                    end;//case
                  end;//for
                end
                else
                begin
                  //входы
                  try
                    nmContacts := StrToInt(spltArr[2]);
                  except
                    nmContacts := 0;
                  end;
                  ioArea := nil;
                  if nmContacts > 8 then
                  begin
                    ioArea := TioWord.Create(string.Empty,RTESlave,VT_UI2,0,nmModule,iaOffset,false);
                    if MPRCore.MSURTESettings.PHL_ModuleNameMethod = 1 then
                      iaOffset := iaOffset + 1;
                  end
                  else
                    if nmContacts > 0 then
                    begin
                      ioArea:= TioByte.Create(string.Empty,RTESlave,VT_UI1,0,nmModule,iaOffset,false);
                      if MPRCore.MSURTESettings.PHL_ModuleNameMethod = 1 then
                        inc(iaOffset);
                    end;
                  if Assigned(ioArea) then
                  begin
                    RTESlave.ioAreas.AddObject(ioArea.Name,ioArea);
                    //заполнение массивов битов
                    tmpStr2 := Slaves[i] + '.' + Modules[j];
                    for q := 0 to High(ioArea.Bits) do
                    begin
                      tmpStr := USO.ReadString(tmpStr2,IntToStr(ContactOffset + q),string.Empty);
                      if tmpStr.Equals(string.Empty) then continue;
                      spltArr2 := tmpStr.Split([',']);
                      if Length(spltArr2) >= 1 then
                      begin
                        tagName := spltArr2[0];
                        tagIdx := IASymbols.IndexOf(tagName);
                        if tagIdx > -1 then
                        begin
                          ioArea.Bits[q] := TRTETag(IASymbols.Objects[tagIdx]);
                          TRTETag(IASymbols.Objects[tagIdx]).Description := spltArr2[1].Trim();
                        end
                        else
                        begin
                          //создание тэга из USO-файла
                          //тэг создается только при наличии поля №2 и значения в нем "1"
                           if Length(spltArr2) >= 3 then
                           begin
                              if (spltArr2[2] = '1') then
                              begin
                                ioArea.Bits[q] := CreateUSOTag(tagName,VT_BOOL,FALSE);
                                TRTETag(ioArea.Bits[q]).OPCWritable := false;
                                TRTETag(ioArea.Bits[q]).Description := spltArr2[1].Trim();
                                if Assigned(ioArea.Bits[q]) then
                                begin
                                  if not MSURTESettings.IsEmulation  then
                                    IASymbols.AddObject(TRTETag(ioArea.Bits[q]).Name, TRTETag(ioArea.Bits[q]));
                                end;
                              end;
                           end;
                        end;
                      end; //if Length(spltArr2) >= 1 then
                    end;//for q
                    ContactOffset := High(ioArea.Bits) + 1;
                  end;
                  //выходы
                  try
                    nmContacts := StrToInt(spltArr[3]);
                  except
                    nmContacts := 0;
                  end;
                  ioArea := nil;
                  if nmContacts > 8 then
                  begin
                    ioArea := TioWord.Create(string.Empty,RTESlave,VT_UI2,0,nmModule,oaOffset,true);
                    if MPRCore.MSURTESettings.PHL_ModuleNameMethod = 1 then
                      oaOffset := oaOffset + 2;
                  end
                  else
                    if nmContacts > 0 then
                    begin
                      ioArea:= TioByte.Create(string.Empty,RTESlave,VT_UI1,0,nmModule,oaOffset,true);
                      if MPRCore.MSURTESettings.PHL_ModuleNameMethod = 1 then
                        inc(oaOffset);
                    end;
                  if Assigned(ioArea) then
                  begin
                    RTESlave.ioAreas.AddObject(ioArea.Name,ioArea);
                    //заполнение массивов битов
                    tmpStr2 := Slaves[i] + '.' + Modules[j];
                    for q := 0 to High(ioArea.Bits) do
                    begin
                      tmpStr := USO.ReadString(tmpStr2,IntToStr(ContactOffset + q),string.Empty);
                      if tmpStr.Equals(string.Empty) then continue;
                      spltArr2 := tmpStr.Split([',']);
                      if Length(spltArr2) >= 1 then
                      begin
                        tagName := spltArr2[0];
                        tagIdx := OASymbols.IndexOf(tagName);
                        if tagIdx > -1 then
                        begin
                          ioArea.Bits[q] := TRTETag(OASymbols.Objects[tagIdx]);
                          TRTETag(OASymbols.Objects[tagIdx]).Description := spltArr2[1].Trim();
                        end
                        else
                        begin
                          if Length(spltArr2) >= 7 then
                          begin
                            if spltArr2[5] = '1' Then
                            begin
                              ListSignalDoubles.Add(tagName + '=' + spltArr2[6]);
                              ioArea.Bits[q] := CreateUSOTag(tagName,VT_BOOL,FALSE);
                              TRTETag(ioArea.Bits[q]).Description := spltArr2[1].Trim();
                              if Assigned(ioArea.Bits[q]) then
                              begin
                                if not MSURTESettings.IsEmulation  then
                                  OASymbols.AddObject(TRTETag(ioArea.Bits[q]).Name, TRTETag(ioArea.Bits[q]));
                              end;//if Assigned(ioArea.Bits[q])
                            end;//if spltArr2[5] = '1' Then
                          end;//if Length(spltArr2) >= 7 then
                          //создание тэга из USO-файла
                          //тэг создается только при наличии поля №2 и значения в нем "1"
                          if Length(spltArr2) >= 3 then
                          begin
                              if (spltArr2[2] = '1') then
                              begin
                                ioArea.Bits[q] := CreateUSOTag(tagName,VT_BOOL,FALSE);
                                TRTETag(ioArea.Bits[q]).Description := spltArr2[1].Trim();
                                if Assigned(ioArea.Bits[q]) then
                                begin
                                  if not MSURTESettings.IsEmulation  then
                                    OASymbols.AddObject(TRTETag(ioArea.Bits[q]).Name, TRTETag(ioArea.Bits[q]));
                                end;//if Assigned(ioArea.Bits[q])
                              end;//if (spltArr2[2] = '1') then
                          end;//if Length(spltArr2) >= 3
                        end;//if tagIdx > -1 then
                      end; //if Length(spltArr2) >= 1 then
                    end;//for q
                  end;
                end; //модуль аналоговый/дискретный if spltArr[1] = '1' then
              end;
            end;//for j
          end;//if Modules.Count > 0 then
        end; //for i
      end;//if Slaves.Count > 0
      USO.Free;
      Slaves.Free;
      Modules.Free;
      Result := true;
    except
      AppLogger.AddErrorMessage('Ошибка структуры файла '+ AUSOFile + '!');
      Slaves.Free;
      USO.Free;
      Modules.Free;
    end;
 end;

 Constructor TioArea.Create;
 begin
    inherited Create(string.Empty,AHost,AType,AIniValue);
    MPRCore := nil;
    if Assigned(AHost) then
      MPRCore := AHost.MPRCore;
    Slave := nil;
    if Assigned(AHost) then
      if AHost.ClassType = TRTEPFBSlave then
        Slave := TRTEPFBSlave(AHost);
    Module := AModule;
    Offset := AOffset;
    isOutput := AOut;
    if AOut then
      AreaLitera := 'Q'
    else
      AreaLitera := 'I';
    FValue := 0;
 end;

 Constructor TioByte.Create;
 begin
    inherited Create(TagName,AHost,AType,AIniValue,AModule,AOffset,AOut);
    SetLength(Bits,8);
    Name := GetAreaName;
 end;

 Constructor TioWord.Create;
 begin
    inherited Create(TagName,AHost,AType,AIniValue,AModule,AOffset,AOut);
    SetLength(Bits,16);
    Name := GetAreaName;
 end;

 function TioByte.GetAreaName;
 begin
    Result := string.Empty;
    if not Assigned(Slave) then Exit;
    case MPRCore.MSURTESettings.PHL_CardVendor of
      0: //SST
      begin
        Result := Slave.GetSlaveStr + 'M' + IntToStr(Module - 1) + AreaLitera + 'X' + IntToStr(Offset);
      end;//0
      1: //SIEMENS
      begin
        case MPRCore.MSURTESettings.PHL_ModuleNameMethod of
          1:
            begin
              Result := Slave.GetSlaveStr + '_' + AreaLitera + 'B' + IntToStr(Offset);
            end//1
            else
            begin
              Result := Slave.GetSlaveStr + 'M' + GetModuleNumberStr + '_' + AreaLitera + 'B' + IntToStr(Offset);
            end;
          end;//case
      end;//1
      2:
      begin
         case MPRCore.MSURTESettings.PHL_NameMethod of
          2:
          begin
            Result := MPRCore.MSURTESettings.PHL_CardName + '.' + AreaLitera + IntToStr(Slave.nmSlave) + '_' + IntToStr(Module) + '_' + IntToStr(Offset);
          end
          else
          begin
            Result := Slave.GetSlaveStr + '_' + AreaLitera + 'B_S' + IntToStr(Slave.nmSlave) + '_M' + IntToStr(Module - 1) + '_' + IntToStr(Offset);
          end;
         end;
      end;
      3://InControl
      begin
        Result := 'N_' + AreaLitera + 'B_S' + IntToStr(Slave.nmSlave) + '_M' + IntToStr(Module - 1) + '_' + IntToStr(Offset);
      end;
    end;//case
 end;

 function TioWord.GetAreaName;
 begin
    Result := string.Empty;
    if not Assigned(Slave) then Exit;
     case MPRCore.MSURTESettings.PHL_CardVendor of
      0: //SST
      begin
        Result := Slave.GetSlaveStr + 'M' + IntToStr(Module - 1) + AreaLitera + 'W' + IntToStr(Offset);
      end;//0
      1: //SIEMENS
      begin
        case MPRCore.MSURTESettings.PHL_ModuleNameMethod of
        1:
          begin
            Result := Slave.GetSlaveStr + '_' + AreaLitera + 'W' + IntToStr(Offset);
          end
          else
          begin
            Result := Slave.GetSlaveStr + 'M' + GetModuleNumberStr + '_' + AreaLitera + 'W' + IntToStr(Offset);
          end;
        end;//case
      end;//1
      2:
      begin
        case MPRCore.MSURTESettings.PHL_NameMethod of
          2:
          begin
            Result := MPRCore.MSURTESettings.PHL_CardName + '.' + AreaLitera + IntToStr(Slave.nmSlave) + '_' + IntToStr(Module) + '_' + IntToStr(Offset);
          end
          else
          begin
            Result := Slave.GetSlaveStr + '_' + AreaLitera + 'W_S' + IntToStr(Slave.nmSlave) + '_M' + IntToStr(Module - 1) + '_' + IntToStr(Offset);
          end;
        end;
      end;
      3: //InControl
      begin
        Result := 'N_' + AreaLitera + 'W_S' + IntToStr(Slave.nmSlave) + '_M' + IntToStr(Module - 1) + '_' + IntToStr(Offset);
      end;
     end;//case
 end;

 function TRTEPFBSlave.GetSiemensSlaveStr;
 begin
    if nmSlave >= 100 then
      Result := IntToStr(nmSlave)
    else
      if nmSlave >= 10 then
        Result := '0' + IntToStr(nmSlave)
      else
        Result := '00' + IntToStr(nmSlave);
 end;

 Constructor TRTEPFBSlave.Create;
 var
    NewTag : TRTETag;
    TagType : TVarType;
    valIni : OleVariant;
 begin
   inherited Create(AMPRCore);
   nmSlave := ASlvNumber;
   Name := 'Slave_' + IntToStr(nmSlave);
   _Status := nil;
   _State := nil;
   NewTag := TRTETag.Create(Name + '_Status', Self, VT_I2, 0);
   _Status := NewTag;
   NewTag.IsOPCTag := true;
   NewTag.OPCWritable := false;
   MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
   if MPRCore.MSURTESettings.IsEmulation  then
    MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
   //физический сигнал контроля состояния
   case MPRCore.MSURTESettings.PHL_CardVendor of
    0 : //SST
    begin
      TagType := VT_UI1;
      valIni := 0;
    end;//0
    1 : //Siemens
    begin
      TagType := VT_BSTR;
      valIni := 'BAD';
    end//1
    else
    begin
      TagType := VT_I2;
      valIni := 0;
    end;
   end;//case
   NewTag := TRTETag.Create(Name + '_State', Self, TagType, valIni);
   _State := NewTag;
   NewTag.IsOPCTag := true;
   NewTag.OPCWritable := false;
   case MPRCore.MSURTESettings.PHL_CardVendor of
   0 : //SST
    begin
      NewTag.OPCItemName := GetSlaveStr + 'Status'
    end;//0
    1 : //Siemens
    begin
     NewTag.OPCItemName := GetSlaveStr + 'SlvState';
    end;
    2: //SST 32 - bit
    begin
      case MPRCore.MSURTESettings.PHL_NameMethod of
        2:
        begin
          NewTag.OPCItemName := GetSlaveStr + '_Status';
        end
        else
        begin
          NewTag.OPCItemName := GetSlaveStr + '_IB_S' + IntToStr(nmSlave) +  '_STS';
        end;
      end;
    end;
    3: //InControl
    begin
      NewTag.OPCItemName := 'N_IB_S' + IntToStr(nmSlave) +  '_STS';
    end
    else
    begin
      NewTag.OPCItemName := Name;
    end;
   end;//case
   MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
   if not MPRCore.MSURTESettings.IsEmulation  then
    MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
   ioAreas := TStringList.Create(true);
 end;

 Destructor TRTEPFBSlave.Destroy;
 begin
  if Assigned(ioAreas) then
  begin
    ioAreas.Free;
    ioAreas := nil;
  end;
  inherited;
 end;

 function TRTEPFBSlave.GetSlaveStr;
 begin
  Result := string.Empty;
  if not Assigned(MPRCore) then Exit;
  case MPRCore.MSURTESettings.PHL_CardVendor of
    0 : //SST
    begin
       Result := 'SLAVE_' + IntToStr(nmSlave) + '.';
    end;//0
    1 : //Siemens
    begin
      Result := 'DP:[' + MPRCore.MSURTESettings.PHL_CardName + ']Slave' + GetSiemensSlaveStr;
    end; //1
    2: //SST 32 - bit
    begin
      case MPRCore.MSURTESettings.PHL_NameMethod of
        2:
        begin
           Result := MPRCore.MSURTESettings.PHL_CardName + '.Slave_' + IntToStr(nmSlave);
        end
        else
        begin
          Result := MPRCore.MSURTESettings.PHL_CardName + '.N';
        end;
      end;
    end;
    3: //InControl
    begin
      Result := 'N';
    end;
  end;//case
 end;

 procedure TMSURTECore.pfbInit;
 var
    i : Integer;
 begin
  //установление размерности массивов
  SetLength(PFBSlaves.List, MPR_Params.HighPFBSlaves + 1);
  if MPR_Params.HighPFBSlaves = -1 then Exit;
  for i := 0 to MPR_Params.HighPFBSlaves do
  begin
    PFBSlaves.List[i]._Status := 0;
    PFBSlaves.List[i]._Status_send := FALSE;
    PFBSlaves.List[i].nmSlave := TRTEPFBSlave(RTESlaves.Objects[i]).nmSlave;
    PFBSlaves.List[i].cntScn := 4;
  end;
  //связанные глобальные переменные
  GlbTags.PLC_ErSt := 0;
  GlbTags.oldPLC_ErSt := -2;
  GlbTags.PLC_Slv := 0;
  GlbTags.oldPLC_Slv := -2;
  GlbTags.cntPLC_ErSt := 4;
 end;

 procedure TMSURTECore.pfbRead;
 var
    i : Integer;
 begin
    if MPR_Params.HighPFBSlaves = -1 then Exit;
    if RTESlaves.Count = 0 then Exit;
    if not MPRCore.MSURTESettings.IsEmulation  then
    begin
      for i := 0 to MPR_Params.HighPFBSlaves do
      begin
        if Assigned(TRTEPFBSlave(RTESlaves.Objects[i])._State) then
        begin
          case MPRCore.MSURTESettings.PHL_CardVendor of
            0,2,3 : //SST
            begin
              if Assigned(TRTEPFBSlave(RTESlaves.Objects[i])._Status) then
                TRTEPFBSlave(RTESlaves.Objects[i])._Status.Value := TRTEPFBSlave(RTESlaves.Objects[i])._State.Value;
            end;//0
            1: //SIEMENS
            begin
              if string(TRTEPFBSlave(RTESlaves.Objects[i])._State.Value).Equals('READY') then
              begin
                if Assigned(TRTEPFBSlave(RTESlaves.Objects[i])._Status) then
                  TRTEPFBSlave(RTESlaves.Objects[i])._Status.Value := 128;
              end
              else
              begin
                if Assigned(TRTEPFBSlave(RTESlaves.Objects[i])._Status) then
                  TRTEPFBSlave(RTESlaves.Objects[i])._Status.Value := 0;
              end;
            end;//1
          end;//case
        end;
      end;
    end;
    for i := 0 to MPR_Params.HighPFBSlaves do
    begin
      if Assigned(RTESlaves.Objects[i]) then
      begin
        PFBSlaves.List[i]._Status := TRTEPFBSlave(RTESlaves.Objects[i])._Status.Value;
      end;
    end;//for i
 end;

procedure TMSURTECore.pfbWrite;
begin
  if MPR_Params.HighPFBSlaves = -1 then Exit;
   if Assigned(StationPLC_Slave) then
      StationPLC_Slave.Value := GlbTags.PLC_Slv;
  if Assigned(StationPLC_ErrorStatus) then
      StationPLC_ErrorStatus.Value := GlbTags.PLC_ErSt;
end;

procedure TioArea.DirectSetValue(aRawValue: OleVariant);
var
  oldValue : OleVariant;
  i : Integer;
  RTETag : TRTETag;
  lcWORD : WORD;
  lcRes : WORD;
begin
  oldValue := FValue;
  FValue := aRawValue;
  Changed := true;
  if Length(Bits) = 0 then Exit;
  //только для входных тэгов
  //выходные формируются не по изменениям
  if isOutput then Exit;
  lcWORD := FValue;
  for i := 0 to High(Bits) do
  begin
    RTETag := Bits[i];
    if not Assigned(RTETag) then
    begin
      lcWORD := lcWORD shr 1;
      continue;
    end;
    if RTETag.TagType <> VT_BOOL then Exit;
    lcRes := lcWORD and 1;
    case lcRes of
    0: RTETag.Value := FALSE;
    1: RTETag.Value := TRUE;
    end;
    lcWORD := lcWORD shr 1;
  end;
end;

procedure TioArea.AssemblyOutputBits;
var
  i : Integer;
  RTETag : TRTETag;
  lcWORD : WORD;
  tgVl : Boolean;
begin
  lcWORD := 0;
  if Length(Bits) = 0 then Exit;
  //только для выходных тэгов
  //входные формируются сами по изменениям
  if not isOutput then Exit;
  for i := High(Bits) downto 0 do
  begin
    RTETag := Bits[i];
    if Assigned(RTETag) then
    begin
      if RTETag.TagType <> VT_BOOL then Exit;
      tgVl := RTETag.Value;
    end
    else
    begin
      tgVl := false;
    end;
    lcWORD := lcWORD shl 1;
    if tgVl then
    begin
      lcWORD := lcWORD OR 1;
    end
  end;
  Value := lcWORD;
end;

procedure TRTEPFBSlave.AssemblyOutputBits;
var
  i : Integer;
begin
  if not Assigned(ioAreas) then  Exit;
  if ioAreas.Count > 0 then
    for i := 0 to ioAreas.Count - 1 do
    begin
      TioArea(ioAreas.Objects[i]).AssemblyOutputBits;
    end;
end;

function TRTEPFBSlave.PostProcessing;
begin
  Result := true;
end;

function TioArea.GetModuleNumberStr;
var
  nmMdl : Integer;
begin
  Result := string.Empty;
  nmMdl := Module - 1;
  if nmMdl < 0 then Exit;
  if nmMdl >= 10 then
    Result := IntToStr(nmMdl)
  else
    Result := '0' + IntToStr(nmMdl);
 end;

 Constructor TAioWord.Create;
 begin
    inherited Create(TagName,AHost,AType,AIniValue,AModule,AOffset,AOut);
    SetLength(Bits,1);
    Name := GetAreaName;
 end;

 procedure TAioWord.DirectSetValue(aRawValue: OleVariant);
 begin
    FValue := aRawValue;
    if Assigned(Bits[0]) then
    begin
      TRTETag(Bits[0]).Value := FValue;
    end;
 end;

 function TAioWord.GetAreaName;
 begin
    Result := string.Empty;
    if not Assigned(Slave) then Exit;
    case MPRCore.MSURTESettings.PHL_CardVendor of
      0: //SST
      begin
        Result := Slave.GetSlaveStr + 'M' + IntToStr(Module - 1) + AreaLitera + 'W' + IntToStr(Offset);
      end;//0
      1: //SIEMENS
      begin
        case MPRCore.MSURTESettings.PHL_ModuleNameMethod of
        1:
          begin
            Result := Slave.GetSlaveStr + '_' + AreaLitera + 'W' + IntToStr(Offset);
          end
          else
          begin
            Result := Slave.GetSlaveStr + 'M' + GetModuleNumberStr + '_' + AreaLitera + 'W' + IntToStr(Offset);
          end;
        end;//case
      end;//1
      2: //SST 32-bit
      begin
         case MPRCore.MSURTESettings.PHL_NameMethod of
          2:
          begin
            Result := MPRCore.MSURTESettings.PHL_CardName + '.' + AreaLitera + IntToStr(Slave.nmSlave) + '_' + IntToStr(Module) + '_' + IntToStr(Offset);
          end
          else
          begin
            Result := Slave.GetSlaveStr + '_' + AreaLitera + 'W_S' + IntToStr(Slave.nmSlave) + '_M' + IntToStr(Module - 1) + '_' + IntToStr(Offset);
          end;
         end;
      end;
      3: //InControl
      begin
        Result := 'N_' + AreaLitera + 'W_S' + IntToStr(Slave.nmSlave) + '_M' + IntToStr(Module - 1) + '_' + IntToStr(Offset);
      end;
    end;//case
 end;
procedure TioArea.SetTagsAsPhisicalVaue;
var
  i : Integer;
begin
  if Length(Bits) = 0 then Exit;
  for i := 0 to High(Bits) do
  begin
    if not Assigned(Bits[i]) then continue;
    if not TRTETag(Bits[i]).forCstApps  then
      TRTETag(Bits[i]).PhisicalValue := true;
  end;//for
end;

Constructor TRTEExtApp.Create(AMPRCore: TMSURTECore; AExAppIniFile: string);
begin
  inherited Create(AMPRCore);
  ExAppIniFile := AExAppIniFile;
end;

Constructor TRTEExAppDusting.Create(AName : String; AMPRCore: TMSURTECore; AExAppIniFile: string);
var
  DustingIni : TIniFile;
  RelaysSection : TStringList;
  i,j : Integer;
  NewTag : TRTETag;
  CurrentItem : string;
  spltArr : TArray<string>;
begin
  inherited Create (AMPRCore,AExAppIniFile);
  Name := AName;
  if not Assigned(MPRCore) then Exit;
  if not FileExists(ExAppIniFile) then Exit;
  DustingIni := TIniFile.Create(ExAppIniFile);
  RelaysSection := TStringList.Create;
  try
    DustingIni.ReadSection('Relays',RelaysSection);
    if (RelaysSection.Count > 0) then
    begin
      for i := 0 to RelaysSection.Count - 1 do
      begin
        NewTag := TRTETag.Create('D' + MPRCore.MPR.StationCode + '_RelayV' + RelaysSection[i] + '_OUT', Self, VT_BOOL, false);
        NewTag.IsOPCTag := true;
        NewTag.PLCTagEntry.Phisical := true;
        NewTag.forCstApps := true;
        MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
        MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
        NewTag := TRTETag.Create('D' + MPRCore.MPR.StationCode + '_RelayV' + RelaysSection[i] + '_IN', Self, VT_BOOL, false);
        NewTag.IsOPCTag := true;
        NewTag.PLCTagEntry.Phisical := true;
        NewTag.forCstApps := true;
        MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
        MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
        CurrentItem := DustingIni.ReadString('Relays',RelaysSection[i],string.Empty);
        if not CurrentItem.Equals (string.Empty) then
        begin
          spltArr := CurrentItem.Split([',']);
          if Length(spltArr) > 0 then
          begin
            for j := 0 to Length(spltArr) - 1 do
            begin
              NewTag := TRTETag.Create('P' + spltArr[j] + '_OUT_EPK', Self, VT_BOOL, false);
              NewTag.IsOPCTag := true;
              NewTag.PLCTagEntry.Phisical := true;
              NewTag.forCstApps := true;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
            end;//for j
          end;
        end;
      end;//for i
    end;
  finally
    if Assigned(RelaysSection) then
    begin
      RelaysSection.Free;
      RelaysSection := nil;
    end;
    if Assigned(DustingIni) then
    begin
      DustingIni.Free;
      DustingIni:= nil;
    end;
  end;
end;

function TMSURTECore.CreateExternalApps;
var
  ExAppsPath, IniPath : string;
  Dusting : TRTEExAppDusting;
  Heating : TRTEExAppHeating;
  Sprinkler : TRTEExAppSprinkler;
begin
  Result := false;
  ExAppsPath := TPath.GetDirectoryName(MSURTESettings.MPRFile) + '\Apps\';
  if DirectoryExists(ExAppsPath) then
  begin
    //полив
    IniPath := ExAppsPath + 'sprinkler.ini';
    if (FileExists(IniPath)) then
    begin
        Sprinkler := TRTEExAppSprinkler.Create('sprinkler',Self,IniPath);
        RTEExtApps.AddObject(Sprinkler.Name,Sprinkler);
    end;
    //обдув
    IniPath := ExAppsPath + 'dusting.ini';
    if (FileExists(IniPath)) then
    begin
        Dusting := TRTEExAppDusting.Create ('Dusting',Self,IniPath);
        RTEExtApps.AddObject(Dusting.Name,Dusting);
    end;
    //обогрев
    IniPath := ExAppsPath + 'heating.ini';
    if (FileExists(IniPath)) then
    begin
        Heating := TRTEExAppHeating.Create('Heating',Self,IniPath);
        RTEExtApps.AddObject(Heating.Name,Heating);
    end;
  end;//if
  Result := true;
end;

Constructor TRTEExAppHeating.Create(AName: string; AMPRCore: TMSURTECore; AExAppIniFile: string);
var
  NewTag : TRTETag;
  HeatingIni : TIniFile;
  CurrentItem : string;
  spltArr : TArray<string>;
  j : Integer;
begin
  inherited Create (AMPRCore,AExAppIniFile);
  Name := AName;
  if not Assigned(MPRCore) then Exit;
  if not FileExists(ExAppIniFile) then Exit;
  NewTag := TRTETag.Create('H' + MPRCore.MPR.StationCode + '_RelayH_OUT', Self, VT_BOOL, false);
  NewTag.IsOPCTag := true;
  NewTag.PLCTagEntry.Phisical := true;
  NewTag.forCstApps := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
  if not FileExists(ExAppIniFile) then Exit;
  HeatingIni := TIniFile.Create(ExAppIniFile);
  try
      CurrentItem := HeatingIni.ReadString('settings','cases',string.Empty);
      if not CurrentItem.Equals(string.Empty) then
      begin
        spltArr := CurrentItem.Split([',']);
        if Length(spltArr) > 0 then
        begin
            for j := 0 to Length(spltArr) - 1 do
            begin
              NewTag := TRTETag.Create('H' + MPRCore.MPR.StationCode + '_' + spltArr[j] + '_I_L1', Self, VT_BOOL, false);
              NewTag.IsOPCTag := true;
              NewTag.PLCTagEntry.Phisical := true;
              NewTag.forCstApps := true;
              //NewTag.OPCWritable := false;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
              NewTag := TRTETag.Create('H' + MPRCore.MPR.StationCode + '_' + spltArr[j] + '_H_L1', Self, VT_BOOL, false);
              NewTag.IsOPCTag := true;
              NewTag.PLCTagEntry.Phisical := true;
              NewTag.forCstApps := true;
              //NewTag.OPCWritable := false;
              MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
              MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
            end;//for j
        end;
      end;
  finally
    if Assigned(HeatingIni) then
    begin
      HeatingIni.Free;
      HeatingIni := nil;
    end;
  end;
end;

Constructor TRTEExAppPZ.Create(AName: string; AMPRCore: TMSURTECore; AExAppIniFile: string);
var
  NewTag : TRTETag;
  PZini : TIniFile;
  SignalsSection : TStringList;
  i : Integer;
begin
  inherited Create (AMPRCore,AExAppIniFile);
  Name := AName;
  if not Assigned(MPRCore) then Exit;
  if not FileExists(ExAppIniFile) then Exit;
  PZini := TIniFile.Create(ExAppIniFile);
  SignalsSection := TStringList.Create;
  try
    PZini.ReadSection('Signals',SignalsSection);
    if SignalsSection.Count > 0 then
    begin
      for i := 0 to SignalsSection.Count - 1 do
      begin
        NewTag := TRTETag.Create(SignalsSection[i], Self, VT_BOOL, false);
        NewTag.IsOPCTag := true;
        NewTag.PLCTagEntry.Phisical := true;
        NewTag.forCstApps := true;
        NewTag.TagServerTagEntry.IOReadOnly := true;
        MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
      end;//for i
    end;
  finally
    if Assigned(PZini) then
    begin
      PZini.Free;
      PZini := nil;
    end;
    if Assigned(SignalsSection) then
    begin
      SignalsSection.Free;
      SignalsSection := nil;
    end;
  end;
end;

Constructor TRTEExAppSprinkler.Create(AName: string; AMPRCore: TMSURTECore; AExAppIniFile: string);
var
  NewTag : TRTETag;
begin
  inherited Create (AMPRCore,AExAppIniFile);
  Name := AName;
  if not Assigned(MPRCore) then Exit;
  if not FileExists(ExAppIniFile) then Exit;
  NewTag := TRTETag.Create('T' + MPRCore.MPR.StationCode + '_SPRON_L1', Self, VT_BOOL, false);
  NewTag.IsOPCTag := true;
  NewTag.PLCTagEntry.Phisical := true;
  NewTag.forCstApps := true;
  NewTag.OPCWritable := false;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
  NewTag := TRTETag.Create('T' + MPRCore.MPR.StationCode + '_SPROFF_L1', Self, VT_BOOL, false);
  NewTag.IsOPCTag := true;
  NewTag.PLCTagEntry.Phisical := true;
  NewTag.forCstApps := true;
  NewTag.OPCWritable := false;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  MPRCore.IASymbols.AddObject(NewTag.Name, NewTag);
  NewTag := TRTETag.Create('T' + MPRCore.MPR.StationCode + '_SPRON_OUT', Self, VT_BOOL, false);
  NewTag.IsOPCTag := true;
  NewTag.PLCTagEntry.Phisical := true;
  NewTag.forCstApps := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
  NewTag := TRTETag.Create('T' + MPRCore.MPR.StationCode + '_SPROFF_OUT', Self, VT_BOOL, false);
  NewTag.IsOPCTag := true;
  NewTag.PLCTagEntry.Phisical := true;
  NewTag.forCstApps := true;
  MPRCore.GlobalTags.AddObject(NewTag.Name, NewTag);
  MPRCore.OASymbols.AddObject(NewTag.Name, NewTag);
end;

function TMSURTECore.CreateUSOTag;
begin
  Result := TRTETag.Create(AtagName, Self, VT_BOOL, false);
  Result.PLCTagEntry.Phisical := true;
  Result.IsOPCTag := true;
  Result.forCstApps := true;
  GlobalTags.AddObject(Result.Name, Result);
end;

procedure TMSURTECore.PLC_WatchDog;
begin
  if not Assigned(WatchDogCycle) then Exit;
  if not Assigned(StationPLC_WatchDog) then Exit;
  if PLC_WatchDogTimeCounter >= WatchDogCycle.Value then
  begin
    if StationPLC_WatchDog.Value  >= 100 then
    begin
        StationPLC_WatchDog.Value := 0;
    end
    else
    begin
        StationPLC_WatchDog.Value := StationPLC_WatchDog.Value + 1;
    end;
    PLC_WatchDogTimeCounter := 1;
  end
  else
  begin
    PLC_WatchDogTimeCounter := PLC_WatchDogTimeCounter + 1;
  end;
end;

procedure TMSURTECore.TS_WatchDog;
begin
  if not Assigned(WatchDogCycle) then Exit;
  if not Assigned(StationTagServer_WatchDog) then Exit;
  if TS_WatchDogTimeCounter >= WatchDogCycle.Value then
  begin
    if StationTagServer_WatchDog.Value  >= 100 then
    begin
        StationTagServer_WatchDog.Value := 0;
    end
    else
    begin
        StationTagServer_WatchDog.Value := StationTagServer_WatchDog.Value + 1;
    end;
    TS_WatchDogTimeCounter := 1;
  end
  else
  begin
    TS_WatchDogTimeCounter := TS_WatchDogTimeCounter + 1;
  end;
end;

function TMSURTECore.BOS_WatchDog;
begin
  Result := false;
  if not Assigned(WatchDogCycle) then Exit;
  if not Assigned(BusOPCServer_WatchDog) then Exit;
  if BOS_WatchDogTimeCounter >= WatchDogCycle.Value then
  begin
    BOS_WatchDogTimeCounter := 1;
    Result := true;
  end
  else
  begin
    BOS_WatchDogTimeCounter := BOS_WatchDogTimeCounter + 1;
  end;
end;

procedure  TMSURTECore.IncBOS_WatchDog;
begin
  if BusOPCServer_WatchDog.Value >= 100 then
  begin
    BusOPCServer_WatchDog.Value := 0;
  end
  else
  begin
    BusOPCServer_WatchDog.Value := BusOPCServer_WatchDog.Value + 1;
  end;
end;

procedure TRTETag.SetQuality(qValue: Word);
begin
  if qValue <> FQuality then
  begin
    case qValue of
     OPC_QUALITY_GOOD:
      begin
        FQuality := qValue;
        //Value := LastValue;
      end;//OPC_QUALITY_GOOD
     else
      begin
        LastValue := FValue;
        Value := InitialValue;
        FQuality := qValue;
      end;//else
    end;//case
  end;
end;

function TMSURTECore.CreateConnections;
var
  OneRTEConn : TRTEConnect;
  i : Integer;
begin
  Result := false;
  RTEConnections.Clear;
  if not Assigned(MPR) then Exit;
  if not MPRLoaded then Exit;
  if Length(MPR.RWConnections) <= 0 then Exit;
  OneRTEConn := nil;
  for i := 0 to High(MPR.RWConnections) do
  begin
    try
      OneRTEConn := TRTEConnect.Create(Self,i);
      RTEConnections.AddObject(OneRTEConn.Name, OneRTEConn);
    except
      AppLogger.AddErrorMessage('Соединение '+ MPR.RWConnections[i].Code +': сбой при создании объекта.');
      Exit;
    end;
  end;//for i
  Result := True;
end;

procedure TMSURTECore.qdblInit;
var
  i, idxTag : Integer;
  destTagName, srcTagName : string;
  destTag, srcTag : TRTETag;
begin
  SomeDoubles := false;
  if not Assigned(ListSignalDoubles) then Exit;
  if ListSignalDoubles.Count = 0 then Exit;
  SetLength(srcDoubles,ListSignalDoubles.Count);
  SetLength(dstDoubles,ListSignalDoubles.Count);
  SomeDoubles := true;
  for i := 0 to ListSignalDoubles.Count - 1 do
  begin
    destTagName := ListSignalDoubles.Names[i];
    srcTagName := ListSignalDoubles.ValueFromIndex[i];
    idxTag := GlobalTags.IndexOf(srcTagName);
    if idxTag > -1 then
    begin
      srcTag := TRTETag(GlobalTags.Objects[idxTag]);
    end;
    idxTag := GlobalTags.IndexOf(destTagName);
    if idxTag > -1 then
    begin
      destTag := TRTETag(GlobalTags.Objects[idxTag]);
    end;
    if Assigned(srcTag) then
    begin
      srcDoubles[i] := srcTag;
    end
    else
    begin
      srcDoubles[i] := nil;
    end;
    if Assigned(destTag) then
    begin
      dstDoubles[i] := destTag;
    end
    else
    begin
      dstDoubles[i] := nil;
    end;
  end;//for i
end;

procedure TMSURTECore.qdblWrite;
var
  i : Integer;
  destTag, srcTag : TRTETag;
begin
  if not SomeDoubles then Exit;
  if Length(srcDoubles) = 0 then Exit;
  if Length(dstDoubles) = 0 then Exit;
  for i := 0 to High(srcDoubles) do
  begin
    srcTag := srcDoubles[i];
    destTag := dstDoubles[i];
    if Assigned(srcTag) and Assigned(destTag) then
    begin
      destTag.Value := srcTag.Value;
    end;
  end;//for i
end;

end.
