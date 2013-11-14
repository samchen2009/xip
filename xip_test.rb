require 'test/unit'
require 'pp'
require 'debugger'
require './xip_lib.rb'

class ProxyFactoryTest < Test::Unit::TestCase
    def test_init
        pf = ProxyFactory.new(["http://10.83.124.151:1080","http://localhost:80"])
        assert pf.proxy_list.size == 2
    end

    def test_next_prev
        pf = ProxyFactory.new(["http://10.83.124.151:1080","http://localhost:80"])
        debugger
        assert(pf.next =~ /10.83.124.151/)
        assert(pf.next =~ /localhost/)
        assert(pf.prev =~ /10.83.124.151/)
        assert(pf.prev =~ /localhost/)
    end

    def test_append
        pf = ProxyFactory.new(["http://10.83.124.151:1080","http://localhost:80"])
        pf.append("http://10.37.131.231:30")
        assert pf.proxy_list.size == 3
        pf.append(["http://10.37.131.231:130", "sdfsdf"])
        assert pf.proxy_list.size == 5
    end

    def test_from_html

    end
end

class RouterTest < Test::Unit::TestCase
    def test_router_new
        r = Router.new()
        ip = r.get_remote_ip()
        assert !ip.nil?
    end

    def test_router_proxy
        r = Router.new()
        ip1 = r.get_remote_ip()
        r.proxy = "http://10.83.124.151:1080"
        ip2 = r.get_remote_ip()
        puts [ip1,ip2]
        assert ip1 != ip2
    end

    def test_router_renew
        r = Router.new()
        r.remote_ip = "abc"
        r.renew()
        assert(r.remote_ip.nil?)
    end
end

class ProxyRouterTest < Test::Unit::TestCase
    def test_validate
        r = ProxyRouter.new("http://192.1.1.1:9090")
        assert(!r.validate())

        r = ProxyRouter.new("http://10.83.124.151:1080")
        assert(r.validate())
    end
end

class AdslRouterTest < Test::Unit::TestCase
    def test_renew

    end
end
