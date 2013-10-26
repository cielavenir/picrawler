#coding:utf-8

#Picrawler under CC0
#Picrawler::Piapro module

class Picrawler::Piapro
	def initialize(options={})
		@agent=Mechanize.new
		@agent.user_agent="Mozilla/5.0"
		@encoding=options[:encoding]||raise
		@sleep=options[:sleep]||3
		@notifier=options[:notifier]
		@enter_critical=options[:enter_critical]
		@exit_critical=options[:exit_critical]
	end

	def list() return ["member","tag","keyword","audio","tagaudio","keywordaudio"] end

	def open(user,pass,cookie)
		if File.exist?(cookie)
			@agent.cookie_jar.load(cookie)
			if @agent.cookie_jar.jar.exists_rec?(["piapro.jp","/",'piapror'])
				unless @agent.cookie_jar.jar["piapro.jp"]["/"]['piapror'].expired? then return 1 end #use cookie
			end
		end
		if false
			@agent.get('https://piapro.jp/logout/')
			@agent.cookie_jar.save_as(cookie)
			return false
		end

		#normal auth.
		form = @agent.get('https://piapro.jp/login/').form_with(:action=>"/login/exe")
		form._username = user
		form._password = pass
		form.checkbox_with("_remember_me").check
		if @agent.submit(form).body.resolve =~ /ログアウト/
			@agent.cookie_jar.save_as(cookie)
			return 0
		end
		#auth failed.
		return -1
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
		@type='image'
		@argtype='pid'
		ret=member_next
		if ret then @notifier.call 'Browsing http://piapro.jp/content_list/?view='+@type+'&'+@argtype+'='+@arg+"\n" end
		return ret
	end

	def tag_first(options={})
		setup(options)
		@type='image'
		@argtype='tag'
		ret=member_next
		if ret then @notifier.call 'Browsing http://piapro.jp/content_list/?view='+@type+'&'+@argtype+'='+@arg+"\n" end
		return ret
	end

	def keyword_first(options={})
		setup(options)
		@type='image'
		@argtype='keyword'
		ret=member_next
		if ret then @notifier.call 'Browsing http://piapro.jp/content_list/?view='+@type+'&'+@argtype+'='+@arg+"\n" end
		return ret
	end

	def member_next
		if @page==@stop||@seek_end then return false end
		begin
			@agent.get('http://piapro.jp/content_list/?view='+@type+'&'+@argtype+'='+@arg.uriEncode+'&start_rec='+(@page*35).to_s)
		rescue
			return false
		end
		@page+=1

		if
			@agent.page.body.resolve=~/\<li\>\<span class="dum page_navi_sp"\>NEXT&nbsp;&gt;&gt;\<\/span\>\<\/li\>/ || 
			!(@agent.page.body.resolve=~/"\>NEXT&nbsp;&gt;&gt;\<\/a\>\<\/li\>/) #only 1 page
		@seek_end=true end

		@content=[]
		array=@agent.page.body.resolve.split(" style=\"background:url")
		array.shift
		array.each{|e|
			bookmark=0
			if e=~/\(http:\/\/c\d.piapro.jp\/timg\/([0-9a-z]+)_[0-9]+_0150_0150\.([a-z]+)\)/
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

	def audio_first(options={})
		setup(options)
		@type='audio'
		@argtype='pid'
		ret=audio_next
		if ret then @notifier.call 'Browsing http://piapro.jp/content_list/?view='+@type+'&'+@argtype+'='+@arg+"\n" end
		return ret
	end

	def tagaudio_first(options={})
		setup(options)
		@type='audio'
		@argtype='tag'
		ret=audio_next
		if ret then @notifier.call 'Browsing http://piapro.jp/content_list/?view='+@type+'&'+@argtype+'='+@arg+"\n" end
		return ret
	end

	def keywordaudio_first(options={})
		setup(options)
		@type='audio'
		@argtype='keyword'
		ret=audio_next
		if ret then @notifier.call 'Browsing http://piapro.jp/content_list/?view='+@type+'&'+@argtype+'='+@arg+"\n" end
		return ret
	end

	def audio_next
		if @page==@stop||@seek_end then return false end
		begin
			@agent.get('http://piapro.jp/content_list/?view='+@type+'&'+@argtype+'='+@arg.uriEncode+'&start_rec='+(@page*35).to_s)
		rescue
			return false
		end
		@page+=1

		if
			@agent.page.body.resolve=~/\<li\>\<span class="dum page_navi_sp"\>NEXT&nbsp;&gt;&gt;\<\/span\>\<\/li\>/ || 
			!(@agent.page.body.resolve=~/"\>NEXT&nbsp;&gt;&gt;\<\/a\>\<\/li\>/) #only 1 page
		@seek_end=true end

		@content=[]
		array=@agent.page.body.resolve.split(".data('piapro_player', { id: '")
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
				@agent.get("http://piapro.jp/download/?view=content&id="+e[0], [], 'http://piapro.jp/') #2.1 syntax
				@enter_critical.call
				@agent.page.save_as(e[0]+'.'+e[1])
				@exit_critical.call
				sleep(@sleep)
			end
			@notifier.call sprintf("Page %d %d/%d    \r",@page,i+1,@content.length)
		}
	end
end
