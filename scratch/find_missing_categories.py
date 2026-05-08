import json
with open('/Users/yousefalenzi/Downloads/reagent_colors_test/assets/data/reagents.json', 'r') as f:
    data = json.load(f)
missing = [key for key, val in data.items() if 'category' not in val]
print(missing)
