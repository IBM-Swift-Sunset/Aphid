Pod::Spec.new do |s|
  s.name             = "Aphid"
  s.version          = "0.5.1"
  s.summary          = "Lightweight MQTT client in Swift 3"
  s.homepage         = "https://github.com/IBM-Swift/Aphid"
  s.license          = { :type => "Apache License, Version 2.0" }
  s.author           = "IBM"

  s.osx.deployment_target = "10.11"
  s.ios.deployment_target = "10.0"

  s.source = { :git => "https://github.com/IBM-Swift/Aphid.git", :tag => s.version.to_s }
  s.source_files = "Sources/*.swift"

  s.dependency "BlueSocket", "~> 0.12"
  s.dependency "BlueSSLService", "~> 0.12"
  
  s.pod_target_xcconfig = { "SWIFT_VERSION" => "3.1.1" }
end
