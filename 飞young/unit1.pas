unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, DCPrc4, DCPbase64, md5, Forms, Controls, Graphics,
  Dialogs, StdCtrls, IniFiles, fphttpclient, RegExpr;

type

  { TForm1 }

  TForm1 = class(TForm)
    btnClick2Login: TButton;
    btnClick2Logoff: TButton;
    DCP_rc4_1: TDCP_rc4;
    edtAuthKey: TEdit;
    edtDeviceInfo: TEdit;
    edtPassword: TEdit;
    edtUsername: TEdit;
    grpInfo: TGroupBox;
    grpAuthConfig: TGroupBox;
    grpLoginInfoConfig: TGroupBox;
    lblInfo: TLabel;
    lblAuthKey: TLabel;
    lblMachineCode: TLabel;
    lblPassword: TLabel;
    lblUsername: TLabel;
    procedure btnClick2LoginClick(Sender: TObject);
    procedure btnClick2LogoffClick(Sender: TObject);
    procedure edtAuthKeyChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    function getTodayOfMonth():Integer;
    function encryptPassword(password:string):string;
    function encryptAuthAttr(infostr:string):string;
    // 根据所给的分隔符生成随机MAC地址(小写)
    function randomMAC(Separator: String): string;
    procedure getRedirectURL(base_url:string);
    procedure getLoginINFO();
    procedure loginAction(username:string; password:string);
    procedure logoffAction(logoff_url:string);
    procedure showInfoFromINI(filename:string);
    procedure updateINI(filename:string);
    function verifyKey(key:string):Boolean;
  private
    redirectURL: string;
    loginURL: string;
    aidcAuthAttr15: string;
    loginINFO: string;
    logoffURL: string;
    logoffINFO: string;
    ipaddr: string;
    macaddr: string;
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.btnClick2LoginClick(Sender: TObject);
begin
  if verifyKey(self.edtAuthKey.Text) then
    begin
      if (self.edtUsername.Text<>'') and (self.edtPassword.Text<>'') then
        loginAction(self.edtUsername.Text, self.edtPassword.Text)
      else
        begin
          self.lblInfo.Caption:='请输入账号和密码';
          Exit;
        end;
      self.lblInfo.Caption:=self.loginINFO;
    end
  else
    self.lblInfo.Caption:='授权失败';

  updateINI('config.ini');
end;

procedure TForm1.btnClick2LogoffClick(Sender: TObject);
begin
  if Length(self.logoffURL)<>0 then
    begin
      logoffAction(self.logoffURL);
      if Length(self.logoffINFO)<>0 then
        self.lblInfo.Caption := self.logoffINFO
      else
        self.lblInfo.Caption := '登出失败';
    end
  else
    self.lblInfo.Caption := '登出失败';
end;

procedure TForm1.edtAuthKeyChange(Sender: TObject);
begin
  if verifyKey(self.edtAuthKey.Text) then
    begin
      self.btnClick2Login.Enabled:=True;
      self.btnClick2Logoff.Enabled:=True;
    end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  showInfoFromINI('config.ini');
end;

function TForm1.getTodayOfMonth(): Integer;
var
  YY,MM,DD : Word;
begin
  DeCodeDate (Date,YY,MM,DD);
  Result := DD;
end;

function TForm1.randomMAC(Separator: String): String;
var Symbol: PChar;
    MAC: String;
    I: Integer;
begin
    Randomize;
    MAC := '';
    Symbol := '0123456789abcdef';
    if Separator = '' then
    begin
        for I := 0 to 11 do
            MAC := MAC + Symbol[Random(16)];
    end
    else if (Separator = '-') Or (Separator = ':') then
    begin
        for I := 0 to 11 do
        begin
            if (I > 0) And (I mod 2 = 0) then
            begin
                MAC := MAC + Separator + Symbol[Random(16)];
            end
            else
                MAC := MAC + Symbol[Random(16)];
        end;
    end
    else if Separator = '.' then
        for I := 0 to 11 do
        begin
            if (I > 0) And (I mod 4 = 0) then
            begin
                MAC := MAC + Separator + Symbol[Random(16)];
            end
            else
                MAC := MAC + Symbol[Random(16)];
        end;
    Result := MAC;
end;

