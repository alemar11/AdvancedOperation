Pod::Spec.new do |s|
  s.name    = 'AdvancedOperation'
  s.version = '2.2.2'
  s.license = 'MIT'
  s.documentation_url = 'http://www.tinrobots.org/AdvancedOperation'  
  s.summary   = 'Advanced operations.'
  s.homepage  = 'https://github.com/tinrobots/AdvancedOperation'
  s.authors   = { 'Alessandro Marzoli' => 'me@alessandromarzoli.com' }
  s.source    = { :git => 'https://github.com/tinrobots/AdvancedOperation.git', :tag => s.version }
  s.requires_arc = true
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '4.2'}
  
  s.swift_version = "4.2"
  s.ios.deployment_target     = '11.0'
  s.osx.deployment_target     = '10.13'
  s.tvos.deployment_target    = '11.0'
  s.watchos.deployment_target = '4.0'

  s.source_files =  'Sources/*.swift',
                    'Sources/*/*.swift',
                    'Support/*.{h,m}'
end
