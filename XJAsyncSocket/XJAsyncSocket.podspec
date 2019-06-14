#
#  Be sure to run `pod spec lint XJAsyncSocket.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  spec.name         = "XJAsyncSocket"
  spec.version      = "0.0.1"
  spec.summary      = "A short description of XJAsyncSocket."

    spec.description  = <<-DESC
      CocoaAsyncSocket，建立IM长连接封装
                     DESC
  
    spec.homepage     = "https://github.com/alienJion/XJAsyncSocket"#项目主页，不是git地址
    
    spec.license      = { :type => "MIT", :file => "FILE_LICENSE" }#开源协议
  
    spec.author             = { "alienJion" => "alienvvip@126.com" }#作者
  
    spec.platform     = :ios, "9.0"#支持的平台和版本号
  
    spec.source       = { :git => "https://github.com/alienJion/XJAsyncSocket.git", :tag => "0.0.1" }
  

    spec.dependency "CocoaAsyncSocket"      #依赖的第三方库
  
    # spec.source_files  = "**/*/*.{h,m}"
    # spec.frameworks = "UIKit", "Foundation"  #需要导入的frameworks名称，注意不要带上frameworks
    spec.subspec 'XJAsyncSocket' do |ss|
      ss.source_files = "XJAsyncSocket/XJAsyncSocket/SocketManager/*"
      ss.framework    = "UIKit"
  end
  
  end
  