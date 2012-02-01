#coding:utf-8

#Picrawler under CC0
#Picrawler::Tinami module
#!!! Very experimental. Too many modes... !!!

# type[]=X X->1=illust,2=comic,3=model,4=novel,5=cosplay

=begin
POST /view/ID HTTP/1.1
Host: www.tinami.com
User-Agent: Mozilla/5.0
Referer: http://www.tinami.com/view/ID
Cookie: ***
Content-Type: application/x-www-form-urlencoded
Content-Length: ***

action_view_original=true&cont_id=ID&ethna_csrf=***
=end

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

class Picrawler::Tinami
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
		@type=1
	end

	def list() return ["member","tag"] end

	def open(user,pass,cookie)
		if File.exist?(cookie)
			@agent.cookie_jar.load(cookie)
			if @agent.cookie_jar.jar["www.tinami.com"]
				unless @agent.cookie_jar.jar["www.tinami.com"]["/"]["vid"].expired? || @agent.cookie_jar.jar["www.tinami.com"]["/"]["rem2"].expired? then return 1 end #use cookie
			end
		end

		#normal auth.
		form = @agent.get('http://www.tinami.com/login').forms[1]
		form.username = user
		form.password = pass
		#form.checkbox_with("remember_me").check
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
		@type=1

		@page=start-1
		@stop=stop
		ret=member_next
		if ret then puts 'Browsing http://www.tinami.com/search/list?sort=new&type[]=1&prof_id='+arg end
		return ret
	end

	def member_next
		if @page==@stop then return false end
		if @seek_end then return false end
		begin
			@agent.get('http://www.tinami.com/search/list?sort=new&type[]=1&prof_id='+@arg+'&offset='+(@page*20).to_s)
		rescue
			return false
		end

		unless @agent.page.body.resolve=~/id="next-page"/ then @seek_end=true end
		@content=[]
		array=@agent.page.body.resolve.split("<a href=\"/view/")
		array.shift
		array.each{|e|
			bookmark=0
			if e=~/(\d+)/
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push($1)
			end
		}
		@page+=1
		sleep(@sleep)
		return true
	end

	def tag_first(arg,bookmark,fast,filter,start,stop)
		@arg=arg
		@bookmark=bookmark
		if @bookmark==nil then @bookmark=0 end
		@fast=fast
		@filter=filter
		@seek_end=false
		@type=1

		@page=start-1
		@stop=stop
		ret=tag_next
		if ret then puts 'Browsing http://www.tinami.com/search/list?sort=new&type[]=1&keyword='+arg end
		return ret
	end

	def tag_next
		if @page==@stop then return false end
		if @seek_end then return false end
		begin
			@agent.get('http://www.tinami.com/search/list?sort=new&type[]=1&keyword='+@arg.uriEncode+'&offset='+(@page*20).to_s)
		rescue
			return false
		end

		unless @agent.page.body.resolve=~/id="next-page"/ then @seek_end=true end
		@content=[]
		array=@agent.page.body.resolve.split("<a href=\"/view/")
		array.shift
		array.each{|e|
			bookmark=0
			if e=~/(\d+)/
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push($1)
			end
		}
		@page+=1
		sleep(@sleep)
		return true
	end

	def crawl
		@content.each_with_index{|e,i| # e -> ID
			case @type
				when 1
					if @filter.include?(e)
						if @fast then @seek_end=true end
					else
						@agent.get('http://www.tinami.com/view/'+e, [], 'http://www.tinami.com/') #2.1 syntax
						sleep(1)
						forms = @agent.page.forms
						if forms.length > 2
							form=forms[2]
							body=@agent.submit(form).body
							sleep(1)
							if body=~/(http\:\/\/img.tinami.com\/illust\d*\/img\/\d+\/[0-9a-f]+\.(jpeg|jpg|png|gif))/
								ext=$2
								@agent.get($1, [], 'http://www.tinami.com/') #2.1 syntax
								@agent.page.save_as(e+"."+ext) #as file is written after obtaining whole file, it should be less dangerous.
								sleep(@sleep)
							else
								raise "[Programmer's fault] cannot parse HTML:\n"+body
							end
						end
					end
				else
					raise "Type "+@type.to_s+" not implemented!"
			end
			printf("Page %d %d/%d    \r",@page,i+1,@content.length) 
		}
	end
end
