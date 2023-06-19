require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "react-native-kyc-pl"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => "12.0" }
  s.ios.deployment_target = '12.0'
  s.source       = { :git => "https://github.com/anil1997/react-native-kyc-pl.git", :tag => "#{s.version}" }

  s.source_files = "ios/**/*.{h,m,mm,swift}"
  s.resources = "ios/**/*.{png,jpeg,jpg,xib,xcassets,imageset,gif,mp3,storyboard}"

  s.dependency "React-Core"
  s.static_framework = true
  s.dependency "AccuraOCR","3.2.2"
  s.dependency "AccuraLiveness_FM","4.2.2"
  s.dependency "JGProgressHUD","2.2"
  s.swift_version = '5.0'
  s.platform = :ios, '12.0'
end
