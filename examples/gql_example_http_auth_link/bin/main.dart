import "package:gql/language.dart";
import "package:gql_example_http_auth_link/http_auth_link.dart";
import "package:gql_http_link/gql_http_link.dart";
import "package:gql_exec/gql_exec.dart";
import "package:gql_link/gql_link.dart";
import "package:http/http.dart" as http;

final fakeHttpLink = Link.function(
  (request, [forward]) async* {
    final headers = request.context.entry<HttpLinkHeaders>();

    if (headers.headers["Authorization"] == null) {
      throw HttpLinkServerException(
        httpResponse: http.Response("", 401),
      );
    }

    yield Response(
      data: <String, String>{
        "authHeader": headers.headers["Authorization"],
      },
    );
  },
);

void main(List<String> arguments) async {
  final link = Link.from([
    HttpAuthLink(),
    fakeHttpLink,
  ]);

  try {
    final response = await link
        .request(
          Request(
            operation: Operation(
              document: parseString("{}"),
            ),
          ),
        )
        .first;

    print(response.data);
  } catch (e) {
    print(e);
  }
}
