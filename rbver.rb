begin
  require 'http'
  require 'nokogiri'
  require 'down'
  require 'down/http'
rescue LoadError
  puts 'gem install http nokogiri down --platform=ruby'
  exit 0
end

url = 'https://rubyinstaller.org/downloads/archives/'
puts "GET #{url}"
doc = Nokogiri::HTML(HTTP.via('127.0.0.1', 1080).get(url).to_s)
ul = doc.at('#archives').next_element
lis = ul.search('li.rubyinstaller7z')
rbs = lis.map { |li| { text: li.at('a.downloadlink').text,
                       href: li.at('a.downloadlink')['href'],
                       sha: li.at('input')&.[]('value') } }
grbs = rbs.group_by { |e| e[:text][/Ruby \d\.\d\.\d/] }
rb = grbs.values.map { |e| e.reject { |a| a[:text]['x64'] }
                            .sort_by { |a| a[:text] }[-1] }

down = Down::Http.new { |http| http.via('127.0.0.1', 1080) }
percent = -> f { '%.02f%%' % (100 * f) }

include FileUtils
TEMP_CACHE = 'temp.cache'
Cache = File.exist?(TEMP_CACHE) ? (Marshal.load IO.binread TEMP_CACHE) : {}

mkdir_p 'each'
rb.reverse_each { |text:, href:, sha:|
  dist = "each/#{text[/\d\.\d\.\d/]}.ri"
  next if File.exist? dist
  unless Cache.key?(dist) && File.exist?(Cache[dist])
    print "DOWNLOAD #{text} \e[s"
    m = m
    rb7z = down.download href,
      content_length_proc: -> max { m = max.to_f },
      progress_proc: -> i { print "\e[u", m ? percent[i / m] : i }
    puts
    rb7z.close
    Cache[dist] = rb7z.path
    open TEMP_CACHE, 'wb' do |f|
      Marshal.dump Cache, f
    end
  end
  puts "\e[s7z x #{Cache[dist]}"
  system '7z', 'x', Cache[dist], out: File::NULL
  folder = Dir['ruby*'][0]
  system "#{folder}/bin/ruby.exe", 'dig.rb'
  rm_rf folder
  mv 'dig.ri', dist
  print "\e[u\e[0K"
}

Ancestors = {}
def build_ancestors x={}, *n
  k = n.empty? ? 'Object' : n.join('::')
  Ancestors[k] = x[:a]
  x[:s]&.each { |m, y| build_ancestors y, *n, m }
end

@ver = 0
Versions = {}
def build_versions x={}, *n
  k = n.empty? ? 'Object' : n.join('::')
  o = (Versions[k] ||= { i: {}, c: {}, a: {}, _: @ver })
  x[:i]&.each { |i| o[:i][i] ||= @ver }
  x[:c]&.each { |c| o[:c][c] ||= @ver }
  x[:i]&.grep(/^\w+=/) { |a| o[:a][a[0..-2]] ||= @ver }
  x[:s]&.each { |m, y| build_versions y, *n, m }
end

Dir.glob('each/?.?.?.ri') do |f|
  @ver = f[/\d\.\d\.\d/].split('.').join.to_i - 100
  a = open(f) { |f| Marshal.load f }
  build_ancestors a
  build_versions a
end

open 'ancestors.ri', 'wb' do |f|
  Marshal.dump Ancestors, f
end

open 'ancestors.json', 'w' do |f|
  f.write JSON.generate Ancestors
end

open 'versions.ri', 'wb' do |f|
  Marshal.dump Versions, f
end

open 'versions.json', 'w' do |f|
  f.write JSON.generate Versions
end