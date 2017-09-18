Pod::Spec.new do |s|
  s.name         = "Blues"
  s.version      = "1.0"
  s.summary      = "Type safe wrapper on CoreBluetooth"
  s.homepage     = "https://github.com/nwtnberlin/Blues"
  s.license      = "MIT"
  s.authors      = { "Michał Kałużny" => "maku@justmaku.org", "Vincent Esche" => "regexident@gmail.com" }
 
  s.ios.deployment_target = "10.0"
  s.watchos.deployment_target = "3.0"
  s.tvos.deployment_target = "10.0"

  s.source       = { :git => "https://github.com/nwtnberlin/Blues.git", :tag => "#{s.version}" }

  s.source_files  = "Blues/**/*.swift"
  s.framework  = "CoreBluetooth"
end
