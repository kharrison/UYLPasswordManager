Pod::Spec.new do |s|
  s.name         = "UYLPasswordManager"
  s.version      = "1.0.0-beta"
  s.summary      = "Simple iOS Keychain Access"
  s.description  = <<-DESC
    The UYLPasswordManager class provides a simple wrapper around Apple Keychain
    Services on iOS devices. The class is designed to make it quick and easy to
    create, read, update and delete keychain items. Keychain groups are also
    supported as is the ability to set the data migration and protection attributes
    of keychain items.
                   DESC
  s.homepage         = "https://github.com/kharrison/UYLPasswordManager"
  s.license          = { :type => "BSD", :file => "LICENSE" }
  s.authors          = { "Keith Harrison" => "keith@useyourloaf.com" }
  s.social_media_url = 'https://twitter.com/kharrison'
  s.platform     = :ios, "6.0"
  s.source       = { :git => "https://github.com/kharrison/UYLPasswordManager.git", :tag => "1.0.0-beta" }
  s.source_files  = "PasswordManager"
  s.requires_arc = true
end
