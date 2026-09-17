enum UserRole { resident, staff, guest }

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
  });
}
