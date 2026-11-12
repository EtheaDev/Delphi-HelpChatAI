{******************************************************************************}
{                                                                              }
{   HelpChatAI CRM demo - license activation (VCL)                             }
{                                                                              }
{   Where a real application would activate its license: ask the user for the  }
{   code they bought, call the licensing service, and keep what comes back -   }
{   the API key among it. This demo has no service, so it asks for the key     }
{   itself; everything after that is the same, and it is the part that         }
{   matters here: the key is encrypted with the secret of the application      }
{   (uAppSecret) and written to the per-user configuration file, never in      }
{   clear.                                                                     }
{                                                                              }
{   It is shown when the model the assistant is about to use needs a key and   }
{   has none - at startup, and when the user switches model in the panel.      }
{   It offers a field per service (Claude, Gemini, OpenAI), the one of the     }
{   model in use in bold: the user registers that key and, while at it, any    }
{   other; a field left empty changes nothing. See AskForApiKeyIfMissing.      }
{                                                                              }
{******************************************************************************}

unit uLicenseActivation;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  // The icon in the form is a PNG, and this is what reads it back.
  Vcl.Imaging.pngimage,
  uAppSecret;

type
  TLicenseActivationForm = class(TForm)
    AppIconImage: TImage;
    TitleLabel: TLabel;
    ExplanationLabel: TLabel;
    KeyLabel1: TLabel;
    KeyEdit1: TEdit;
    KeyLabel2: TLabel;
    KeyEdit2: TEdit;
    KeyLabel3: TLabel;
    KeyEdit3: TEdit;
    KeyLabel4: TLabel;
    KeyEdit4: TEdit;
    ShowKeyCheck: TCheckBox;
    StorageTitleLabel: TLabel;
    StorageLabel: TLabel;
    ActivateButton: TButton;
    SkipButton: TButton;
    procedure ShowKeyCheckClick(Sender: TObject);
    procedure KeyEditChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FFirst: TEdit;
    function Labels: TArray<TLabel>;
    function Edits: TArray<TEdit>;
    procedure Prepare(const ARequests: TArray<TAppSecretKeyRequest>);
    procedure UpdateButtons;
  public
    /// <summary>Asks for the keys of ARequests (AppSecretKeyRequests: one
    /// row per service, the one of the model in use in bold). True when the
    /// user activated with at least one key; AKeys is parallel to ARequests,
    /// empty where nothing was typed. AStorageFile is only shown, so that
    /// whoever types a key knows where it is about to end up.</summary>
    class function Execute(const ARequests: TArray<TAppSecretKeyRequest>;
      const AStorageFile: string; out AKeys: TArray<string>): Boolean;
  end;

implementation

{$R *.dfm}

class function TLicenseActivationForm.Execute(
  const ARequests: TArray<TAppSecretKeyRequest>; const AStorageFile: string;
  out AKeys: TArray<string>): Boolean;
var
  LForm: TLicenseActivationForm;
  LEdits: TArray<TEdit>;
  I: Integer;
begin
  SetLength(AKeys, Length(ARequests));
  LForm := TLicenseActivationForm.Create(Application);
  try
    LForm.StorageLabel.Caption := AStorageFile;
    LForm.Prepare(ARequests);
    Result := LForm.ShowModal = mrOk;
    LEdits := LForm.Edits;
    if Result then
      for I := 0 to High(ARequests) do
        if I <= High(LEdits) then
          AKeys[I] := Trim(LEdits[I].Text);
    Result := False;
    for I := 0 to High(AKeys) do
      Result := Result or (AKeys[I] <> '');
  finally
    LForm.Free;
  end;
end;

function TLicenseActivationForm.Labels: TArray<TLabel>;
begin
  Result := [KeyLabel1, KeyLabel2, KeyLabel3, KeyLabel4];
end;

function TLicenseActivationForm.Edits: TArray<TEdit>;
begin
  Result := [KeyEdit1, KeyEdit2, KeyEdit3, KeyEdit4];
end;

procedure TLicenseActivationForm.Prepare(const ARequests: TArray<TAppSecretKeyRequest>);
var
  LLabels: TArray<TLabel>;
  LEdits: TArray<TEdit>;
  I: Integer;
begin
  LLabels := Labels;
  LEdits := Edits;
  FFirst := nil;
  for I := 0 to High(LEdits) do
  begin
    // APPSECRET_MAX_ROWS rows in the form: a row nobody asked for is hidden
    // rather than left empty.
    LLabels[I].Visible := I <= High(ARequests);
    LEdits[I].Visible := LLabels[I].Visible;
    if not LEdits[I].Visible then
      Continue;
    LLabels[I].Caption := ARequests[I].RowCaption;
    LEdits[I].TextHint := ARequests[I].Hint;
    if ARequests[I].InUse then
    begin
      LLabels[I].Font.Style := [fsBold];
      FFirst := LEdits[I];
    end;
  end;
  if FFirst = nil then
    FFirst := LEdits[0];
end;

procedure TLicenseActivationForm.FormShow(Sender: TObject);
begin
  UpdateButtons;
  FFirst.SetFocus;
end;

procedure TLicenseActivationForm.KeyEditChange(Sender: TObject);
begin
  UpdateButtons;
end;

procedure TLicenseActivationForm.ShowKeyCheckClick(Sender: TObject);
var
  LEdit: TEdit;
begin
  // A key is pasted more often than typed, and a key pasted into the wrong
  // field looks exactly like a key pasted into the right one.
  for LEdit in Edits do
    if ShowKeyCheck.Checked then
      LEdit.PasswordChar := #0
    else
      LEdit.PasswordChar := '*';
end;

procedure TLicenseActivationForm.UpdateButtons;
var
  LEdit: TEdit;
  LAny: Boolean;
begin
  LAny := False;
  for LEdit in Edits do
    LAny := LAny or (LEdit.Visible and (Trim(LEdit.Text) <> ''));
  ActivateButton.Enabled := LAny;
end;

end.
