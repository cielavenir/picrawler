#coding:utf-8

#Picrawler under CC0
#Picrawler::Danbooru module

require "rubygems"
require "mechanize"
require "uri"

class String
	def resolve #must be called if you use regexp for Mechanize::Page#body
		if RUBY_VERSION >= '1.9.0' then self.force_encoding("UTF-8") end
		return self
	end

	def uriEncode
		return URI.encode(self)
	end
end

class Picrawler::Danbooru
	def initialize(encoding,sleep)
		@agent=Mechanize.new
		@agent.user_agent="Mozilla/5.0"
		@encoding=encoding
		@sleep=sleep

		@content=[]
		@seek_end=true
		@arg=""
		@bookmark=0
		@fast=false
		@filter=[]
	end

	def list() return ["member","tag"] end

	def open(user,pass,cookie)
		if File.exist?(cookie)
			@agent.cookie_jar.load(cookie)
			if @agent.cookie_jar.jar.exists_rec?(["danbooru.donmai.us","/","Danbooru"])
				unless @agent.cookie_jar.jar["danbooru.donmai.us"]["/"]["Danbooru"].expired? then return 1 end #use cookie
			end
		end

		#normal auth.
		form = @agent.get('http://danbooru.donmai.us/user/login').forms.first
		form.field_with("user[name]").value = user
		form.field_with("user[password]").value = pass
		#form.checkbox_with("remember_me").check
		if @agent.submit(form).body.resolve =~ /logged in/
			@agent.cookie_jar.save_as(cookie)
			return 0
		end
		#auth failed.
		return -1
	end

	def member_first(arg,bookmark,fast,filter,start,stop)
		@arg="user:"+arg
		@bookmark=bookmark
		if @bookmark==nil then @bookmark=0 end
		@fast=fast
		@filter=filter
		@seek_end=false

		@page=start-1
		@stop=stop
		ret=tag_next
		if ret then puts 'Browsing http://danbooru.donmai.us/post?tags=user:'+arg end
		return ret
	end

	def tag_first(arg,bookmark,fast,filter,start,stop)
		@arg=arg
		@bookmark=bookmark
		if @bookmark==nil then @bookmark=0 end
		@fast=fast
		@filter=filter
		@seek_end=false

		@page=start-1
		@stop=stop
		ret=tag_next
		if ret then puts 'Browsing http://danbooru.donmai.us/post?tags='+arg end
		return ret
	end

	def tag_next
		if @page==@stop then return false end
		@page+=1
		if @seek_end then return false end
		begin
			@agent.get('http://danbooru.donmai.us/post?tags='+@arg.uriEncode+'&page='+@page.to_s)
		rescue
			return false
		end

		if @agent.page.body.resolve=~/span id="cntdwn"/
			printf("Advertised...\r")
			sleep(10)
			begin
				@agent.get('http://danbooru.donmai.us/post?tags='+@arg.uriEncode+'&page='+@page.to_s)
			rescue
				return false
			end
		end

		unless @agent.page.body.resolve=~/rel="next"/ then @seek_end=true end
		@content=[]
		array=@agent.page.body.resolve.split("<a href=\"/post/show/")
		array.shift
		array.each{|e|
			bookmark=0
=begin
			if e=~/^(\d+).+?([0-9a-f]+\.(jpeg|jpg|png|gif))/m
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push([$1+'.'+$3, $2])
			end
=end
			if e=~/^(\d+).+?([0-9a-f]+)\.jpg/m
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push([$1, $2])
			end
		}
		sleep(@sleep)
		return true
	end
	alias member_next tag_next

	def crawl
		@content.each_with_index{|e,i| # e[0] -> id, e[1] -> Internal ID
			if @filter.include?(File.basename(e[0],".*"))
				if @fast then @seek_end=true end
			else
				["jpg","png","gif","jpeg","err"].each{|ext|
					if ext=="err" then raise "[Programmer's fault: failed "+e[0] end
					begin
						@agent.get("http://danbooru.donmai.us/data/"+e[1]+"."+ext, [], 'http://danbooru.donmai.us/') #2.1 syntax
						@agent.page.save_as(e[0]+"."+ext) #as file is written after obtaining whole file, it should be less dangerous.
						sleep(@sleep)
					rescue
						sleep(1)
					else
						break
					end
					#search next ext.
				}
			end
			printf("Page %d %d/%d    \r",@page,i+1,@content.length)
		}
	end
end
