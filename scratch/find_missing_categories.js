const fs = require('fs');
const data = JSON.parse(fs.readFileSync('/Users/yousefalenzi/Downloads/reagent_colors_test/assets/data/reagents.json', 'utf8'));
const missing = [];
for (const key in data) {
  if (!data[key].category) {
    missing.push(key);
  }
}
console.log(missing);
