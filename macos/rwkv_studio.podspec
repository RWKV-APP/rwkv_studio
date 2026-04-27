Pod::Spec.new do |s|
    s.name             = 'rwkv_studio'
    s.version          = '0.0.1'
    s.summary          = '.'
    s.description      = <<-DESC
                         DESC
    s.homepage         = ''
    s.license          = { :file => '../LICENSE' }
    s.author           = { 'Your Company' => 'email@example.com' }

    s.source           = { :path => '.' }
    # s.source_files = 'Classes/**/*'
    s.dependency 'FlutterMacOS'
    s.vendored_libraries = '*.dylib'
    s.platform = :osx, '10.14'
    s.static_framework = true
    s.resources =['mlx-swift_Cmlx.bundle']
    s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
    s.swift_version = '5.0'
  end
