unit Runner_TestHungarian;
{$I KaM_Remake.inc}
interface
uses
  Unit_Runner;

type
  TKMRunnerTestHungarian = class(TKMRunnerCommon)
  protected
    function OnTickCondition(aTick: Cardinal): Boolean; override;
    procedure SetUp; override;
    procedure Execute(aRun: Integer); override;
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
  KM_UnitActionWalkTo, KM_UnitWarrior,
  KM_CampaignTypes,
  KM_HandSpectator, KM_ResHouses, KM_Hand, KM_HandTypes, KM_UnitsCollection, KM_UnitGroup,
  KM_GameSettings,
  KM_CommonTypes, KM_MapTypes, KM_FileIO, KM_Game, KM_GameInputProcess, KM_GameTypes, KM_InterfaceGame,
  KM_UnitGroupTypes,
  KM_ResTypes, KM_CampaignClasses, KM_Hungarian;

{ TKMRunnerTestHungarian }
procedure TKMRunnerTestHungarian.SetUp;
begin
  inherited;
  fResults.ValueCount := 0;
  DYNAMIC_TERRAIN := False;
  SHOW_UNIT_ROUTES := True;
  SHOW_GROUP_MEMBERS_POS := True;
  //SHOW_UNIT_ROUTES_STEPS := True;

  gGameApp.NewEmptyMap(64, 64);

  if gGame.ActiveInterface <> nil then
  begin
    gGame.ActiveInterface.Viewport.Zoom := 0.5;
    gGame.ActiveInterface.Viewport.Position := KMPointF(
      32,
      22
    );
  end;
    gHands[0].AddField(KMPoint(35, 19), ftCorn, 0, False, True);
    gHands[0].AddField(KMPoint(45, 19), ftCorn, 0, False, True);
//  gHands[0].AddField(KMPoint(45, 21), ftCorn, 0, False, True);
//  gHands[0].AddField(KMPoint(40, 34), ftCorn, 0, False, True);

  // Group 1: 30 * 7 = 210 units
  gHands[0].AddUnitGroup(utBowman, KMPoint(32, 30), TKMDirection(dirN), 30, 210);

  // Group 2: 30 * 7 = 210 units, 5 cells apart (started at Y=15, dirS means facing south)
  gHands[1].AddUnitGroup(utBowman, KMPoint(32, 20), TKMDirection(dirS), 30, 210);
end;

function TKMRunnerTestHungarian.OnTickCondition(aTick: Cardinal): Boolean;
var
  iH: Integer;
  iG: Integer;
  iM: Integer;
  distance: Integer;
  warrior: TKMUnitWarrior;
  action: TKMUnitActionWalkTo;
begin
  // Continue simulation (True) until one of armies are destroyed
  Result := (gHands[0].Stats.GetUnitQty(utAny) > 0)
    and (gHands[1].Stats.GetUnitQty(utAny) > 0);

  if not Result then
    Exit;

  for iH := 0 to 1 do
    for iG := 0 to gHands[iH].UnitGroups.Count - 1 do
      for iM := 0 to gHands[iH].UnitGroups.Groups[iG].Count - 1 do
        begin
          warrior := gHands[iH].UnitGroups.Groups[iG].Members[iM];
//          if not KMSamePoint(warrior.PositionNext, warrior.Position) then
          if warrior.Action is TKMUnitActionWalkTo then
          begin
            action := TKMUnitActionWalkTo(warrior.Action);
            distance := KMDistanceAbs(action.WalkFrom, action.WalkTo);
            // 11512047
            if distance > 7 then
              raise ETestFailed.Create('bug found');
          end;
        end;

end;

procedure TKMRunnerTestHungarian.Execute(aRun: Integer);
var
  Group1, Group2: TKMUnitGroup;
  I: Integer;
  Agents, Tasks: TKMPointList;
  NewOrder: TKMCardinalArray;
  MaxDist, Dist: Single;
begin
  SetKaMSeed(aRun + 1);

  SimulateGame;

  gGameApp.StopGame(grSilent);
end;

type
  TKMRunnerTestUnitGroupMemberDeath = class(TKMRunnerCommon)
  protected
    fGroup: TKMUnitGroup;
    function OnTickCondition(aTick: Cardinal): Boolean; override;
    procedure SetUp; override;
    procedure Execute(aRun: Integer); override;
  end;

procedure TKMRunnerTestUnitGroupMemberDeath.SetUp;
begin
  inherited;
  fResults.ValueCount := 0;
  DYNAMIC_TERRAIN := False;
  SHOW_UNIT_ROUTES := True;
  SHOW_GROUP_MEMBERS_POS := True;
  
  gGameApp.NewEmptyMap(64, 64);
  
//  if gGame.ActiveInterface <> nil then
//  begin
    gGame.ActiveInterface.Viewport.Zoom := 1;
    gGame.ActiveInterface.Viewport.Position := KMPointF(32, 18);
//  end;

  // Group: 10 * 6 = 60 units
  fGroup := gHands[0].AddUnitGroup(utBowman, KMPoint(32, 20), TKMDirection(dirS), 10, 60);
end;

function TKMRunnerTestUnitGroupMemberDeath.OnTickCondition(aTick: Cardinal): Boolean;
var
  iM: Integer;
  warrior: TKMUnitWarrior;
  action: TKMUnitActionWalkTo;
  distance: Integer;
begin
  Result := fGroup.Count > 0;
  if not Result then Exit;

  // Убиваем каждые 5 тиков юнита в первом ряду (индексы с 1 по 9)
  if aTick = 20 then
  begin
    iM := 1 + KaMRandom(Min(9, fGroup.Count - 1), 'шляпа');
    if iM < fGroup.Count then
    begin
      warrior := fGroup.Members[iM];
      warrior.Kill(0, False, False);
    end;
  end;
  
  // Успешность проверяется как отсутствие перехода более чем на 1 клетку
  for iM := 0 to fGroup.Count - 1 do
  begin
    warrior := fGroup.Members[iM];
    if warrior.Action is TKMUnitActionWalkTo then
    begin
      action := TKMUnitActionWalkTo(warrior.Action);
      distance := KMDistanceAbs(action.WalkFrom, action.WalkTo);
//      if distance > 1 then
//        raise ETestFailed.Create(Format('bug found: unit %d moving %d cells', [iM, distance]));
    end;
  end;

  if aTick = 150 then
    Result := False;
end;

procedure TKMRunnerTestUnitGroupMemberDeath.Execute(aRun: Integer);
begin
  SetKaMSeed(aRun + 1);
  SimulateGame;
  gGameApp.StopGame(grSilent);
end;

initialization
  RegisterRunner(TKMRunnerTestHungarian);
  RegisterRunner(TKMRunnerTestUnitGroupMemberDeath);
end.
