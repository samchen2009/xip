require 'open-uri'

class WebPage
    attr_accessor :router, :count, :uri
    def initialize(uri, cookie=nil)
        @uri = uri
        @cookie = cookie
        @count = 0
    end

    def visit_through(router = nil)
        proxy = router.is_a?(ProxyRouter) ? router.proxy : nil
        begin 
            open(@uri, :proxy => nil) do |http|
                @count = @count + 1
                yield http.read
            end
        rescue Exception => e
            yield e.to_s
        end
    end
end

class Router
    attr_accessor :type, :remote_ip, :uri, :proxy
    def initialize(uri=nil, type="direct")
        @type = type
        @remote_ip = nil
        @proxy = nil
        @uri = uri;
    end

    def get_remote_ip()
        begin
            @remote_ip = open('http://whatismyip.akamai.com', :proxy=>@proxy).read
        rescue
            @remote_ip
        end
    end

    def renew()
        @remote_ip = nil
    end
end

class ProxyRouter < Router
    def initialize(proxy = nil)
       @proxy = proxy 
    end

    def validate()
        remote_ip = open('http://whatismyip.akamai.com', :proxy=>false).read
        begin
            ip = open('http://whatismyip.akamai.com', :proxy=>@proxy).read
            return true if ip != remote_ip
        rescue Exception=>e
        end
        false
    end
end

class AdslRouter < Router
    def renew()
        puts "remotely reset the Adsl at #{@url}"
        @remote_ip = nil 
    end
end

class ProxyFactory
    
    attr_accessor :proxy_list, :index

    def initialize(list)
        @proxy_list = list if list.is_a?(Array)
        @index = 0
    end

    def next
        proxy = proxy_list[@index]
        @index = (@index+1) % @proxy_list.size
        proxy
    end

    def prev
        proxy = proxy_list[@index]
        @index = (@index-1) % @proxy_list.size
        proxy
    end

    def self.proxy_from_html(html)
        []
    end

    def append(list)
       return nil if list.nil? 
       list.is_a?(Array) ? @proxy_list.concat(list) : @proxy_list << list
    end
end

