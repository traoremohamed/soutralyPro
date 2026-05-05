import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/data/api_client.dart';
import 'package:ride_sharing_user_app/features/wallet/domain/repositories/wallet_repository.dart';

class FakeApiClient implements ApiClient {
  @override
  // ignore: avoid_unused_constructor_parameters
  Future<Response> postData(String uri, dynamic body,
      {Map<String, String>? headers}) async {
    return Response(
        statusCode: 200, body: {'success': true, 'amount': body['amount']});
  }

  // The rest of ApiClient members are not used in this test, so we provide stubs.
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('mockRecharge repository posts user_id and amount and returns 200',
      () async {
    final fakeApi = FakeApiClient();
    final repo = WalletRepository(apiClient: fakeApi);

    final resp = await repo.mockRecharge('123', '500');

    expect(resp, isNotNull);
    expect(resp!.statusCode, 200);
    expect(resp.body['amount'], '500');
  });
}
