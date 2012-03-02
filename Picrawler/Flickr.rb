#coding:utf-8

#Picrawler under CC0
#Picrawler::Flickr module

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

class Picrawler::Flickr
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

	def list() return ["member","search","tag"] end

	def open(user,pass,cookie)
		return 1 #always success without login
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
		ret=tag_next
		if ret then puts 'Browsing http://www.flickr.com/photos/'+@arg end
		return ret
	end

	def member_next
		if @page==@stop then return false end
		@page+=1
		if @seek_end then return false end
		begin
			@agent.get('http://www.flickr.com/photos/'+@arg+'/page'+@page+'/')
		rescue
			return false
		end

		if @agent.page.body.resolve=~/span class="AtEnd"/ then @seek_end=true end
		@content=[]
		array=@agent.page.body.resolve.split(%Q(<span class="photo_container pc_m"><a data-track="photo-click" href="/photos/))
		array.shift
		array.each{|e|
			bookmark=0

			if e=~/^(.+?)\/in\/photostream\"/m
				@content.push("http://www.flickr.com/photos/"+$1+"/sizes/o/in/photostream/")
			end
		}
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

		@page=start-1
		@stop=stop
		ret=tag_next
		if ret then puts 'Browsing http://www.flickr.com/search/?w=all&mt=photos&ct=5&m=tags&q='+arg end
		return ret
	end

	def tag_next
		if @page==@stop then return false end
		@page+=1
		if @seek_end then return false end
		begin
			@agent.get('http://www.flickr.com/search/?w=all&mt=photos&ct=5&m=tags&q='+@arg.uriEncode+'&page='+@page.to_s)
		rescue
			return false
		end

		if @agent.page.body.resolve=~/span class="AtEnd"/ then @seek_end=true end
		@content=[]
		array=@agent.page.body.resolve.split(%Q(<span class="photo_container pc_t"><a href="/photos/))
		array.shift
		array.each{|e|
			bookmark=0

			if e=~/^([^\"]+)/m
				@content.push("http://www.flickr.com/photos/"+$1+"sizes/o/in/photostream/")
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
		ret=tag_next
		if ret then puts 'Browsing http://www.flickr.com/search/?w=all&mt=photos&ct=5&m=text&q='+arg end
		return ret
	end

	def search_next
		if @page==@stop then return false end
		@page+=1
		if @seek_end then return false end
		begin
			@agent.get('http://www.flickr.com/search/?w=all&mt=photos&ct=5&m=text&q='+@arg.uriEncode+'&page='+@page.to_s)
		rescue
			return false
		end

		if @agent.page.body.resolve=~/span class="AtEnd"/ then @seek_end=true end
		@content=[]
		array=@agent.page.body.resolve.split(%Q(<span class="photo_container pc_t"><a href="/photos/))
		array.shift
		array.each{|e|
			bookmark=0

			if e=~/^([^\"]+)/m
				@content.push("http://www.flickr.com/photos/"+$1+"sizes/o/in/photostream/")
			end
		}
		sleep(@sleep)
		return true
	end

	def crawl
		@content.each_with_index{|e,i| # e -> photostream URL
			e=~/^.+?\/(\d+)\/sizes\/o\/in\/photostream\/$/m
			num=$1
			if @filter.include?(num)
				if @fast then @seek_end=true end
			else
				@agent.get(e, [], 'http://www.flickr.com/') #2.1 syntax
				@agent.page.body.resolve=~/\<a href=\"(http:\/\/farm\d+.staticflickr.com\/\d+\/.+?_d\.([a-z]+?)(?:\?.+)?)\"\>/
				url=$1
				ext=$2
				sleep(1)
				@agent.get(url, [], e) #2.1 syntax
				@agent.page.save_as(num+'.'+ext) #as file is written after obtaining whole file, it should be less dangerous.
				sleep(@sleep)
			end
			printf("Page %d %d/%d    \r",@page,i+1,@content.length)
			exit
		}
	end
end
