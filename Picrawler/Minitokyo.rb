#coding:utf-8

#Picrawler under CC0
#Picrawler::Minitokyo module
#I won't update this module out of alpha...

class Picrawler::Minitokyo
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

		@novel=false
	end

	def list() return ["tid"] end

	def open(user,pass,cookie)
		if File.exist?(cookie)
			@agent.cookie_jar.load(cookie)
			if @agent.cookie_jar.jar.exists_rec?(["minitokyo.net","/","minitokyo_hash"])
				unless @agent.cookie_jar.jar["minitokyo.net"]["/"]["minitokyo_hash"].expired? then return 1 end #use cookie
			end
		end

		#normal auth.
		form = @agent.get('http://my.minitokyo.net/login').form_with(:action=>"http://my.minitokyo.net/login")
		form.username = user
		form.password = pass
		if @agent.submit(form,form.buttons.first).body.resolve =~ /Logout/ #lol?
			@agent.cookie_jar.save_as(cookie)
			return 0
		end
		#auth failed.
		return -1
	end
=begin
	def member_first(arg,bookmark,fast,filter,start,stop)
		@arg=arg
		@bookmark=bookmark
		if @bookmark==nil then @bookmark=0 end
		@fast=fast
		@filter=filter
		@seek_end=false
		@novel=false

		@page=start-1
		@stop=stop
		ret=member_next
		if ret then puts(('Browsing http://www.zerochan.net/user/'+arg).encode(@encoding,"UTF-8")) end
		return ret
	end

	def member_next
		if @page==@stop then return false end
		@page+=1
		if @seek_end then return false end
		begin
			@agent.get('http://www.zerochan.net/user/'+@arg.uriEncode+'?p='+@page.to_s)
		rescue
			return false
		end

		unless @agent.page.body.resolve=~/rel="next"/ then @seek_end=true end
		@content=[]
		body=@agent.page.body.resolve.split("<ul id=\"thumbs2\">")[1]
		array=body.split("</li>")
		array.shift
		array.each{|e|
			bookmark=0

			if e=~/src=\"http\:\/\/s[0-9a-z]+\.zerochan\.net\/240\/([0-9a-z\/]+)\.(jpeg|jpg|png|gif)/m
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push($1+"."+$2)
			end
		}
		if @content.length<1 then return false end
		sleep(@sleep)
		return true
	end
=end
	def tid_first(arg,bookmark,fast,filter,start,stop)
		@arg=arg
		@bookmark=bookmark
		if @bookmark==nil then @bookmark=0 end
		@fast=fast
		@filter=filter
		@seek_end=false
		@novel=false

		@page=start-1
		@stop=stop
		ret=tid_next
		if ret then puts(('Browsing http://browse.minitokyo.net/gallery?tid='+@arg+'&index=3').encode(@encoding,"UTF-8")) end
		return ret
	end

	def tid_next
		if @page==@stop then return false end
		@page+=1
		if @seek_end then return false end
		begin
			@agent.get('http://browse.minitokyo.net/gallery?tid='+@arg+'&index=3&page='+@page.to_s)
		rescue
			return false
		end

		unless @agent.page.body.resolve=~/Next &raquo;/ then @seek_end=true end
		@content=[]
		body=@agent.page.body.resolve.split("<ul class=\"scans\">")[1]
		array=body.split("</li>")
		array.shift
		array.each{|e|
			bookmark=0

			if e=~/src=\"http\:\/\/static2\.minitokyo\.net\/thumbs\/([0-9a-z\/]+)\.(jpeg|jpg|png|gif)/m
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push($1+"."+$2)
			end
		}
		if @content.length<1 then return false end
		sleep(@sleep)
		return true
	end

	def crawl
		@content.each_with_index{|e,i| # e -> filename
			if @filter.include?(File.basename(e,".*"))
				if @fast then @seek_end=true end
			else
				@agent.get("http://static.minitokyo.net/downloads/"+e, [], 'http://gallery.minitokyo.net/') #2.1 syntax
				@agent.page.save_as(File.basename(e)) #as file is written after obtaining whole file, it should be less dangerous.
				sleep(@sleep)
			end
			printf("Page %d %d/%d    \r",@page,i+1,@content.length)
		}
	end
end
