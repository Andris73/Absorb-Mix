require 'xcodeproj'
require 'fileutils'
root = ENV.fetch('QA_DIR')
FileUtils.mkdir_p(root)
project = Xcodeproj::Project.new(File.join(root, 'AbsorbMixQA.xcodeproj'))
target = project.new_target(:ui_test_bundle, 'AbsorbMixUITests', :ios, '17.0')
source = project.main_group.new_file(File.join(root, 'AbsorbMixUITests.swift'))
target.add_file_references([source])
target.build_configurations.each do |configuration|
  configuration.build_settings['SWIFT_VERSION'] = '5.0'
  configuration.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.andris73.absorbmix.uitests'
  configuration.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  configuration.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
  configuration.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
end
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(target)
scheme.add_test_target(target)
scheme.test_action.build_configuration = 'Debug'
project.save
scheme.save_as(project.path, 'AbsorbMixUITests', true)
