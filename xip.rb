require './xip_lib.rb'
require 'yaml'
require 'thread'
require 'open-uri'

if ($0 == __FILE__)
  usage = "usage: xip proxy/adsl"

  if (!ARGV[0])
    puts usage
    exit 1
  end
end

if ARGV[0] =~ /proxy/i
    proxy_list = YAML::load(File.read("#{File.expand_path(File.dirname(__FILE__))}/proxy.yml")).compact
    proxy_factory = ProxyFactory.new(proxy_list)
    proxy_finder = YAML::load(File.read("#{File.expand_path(File.dirname(__FILE__))}/proxy_finder.yml")).compact
    proxy_finder.each do |f|
        begin 
            open(f["uri"], :proxy=>false) do |http|
                candiates = ProxyFacotry.proxy_from_html(http.read())
                candiates.each do |c|
                    proxy_factory.append(c) if ProxyRouter.new(c).validate()
                end
            end
        rescue Exception => e
            puts f["uri"] + " error: " + e.to_s
        end
    end
    puts proxy_factory.proxy_list
else

end

#load all webpages from yml
puts "parsing pages.yml"
pages = YAML::load(File.read("#{File.expand_path(File.dirname(__FILE__))}/pages.yml")).compact
puts pages

tids = []
queue = Queue.new()

webPages = []
pages.each do |page|
    webPages << WebPage.new(page["uri"])
end
puts webPages

tids << Thread.new do
    puts "Http Thread start"
    loop = 0
    while true
        tmp_router = queue.pop()
        puts "Http thread receiver new router #{tmp_router}"
        loop = loop + 1
        webPages.each do |wp|
            wp.visit_through(tmp_router) {|h| puts "vist #{wp.uri} #{loop} return #{h.is_a?(RuntimeError) ? 0 : h.size} Byte, success rate: #{wp.count}/#{loop}"}
        end
        puts "#{Thread.current} wait for next router ..."
    end
end


tids << Thread.new do
   renew_count = 0 
   default_router = Router.new()
   puts default_router
   current_ip = default_router.get_remote_ip
   router = ARGV[0] =~ /proxy/i ? ProxyRouter.new() : AdslRouter.new()
   queue << default_router
   while true
      if ARGV[0] =~ /proxy/i
        router.proxy = proxy_factory.next["uri"]
      else
        router.proxy = nil
      end
      router.renew()
      sleep(5)
      next if router.get_remote_ip() == current_ip
      current_ip = router.remote_ip
      puts "XIP thread push new router #{router} with new ip #{current_ip}"
      queue << router
   end
end
sleep(100000)
