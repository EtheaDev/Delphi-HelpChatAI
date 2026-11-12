{******************************************************************************}
{                                                                              }
{   HelpChatAI CRM demo - license activation (FireMonkey)                      }
{                                                                              }
{   The FireMonkey half of uLicenseActivation: same window, same words. Where  }
{   a real application would activate its license - ask the licensing service  }
{   for the keys and keep what comes back - this demo asks for them itself,    }
{   encrypts it with the secret of the application (uAppSecret) and writes it  }
{   to the per-user configuration file, never in clear.                        }
{                                                                              }
{   FireMonkey answers in a callback: ShowModal is asynchronous, so Execute    }
{   hands the keys to a closure instead of returning them.                     }
{                                                                              }
{******************************************************************************}

unit uLicenseActivationFmx;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Objects, FMX.StdCtrls, FMX.Controls.Presentation, FMX.Edit,
  uAppSecret;

type
  TLicenseActivationFormFmx = class(TForm)
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
    procedure FormShow(Sender: TObject);
    procedure KeyEditChangeTracking(Sender: TObject);
    procedure ShowKeyCheckChange(Sender: TObject);
    procedure ActivateButtonClick(Sender: TObject);
    procedure SkipButtonClick(Sender: TObject);
  private
    FFirst: TEdit;
    function Labels: TArray<TLabel>;
    function Edits: TArray<TEdit>;
    procedure Prepare(const ARequests: TArray<TAppSecretKeyRequest>);
    function Keys(const ACount: Integer): TArray<string>;
    procedure UpdateButtons;
  public
    /// <summary>Asks for the keys of ARequests (AppSecretKeyRequests: one
    /// row per service, the one of the model in use in bold), and calls
    /// AOnActivated with them, once, only when the user activated with at
    /// least one key - parallel to ARequests, empty where nothing was typed;
    /// AOnClosed in any case, after it. AStorageFile is only shown, so that
    /// whoever types a key knows where it is about to end up.</summary>
    class procedure Execute(const ARequests: TArray<TAppSecretKeyRequest>;
      const AStorageFile: string; const AOnActivated: TProc<TArray<string>>;
      const AOnClosed: TProc = nil);
  end;

implementation

{$R *.fmx}

class procedure TLicenseActivationFormFmx.Execute(
  const ARequests: TArray<TAppSecretKeyRequest>; const AStorageFile: string;
  const AOnActivated: TProc<TArray<string>>; const AOnClosed: TProc);
var
  LForm: TLicenseActivationFormFmx;
  LCount: Integer;
begin
  LForm := TLicenseActivationFormFmx.Create(Application);
  LForm.StorageLabel.Text := AStorageFile;
  LForm.Prepare(ARequests);
  LCount := Length(ARequests);
  LForm.ShowModal(
    procedure(AResult: TModalResult)
    var
      LKeys: TArray<string>;
      LAny: Boolean;
      I: Integer;
    begin
      LKeys := LForm.Keys(LCount);
      LAny := False;
      for I := 0 to High(LKeys) do
        LAny := LAny or (LKeys[I] <> '');
      if (AResult = mrOk) and LAny and Assigned(AOnActivated) then
        AOnActivated(LKeys);
      if Assigned(AOnClosed) then
        AOnClosed();
      // Not here: this closure runs while the modal window is still being
      // closed, and the runtime touches the form after it returns.
      TThread.ForceQueue(nil,
        procedure
        begin
          LForm.Free;
        end);
    end);
end;

function TLicenseActivationFormFmx.Labels: TArray<TLabel>;
begin
  Result := [KeyLabel1, KeyLabel2, KeyLabel3, KeyLabel4];
end;

function TLicenseActivationFormFmx.Edits: TArray<TEdit>;
begin
  Result := [KeyEdit1, KeyEdit2, KeyEdit3, KeyEdit4];
end;

function TLicenseActivationFormFmx.Keys(const ACount: Integer): TArray<string>;
var
  LEdits: TArray<TEdit>;
  I: Integer;
begin
  SetLength(Result, ACount);
  LEdits := Edits;
  for I := 0 to ACount - 1 do
    if I <= High(LEdits) then
      Result[I] := Trim(LEdits[I].Text);
end;

procedure TLicenseActivationFormFmx.Prepare(const ARequests: TArray<TAppSecretKeyRequest>);
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
    LLabels[I].Text := ARequests[I].RowCaption;
    LEdits[I].TextPrompt := ARequests[I].Hint;
    if ARequests[I].InUse then
    begin
      // The style decides the font unless told otherwise.
      LLabels[I].StyledSettings := LLabels[I].StyledSettings - [TStyledSetting.Style];
      LLabels[I].TextSettings.Font.Style := [TFontStyle.fsBold];
      FFirst := LEdits[I];
    end;
  end;
  if FFirst = nil then
    FFirst := LEdits[0];
end;

procedure TLicenseActivationFormFmx.FormShow(Sender: TObject);
begin
  UpdateButtons;
  FFirst.SetFocus;
end;

procedure TLicenseActivationFormFmx.KeyEditChangeTracking(Sender: TObject);
begin
  UpdateButtons;
end;

procedure TLicenseActivationFormFmx.ShowKeyCheckChange(Sender: TObject);
var
  LEdit: TEdit;
begin
  // A key is pasted more often than typed, and a key pasted into the wrong
  // field looks exactly like a key pasted into the right one.
  for LEdit in Edits do
    LEdit.Password := not ShowKeyCheck.IsChecked;
end;

procedure TLicenseActivationFormFmx.UpdateButtons;
var
  LEdit: TEdit;
  LAny: Boolean;
begin
  LAny := False;
  for LEdit in Edits do
    LAny := LAny or (LEdit.Visible and (Trim(LEdit.Text) <> ''));
  ActivateButton.Enabled := LAny;
end;

procedure TLicenseActivationFormFmx.ActivateButtonClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

procedure TLicenseActivationFormFmx.SkipButtonClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.
