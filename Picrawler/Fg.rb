#coding:utf-8

#Picrawler under CC0
#Picrawler::Fg module
#bookmark isn't implemented.

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

class Picrawler::Fg
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
			if @agent.cookie_jar.jar.exists_rec?(["fg-site.net","/","my_id"])
				unless @agent.cookie_jar.jar["fg-site.net"]["/"]["my_id"].expired? then return 1 end #use cookie
			end
		end

		#normal auth.
		form = @agent.get('http://www.fg-site.net/users/login/').form_with(:action=>"/users/login")
		form.field_with("data[email]").value = user
		form.field_with("data[password]").value = pass
		form.checkbox_with("data[autologin]").check
		if @agent.submit(form).body.resolve =~ /ログアウト/
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
		if ret then puts 'Browsing http://www.fg-site.net/contents/view/user_id:'+arg+'/' end
		return ret
	end

	def member_next
		if @page==@stop then return false end
		@page+=1
		if @seek_end then return false end
		begin
			@agent.get('http://www.fg-site.net/contents/view/user_id:'+@arg+'/page:'+@page.to_s)
		rescue
			return false
		end

		unless @agent.page.body.resolve=~/次の20件/ then @seek_end=true end ###
		@content=[]
		array=@agent.page.body.resolve.split("<a href=\"http://www.fg-site.net/products/")
		array.shift
		array.each{|e|
			bookmark=0
			if e=~/.+?(http\:\/\/image.+?\.fg-site\.net\/image\/mid\/\d+\/(.+?\.(jpeg|jpg|png|gif)))/m
				if @bookmark>0 && bookmark<@bookmark then next end
				url,filename = $1,$2
				@content.push([filename.gsub("mid","org"), url.gsub("/mid","/org")])
			end
		}
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
		if ret then puts 'Browsing http://www.fg-site.net/contents/search/sort:created/direction:desc/word:'+arg+'/' end
		return ret
	end

	def search_next
		if @page==@stop then return false end
		@page+=1
		if @seek_end then return false end
		begin
			@agent.get('http://www.fg-site.net/contents/search/sort:created/direction:desc/word:'+@arg.uriEncode+'/page:'+@page.to_s)
		rescue
			return false
		end

		unless @agent.page.body.resolve=~/次の20件/ then @seek_end=true end ###
		@content=[]
		array=@agent.page.body.resolve.split("<a href=\"http://www.fg-site.net/products/")
		array.shift
		array.each{|e|
			if e=~/.+?(http\:\/\/image.+?\.fg-site\.net\/image\/mid\/\d+\/(.+?\.(jpeg|jpg|png|gif)))/m
				if @bookmark>0 && bookmark<@bookmark then next end
				url,filename = $1,$2
				@content.push([filename.gsub("mid","org"), url.gsub("/mid","/org")])
			end
		}
		sleep(@sleep)
		return true
	end

	def crawl
		@content.each_with_index{|e,i| # e[0] -> filename, e[1] -> URL
			if @filter.include?(File.basename(e[0],".*"))
				if @fast then @seek_end=true end
			else
				@agent.get(e[1], [], 'http://www.fg-site.net/') #2.1 syntax
				@agent.page.save_as(e[0]) #as file is written after obtaining whole file, it should be less dangerous.
				sleep(@sleep)
			end
			printf("Page %d %d/%d    \r",@page,i+1,@content.length) 
		}
	end
end
