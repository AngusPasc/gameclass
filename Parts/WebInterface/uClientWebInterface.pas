unit uClientWebInterface;

interface

uses
  Classes,
  cefvcl,
  ceflib,
  Forms,
  StrUtils,
  Vcl.Controls,
  System.Rtti,
  windows,
  uMyWebBrowser,
  uWebServer;

type
  TParceAndReplaceLine = procedure (Sender: TObject; var sBuf:String) of object;
  TNoParamsProcedure = procedure (Sender: TObject) of object;
  TActionLogon  = procedure (Sender: TObject;sLogin,sPassword,sSecCode:string) of object;
  TActionQueryCostTime = procedure (Sender: TObject;sTariff,sSumm:string) of object;
  TActionChangeTariff = procedure (Sender: TObject;sTariff:string) of object;
  TActionStartSession = procedure (Sender: TObject;sTariff,sSumm:string) of object;
  TActionQueryAddTimeCost = procedure (Sender: TObject;sSumm:string) of object;
  TActionAddMoney = procedure (Sender: TObject;sSumm:string) of object;
  TActionQueryAddTrafficCost = procedure (Sender: TObject;sSumm:string) of object;
  TActionAddTraffic = procedure (Sender: TObject;sSumm:string) of object;
  TActionUnblock = procedure (Sender: TObject;Code:string) of object;
  TActionChangePassword = procedure (Sender: TObject;OldPassword,NewPassword:string) of object;
  TWebInterface = class
    private
      _MyWebBrowser :TMyWebBrowser;
      _MyWebServer:TMyWebServer;
      _Parent:TWinControl;

      FstrTarifName : string;
      FfSum: Double;
      FfAddTimeSum: Double;

    protected
      procedure SetTarifName(const AstrTarifName: String);
      procedure SetSum(const AfSum: Double);
      procedure SetAddTimeSum(const AfAddTimeSum: Double);

    public
      Port:Integer;
      IndexFile:string;
      SkinPath:string;
      ParceAndReplaceLine : TParceAndReplaceLine;

      ExecuteClient:TExecuteClientEvent;

      ActionLogon:TActionLogon;
      ActionQueryCostTime:TActionQueryCostTime;
      ActionChangeTariff:TActionChangeTariff;
      ActionStartSession:TActionStartSession;
      ActionQueryAddTimeCost:TActionQueryAddTimeCost;
      ActionAddMoney:TActionAddMoney;
      ActionQueryAddTrafficCost:TActionQueryAddTrafficCost;
      ActionAddTraffic:TActionAddTraffic;
      ActionUnblock:TActionUnblock;
      ActionLogoff:TNoParamsProcedure;
      ActionStopSession:TNoParamsProcedure;
      ActionAgreeEula:TNoParamsProcedure;
      ActionNotAgreeEula:TNoParamsProcedure;
      ActionChangePassword:TActionChangePassword;
      ActionGetTariffs:TNoParamsProcedure;
      ActionLoadComplete:TNoParamsProcedure;
      ActionSysLogoff:TNoParamsProcedure;
      ActionSysReboot:TNoParamsProcedure;
      ActionSysShutdown:TNoParamsProcedure;


      constructor Create (Parent:TWinControl);

      // ��� ������
      property TarifName: String
        read FstrTarifName write SetTarifName;
      property Sum: Double
        read FfSum write SetSum;
      property AddTimeSum: Double
        read FfAddTimeSum write SetAddTimeSum;

      procedure ShowDevTools;
      procedure ReloadSkin();
      procedure ShowUnblock();
      procedure HideUnblock();

      procedure ShowChangePassword();
      procedure HideChangePassword();

      procedure ShowMessages(msg:string);
      procedure SetClientState(state:integer);
      procedure SetInterfaceData(str: string);


      procedure Start;
      procedure DoJsCommand(Command:string);

      function ExecuteClientEvent (Sender: TObject; Request:HttpRequest):boolean;
      function PrepareFile (Sender: TObject; FilePath:String): TMemoryStream;



    end;

implementation

uses
  SysUtils;

procedure TWebInterface.DoJsCommand(Command: string);
begin
  _MyWebBrowser.ExecuteJavaScript(Command);
end;

function TWebInterface.ExecuteClientEvent(Sender: TObject;
  Request: HttpRequest): boolean;
