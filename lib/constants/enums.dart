enum WhereBuy {
  none("선택"),
  masterOfMalt("master of malt"),
  whiskybase("whiskybase"),
  smws("SMWS"),
  theWhiskyBarrel("the whisky barrel"),
  theWhiskyExchange("the whisky exchange");

  final String title;

  const WhereBuy(this.title);
}

enum PriceCategory {
  zeroToTen("0~10만원"),
  tenToTwenty("10~20만원"),
  twentyToThirty("20~30만원"),
  moreThirty("30만원 이상");

  const PriceCategory(this.title);

  final String title;
}
