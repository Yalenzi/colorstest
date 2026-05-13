import re

with open('/Users/yousefalenzi/Downloads/reagent_colors_test/lib/features/auth/presentation/views/auth_page.dart', 'r') as f:
    content = f.read()

# Find all variable declarations like 'final varName ='
declarations = re.findall(r'final\s+(\w+)\s*=', content)

# Check each declaration
for d in declarations:
    # Count occurrences of the variable name as a whole word
    count = len(re.findall(r'\b' + d + r'\b', content))
    if count == 1:
        print(f"Variable '{d}' might be unused (count is 1)")
