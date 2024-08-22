class UiState {
  UiState({required this.serversListViewOrientation});

  String serversListViewOrientation = 'vertical';

  Map<String, dynamic> toJson() => {
    'serversListViewOrientation': serversListViewOrientation,
  };

  factory UiState.fromJson(Map<String, dynamic> json) {
    return UiState(
      serversListViewOrientation: json['serversListViewOrientation'],
    );
  }
}
