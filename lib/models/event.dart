import 'package:hive/hive.dart';

part 'event.g.dart';

@HiveType(typeId: 0)
class BirthdayEvent extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  DateTime birthday;

  @HiveField(2)
  List<DateTime> reminderTimes;

  @HiveField(3)
  String? profileImagePath;

  @HiveField(4)
  String? contactNumber;

  @HiveField(5)
  String? notes;

  @HiveField(6)
  bool isActive;

  // Repeat settings
  @HiveField(7)
  String repeatType; // 'none','minute','hour','day','yearly','custom'

  @HiveField(8)
  int? customInterval; // when repeatType == 'custom'

  @HiveField(9)
  String? customUnit; // 'minutes','hours','days'

  @HiveField(10)
  bool repeatEnabled;

  BirthdayEvent({
    required this.name,
    required this.birthday,
    required this.reminderTimes,
    this.profileImagePath,
    this.contactNumber,
    this.notes,
    this.isActive = true,
    this.repeatType = 'none',
    this.customInterval,
    this.customUnit,
    this.repeatEnabled = true,
  });

  int daysUntilBirthday() {
    final now = DateTime.now();
    final thisYearBirthday = DateTime(now.year, birthday.month, birthday.day);

    if (thisYearBirthday.isAfter(now)) {
      return thisYearBirthday.difference(now).inDays;
    } else {
      final nextYearBirthday = DateTime(now.year + 1, birthday.month, birthday.day);
      return nextYearBirthday.difference(now).inDays;
    }
  }

  int getAge() {
    final now = DateTime.now();
    int age = now.year - birthday.year;
    if (now.month < birthday.month ||
        (now.month == birthday.month && now.day < birthday.day)) {
      age--;
    }
    return age + 1;
  }
}