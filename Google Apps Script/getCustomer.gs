// random test 

// customers.gs
function getCustomer() {
  // const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName("Customers");
  // const rows = sheet.getDataRange().getValues();
  const ss = SpreadsheetApp.openById("xxx");
  const sheet = ss.getSheetByName("Customers");
  const rows = sheet.getDataRange().getValues();


  let output = "";

  for (let i = 1; i < rows.length; i++) {
    const account = rows[i][0];
    const name = rows[i][1];
    const surname = rows[i][2];
    const contact1 = rows[i][3];
    const contact2 = rows[i][4];  
    const address = rows[i][8];  
    const package = rows[i][9]; 
  
    let status = "";
    if (package === "A0") {
      status = "suspended";
    } else {
      status = "active";
    }

    if (account) {
      output += `${account}|${name}|${surname}|${contact1}|${contact2}|${address}|${package}|${status}\n`;
    }
  }

  console.log(output); // use console.log instead of console.error
  return ContentService.createTextOutput(output);
}
