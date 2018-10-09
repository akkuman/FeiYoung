unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, DCPrc4, md5, Forms, Controls, Graphics,
  Dialogs, StdCtrls, fphttpclient, RegExpr;

type

  { TForm1 }

  TForm1 = class(TForm)
    btnClick2Login: TButton;
    DCP_rc4_1: TDCP_rc4;
    edtAuthKey: TEdit;
    edtMachineCode: TEdit;
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
    procedure FormCreate(Sender: TObject);
    function getTodayOfMonth():Integer;
    function encryptPassword(password:string):string;
    procedure getRedirectURL(base_url:string);
    procedure getLoginURL();
    procedure loginAction(username:string; password:string);
  private

  public
    var
      redirectURL: string;
      loginURL: string;
      loginINFO: string;
      logoffURL: string;
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.btnClick2LoginClick(Sender: TObject);
begin
  if (self.edtUsername.Text<>'') and (self.edtPassword.Text<>'') then
    loginAction(self.edtUsername.Text, self.edtPassword.Text)
  else
    begin
      self.lblInfo.Caption:='请输入账号和密码';
      Exit;
    end;
  self.lblInfo.Caption:=self.loginINFO;

end;

procedure TForm1.FormCreate(Sender: TObject);
begin

end;

function TForm1.getTodayOfMonth(): Integer;
  Var YY,MM,DD : Word;
begin
  DeCodeDate (Date,YY,MM,DD);
  Result := DD;
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
  rc4cipher.Init(key, Sizeof(key) * 8, nil);
  rc4cipher.Encrypt(Pbytearray(bytes_password)^, Pbytearray(enRC4byte)^, en_size);
  en_password := MD5Print(MD5Buffer(Pbytearray(enRC4byte)^, en_size));
  rc4cipher.Free;

  Result := en_password;
end;

procedure TForm1.getRedirectURL(base_url: string);
var
  //SS: TStringStream;
  html: string;
  //statuscode: array[1..3] of Integer = (200, 301, 302);
begin
  //SS := TStringStream.Create('');
  with TFPHttpClient.Create(Nil) do
  begin
    try
      //AllowRedirect := false;
      html := Post(base_url);
      //KeepConnection := true;
      //AddHeader('User-Agent', 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3163.100 Safari/537.36');
      //HTTPMethod('Get', base_url, SS, statuscode);
      if ResponseStatusCode = 302 then
        self.redirectURL := Trim(ResponseHeaders.Values['Location']);
    finally
      Free;
    end;
  end;
end;

procedure TForm1.getLoginURL();
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
      html := Post(url);
      if ResponseStatusCode = 200 then
        begin
          re := TRegExpr.Create('\<LoginURL\>\<\!\[CDATA\[(\S+?)\]\]\>\<\/LoginURL\>');
          if re.Exec(html) then
            self.loginURL := re.Match[1];
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
begin
  // 获取登录地址
  getRedirectURL('http://59.37.96.63:80');
  if Length(self.redirectURL)=0 then
    begin
      self.lblInfo.Caption := '已联网，请勿再次登录';
      Exit;
    end;
  getLoginURL();
  if Length(self.loginURL)=0 then
    Exit;

  // 构造formdata
  formdata := TStringList.Create;
  formdata.Values['UserName'] := '!^Maod0' + username;
  formdata.Values['Password'] := encryptPassword(password);
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
        end;
    finally
      Free;
    end;
  end;
end;

end.

