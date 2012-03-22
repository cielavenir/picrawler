#coding:utf-8

#Picrawler under CC0
#Picrawler::NicoSeiga module
#Shunga/Comic/Book are not supported.

class Picrawler::NicoSeiga
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
			if @agent.cookie_jar.jar.exists_rec?(["nicovideo.jp","/","user_session"])
				unless @agent.cookie_jar.jar["nicovideo.jp"]["/"]["user_session"].expired? then return 1 end #use cookie
			end
		end

		#normal auth.
		form = @agent.get('https://secure.nicovideo.jp/secure/login_form').forms[0]
		form.mail = user
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

		@page=start-1
		@stop=stop
		ret=member_next
		if ret then puts(('Browsing http://seiga.nicovideo.jp/user/illust/'+arg).encode(@encoding,"UTF-8")) end
		return ret
	end

	def member_next
		if @page==@stop then return false end
		@page+=1
		if @seek_end then return false end
		begin
			@agent.get('http://seiga.nicovideo.jp/user/illust/'+@arg+'?page='+@page.to_s+'&sort=image_created')
		rescue
			return false
		end

		unless @agent.page.body.resolve=~/rel="next"/ then @seek_end=true end
		@content=[]
		array=@agent.page.body.resolve.split("<div class=\"center_img  center_img_size_160\"><a href=\"/seiga/") #bah.
		array.shift
		array.each{|e|
			bookmark=0
			if e=~/クリップ：(\d+)/
				bookmark=$1.to_i
			end
			if e=~/im(\d+)/
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push($1)
			end
		}
		if @content.length<1 then return false end
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
		if ret then puts(('Browsing http://seiga.nicovideo.jp/tag/'+arg).encode(@encoding,"UTF-8")) end
		return ret
	end

	def tag_next
		if @page==@stop then return false end
		@page+=1
		if @seek_end then return false end
		begin
			@agent.get('http://seiga.nicovideo.jp/tag/'+@arg.uriEncode+'?page='+@page.to_s+'&target=illust&sort=image_created')
		rescue
			return false
		end

		unless @agent.page.body.resolve=~/rel="next"/ then @seek_end=true end
		@content=[]
		array=@agent.page.body.resolve.split("<div class=\"center_img  center_img_size_160\"><a href=\"/seiga/") #bah.
		array.shift
		array.each{|e|
			bookmark=0
			if e=~/クリップ：(\d+)/
				bookmark=$1.to_i
			end
			if e=~/im(\d+)/
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push($1)
			end
		}
		if @content.length<1 then return false end
		sleep(@sleep)
		return true
	end

	def crawl
		@content.each_with_index{|e,i| # e -> ID
			if @filter.include?(e)
				if @fast then @seek_end=true end
			else
				@agent.get("http://seiga.nicovideo.jp/image/source?id="+e, [], 'http://seiga.nicovideo.jp/') #2.1 syntax
				ext=""
				if @agent.page.response["content-type"]=="image/jpeg"
					ext=".jpg"
				elsif @agent.page.response["content-type"]=="image/png"
					ext=".png"
				elsif @agent.page.response["content-type"]=="image/gif"
					ext=".gif"
				else
					raise "[Developer's fault] must add crawl entry for "+@agent.page.response["content-type"]
				end
				@agent.page.save_as(e+ext) #as file is written after obtaining whole file, it should be less dangerous.
				sleep(@sleep)
			end
			printf("Page %d %d/%d    \r",@page,i+1,@content.length)
		}
	end
end
