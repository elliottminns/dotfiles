#!/usr/bin/osascript

function incrementString(string) {
  // Extract string's number
  var number = string.match(/\d+/) === null ? 0 : string.match(/\d+/)[0];

  // Store number's length
  var numberLength = number.length;

  // Increment number by 1
  number = (parseInt(number) + 1).toString();

  // If there were leading 0s, add them again
  while (number.length < numberLength) {
    number = "0" + number;
  }

  return number.concat(string.replace(/[0-9]/g, ""));
}

function run(args) {
  var app = Application.currentApplication();
  app.includeStandardAdditions = true;

  const filepath = args[0];
  const filename = filepath.split("/").slice(-1)[0];
  const filePaths = args[0].split("/");
  const dir = filePaths.slice(0, filePaths.length - 1).join("/");

  const items = Application("System Events")
    .folders.byName(dir)
    .diskItems.name()
    .filter((item) => item.includes(".mkv"))
    .filter((item) => item !== filename);

  const nums = items
    .map((item) => parseInt(item.split(".")[0].split("-")[0]))
    .filter((item) => !isNaN(item));

  const keys = items.reduce((x, item) => {
    x[parseInt(item.split(".")[0].split("-")[0])] = item.split("-")[0];
    return x;
  }, {});

  const max = Math.max(...nums);

  let next = "000";
  if (max !== -Infinity) {
    next = incrementString(keys[max]);
  }

  var response = app.displayDialog("Name your recording", {
    defaultAnswer: `${next}-`,
    withIcon: "note",
    buttons: ["Delete", "Continue"],
    defaultButton: "Continue",
  });

  if (response.buttonReturned === "Delete") {
    app.doShellScript(`rm ${filepath}`);
    return;
  }

  const parts = filename.split(".");
  var file = Application("System Events").aliases.byName(filepath);
  file.name = response.textReturned + "." + parts[1];
}
