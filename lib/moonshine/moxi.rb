module Moonshine
  module Moxi
    
    def moxi_template_dir
      @moxi_template_dir ||= Pathname.new(__FILE__).dirname.dirname.dirname.join('templates')
    end
    # Define options for this plugin via the <tt>configure</tt> method
    # in your application manifest:
    #
    #    configure(:moxi => {:foo => true})
    #
    # Moonshine will autoload plugins, just call the recipe(s) you need in your
    # manifests:
    #
    #    recipe :moxi
    def moxi(options = {})
      %w(build-essential automake libtool pkg-config check libssl-dev sqlite3 libsqlite3-dev libevent-dev libglib2.0-dev libglib2.0-0-dbg).each do |p|
        package p, :ensure => :installed, :before => package('moxi-server')
      end
      
      package 'wget', :ensure => :installed

      file '/usr/local/src', :ensure => :directory

      exec 'download moxi',
        :command => "wget http://c2493362.cdn.cloudfiles.rackspacecloud.com/moxi-server_x86_64_1.6.0.deb",
        :cwd => '/usr/local/src',
        :require => package('wget'),
        :unless => "test -f /opt/moxi/bin/moxi"
      package 'moxi-server',
        :ensure   => :installed,
        :provider => :dpkg,
        :source   => '/usr/local/src/moxi-server_x86_64_1.6.0.deb',
        :require  => exec('download moxi')

      file '/usr/local/bin/moxi', :ensure => '/opt/moxi/bin/moxi', :require => package('moxi-server'), :notify => service('moxi')

      file '/etc/default/moxi', 
        :content => template(moxi_template_dir.join('moxi.default'), binding),
        :mode => '755',
        :before => file('/etc/init.d/moxi')

      file '/etc/init.d/moxi', 
        :content => template(moxi_template_dir.join('moxi.init'), binding),
        :mode => '755',
        :before => file('/etc/moxi.conf')
        
      file '/etc/moxi.conf', 
        :content => template(moxi_template_dir.join('moxi.conf.erb'), binding),
        :mode => '644',
        :require => package('moxi-server'),
        :notify => service('moxi')

      service 'moxi', :ensure => :running, :enable => true, :require => file('/etc/moxi.conf')
      
    end
  
  end
end