begin
  if Request.Parametrs.Values['action'] = 'logon' then
    if Assigned(ActionLogon) then
      ActionLogon(Sender, Request.Parametrs.Values['login'],
                Request.Parametrs.Values['password'],
                Request.Parametrs.Values['seccode']);
  if Request.Parametrs.Values['action'] = 'querytimecost' then
    begin
      FfSum := StrToFloatDef(Request.Parametrs.Values['money'],0);
      if Assigned(ActionQueryCostTime) then
        ActionQueryCostTime(Sender,
                Request.Parametrs.Values['tariff'],
                Request.Parametrs.Values['money']);
    end;
  if Request.Parametrs.Values['action'] = 'changetariff' then
    begin
      FstrTarifName := Request.Parametrs.Values['tariff'];
      if Assigned(ActionChangeTariff) then
        ActionChangeTariff(Sender, Request.Parametrs.Values['tariff']);
    end;
  // ����� ������
  if Request.Parametrs.Values['action'] = 'start_session' then
    if Assigned(ActionStartSession) then
      ActionStartSession(Sender,
                Request.Parametrs.Values['tariff'],
                Request.Parametrs.Values['money']);
  //������ ���-�� ���. ������� �� ��������� �����
  if Request.Parametrs.Values['action'] = 'queryaddtimecost' then
    begin
      FfAddTimeSum := StrToFloatDef(Request.Parametrs.Values['money'],0);
      if Assigned(ActionQueryAddTimeCost) then
        ActionQueryAddTimeCost(Sender, Request.Parametrs.Values['money']);
    end;
  //�������� ������ � ������� ������
  if Request.Parametrs.Values['action'] = 'addmoney' then
    if Assigned(ActionAddMoney) then
      ActionAddMoney(Sender,
                Request.Parametrs.Values['money']);
  //������ ��������� ���. �������
  if Request.Parametrs.Values['action'] = 'queryaddtrafficcost' then
    if Assigned(ActionQueryAddTrafficCost) then
      ActionQueryAddTrafficCost(Sender,
                Request.Parametrs.Values['money']);
  //��������� ������
  if Request.Parametrs.Values['action'] = 'addtraffic' then
    if Assigned(ActionAddTraffic) then
      ActionAddTraffic(Sender,
                Request.Parametrs.Values['money']);
  // ������
  if Request.Parametrs.Values['action'] = 'logoff' then
    if Assigned(ActionLogoff) then ActionLogoff(Sender);
  // ��������� ������
  if Request.Parametrs.Values['action'] = 'stop_session' then
    if Assigned(ActionStopSession) then ActionStopSession(Sender);
  //��������� ����������
  if Request.Parametrs.Values['action'] = 'accept_eula' then
    if Assigned(ActionAgreeEula) then ActionAgreeEula(Sender);
  //����� �� ����������
  if Request.Parametrs.Values['action'] = 'no_accept_eula' then
    if Assigned(ActionNotAgreeEula) then ActionNotAgreeEula(Sender);
  //������ ������ �������������
  if Request.Parametrs.Values['action'] = 'unblock' then
    if Assigned(ActionUnblock) then
      ActionUnblock(Sender, Request.Parametrs.Values['unblock_code']);
  //����� ������
  if Request.Parametrs.Values['action'] = 'change_password' then
    if Assigned(ActionChangePassword) then
      ActionChangePassword(Sender,
                Request.Parametrs.Values['old_password'],
                Request.Parametrs.Values['new_password']);
  //������ �� ���������� �������
  if Request.Parametrs.Values['action'] = 'get_tariffs' then
    if Assigned(ActionGetTariffs) then ActionGetTariffs(Sender);
  //���������� web-���������� ���������
  if Request.Parametrs.Values['action'] = 'load_complete' then
    if Assigned(ActionLoadComplete) then ActionLoadComplete(Sender);
  // ������ �� ����� �� �������
  if Request.Parametrs.Values['action'] = 'sys_logoff' then
    if Assigned(ActionSysLogoff) then ActionSysLogoff(Sender);
  // ������ �� ������������
  if Request.Parametrs.Values['action'] = 'sys_reboot' then
    if Assigned(ActionSysReboot) then ActionSysReboot(Sender);
  // ������ �� ����������
  if Request.Parametrs.Values['action'] = 'sys_shutdown' then
    if Assigned(ActionSysShutdown) then ActionSysShutdown(Sender);

  if Assigned(ExecuteClient) then
    Result := ExecuteClient(Sender,Request)
  else
    Result := True;
