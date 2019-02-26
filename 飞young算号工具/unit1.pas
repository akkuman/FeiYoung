unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, DCPrc4, md5, Forms, Controls, Graphics, Dialogs,
  StdCtrls;

type

  { TForm1 }

  TForm1 = class(TForm)
    btnEncryptKey: TButton;
    btnDecryptKey: TButton;
    DCP_rc4_1: TDCP_rc4;
    edtUsername: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    mmoKey: TMemo;
    procedure btnDecryptKeyClick(Sender: TObject);
    procedure btnEncryptKeyClick(Sender: TObject);
    function decryptKey(key: string): string;
    function encryptKey(username: string): string;
  private

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.btnEncryptKeyClick(Sender: TObject);
begin
  self.mmoKey.Text:=encryptKey(self.edtUsername.Text);
end;

procedure TForm1.btnDecryptKeyClick(Sender: TObject);
begin
  self.edtUsername.Text:=decryptKey(self.mmoKey.Text);
end;

function TForm1.decryptKey(key: string): string;
var
  rc4Key: string;
begin
  Result := '';
  rc4Key := '6D2E24B63283CF34024399F7827A2D00';
  with TDCP_rc4.Create(nil) do
  try
    Init(rc4Key[1], Length(rc4Key) * 8, nil);
    Result := DecryptString(key);
  finally
    Burn;
    Free;
  end;
end;

function TForm1.encryptKey(username: string): string;
var
  rc4Key: string;
begin
  Result := '';
  rc4Key := '6D2E24B63283CF34024399F7827A2D00';
  with TDCP_rc4.Create(nil) do
  try
    Init(rc4Key[1], Length(rc4Key) * 8, nil);
    Result := EncryptString(MD5Print(MD5String(username)));
  finally
    Burn;
    Free;
  end;
end;

end.

