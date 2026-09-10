import re

filepath = r"d:\New folder (11)\adhkar\lib\data\companions_stories_data.dart"
with open(filepath, "r", encoding="utf-8") as f:
    content = f.read()

ids = re.findall(r"id:\s*'([^']+)'", content)
print("Found IDs:", ids)
print("Total count:", len(ids))
