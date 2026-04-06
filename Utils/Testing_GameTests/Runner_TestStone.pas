unit Runner_TestStone;
{$I KaM_Remake.inc}
interface
uses
  Unit_Runner;

type
  TKMRunnerStone = class(TKMRunnerCommon)
  protected
    procedure SetUp; override;
    procedure Execute(aRun: Integer); override;
    procedure TearDown; override;
  end;

implementation
uses
  Windows, SysUtils, Classes, Math,
  Generics.Collections, Generics.Defaults,
  KM_CommonClasses, KM_Defaults, KM_Points, KM_CommonUtils,
  KM_GameApp, KM_Log, KM_HandsCollection, KM_HouseCollection, KM_Resource,
  KM_Terrain, KM_Units, KM_Campaigns, KM_Houses,
  KM_GameParams,
  KM_Exceptions,
  KM_CampaignTypes,
  KM_HandSpectator, KM_ResHouses, KM_Hand, KM_HandTypes, KM_UnitsCollection, KM_UnitGroup,
  KM_GameSettings,
  KM_CommonTypes, KM_MapTypes, KM_FileIO, KM_Game, KM_GameInputProcess, KM_GameTypes, KM_InterfaceGame,
  KM_UnitGroupTypes,
  KM_ResTypes, KM_CampaignClasses;

{ TKMRunnerStone }
procedure TKMRunnerStone.SetUp;
begin
  inherited;
  fResults.ValueCount := 1;
//  fResults.TimesCount := 0;

  //FEAT_AI_GENERATE_INFLUENCE := False;
  //FEAT_AI_GENERATE_NAVMESH := False;
  DYNAMIC_TERRAIN := False;
end;


procedure TKMRunnerStone.TearDown;
begin
  inherited;
  //FEAT_AI_GENERATE_INFLUENCE := True;
  //FEAT_AI_GENERATE_NAVMESH := True;
  DYNAMIC_TERRAIN := True;
end;


procedure TKMRunnerStone.Execute(aRun: Integer);
begin
  gGameApp.NewEmptyMap(32, 32);

  SetKaMSeed(aRun+1);

  // Set a stone deposit for mining
  // 132 is a base tile ID for Stone (tkStone)
  gTerrain.ScriptTrySetTile(16, 10, 132, 0);

  // Set the quarry house
  gHands[0].AddHouse(htQuarry, 16, 16, False);
  
  // Add the stonemason unit just outside the house
  gHands[0].AddUnit(utStonemason, KMPoint(16, 17));

  // Run the simulation loop
  SimulateGame;

  // The stonemason should have found the stone, mined it, and delivered it.
  fResults.Value[aRun, 0] := gHands[0].Stats.GetWaresProduced(wtStone);

  AssertTrue(fResults.Value[aRun, 0] > 0, 'Stonemason should have mined some stone');

  gGameApp.StopGame(grSilent);
end;

initialization
  RegisterRunner(TKMRunnerStone);
end.
