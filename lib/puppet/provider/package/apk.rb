require 'puppet/provider/package'

Puppet::Type.type(:package).provide :apk, :parent => ::Puppet::Provider::Package do
  desc "System packages on Alpine linux via `apk`.

  This provider supports the `install_options` attribute, which allows command-line flags to be passed to apk.
  These options should be specified as a string (e.g. '--flag'), a hash (e.g. {'--flag' => 'value'}),
  or an array where each element is either a string or a hash."

  has_feature :installable, :uninstallable, :upgradeable, :versionable, :install_options

  commands :apk => 'apk'

  confine :operatingsystem => [:alpine]
  defaultfor :operatingsystem => :alpine

  def self.instances
    # apk info doesn't have output that makes parsing for the version easy
    # because it's split on - which could also be in the package name.
    # To work around that we run apk info twice, the first time to just get
    # the package name and the second time to get the package and version.
    # We then use the name to determine the version. This has a very small chance
    # of a race condition, if the package database changes between the two
    # runs, but the runtime for apk info is typically miliseconds.
    packages = remove_warnings(apk('info').split("\n"))
    packages_with_versions = remove_warnings(apk('info', '-v').split("\n"))
    packages.collect.with_index do |package, index|
      version = packages_with_versions[index].gsub("#{package}-", '')
      new({
        name: package,
        ensure: version,
        provider: name,
      })
    end
  end

  def self.remove_warnings(packages)
    packages.reject { |name| name.to_s.start_with? 'WARNING' }
  end

  def query
    self.class.instances.each do |provider|
      return provider.properties if name.downcase == provider.name.downcase
    end
    return
  end

  def latest
    details = apk('info', name, '--no-cache').split("\n")
    details.each do |line|
      unless line.match(/^fetch/)
        parts = line.split(' ')
        return parts.first.gsub("#{name}-", '')
      end
    end
  end

  def install(options=[])
    args = ['add']
    args += install_options if @resource[:install_options]
    args += options
    args << name
    apk(*args)
  end

  def uninstall
    apk('del', name)
  end

  def update
    install(['--update'])
  end

  private
  def install_options
    join_options(@resource[:install_options])
  end
end
