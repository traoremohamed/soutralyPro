import 'package:get/get.dart';

class DynamicTranslationHelper {
  static const Map<String, String> frenchTranslations = {
    'fund added digitally': 'Fonds ajoutes numeriquement',
    'fund_added_digitally': 'Fonds ajoutes numeriquement',
    'debited from wallet': 'Debite du portefeuille',
    'debited_from_wallet': 'Debite du portefeuille',
    'digital payment successful': 'Paiement numerique effectue avec succes',
    'digital_payment_successful': 'Paiement numerique effectue avec succes',
    'payment successful': 'Paiement effectue avec succes',
    'payment_successful': 'Paiement effectue avec succes',
    'parcel_refund_request': 'Demande de remboursement de colis',
    'parcel_refund_request_approved':
        'Demande de remboursement de colis approuvee',
    'new_ride_request': 'Nouvelle demande de course',
    'new_parcel_request': 'Nouvelle demande de colis',
    'referral_reward_received': 'Prime de parrainage recue',
    'someone_used_your_code': 'Quelqu un a utilise votre code',
    'new_message': 'Nouveau message',
    'review_from_driver': 'Avis recu du chauffeur',
    'review_from_customer': 'Avis recu du client',
    'vehicle_active': 'Vehicule active',
    'vehicle_request_approved': 'Demande de vehicule approuvee',
    'vehicle_request_denied': 'Demande de vehicule refusee',
    'legal_updated': 'Informations legales mises a jour',
    'terms_and_conditions_updated': 'Conditions generales mises a jour',
    'privacy_policy_updated': 'Politique de confidentialite mise a jour',
    'withdraw_request_rejected': 'Demande de retrait rejetee',
    'withdraw_request_settled': 'Demande de retrait reglee',
    'withdraw_request_approved': 'Demande de retrait approuvee',
    'withdraw_request_reversed': 'Demande de retrait annulee',
    'safety_problem_resolved': 'Probleme de securite resolu',
    'refund_accepted': 'Remboursement accepte',
    'refund_denied': 'Remboursement refuse',
    'parcel_amount_debited': 'Montant du colis debite',
    'parcel_amount_deducted': 'Montant du colis deduit',
    'refunded_as_coupon': 'Remboursement effectue en coupon',
    'refunded_to_wallet': 'Remboursement effectue sur le portefeuille',
    'tips_from_customer': 'Pourboire recu du client',
    'cash_in_hand_limit_exceeds': 'Limite de cash en main depassee',
    'parcel_returning_otp': 'OTP de retour du colis',
    'schedule_ride_started': 'Course programmee demarree',
    'trip_started': 'Trajet demarre',
    'parcel_returned': 'Colis retourne',
    'parcel_canceled_after_trip_started':
        'Colis annule apres le debut du trajet',
    'driver_canceled_ride_request':
        'Le chauffeur a annule la demande de course',
    'another_driver_assigned': 'Un autre chauffeur a ete assigne',
    'schedule_trip_accepted_by_driver':
        'Course programmee acceptee par le chauffeur',
    'driver_on_the_way': 'Le chauffeur est en route',
    'received_new_bid': 'Nouvelle offre recue',
    'driver_on_the_way_to_pickup_location':
        'Le chauffeur est en route vers le point de prise en charge',
    'bid_accepted': 'Offre acceptee',
    'customer_canceled_the_trip': 'Le client a annule le trajet',
    'customer_canceled_trip': 'Le client a annule le trajet',
    'coupon_removed': 'Coupon retire',
    'customer_rejected_bid': 'Offre refusee par le client',
    'trip_canceled': 'Trajet annule',
    'trip_cancelled': 'Trajet annule',
    'trip_completed': 'Trajet termine',
    'coupon_applied': 'Coupon applique',
    'level_up': 'Niveau superieur',
    'registration_approved': 'Inscription approuvee',
    'identity_image_approved': 'Image d identite approuvee',
    'identity_image_rejected': 'Image d identite rejetee',
    'fund_added_by_admin': 'Fonds ajoutes par l administrateur',
    'face_verification_completed_successfully':
        'Verification du visage terminee avec succes',
    'driver_daily_forfait': 'Achat de forfait',
    'admin_commission': 'Prelevement de commission',
    'pending': 'En attente',
    'approved': 'Approuve',
    'denied': 'Refuse',
    'settled': 'Regle',
    'completed': 'Termine',
    'cancelled': 'Annule',
    'canceled': 'Annule',
    'ongoing': 'En cours',
    'returned': 'Retourne',
    'returning': 'En retour',
    'accepted': 'Accepte',
    'processing': 'En traitement',
    'success': 'Succes',
    'failed': 'Echec',
    'wallet': 'Portefeuille',
    'commission': 'Commission',
    'forfait': 'Forfait',
    'recharge': 'Recharge',
    'cash': 'Espece',
    'cash_payment': 'Paiement en espece',
    'wallet_payment': 'Paiement par portefeuille',
    'orange_money': 'Orange Money',
    'wave': 'Wave',
    'online': 'En ligne',
    'offline': 'Hors ligne',
    'parcel': 'Colis',
    'ride': 'Course',
    'trip': 'Trajet',
    'passport': 'Passeport',
    'national_id': 'Carte nationale d identite',
    'nid': 'Carte nationale d identite',
    'driving_license': 'Permis de conduire',
    'trade_license': 'Patente',
    'motor_bike': 'Moto',
    'motorbike': 'Moto',
    'car': 'Voiture',
    'sedan': 'Berline',
    'pickup': 'Pickup',
    'suv': 'SUV',
    'parcel_delivery': 'Livraison de colis',
    'ride_share': 'Course',
    'admin_collected_cash': 'Encaissement admin du cash',
    'safety_alert_sent_successfully': 'Alerte de securite envoyee avec succes',
    'safety_alert_resolved_successfully':
        'Alerte de securite resolue avec succes',
    'safety_alert_undone_successfully':
        'Alerte de securite annulee avec succes',
  };

