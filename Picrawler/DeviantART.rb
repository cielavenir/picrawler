#coding:utf-8

#Picrawler under CC0
#Picrawler::DeviantART module
#bookmark isn't implemented.

#!!! Not implemented yet. !!!

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

class Picrawler::DeviantART
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

	def list() return ["member","search"] end

	def open(user,pass,cookie)
		if File.exist?(cookie)
			@agent.cookie_jar.load(cookie)
			if @agent.cookie_jar.jar["deviantart.com"]
				unless @agent.cookie_jar.jar["deviantart.com"]["/"]["auth"].expired? then return 1 end #use cookie
			end
		end

		#normal auth.
		form = @agent.get('http://www.deviantart.com/').form_with(:action=>"https://www.deviantart.com/users/login")
		form.username = user
		form.password = pass
		form.checkbox_with("remember_me").check
		if @agent.submit(form).body.resolve =~ /Logout/
			@agent.cookie_jar.save_as(cookie)
			return 0
		end
		#auth failed.
		return -1
	end

	def member_first(arg,bookmark,fast,filter,start,stop)
		@arg=arg
		@bookmark=bookmark
		if @bookmark==nil then @bookmark=0 end
		@fast=fast
		@filter=filter
		@seek_end=false

		@page=start-1
		@stop=stop
		ret=member_next
		if ret then puts 'Browsing http://'+arg+'.deviantart.com/gallery/?catpath=/' end
		return ret
	end

	def member_next
		if @page==@stop then return false end
		if @seek_end then return false end
		begin
			@agent.get('http://'+@arg+'.deviantart.com/gallery/?catpath=/&offset='+(@page*24).to_s)
		rescue
			return false
		end

		unless @agent.page.body.resolve=~/\<a class="disabled"\>Next\<\/a\>/ then @seek_end=true end
		@content=[]
		array=@agent.page.body.resolve.split("<span class=\"tt-w\">")
		array.shift
		array.each{|e|
			bookmark=0
			if e=~/src\=\"(http\:\/\/.+?\.deviantart\.net\/fs\d{2}\/.+?\/([^\/]+.(jpeg|jpg|png|gif)))/ #collect_rid\=\"1\:\d+\" -> numeric ID
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push([$2,$1.sub("/150/","/")])
			end
		}
		@page+=1
		sleep(@sleep)
		return true
	end

	def search_first(arg,bookmark,fast,filter,start,stop)
		@arg=arg
		@bookmark=bookmark
		if @bookmark==nil then @bookmark=0 end
		@fast=fast
		@filter=filter
		@seek_end=false

		@page=start-1
		@stop=stop
		ret=search_next
		if ret then puts 'Browsing http://browse.deviantart.com/?order=5&q='+arg end
		return ret
	end

	def search_next
		if @page==@stop then return false end
		if @seek_end then return false end
		begin
			@agent.get('http://browse.deviantart.com/?order=5&q='+@arg.uriEncode+'&offset='+(@page*24).to_s)
		rescue
			return false
		end

		unless @agent.page.body.resolve=~/\<a class="disabled"\>Next\<\/a\>/ then @seek_end=true end
		@content=[]
		array=@agent.page.body.resolve.split("<span class=\"tt-w\">")
		array.shift
		array.each_with_index{|e,i|
			if i==24 then break end #kills daily deviation stuff
			bookmark=0
			if e=~/src\=\"(http\:\/\/.+?\.deviantart\.net\/fs\d{2}\/.+?\/([^\/]+.(jpeg|jpg|png|gif)))/
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push([$2,$1.sub("/150/","/")])
			end
		}
		@page+=1
		sleep(@sleep)
		return true
	end

	def crawl
		@content.each_with_index{|e,i| # e[0] -> filename, e[1] -> URL
			if @filter.include?(File.basename(e[0],".*"))
				if @fast then @seek_end=true end
			else
				@agent.get(e[1], [], 'http://www.deviantart.com/') #2.1 syntax
				@agent.page.save_as(e[0]) #as file is written after obtaining whole file, it should be less dangerous.
				sleep(@sleep)
			end
			printf("Page %d %d/%d    \r",@page,i+1,@content.length) 
		}
		exit
	end
end
