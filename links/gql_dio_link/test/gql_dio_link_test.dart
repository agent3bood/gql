// ignore_for_file: implicit_dynamic_method, unused_local_variable,implicit_dynamic_map_literal

import "dart:async";
import "dart:core";

import "package:collection/collection.dart";
import "package:dio/dio.dart" as dio;
import "package:gql/language.dart";
import "package:gql_dio_link/gql_dio_link.dart";
import "package:gql_exec/gql_exec.dart";
import "package:gql_link/gql_link.dart";
import "package:mockito/annotations.dart";
import "package:mockito/mockito.dart";
import "package:test/test.dart";
import "gql_dio_link_test.mocks.dart";

// class MockClient extends Mock implements dio.Dio {}
//
// class MockRequestSerializer extends Mock implements RequestSerializer {}
//
// class MockResponseParser extends Mock implements ResponseParser {}

extension on dio.Options {
  bool extEqual(Object o) {
    if (identical(this, o)) return true;
    final mapEquals = const DeepCollectionEquality().equals;
    return o is dio.Options &&
        o.method == method &&
        o.sendTimeout == sendTimeout &&
        o.receiveTimeout == receiveTimeout &&
        mapEquals(o.extra, extra) &&
        mapEquals(o.headers, headers) &&
        o.responseType == responseType &&
        o.contentType == contentType &&
        o.validateStatus == validateStatus &&
        o.maxRedirects == maxRedirects &&
        o.requestEncoder == requestEncoder &&
        o.responseDecoder == responseDecoder;
  }
}

