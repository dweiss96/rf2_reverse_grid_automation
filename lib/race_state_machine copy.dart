import 'package:rf2_double_race_manager/state_machine.dart';

class RaceStateMachine {
  static StateMachine initialize() {
    final practice = State("practice");
    final _sm = StateMachine(practice);

    final race2 = State("race2");
    race2.addTransitionTo("restart_server", practice);

    final grid2 = State("grid2");
    grid2.addTransitionTo("go_to_race_2", race2);

    final warmup2 = State("warmup2");
    warmup2.addTransitionTo("go_to_grid_2", grid2);

    final unwantedRace = State("unwanted_race");
    unwantedRace.addTransitionTo("go_to_warmup_2", warmup2);

    final race1 = State("race1");
    race1.addTransitionTo("go_to_unwanted_race", unwantedRace);

    final grid1 = State("grid1");
    grid1.addTransitionTo("go_to_race_1", race1);

    final warmup1 = State("warmup1");
    warmup1.addTransitionTo("go_to_grid_1", grid1);

    final qualy = State("qualy");
    qualy.addTransitionTo("go_to_warmup_1", warmup1);

    practice.addTransitionTo("go_to_qualy", qualy);

    _sm.addState(qualy);
    _sm.addState(warmup1);
    _sm.addState(grid1);
    _sm.addState(race1);
    _sm.addState(unwantedRace);
    _sm.addState(warmup2);
    _sm.addState(grid2);
    _sm.addState(race2);

    return _sm;
  }
}
