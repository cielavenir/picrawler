#coding:Windows-31J

#Picrawler under CC0
#Picrawler::Piapro module

#Please don't use this module in Ruby 1.8 (due to combined charcode issue).

class Picrawler::Piapro
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

		@type='image'
		@argtype='pid'
	end

	def list() return ["member","tag","keyword","audio","tagaudio","keywordaudio"] end

	def open(user,pass,cookie)
		if File.exist?(cookie)
			@agent.cookie_jar.load(cookie)
			if @agent.cookie_jar.jar.exists_rec?(["piapro.jp","/",'%98y%E2%E1%F4nQ%C8'])
				unless @agent.cookie_jar.jar["piapro.jp"]["/"]['%98y%E2%E1%F4nQ%C8'].expired? then return 1 end #use cookie
			end
		end
		if false
			@agent.get('https://piapro.jp/logout/')
			@agent.cookie_jar.save_as(cookie)
			exit
		end

		#normal auth.
		form = @agent.get('https://piapro.jp/login/').form_with(:action=>"https://piapro.jp/login/")
		form.login_email = user
		form.login_password = pass
		form.checkbox_with("auto_login").check
		if @agent.submit(form).body.resolve2("CP932") =~ /ログアウト/
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

		@type='image'
		@argtype='pid'

		@page=start-1
		@stop=stop
		ret=member_next
		if ret then puts(('Browsing http://piapro.jp/content_list/?view='+@type+'&'+@argtype+'='+@arg).encode(@encoding,"UTF-8")) end
		return ret
	end

	def tag_first(arg,bookmark,fast,filter,start,stop)
		@arg=arg
		@bookmark=bookmark
		if @bookmark==nil then @bookmark=0 end
		@fast=fast
		@filter=filter
		@seek_end=false

		@type='image'
		@argtype='tag'

		@page=start-1
		@stop=stop
		ret=member_next
		if ret then puts(('Browsing http://piapro.jp/content_list/?view='+@type+'&'+@argtype+'='+@arg).encode(@encoding,"UTF-8")) end
		return ret
	end

	def keyword_first(arg,bookmark,fast,filter,start,stop)
		@arg=arg
		@bookmark=bookmark
		if @bookmark==nil then @bookmark=0 end
		@fast=fast
		@filter=filter
		@seek_end=false

		@type='image'
		@argtype='keyword'

		@page=start-1
		@stop=stop
		ret=member_next
		if ret then puts(('Browsing http://piapro.jp/content_list/?view='+@type+'&'+@argtype+'='+@arg).encode(@encoding,"UTF-8")) end
		return ret
	end

	def member_next
		if @page==@stop then return false end
		if @seek_end then return false end
		begin
			@agent.get('http://piapro.jp/content_list/?view='+@type+'&'+@argtype+'='+@arg.encode('CP932','UTF-8').uriEncode+'&start_rec='+(@page*35).to_s)
		rescue
			return false
		end
		@page+=1

		if
			@agent.page.body.resolve2("CP932")=~/\<li\>\<span class="dum page_navi_sp"\>NEXT&nbsp;&gt;&gt;\<\/span\>\<\/li\>/ || 
			!(@agent.page.body.resolve2("CP932")=~/"\>NEXT&nbsp;&gt;&gt;\<\/a\>\<\/li\>/) #only 1 page
		@seek_end=true end

		@content=[]
		array=@agent.page.body.resolve2("CP932").split(" style=\"background:url")
		array.shift
		array.each{|e|
			bookmark=0
			if e=~/\(http:\/\/c\d.piapro.jp\/timg\/([0-9a-z]+)_[0-9]+_0120_0120\.([a-z]+)\)/
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push([$1,$2])
			end
		}
		if @content.length<1 then return false end
		sleep(@sleep)
		return true
	end
	#alias member_next image_next
	alias tag_next member_next
	alias keyword_next member_next

	def audio_first(arg,bookmark,fast,filter,start,stop)
		@arg=arg
		@bookmark=bookmark
		if @bookmark==nil then @bookmark=0 end
		@fast=fast
		@filter=filter
		@seek_end=false

		@type='audio'
		@argtype='pid'

		@page=start-1
		@stop=stop
		ret=audio_next
		if ret then puts(('Browsing http://piapro.jp/content_list/?view='+@type+'&'+@argtype+'='+@arg).encode(@encoding,"UTF-8")) end
		return ret
	end

	def tagaudio_first(arg,bookmark,fast,filter,start,stop)
		@arg=arg
		@bookmark=bookmark
		if @bookmark==nil then @bookmark=0 end
		@fast=fast
		@filter=filter
		@seek_end=false

		@type='audio'
		@argtype='tag'

		@page=start-1
		@stop=stop
		ret=audio_next
		if ret then puts(('Browsing http://piapro.jp/content_list/?view='+@type+'&'+@argtype+'='+@arg).encode(@encoding,"UTF-8")) end
		return ret
	end

	def keywordaudio_first(arg,bookmark,fast,filter,start,stop)
		@arg=arg
		@bookmark=bookmark
		if @bookmark==nil then @bookmark=0 end
		@fast=fast
		@filter=filter
		@seek_end=false

		@type='audio'
		@argtype='keyword'

		@page=start-1
		@stop=stop
		ret=audio_next
		if ret then puts(('Browsing http://piapro.jp/content_list/?view='+@type+'&'+@argtype+'='+@arg).encode(@encoding,"UTF-8")) end
		return ret
	end

	def audio_next
		if @page==@stop then return false end
		if @seek_end then return false end
		begin
			@agent.get('http://piapro.jp/content_list/?view='+@type+'&'+@argtype+'='+@arg.encode('CP932','UTF-8').uriEncode+'&start_rec='+(@page*35).to_s)
		rescue
			return false
		end
		@page+=1

		if
			@agent.page.body.resolve2("CP932")=~/\<li\>\<span class="dum page_navi_sp"\>NEXT&nbsp;&gt;&gt;\<\/span\>\<\/li\>/ || 
			!(@agent.page.body.resolve2("CP932")=~/"\>NEXT&nbsp;&gt;&gt;\<\/a\>\<\/li\>/) #only 1 page
		@seek_end=true end

		@content=[]
		array=@agent.page.body.resolve2("CP932").split("<a href=\"javascript:swf_popup_display('")
		array.shift
		array.each{|e|
			bookmark=0
			if e=~/([0-9a-z]+)/
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push([$1,"mp3"])
			end
		}
		if @content.length<1 then return false end
		sleep(@sleep)
		return true
	end
	alias tagaudio_next audio_next
	alias keywordaudio_next audio_next

	def crawl
		@content.each_with_index{|e,i| # e[0] -> Internal ID, e[1] -> ext
			if @filter.include?(e[0])
				if @fast then @seek_end=true end
			else
				@agent.get("http://piapro.jp/download/?view=content_"+@type+"&id="+e[0], [], 'http://piapro.jp/') #2.1 syntax
=begin
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
=end
				@agent.page.save_as(e[0]+'.'+e[1]) #as file is written after obtaining whole file, it should be less dangerous.
				sleep(@sleep)
			end
			printf("Page %d %d/%d    \r",@page,i+1,@content.length)
		}
	end
end
