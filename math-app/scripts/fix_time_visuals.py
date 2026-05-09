import re

sql_path = '/home/s0lut1on/project/learning/math/math-app/backend/content/migrations/003_mass_curriculum.sql'

with open(sql_path, 'r') as f:
    content = f.read()

# Pattern matches time exercise INSERT lines with visual_asset = '🕐'
pattern = re.compile(
    r"(VALUES \('ex_m_time\d+_1', 'm_time\d+', 'Mấy giờ\? 🕐', 'What time\? 🕐', ARRAY\[([^]]+)\], (\d+), )'🕐'(.*\);)"
)

def replace_match(m):
    prefix = m.group(1)
    options_str = m.group(2)
    correct_index = int(m.group(3))
    suffix = m.group(4)
    
    # Parse options array like '9:30','10:45','12:15'
    options = [opt.strip().strip("'") for opt in options_str.split(',')]
    correct_time = options[correct_index]
    
    # Parse time like '10:45' -> hour=10, minute=45
    hour, minute = correct_time.split(':')
    
    return f"{prefix}'clock|{hour}|{minute}'{suffix}"

new_content = pattern.sub(replace_match, content)

# Count replacements
old_count = content.count("ex_m_time")
new_count = new_content.count("clock|")

print(f"Replaced {new_count} time exercise visual assets")

with open(sql_path, 'w') as f:
    f.write(new_content)
