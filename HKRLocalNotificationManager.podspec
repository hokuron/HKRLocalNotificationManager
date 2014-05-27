Pod::Spec.new do |s|
  s.name         = "HKRLocalNotificationManager"
  s.version      = "0.6"
  s.summary      = "Safe schedule manager of local notification."
  s.homepage     = "https://github.com/hokuron/HKRLocalNotificationManager"
  s.license      = "MIT"
  s.author       = "Takuma Shimizu"
  s.platform     = :ios
  s.source       = { :git => "https://github.com/hokuron/HKRLocalNotificationManager.git", :tag => "v0.6" }
  s.source_files = "HRKLocalNotificationManager/**/*.{h,m}"
  s.requires_arc = true
end
