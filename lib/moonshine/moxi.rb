module Moonshine
  module Moxi
    
    def moxi_template_dir
      @moxi_template_dir ||= Pathname.new(__FILE__).dirname.dirname.join('templates')
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
        package p, :ensure => :installed, :before => exec('install moxi')
      end
      
      package 'wget', :ensure => :installed
              
      exec 'install moxi',
        :command => [
          "wget http://labs.northscale.com/moxi/moxi-0.10.0.tar.gz",
          "tar xzf http://labs.northscale.com/moxi/moxi-0.10.0.tar.gz",
          "cd moxi-0.10.0",
          './configure',
          'make',
          'make install'
        ].join(' && '),
        :cwd => '/tmp',
        :require => package('wget'),
        :unless => "test -f /usr/local/bin/moxi"
        
      file '/etc/moxi.conf', 
        :content => template(moxi_template_dir.join('moxi.conf.erb')), binding),
        :mode => '644',
        :require => exec('install moxi'),
        :notify => service('moxi')
          
      file '/etc/init.d/moxi', 
        :content => template(moxi_template_dir.join('moxi.init')), binding),
        :mode => '755',
        :require => exec('install moxi'),
        :before => file('/etc/moxi.conf')

      service 'moxi', :ensure => :running, :require => file('/etc/init.d/moxi')
      
    end
  
  end
end