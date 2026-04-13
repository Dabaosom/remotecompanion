import re

content = open("RemoteCompanion/RCActionPickerViewController.m").read()
start = content.find("_sections = @[")
end = content.find("];", start)

sections_raw = content[start:end+1]

# This is just a quick and dirty way to convert Obj-C dicts to JS objects
sections_raw = re.sub(r'@\{\s*@"name":\s*@"([^"]*)",\s*@"command":\s*@"([^"]*)",\s*@"icon":\s*@"([^"]*)"\s*\}', r'{"name": "\1", "command": "\2", "icon": "\3"}', sections_raw)
sections_raw = sections_raw.replace('@[', '[')
sections_raw = sections_raw.replace(']', ']')
sections_raw = sections_raw.replace('_sections = ', '')
sections_raw = sections_raw.replace(';', '')
# Remove comments
sections_raw = re.sub(r'//.*', '', sections_raw)
print(sections_raw)