function TForm1.encryptPassword(password: string): string;
const
  day_key: array[1..31,1..10] of byte = (
    ($01,$04,$03,$00,$07,$08,$02,$06,$05,$09),
    ($00,$02,$06,$07,$08,$05,$04,$03,$01,$09),
    ($09,$01,$07,$03,$02,$06,$08,$00,$04,$05),
    ($03,$04,$00,$01,$09,$07,$08,$05,$06,$02),
    ($08,$01,$07,$04,$00,$06,$09,$03,$02,$05),
    ($08,$00,$07,$06,$01,$04,$02,$05,$03,$09),
    ($08,$09,$05,$07,$06,$01,$02,$04,$00,$03),
    ($04,$05,$07,$03,$08,$01,$09,$06,$00,$02),
    ($03,$08,$02,$09,$05,$00,$07,$04,$06,$01),
    ($09,$03,$05,$06,$00,$07,$08,$02,$04,$01),
    ($04,$07,$09,$01,$02,$05,$00,$03,$06,$08),
    ($06,$07,$02,$01,$08,$09,$05,$03,$04,$00),
    ($01,$09,$03,$08,$05,$06,$07,$02,$00,$04),
    ($04,$01,$09,$05,$07,$06,$08,$00,$02,$03),
    ($02,$05,$00,$08,$04,$07,$09,$03,$01,$06),
    ($07,$00,$02,$09,$01,$08,$03,$06,$05,$04),
    ($01,$08,$07,$06,$03,$05,$04,$00,$09,$02),
    ($01,$07,$08,$05,$00,$04,$03,$09,$02,$06),
    ($06,$01,$07,$08,$00,$09,$03,$05,$04,$02),
    ($05,$06,$04,$03,$07,$01,$02,$00,$08,$09),
    ($01,$09,$05,$08,$06,$02,$07,$00,$04,$03),
    ($09,$05,$07,$02,$03,$01,$04,$06,$00,$08),
    ($00,$08,$04,$01,$02,$06,$07,$09,$05,$03),
    ($07,$04,$01,$05,$00,$03,$08,$02,$09,$06),
    ($05,$03,$06,$04,$01,$00,$07,$09,$08,$02),
    ($01,$03,$02,$08,$07,$06,$00,$05,$04,$09),
    ($01,$04,$02,$00,$06,$09,$08,$05,$03,$07),
    ($07,$03,$06,$08,$02,$04,$00,$01,$09,$05),
    ($08,$03,$01,$04,$09,$00,$02,$05,$06,$07),
    ($00,$04,$05,$06,$08,$09,$07,$02,$01,$03),
    ($00,$09,$05,$04,$07,$06,$01,$02,$03,$08)
   );
var
  day_num: Integer;
  key: array[1..10] of byte;
  rc4cipher: TDCP_rc4;
  enRC4byte: array of byte;
  en_password: string;
  en_size: Integer;
  bytes_password: array of byte;
begin
  day_num := getTodayOfMonth();
  key := day_key[day_num];
  // string转为byte数组
  bytes_password := bytesof(password);
  // 设置outbuffer长度
  setLength(enRC4byte, Length(password));
  en_size := Sizeof(byte)*Length(enRC4byte);
  // 加密
  rc4cipher := TDCP_rc4.Create(nil);
  try
    rc4cipher.Init(key, Sizeof(key) * 8, nil);
    rc4cipher.Encrypt(Pbytearray(bytes_password)^, Pbytearray(enRC4byte)^, en_size);
    en_password := MD5Print(MD5Buffer(Pbytearray(enRC4byte)^, en_size));
  finally
    rc4cipher.Burn;
    rc4cipher.Free;
  end;

  Result := en_password;
end;

function TForm1.encryptAuthAttr(infostr:string):string;
const
  day_key: array[1..31,1..10] of byte = (
    ($05,$03,$04,$08,$07,$02,$09,$06,$00,$01),
    ($07,$08,$02,$09,$04,$06,$03,$01,$05,$00),
    ($07,$09,$05,$01,$04,$02,$00,$03,$08,$06),
    ($08,$07,$00,$06,$02,$05,$04,$01,$03,$09),
    ($06,$02,$03,$05,$08,$01,$00,$04,$07,$09),
    ($00,$03,$05,$02,$04,$08,$01,$06,$07,$09),
    ($04,$01,$02,$08,$05,$00,$06,$09,$07,$03),
    ($07,$01,$03,$04,$00,$08,$09,$02,$06,$05),
    ($06,$09,$00,$08,$05,$03,$04,$01,$07,$02),
    ($04,$05,$01,$06,$08,$09,$03,$07,$00,$02),
    ($01,$06,$04,$08,$00,$09,$02,$03,$05,$07),
    ($05,$00,$07,$02,$04,$08,$03,$01,$06,$09),
    ($06,$09,$00,$04,$02,$08,$03,$01,$05,$07),
    ($02,$09,$03,$00,$05,$01,$08,$06,$04,$07),
    ($07,$00,$08,$02,$04,$03,$06,$05,$01,$09),
    ($06,$03,$01,$08,$02,$05,$00,$09,$04,$07),
    ($01,$00,$07,$09,$02,$03,$04,$05,$06,$08),
    ($01,$04,$09,$08,$00,$05,$03,$06,$07,$02),
    ($06,$08,$05,$02,$00,$09,$03,$04,$07,$01),
    ($08,$07,$04,$06,$03,$09,$05,$00,$02,$01),
    ($09,$02,$08,$03,$04,$01,$07,$06,$00,$05),
    ($00,$05,$08,$03,$09,$02,$04,$01,$07,$06),
    ($09,$07,$04,$05,$02,$01,$06,$00,$03,$08),
    ($05,$01,$07,$04,$02,$03,$00,$08,$09,$06),
    ($07,$04,$05,$01,$06,$02,$08,$09,$00,$03),
    ($05,$09,$03,$06,$08,$02,$00,$07,$01,$04),
    ($04,$09,$06,$05,$02,$08,$07,$01,$03,$00),
    ($05,$08,$09,$02,$01,$07,$06,$03,$00,$04),
    ($08,$03,$09,$05,$06,$00,$04,$07,$02,$01),
    ($07,$05,$02,$08,$04,$01,$03,$09,$06,$00),
    ($09,$00,$07,$02,$08,$04,$06,$01,$03,$05)
   );
