unit KM_Test_MP_DroppedPlayerStaysOut;
{$I KaM_Remake.inc}
interface
uses
  KM_Test, KM_Test_MP, KM_TestMPParticipant;


type
  // The host drops a player who is still connected: the game has been waiting for him, or he came
  // back while the host was confirming the drop, as in issue #356. The server kicks him, and his game
  // tries to get back in, as it does after any lost connection.
  //
  // The host must not let him back, and once his connection is gone the game has to go on without him
  TKMTest_MP_DroppedPlayerStaysOut = class(TKMTestMultiplayer)
  private
    fCoyottes: TKMTestMPParticipant;
    fLastTickFromHim: Cardinal;
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
  KM_GameParams;

const
  COYOTTES_LOC = 2; // We take location 1
  ACT_AT_TICK = 10;


{ TKMTest_MP_DroppedPlayerStaysOut }
procedure TKMTest_MP_DroppedPlayerStaysOut.AddPlayers;
begin
  Session.Host.Spectate;
  fCoyottes := Session.AddParticipant('Coyottes', COYOTTES_LOC);
end;


procedure TKMTest_MP_DroppedPlayerStaysOut.SetUp;
begin
  inherited;

  fDuration := 200;
  fLastTickFromHim := 0;

  StartSession;
end;


procedure TKMTest_MP_DroppedPlayerStaysOut.DoTick(aTick: Cardinal; var aKeepGoing: Boolean);
begin
  AssertTrue(CaughtException = '', 'Nothing should have crashed while handling packets, but got ' + CaughtException);

  if (fLastTickFromHim = 0) and (gGameParams.Tick >= ACT_AT_TICK) then
  begin
    var slotOnHost := Session.Host.Net.Room.NicknameToLocal(fCoyottes.Nickname);

    // Coyottes is still connected when the host drops him, so the server kicks him
    Session.HostDropsPlayer(fCoyottes.Nickname);
    Session.PumpUntil(function: Boolean
                      begin
                        Result := not fCoyottes.Playing and not fCoyottes.Net.Connected
                                  and not Session.Host.Net.Room[slotOnHost].Connected;
                      end, 5000, 'Coyottes to be kicked');

    // His game tries to get back in, as it does after any lost connection (TKMGame.GameMPDisconnect)
    fCoyottes.Reconnect;
    Session.PumpUntil(function: Boolean
                      begin
                        Result := Session.Host.Net.Room[slotOnHost].Connected or (fCoyottes.Error <> '');
                      end, 20000, 'the host to answer Coyottes');
    AssertTrue(not Session.Host.Net.Room[slotOnHost].Connected,
               'The host dropped Coyottes while he was still connected, but then let him back into the game');

    // Nothing more can come from him. The game waits for his commands until the host, seeing it wait,
    // drops him again
    fLastTickFromHim := fCoyottes.HighestSentTick;
    Session.HostDropsPlayer(fCoyottes.Nickname);
  end;

  if (fLastTickFromHim > 0) and (gGameParams.Tick > fLastTickFromHim) then
  begin
    aKeepGoing := False;
    Exit;
  end;

  if TimeIsOut then
    AssertFail(Format('The game should have gone on past tick %d without Coyottes, but stopped at %d',
                      [fLastTickFromHim, gGameParams.Tick]));
end;


class function TKMTest_MP_DroppedPlayerStaysOut.TestTags: TKMTestTagSet;
begin
  Result := [tcMultiplayer, tcNetworking];
end;


class function TKMTest_MP_DroppedPlayerStaysOut.TestDescription: string;
begin
  Result := 'A player the host drops while he is still connected should not get back in, and the game should go on without him.';
end;


initialization
  RegisterTest(TKMTest_MP_DroppedPlayerStaysOut);
end.
