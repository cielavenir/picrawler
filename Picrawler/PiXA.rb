#coding:utf-8

#Picrawler under CC0
#Picrawler::PiXA module

class Picrawler::PiXA
	def initialize(options={})
		@agent=Mechanize.new
		@agent.user_agent="Mozilla/5.0"
		@encoding=options[:encoding]||raise
		@sleep=options[:sleep]||3
		@notifier=options[:notifier]
		@enter_critical=options[:enter_critical]
		@exit_critical=options[:exit_critical]
	end

	def list() return ["member","tag","keyword","nickname"] end

	def open(user,pass,cookie)
		if File.exist?(cookie)
			@agent.cookie_jar.load(cookie)
			if @agent.cookie_jar.jar.fetch_nested(*["www.pixa.cc","/","_imagesns2_session"])
				unless @agent.cookie_jar.jar["www.pixa.cc"]["/"]["_imagesns2_session"].expired? then return 1 end #use cookie
			end
		end

		#normal auth.
		form = @agent.get('http://www.pixa.cc').form_with(:action=>"/session")
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
		if ret then @notifier.call 'Browsing http://www.pixa.cc/profiles/show/'+@arg+"\n" end
		return ret
	end

	def member_next
		if @page==@stop||@seek_end then return false end;@page+=1
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
		if @content.length<1 then return false end
		sleep(@sleep)
		return true
	end

	def tag_first(options={})
		setup(options)
		ret=tag_next
		if ret then @notifier.call 'Browsing http://www.pixa.cc/illustrations/list_tag?tag='+@arg+"\n" end
		return ret
	end

	def tag_next
		if @page==@stop||@seek_end then return false end;@page+=1
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
		if @content.length<1 then return false end
		sleep(@sleep)
		return true
	end

	def keyword_first(options={})
		setup(options)
		ret=keyword_next
		if ret then @notifier.call 'Browsing http://www.pixa.cc/illustrations/list_search?keyword='+@arg+"\n" end
		return ret
	end

	def keyword_next
		if @page==@stop||@seek_end then return false end;@page+=1
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
		if @content.length<1 then return false end
		sleep(@sleep)
		return true
	end

	def nickname_first(options={})
		setup(options)
		ret=nickname_next
		if ret then @notifier.call 'Browsing http://www.pixa.cc/illustrations/list_nickname?nickname='+@arg+"\n" end
		return ret
	end

	def nickname_next
		if @page==@stop||@seek_end then return false end;@page+=1
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
		if @content.length<1 then return false end
		sleep(@sleep)
		return true
	end

	def crawl
		@content.each_with_index{|e,i| # e[0] -> filename, e[1] -> original URL
			if @filter.include?(File.basename(e[0],".*"))
				if @fast then @seek_end=true end
			else
				@agent.get(e[1], [], 'http://www.pixa.cc/') #2.1 syntax
				@enter_critical.call
				@agent.page.save_as(e[0])
				@exit_critical.call
				sleep(@sleep)
			end
			@notifier.call sprintf("Page %d %d/%d    \r",@page,i+1,@content.length)
		}
	end
end
