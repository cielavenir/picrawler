#coding:utf-8

#Picrawler under CC0
#Picrawler::DeviantART module
#bookmark isn't implemented.

class Picrawler::DeviantART
	def initialize(options={})
		@agent=Mechanize.new
		@agent.user_agent="Mozilla/5.0"
		@encoding=options[:encoding]||raise
		@sleep=options[:sleep]||3
		@notifier=options[:notifier]
		@enter_critical=options[:enter_critical]
		@exit_critical=options[:exit_critical]
	end

	def list() return ["member","search"] end

	def open(user,pass,cookie)
		if File.exist?(cookie)
			@agent.cookie_jar.load(cookie)
			if @agent.cookie_jar.jar.fetch_nested(*["deviantart.com","/","auth"])
				unless @agent.cookie_jar.jar["deviantart.com"]["/"]["auth"].expired? then return 1 end #use cookie
			end
		end

		#normal auth.
		form = @agent.get('http://www.deviantart.com/').form_with(:action=>"https://www.deviantart.com/users/login")
		form.username = user
		form.password = pass
		form.checkbox_with("remember_me").check
		if @agent.submit(form).body.resolve =~ /Logout/
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
		if ret then @notifier.call 'Browsing http://'+@arg+'.deviantart.com/gallery/?catpath=/'+"\n" end
		return ret
	end

	def member_next
		if @page==@stop||@seek_end then return false end
		begin
			@agent.get('http://'+@arg+'.deviantart.com/gallery/?catpath=/&offset='+(@page*24).to_s)
		rescue
			return false
		end

		unless @agent.page.body.resolve=~/\<a class="disabled"\>Next\<\/a\>/ then @seek_end=true end
		@content=[]
		array=@agent.page.body.resolve.split("<span class=\"tt-w\">")
		array.shift
		array.each{|e|
			bookmark=0
			if e=~/src\=\"(http\:\/\/.+?\.deviantart\.net\/fs\d{2}\/.+?\/([^\/]+.(jpeg|jpg|png|gif)))/ #collect_rid\=\"1\:\d+\" -> numeric ID
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push([$2,$1.sub("/150/","/")])
			end
		}
		@page+=1
		if @content.length<1 then return false end
		sleep(@sleep)
		return true
	end

	def search_first(options={})
		setup(options)
		ret=search_next
		if ret then @notifier.call 'Browsing http://browse.deviantart.com/?order=5&q='+@arg+"\n" end
		return ret
	end

	def search_next
		if @page==@stop||@seek_end then return false end
		begin
			@agent.get('http://browse.deviantart.com/?order=5&q='+@arg.uriEncode+'&offset='+(@page*24).to_s)
		rescue
			return false
		end

		unless @agent.page.body.resolve=~/\<a class="disabled"\>Next\<\/a\>/ then @seek_end=true end
		@content=[]
		array=@agent.page.body.resolve.split("<span class=\"tt-w\">")
		array.shift
		array.each_with_index{|e,i|
			if i==24 then break end #kills daily deviation stuff
			bookmark=0
			if e=~/src\=\"(http\:\/\/.+?\.deviantart\.net\/fs\d{2}\/.+?\/([^\/]+.(jpeg|jpg|png|gif)))/
				if @bookmark>0 && bookmark<@bookmark then next end
				@content.push([$2,$1.sub("/150/","/")])
			end
		}
		@page+=1
		if @content.length<1 then return false end
		sleep(@sleep)
		return true
	end

	def crawl
		@content.each_with_index{|e,i| # e[0] -> filename, e[1] -> URL
			if @filter.include?(File.basename(e[0],".*"))
				if @fast then @seek_end=true end
			else
				@agent.get(e[1], [], 'http://www.deviantart.com/') #2.1 syntax
				@enter_critical.call
				@agent.page.save_as(e[0])
				@exit_critical.call
				sleep(@sleep)
			end
			@notifier.call sprintf("Page %d %d/%d    \r",@page,i+1,@content.length)
		}
	end
end
