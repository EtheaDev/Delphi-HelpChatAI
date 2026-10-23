unit HelpChatAI.Tests.Store;

interface

uses
  DUnitX.TestFramework,
  System.Generics.Collections,
  HelpChatAI.Types,
  HelpChatAI.Store;

type
  [TestFixture]
  TStoreTests = class
  strict private
    FStore: THelpChatStore;
    FChanges: TList<string>;
    procedure OnChange(const AKey, AMessageId: string);
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;
    [Test] procedure AddUserMessage_ReturnsStoredCopy;
    [Test] procedure PendingAssistant_Append_Complete;
    [Test] procedure PendingAssistant_Fail;
    [Test] procedure Update_UnknownId_IsNoOp;
    [Test] procedure GetHistory_FiltersAndLimits;
    [Test] procedure PendingIds_And_Count;
    [Test] procedure Prune_KeepsMostRecent_NeverPending;
    [Test] procedure Clear_RemovesConversation;
    [Test] procedure Conversations_AreIsolated;
    [Test] procedure OnChange_FiresPerMutation;
    [Test] procedure Json_RoundTrip_ExcludesPending;
    [Test] procedure FromJson_Invalid_LeavesStoreUntouched;
    [Test] procedure FromJson_Expired_IsRejected;
    [Test] procedure File_SaveAndLoad;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  System.DateUtils,
  HelpChatAI.Tests.Helpers;

const
  K = 'k';

procedure TStoreTests.Setup;
begin
  FStore := THelpChatStore.Create;
  FChanges := TList<string>.Create;
end;

procedure TStoreTests.TearDown;
begin
  FStore.Free;
  FChanges.Free;
end;

procedure TStoreTests.OnChange(const AKey, AMessageId: string);
begin
  FChanges.Add(AKey + ':' + AMessageId);
end;

procedure TStoreTests.AddUserMessage_ReturnsStoredCopy;
var
  LMessage, LStored: THelpChatMessage;
begin
  LMessage := FStore.AddUserMessage(K, 'hello');
  Assert.AreEqual(hcrUser, LMessage.Role);
  Assert.AreEqual('hello', LMessage.Content);
  Assert.IsFalse(LMessage.Pending);
  Assert.IsTrue(FStore.TryGetMessage(K, LMessage.Id, LStored));
  Assert.AreEqual(LMessage.Id, LStored.Id);
  Assert.AreEqual(1, FStore.Count(K));
end;

procedure TStoreTests.PendingAssistant_Append_Complete;
var
  LId: string;
  LMessage: THelpChatMessage;
begin
  LId := FStore.AddPendingAssistant(K);
  Assert.IsTrue(FStore.TryGetMessage(K, LId, LMessage));
  Assert.IsTrue(LMessage.Pending);
  Assert.AreEqual(hcrAssistant, LMessage.Role);
  Assert.AreEqual('', LMessage.Content);

  FStore.AppendAssistantToken(K, LId, 'Hel');
  FStore.AppendAssistantToken(K, LId, '');
  FStore.AppendAssistantToken(K, LId, 'lo');
  FStore.TryGetMessage(K, LId, LMessage);
  Assert.AreEqual('Hello', LMessage.Content);
  Assert.IsTrue(LMessage.Pending, 'tokens keep the message pending');

  FStore.CompleteAssistant(K, LId, 'Hello world');
  FStore.TryGetMessage(K, LId, LMessage);
  Assert.AreEqual('Hello world', LMessage.Content);
  Assert.IsFalse(LMessage.Pending);
  Assert.IsFalse(LMessage.IsError);
end;

procedure TStoreTests.PendingAssistant_Fail;
var
  LId: string;
  LMessage: THelpChatMessage;
begin
  LId := FStore.AddPendingAssistant(K);
  FStore.AppendAssistantToken(K, LId, 'partial');
  FStore.FailAssistant(K, LId, 'boom');
  FStore.TryGetMessage(K, LId, LMessage);
  Assert.AreEqual('boom', LMessage.Content);
  Assert.IsFalse(LMessage.Pending);
  Assert.IsTrue(LMessage.IsError);
end;

procedure TStoreTests.Update_UnknownId_IsNoOp;
var
  LMessage: THelpChatMessage;
begin
  FStore.AddUserMessage(K, 'x');
  FStore.CompleteAssistant(K, 'nope', 'y');
  FStore.AppendAssistantToken(K, 'nope', 'y');
  FStore.FailAssistant('other-key', 'nope', 'y');
  Assert.AreEqual(1, FStore.Count(K));
  Assert.IsFalse(FStore.TryGetMessage(K, 'nope', LMessage));
