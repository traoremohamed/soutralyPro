import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/features/wallet/controllers/wallet_controller.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';
import 'package:ride_sharing_user_app/util/app_constants.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/styles.dart';
import 'package:url_launcher/url_launcher.dart';

class WaveRechargePage extends StatefulWidget {
  final String? initialAmount;
  final String paymentMethod;
  const WaveRechargePage(
      {super.key, this.initialAmount, this.paymentMethod = 'wave'});

  @override
  State<WaveRechargePage> createState() => _WaveRechargePageState();
}

class _WaveRechargePageState extends State<WaveRechargePage>
    with WidgetsBindingObserver {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _paymentNumberController =
      TextEditingController();
  bool _isLoading = false;
  bool _isWaitingForWaveResult = false;
  bool _isCheckingWaveResult = false;
  double _walletBeforePayment = 0;

  bool get _hasValidAmount {
    final parsed = double.tryParse(_amountController.text.trim());
    return parsed != null && parsed > 0;
  }

  bool get _hasValidPaymentNumber {
    final normalized =
        _normalizePaymentNumber(_paymentNumberController.text.trim());
    return normalized.length == 10;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _amountController.text = '';
    _amountController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    final profilePhone =
        Get.find<ProfileController>().profileInfo?.phone?.toString() ?? '';
    _paymentNumberController.text = _normalizePaymentNumber(profilePhone);
    _paymentNumberController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _amountController.dispose();
    _paymentNumberController.dispose();
    super.dispose();
  }

  String _normalizePaymentNumber(String raw) {
    String digits = raw.replaceAll(RegExp(r'\D+'), '');
    if (digits.startsWith('225') && digits.length > 10) {
      digits = digits.substring(3);
    }
    if (digits.length > 10) {
      digits = digits.substring(digits.length - 10);
    }
    return digits.length == 10 ? digits : '';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isWaitingForWaveResult) {
      _syncWalletAfterWaveReturn();
    }
  }

  String? _extractLaunchUrl(dynamic body) {
    if (body is! Map) return null;
    final dynamic data = body['data'];
    if (data is Map) {
      final String? nested = data['launch_url']?.toString();
      if (nested != null && nested.isNotEmpty) {
        return nested;
      }
    }
    final String? topLevel = body['launch_url']?.toString();
    if (topLevel != null && topLevel.isNotEmpty) {
      return topLevel;
    }
    return null;
  }

  Future<void> _startWavePayment() async {
    final profile = Get.find<ProfileController>();
    final walletController = Get.find<WalletController>();
    final amount = _amountController.text.trim();

    final parsedAmount = double.tryParse(amount);
    if (parsedAmount == null || parsedAmount <= 0) {
      Get.snackbar('Erreur', 'Montant invalide');
      return;
    }

    final paymentNumber =
        _normalizePaymentNumber(_paymentNumberController.text.trim());
    if (paymentNumber.isEmpty) {
      Get.snackbar('Erreur', 'Numero a debiter invalide (10 chiffres)');
      return;
    }

    _walletBeforePayment = profile.profileInfo?.wallet?.walletBalance ?? 0;

    setState(() => _isLoading = true);
    final userId = profile.driverId;
    final bool isOrange = widget.paymentMethod.toLowerCase() == 'orange_money';
    final successUrl = isOrange
        ? '${AppConstants.baseUrl}/payments/om/callback'
        : '${AppConstants.baseUrl}/wave/success';
    final errorUrl = isOrange
        ? '${AppConstants.baseUrl}/payments/om/cancel'
        : '${AppConstants.baseUrl}/wave/cancel';

    final resp = await walletController.initiatePaymentSession(
      userId,
      amount,
      widget.paymentMethod,
      paymentNumber: paymentNumber,
      successUrl: successUrl,
      errorUrl: errorUrl,
      cancelUrl: errorUrl,
    );

    if (!mounted) {
      return;
    }
    setState(() => _isLoading = false);

    if (resp == null || resp.statusCode != 200) {
      return;
    }

    final waveLaunchUrl = _extractLaunchUrl(resp.body);
    if (waveLaunchUrl == null) {
      Get.snackbar('Erreur', 'Lien de paiement introuvable');
      return;
    }

    final waveUri = Uri.tryParse(waveLaunchUrl);
    if (waveUri == null) {
      Get.snackbar('Erreur', 'URL de paiement invalide');
      return;
    }

    final opened = await launchUrl(
      waveUri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened) {
      showCustomSnackBar('Impossible d\'ouvrir le paiement');
      return;
    }

    _isWaitingForWaveResult = true;

    showCustomSnackBar(
      'Lien de paiement ouvert, finalisez la transaction puis revenez dans l\'app.',
      isError: false,
    );
  }

  Future<void> _syncWalletAfterWaveReturn() async {
    if (_isCheckingWaveResult) {
      return;
    }

    _isCheckingWaveResult = true;
    final profileController = Get.find<ProfileController>();
    double latestWallet = _walletBeforePayment;
    bool paymentDetected = false;

    for (int i = 0; i < 5; i++) {
      await profileController.getProfileInfo();
      latestWallet = profileController.profileInfo?.wallet?.walletBalance ??
          _walletBeforePayment;

      if (latestWallet > _walletBeforePayment) {
        paymentDetected = true;
        break;
      }

      if (i < 4) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    _isCheckingWaveResult = false;
    if (!mounted) {
      return;
    }

    if (paymentDetected) {
      _isWaitingForWaveResult = false;
      showCustomSnackBar('recharge_successful'.tr, isError: false);
      // Keep dashboard stack (bottom tabs) alive by just closing this page.
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.paymentMethod.toLowerCase() == 'orange_money'
              ? 'Rechargement Orange Money'
              : 'Rechargement WAVE')),
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
              decoration: const InputDecoration(hintText: 'Entrer le montant'),
            ),
            const SizedBox(height: 12),
            Text('Numero a debiter', style: textBold),
            const SizedBox(height: 8),
            TextField(
              controller: _paymentNumberController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  hintText: 'Ex: +2250504049192 ou 0504049192'),
              onChanged: (value) {
                final normalized = _normalizePaymentNumber(value);
                if (normalized != value && normalized.isNotEmpty) {
                  _paymentNumberController.value = TextEditingValue(
                    text: normalized,
                    selection:
                        TextSelection.collapsed(offset: normalized.length),
                  );
                }
              },
            ),
            const SizedBox(height: 24),
            Text('Wallet', style: textBold),
            const SizedBox(height: 8),
            // The app uses user account wallet by default - display balance
            Text('Votre wallet (utilisé pour payer vos forfaits/commissions)'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A00),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFFFB067),
                  disabledForegroundColor: Colors.white70,
                ),
                onPressed:
                    (_isLoading || !_hasValidAmount || !_hasValidPaymentNumber)
                        ? null
                        : _startWavePayment,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(widget.paymentMethod.toLowerCase() == 'orange_money'
                        ? 'Payer par Orange Money'
                        : 'Payer par WAVE'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
