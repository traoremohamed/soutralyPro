import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/wallet/controllers/wallet_controller.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/features/profile/domain/models/profile_model.dart';
import 'package:ride_sharing_user_app/features/wallet/screens/wallet_screen.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class WaveRechargePage extends StatefulWidget {
  final String? initialAmount;
  const WaveRechargePage({super.key, this.initialAmount});

  @override
  State<WaveRechargePage> createState() => _WaveRechargePageState();
}

class _WaveRechargePageState extends State<WaveRechargePage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialAmount != null && widget.initialAmount!.isNotEmpty) {
      _amountController.text = widget.initialAmount!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = Get.find<ProfileController>();
    final walletController = Get.find<WalletController>();

    return Scaffold(
      appBar: AppBar(title: Text('Rechargement WAVE')),
      body: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Montant', style: textBold),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Enter amount'),
            ),
            const SizedBox(height: 16),
            Text('Numéro WAVE', style: textBold),
            const SizedBox(height: 8),
            Row(children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(6)),
                child: Text('+225'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _numberController,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  decoration: const InputDecoration(hintText: 'XXXXXXXXXX'),
                ),
              ),
            ]),
            const SizedBox(height: 24),
            Text('Wallet', style: textBold),
            const SizedBox(height: 8),
            // The app uses user account wallet by default - display balance
            Text('Votre wallet (utilisé pour payer forfaits/commissions)'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        final amount = _amountController.text.trim();
                        final number = _numberController.text.trim();
                        if (amount.isEmpty || double.tryParse(amount) == null) {
                          Get.snackbar('Erreur', 'Montant invalide');
                          return;
                        }
                        if (number.length != 10 ||
                            int.tryParse(number) == null) {
                          Get.snackbar(
                              'Erreur', 'Numéro WAVE invalide (10 chiffres)');
                          return;
                        }

                        setState(() => _isLoading = true);
                        final userId = profile.driverId;
                        final resp = await walletController
                            .mockRecharge(userId, amount, waveNumber: number);
                        setState(() => _isLoading = false);
                        if (resp != null && resp.statusCode == 200) {
                          // if backend returned updated wallet balance, update local profile model
                          try {
                            final body = resp.body;
                            if (body is Map &&
                                body.containsKey('wallet_balance')) {
                              final wb = double.tryParse(
                                      '${body['wallet_balance']}') ??
                                  null;
                              if (wb != null) {
                                profile.profileInfo ??= profile.profileInfo;
                                profile.profileInfo?.wallet ??= null;
                                try {
                                  profile.profileInfo!.wallet =
                                      profile.profileInfo!.wallet ??
                                          (Wallet(walletBalance: wb));
                                } catch (_) {}
                                // set walletBalance and payableBalance to reflect the top-up
                                profile.profileInfo!.wallet!.walletBalance = wb;
                                profile.profileInfo!.wallet!.payableBalance =
                                    wb;
                                profile.update();
                              }
                            }
                          } catch (_) {}
                          Get.offAll(() => const WalletScreenMenu());
                          Get.snackbar('Succès', 'Recharge effectuée');
                        }
                      },
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text('Payer par WAVE'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
