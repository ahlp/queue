import 'package:queue/src/github/pr.dart';
import 'package:queue/src/queue/queue_manager.dart';
import 'package:test/test.dart';

void main() {
  group(QueueManager, () {
    group('.add', () {
      test('complete task and show that is not running', () async {
        PR pr = PR(0);
        final _task = (Iterable<PR> prs) async {
          await Future.delayed(Duration(milliseconds: 1));
          return QueueResult<PR>(QueueResultState.success, results: prs);
        };

        final queue = QueueManager<PR>(_task);
        queue.add(pr);
        QueueResult<PR> result = await queue.task;
        assert(result.success);
        assert(result.results.length == 1);
        assert(result.results.first.id == pr.id);
        assert(!queue.isRunning);
      });
      test('retry splitting up the failed queue', () async {
        PR pr = PR(0);
        PR pr1 = PR(1);
        PR pr2 = PR(2);
        final _task = (Iterable<PR> prs) async {
          if (prs.length == 1) {
            await Future.delayed(Duration(milliseconds: 1));
            return QueueResult<PR>(QueueResultState.success, results: prs);
          } else if (prs.length == 2) {
            await Future.delayed(Duration(milliseconds: 2));
            return QueueResult<PR>(QueueResultState.failure, results: prs);
          } else {
            throw Exception('test fail');
          }
        };

        final queue = QueueManager<PR>(_task);
        queue.add(pr);
        queue.add(pr1);
        queue.add(pr2);
        QueueResult<PR> result = await queue.task;
        assert(result.success);
        assert(result.results.length == 1);
        assert(result.results.first.id == pr.id);
        result = await queue.task;
        assert(!result.idle);
        assert(!result.success);
        assert(result.results.length == 2);
        assert(result.results.first.id == pr1.id);
        assert(result.results.last.id == pr2.id);
        result = await queue.task;
        assert(result.success);
        assert(result.results.length == 1);
        assert(result.results.first.id == pr1.id);
        result = await queue.task;
        assert(result.success);
        assert(result.results.length == 1);
        assert(result.results.first.id == pr2.id);
      });
      test('retry splitting up 3 items in a group with 2/1 items', () async {
        PR pr = PR(0);
        PR pr1 = PR(1);
        PR pr2 = PR(2);
        PR pr3 = PR(3);
        final _task = (Iterable<PR> prs) async {
          if (prs.length < 3) {
            await Future.delayed(Duration(milliseconds: 1));
            return QueueResult<PR>(QueueResultState.success, results: prs);
          } else if (prs.length == 3) {
            await Future.delayed(Duration(milliseconds: 2));
            return QueueResult<PR>(QueueResultState.failure, results: prs);
          } else {
            throw Exception('test fail');
          }
        };

        final queue = QueueManager<PR>(_task);
        queue.add(pr);
        queue.add(pr1);
        queue.add(pr2);
        queue.add(pr3);
        QueueResult<PR> result = await queue.task;
        assert(result.success);
        assert(result.results.length == 1);
        assert(result.results.first.id == pr.id);
        result = await queue.task;
        assert(!result.idle);
        assert(!result.success);
        assert(result.results.length == 3);
        result = await queue.task;
        assert(result.success);
        assert(result.results.length == 2);
        assert(result.results.first.id == pr1.id);
        assert(result.results.last.id == pr2.id);
        result = await queue.task;
        assert(result.success);
        assert(result.results.length == 1);
        assert(result.results.first.id == pr3.id);
      });
      test('Don\'t retry if fails alone', () async {
        PR pr = PR(0);
        final _task = (Iterable<PR> prs) async {
          await Future.delayed(Duration(milliseconds: 1));
          return QueueResult<PR>(QueueResultState.failure, results: prs);
        };

        final queue = QueueManager<PR>(_task);
        queue.add(pr);
        QueueResult<PR> result = await queue.task;
        assert(!result.success);
        assert(result.results.length == 1);
        assert(result.results.first.id == pr.id);
        assert(!queue.isRunning);
      });
    });
  });
}
