#coding:utf-8

#Picrawler under CC0
#Picrawler::PiXA module

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

class Picrawler::PiXA
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

	def list() return ["member","tag","keyword","nickname"] end

	def open(user,pass,cookie)
		if File.exist?(cookie)
			@agent.cookie_jar.load(cookie)
			if @agent.cookie_jar.jar["www.pixa.cc"]
				unless @agent.cookie_jar.jar["www.pixa.cc"]["/"]["auth_token"].expired? then return 1 end #use cookie
			end
		end

		#normal auth.
		form = @agent.get('http://www.pixa.cc').forms[1]
		form.email = user
		form.password = pass
		form.checkbox_with("remember_me").check
		if @agent.submit(form).body.resolve =~ /ログアウト/
			@agent.cookie_jar.save_as(cookie)
			return 0
		end
		#auth failed.
		return -1
	end

	def member_first(arg,bookmark,fast,filter)
		@arg=arg
		@bookmark=bookmark
		if @bookmark==nil then @bookmark=0 end
		@fast=fast
		@filter=filter
		@seek_end=false

		@page=0
		ret=member_next
		if ret then puts 'Browsing http://www.pixa.cc/profiles/show/'+arg end
		return ret
	end

	def member_next
		@page+=1
		if @seek_end then return false end
		begin
			@agent.get('http://www.pixa.cc/profiles/show/'+@arg+'?page='+@page.to_s)
		rescue
			return false
		end

		unless @agent.page.body.resolve=~/rel="next"/ then @seek_end=true end
		@content=[]
		array=@agent.page.body.resolve.split("          <a href=\"/illustrations/show/") #bah.
		array.shift
		array.each{|e|
			bookmark=0
			if e=~/(\d+)users/
				bookmark=$1.to_i
			end
			if e=~/(\d+).+?(http\:\/\/file.+?\.pixa\.cc\/illustrations\/[0-9a-fA-F\/]+\/two_thumb\/.+?\.(jpeg|jpg|png|gif)(?:\?[0-9]+)?)/
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push([$1+'.'+$3, $2.gsub("two_thumb","original")])
			end
		}
		sleep(@sleep)
		return true
	end

	def tag_first(arg,bookmark,fast,filter)
		@arg=arg
		@bookmark=bookmark
		if @bookmark==nil then @bookmark=0 end
		@fast=fast
		@filter=filter
		@seek_end=false

		@page=0
		ret=tag_next
		if ret then puts 'Browsing http://www.pixa.cc/illustrations/list_tag?tag='+arg end
		return ret
	end

	def tag_next
		@page+=1
		if @seek_end then return false end
		begin
			@agent.get('http://www.pixa.cc/illustrations/list_tag?tag='+@arg.uriEncode+'&page='+@page.to_s)
		rescue
			return false
		end

		unless @agent.page.body.resolve=~/rel="next"/ then @seek_end=true end
		@content=[]
		array=@agent.page.body.resolve.split("          <a href=\"/illustrations/show/") #bah.
		array.shift
		array.each{|e|
			bookmark=0
			if e=~/(\d+)users/
				bookmark=$1.to_i
			end
			if e=~/(\d+).+?(http\:\/\/file.+?\.pixa\.cc\/illustrations\/[0-9a-fA-F\/]+\/two_thumb\/.+?\.(jpeg|jpg|png|gif)(?:\?[0-9]+)?)/
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push([$1+'.'+$3, $2.gsub("two_thumb","original")])
			end
		}
		sleep(@sleep)
		return true
	end

	def keyword_first(arg,bookmark,fast,filter)
		@arg=arg
		@bookmark=bookmark
		if @bookmark==nil then @bookmark=0 end
		@fast=fast
		@filter=filter
		@seek_end=false

		@page=0
		ret=keyword_next
		if ret then puts 'Browsing http://www.pixa.cc/illustrations/list_search?keyword='+arg end
		return ret
	end

	def keyword_next
		@page+=1
		if @seek_end then return false end
		begin
			@agent.get('http://www.pixa.cc/illustrations/list_search?keyword='+@arg.uriEncode+'&page='+@page.to_s)
		rescue
			return false
		end

		unless @agent.page.body.resolve=~/rel="next"/ then @seek_end=true end
		@content=[]
		array=@agent.page.body.resolve.split("          <a href=\"/illustrations/show/") #bah.
		array.shift
		array.each{|e|
			bookmark=0
			if e=~/(\d+)users/
				bookmark=$1.to_i
			end
			if e=~/^(\d+).+?(http\:\/\/file.+?\.pixa\.cc\/illustrations\/[0-9a-fA-F\/]+\/two_thumb\/.+?\.(jpeg|jpg|png|gif)(?:\?[0-9]+)?)/m
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push([$1+'.'+$3, $2.gsub("two_thumb","original")])
			end
		}
		sleep(@sleep)
		return true
	end

	def nickname_first(arg,bookmark,fast,filter)
		@arg=arg
		@bookmark=bookmark
		if @bookmark==nil then @bookmark=0 end
		@fast=fast
		@filter=filter
		@seek_end=false

		@page=0
		ret=nickname_next
		if ret then puts 'Browsing http://www.pixa.cc/illustrations/list_nickname?nickname='+arg end
		return ret
	end

	def nickname_next
		@page+=1
		if @seek_end then return false end
		begin
			@agent.get('http://www.pixa.cc/illustrations/list_nickname?nickname='+@arg.uriEncode+'&page='+@page.to_s)
		rescue
			return false
		end

		unless @agent.page.body.resolve=~/rel="next"/ then @seek_end=true end
		@content=[]
		array=@agent.page.body.resolve.split("          <a href=\"/illustrations/show/") #bah.
		array.shift
		array.each{|e|
			bookmark=0
			if e=~/(\d+)users/
				bookmark=$1.to_i
			end
			if e=~/^(\d+).+?(http\:\/\/file.+?\.pixa\.cc\/illustrations\/[0-9a-fA-F\/]+\/two_thumb\/.+?\.(jpeg|jpg|png|gif)(?:\?[0-9]+)?)/m
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push([$1+'.'+$3, $2.gsub("two_thumb","original")])
			end
		}
		sleep(@sleep)
		return true
	end

	def crawl
		@content.each_with_index{|e,i| # e[0] -> filename, e[1] -> original URL
			if @filter.include?(File.basename(e[0],".*"))
				if @fast then @seek_end=true end
			else
				@agent.get(e[1], [], 'http://www.pixa.cc/') #2.1 syntax
				@agent.page.save_as(e[0]) #as file is written after obtaining whole file, it should be less dangerous.
				sleep(@sleep)
			end
			printf("Page %d %d/%d    \r",@page,i+1,@content.length) 
		}
	end
end