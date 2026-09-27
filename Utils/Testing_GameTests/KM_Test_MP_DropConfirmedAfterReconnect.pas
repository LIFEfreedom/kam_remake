unit KM_Test_MP_DropConfirmedAfterReconnect;
{$I KaM_Remake.inc}
interface
uses
  KM_Test, KM_Test_MP, KM_TestMPParticipant;


type
  // Issue #356, the crash from the replays attached there.
  //
  // Coyottes loses his connection and the host starts dropping him, but Coyottes is back before the
  // host confirms. By then he has opened his message scroll, and the pack carrying that reached us.
  // Only after that does the host's confirmation arrive.
  //
  // A client that played the tick before the host's player list came in has already done what
  // Coyottes asked for, so we must do it too - otherwise the games part ways, and the next random
  // check crashes both of them
  TKMTest_MP_DropConfirmedAfterReconnect = class(TKMTestMultiplayer)
  private
    fCoyottes: TKMTestMPParticipant;
    fScrollTick: Cardinal;
  protected
    procedure AddPlayers; override;
    procedure SetUp; override;
    procedure DoTick(aTick: Cardinal; var aKeepGoing: Boolean); override;
  public
    class function TestTags: TKMTestTagSet; override;
    class function TestDescription: string; override;
  end;


implementation
uses
  SysUtils,
  KM_Points, KM_GameTypes, KM_ResTexts,
  KM_Game, KM_GameParams, KM_HandsCollection, KM_Hand, KM_MessageLog;

const
  COYOTTES_LOC = 2; // We take location 1
  COYOTTES_HAND = COYOTTES_LOC - 1; // Hands count from zero, locations from one
  ACT_AT_TICK = 10;


{ TKMTest_MP_DropConfirmedAfterReconnect }
procedure TKMTest_MP_DropConfirmedAfterReconnect.AddPlayers;
begin
  // Like the host of the game in the issue, ours only watches
  Session.Host.Spectate;
  fCoyottes := Session.AddParticipant('Coyottes', COYOTTES_LOC);
end;


procedure TKMTest_MP_DropConfirmedAfterReconnect.SetUp;
begin
  inherited;

  fDuration := 200;
  fScrollTick := 0;

  StartSession;
  Session.WatchSUTCommands;

  // Coyottes has one unread message in his scroll
  gGame.ShowMessage(mkHouse, TX_MSG_WOODCUTTER_DEPLETED, KMPOINT_ZERO, 0, COYOTTES_HAND);
end;


procedure TKMTest_MP_DropConfirmedAfterReconnect.DoTick(aTick: Cardinal; var aKeepGoing: Boolean);
begin
  AssertTrue(CaughtException = '', 'Nothing should have crashed while handling packets, but got ' + CaughtException);

  if (fScrollTick = 0) and (gGameParams.Tick >= ACT_AT_TICK) then
  begin
    // Coyottes' connection breaks, and his game reconnects
    fCoyottes.Reconnect;
    Session.PumpUntil(function: Boolean
                      begin
                        Result := not fCoyottes.Net.IsReconnecting or (fCoyottes.Error <> '');
                      end, 20000, 'Coyottes to reconnect');
    AssertTrue(fCoyottes.Error = '', 'Coyottes could not reconnect: ' + fCoyottes.Error);

    // Back in the game, he opens his message scroll
    fScrollTick := fCoyottes.OpenMessageScroll(1);
    Session.PumpUntil(function: Boolean
                      begin
                        Result := Session.SUTHasCommandsFrom(fCoyottes.Nickname, fScrollTick);
                      end, 5000, 'Coyottes'' command to reach us');

    // Only now does the host confirm the drop it began while Coyottes was away
    var listCountBefore := Session.SUTPlayersListCount;
    Session.HostDropsPlayer(fCoyottes.Nickname);
    Session.PumpUntil(function: Boolean
                      begin
                        Result := Session.SUTPlayersListCount > listCountBefore;
                      end, 5000, 'the host''s player list to reach us');
  end;

  if (fScrollTick > 0) and (gGameParams.Tick >= fScrollTick) then
  begin
    aKeepGoing := False;
    AssertTrue(not gHands[COYOTTES_HAND].MessageLog.HasNewMessages,
               Format('Coyottes opened his message scroll for tick %d, and it reached us before the host dropped him, ' +
                      'but we did not play it. A client that played that tick before the host''s player list ' +
                      'arrived did, and from here on our games differ', [fScrollTick]));
    Exit;
  end;

  if TimeIsOut then
    AssertFail(Format('The game should have reached tick %d, but stopped at %d', [fScrollTick, gGameParams.Tick]));
end;


class function TKMTest_MP_DropConfirmedAfterReconnect.TestTags: TKMTestTagSet;
begin
  Result := [tcMultiplayer, tcNetworking];
end;


class function TKMTest_MP_DropConfirmedAfterReconnect.TestDescription: string;
begin
  Result := 'A command from a player who came back before the host confirmed dropping him should still be played (issue 356).';
end;


initialization
  RegisterTest(TKMTest_MP_DropConfirmedAfterReconnect);
end.
