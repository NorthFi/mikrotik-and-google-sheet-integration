function doGet(e) {
  const action = e.parameter.action;
  switch (action) {
    case "user":      return getUser();
    case "pppoe":     return getPPPoE();
    case "customer":  return getCustomer();
    case "stats":     return getStats();
    default:          return ContentService.createTextOutput("Unknown action");
  }
}
