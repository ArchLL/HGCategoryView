#
# Be sure to run `pod lib lint HGCategoryView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'HGCategoryView'
  s.version          = '1.1.5'
  s.license          = 'MIT'
  s.summary          = '一个APP分页切换滚动视图'
  s.description      = %{
    一个多样式的APP分页切换滚动视图.
  }                       
  s.homepage         = 'https://github.com/ArchLL/HGCategoryView'
  s.author           = { 'Arch' => 'mint_bin@163.com' }
  s.source           = { :git => 'https://github.com/ArchLL/HGCategoryView.git', :tag => s.version.to_s }
  s.source_files = 'HGCategoryView/*.{h,m}'
  s.ios.frameworks = 'Foundation', 'UIKit'
  s.ios.deployment_target = '9.0'
  s.dependency 'Masonry', '~> 1.1.0'
  s.requires_arc = true
end