end;

procedure TStoreTests.GetHistory_FiltersAndLimits;
var
  LPendingId, LFailedId: string;
  LHistory: TArray<THelpChatMessage>;
  I: Integer;
begin
  for I := 1 to 4 do
  begin
    FStore.AddUserMessage(K, 'q' + IntToStr(I));
    FStore.CompleteAssistant(K, FStore.AddPendingAssistant(K), 'a' + IntToStr(I));
  end;
  FStore.AddSystemMessage(K, 'sys');
  LFailedId := FStore.AddPendingAssistant(K);
  FStore.FailAssistant(K, LFailedId, 'err');
  LPendingId := FStore.AddPendingAssistant(K);

  LHistory := FStore.GetHistory(K, 0);
  Assert.AreEqual(8, Integer(Length(LHistory)), 'system, failed and pending are excluded');
  for I := 0 to High(LHistory) do
  begin
    Assert.IsTrue(LHistory[I].IsCompleted);
    Assert.AreNotEqual(hcrSystem, LHistory[I].Role);
  end;

  LHistory := FStore.GetHistory(K, 3);
  Assert.AreEqual(3, Integer(Length(LHistory)));
  Assert.AreEqual('a3', LHistory[0].Content, 'the most recent ones are kept');
  Assert.AreEqual('q4', LHistory[1].Content);
  Assert.AreEqual('a4', LHistory[2].Content);

  Assert.AreEqual(0, Integer(Length(FStore.GetHistory('missing', 0))));
end;

procedure TStoreTests.PendingIds_And_Count;
var
  LId1, LId2: string;
  LIds: TArray<string>;
begin
  FStore.AddUserMessage(K, 'q');
  LId1 := FStore.AddPendingAssistant(K);
  LId2 := FStore.AddPendingAssistant(K);
  LIds := FStore.PendingIds(K);
  Assert.AreEqual(2, Integer(Length(LIds)));
  Assert.Contains<string>(LIds, LId1);
  Assert.Contains<string>(LIds, LId2);
  FStore.CompleteAssistant(K, LId1, 'done');
  Assert.AreEqual(1, Integer(Length(FStore.PendingIds(K))));
  Assert.AreEqual(3, FStore.Count(K));
  Assert.AreEqual(0, FStore.Count('missing'));
end;

procedure TStoreTests.Prune_KeepsMostRecent_NeverPending;
var
  LPendingId: string;
  LMessages: TArray<THelpChatMessage>;
  I: Integer;
begin
  FStore.MaxMessages := 3;
  LPendingId := FStore.AddPendingAssistant(K);
  for I := 1 to 5 do
    FStore.AddUserMessage(K, 'm' + IntToStr(I));
  LMessages := FStore.GetMessages(K);
  Assert.AreEqual(3, Integer(Length(LMessages)));
  Assert.AreEqual(LPendingId, LMessages[0].Id, 'the pending message survives pruning');
  Assert.AreEqual('m4', LMessages[1].Content);
  Assert.AreEqual('m5', LMessages[2].Content);
end;

procedure TStoreTests.Clear_RemovesConversation;
begin
  FStore.AddUserMessage(K, 'x');
  FStore.AddUserMessage('other', 'y');
  FStore.Clear(K);
  Assert.AreEqual(0, FStore.Count(K));
  Assert.AreEqual(1, FStore.Count('other'));
  FStore.ClearAll;
  Assert.AreEqual(0, FStore.Count('other'));
end;

procedure TStoreTests.Conversations_AreIsolated;
var
  LId: string;
  LMessage: THelpChatMessage;
begin
  LId := FStore.AddPendingAssistant('a');
  FStore.CompleteAssistant('b', LId, 'wrong key');
  FStore.TryGetMessage('a', LId, LMessage);
  Assert.IsTrue(LMessage.Pending, 'a message is reachable only through its own conversation');
  Assert.IsFalse(FStore.TryGetMessage('b', LId, LMessage));
end;

procedure TStoreTests.OnChange_FiresPerMutation;
var
  LUser: THelpChatMessage;
  LId: string;