var
  day_num: Integer;
  key: array[1..10] of byte;
  rc4cipher: TDCP_rc4;
  enRC4byte: array of byte;
  //en_infostr: string;
  en_size: Integer;
  bytes_infostr: array of byte;
begin
  day_num := getTodayOfMonth();
  key := day_key[day_num];
  // string转为byte数组
  bytes_infostr := bytesof(infostr);
  // 设置outbuffer长度
  setLength(enRC4byte, Length(infostr));
  en_size := Sizeof(byte)*Length(enRC4byte);
  // 加密
  rc4cipher := TDCP_rc4.Create(nil);
  try
    rc4cipher.Init(key, Sizeof(key) * 8, nil);
    rc4cipher.Encrypt(Pbytearray(bytes_infostr)^, Pbytearray(enRC4byte)^, en_size);
    SetLength(Result,((Length(enRC4byte)+2) div 3) * 4);
    Base64Encode(Pbytearray(enRC4byte), @Result[1], en_size);
  finally
    rc4cipher.Burn;
    rc4cipher.Free;
  end;

  //Result := en_password;
end;

procedure TForm1.getRedirectURL(base_url: string);
begin
  with TFPHttpClient.Create(Nil) do
  begin
    try
      Post(base_url);
      if ResponseStatusCode = 302 then
        self.redirectURL := Trim(ResponseHeaders.Values['Location']);
    finally
      Free;
    end;
  end;
end;

procedure TForm1.getLoginINFO();
var
  re: TRegExpr;
  html: string;
  url: string;
begin
  with TFPHttpClient.Create(Nil) do
  begin
    try
      AddHeader('User-Agent', 'CDMA+WLAN(Maod)');
      url := self.redirectURL + '&aidcauthtype=0';
      html := Get(url);
      if ResponseStatusCode = 200 then
        begin
          re := TRegExpr.Create('\<LoginURL\>\<\!\[CDATA\[(\S+?)\]\]\>\<\/LoginURL\>');
          if re.Exec(html) then
            self.loginURL := re.Match[1];
          re.Free;
          re := TRegExpr.Create('<AidcAuthAttr15>(\S+?)</AidcAuthAttr15>');
          if re.Exec(html) then
            self.aidcAuthAttr15 := re.Match[1];
          re.Free;
          re := TRegExpr.Create('100\.64\.\d{1,3}\.\d{1,3}');
          if re.Exec(html) then
            self.ipaddr := re.Match[0];
          re.Free;
          re := TRegExpr.Create('(\w\w\-){5}\w\w');
          if re.Exec(html) then
            self.macaddr := StringReplace(re.Match[0], '-', ':', [rfReplaceAll, rfIgnoreCase]);
          re.Free;
        end;
    finally
      Free;
    end;
  end;
end;

procedure TForm1.loginAction(username: string; password: string);
var
  re: TRegExpr;
  html: string;
  formdata: TStrings;
  version: string = '1.0.12';
  deviceINFO: string;
