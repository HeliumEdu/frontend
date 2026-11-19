import 'package:flutter_test/flutter_test.dart';
import 'package:heliumapp/presentation/features/auth/widgets/oauth_relink_prompt.dart';

void main() {
  test('the not-linked message says how to link it later', () {
    // WHEN
    final message = providerNotLinkedMessage('Microsoft');

    // THEN
    expect(
      message,
      "Microsoft wasn't linked. Sign in with Microsoft any time to link it "
      'again.',
    );
  });
}
