enum UserRole { resident, staff, guest, admin }

enum StaffRole { tanod, kagawad, healthWorker, secretary, captain }

class User {
  final String id;
  final String name;
  final UserRole role;
  final StaffRole? staffRole;
  final String purok;
  final String phoneNumber;
  bool isVerified;
  String? idImagePath;
  String? faceData;
  bool isArchived;
  final String? password;
  final String? username;
  final String? idPhotoUrl;
  final String verificationStatus;

  User({
    required this.id,
    required this.name,
    required this.role,
    this.staffRole,
    required this.purok,
    required this.phoneNumber,
    this.isVerified = false,
    this.idImagePath,
    this.faceData,
    this.isArchived = false,
    this.password,
    this.username,
    this.idPhotoUrl,
    this.verificationStatus = 'Verified',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role.name,
      'staffRole': staffRole?.name,
      'purok': purok,
      'phoneNumber': phoneNumber,
      'isVerified': isVerified,
      'idImagePath': idImagePath,
      'faceData': faceData,
      'isArchived': isArchived,
      'password': password,
      'username': username,
      'idPhotoUrl': idPhotoUrl,
      'verificationStatus': verificationStatus,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      role: UserRole.values.firstWhere((e) => e.name == map['role'], orElse: () => UserRole.resident),
      staffRole: map['staffRole'] != null ? StaffRole.values.firstWhere((e) => e.name == map['staffRole']) : null,
      purok: map['purok'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      isVerified: map['isVerified'] ?? false,
      idImagePath: map['idImagePath'],
      faceData: map['faceData'],
      isArchived: map['isArchived'] ?? false,
      password: map['password'],
      username: map['username'],
      idPhotoUrl: map['idPhotoUrl'] ?? map['idImagePath'],
      verificationStatus: map['verificationStatus'] ?? (map['isVerified'] == true ? 'Verified' : 'Pending Verification'),
    );
  }
}
