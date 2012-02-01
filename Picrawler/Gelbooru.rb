#coding:utf-8

#Picrawler under CC0
#Picrawler::Gelbooru module

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

class Picrawler::Gelbooru
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
			if @agent.cookie_jar.jar["gelbooru.com"]
				unless @agent.cookie_jar.jar["gelbooru.com"]["/"]["__cfduid"].expired? then return 1 end #use cookie
			end
		end

		#normal auth.
		form = @agent.get('http://gelbooru.com/index.php?page=account&s=login&code=00').forms.first
		form.field_with("user").value = user
		form.field_with("pass").value = pass
		#form.checkbox_with("remember_me").check
		#if @agent.submit(form).body.resolve =~ /Logout/
		unless @agent.submit(form).body.resolve =~ /Log in/ #lol?
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
		if ret then puts 'Browsing http://gelbooru.com/index.php?page=post&s=list&tags=user:'+arg end
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
		if ret then puts 'Browsing http://gelbooru.com/index.php?page=post&s=list&tags='+arg end
		return ret
	end

	def tag_next
		if @page==@stop then return false end
		if @seek_end then return false end
		begin
			@agent.get('http://gelbooru.com/index.php?page=post&s=list&tags='+@arg.uriEncode+'&pid='+(@page*28).to_s)
		rescue
			return false
		end

		unless @agent.page.body.resolve=~/ alt="next"\>/ then @seek_end=true end
		@content=[]
		array=@agent.page.body.resolve.split("<a id=\"p")
		array.shift
		array.each{|e|
			bookmark=0
			if e=~/(\d+).+?(http\:\/\/img.+?\.gelbooru\.com\/thumbs\/[0-9]+\/thumbnail_[0-9a-fA-F\/]+\.(jpeg|jpg|png|gif)(?:\?[0-9]+)?)/m
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push([$1+'.'+$3, $2.sub("/thumbnail_","/").sub("/thumbs/","/images/")])
			end
		}
		@page+=1
		sleep(@sleep)
		return true
	end
	alias member_next tag_next

	def crawl
		@content.each_with_index{|e,i| # e[0] -> filename, e[1] -> URL
			if @filter.include?(File.basename(e[0],".*"))
				if @fast then @seek_end=true end
			else
				#["jpg","jpeg","png","gif","err"].each{|ext|
				#	if ext=="err" then raise "[Programmer's fault: failed "+e[0] end
				#	begin
						@agent.get(e[1], [], 'http://gelbooru.com/') #2.1 syntax
						@agent.page.save_as(e[0]) #as file is written after obtaining whole file, it should be less dangerous.
						sleep(@sleep)
				#	rescue
				#		sleep(1)
				#	else
				#		break
				#	end
				#	#search next ext.
				#}
			end
			printf("Page %d %d/%d    \r",@page,i+1,@content.length) 
		}
	end
end