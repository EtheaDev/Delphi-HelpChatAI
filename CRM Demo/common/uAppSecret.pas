{******************************************************************************}
{                                                                              }
{   HelpChatAI CRM demo - the secret of this application                       }
{                                                                              }
{   How the demo keeps its API key encrypted in helpchatai.json, and how it    }
{   hands it back to the component through OnDecryptSecret. AES-256 (CBC,      }
{   random IV, PKCS#7) from DCPcrypt, with a key derived from a passphrase     }
{   that is not written anywhere as a string.                                  }
{                                                                              }
{   THIS IS A SIMPLE EXAMPLE, AND IT IS OBFUSCATION, NOT SECRECY.              }
{   It raises the cost: whoever receives the configuration file, a backup, a   }
{   log or a screenshot of the Object Inspector no longer has the key.         }
{   It does not make it impossible: the passphrase travels inside the          }
{   executable, so whoever owns the machine and a debugger can recover it -    }
{   and the sources of this demo are public, which settles the matter here.    }
{   A real application does better: a secret fetched from its own server at    }
{   startup, one derived from the machine or the logged-on user, or no key on  }
{   the client at all (Settings.Remote: the key lives on the HelpChat server   }
{   and never reaches the client).                                             }
{                                                                              }
{   DCPcrypt is used by the demo alone: the library has no dependency on it,   }
{   it only calls the handler. See the search path of the two projects.        }
{                                                                              }
{******************************************************************************}

unit uAppSecret;

interface

uses
  System.SysUtils,
  HelpChatAI.Settings;

const
  /// <summary>What marks a value this unit wrote. The library imposes no
  /// format: this prefix is a convention of the demo, and the handler is the
  /// only thing that has to recognize it.</summary>
  APPSECRET_PREFIX = 'enc:';

/// <summary>True when AValue carries the prefix of a protected value.</summary>
function AppSecretIsProtected(const AValue: string): Boolean;

/// <summary>AClearText encrypted with the secret of this application:
/// <c>enc:</c> followed by Base64 of the IV and the ciphertext. Encrypting
/// the same text twice gives two different results, because the IV is drawn
/// every time.</summary>
function AppSecretProtect(const AClearText: string): string;

/// <summary>What AppSecretProtect wrote, back in clear. Raises when the value
/// was not produced by this application - a key encrypted with another
/// passphrase is not a key with a typo in it.</summary>
function AppSecretReveal(const AValue: string): string;

type
  /// <summary>The key the model in use is missing, and where it belongs.</summary>
  TAppSecretKeyRequest = record
    /// <summary>The name of the model in use, as the panel shows it.</summary>
    Model: string;
    /// <summary>What it calls (gemini-3.5-flash-lite), when it says more than the name.</summary>
    ModelId: string;
    /// <summary>Its provider: claude, gemini, openai.</summary>
    Provider: string;
    /// <summary>The section of that provider in helpchatai.json (Claude,
    /// Gemini, OpenAI).</summary>
    Section: string;
    /// <summary>The entry of <c>Models</c> that gets the key, when the model
    /// has an endpoint of its own: a key goes with the host it is for, and
    /// the key of the section is never sent there. Empty: the section.</summary>
    Entry: string;
    /// <summary>The endpoint of that entry, when it has one: what tells a
    /// GitHub token from an OpenAI key.</summary>
    BaseUrl: string;
    /// <summary>The model the assistant is using now is of this service.</summary>
    InUse: Boolean;
    /// <summary>A key is already there (a file, the handler, the
    /// environment): a field left empty keeps it.</summary>
    HasKey: Boolean;
    /// <summary>"Gemini (gemini-3.5-flash-lite)": who the key is for.</summary>
    function Caption: string;
    /// <summary>What a key of that service looks like ("AIza..."), or empty.</summary>
    function Example: string;
    /// <summary>The label of its row in the activation window: who the key
    /// is for, and whether it is the model in use.</summary>
    function RowCaption: string;
    /// <summary>The hint of its empty field: what a key looks like, or that
    /// one is registered already and stays unless replaced.</summary>
    function Hint: string;
  end;

/// <summary>True when the model the assistant would use now needs a key and
/// has none: none in the files, none the handler can decrypt, none in the
/// environment. The provider decides (its <c>ConfigurationIssue</c>), so a
/// <c>docsearch</c> or a local server on <c>openai</c> never asks. ASettings
/// is <c>RunSettings</c> of the component: the settings of the running
/// engine, with the model the user picked in the panel applied.</summary>
function AppSecretMissingKey(const ASettings: THelpChatSettings;
  out ARequest: TAppSecretKeyRequest): Boolean;

const
  /// <summary>The services the activation window offers a key for, in the
  /// order of its rows: the three built-in providers that need one.</summary>
  APPSECRET_SERVICES: array[0..2] of string = ('claude', 'gemini', 'openai');
  /// <summary>The rows of the activation window.</summary>
  APPSECRET_MAX_ROWS = 4;

/// <summary>What the activation window shows, at most
/// <c>APPSECRET_MAX_ROWS</c>: one row per service of
/// <c>APPSECRET_SERVICES</c>, then one per model of the catalogue served by
/// a service of its own on the internet (Groq, OpenRouter...), whose key
/// is that model's and not the section's. The user registers the key the
/// model in use is missing and, while at it, the others; the row of the
/// model in use is always there.</summary>
function AppSecretKeyRequests(const ASettings: THelpChatSettings): TArray<TAppSecretKeyRequest>;

/// <summary>Every non-empty key of AKeys (parallel to ARequests) encrypted,
/// written to the per-user file and applied to ASettings: what the
/// activation window hands back. A clear key lives as long as this call.</summary>
procedure AppSecretActivate(const ASettings: THelpChatSettings;
  const ARequests: TArray<TAppSecretKeyRequest>; const AKeys: TArray<string>);

/// <summary>Writes AProtectedKey as <c>ApiKeyEncrypted</c> where ARequest
/// says, in the per-user configuration file of this application
/// (<c>%APPDATA%\&lt;exe&gt;\helpchatai.json</c>): the section of the
/// provider, or the entry of the model in <c>Models</c> - added to the list
/// of that file, or, when the file has none, in a list naming the other
/// models of the catalogue as they are. The rest of the file stays as it is,
/// a clear <c>ApiKey</c> of the developer included: the IDE reads that one,
/// the running application this one.</summary>
procedure AppSecretStoreApiKey(const ASettings: THelpChatSettings;
  const ARequest: TAppSecretKeyRequest; const AProtectedKey: string);

/// <summary>The same key into the settings in memory, as if it had just been
/// read from the file: the next question uses it, no restart.</summary>
procedure AppSecretApplyApiKey(const ASettings: THelpChatSettings;
  const ARequest: TAppSecretKeyRequest; const AProtectedKey: string);

type
  /// <summary>The handler to hang on <c>OnDecryptSecret</c>, for a host that
  /// has no form of its own to put it on. Both demos use a method of their
  /// main form instead, which is where the Object Inspector looks.</summary>
  TAppSecret = class
  public
    /// <summary>Answers for every value carrying the prefix, whichever secret
    /// it is, and leaves the others as they are.</summary>
    procedure DecryptSecret(Sender: TObject; const AName, AValue: string;
      var AResult: string; var AHandled: Boolean);
  end;

/// <summary>The one instance, freed with the unit.</summary>
function AppSecret: TAppSecret;

implementation

uses
  System.Classes,
  System.Generics.Collections,
  System.IOUtils,
  System.JSON,
  System.NetEncoding,
  HelpChatAI.Provider,
  HelpChatAI.Provider.OpenAI,
  DCPcrypt2,
  DCPrijndael,
  DCPsha256;

const
  AES_BLOCK = 16;
  AES_KEYBITS = 256;

  // The passphrase of this application, in two halves that mean nothing on
  // their own: neither is a readable string in the executable, and the value
  // itself exists only while the key is being derived. Read the header of
  // this unit before trusting it with anything that matters.
  SECRET_A: array[0..41] of Byte = (
    $B6, $7F, $17, $F8, $9A, $C4, $AC, $67,
    $CD, $6F, $DC, $11, $9C, $E5, $1E, $6F,
    $67, $C6, $24, $C8, $D3, $D8, $7A, $7E,
    $67, $7C, $A3, $20, $A5, $86, $A9, $27,
    $97, $D1, $9A, $18, $E1, $F9, $F8, $E9,
    $9B, $84);
  SECRET_B: array[0..41] of Byte = (
    $A5, $46, $26, $D6, $86, $CC, $AC, $71,
    $EF, $42, $99, $34, $A9, $C0, $57, $61,
    $69, $C7, $26, $86, $8E, $98, $39, $3A,
    $34, $25, $FB, $76, $B7, $86, $B1, $30,
    $9C, $C1, $82, $46, $ED, $1C, $1A, $19,
    $7D, $74);
  SECRET_SALT = $5B;

var
  FAppSecret: TAppSecret;

/// <summary>Zeroes a buffer that held something secret. An empty one is
/// legal and must not be addressed.</summary>
procedure Wipe(var ABytes: TBytes);
begin
  if Length(ABytes) > 0 then
    FillChar(ABytes[0], Length(ABytes), 0);
  SetLength(ABytes, 0);
end;

function Passphrase: TBytes;
var
  I: Integer;
begin
  SetLength(Result, Length(SECRET_A));
  for I := 0 to High(SECRET_A) do
    Result[I] := SECRET_A[I] xor SECRET_B[I] xor Byte(SECRET_SALT + I);
end;

/// <summary>The 256-bit key: the SHA-256 of the passphrase, which is also
/// what turns a passphrase of any length into a key of the right one.</summary>
function KeyBytes: TBytes;
var
  LHash: TDCP_sha256;
  LPass: TBytes;
begin
  SetLength(Result, 32);
  LPass := Passphrase;
  LHash := TDCP_sha256.Create(nil);
  try
    LHash.Init;
    LHash.Update(LPass[0], Length(LPass));
    LHash.Final(Result[0]);
  finally
    LHash.Burn;
    LHash.Free;
    Wipe(LPass);
  end;
end;

/// <summary>AES-256 in CBC, keyed and set on AIv. The caller burns it.</summary>
function NewCipher(const AIv: TBytes): TDCP_rijndael;
var
  LKey: TBytes;
begin
  LKey := KeyBytes;
  Result := TDCP_rijndael.Create(nil);
  try
    Result.Init(LKey[0], AES_KEYBITS, @AIv[0]);
    Result.CipherMode := cmCBC;
  except
    Result.Free;
    raise;
  end;
  Wipe(LKey);
end;

/// <summary>An initialisation vector nobody can guess: two GUIDs, hashed.
/// It is not a secret - it travels in front of the ciphertext - but it must
/// differ every time, or the same key encrypted twice looks the same.</summary>
function NewIv: TBytes;
var
  LHash: TDCP_sha256;
  LSeed: array[0..1] of TGUID;
  LDigest: TBytes;
begin
  CreateGUID(LSeed[0]);
  CreateGUID(LSeed[1]);
  SetLength(LDigest, 32);
  LHash := TDCP_sha256.Create(nil);
  try
    LHash.Init;
    LHash.Update(LSeed[0], SizeOf(LSeed));
    LHash.Final(LDigest[0]);
  finally
    LHash.Burn;
    LHash.Free;
  end;
  SetLength(Result, AES_BLOCK);
  Move(LDigest[0], Result[0], AES_BLOCK);
end;

/// <summary>Base64 on one line: the value goes into a JSON string and into a
/// form file, and the encoder of the RTL wraps at 76 characters unless it is
/// told not to.</summary>
function Base64Of(const ABytes: TBytes): string;
var
  LEncoding: TBase64Encoding;
begin
  LEncoding := TBase64Encoding.Create(0);
  try
    Result := LEncoding.EncodeBytesToString(ABytes);
  finally
    LEncoding.Free;
  end;
end;

function BytesOfBase64(const AText: string): TBytes;
var
  LEncoding: TBase64Encoding;
begin
  LEncoding := TBase64Encoding.Create(0);
  try
    Result := LEncoding.DecodeStringToBytes(AText);
  finally
    LEncoding.Free;
  end;
end;

function AppSecretIsProtected(const AValue: string): Boolean;
begin
  Result := AValue.StartsWith(APPSECRET_PREFIX);
end;

function AppSecretProtect(const AClearText: string): string;
var
  LPlain, LPadded, LCipherText, LIv: TBytes;
  LPad: Integer;
  LCipher: TDCP_rijndael;
begin
  if AClearText = '' then
    Exit('');
  LPlain := TEncoding.UTF8.GetBytes(AClearText);
  // PKCS#7: always at least one byte of padding, every one of them saying
  // how many there are, so the length of the text is not readable from the
  // length of the ciphertext.
  LPad := AES_BLOCK - (Length(LPlain) mod AES_BLOCK);
  SetLength(LPadded, Length(LPlain) + LPad);
  Move(LPlain[0], LPadded[0], Length(LPlain));
  FillChar(LPadded[Length(LPlain)], LPad, Byte(LPad));
  LIv := NewIv;
  SetLength(LCipherText, Length(LPadded));
  LCipher := NewCipher(LIv);
  try
    LCipher.EncryptCBC(LPadded[0], LCipherText[0], Length(LPadded));
  finally
    LCipher.Burn;
    LCipher.Free;
    Wipe(LPlain);
    Wipe(LPadded);
  end;
  Result := APPSECRET_PREFIX + Base64Of(LIv + LCipherText);
end;

function AppSecretReveal(const AValue: string): string;
var
  LRaw, LPlain, LIv: TBytes;
  LCipher: TDCP_rijndael;
  LPad, LSize: Integer;
begin
  if not AppSecretIsProtected(AValue) then
    Exit(AValue);
  LRaw := BytesOfBase64(AValue.Substring(Length(APPSECRET_PREFIX)));
  LSize := Length(LRaw) - AES_BLOCK;
  if (LSize <= 0) or (LSize mod AES_BLOCK <> 0) then
    raise Exception.Create('The protected value is not one this application wrote.');
  SetLength(LIv, AES_BLOCK);
  Move(LRaw[0], LIv[0], AES_BLOCK);
  SetLength(LPlain, LSize);
  LCipher := NewCipher(LIv);
  try
    LCipher.DecryptCBC(LRaw[AES_BLOCK], LPlain[0], LSize);
  finally
    LCipher.Burn;
    LCipher.Free;
  end;
  // The padding is the only check there is: a wrong passphrase gives noise,
  // and noise does not end in 1..16 equal bytes - almost never, anyway.
  LPad := LPlain[LSize - 1];
  if (LPad < 1) or (LPad > AES_BLOCK) or (LPad > LSize) then
  begin
    Wipe(LPlain);
    raise Exception.Create('The protected value was written with another secret.');
  end;
  try
    Result := TEncoding.UTF8.GetString(LPlain, 0, LSize - LPad);
  finally
    Wipe(LPlain);
  end;
end;

{ TAppSecretKeyRequest }

function TAppSecretKeyRequest.Caption: string;
begin
  Result := Model;
  if (ModelId <> '') and not SameText(ModelId, Model) then
    Result := Format('%s (%s)', [Model, ModelId]);
end;

function TAppSecretKeyRequest.Example: string;
begin
  // Only to help whoever pastes it: a key of another service is the most
  // common mistake, and it looks exactly like a right one until the first
  // question fails.
  if BaseUrl.ToLower.Contains('groq.com') then
    Result := 'gsk_...'
  else if BaseUrl.ToLower.Contains('openrouter.ai') then
    Result := 'sk-or-...'
  else if SameText(Provider, 'claude') then
    Result := 'sk-ant-...'
  else if SameText(Provider, 'gemini') then
    Result := 'AIza...'
  else if SameText(Provider, 'openai') then
    Result := 'sk-...'
  else
    Result := '';
end;

function TAppSecretKeyRequest.RowCaption: string;
begin
  Result := Caption;
  if InUse then
    Result := Result + ' - the model in use';
  Result := Result + ':';
end;

function TAppSecretKeyRequest.Hint: string;
begin
  if HasKey then
    Result := 'Registered: leave empty to keep it'
  else
    Result := Example;
end;

function AppSecretMissingKey(const ASettings: THelpChatSettings;
  out ARequest: TAppSecretKeyRequest): Boolean;
var
  LSection: THelpChatModelSettings;
  LClass: THelpChatProviderClass;
  LEntry: THelpChatModelEntry;
begin
  ARequest := Default(TAppSecretKeyRequest);
  // The provider in force: the one of the model the user picked, when it
  // names one. A provider with no model behind it (docsearch, stub) has no
  // section, and no key to ask for.
  ARequest.Provider := ASettings.Provider;
  LSection := ASettings.ModelFor(ARequest.Provider);
  if LSection = nil then
    Exit(False);
  // The provider says what it needs, and the demo does not second-guess it:
  // for the three built-in ones that is the key, and only where a key makes
  // sense - openai on a local server or a gateway needs none.
  LClass := THelpChatProviderRegistry.FindProviderClass(ARequest.Provider);
  if (LClass = nil) or (LClass.ConfigurationIssue(ASettings) = '') then
    Exit(False);
  ARequest.Model := ASettings.ActiveModelName;
  ARequest.ModelId := LSection.ResolveModel;
  ARequest.Section := LSection.SectionName;
  // A model of the catalogue with an endpoint of its own keeps its key with
  // it: the library never sends the key of the section to another host.
  LEntry := ASettings.Models.Find(ARequest.Model);
  if (LEntry <> nil) and (Trim(LEntry.BaseUrl) <> '') then
  begin
    ARequest.Entry := LEntry.Name;
    ARequest.BaseUrl := Trim(LEntry.BaseUrl);
  end;
  Result := True;
end;

function AppSecretKeyRequests(const ASettings: THelpChatSettings): TArray<TAppSecretKeyRequest>;
var
  LMissing, LRow: TAppSecretKeyRequest;
  LIsMissing, LActiveOwnUrl: Boolean;
  LSection: THelpChatModelSettings;
  LActive, LEntry: THelpChatModelEntry;
  LProvider: string;
  I: Integer;
begin
  Result := nil;
  LIsMissing := AppSecretMissingKey(ASettings, LMissing);
  LActive := ASettings.Models.Find(ASettings.ActiveModelName);
  LActiveOwnUrl := (LActive <> nil) and (Trim(LActive.BaseUrl) <> '');
  // The sections: one key per service.
  for I := 0 to High(APPSECRET_SERVICES) do
  begin
    if LIsMissing and (LMissing.Entry = '') and
       SameText(LMissing.Provider, APPSECRET_SERVICES[I]) then
    begin
      // What the model in use needs, and where it goes.
      LRow := LMissing;
      LRow.InUse := True;
      Result := Result + [LRow];
      Continue;
    end;
    LRow := Default(TAppSecretKeyRequest);
    LRow.Provider := APPSECRET_SERVICES[I];
    LSection := ASettings.ModelFor(LRow.Provider);
    if LSection = nil then
      Continue;
    LRow.Section := LSection.SectionName;
    LRow.Model := LSection.SectionName;
    LRow.ModelId := LSection.ResolveModel;
    LRow.InUse := not LActiveOwnUrl and SameText(ASettings.Provider, LRow.Provider);
    // Through the handler, as a request would: a key that is there but
    // cannot be read is no key.
    LRow.HasKey := LSection.ResolveApiKey <> '';
    Result := Result + [LRow];
  end;
  // The models of the catalogue on a service of their own on the internet:
  // their key is theirs, never the section's (a local server wants none).
  for I := 0 to ASettings.Models.Count - 1 do
  begin
    LEntry := ASettings.Models[I];
    if (Trim(LEntry.BaseUrl) = '') or HelpChatIsLocalEndpoint(LEntry.BaseUrl) then
      Continue;
    if LIsMissing and SameText(LMissing.Entry, LEntry.Name) then
    begin
      LRow := LMissing;
      LRow.InUse := True;
    end
    else
    begin
      LProvider := Trim(LEntry.Provider);
      if LProvider = '' then
        LProvider := ASettings.ConfiguredProvider;
      LSection := ASettings.ModelFor(LProvider);
      if LSection = nil then
        Continue;
      LRow := Default(TAppSecretKeyRequest);
      LRow.Provider := LProvider;
      LRow.Section := LSection.SectionName;
      LRow.Model := LEntry.Name;
      LRow.ModelId := Trim(LEntry.Model);
      LRow.Entry := LEntry.Name;
      LRow.BaseUrl := Trim(LEntry.BaseUrl);
      LRow.InUse := LEntry = LActive;
      LRow.HasKey := HelpChatModelIsConfigured(ASettings, LEntry.Name);
    end;
    if Length(Result) < APPSECRET_MAX_ROWS then
      Result := Result + [LRow]
    else if LRow.InUse then
      // No room: the model in use takes the place of the last of these.
      Result[High(Result)] := LRow;
  end;
end;

procedure AppSecretActivate(const ASettings: THelpChatSettings;
  const ARequests: TArray<TAppSecretKeyRequest>; const AKeys: TArray<string>);
var
  LProtected: string;
  I: Integer;
begin
  for I := 0 to High(ARequests) do
    if (I <= High(AKeys)) and (Trim(AKeys[I]) <> '') and (ARequests[I].Section <> '') then
    begin
      LProtected := AppSecretProtect(Trim(AKeys[I]));
      // In the section of the provider, or in the model of the catalogue
      // when it has an endpoint of its own: a key goes with its host.
      AppSecretStoreApiKey(ASettings, ARequests[I], LProtected);
      // What stays in memory is the encrypted one, as if it had just been
      // read from the file: the clear text lives as long as the request.
      AppSecretApplyApiKey(ASettings, ARequests[I], LProtected);
    end;
end;

procedure SetEncryptedKey(const AObject: TJSONObject; const AProtectedKey: string);
begin
  AObject.RemovePair('ApiKeyEncrypted').Free;
  AObject.AddPair('ApiKeyEncrypted', AProtectedKey);
end;

/// <summary>The <c>Models</c> of the file with the entry carrying the key:
/// the entry of the file when it has one, else the model of the catalogue
/// written out. A file with no list gets one: the other models by name - a
/// name is a model of the catalogue already loaded - so that the list in
/// force stays what it was.</summary>
function ModelsWithKey(const ASettings: THelpChatSettings; const AOld: TJSONValue;
  const AEntry, AProtectedKey: string): TJSONArray;

  function EntryObject: TJSONObject;
  var
    LEntry: THelpChatModelEntry;
  begin
    Result := TJSONObject.Create;
    LEntry := ASettings.Models.Find(AEntry);
    if LEntry <> nil then
      LEntry.SaveToJSONObject(Result)
    else
      Result.AddPair('Name', AEntry);
    SetEncryptedKey(Result, AProtectedKey);
  end;

  function NameOf(const AItem: TJSONValue): string;
  begin
    if AItem is TJSONObject then
      Result := TJSONObject(AItem).GetValue<string>('Name', '')
    else if AItem is TJSONString then
      Result := TJSONString(AItem).Value
    else
      Result := '';
  end;

var
  LItem: TJSONValue;
  LFound: Boolean;
  I: Integer;
begin
  Result := TJSONArray.Create;
  LFound := False;
  if AOld is TJSONArray then
  begin
    for LItem in TJSONArray(AOld) do
      if SameText(NameOf(LItem), AEntry) then
      begin
        LFound := True;
        if LItem is TJSONObject then
        begin
          // The entry as the file wrote it, the key added: nothing else moves.
          Result.AddElement(TJSONValue(LItem.Clone));
          SetEncryptedKey(TJSONObject(Result.Items[Result.Count - 1]), AProtectedKey);
        end
        else
          Result.AddElement(EntryObject);
      end
      else
        Result.AddElement(TJSONValue(LItem.Clone));
    if not LFound then
      Result.AddElement(EntryObject);
  end
  else
    for I := 0 to ASettings.Models.Count - 1 do
      if SameText(ASettings.Models[I].Name, AEntry) then
        Result.AddElement(EntryObject)
      else
        Result.Add(ASettings.Models[I].Name);
end;

procedure AppSecretStoreApiKey(const ASettings: THelpChatSettings;
  const ARequest: TAppSecretKeyRequest; const AProtectedKey: string);
var
  LFileName: string;
  LRoot, LSection: TJSONObject;
  LValue: TJSONValue;
begin
  LFileName := THelpChatSettings.UserConfigFile;
  LRoot := nil;
  if TFile.Exists(LFileName) then
    LRoot := TJSONObject.ParseJSONValue(
      TFile.ReadAllText(LFileName, TEncoding.UTF8)) as TJSONObject;
  if LRoot = nil then
    LRoot := TJSONObject.Create;
  try
    if ARequest.Entry <> '' then
    begin
      LValue := ModelsWithKey(ASettings, LRoot.GetValue('Models'), ARequest.Entry,
        AProtectedKey);
      LRoot.RemovePair('Models').Free;
      LRoot.AddPair('Models', LValue);
    end
    else
    begin
      LValue := LRoot.GetValue(ARequest.Section);
      if LValue is TJSONObject then
        LSection := TJSONObject(LValue)
      else
      begin
        LSection := TJSONObject.Create;
        LRoot.AddPair(ARequest.Section, LSection);
      end;
      SetEncryptedKey(LSection, AProtectedKey);
    end;
    TDirectory.CreateDirectory(TPath.GetDirectoryName(LFileName));
    TFile.WriteAllText(LFileName, LRoot.Format(2), TEncoding.UTF8);
  finally
    LRoot.Free;
  end;
end;

procedure AppSecretApplyApiKey(const ASettings: THelpChatSettings;
  const ARequest: TAppSecretKeyRequest; const AProtectedKey: string);
var
  LEntry: THelpChatModelEntry;
  LSection: THelpChatModelSettings;
begin
  if ARequest.Entry <> '' then
  begin
    LEntry := ASettings.Models.Find(ARequest.Entry);
    if LEntry = nil then
      Exit;
    LEntry.ApiKeyEncrypted := AProtectedKey;
    // The key of a model reaches its section as an override, set when the
    // model is applied: apply it again.
    ASettings.ApplyModel(ARequest.Entry);
  end
  else
  begin
    LSection := ASettings.ModelFor(ARequest.Provider);
    if LSection <> nil then
      LSection.ApiKeyEncrypted := AProtectedKey;
  end;
end;

{ TAppSecret }

procedure TAppSecret.DecryptSecret(Sender: TObject; const AName, AValue: string;
  var AResult: string; var AHandled: Boolean);
begin
  AHandled := AppSecretIsProtected(AValue);
  if AHandled then
    AResult := AppSecretReveal(AValue);
end;

function AppSecret: TAppSecret;
begin
  if FAppSecret = nil then
    FAppSecret := TAppSecret.Create;
  Result := FAppSecret;
end;

initialization

finalization
  FreeAndNil(FAppSecret);

end.
