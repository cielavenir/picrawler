#coding:utf-8

#Picrawler under CC0
#Picrawler::FgOld module
#bookmark isn't implemented.

class Picrawler::FgOld
	def initialize(options={})
		@agent=Mechanize.new
		@agent.user_agent="Mozilla/5.0"
		@encoding=options[:encoding]||raise
		@sleep=options[:sleep]||3
		@notifier=options[:notifier]
	end

	def list() return ["member","search"] end

	def open(user,pass,cookie)
		if File.exist?(cookie)
			@agent.cookie_jar.load(cookie)
			if @agent.cookie_jar.jar.exists_rec?(["fg-site.net","/","my_id"])
				unless @agent.cookie_jar.jar["fg-site.net"]["/"]["my_id"].expired? then return 1 end #use cookie
			end
		end

		#normal auth.
		form = @agent.get('http://www.fg-site.net/old/users/login/').form_with(:action=>"/old/users/login")
		form.field_with("data[email]").value = user
		form.field_with("data[password]").value = pass
		form.checkbox_with("data[autologin]").check
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
		if ret then @notifier.call 'Browsing http://www.fg-site.net/old/contents/view/'+@arg+"/\n" end
		return ret
	end

	def member_next
		if @page==@stop||@seek_end then return false end;@page+=1
		begin
			@agent.get('http://www.fg-site.net/old/contents/view/'+@arg+'/page:'+@page.to_s)
		rescue
			return false
		end

		unless @agent.page.body.resolve=~/次の20件/ then @seek_end=true end ###
		@content=[]
		array=@agent.page.body.resolve.split("<a href=\"http://www.fg-site.net/old/products/")
		array.shift
		array.each{|e|
			bookmark=0
			if e=~/.+?(http\:\/\/image.+?\.fg-site\.net\/image\/mid\/\d+\/(.+?\.(jpeg|jpg|png|gif)))/m
				if @bookmark>0 && bookmark<@bookmark then next end
				url,filename = $1,$2
				@content.push([filename.gsub("mid","lrg"), url.gsub("/mid","/lrg")])
			end
		}
		if @content.length<1 then return false end
		sleep(@sleep)
		return true
	end

	def search_first(options={})
		setup(options)
		ret=search_next
		if ret then @notifier.call 'Browsing http://www.fg-site.net/old/contents/search/sort:created/direction:desc/word:'+@arg+"/\n" end
		return ret
	end

	def search_next
		if @page==@stop||@seek_end then return false end;@page+=1
		begin
			@agent.get('http://www.fg-site.net/old/contents/search/sort:created/direction:desc/word:'+@arg.uriEncodePath+'/page:'+@page.to_s)
		rescue
			return false
		end

		unless @agent.page.body.resolve=~/次の20件/ then @seek_end=true end ###
		@content=[]
		array=@agent.page.body.resolve.split("<a href=\"http://www.fg-site.net/old/products/")
		array.shift
		array.each{|e|
			if e=~/.+?(http\:\/\/image.+?\.fg-site\.net\/image\/mid\/\d+\/(.+?\.(jpeg|jpg|png|gif)))/m
				if @bookmark>0 && bookmark<@bookmark then next end
				url,filename = $1,$2
				@content.push([filename.gsub("mid","lrg"), url.gsub("/mid","/lrg")])
			end
		}
		if @content.length<1 then return false end
		sleep(@sleep)
		return true
	end

	def crawl
		@content.each_with_index{|e,i| # e[0] -> filename, e[1] -> URL
			if @filter.include?(File.basename(e[0],".*"))
				if @fast then @seek_end=true end
			else
				@agent.get(e[1], [], 'http://www.fg-site.net/old/') #2.1 syntax
				@agent.page.save_as(e[0]) #as file is written after obtaining whole file, it should be less dangerous.
				sleep(@sleep)
			end
			@notifier.call sprintf("Page %d %d/%d    \r",@page,i+1,@content.length)
		}
	end
end
=end
