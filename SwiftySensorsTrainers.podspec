Pod::Spec.new do |spec|

    spec.name           = 'SwiftySensorsTrainers'
    spec.version        = '0.3.3'
    spec.summary        = 'Trainer Plugins for SwiftySensors'

    spec.homepage       = 'https://github.com/kinetic-fit/sensors-swift-trainers'
    spec.license        = { :type => 'MIT', :file => 'LICENSE' }
    spec.author         = { 'Kinetic' => 'admin@kinetic.fit' }

    spec.ios.deployment_target  = '8.2'
    spec.osx.deployment_target  = '10.11'

    spec.source         = { :git => 'https://github.com/kinetic-fit/sensors-swift-trainers.git',
                            :tag => spec.version.to_s }
    spec.source_files   = 'Source/**/*.swift', 'Headers/*.h'

    spec.ios.vendored_library   = 'Libraries/libKineticSDK.a'
    spec.osx.vendored_library   = 'Libraries/libKineticSDKCocoa.a'

    spec.dependency     'SwiftySensors', '~>0.3'
    spec.dependency     'Signals', '~> 4.0'

end