begin
  deviceINFO := self.edtDeviceInfo.Text;
  // 获取登录地址
  getRedirectURL('http://59.37.96.63:80');
  if Length(self.redirectURL)=0 then
    begin
      self.lblInfo.Caption := '已联网，请勿再次登录';
      Exit;
    end;
  getLoginINFO();
  if Length(self.loginURL)=0 then
    Exit;

  //ShowMessage(self.aidcAuthAttr15+'|'+self.macaddr+'|'+self.ipaddr);
  //构造formdata
  formdata := TStringList.Create;
  formdata.Values['UserName'] := '!^Maod0' + username;
  formdata.Values['Password'] := encryptPassword(password);
  formdata.Values['AidcAuthAttr1'] := FormatDateTime('YYYYMMDDhhnnss',Now);
  formdata.Values['AidcAuthAttr3'] := encryptAuthAttr(version);
  formdata.Values['AidcAuthAttr4'] := encryptAuthAttr(deviceINFO);
  formdata.Values['AidcAuthAttr5'] := encryptAuthAttr('10.0.8.1;127.0.0.1;'+ self.ipaddr);
  formdata.Values['AidcAuthAttr6'] := encryptAuthAttr(self.macaddr);
  formdata.Values['AidcAuthAttr7'] := encryptAuthAttr(Format('IP address       HW type     Flags       HW address            Mask     Device;100.64.0.1       0x1         0x2         %s     *        wlan0;', [randomMAC(':')]));
  formdata.Values['AidcAuthAttr8'] := encryptAuthAttr(',1071,-1,not matcher content;,1076,-1,not matcher content;,1075,-1,not matcher content');
  formdata.Values['AidcAuthAttr15'] := self.aidcAuthAttr15;
  formdata.Values['AidcAuthAttr22'] := encryptAuthAttr('0');
  formdata.Values['AidcAuthAttr23'] := encryptAuthAttr('success');
  formdata.Values['createAuthorFlag'] := '0';

  // 登录
  with TFPHttpClient.Create(Nil) do
  begin
    try
      AddHeader('User-Agent', 'CDMA+WLAN(Maod)');
      html := FormPost(self.loginURL, formdata);
      if ResponseStatusCode = 200 then
        begin
          re := TRegExpr.Create('\<ReplyMessage\>(\S+?)\<\/ReplyMessage\>');
          if re.Exec(html) then
            self.loginINFO := re.Match[1];
          re := TRegExpr.Create('\<LogoffURL\>\<\!\[CDATA\[(\S+?)\]\]\>\<\/LogoffURL\>');
          if re.Exec(html) then
            self.logoffURL := re.Match[1];
          re.Free;
        end;
    finally
      Free;
      formdata.Free;
    end;
  end;
end;

procedure TForm1.logoffAction(logoff_url: string);
var
  html: string;
  re: TRegExpr;
  logoff_code: string;
begin
  with TFPHttpClient.Create(Nil) do
  begin
    try
      AddHeader('User-Agent', 'CDMA+WLAN(Maod)');
      html := Get(logoff_url);
      if ResponseStatusCode = 200 then
        begin
          re := TRegExpr.Create('\<ResponseCode\>(\S+?)\<\/ResponseCode\>');
          if re.Exec(html) then
            begin
              logoff_code := re.Match[1];
              if logoff_code = '150' then
                self.logoffINFO := logoff_code + ' 登出成功';
            end;
          re.Free;
        end;
    finally
      Free;
    end;
  end;
end;

procedure TForm1.showInfoFromINI(filename: string);
const
  ASECTION = 'General';
var
  INI: TINIFile;
  username, password, key: string;
begin
  INI := TINIFile.Create(filename);
  try
    username := INI.ReadString(ASECTION, 'username', '');
    password := INI.ReadString(ASECTION, 'password', '');
    key      := INI.ReadString(ASECTION, 'key', '');
    self.logoffURL := INI.ReadString(ASECTION, 'logoff', '');

    self.edtUsername.Text := username;
    self.edtPassword.Text := password;
    self.edtAuthKey.Text  := key;
  finally
    INI.Free;
  end;
end;

procedure TForm1.updateINI(filename: string);
const
  ASECTION = 'General';
var
  INI: TINIFile;
begin
  INI := TINIFile.Create(filename);
  try
    INI.WriteString(ASECTION, 'username', self.edtUsername.Text);
    INI.WriteString(ASECTION, 'password', self.edtPassword.Text);
    INI.WriteString(ASECTION, 'key', self.edtAuthKey.Text);
    INI.WriteString(ASECTION, 'logoff', self.logoffURL);
    INI.UpdateFile;
  finally
    INI.Free;
  end;
end;

function TForm1.verifyKey(key: string): Boolean;
var
  rc4Key: string;
begin
  Result := false;
 rc4Key := '6D2E24B63283CF34024399F7827A2D00';
 with TDCP_rc4.Create(nil) do
 try
  Init(rc4Key[1], Length(rc4Key) * 8, nil);
  if length(key)<>0 then
    if MD5Print(MD5String(self.edtUsername.Text)) = DecryptString(key) then
      Result := true;
 finally
   Burn;
   Free;
 end;
end;

end.

