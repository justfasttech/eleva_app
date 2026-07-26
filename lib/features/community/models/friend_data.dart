class FriendData {
  final String id;
  final String name;
  final int faithLevel;

  const FriendData({
    required this.id,
    required this.name,
    required this.faithLevel,
  });

  int get treeLevel => (faithLevel ~/ 5).clamp(0, 14);
}
