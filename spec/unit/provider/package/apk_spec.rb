#! /usr/bin/env ruby
require 'spec_helper'

describe Puppet::Type.type(:package).provider(:apk) do
  let (:resource) { Puppet::Type.type(:package).new(:name => 'mypackage', :ensure => :installed, :provider => :apk) }
  let (:provider) { resource.provider }

  [:install, :uninstall, :latest, :query, :update].each do |method|
    it "should have a method called #{method}" do
      expect(provider).to respond_to(method)
    end
  end

  it 'should be versionable' do
    expect(described_class).to be_versionable
  end

  it 'should be instalable' do
    expect(described_class).to be_installable
  end

  it 'should be uninstalable' do
    expect(described_class).to be_uninstallable
  end

  it 'should be upgradeable' do
    expect(described_class).to be_upgradeable
  end

  it 'should call apk info twice with different arguments when listing packages' do
    described_class.expects(:apk).with('info', '-v').returns('')
    described_class.expects(:apk).with('info',).returns('')
    described_class.expects(:warning).never
    described_class.instances
  end

  it 'should call apk info twice with different arguments when listing packages' do
    described_class.expects(:apk).with('info', '-v').returns <<-OUTPUT
ncurses-terminfo-6.0-r6
ncurses-libs-6.0-r6
readline-6.3.008-r4
bash-4.3.42-r3
openssl-1.0.2f-r0
ca-certificates-20160104-r2
libssh2-1.6.0-r0
    OUTPUT
    described_class.expects(:apk).with('info',).returns <<-OUTPUT
ncurses-terminfo
ncurses-libs
readline
bash
openssl
ca-certificates
libssh2
    OUTPUT
    described_class.expects(:warning).never
    instances = described_class.instances.map { |p| {:name => p.get(:name), :ensure => p.get(:ensure) }}
    expect(instances.size).to eq(7)
    expect(instances[0]).to eq({:name => 'ncurses-terminfo', :ensure => '6.0-r6'})
  end

  it 'should not output false package resources for WARNINGS' do
    described_class.expects(:apk).with('info', '-v').returns <<-OUTPUT
WARNING: Ignoring APKINDEX.167438ca.tar.gz: No such file or directory
ncurses-terminfo-6.0-r6
ncurses-libs-6.0-r6
    OUTPUT
    described_class.expects(:apk).with('info',).returns <<-OUTPUT
WARNING: Ignoring APKINDEX.167438ca.tar.gz: No such file or directory
ncurses-terminfo
ncurses-libs
    OUTPUT
    described_class.expects(:warning).never
    instances = described_class.instances.map { |p| {:name => p.get(:name), :ensure => p.get(:ensure) }}
    expect(instances.size).to eq(2)
    expect(instances[0]).to eq({:name => 'ncurses-terminfo', :ensure => '6.0-r6'})
  end


  it 'should uninstall a package' do
    provider.expects(:apk).with('del', 'mypackage')
    provider.uninstall
  end

  it 'should install a package' do
    provider.expects(:apk).with('add', 'mypackage')
    provider.install
  end

  it 'should query for packages based on self.instances' do
    described_class.expects(:instances).returns([resource])
    expect(provider.query).to eq(resource.properties)
  end

  it 'should update a package' do
    provider.expects(:apk).with('add', '--update', 'mypackage')
    provider.update
  end

  it 'update should install a package' do
    provider.expects(:install)
    provider.update
  end

  it 'should check for the latest version of a package' do
    provider.expects(:apk).with('info', 'mypackage', '--no-cache').returns <<-OUTPUT
fetch http://repos.dfw.lax-noc.com/alpine/v3.3/main/x86_64/APKINDEX.tar.gz
fetch http://dl-4.alpinelinux.org/alpine/edge/testing/x86_64/APKINDEX.tar.gz
mypackage-7.4.943-r2 description:
    OUTPUT
    expect(provider.latest).to eq('7.4.943-r2')
  end

  it 'should allow passing options to install' do
    resource[:install_options] = ['--allow-untrusted']
    provider.expects(:apk).with('add', '--allow-untrusted', 'mypackage')
    provider.install
  end
end
