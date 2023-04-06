#
#  Be sure to run `pod spec lint ImageProc.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  spec.name         = "ImageProc"
  spec.version      = "1.2.0"
  spec.summary      = "A collection of Image Processing Swift UIKit methods."
  spec.homepage     = "https://gitlab.com/herme5/ImageProc"
  spec.description  = <<-DESC
                      ImageProc implements basic image processing methods that are exposed as UIImage and UIColor extension.
                      DESC
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "Andrea Ruffino" => "andrea.ruffino@hotmail.fr" }

  spec.platform               = :ios, "13.0"
  spec.ios.deployment_target  = "13.0"
  spec.swift_version          = "5.0"
  
  spec.source               = { :git => "https://gitlab.com/herme5/ImageProc.git", :tag => "#{spec.version}" }
  spec.source_files         = "ImageProc/**/*.{h,m,mm,swift}"
  spec.public_header_files  = "ImageProc/ImageProc.h"
  spec.xcconfig             = { "GCC_PREPROCESSOR_DEFINITIONS" => "CI_SILENCE_GL_DEPRECATION" }

end
