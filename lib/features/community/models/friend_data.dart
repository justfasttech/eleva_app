class FriendData {
  final String id;
  final String name;
  final double faithLevel;

  const FriendData({
    required this.id,
    required this.name,
    required this.faithLevel,
  });

  int get treeLevel => (faithLevel / 5).floor().clamp(0, 14);
}
