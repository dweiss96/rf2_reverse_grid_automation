import 'dart:async';

class State {
  final Map<String, State> _transitions = {};
  String name;

  State(this.name);

  void addTransitionTo(String name, State end) {
    _transitions.putIfAbsent(name, () => end);
  }

  State? transition(String actionName) {
    if (_transitions.containsKey(actionName)) {
      return _transitions[actionName];
    }
    return null;
  }
}

class StateMachine {
  final List<State> _states;
  State currentState;
  StreamController sc = StreamController<String>();
  StateMachine(this.currentState) : _states = List.filled(1, currentState, growable: true);

  Stream stream() => sc.stream;

  void addState(State s) {
    _states.add(s);
  }

  bool transition(String actionName) {
    final resultState = currentState.transition(actionName);
    if (resultState == null) {
      return false;
    }

    currentState = resultState;
    sc.add(actionName);
    return true;
  }
}
