import 'package:rf2_double_race_manager/state_machine.dart';

abstract class RST {
  static const restartWeekend = "restart_weekend";
  static const goToQualy = "go_to_qualy";
  static const goToUnwantedRace = "go_to_unwanted_race";
  static const goToWarmup1 = "go_to_warmup_1";
  static const goToWarmup2 = "go_to_warmup_2";
  static const goToGrid1 = "go_to_grid_1";
  static const goToGrid2 = "go_to_grid_2";
  static const goToRace1 = "go_to_race_1";
  static const goToRace2 = "go_to_race_2";
}

class RaceStateMachine {
  static StateMachine initialize() {
    final practice = State("practice");
    final sm = StateMachine(practice);

    final race2 = State("race2");
    race2.addTransitionTo(RST.restartWeekend, practice);

    final grid2 = State("grid2");
    grid2.addTransitionTo(RST.goToRace2, race2);

    final warmup2 = State("warmup2");
    warmup2.addTransitionTo(RST.goToGrid2, grid2);

    final unwantedRace = State("unwanted_race");
    unwantedRace.addTransitionTo(RST.goToWarmup2, warmup2);

    final race1 = State("race1");
    race1.addTransitionTo(RST.goToUnwantedRace, unwantedRace);

    final grid1 = State("grid1");
    grid1.addTransitionTo(RST.goToRace1, race1);

    final warmup1 = State("warmup1");
    warmup1.addTransitionTo(RST.goToGrid1, grid1);

    final qualy = State("qualy");
    qualy.addTransitionTo(RST.goToWarmup1, warmup1);

    practice.addTransitionTo(RST.goToQualy, qualy);

    sm.addState(qualy);
    sm.addState(warmup1);
    sm.addState(grid1);
    sm.addState(race1);
    sm.addState(unwantedRace);
    sm.addState(warmup2);
    sm.addState(grid2);
    sm.addState(race2);

    return sm;
  }
}