  static const Map<String, String> _tokenMap = {
    'wallet': 'portefeuille',
    'fund': 'fonds',
    'added': 'ajoutes',
    'digitally': 'numeriquement',
    'digital': 'numerique',
    'payment': 'paiement',
    'successful': 'effectue avec succes',
    'debited': 'debite',
    'from': 'du',
    'request': 'demande',
    'parcel': 'colis',
    'refund': 'remboursement',
    'approved': 'approuvee',
    'rejected': 'rejetee',
    'reversed': 'annulee',
    'settled': 'reglee',
    'withdraw': 'retrait',
    'new': 'nouvelle',
    'ride': 'course',
    'trip': 'trajet',
    'message': 'message',
    'review': 'avis',
    'driver': 'chauffeur',
    'customer': 'client',
    'vehicle': 'vehicule',
    'legal': 'legales',
    'updated': 'mises a jour',
    'privacy': 'confidentialite',
    'policy': 'politique',
    'terms': 'conditions',
    'conditions': 'generales',
    'safety': 'securite',
    'problem': 'probleme',
    'tips': 'pourboire',
    'cash': 'espece',
    'money': 'argent',
    'orange': 'orange',
    'wave': 'wave',
    'online': 'en ligne',
    'offline': 'hors ligne',
    'hand': 'main',
    'limit': 'limite',
    'exceeds': 'depassee',
    'otp': 'OTP',
    'started': 'demarre',
    'returned': 'retourne',
    'canceled': 'annule',
    'cancelled': 'annule',
    'another': 'un autre',
    'assigned': 'assigne',
    'accepted': 'acceptee',
    'received': 'recue',
    'bid': 'offre',
    'coupon': 'coupon',
    'removed': 'retire',
    'applied': 'applique',
    'level': 'niveau',
    'up': 'superieur',
    'registration': 'inscription',
    'identity': 'identite',
    'national': 'nationale',
    'passport': 'passeport',
    'driving': 'conduire',
    'license': 'permis',
    'trade': 'patente',
    'bike': 'moto',
    'motor': 'moto',
    'car': 'voiture',
    'sedan': 'berline',
    'suv': 'SUV',
    'pickup': 'pickup',
    'share': 'course',
    'delivery': 'livraison',
    'sent': 'envoyee',
    'image': 'image',
    'face': 'visage',
    'verification': 'verification',
    'completed': 'terminee',
    'resolved': 'resolue',
    'undone': 'annulee',
    'commission': 'commission',
    'forfait': 'forfait',
    'pending': 'en attente',
    'denied': 'refuse',
    'ongoing': 'en cours',
  };

  static String translate(String? raw, {String fallback = ''}) {
    if (raw == null) return fallback;
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) return fallback;

    final String lower = trimmed.toLowerCase();
    final String snake = _toSnakeCase(trimmed);

    if (frenchTranslations.containsKey(trimmed)) {
      return frenchTranslations[trimmed]!;
    }
    if (frenchTranslations.containsKey(lower)) {
      return frenchTranslations[lower]!;
    }
    if (frenchTranslations.containsKey(snake)) {
      return frenchTranslations[snake]!;
    }

    final String directTr = trimmed.tr;
    if (directTr != trimmed) return directTr;
    final String snakeTr = snake.tr;
    if (snakeTr != snake) return snakeTr;

    final List<String> tokens =
        snake.split('_').where((e) => e.isNotEmpty).toList();
    if (tokens.isEmpty) return trimmed;

    bool changed = false;
    final translatedTokens = tokens.map((token) {
      final translated = _tokenMap[token];
      if (translated != null) {
        changed = true;
        return translated;
      }
      return token;
    }).toList();

    if (!changed) return trimmed;
    final String sentence =
        translatedTokens.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (sentence.isEmpty) return trimmed;
    return sentence[0].toUpperCase() + sentence.substring(1);
  }

  static String _toSnakeCase(String value) {
    return value
        .trim()
        .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'),
            (match) => '${match.group(1)}_${match.group(2)}')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s_]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(' ', '_');
  }
}