begin
  FStore.OnChange := OnChange;
  LUser := FStore.AddUserMessage(K, 'q');
  LId := FStore.AddPendingAssistant(K);
  FStore.AppendAssistantToken(K, LId, 't');
  FStore.AppendAssistantToken(K, 'unknown', 't'); // no-op: no event
  FStore.CompleteAssistant(K, LId, 'done');
  FStore.Clear(K);
  Assert.AreEqual(5, Integer(FChanges.Count));
  Assert.AreEqual(K + ':' + LUser.Id, FChanges[0]);
  Assert.AreEqual(K + ':' + LId, FChanges[1]);
  Assert.AreEqual(K + ':' + LId, FChanges[2]);
  Assert.AreEqual(K + ':' + LId, FChanges[3]);
  Assert.AreEqual(K + ':', FChanges[4], 'clear reports an empty id');
end;

procedure TStoreTests.Json_RoundTrip_ExcludesPending;
var
  LJson, LFailedId: string;
  LCopy: THelpChatStore;
  LSrc, LDst: TArray<THelpChatMessage>;
  I: Integer;
begin
  FStore.AddUserMessage(K, 'q "quoted" à');
  FStore.CompleteAssistant(K, FStore.AddPendingAssistant(K), '**md**'#10'line2');
  FStore.AddSystemMessage(K, 'sys');
  LFailedId := FStore.AddPendingAssistant(K);
  FStore.FailAssistant(K, LFailedId, 'err');
  FStore.AddPendingAssistant(K); // excluded
  LJson := FStore.ToJSON(K);
  Assert.Contains(LJson, '"version":' + IntToStr(HELPCHAT_STORE_JSON_VERSION));

  LCopy := THelpChatStore.Create;
  try
    Assert.IsTrue(LCopy.FromJSON(K, LJson));
    LSrc := FStore.GetMessages(K);
    LDst := LCopy.GetMessages(K);
    Assert.AreEqual(4, Integer(Length(LDst)), 'pending excluded');
    for I := 0 to High(LDst) do
    begin
      Assert.AreEqual(LSrc[I].Id, LDst[I].Id);
      Assert.AreEqual(LSrc[I].Role, LDst[I].Role);
      Assert.AreEqual(LSrc[I].Content, LDst[I].Content);
      Assert.AreEqual(LSrc[I].IsError, LDst[I].IsError);
      Assert.IsFalse(LDst[I].Pending);
      Assert.IsTrue(Abs(LSrc[I].Created - LDst[I].Created) < 1 / SecsPerDay, 'created within one second');
    end;
  finally
    LCopy.Free;
  end;
end;

procedure TStoreTests.FromJson_Invalid_LeavesStoreUntouched;
begin
  FStore.AddUserMessage(K, 'keep me');
  Assert.IsFalse(FStore.FromJSON(K, 'not json'));
  Assert.IsFalse(FStore.FromJSON(K, '[1,2,3]'));
  Assert.IsFalse(FStore.FromJSON(K, '{"version":1}'));
  Assert.AreEqual(1, FStore.Count(K));
  Assert.AreEqual('keep me', FStore.GetMessages(K)[0].Content);
end;

procedure TStoreTests.FromJson_Expired_IsRejected;
var
  LOld, LFresh: string;
begin
  LOld := Format('{"version":1,"saved":"%s","messages":[{"id":"1","role":"user","content":"x"}]}',
    [DateToISO8601(IncDay(Now, -40), False)]);
  Assert.IsFalse(FStore.FromJSON(K, LOld, 30), 'older than 30 days');
  Assert.AreEqual(0, FStore.Count(K));
  Assert.IsTrue(FStore.FromJSON(K, LOld, 0), 'no expiry');
  Assert.AreEqual(1, FStore.Count(K));
  LFresh := Format('{"version":1,"saved":"%s","messages":[{"id":"1","role":"user","content":"x"}]}',
    [DateToISO8601(Now, False)]);
  Assert.IsTrue(FStore.FromJSON(K, LFresh, 30));
end;

procedure TStoreTests.File_SaveAndLoad;
var
  LFile: string;
  LCopy: THelpChatStore;
begin
  LFile := TempFileName;
  try
    FStore.AddUserMessage(K, 'persisted');
    FStore.SaveToFile(K, LFile);
    Assert.IsTrue(TFile.Exists(LFile));
    LCopy := THelpChatStore.Create;
    try
      Assert.IsTrue(LCopy.LoadFromFile(K, LFile));
      Assert.AreEqual('persisted', LCopy.GetMessages(K)[0].Content);
      Assert.IsFalse(LCopy.LoadFromFile(K, LFile + '.missing'));
    finally
      LCopy.Free;
    end;
  finally
    if TFile.Exists(LFile) then
      TFile.Delete(LFile);
  end;
end;

end.
