#coding:utf-8

#Picrawler under CC0
#Picrawler::Flickr module

class Picrawler::Flickr
	def initialize(options={})
		@agent=Mechanize.new
		@agent.user_agent="Mozilla/5.0"
		@encoding=options[:encoding]||raise
		@sleep=options[:sleep]||3
		@notifier=options[:notifier]
	end

	def list() return ["member","search","tag"] end

	def open(user,pass,cookie)
		return 1 #always success without login
	end

	def setup(options={})
		@arg=options[:arg]||raise
		@bookmark=options[:bookmark]||0
		@fast=options[:fast]
		@filter=options[:filter]||[]
		@page=options[:start] ? options[:start]-1 : 0
		@stop=options[:stop]||-1
		@additional=options[:additional]||''
		@seek_end=false
	end

	def member_first(options={})
		setup(options)
		ret=member_next
		if ret then @notifier.call 'Browsing http://www.flickr.com/photos/'+@arg+"\n" end
		return ret
	end

	def member_next
		if @page==@stop||@seek_end then return false end;@page+=1
		begin
			@agent.get('http://www.flickr.com/photos/'+@arg+'/page'+@page.to_s+'/')
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
		if @content.length<1 then return false end
		sleep(@sleep)
		return true
	end

	def tag_first(options={})
		setup(options)
		ret=tag_next
		if ret then @notifier.call 'Browsing http://www.flickr.com/search/?w=all&mt=photos&ct=5&m=tags&q='+@arg+"\n" end
		return ret
	end

	def tag_next
		if @page==@stop||@seek_end then return false end;@page+=1
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
		if @content.length<1 then return false end
		sleep(@sleep)
		return true
	end

	def search_first(options={})
		setup(options)
		ret=tag_next
		if ret then @notifier.call 'Browsing http://www.flickr.com/search/?w=all&mt=photos&ct=5&m=text&q='+@arg+"\n" end
		return ret
	end

	def search_next
		if @page==@stop||@seek_end then return false end;@page+=1
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
		if @content.length<1 then return false end
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
			@notifier.call sprintf("Page %d %d/%d    \r",@page,i+1,@content.length)
		}
	end
end
