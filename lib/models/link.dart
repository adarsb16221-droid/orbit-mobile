class Link {
  final String id;
  final String name;
  final String url;

  Link({
    required this.id,
    required this.name,
    required this.url,
  });

  factory Link.fromJson(Map<String, dynamic> json) {
    return Link(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      url: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': id,
      'name': name,
      'url': url,
    };
  }
}
