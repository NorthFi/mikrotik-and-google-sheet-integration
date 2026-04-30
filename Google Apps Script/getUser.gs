// Google Apps Script

function getUser() {
  const ss = SpreadsheetApp.openById("xxx");
  const sheet = ss.getSheetByName("user");
  const rows = sheet.getDataRange().getValues();

  let output = "";

  for (let i = 1; i < rows.length; i++) {
    const username = rows[i][0];
    const password = rows[i][1];
    const status   = rows[i][2];

    if (username) {
      output += `${username}|${password}|${status}\n`;
    }
    
    
  }
  console.log(output);
  return ContentService.createTextOutput(output);
}