end;

procedure TWebInterface.ShowUnblock;
begin
  _MyWebBrowser.ExecuteJavaScript('show_unblock_window();');
end;

procedure TWebInterface.HideUnblock;
begin
  _MyWebBrowser.ExecuteJavaScript('hide_unblock_window();');
end;

function TWebInterface.PrepareFile(Sender: TObject;
  FilePath: String): TMemoryStream;
var
  msResultFile: TMemoryStream;
  sFileType: AnsiString;
  fFile: TextFile;
  sBuf:AnsiString;
  ssBuf:string;
  _Out_buff:array [0..5000] of ansichar;
  iBufSize:integer;
begin
  msResultFile := TMemoryStream.Create;
  sFileType := AnsiString(UpperCase(ExtractFileExt(FilePath)));
  if (sFileType='.HTM')
    or (sFileType='.HTML')
    or (sFileType='.CSS')
    or (sFileType='.JS') then
  begin
    AssignFile (fFile,FilePath);
    Reset(fFile);
    While not EOF(fFile)do
    begin
      readln(fFile,sBuf);
      if Assigned(ParceAndReplaceLine) then
      begin
        ssBuf := string(sBuf);
        ParceAndReplaceLine(Self,ssBuf);
        sBuf := AnsiString(ssBuf);
      end;
      StrPCopy(_Out_buff, sBuf);
      iBufSize := Length(sBuf);
      _Out_buff[iBufSize] := #10;
      msResultFile.WriteBuffer(_Out_buff,iBufSize + 1);
    end;
    CloseFile(fFile);
    msResultFile.Seek(0,soBeginning);
  end else begin
    msResultFile.LoadFromFile(FilePath);
  end;
  Result := msResultFile;
end;

procedure TWebInterface.ReloadSkin;
begin
  _MyWebBrowser.Reload;
end;

constructor TWebInterface.Create(Parent: TWinControl);
begin
  inherited Create();
  _Parent := Parent;
  IndexFile := 'main.html';
  Port := 5068;
  SkinPath := ExtractFilePath(Application.ExeName) +  'Skins\new';
end;


procedure TWebInterface.SetAddTimeSum(const AfAddTimeSum: Double);
begin
  FfAddTimeSum := AfAddTimeSum;
  SetInterfaceData('{ "add_money": "' + FloatToStr(FfAddTimeSum) +'" }');

end;

procedure TWebInterface.SetClientState(state: integer);
begin
  _MyWebBrowser.ExecuteJavaScript('gcclient_set_state('+IntToStr(state)+');');
end;

procedure TWebInterface.SetInterfaceData(str: string);
var
  buffer :string;
begin
  buffer := ReplaceStr(str,#$D#$A,'<br>');
  _MyWebBrowser.ExecuteJavaScript('update_info(' + buffer + ');');
end;
procedure TWebInterface.SetSum(const AfSum: Double);
begin
  FfSum := AfSum;
  SetInterfaceData('{ "booking_money": "' + FloatToStr(FfSum) +'" }');
end;

procedure TWebInterface.SetTarifName(const AstrTarifName: String);
begin
  FstrTarifName := AstrTarifName;
  SetInterfaceData('{ "select_tariff": "' + AstrTarifName +'" }');
end;

procedure TWebInterface.ShowChangePassword;
begin
  _MyWebBrowser.ExecuteJavaScript('show_change_password_window();');
end;

procedure TWebInterface.HideChangePassword;
begin
  _MyWebBrowser.ExecuteJavaScript('hide_change_password_window();');
end;

procedure TWebInterface.ShowDevTools;
begin
  _MyWebBrowser.ShowDevTools;
end;

procedure TWebInterface.ShowMessages(msg: string);
begin
  _MyWebBrowser.ExecuteJavaScript('show_messages(''' + msg + ''');');
end;

procedure TWebInterface.Start;
begin
  _MyWebServer := TMyWebServer.Create;
  _MyWebServer.RootFolder := SkinPath;
  _MyWebServer.Port := Port;
  _MyWebServer.ExecuteClientEvent := ExecuteClientEvent;
  _MyWebServer.PrepareFileEvent := PrepareFile;
  _MyWebServer.start;
  _MyWebBrowser := TMyWebBrowser.Create(_Parent,'http://127.0.0.1:'
                                        + IntToStr(Port)
                                        + '/' + IndexFile );
end;



end.
