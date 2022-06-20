enum WhereBuy {
  none,
  masterOfMalt,
  whiskybase,
  smws,
  theWhiskyBarrel,
  theWhiskyExchange
}

extension WhereBuyExtension on WhereBuy {
  String title() {
    switch (this) {
      case WhereBuy.none:
        return "선택";
      case WhereBuy.masterOfMalt:
        return "master of malt";
      case WhereBuy.whiskybase:
        return "whiskybase";
      case WhereBuy.smws:
        return "SMWS";
      case WhereBuy.theWhiskyBarrel:
        return "the whisky barrel";
      case WhereBuy.theWhiskyExchange:
        return "the whisky exchange";
    }
  }
}
