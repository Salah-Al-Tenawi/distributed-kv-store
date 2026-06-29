import 'package:equatable/equatable.dart';

class TxnInfo extends Equatable {
  final String id;
  final Map<String, String> votes;
  final String result;

  const TxnInfo({
    required this.id,
    required this.votes,
    required this.result,
  });

  bool get committed => result == 'COMMITTED';

  factory TxnInfo.fromJson(Map<String, dynamic> json) {
    return TxnInfo(
      id: json['id'] as String? ?? '',
      votes: (json['votes'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ??
          const {},
      result: json['result'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, votes, result];
}