// Adapted tests from ``gql_http_link`` tests
// https://github.com/gql-dart/gql/blob/master/gql_http_link/test/gql_http_link_test.dart
@GenerateMocks([dio.Dio, RequestSerializer])
void main() {
  group("DioLink", () {
    late MockDio client;
    late Request request;
    late String path;
    late DioLink link;

    final Stream<Response> Function([
      Request? customRequest,
    ]) execute = ([
      Request? customRequest,
    ]) =>
        link.request(customRequest ?? request);

    setUp(() {
      client = MockDio();
      request = Request(
        operation: Operation(
          document: parseString("query MyQuery {}"),
        ),
        variables: const <String, dynamic>{"i": 12},
      );
      path = "/graphql-test";
      link = DioLink(
        path,
        client: client,
      );
    });

    test("parses a successful response", () {
      when(
        client.post<dynamic>(
          any,
          data: anyNamed("data"),
          options: anyNamed("options"),
        ),
      ).thenAnswer(
        (_) => Future.value(
          dio.Response<Map<String, dynamic>>(
            data: <String, dynamic>{
              "data": <String, dynamic>{},
            },
            statusCode: 200,
            requestOptions: dio.RequestOptions(path: path),
          ),
        ),
      );

      expect(
        execute(),
        emitsInOrder(<dynamic>[
          Response(
            data: const <String, dynamic>{},
            errors: null,
            context: Context()
                .withEntry(
                  ResponseExtensions(null),
                )
                .withEntry(
                  DioLinkResponseContext(statusCode: 200),
                ),
          ),
          emitsDone,
        ]),
      );
    });

    test("uses the defined endpoint", () async {
      when(
        client.post<dynamic>(
          any,
          data: anyNamed("data"),
          options: anyNamed("options"),
        ),
      ).thenAnswer(
        (_) => Future.value(
          dio.Response<Map<String, dynamic>>(
            data: <String, dynamic>{
              "data": <String, dynamic>{},
            },
            statusCode: 200,
            requestOptions: dio.RequestOptions(path: path),
          ),
        ),
      );

      await execute().first;

      verify(
        client.post<dynamic>(
          path,
          data: anyNamed("data"),
          options: anyNamed("options"),
        ),
      ).called(1);
    });

    test("uses json mime types", () async {
      when(
        client.post<dynamic>(
          any,
          data: anyNamed("data"),
          options: anyNamed("options"),
        ),
      ).thenAnswer(
        (_) => Future.value(
          dio.Response<Map<String, dynamic>>(
            data: <String, dynamic>{
              "data": <String, dynamic>{},
            },
            statusCode: 200,
            requestOptions: dio.RequestOptions(path: path),
          ),
        ),
      );

      await execute().first;

      verify(
        client.post<dynamic>(
          any,
          data: anyNamed("data"),
          options: argThat(
            predicate((dio.Options o) => o.extEqual(dio.Options(
                  responseType: dio.ResponseType.json,
                  headers: <String, dynamic>{
                    dio.Headers.contentTypeHeader: "application/json",
                    "Accept": "*/*",
                  },
                ))),
            named: "options",
          ),
        ),
      ).called(1);
    });

    test("adds headers from context", () async {
      when(
        client.post<dynamic>(
          any,
          data: anyNamed("data"),
          options: anyNamed("options"),
        ),
      ).thenAnswer(
        (_) => Future.value(
          dio.Response<Map<String, dynamic>>(
            data: <String, dynamic>{
              "data": <String, dynamic>{},
            },
            statusCode: 200,
            requestOptions: dio.RequestOptions(path: path),
          ),
        ),
      );

      await execute(
        Request(
          operation: Operation(
            document: parseString("query MyQuery {}"),
          ),
          variables: const <String, dynamic>{"i": 12},
          context: Context.fromList(
            const [
              HttpLinkHeaders(
                headers: {
                  "foo": "bar",
                },
              ),
            ],
          ),
        ),
      ).first;

      verify(
        client.post<dynamic>(
          any,
          data: anyNamed("data"),
          options: argThat(
            predicate((dio.Options o) => o.extEqual(dio.Options(
                  responseType: dio.ResponseType.json,
                  headers: <String, dynamic>{
                    dio.Headers.contentTypeHeader: "application/json",
                    "Accept": "*/*",
                    "foo": "bar",
                  },
                ))),
            named: "options",
          ),
        ),
      ).called(1);
    });

    test("adds default headers", () async {
      final client = MockDio();
      final link = DioLink(
        path,
        client: client,
        defaultHeaders: {
          "foo": "bar",
        },
      );

      when(
        client.post<dynamic>(
          any,
          data: anyNamed("data"),
          options: anyNamed("options"),
        ),
      ).thenAnswer(
        (_) => Future.value(
          dio.Response<Map<String, dynamic>>(
            data: <String, dynamic>{
              "data": <String, dynamic>{},
            },
            statusCode: 200,
            requestOptions: dio.RequestOptions(path: path),
          ),
        ),
      );

      await link
          .request(
            Request(
              operation: Operation(
                document: parseString("query MyQuery {}"),
              ),
              variables: const <String, dynamic>{"i": 12},
            ),
          )
          .first;

      verify(
        client.post<dynamic>(
          any,
          data: anyNamed("data"),
          options: argThat(
            predicate((dio.Options o) => o.extEqual(dio.Options(
                    responseType: dio.ResponseType.json,
                    headers: <String, dynamic>{
                      dio.Headers.contentTypeHeader: "application/json",
                      "Accept": "*/*",
                      "foo": "bar",
                    }))),
            named: "options",
          ),
        ),
      ).called(1);
    });

    test("headers from context override defaults", () async {
      when(
        client.post<dynamic>(
          any,
          data: anyNamed("data"),
          options: anyNamed("options"),
        ),
      ).thenAnswer(
        (_) => Future.value(
          dio.Response<Map<String, dynamic>>(
            data: <String, dynamic>{
              "data": <String, dynamic>{},
            },
            statusCode: 200,
            requestOptions: dio.RequestOptions(path: path),
          ),
        ),
      );

      await execute(
        Request(
          operation: Operation(
            document: parseString("query MyQuery {}"),
          ),
          variables: const <String, dynamic>{"i": 12},
          context: Context.fromList(
            const [
              HttpLinkHeaders(
                headers: {
                  dio.Headers.contentTypeHeader: "application/jsonize",
                },
              ),
            ],
          ),
        ),
      ).first;

      verify(
        client.post<dynamic>(
          any,
          data: anyNamed("data"),
          options: argThat(
            predicate((dio.Options o) => o.extEqual(dio.Options(
                    responseType: dio.ResponseType.json,
                    headers: <String, dynamic>{
                      dio.Headers.contentTypeHeader: "application/jsonize",
                      "Accept": "*/*",
                    }))),
            named: "options",
          ),
        ),
      ).called(1);
    });

    test("serializes the request", () async {
      when(
        client.post<dynamic>(
          any,
          data: anyNamed("data"),
          options: anyNamed("options"),
        ),
      ).thenAnswer(
        (_) => Future.value(
          dio.Response<Map<String, dynamic>>(
            data: <String, dynamic>{
              "data": <String, dynamic>{},
            },
            statusCode: 200,
            requestOptions: dio.RequestOptions(path: path),
          ),
        ),
      );

      await execute().first;

      verify(
        client.post<dynamic>(
          any,
          data: argThat(
              equals({
                "operationName": null,
                "variables": {"i": 12},
                "query": "query MyQuery {\n  \n}"
              }),
              named: "data"),
          //"""{"operationName":null,"variables":{"i":12},"query":"query MyQuery {\\n  \\n}"}""",
          options: anyNamed("options"),
        ),
      ).called(1);
    });

    test("parses a successful response with errors", () async {
      when(
        client.post<dynamic>(
          any,
          data: anyNamed("data"),
          options: anyNamed("options"),
        ),
      ).thenAnswer(
        (_) => Future.value(
          dio.Response<Map<String, dynamic>>(
            data: <String, dynamic>{
              "errors": <Map<String, dynamic>>[
                <String, dynamic>{
                  "message": "Execution error",
                  "path": <dynamic>["friends", 0, "name"],
                  "extensions": <String, dynamic>{},
                  "locations": <Map<String, dynamic>>[
                    <String, dynamic>{
                      "line": 1,
                      "column": 1,
                    },
                  ],
                },
              ],
              "data": <String, dynamic>{},
            },
            statusCode: 200,
            requestOptions: dio.RequestOptions(path: path),
          ),
        ),
      );

      expect(
        execute(),
        emitsInOrder(<dynamic>[
          Response(
            data: const <String, dynamic>{},
            errors: const [
              GraphQLError(
                message: "Execution error",
                path: <dynamic>["friends", 0, "name"],
                extensions: <String, dynamic>{},
                locations: [
                  ErrorLocation(line: 1, column: 1),
                ],
              ),
            ],
            context: Context()
                .withEntry(
                  ResponseExtensions(null),
                )
                .withEntry(
                  DioLinkResponseContext(statusCode: 200),
                ),
          ),
          emitsDone,
        ]),
      );
    });

    test("throws DioLinkServerException when status code >= 300", () async {
      final dio.Response response = dio.Response<Map<String, dynamic>>(
        data: <String, dynamic>{
          "data": <String, dynamic>{"something": "random text 55656"},
        },
        statusCode: 300,
        requestOptions: dio.RequestOptions(path: path),
      );

      when(
        client.post<dynamic>(
          any,
          data: anyNamed("data"),
          options: anyNamed("options"),
        ),
      ).thenAnswer(
        (_) => Future.value(
          response,
        ),
      );

      DioLinkServerException? exception;

      try {
        await execute().first;
      } catch (e) {
        exception = e as DioLinkServerException;
      }

      expect(
        exception,
        TypeMatcher<DioLinkServerException>(),
      );
      expect(
        exception!.response.data,
        response.data,
      );
      expect(
        exception.response.statusCode,
        response.statusCode,
      );
      expect(
        exception.parsedResponse,
        equals(
          Response(
            data: const <String, dynamic>{
              "something": "random text 55656",
            },
            errors: null,
            context: Context().withEntry(
              ResponseExtensions(null),
            ),
          ),
        ),
      );
    });

    test("throws HttpLinkServerException when no data and errors", () async {
      final dio.Response response = dio.Response<Map<String, dynamic>>(
        data: <String, dynamic>{
          "test": <String, dynamic>{"something": "random text 55656"},
        },
        statusCode: 300,
        requestOptions: dio.RequestOptions(path: path),
      );

      when(
        client.post<dynamic>(
          any,
          data: anyNamed("data"),
          options: anyNamed("options"),
        ),
      ).thenAnswer(
        (_) => Future.value(
          response,
        ),
      );

      DioLinkServerException? exception;

      try {
        await execute().first;
      } catch (e) {
        exception = e as DioLinkServerException;
      }

      expect(
        exception,
        TypeMatcher<DioLinkServerException>(),
      );
      expect(
        exception!.response.data,
        response.data,
      );
      expect(
        exception.response.statusCode,
        response.statusCode,
      );
      expect(
        exception.parsedResponse,
        equals(
          Response(
              data: null,
              errors: null,
              context: Context().withEntry(
                ResponseExtensions(null),
              )),
        ),
      );
    });

    test("throws SerializerException when unable to serialize request",
        () async {
      final client = MockDio();
      final serializer = MockRequestSerializer();
      final link = DioLink(
        path,
        client: client,
        serializer: serializer,
      );

      final originalException = Exception("Foo bar");

      when(
        client.post<dynamic>(
          any,
          options: anyNamed("options"),
        ),
      ).thenAnswer(
        (_) => Future.value(dio.Response<Map<String, dynamic>>(
          data: <String, dynamic>{},
          statusCode: 200,
          requestOptions: dio.RequestOptions(path: path),
        )),
      );

      when(
        serializer.serializeRequest(
          any,
        ),
      ).thenThrow(originalException);

      RequestFormatException? exception;

      try {
        await link
            .request(
              Request(
                operation: Operation(
                  document: parseString("query MyQuery {}"),
                ),
                variables: const <String, dynamic>{"i": 12},
              ),
            )
            .first;
      } catch (e) {
        exception = e as RequestFormatException;
      }

      expect(
        exception,
        TypeMatcher<RequestFormatException>(),
      );
      expect(
        exception!.originalException,
        originalException,
      );
    });

    test("throws ParserException when unable to serialize request", () async {
      when(
        client.post<dynamic>(
          any,
          data: anyNamed("data"),
          options: anyNamed("options"),
        ),
      ).thenAnswer(
        (_) => Future.value(
          dio.Response<String>(
            data: "foobar",
            statusCode: 200,
            requestOptions: dio.RequestOptions(path: path),
          ),
        ),
      );

      ResponseFormatException? exception;

      try {
        await link
            .request(
              Request(
                operation: Operation(
                  document: parseString("query MyQuery {}"),
                ),
                variables: const <String, dynamic>{"i": 12},
              ),
            )
            .first;
      } catch (e) {
        exception = e as ResponseFormatException;
      }

      expect(
        exception,
        TypeMatcher<ResponseFormatException>(),
      );
      // expect(
      //   exception.originalException,
      //   TypeMatcher<FormatException>(),
      // );
    });

    test("closes the underlining http client", () {
      link.close(force: true);

      verify(
        client.close(force: true),
      ).called(1);
    });
  });
}
