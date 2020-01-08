import 'dart:async';
import 'dart:collection';

enum QueueResultState { success, failure, idle }

class QueueResult<NodeType> {
  QueueResult(this._resultState, {this.results: const []});
  final QueueResultState _resultState;
  final Iterable<NodeType> results;
  bool get success => _resultState == QueueResultState.success;
  bool get idle => _resultState == QueueResultState.idle;
}

class QueueManager<NodeType> {
  QueueManager(this._task);
  final Future<QueueResult<NodeType>> Function(Iterable<NodeType>) _task;

  Queue<List<NodeType>> _waiting = Queue();
  List<NodeType> _running = [];
  bool get isRunning => _running.isNotEmpty;
  Future<QueueResult<NodeType>> _runningTask =
      Future.value(QueueResult(QueueResultState.idle));
  Future<QueueResult<NodeType>> get task async => await _runningTask;

  void add(NodeType node, {runTask: true}) {
    if (_waiting.isEmpty) {
      _waiting.add([node]);
    } else {
      _waiting.last.add(node);
    }
    if (runTask) {
      run();
    }
  }

  void remove(NodeType node) {
    // TODO
  }

  Future<QueueResult<NodeType>> _run() async {
    final result = await _task(_running);
    _complete(result);
    return result;
  }

  void run() {
    if (!isRunning && _waiting.isNotEmpty) {
      _running = _waiting.removeFirst();
      _runningTask = _run();
    }
  }

  void _complete(QueueResult result) {
    if (!result.success && _running.length > 1) {
        final half = (_running.length / 2).ceil();
        _waiting.add(_running.sublist(0, half));
        _waiting.add(_running.sublist(half));
        _waiting.removeWhere((nodes) => nodes.isEmpty);
    }
    _running = [];
    run();
  }
}
