module YXConfig
  def self.commonuikit_version
    "9.8.4"
  end

  def self.imuikit_version
    "10.9.60"
  end

  def self.qchatuikit_version
    "10.0.1"
  end

  def self.nimsdk_version
    "10.11.0"
  end

  def self.calluikit_version
    ENV.fetch("CALLUIKIT_VERSION", "4.3.0")
  end

  def self.use_source_files?
    ENV["USE_SOURCE_FILES"] == "true"
  end

  def self.build_component_package?
    ENV["BUILD_COMPONENT_PACKAGE"] == "true"
  end

  def self.use_local_nimlib?
    ENV["USE_LOCAL_NIMLIB"] == "true"
  end

  def self.deployment_target
    "15.0"
  end

  def self.swift_version
    "5.0"
  end

  def self.homepage
    "http://netease.im"
  end

  def self.author
    "yunxin engineering department"
  end

  def self.pod_target_xcconfig(s)
    s.pod_target_xcconfig = {
      "BUILD_LIBRARY_FOR_DISTRIBUTION" => "YES",
      "APPLICATION_EXTENSION_API_ONLY" => "NO",
      "DEBUG_INFORMATION_FORMAT" => "dwarf-with-dsym",
      "CLANG_ENABLE_EXPLICIT_MODULES" => "NO",
      "DEFINES_MODULE" => "YES",
      "SWIFT_INSTALL_OBJC_HEADER" => "YES",
      "SWIFT_OBJC_INTERFACE_HEADER_NAME" => "$(PRODUCT_MODULE_NAME)-Swift.h"
    }
  end

  def self.license
    { :'type' => "Copyright", :'text' => " Copyright 2022 Netease " }
  end
end
