import 'dart:convert';
import 'dart:io';

void main() async {
  final server = await HttpServer.bind(
    InternetAddress.loopbackIPv4,
    80,
  );
  print('Listening on localhost:${server.port}');

  await for (HttpRequest req in server) {
    HttpResponse response = req.response;
    if (req.method == 'POST' && req.uri.path.startsWith('/hook')) {
      try {
        String content = await utf8.decoder.bind(req).join(); /*2*/
        var data = jsonDecode(content) as Map; /*3*/

        req.response
          ..statusCode = HttpStatus.ok
          ..write('Wrote data for $data.');
        print(content);
      } catch (e) {
        response
          ..statusCode = HttpStatus.internalServerError
          ..write("Exception during file I/O: $e.");
      }
    } else {
      response
        ..statusCode = HttpStatus.accepted
        ..write("ok");
    }

    await req.response.close();
  }
}
