import os
import re

models_dir = r"c:\projects\cozyhealth\cozy-health-mobile-app-main-main\lib\core\models"

for filename in os.listdir(models_dir):
    if not filename.endswith('.dart'):
        continue
    
    filepath = os.path.join(models_dir, filename)
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find the class name (e.g. class UserProfile extends HiveObject)
    class_match = re.search(r'class (\w+) extends HiveObject', content)
    if not class_match:
        continue
        
    class_name = class_match.group(1)
    
    # Extract the toJson method from inside the adapter
    to_json_match = re.search(r'(  Map<String, dynamic> toJson\(\).*?  })', content, re.DOTALL)
    from_json_match = re.search(r'(  factory ' + class_name + r'\.fromJson\(Map<String, dynamic> json\) {.*?  })', content, re.DOTALL)
    
    if to_json_match and from_json_match:
        to_json = to_json_match.group(1)
        from_json = from_json_match.group(1)
        
        # Remove them from their current location
        content = content.replace(to_json, '')
        content = content.replace(from_json, '')
        
        # We need to insert them before the end of the class.
        # Find where the class ends. Usually before the adapter class.
        adapter_idx = content.find(f'class {class_name}Adapter extends TypeAdapter<{class_name}>')
        if adapter_idx != -1:
            # Find the closing brace just before the adapter
            before_adapter = content[:adapter_idx]
            last_brace_idx = before_adapter.rfind('}')
            
            if last_brace_idx != -1:
                new_before_adapter = before_adapter[:last_brace_idx] + f'\n{to_json}\n\n{from_json}\n' + before_adapter[last_brace_idx:]
                content = new_before_adapter + content[adapter_idx:]
                
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"Fixed {filename}")
