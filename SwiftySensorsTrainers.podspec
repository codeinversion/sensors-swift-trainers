Pod::Spec.new do |spec|

    spec.name           = 'SwiftySensorsTrainers'
    spec.version        = '1.0.0'
    spec.summary        = 'Trainer Plugins for SwiftySensors'

    spec.homepage       = 'https://github.com/kinetic-fit/sensors-swift-trainers'
    spec.license        = { :type => 'MIT', :file => 'LICENSE' }
    spec.author         = { 'Kinetic' => 'admin@kinetic.fit' }

    spec.ios.deployment_target  = '8.4'
    spec.osx.deployment_target  = '10.13'
    spec.tvos.deployment_target = '11.2'

    spec.source         = { :git => 'https://github.com/kinetic-fit/sensors-swift-trainers.git',
                            :tag => spec.version.to_s }
    spec.source_files   = 'Source/**/*.swift', 'Headers/*.h'
    spec.swift_version  = '4.2'

    spec.ios.vendored_library   = 'Libraries/libKineticSDKiOS.a'
    spec.osx.vendored_library   = 'Libraries/libKineticSDKmacOS.a'
    spec.tvos.vendored_library  = 'Libraries/libKineticSDKtvOS.a'

    spec.dependency     'SwiftySensors'
    spec.dependency     'Signals'

end
