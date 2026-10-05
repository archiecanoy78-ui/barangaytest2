class CameraConsent {
  final String id;
  final String userId;
  final String agreementVersion;
  final DateTime timestamp;
  final String appVersion;
  final String consentTextHash;
  final bool agreed;

  CameraConsent({
    required this.id,
    required this.userId,
    required this.agreementVersion,
    DateTime? timestamp,
    this.appVersion = '1.0.0',
    this.consentTextHash = 'v1.0-data-privacy-act-2012',
    this.agreed = true,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'agreementVersion': agreementVersion,
      'timestamp': timestamp.toIso8601String(),
      'appVersion': appVersion,
      'consentTextHash': consentTextHash,
      'agreed': agreed,
    };
  }

  factory CameraConsent.fromMap(Map<String, dynamic> map) {
    return CameraConsent(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      agreementVersion: map['agreementVersion'] ?? 'v1.0',
      timestamp: map['timestamp'] != null ? DateTime.parse(map['timestamp']) : DateTime.now(),
      appVersion: map['appVersion'] ?? '1.0.0',
      consentTextHash: map['consentTextHash'] ?? 'v1.0-data-privacy-act-2012',
      agreed: map['agreed'] ?? true,
    );
  }
}
