import 'package:state_machine/state_machine.dart';

class RaceStateMachine {
  static final StateMachine _sm = StateMachine('race_states');

  static State practice = _sm.newState('practice');
  static State qualy = _sm.newState('qualy');
  static State warmup1 = _sm.newState('warmup1');
  static State grid1 = _sm.newState('grid1');
  static State race1 = _sm.newState('race1');
  static State unwantedRace = _sm.newState('unwanted_race');
  static State warmup2 = _sm.newState('warmup2');
  static State grid2 = _sm.newState('grid2');
  static State race2 = _sm.newState('race2');

  StateTransition goToQualy =
      _sm.newStateTransition("go_to_qualy", [practice], qualy);
  StateTransition goToWarmup1 =
      _sm.newStateTransition("go_to_warmup_1", [qualy], warmup1);
  StateTransition goToGrid1 =
      _sm.newStateTransition("go_to_grid_1", [warmup1], grid1);
  StateTransition goToRace1 =
      _sm.newStateTransition("go_to_race_1", [grid1], race1);
  StateTransition goToUnwantedRace =
      _sm.newStateTransition("go_to_unwanted", [race1], unwantedRace);
  StateTransition goToWarmup2 =
      _sm.newStateTransition("go_to_warmup_2", [unwantedRace], warmup2);
  StateTransition goToGrid2 =
      _sm.newStateTransition("go_to_grid_2", [warmup2], grid2);
  StateTransition goToRace2 =
      _sm.newStateTransition("go_to_race_2", [grid2], race2);
  StateTransition restartServer =
      _sm.newStateTransition("restart", [race2], practice);

  RaceStateMachine() {
    _sm.start(practice);
  }

  StateMachine getStateMachine() {
    return _sm;
  }
}
