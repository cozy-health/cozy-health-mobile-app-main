<?php
$models_dir = 'c:\projects\cozyhealth\cozy-health-mobile-app-main-main\lib\core\models';

$files = glob($models_dir . '\*.dart');
foreach ($files as $file) {
    $content = file_get_contents($file);
    
    // Find the adapter class definition
    preg_match('/class (\w+)Adapter extends TypeAdapter<\w+> {/', $content, $matches);
    if (empty($matches)) continue;
    
    $model_name = $matches[1];
    
    // Extract toJson and fromJson
    preg_match('/(  Map<String, dynamic> toJson\(\) {.*?^  })/ms', $content, $json_match);
    preg_match('/(  factory ' . $model_name . '\.fromJson\(Map<String, dynamic> json\) {.*?^  })/ms', $content, $from_json_match);
    
    if (!empty($json_match) && !empty($from_json_match)) {
        $to_json = $json_match[1];
        $from_json = $from_json_match[1];
        
        // Remove from the adapter class
        $content = str_replace($to_json, '', $content);
        $content = str_replace($from_json, '', $content);
        
        // Insert before the adapter class
        $adapter_pos = strpos($content, 'class ' . $model_name . 'Adapter');
        $before_adapter = substr($content, 0, $adapter_pos);
        $after_adapter = substr($content, $adapter_pos);
        
        $last_brace_pos = strrpos($before_adapter, '}');
        
        $new_before = substr($before_adapter, 0, $last_brace_pos) . "\n" . $to_json . "\n\n" . $from_json . "\n" . substr($before_adapter, $last_brace_pos);
        
        file_put_contents($file, $new_before . $after_adapter);
        echo "Fixed $model_name\n";
    }
}
?>
