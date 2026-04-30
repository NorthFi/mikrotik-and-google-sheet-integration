function getPPPoE() {
  const ss = SpreadsheetApp.openById("xxx");
  const sheet = ss.getSheetByName("pppoe");
  const rows = sheet.getDataRange().getValues();

  let output = "";

  for (let i = 1; i < rows.length; i++) {
    const username = rows[i][0];
    const password = rows[i][1];
    const profile  = rows[i][2];
    const status   = rows[i][3];

    if (username) {
      output += `${username}|${password}|${profile}|${status}\n`;
    }
    
  }

  return ContentService.createTextOutput(output);
}
