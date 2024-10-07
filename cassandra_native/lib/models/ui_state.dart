class UiState {
  UiState({required this.serversListViewOrientation, required this.theme});

  String serversListViewOrientation = 'vertical';
  String theme = 'light';

  Map<String, dynamic> toJson() => {
        'serversListViewOrientation': serversListViewOrientation,
        'theme': theme,
      };

  factory UiState.fromJson(Map<String, dynamic> json) {
    try {
      return UiState(
        serversListViewOrientation: json['serversListViewOrientation'],
        theme: json['theme'],
      );
    } catch (e) {
      return UiState(
        serversListViewOrientation: 'vertical', 
        theme: 'light'
      );
    }
  }
}
